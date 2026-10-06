"""Fail the build when a registered cross-map weapon port loses an asset.

Add each new port to weapon-port-contracts.json. Two passes run.

Source pass (always): both weapon forms, their models, animations, sound
aliases, and the PaP camo table's slots 3, 8 and 12. A contract may set
"camo" to null (the gun ships no camo table at all) and may set
"camoExceptions" per def (def -> expected camo, null = no camo on that def)
for base forms and projectiles that legitimately carry no camo.

Readback pass (when the Unlinker and the stock listings are present): every
xmodel, fx, tracer and material a def names must exist either in the linked
mod.ff or in a zone EVERY stock map loads. Only then can the gun draw the same
on all six. The readback reads mod.ff itself, so a zone line that never linked,
or a mod.ff older than its zone, fails here. With --pixels, each image in the
port's zone must also have pixels in an image bank the client opens at startup;
a linked image with no pixels draws black.

Why each pass exists. The Blundergat shipped with none of this and the player
saw it: the upgraded def named an armor attachment the zone never linked (black
block across the screen on reload), its camo table had no Blundergat entry in
slots 3 or 12 (black gun on Pack-a-Punch with animated camos off), and all four
muzzle flashes were Mob-only (no flash anywhere else). A clean build and a clean
map load hid all three. A def's missing fx or model logs one line, or none.

What no offline check can prove: how the gun looks, and whether a notetrack
fires. Still test the upgraded gun in game with animated camos on and off,
including a reload, on a map that is not the donor's.

Usage: python tools/check-weapon-port.py [--pixels] [--mod-ff PATH]
Stock listings in tools/stock-zone-assets/ are regenerated with --relist.
"""

import argparse
import csv
import json
import os
import re
import struct
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CONTRACTS = Path(__file__).with_name("weapon-port-contracts.json")
STOCK_DIR = Path(__file__).with_name("stock-zone-assets")
STOCK_MAPS = ["zm_transit", "zm_nuked", "zm_highrise", "zm_prison", "zm_buried", "zm_tomb"]
STOCK_SHARED = ["common_zm", "patch_zm"]
LISTED_KINDS = {"fx", "tracer", "xmodel", "material", "xanim", "camo", "weapon"}
# Banks Plutonium opens before any map zone (console: "Added ipak file:").
STARTUP_BANKS = ["patch_zm", "base", "zm", "mp", "dlczm0_load_zm",
                 "dlczm0", "dlczm1", "dlczm2", "dlczm3", "dlczm4"]

ANIM_KEYS = {"dtp_in", "dtp_loop", "dtp_out", "dtp_empty_in", "dtp_empty_loop", "dtp_empty_out"}
MODEL_KEY = re.compile(r"(?:gunModel|worldModel|attachViewModel|attachWorldModel|"
                       r"worldClipModel|rocketModel|knifeModel|worldKnifeModel|"
                       r"projectileModel|stowedModel)\d*$")
FX_KEY = re.compile(r"(?:view|world)(?:Flash|ShellEject|LastShotEject)Effect$|"
                    r"^proj(?:Explosion|Dud|Trail|IgnitionEffect|Beacon)Effect\d*$")
MATERIAL_KEYS = {"hudIcon", "killIcon", "ammoCounterIcon", "dpadIcon", "indicatorIcon",
                 "reticleCenter", "reticleSide", "adsOverlayShader", "adsOverlayShaderLowRes"}


def oat_dir():
    for candidate in (os.environ.get("OAT_BASE"), r"H:\Plutonium\tools\oat-dlc5",
                      r"H:\Plutonium\tools\oat-windows"):
        if candidate and (Path(candidate) / "Unlinker.exe").is_file():
            return Path(candidate)
    return None


def bo2_dir():
    path = Path(os.environ.get("BO2_DIR", r"F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II"))
    return path if (path / "zone" / "all").is_dir() else None


def weapon_fields(path):
    raw = path.read_text(encoding="latin-1")
    words = raw.split("\\")
    if words[0] != "WEAPONFILE" or len(words) % 2 != 1:
        raise ValueError(f"{path}: invalid weapon file format")
    return dict(zip(words[1::2], words[2::2]))


