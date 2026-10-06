"""Regenerate tools/weapon-matrix.csv from the tree (audit row A17).

One row per weapon definition the repo ships, in weapons/zm (the mod's raw
defs) and weapons/ (the stock defs carried from the pristine donor).

Columns: def, location, family, kind, contract, camo, stock_zone,
stock_dump, note.

Kind is measured, not guessed:
- stock-zone: the def name is a `weapon,` asset in tools/stock-zone-assets
  (the six map zones plus common_zm/patch_zm) - the engine already registers
  this gun there, so the mod's copy overrides it.
- stock-dump: the def name (or its family base) exists in the dumped stock
  weapon set (t6-mod-tools all2raw, raw/weapons/mp + sp) - a stock MP/SP gun
  the mod carries into zombies is a stock rebalance; an exact-name hit is a
  stock override.
- port: no stock evidence anywhere - a gun the mod adds.
- donor helper: an off-hand half or projectile def that completes another def
  and is never handed out itself.

Usage: python tools/gen-weapon-matrix.py [repo_root] [stock_dump_root] [out]
"""

import csv
import json
import re
import sys
from pathlib import Path

REPO = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
DUMP = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(r"H:\Plutonium\t6\t6-mod-tools\raw\weapons")
OUT = Path(sys.argv[3]) if len(sys.argv) > 3 else REPO / "tools" / "weapon-matrix.csv"

STOCK_MAPS = ["zm_transit", "zm_nuked", "zm_highrise", "zm_prison", "zm_buried", "zm_tomb"]
STOCK_SHARED = ["common_zm", "patch_zm"]
STOCK_DIR = REPO / "tools" / "stock-zone-assets"

# The audit's gap list (REMAINING-AUDIT.md A17): port families every variant
# def of which belongs in a contract. browninghp is the single-form Browning
# from the same BO1 donor as the contracted dual wield - the audit's gap list
# does not name it, but it is a port all the same.
AUDIT_PORT_FAMILIES = {
    "tesla_gun", "freezegun", "thundergun", "microwavegun", "metalstorm_mms",
    "titus6", "mk_titus6", "titus6_explosive_dart", "peacekeeper", "crossbow",
    "jetgun", "slipgun", "slowgun", "browninghp", "blastomatic", "bloodhound",
    "scavenger", "mm1", "blundergat",
}
# The audit's intentional stock rebalances: no contract wanted, marked as such.
AUDIT_OVERRIDE_FAMILIES = {
    "sa58", "insas", "qbb95", "m60", "mk48", "vector", "dragunov", "t5_l96a1",
    "dsr50", "spas", "sig556", "rpg",
}

# Def-name suffixes that mark a def existing to complete another one.
HELPER_SUFFIX = re.compile(r"(_lh|_bolt|_explosive_dart)(_upgraded)?_zm$")


def weapon_fields(path):
    raw = path.read_text(encoding="latin-1")
    words = raw.split("\\")
    if words[0] != "WEAPONFILE" or len(words) % 2 != 1:
        return {}
    return dict(zip(words[1::2], words[2::2]))


def family_of(name):
    base = name
    for suffix in ("_extclip_upgraded_zm", "_upgraded_zm", "_zm", "_upgraded_mp", "_mp"):
        if base.endswith(suffix):
            base = base[: -len(suffix)]
            break
    base = re.sub(r"^(metalstorm)\d+(_mms)$", r"\1\2", base)
    base = re.sub(r"^(microwavegun)(dw|lh)$", r"\1", base)
    base = re.sub(r"^(browninghp)(dw|lh)$", r"\1", base)
    base = re.sub(r"^(fiveseven)dw$", r"\1", base)
    base = re.sub(r"^(.*)qol$", r"\1", base)
    base = re.sub(r"^(.*)_extclip$", r"\1", base)
    return base


def main():
    stock_zone_weapons = set()
    for zone in STOCK_MAPS + STOCK_SHARED:
        path = STOCK_DIR / f"{zone}.txt"
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            parts = line.split(",", 1)
            if len(parts) == 2 and parts[0] == "weapon":
                stock_zone_weapons.add(parts[1].strip())

    dump_files = {}
    if DUMP.is_dir():
        for path in DUMP.rglob("*_zm*"):
            if path.is_file():
                dump_files[path.name] = path
        for path in DUMP.rglob("*_mp"):
            if path.is_file():
                dump_files[path.name] = path
    dump_bases = {family_of(name) for name in dump_files}

    contracts = {}
    cpath = REPO / "tools" / "weapon-port-contracts.json"
    if cpath.is_file():
        for port in json.loads(cpath.read_text(encoding="utf-8"))["ports"]:
            for weapon in port["weapons"]:
                contracts[weapon] = port["name"]

    zone_camo = {}
    for zpath in (REPO / "zone_source").glob("*.zone"):
        try:
            text = zpath.read_text(encoding="utf-8-sig", errors="replace")
        except OSError:
            continue
        for line in text.splitlines():
            line = line.split("//", 1)[0].strip()
            if line.startswith("camo,"):
                zone_camo.setdefault(line[5:].strip(), []).append(zpath.name)

    rows = []
    for location in ("zm", "root"):
        folder = REPO / "weapons" / ("zm" if location == "zm" else "")
        if location == "root":
            paths = sorted(p for p in REPO.glob("weapons/*_zm*") if p.is_file())
        else:
            paths = sorted(p for p in folder.iterdir() if p.is_file())
        for path in paths:
            name = path.name
            fields = weapon_fields(path)
            fam = family_of(name)
            is_helper = bool(HELPER_SUFFIX.search(name)) or fields.get("inventoryType") == "dwlefthand"
            in_zone = name in stock_zone_weapons
            in_dump = name in dump_files
            fam_in_dump = fam in dump_bases
            same_bytes = False
            if in_dump:
                same_bytes = dump_files[name].read_bytes() == path.read_bytes()
            if is_helper and not in_zone and not in_dump:
                kind = "donor helper"
            elif in_zone or in_dump:
                kind = "stock copy" if same_bytes else "stock override"
            elif fam in AUDIT_PORT_FAMILIES:
                kind = "port"
            elif fam in AUDIT_OVERRIDE_FAMILIES or fam in dump_bases:
                kind = "stock rebalance"
            else:
                kind = "mod def"
            camo = fields.get("camo", "")
            rows.append({
                "def": name,
                "location": location,
                "family": fam,
                "kind": kind,
                "contract": contracts.get(name, ""),
                "camo": camo,
                "stock_zone": "yes" if in_zone else "",
                "stock_dump": "yes" if in_dump else "",
                "note": "",
            })
            if camo and camo in zone_camo:
                rows[-1]["note"] = "camo declared in " + ",".join(zone_camo[camo])

    with OUT.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=[
            "def", "location", "family", "kind", "contract", "camo",
            "stock_zone", "stock_dump", "note"])
        writer.writeheader()
        writer.writerows(rows)
    counts = {}
    for row in rows:
        counts[row["kind"]] = counts.get(row["kind"], 0) + 1
    print("[matrix] %d defs -> %s" % (len(rows), OUT))
    for kind in sorted(counts):
        print("[matrix]   %s: %d" % (kind, counts[kind]))


if __name__ == "__main__":
    main()
