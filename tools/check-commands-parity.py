#!/usr/bin/env python3
"""Check command-table coverage and the cheat-mode permission categories.

Exit 0: covered; exit 1: missing, misclassified or inconsistent command.
Runtime behavior still requires the co-op scenario, including server row writes.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLAYEROPT = ROOT / "scripts" / "zm" / "zmqol_playeropt.gsc"
CMDS = ROOT / "scripts" / "zm" / "zmqol_commands_mp.gsc"


def fail(msg):
    print(f"    [FAIL] {msg}")
    sys.exit(1)


def main():
    old_src = PLAYEROPT.read_text(encoding="utf-8", errors="replace")
    new_src = CMDS.read_text(encoding="utf-8", errors="replace")

    rows = {}
    for m in re.finditer(
        r'zmqol_mp_row\(\s*"(\w+)"\s*,\s*"(\w*)"\s*,\s*"(\w+)"\s*,\s*([01])\s*\)',
        new_src,
    ):
        name, canon, level, targetable = m.groups()
        if level not in {"utility", "self", "host"}:
            fail(f"invalid permission {level} for {name}")
        if name in rows:
            fail(f"duplicate command row: {name}")
        rows[name] = (canon, level, targetable)

    if not rows:
        fail("no zmqol_mp_row() calls found - the table is missing")

    open_start = old_src.find("zmqol_popt_cmd_open( cmd )")
    open_end = old_src.find("zmqol_popt_command( tokens )")
    if open_start < 0 or open_end <= open_start:
        fail("could not locate zmqol_popt_cmd_open in zmqol_playeropt.gsc")
    open_names = set(re.findall(r'case\s+"(\w+)"\s*:', old_src[open_start:open_end]))
    if not open_names:
        fail("the old open list parsed empty")

    chain_names = set(re.findall(r'cmd\s*==\s*"(\w+)"', old_src))
    if not chain_names:
        fail("no cmd == labels found in the old chain")

    missing_open = sorted(n for n in open_names if n not in rows)
    if missing_open:
        fail(f"open-list names missing from the table: {', '.join(missing_open)}")

    utilities = {
        "my", "popt", "mine", "hud", "character", "char", "help", "where",
        "wallhere", "afk", "velocity", "vel", "speed", "powerups", "pay",
    }
    self_cheats = {"give", "giveweapon", "gun", "pack", "unpack", "p",
                   "giveperks", "removeperks", "reload", "movespeed"}
    for name in utilities | self_cheats:
        expected = "utility" if name in utilities else "self"
        if name not in rows or rows[name][1] != expected:
            fail(f"{name} must have permission {expected}")
    for name, (_canon, permission, _target) in rows.items():
        if permission == "utility" and name not in utilities:
            fail(f"unexpected utility permission: {name}")
        if permission == "self" and name not in self_cheats:
            fail(f"unexpected self cheat permission: {name}")

    missing_chain = sorted(n for n in chain_names if n not in rows)
    if missing_chain:
        fail(f"chain labels missing from the table: {', '.join(missing_chain)}")

    if not re.search(r'if \( scripts\\zm\\zmqol_commands_mp::zmqol_mp_dispatch\( player, cmd, tokens \) \)', old_src):
        fail("the dispatcher must run unconditionally before the executor")

    bad_alias = sorted(n for n, (c, _l, _t) in rows.items() if c and c not in rows)
    if bad_alias:
        fail(f"aliases whose canonical name is not a row: {', '.join(bad_alias)}")

    print(f"    [ok] table covers {len(open_names)} open-list names and {len(chain_names)} chain labels")
    print('    [ok] utilities stay open; self cheats require mode or grant; aliases resolve')


if __name__ == "__main__":
    main()