def zone_entries(path):
    entries = set()
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.split("//", 1)[0].strip()
        if "," in line and not line.startswith(">"):
            kind, name = line.split(",", 1)
            entries.add((kind.strip(), name.strip().lstrip(",")))
    return entries


def zone_declarations(path):
    """Assets the zone DECLARED (copied into the fastfile it produces), not the
    bare `kind,,name` references it only names for the Linker to resolve out of
    a --load'ed zone. A bare reference never lands in mod.ff, so the readback
    must not demand it there."""
    entries = set()
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.split("//", 1)[0].strip()
        if "," in line and not line.startswith(">") and ",," not in line:
            kind, name = line.split(",", 1)
            entries.add((kind.strip(), name.strip().lstrip(",")))
    return entries


def unlinker_list(unlinker, fastfile):
    """Asset (kind, name) pairs a fastfile owns. Bare references are skipped."""
    out = subprocess.run([str(unlinker), "--list", str(fastfile)], capture_output=True,
                         text=True, encoding="utf-8", errors="replace", check=False).stdout
    owned = set()
    for line in out.splitlines():
        if ", " not in line or line.startswith(("Loaded", "Unloaded", "Zone ")):
            continue
        kind, name = line.split(", ", 1)
        if not name.startswith(","):
            owned.add((kind, name))
    return owned


def relist(unlinker, bo2):
    STOCK_DIR.mkdir(exist_ok=True)
    for zone in STOCK_MAPS + STOCK_SHARED:
        rows = sorted(f"{k},{n}" for k, n in unlinker_list(unlinker, bo2 / "zone" / "all" / f"{zone}.ff")
                      if k in LISTED_KINDS)
        (STOCK_DIR / f"{zone}.txt").write_text("\n".join(rows) + "\n", encoding="utf-8")
        print(f"[weapon-port] relisted {zone}: {len(rows)} assets")


def stock_listing(zone):
    path = STOCK_DIR / f"{zone}.txt"
    if not path.is_file():
        return None
    return {tuple(line.split(",", 1)) for line in path.read_text(encoding="utf-8").split("\n") if line}


def stock_everywhere():
    """Assets every stock map provides: in all six map zones, or in a shared zone."""
    maps = [stock_listing(z) for z in STOCK_MAPS]
    if any(m is None for m in maps):
        return None
    everywhere = set.intersection(*maps)
    for zone in STOCK_SHARED:
        everywhere |= stock_listing(zone) or set()
    return everywhere


def stock_camo_owners(camo_name):
    """Stock zones that own a camo table of this name. A map's own copy is the
    one that draws on that map, so a port must use a name no stock zone owns."""
    return [z for z in STOCK_MAPS + STOCK_SHARED
            if ("camo", camo_name) in (stock_listing(z) or set())]


def r_hash_string(name):
    value = 0
    for ch in name.encode("latin-1"):
        value = ((33 * value) ^ (ch | 0x20)) & 0xFFFFFFFF
    return value


def ipak_name_hashes(path):
    """nameHash keys from a KAPI image bank's index section (section type 1)."""
    found = set()
    with path.open("rb") as handle:
        magic, _version, _size, sections = struct.unpack("<4sIII", handle.read(16))
        if magic != b"KAPI":
            return found
        table = [struct.unpack("<IIII", handle.read(16)) for _ in range(sections)]
        for kind, offset, _length, count in table:
            if kind != 1:
                continue
            handle.seek(offset)
            data = handle.read(count * 16)
            found.update(struct.unpack_from("<I", data, i * 16 + 4)[0] for i in range(count))
    return found


def stock_union():
    """Assets ANY stock zone provides: the union of the six map zones and the
    shared zones. A def that ships as a stock override may reference stock
    assets (the Jet Gun's minigun anims, the engine's tag_flash), which the
    mod's own zones never declare."""
    cached = getattr(stock_union, "_cache", None)
    if cached is not None:
        return cached
    found = set()
    for zone in STOCK_MAPS + STOCK_SHARED:
        found |= stock_listing(zone) or set()
    stock_union._cache = found
    return found


