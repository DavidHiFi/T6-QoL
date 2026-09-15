#!/usr/bin/env python3
"""
zone_ownership_gate.py - refuse to ship a mod.ff that a stock map zone will
fight over.

WHY THIS EXISTS
---------------
mod.ff loads BEFORE every stock map zone. When both own an asset of the same
name the engine has to pick one, and for most asset types it quietly takes
mod.ff's copy - that is the v1.62.7 Electric Cherry ownership trap, documented
at length in build_ff.bat. For a few types it does not pick at all, it dies:

    COM_ERROR: Attempting to override asset 'zmcore_basicwoodbarrier'
               from zone 'mod' with zone 'zm_tomb'

That shipped in v2.17.1 and made Origins unbootable. The custom-map payload
that caused it is now in zm_octagonal.ff (which only loads with its own map);
this gate is what stops a payload like it coming back into the shared fastfile.

WHAT IT CHECKS
--------------
Every asset in mod.ff whose (type, name) is also owned by a zone that loads
AFTER mod.ff - the six stock zombies map zones. Assets of a type this mod has
already shipped overriding, on every map, for many versions are reported and
allowed. Any other type is a hard failure.

The allow-list is not a guess: it is the set of types present in the 4,502
assets that the shipping v2.16.x mod.ff already overrode without a COM_ERROR.
Adding a type to it means asserting the same thing about that type, so do it
only with a boot on a map that owns the asset.

USAGE
    python zone_ownership_gate.py [--mod-ff mod.ff] [--index <dir>]
                                  [--rebuild-index] [--bo2 <Black Ops II dir>]

The index is a directory of Unlinker --list dumps, one per stock zone. Build it
once with --rebuild-index; after that the gate is a few seconds.

Exit 0 = clean. Exit 1 = a fatal-shaped overlap. Exit 2 = could not run.
"""

import argparse
import collections
import os
import re
import subprocess
import sys

# Zones that load AFTER mod.ff on a stock map. Anything mod.ff owns that these
# also own is an override the engine has to resolve at load time.
POST_MOD_ZONES = [
    "zm_transit", "zm_prison", "zm_buried",
    "zm_tomb", "zm_highrise", "zm_nuked",
]

# Types the shipping mod.ff already overrides on stock maps without a COM_ERROR.
# See the module docstring before touching this.
PROVEN_OVERRIDABLE = {
    "attachment", "attachmentunique", "camo", "fx", "image", "material",
    "physpreset", "rawfile", "techniqueset", "tracer", "weapon", "xanim",
    "xmodel",
}

LINE = re.compile(r"^([a-z0-9_]+), (.*)$")


def read_list(path):
    """(type, name) pairs a zone actually OWNS.

    A leading comma in the name column ("xmodel, ,fx_axis_createfx") is OAT's
    marker for a bare reference - the zone names the asset but carries none of
    its data, so it cannot collide with anything.
    """
    owned = set()
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = LINE.match(line.rstrip("\n"))
            if not m:
                continue
            name = m.group(2)
            if name.startswith(","):
                continue
            owned.add((m.group(1), name))
    return owned


def build_index(unlinker, bo2, index_dir):
    os.makedirs(index_dir, exist_ok=True)
    zone_dir = os.path.join(bo2, "zone", "all")
    for zone in POST_MOD_ZONES:
        ff = os.path.join(zone_dir, zone + ".ff")
        if not os.path.isfile(ff):
            print("  MISSING {}".format(ff))
            return False
        out = os.path.join(index_dir, zone + ".txt")
        with open(out, "w", encoding="utf-8") as fh:
            subprocess.run([unlinker, "--list", ff], stdout=fh,
                           stderr=subprocess.STDOUT, check=True)
        print("  indexed {}".format(zone))
    return True


def main():
    proj = os.path.dirname(os.path.abspath(__file__))

    ap = argparse.ArgumentParser()
    ap.add_argument("--mod-ff", default=os.path.join(proj, "mod.ff"))
    ap.add_argument("--index", default=os.path.join(proj, "zone_source",
                                                   "_stock_zone_index"))
    ap.add_argument("--rebuild-index", action="store_true")
    ap.add_argument("--bo2", default=os.environ.get(
        "BO2_DIR",
        r"F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II"))
    ap.add_argument("--unlinker", default=os.environ.get(
        "OAT_UNLINKER", r"H:\Plutonium\tools\oat-windows\Unlinker.exe"))
    args = ap.parse_args()

    if args.rebuild_index:
        print("Rebuilding the stock zone index (once, then it is cached):")
        if not build_index(args.unlinker, args.bo2, args.index):
            return 2

    missing = [z for z in POST_MOD_ZONES
               if not os.path.isfile(os.path.join(args.index, z + ".txt"))]
    if missing:
        print("No stock zone index for: {}".format(", ".join(missing)))
        print("Run once with --rebuild-index.")
        return 2

    if not os.path.isfile(args.mod_ff):
        print("No such fastfile: {}".format(args.mod_ff))
        return 2

    mod_list = os.path.join(args.index, "_mod.ff.assets.txt")
    with open(mod_list, "w", encoding="utf-8") as fh:
        subprocess.run([args.unlinker, "--list", args.mod_ff], stdout=fh,
                       stderr=subprocess.STDOUT, check=True)
    mod = read_list(mod_list)

    owner = collections.defaultdict(list)
    for zone in POST_MOD_ZONES:
        for key in read_list(os.path.join(args.index, zone + ".txt")):
            owner[key].append(zone)

    fatal, allowed = [], collections.Counter()
    for key in sorted(mod):
        if key not in owner:
            continue
        if key[0] in PROVEN_OVERRIDABLE:
            allowed[key[0]] += 1
        else:
            fatal.append((key, owner[key]))

    print("mod.ff: {} assets".format(len(mod)))
    print("overriding a stock map zone, on a type already proven safe: {}"
          .format(sum(allowed.values())))
    for asset_type, count in allowed.most_common():
        print("    {:18} {}".format(asset_type, count))

    if not fatal:
        print("\nOWNERSHIP GATE PASSED - nothing of an unproven type collides.")
        return 0

    print("\n*** OWNERSHIP GATE FAILED - {} asset(s) mod.ff must not own ***"
          .format(len(fatal)))
    for (asset_type, name), zones in fatal:
        print("    {:12} {:48} owned by {}"
              .format(asset_type, name, ", ".join(zones)))
    print("""
Each of these loads again, from a map zone, AFTER mod.ff. Move it into the
fastfile of whatever needs it - a custom map's payload belongs in that map's
own .ff - or drop it and let the stock zone provide it.""")
    return 1


if __name__ == "__main__":
    sys.exit(main())
