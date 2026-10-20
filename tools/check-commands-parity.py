#!/usr/bin/env python3
"""check-commands-parity.py - the phase 2 command table must cover the old chain.

WHY THIS EXISTS
---------------
2026-10-19, multiplayer plan phase 2: scripts/zm/zmqol_commands_mp.gsc puts a
permission table in front of the chat chain in zmqol_playeropt.gsc, dormant
behind the `zmqol_commands_mp` dvar. When the switch is on, a command name that
is missing from the table would be treated as host-only - which silently takes
an open command away from non-host players, the exact class of regression the
plan's parity rule exists to prevent.

WHAT IT CHECKS
--------------
1. Every name in the old open list (zmqol_popt_cmd_open) has a table row at
   level "self" - except "p", which decision 2 moves to "granted".
2. Every `cmd == "x"` label in the chat chain has a table row (name or alias),
   so nothing rides the host catch-all by accident.
3. Every table row's level is one of self/host/granted, and every alias's
   canonical name is itself a row.

Not checked here (needs a live session): that the layer behaves, which is the
plan's two-client parity probe. This gate only proves coverage.

EXIT CODES
----------
  0  the table covers the old chain
  1  a name is missing or mis-levelled  (do not flip the dvar)
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
        r'zmqol_mp_row\(\s*"(\w+)"\s*,\s*"(\w*)"\s*,\s*"(self|host|granted)"\s*,\s*([01])\s*\)',
        new_src,
    ):
        name, canon, level, targetable = m.groups()
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

    wrong_self = sorted(
        n for n in open_names if n != "p" and n in rows and rows[n][1] != "self"
    )
    if wrong_self:
        fail(f"open-list names not at level self: {', '.join(wrong_self)}")

    if "p" not in rows or rows["p"][1] != "granted":
        fail('decision 2: "p" must be a "granted" row')

    missing_chain = sorted(n for n in chain_names if n not in rows)
    if missing_chain:
        fail(f"chain labels missing from the table: {', '.join(missing_chain)}")

    bad_alias = sorted(n for n, (c, _l, _t) in rows.items() if c and c not in rows)
    if bad_alias:
        fail(f"aliases whose canonical name is not a row: {', '.join(bad_alias)}")

    print(f"    [ok] table covers {len(open_names)} open-list names and {len(chain_names)} chain labels")
    print('    [ok] "p" is granted (decision 2); every alias resolves to a row')


if __name__ == "__main__":
    main()