def source_pass(port, errors, all_zones, sound_aliases):
    name = port["name"]
    zone_path = ROOT / port["zone"]
    if not zone_path.is_file():
        errors.append(f"{name}: missing zone {zone_path}")
        return None
    zone = zone_entries(zone_path)
    # A def's references must be declared in the contract's own zone, plus any
    # extra zones the contract names (the Titus-6's dive-to-prone anims live
    # in mod_revise.zone), plus, when the contract sets stockAssets, any
    # asset a stock zone provides (stock guns and engine builtins).
    resolvable = set(zone)
    for extra in port.get("assetZones", []):
        resolvable |= zone_entries(ROOT / extra)
    if port.get("stockAssets"):
        resolvable |= stock_union()
    camo_name = port.get("camo")
    camo_exceptions = port.get("camoExceptions", {})
    if camo_name:
        if ("camo", camo_name) not in zone:
            errors.append(f"{name}: {camo_name} is not linked in {port['zone']}")
        owners = stock_camo_owners(camo_name)
        if owners:
            errors.append(f"{name}: camo table {camo_name} is also owned by {', '.join(owners)}; "
                          f"that map's copy draws instead of the mod's, so use a camo_qol_ name")
        camo_path = ROOT / "zone_assets" / "camo" / f"{camo_name}.json"
        if not camo_path.is_file():
            errors.append(f"{name}: missing {camo_path}")
        else:
            camo = json.loads(camo_path.read_text(encoding="utf-8"))
            slots = camo.get("camoMaterials", [])
            for index in port["camoSlots"]:
                if index >= len(slots):
                    errors.append(f"{name}: camo slot {index} is absent")
                    continue
                overrides = [o for m in slots[index]["materials"] for o in m["materialOverrides"]]
                mapped = {o["baseMaterial"] for o in overrides}
                for base in port["camoBaseMaterials"]:
                    if base not in mapped:
                        errors.append(f"{name}: slot {index} has no {base} override")
                for override in overrides:
                    if ("material", override["camoMaterial"]) not in all_zones:
                        errors.append(f"{name}: slot {index} uses unlinked {override['camoMaterial']}")

    forms = {}
    for weapon in port["weapons"]:
        path = ROOT / "weapons" / "zm" / weapon
        if not path.is_file():
            errors.append(f"{name}: missing weapon {weapon}")
            continue
        if path.stat().st_size > 20480:
            errors.append(f"{name}: {weapon} exceeds the 20480-byte raw weapon limit")
        fields = weapon_fields(path)
        forms[weapon] = fields
        # A projectile def nobody holds (the Scavenger's bolt grenade, like
        # stock's blundersplat dart) has no view model and so no camo to draw.
        held = fields.get("gunModel") or fields.get("inventoryType") != "offhand"
        # camoExceptions names defs whose camo field legitimately differs from
        # the family's table (a base form with no camo, a projectile with no
        # view model camo); null means that def ships with no camo at all.
        expected_camo = camo_exceptions.get(weapon, camo_name)
        if held and expected_camo is not None and fields.get("camo") != expected_camo:
            errors.append(f"{name}: {weapon} uses {fields.get('camo')}, expected {expected_camo}")
        for key, value in fields.items():
            if not value:
                continue
            if MODEL_KEY.fullmatch(key) and ("xmodel", value) not in resolvable:
                errors.append(f"{name}: {weapon} references missing xmodel {value} ({key})")
            if (key.endswith("Anim") or key in ANIM_KEYS) and value.startswith("viewmodel_"):
                if ("xanim", value) not in resolvable:
                    errors.append(f"{name}: {weapon} references missing xanim {value} ({key})")
            if "Sound" in key and any(value.startswith(p) for p in port["soundPrefixes"]):
                if value not in sound_aliases:
                    errors.append(f"{name}: {weapon} references missing sound alias {value}")
    return forms


