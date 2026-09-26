"""Fail the build when a shipped zombie character can throw a model mod.ff lacks.

A character script names up to five gib pieces (gibspawn1..5). When the zombie
loses that arm, leg or hat, the client hands the name to
createdynentandlaunch(). If no loaded zone carries the model, the engine does
not refuse it: it launches it anyway, reads its null physics preset, and the
game closes with an access violation. No console line and no script error name
it. The crash text points at whatever server thread was running at that moment.

That is how Borough survival closed the game mid-match (user, 2026-09-27). The
35 Buried character scripts mod_locations.zone declares named four limb models,
c_zom_buried_g_{r,l}{arm,leg}spawn, that live only in the classic and grief
Buried fastfiles. zstandard never loads those, so the first zombie that lost a
limb killed the game. modding-jobs\\crash-0447-001 has the dump reading.

Every character a zone declares is read (from this repo, else the stock dump
in T6_RAW), and each gib model it names must be declared in a zone too. The
Buried pieces are in no fastfile every map loads, so declaring them is the only
way to carry them.

Usage: python tools/check-gib-models.py
"""

import os
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
STOCK = Path(os.environ.get("T6_RAW", r"H:\Plutonium\t6\t6-mod-tools\raw"))
GIB = re.compile(r'gibspawn[1-5]\s*=\s*"([^"]+)"', re.I)


def zone_rows():
    scripts, models = set(), set()
    for zone in (ROOT / "zone_source").glob("*.zone"):
        for line in zone.read_text(encoding="utf-8", errors="replace").splitlines():
            kind, _, name = line.strip().partition(",")
            name = name.strip().lstrip(",").replace("\\", "/")
            if kind == "script" and name.startswith("character/"):
                scripts.add(name)
            elif kind == "xmodel":
                models.add(name.lower())
    return scripts, models


def main():
    scripts, models = zone_rows()
    missing, unread = {}, []
    for name in sorted(scripts):
        src = next((p for p in (ROOT / name, STOCK / name) if p.is_file()), None)
        if src is None:
            unread.append(name)
            continue
        for model in GIB.findall(src.read_text(encoding="utf-8", errors="replace")):
            if model.lower() not in models:
                missing.setdefault(model, []).append(name)

    if unread and len(unread) == len(scripts):
        print(f"  [gib-models] skipped: no character source here or in {STOCK} (set T6_RAW)")
        return 0
    for name in unread:
        print(f"  [gib-models] no source for {name}, not checked")
    if missing:
        for model, owners in sorted(missing.items()):
            print(f"  [gib-models] {model} is thrown by {len(owners)} shipped characters, e.g. {owners[0]}")
        print()
        print("  No zone declares it, so on a map whose own fastfile lacks it the first")
        print("  zombie to lose that piece closes the game. Add an xmodel, row for it to")
        print("  the zone that declares the character.")
        return 1
    print(f"  [gib-models] {len(scripts)} characters, every gib model declared")
    return 0


if __name__ == "__main__":
    sys.exit(main())
