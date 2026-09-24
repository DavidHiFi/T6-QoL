"""Fail the build when a registered cross-map weapon port loses an asset.

Add each new port to weapon-port-contracts.json. The check covers both weapon
forms, their models and animations, all PaP camo choices, and local sounds.
It cannot inspect the appearance of an animation or an engine-only FX asset;
those still require a live gameplay pass on the target maps.
"""

import csv
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CONTRACTS = Path(__file__).with_name("weapon-port-contracts.json")
ANIM_KEYS = {"dtp_in", "dtp_loop", "dtp_out", "dtp_empty_in", "dtp_empty_loop", "dtp_empty_out"}
MODEL_KEY = re.compile(r"(?:gunModel|worldModel|attachViewModel|attachWorldModel)\d*$")


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
        if "," in line:
            kind, name = line.split(",", 1)
            entries.add((kind.strip(), name.strip()))
    return entries


def main():
    errors = []
    contracts = json.loads(CONTRACTS.read_text(encoding="utf-8"))["ports"]
    all_zones = set()
    for path in (ROOT / "zone_source").glob("*.zone"):
        all_zones |= zone_entries(path)
    sound_aliases = set()
    for path in (ROOT / "soundbank").glob("*.csv"):
        with path.open(encoding="utf-8-sig", errors="replace", newline="") as handle:
            sound_aliases.update(row[0] for row in csv.reader(handle) if row)

    for port in contracts:
        name = port["name"]
        zone_path = ROOT / port["zone"]
        if not zone_path.is_file():
            errors.append(f"{name}: missing zone {zone_path}")
            continue
        zone = zone_entries(zone_path)
        camo_name = port["camo"]
        if ("camo", camo_name) not in zone:
            errors.append(f"{name}: {camo_name} is not linked in {port['zone']}")
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
                mapped = {
                    override["baseMaterial"]
                    for material in slots[index]["materials"]
                    for override in material["materialOverrides"]
                }
                for base in port["camoBaseMaterials"]:
                    if base not in mapped:
                        errors.append(f"{name}: slot {index} has no {base} override")
                for material in slots[index]["materials"]:
                    for override in material["materialOverrides"]:
                        dest = override["camoMaterial"]
                        if ("material", dest) not in all_zones:
                            errors.append(f"{name}: slot {index} uses unlinked {dest}")

        for weapon in port["weapons"]:
            path = ROOT / "weapons" / "zm" / weapon
            if not path.is_file():
                errors.append(f"{name}: missing weapon {weapon}")
                continue
            if path.stat().st_size > 20480:
                errors.append(f"{name}: {weapon} exceeds the 20480-byte raw weapon limit")
            fields = weapon_fields(path)
            if fields.get("camo") != camo_name:
                errors.append(f"{name}: {weapon} uses {fields.get('camo')}, expected {camo_name}")
            for key, value in fields.items():
                if not value:
                    continue
                if MODEL_KEY.fullmatch(key) and ("xmodel", value) not in zone:
                    errors.append(f"{name}: {weapon} references missing xmodel {value} ({key})")
                if (key.endswith("Anim") or key in ANIM_KEYS) and value.startswith("viewmodel_"):
                    if ("xanim", value) not in zone:
                        errors.append(f"{name}: {weapon} references missing xanim {value} ({key})")
                if "Sound" in key and any(value.startswith(p) for p in port["soundPrefixes"]):
                    if value not in sound_aliases:
                        errors.append(f"{name}: {weapon} references missing sound alias {value}")
        print(f"[weapon-port] checked {name}: {len(port['weapons'])} forms, camo slots {port['camoSlots']}")

    if errors:
        for error in errors:
            print(f"[weapon-port] FAIL: {error}", file=sys.stderr)
        return 1
    print("[weapon-port] PASS: registered cross-map ports have their declared assets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