def raw_efx_names():
    """Every effect shipped raw (fx/<name>.efx, packed into mod.iwd). A def may
    reference one directly (the T5 wonder weapons' muzzle flashes): Plutonium
    resolves a weapon def's fx out of the iwd at weapon precache, which is how
    the donor mod shipped its 27 T5 effects (mod_wonderweapons.zone header)."""
    fx_dir = ROOT / "fx"
    if not fx_dir.is_dir():
        return set()
    return {p.relative_to(fx_dir).with_suffix("").as_posix().lower()
            for p in fx_dir.rglob("*.efx")}


def raw_server_fx():
    """Effects that ship raw (fx/<name>.efx, packed into mod.iwd) AND that a server
    script loadfx's. Plutonium loads such an effect at precache ("Loaded fx:
    <name>" in console_zm.log), and a weapon def naming it then resolves: the
    Thundergun's and Winter's Howl's muzzle flashes have always shipped this way.
    A raw .efx that no server script loadfx's does NOT load (the client-only
    Wunderfizz marker, tools/check-client-fx-precache.py), so it is not counted."""
    fx_dir = ROOT / "fx"
    if not fx_dir.is_dir():
        return set()
    raw = {p.relative_to(fx_dir).with_suffix("").as_posix().lower() for p in fx_dir.rglob("*.efx")}
    loaded = set()
    pattern = re.compile(r'loadfx\s*\(\s*"([^"]+)"', re.I)
    for top in ("scripts", "maps"):
        base = ROOT / top
        if not base.is_dir():
            continue
        for path in base.rglob("*.gsc"):
            text = path.read_text(encoding="utf-8", errors="replace")
            text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
            text = "\n".join(line.split("//", 1)[0] for line in text.splitlines())
            loaded |= {m.group(1).replace("\\", "/").strip("/").lower() for m in pattern.finditer(text)}
    return {("fx", n) for n in raw & loaded}


def readback_pass(port, forms, errors, linked, everywhere):
    """Every asset a def names must be in mod.ff, on every stock map, or (fx only)
    ship raw in mod.iwd with a server loadfx."""
    name = port["name"]
    # A stock gun the mod overrides only appears on the maps that own it; its
    # contract names those maps ("stockMaps") and their stock zones count as
    # providers for that def's references.
    allowed = everywhere
    for map_name in port.get("stockMaps", []):
        listing = stock_listing(map_name)
        if listing is None:
            errors.append(f"{name}: stockMaps names {map_name}, which has no stock listing")
        else:
            allowed = allowed | listing
    raw_fx = raw_server_fx()
    shipped_efx = raw_efx_names()
    for weapon, fields in forms.items():
        for key, value in fields.items():
            if not value or value.lower() == "none":
                continue
            if MODEL_KEY.fullmatch(key):
                kind = "xmodel"
            elif FX_KEY.search(key):
                kind = "fx"
            elif key == "tracerType":
                kind = "tracer"
            elif key in MATERIAL_KEYS:
                kind = "material"
            else:
                continue
            if (kind, value) in raw_fx:
                continue
            if kind == "fx" and value.lower() in shipped_efx:
                continue
            if (kind, value) not in linked and (kind, value) not in allowed:
                errors.append(f"{name}: {weapon} {key} names {kind} {value}, which is neither "
                              f"in the linked mod.ff nor on every stock map; declare it in {port['zone']}"
                              + (" or ship fx/<name>.efx with a server loadfx" if kind == "fx" else ""))
    zone = zone_declarations(ROOT / port["zone"])
    for kind, asset in sorted(zone):
        if kind in ("xmodel", "xanim", "fx", "camo", "material") and (kind, asset) not in linked:
            if (kind, asset) in everywhere:
                # A stock shared zone owns it; the runtime resolves it there and
                # the Linker may emit a reference instead of a copy.
                continue
            errors.append(f"{name}: {port['zone']} declares {kind} {asset} but the linked mod.ff "
                          f"does not carry it; run build_ff.bat")


