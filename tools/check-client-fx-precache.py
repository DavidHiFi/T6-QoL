"""Fail the build when a client script loads a raw .efx no server script loads.

Plutonium reads a raw effect (fx/<name>.efx, packed into mod.iwd) only when a
SERVER script loadfx's it during precache. The console then logs
"Loaded fx: <name>". A loadfx of the same name in a .csc alone never loads it:
level._effect[...] stays undefined on the client, with no error anywhere.

That is how the Wunderfizz Vulture Aid marker came out blown out for weeks
(user, 2026-09-25). zm_expanded.csc was the only script that loadfx'd the four
marker effects (fx_zm_vulture_glow_wunderfizz/generic/deadshot/flopper), none of
them ever loaded, and the marker fell back to vulture_perk_wallbuy_dynamic: the
crossed rifles, 47% pure white. Three fixes dimmed textures that were never
drawn. The server-side loadfx now lives in _zm_perk_vulture.gsc
vulture_precache().

An effect linked into mod.ff by a zone (an "fx,<name>" row) is not raw and
loads with the fastfile, so it passes. So does a name with no .efx in fx/,
which is a stock asset.

Usage: python tools/check-client-fx-precache.py
"""

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
# Script folders pack_iwd.ps1 ships. zone_assets holds the linked copies, and
# parsed/ and compiled/ are tool output, not shipped source.
SCRIPT_DIRS = ["scripts", "maps", "clientscripts", "character", "aitype"]
LOADFX = re.compile(r'loadfx\s*\(\s*"([^"]+)"', re.I)


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def norm(name):
    return re.sub(r"/+", "/", name.replace("\\", "/")).strip("/").lower()


def loads(suffix):
    found = {}
    for top in SCRIPT_DIRS:
        base = ROOT / top
        if not base.is_dir():
            continue
        for path in base.rglob("*" + suffix):
            text = strip_comments(path.read_text(encoding="utf-8", errors="replace"))
            for match in LOADFX.finditer(text):
                found.setdefault(norm(match.group(1)), []).append(path.relative_to(ROOT))
    return found


def zone_fx():
    linked = set()
    for zone in (ROOT / "zone_source").glob("*.zone"):
        for line in zone.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if line.lower().startswith("fx,"):
                linked.add(norm(line[3:].strip().strip('"')))
    return linked


def main():
    fx_dir = ROOT / "fx"
    raw = {norm(p.relative_to(fx_dir).with_suffix("").as_posix()) for p in fx_dir.rglob("*.efx")}
    server = loads(".gsc")
    client = loads(".csc")
    linked = zone_fx()

    bad = sorted(name for name in client if name in raw and name not in server and name not in linked)
    if bad:
        for name in bad:
            where = ", ".join(str(p) for p in sorted(set(client[name])))
            print(f"  [client-fx] fx/{name}.efx is loadfx'd only in {where}")
        print()
        print("  Plutonium never loads a raw .efx that only a .csc asks for, and the")
        print("  client falls back without an error. Add the same loadfx to a server")
        print("  .gsc precache (the Vulture marker icons live in _zm_perk_vulture.gsc")
        print("  vulture_precache), or link the effect into mod.ff with an fx, row.")
        return 1

    shared = sum(1 for name in client if name in raw)
    print(f"  [ok] {shared} raw .efx loaded by client scripts, all loaded by a server script too")
    return 0


if __name__ == "__main__":
    sys.exit(main())
