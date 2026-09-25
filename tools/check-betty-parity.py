"""Fail the build when the Bouncing Betty drifts from the claymore again.

The user reported three Betty bugs on 2026-09-25 and asked never to see them
again:

1. Damage. Stock _zm_spawner::zombie_damage already gives a registered mine
   level.round_number * randomintrange(100,200). bouncingbetty.gsc applied that
   bonus a second time, so Betties still one-shot at round 20+. The blast must
   also stay claymore_zm's 200/200/50, not MP's 256/210/70.
2. The x0 icon. The engine takes an empty clipOnly offhand about 0.9 s after
   the last throw unless the def is plantable or hasDetonator. The Betty must
   stay plantable 0, so zmqol_betty_keep_empty_slot() polls for the take and
   gives the mine back at 0. A fixed short wait re-gives it before the take and
   the icon still vanishes.
3. Box refill. weapon_give() tops up a held weapon with givestartammo, which
   sharedAmmoCap caps. At 1, a re-pull left the player holding one Betty.
4. Reach. Reported the same afternoon: "it's just not affecting the zombies at
   all". The fix for bug 1 deleted the loop that hit every zombie in the blast
   and cut the reach from MP's 256 to 200. The Betty goes off 65 units up,
   0.8 s after the trip, so the engine's radiusdamage alone missed the zombie
   that had tripped it. The reach is 256 again, and zmqol_betty_blast_fill_in()
   hits only the zombies that radiusdamage missed, once each, so bug 1 stays
   fixed.

None of these shows up in a build or a map load. The player finds them in a
match, so each is checked here against the source.

Usage: python tools/check-betty-parity.py [--installed]
--installed also checks the mod the game loads (storage\\t6\\mods\\zm_qol\\mod.iwd)
and fails on a loose raw\\weapons\\zm\\bouncingbetty_zm, which would override it.
"""

import argparse
import os
import re
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DEF = "weapons/zm/bouncingbetty_zm"
SCRIPT = "scripts/zm/bouncingbetty.gsc"

# claymore_zm, stock common_zm. The Betty matches it.
CLAYMORE_BLAST = {"explosionRadius": "200", "explosionInnerDamage": "200", "explosionOuterDamage": "50"}
# Two mines, like the claymore. sharedAmmoCap is the one that broke the refill.
TWO_MINES = {"clipSize": "2", "startAmmo": "2", "maxAmmo": "2", "sharedAmmoCap": "2"}
# plantable 1 would keep the icon on its own, but breaks the MP jump and trigger.
MP_PARITY = {"plantable": "0", "clipOnly": "1"}


def def_fields(data):
    parts = data.decode("latin-1").split("\\")
    return dict(zip(parts[1::2], parts[2::2]))


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def function_body(code, name):
    match = re.search(r"^" + re.escape(name) + r"\s*\([^)]*\)\s*\{", code, re.M)
    if not match:
        return None
    depth, start = 0, match.end() - 1
    for i in range(start, len(code)):
        if code[i] == "{":
            depth += 1
        elif code[i] == "}":
            depth -= 1
            if depth == 0:
                return code[start:i + 1]
    return None


def check_def(fields, where, errors):
    for group, why in ((CLAYMORE_BLAST, "claymore_zm blast (bug 1: damage)"),
                       (TWO_MINES, "two mines (bug 3: box refill)"),
                       (MP_PARITY, "MP trigger parity")):
        for key, want in group.items():
            got = fields.get(key)
            if got != want:
                errors.append(f"{where}: {key} is {got!r}, must be {want!r} for the {why}")