def pixel_pass(port, unlinker, bo2, errors):
    """Images the port's xmodels pull in must have pixels in a startup bank."""
    name = port["name"]
    if port.get("pixelCheck") is False:
        # Contracts whose gun's images live in a donor or stock bank the
        # checker cannot open (a --load'ed donor fastfile, a stock DLC bank)
        # declare pixelCheck false; the pixels are proven another way and
        # recorded in the port's own job folder. Everything else still needs
        # donorZone+imageMatch or rawMaterials.
        print(f"[weapon-port] {name}: pixel check skipped (pixelCheck false in contract)")
        return
    banks = set()
    for bank in STARTUP_BANKS:
        path = bo2 / "zone" / "all" / f"{bank}.ipak"
        if path.is_file():
            banks |= ipak_name_hashes(path)
    english = bo2 / "zone" / "english" / "en_base.ipak"
    if english.is_file():
        banks |= ipak_name_hashes(english)
    # A mod-shipped .iwi is copied from zone_assets\images into images\ by
    # build.bat step 1, so either folder counts as shipping its pixels.
    loose = {p.stem.lower() for p in (ROOT / "images").glob("*.iwi")}
    loose |= {p.stem.lower() for p in (ROOT / "zone_assets" / "images").glob("*.iwi")}
    donor, match = port.get("donorZone"), port.get("imageMatch", [])
    raw_prefix = port.get("rawMaterials")
    if raw_prefix:
        # A port built from raw source has no donor zone: its images are the
        # ones its own material JSONs name. Each needs a shipped .iwi or a bank.
        images = set()
        for path in (ROOT / "zone_assets" / "materials").rglob(f"{raw_prefix}*.json"):
            material = json.loads(path.read_text(encoding="utf-8"))
            images |= {t["image"] for t in material.get("textures", [])}
        if not images:
            errors.append(f"{name}: no zone_assets/materials/{raw_prefix}*.json; fix rawMaterials")
    elif not donor or not match:
        errors.append(f"{name}: --pixels needs donorZone and imageMatch, or rawMaterials, in the contract")
        return
    else:
        owned = unlinker_list(unlinker, bo2 / "zone" / "all" / f"{donor}.ff")
        images = {n for k, n in owned if k == "image" and any(m in n for m in match)}
        if not images:
            errors.append(f"{name}: {donor}.ff owns no image matching {match}; fix imageMatch")
    for image in sorted(images):
        if image.startswith("$"):
            # engine built-ins ($gray, $white, $black, $identitynormalmap) exist on
            # every map; the shipped BO1 L96A1's materials use $gray
            continue
        if r_hash_string(image) not in banks and image.lower() not in loose:
            errors.append(f"{name}: image {image} has no pixels in any startup bank or mod image; it will draw black")
    print(f"[weapon-port] {name}: {len(images)} image(s) checked for pixels")


def iwi_is_black(path):
    """True when the full-size mip of a DXT .iwi is (almost) all zero bytes.

    An all-zero DXT1/DXT5 block decodes to black, so byte zeros are enough to
    see it without a decoder. Mips are stored smallest first: the top mip is
    the tail of the file.
    """
    data = path.read_bytes()
    if data[:3] != b"IWi":
        return False
    fmt = data[4]
    width, height = struct.unpack_from("<HH", data, 6)
    block = {11: 8, 12: 16, 13: 16}.get(fmt)
    if not block:
        return False
    top = data[-(((width + 3) // 4) * ((height + 3) // 4) * block):]
    sample = top[::61]
    return sum(1 for b in sample if b) < len(sample) * 0.001


def camo_colour_pass(port, errors):
    """The gun's main surface must not take a camo whose colour map is black.

    The installed HD pack replaces some camo textures in storage\\t6\\images,
    and a loose file there beats every bank. Its ~-gcamo_zmb_dlc2_alt_col is
    solid black. Stock guns use that "_alt" material for small trim parts, so
    black trim is the pack's look. The Blundergat has one material, and its
    table sent it to dlc2_alt_2: the whole gun drew black on every map.

    So the first entry of camoBaseMaterials is the gun's main surface, and it
    must not resolve to a black colour map in any PaP slot. A glow material
    (it has an Ember map) passes, because its colour comes from the glow.
    """
    name = port["name"]
    main = port["camoBaseMaterials"][0]
    camo = json.loads((ROOT / "zone_assets" / "camo" / f"{port['camo']}.json").read_text(encoding="utf-8"))
    sources = []
    local = os.environ.get("LOCALAPPDATA")
    if local:
        sources.append(Path(local) / "Plutonium" / "storage" / "t6" / "images")
    sources += [ROOT / "images", ROOT / "zone_assets" / "images"]
    slots = camo.get("camoMaterials", [])
    for index in port["camoSlots"]:
        if index >= len(slots):
            continue
        for material in slots[index]["materials"]:
            for override in material["materialOverrides"]:
                if override["baseMaterial"] != main:
                    continue
                path = ROOT / "zone_assets" / "materials" / f"{override['camoMaterial']}.json"
                if not path.is_file():
                    continue
                textures = json.loads(path.read_text(encoding="utf-8")).get("textures", [])
                if any(t.get("name") == "Ember" for t in textures):
                    continue
                for texture in textures:
                    if texture.get("name") != "colorMap":
                        continue
                    image = next((s / f"{texture['image']}.iwi" for s in sources
                                  if (s / f"{texture['image']}.iwi").is_file()), None)
                    if image and iwi_is_black(image):
                        errors.append(f"{name}: slot {index} paints the main surface {main} with "
                                      f"{override['camoMaterial']}, whose colour map {image} is solid black, "
                                      f"so the Pack-a-Punched gun draws black; use the body camo other guns use "
                                      f"(mtl_weapon_camo_zmb_dlc2_1 in slot 8)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pixels", action="store_true", help="also check image pixels in the client's banks")
    parser.add_argument("--mod-ff", default=str(ROOT / "mod.ff"))
    parser.add_argument("--relist", action="store_true", help="regenerate tools/stock-zone-assets and exit")
    parser.add_argument("--source-only", action="store_true", help="skip the mod.ff readback")
    args = parser.parse_args()

    oat, bo2 = oat_dir(), bo2_dir()
    if args.relist:
        if not (oat and bo2):
            print("[weapon-port] FAIL: --relist needs the Unlinker (OAT_BASE) and BO2_DIR", file=sys.stderr)
            return 1
        relist(oat / "Unlinker.exe", bo2)
        return 0

    errors = []
    contracts = json.loads(CONTRACTS.read_text(encoding="utf-8"))["ports"]
    all_zones = set()
    for path in (ROOT / "zone_source").glob("*.zone"):
        all_zones |= zone_entries(path)
    sound_aliases = set()
    for path in (ROOT / "soundbank").glob("*.csv"):
        with path.open(encoding="utf-8-sig", errors="replace", newline="") as handle:
            sound_aliases.update(row[0] for row in csv.reader(handle) if row)

    everywhere = stock_everywhere()
    linked = None
    mod_ff = Path(args.mod_ff)
    if args.source_only:
        pass
    elif not oat or everywhere is None or not mod_ff.is_file():
        missing = "Unlinker" if not oat else "tools/stock-zone-assets" if everywhere is None else str(mod_ff)
        print(f"[weapon-port] WARN: readback skipped, {missing} not found; only the source pass ran")
    else:
        linked = unlinker_list(oat / "Unlinker.exe", mod_ff)

    for port in contracts:
        forms = source_pass(port, errors, all_zones, sound_aliases)
        if forms is None:
            continue
        if port.get("camo"):
            camo_colour_pass(port, errors)
        if linked is not None:
            readback_pass(port, forms, errors, linked, everywhere)
        if args.pixels and oat and bo2:
            pixel_pass(port, oat / "Unlinker.exe", bo2, errors)
        passes = "source + readback" if linked is not None else "source"
        print(f"[weapon-port] checked {port['name']} ({passes}): {len(forms)} forms, "
              f"camo slots {port['camoSlots']}")

    if errors:
        for error in errors:
            print(f"[weapon-port] FAIL: {error}", file=sys.stderr)
        return 1
    print("[weapon-port] PASS: registered cross-map ports have their declared assets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