def check_script(text, where, errors):
    code = strip_comments(text)

    # Bug 1: claymore damage, one mine hit per zombie. Bug 4: MP's 256 reach.
    for field, want, bug in (("zmqol_betty_damage_radius", "256", "bug 4: MP blast reach"),
                             ("zmqol_betty_damage_max", "200", "bug 1: claymore damage"),
                             ("zmqol_betty_damage_min", "50", "bug 1: claymore damage")):
        match = re.search(r"level\." + field + r"\s*=\s*(\d+)\s*;", code)
        if not match or match.group(1) != want:
            got = match.group(1) if match else "missing"
            errors.append(f"{where}: level.{field} is {got}, must be {want} ({bug})")
    if re.search(r"round_number", code):
        errors.append(f"{where}: uses round_number. Stock _zm_spawner already gives a registered mine "
                      "the round bonus; adding it here doubles Betty damage (bug 1)")

    # Bug 4: the fill-in reaches the zombies radiusdamage missed. Bug 1: only those.
    fill = function_body(code, "zmqol_betty_blast_fill_in")
    blast = function_body(code, "zmqol_betty_jump_and_explode")
    if fill is None:
        errors.append(f"{where}: zmqol_betty_blast_fill_in() is gone, so a Betty that goes off after "
                      "the zombie walked on hits nothing (bug 4)")
    else:
        if not re.search(r"\.health\s*<\s*a_health\s*\[", fill):
            errors.append(f"{where}: zmqol_betty_blast_fill_in() no longer skips zombies the blast "
                          "already hurt, so they take the mine hit twice (bug 1)")
        if not re.search(r"\"bouncingbetty_zm\"\s*\)", fill):
            errors.append(f"{where}: zmqol_betty_blast_fill_in() must pass \"bouncingbetty_zm\" to "
                          "dodamage, or stock's mine branch never sees the hit (bug 4)")
    if blast is None or not re.search(r"\bzmqol_betty_blast_fill_in\s*\(", blast or ""):
        errors.append(f"{where}: zmqol_betty_jump_and_explode() does not call "
                      "zmqol_betty_blast_fill_in() (bug 4)")
    outside = code.replace(fill, "") if fill else code
    if re.search(r"\bdodamage\s*\(", outside):
        errors.append(f"{where}: calls dodamage() outside zmqol_betty_blast_fill_in(). That is the "
                      "double hit of bug 1")

    # Bug 2: the empty Betty is given back at 0 after the engine takes it.
    body = function_body(code, "zmqol_betty_keep_empty_slot")
    if body is None:
        errors.append(f"{where}: zmqol_betty_keep_empty_slot() is gone, so the Betty icon "
                      "disappears after the second throw instead of reading x0 (bug 2)")
    else:
        needs = {
            "a poll loop (for/while)": r"\b(?:for|while)\s*\(",
            "hasweapon( \"bouncingbetty_zm\" ) to see the take": r"hasweapon\s*\(\s*\"bouncingbetty_zm\"",
            "giveweapon( \"bouncingbetty_zm\" )": r"giveweapon\s*\(\s*\"bouncingbetty_zm\"",
            "setweaponammoclip( \"bouncingbetty_zm\", 0 )": r"setweaponammoclip\s*\(\s*\"bouncingbetty_zm\"\s*,\s*0\s*\)",
            "setactionslot( 4, \"weapon\", \"bouncingbetty_zm\" )": r"setactionslot\s*\(\s*4\s*,\s*\"weapon\"\s*,\s*\"bouncingbetty_zm\"",
        }
        for label, pattern in needs.items():
            if not re.search(pattern, body):
                errors.append(f"{where}: zmqol_betty_keep_empty_slot() lacks {label} (bug 2: x0 icon)")
    if not re.search(r"thread\s+zmqol_betty_keep_empty_slot\s*\(", code):
        errors.append(f"{where}: nothing threads zmqol_betty_keep_empty_slot() on a throw (bug 2: x0 icon)")


def installed_mod_dir():
    base = os.environ.get("LOCALAPPDATA")
    return Path(base) / "Plutonium" / "storage" / "t6" if base else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--installed", action="store_true",
                        help="also check the mod.iwd the game loads and any loose raw override")
    args = parser.parse_args()
    errors = []

    check_def(def_fields((ROOT / DEF).read_bytes()), DEF, errors)
    check_script((ROOT / SCRIPT).read_text(encoding="utf-8", errors="replace"), SCRIPT, errors)
    checked = "source"

    if args.installed:
        storage = installed_mod_dir()
        iwd = storage / "mods" / "zm_qol" / "mod.iwd" if storage else None
        if not iwd or not iwd.is_file():
            errors.append(f"installed mod.iwd not found at {iwd}")
        else:
            with zipfile.ZipFile(iwd) as z:
                names = {n.lower(): n for n in z.namelist()}
                for entry, check in ((DEF, lambda d, w: check_def(def_fields(d), w, errors)),
                                     (SCRIPT, lambda d, w: check_script(d.decode("utf-8", "replace"), w, errors))):
                    name = names.get(entry)
                    if name is None:
                        errors.append(f"installed mod.iwd has no {entry}")
                    else:
                        check(z.read(name), f"installed {entry}")
        loose = storage / "raw" / DEF if storage else None
        if loose and loose.is_file():
            errors.append(f"a loose {loose} overrides the mod's Betty def; delete it")
        checked = "source + installed"

    if errors:
        for error in errors:
            print(f"[betty] FAIL: {error}", file=sys.stderr)
        return 1
    print(f"[betty] PASS ({checked}): claymore damage, 256 reach, x0 icon re-give, box refill to 2")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
