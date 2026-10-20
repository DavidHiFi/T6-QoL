# HANDOFF 2026-10-11 — "zombies walk into me but don't attack" + "going straight through the barriers"

Status: **source fixes are written; build, deploy and live verify did NOT run** — this
session's sandbox could not execute any shell command (every `pwsh` call failed with
`SetNamedSecurityInfoW failed (Win32 5): grantWrite(H:\C-O-D Configuration\T6 - Black Ops 2\mods\zm_qol)`, including
the approved ACL-repair attempt). Git, `build.bat`, deploy and the game were unreachable all
session. Everything below is file-tool work only. Working tree was already on
`fix/lui-guard-deploy-copies` (last commit `6e74638`, v2.18.2); it was left untouched apart
from the files listed here.

## What the user reported (dictated, 2026-10-11)

1. Zombies walk into the player but don't attack — "the same thing earlier", believed fixed,
   wants it permanently fixed.
2. Zombies go straight through the barriers — "again?".

## Evidence

`C:\Users\LOCALU~1\AppData\Local\Plutonium\console.log` (1828 lines, today): ONE session,
**TranZit Farm survival** (`so_zsurvival_zm_transit`, gump farm), the deployed build printed

- `[zm_qol] BARRIERS: gating inside nodes on 37 windows in farm` (38 total, 1 has no `neg_end`)
- `[zm_qol] BARRIERS: farm - 38 of 38 windows fully boarded at start (rebuilt 0 that were open)`
- `[zm_qol] no_bleedout: shared failsafe hook LIVE on zm_transit - row=0`
- and **zero** `[zm_qol] zombie AI:` repair lines — because nothing on Farm runs the repair.

## Root cause 1 — walk-into-you: the proven fix never ran on Farm

Stock `_zm_spawner.gsc::zombie_goto_entrance` (lines 506-544) sets
`self.pathenemyfightdist = 4` (line 540) and restores 64 (line 542) two lines later; the
thread is killable there (`endon("bad_path")`, line 515), stranding a zombie that only ever
fights from 4 units — it presses into the player and never swings. `loc_common.gsc::
fix_stuck_fight_distance()` (v2.17.30, live on the arenas since) repairs exactly this plus a
dead `find_flesh`/`ignoreme=1` zombie — but it was threaded **only** from
`loc_common::init()`, which runs on the 14 replaced locations (Diner, Power, Tunnel,
Cornfield, Church, Trenches, Crazy Place, Excavation, Docks, Mall, Rooftop, Sweatshop,
Maze). **Farm, Town, Bus Depot and every classic gamemode have no loc script, so the fix
never existed there.** Not a code regression — a coverage hole.

## Root cause 2 — vault-through: a stranded mid-rip board reads as "no boards"

Tear-piece state machine (all verified in the dump): `closed` →
`targetted_by_zombie` (selected, `_zm_spawner.gsc:720`) → `opening` (rip notetrack,
`:963`) → `open` (native rip completion; no script site sets it for windows — only
Brutus/magic-box do — yet `get_random_destroyed_chunk` reads `"open"` on zbarriers, so the
native transition is real). Stock's death/interrupt cleanup reverts to `closed` ONLY from
`targetted_by_zombie` (`:1185-1199`); `get_non_destroyed_chunks()` offers only `"closed"`
pieces (`_zm_utility.gsc:1863`); and `all_chunks_destroyed()` counts `open` + `opening`
(`:410`). So a zombie killed or teleported after the notetrack strands its piece in
`opening`: the window is "all destroyed" to stock, the piece can never be re-torn, and every
later zombie vaults past a board that is visibly still there. Players shoot through boards
(84-100% of traces passed a boarded Church window, 2026-09-16), so deaths mid-rip are
constant. The mod's gate counter (`zmqol_barriers_boards_up`) had copied stock's
open+opening test verbatim, so it re-opened the inside path node while a board stood. The
vault itself is `animscripted` (no pathing), so the RULE 2 gate alone could never stop the
entrance-flow vault at such a window — the stranding had to be healed too.

## Changes written (all in `H:\C-O-D Configuration\T6 - Black Ops 2\mods\zm_qol`)

1. **NEW `scripts\zm\zmqol_ai_fightdist.gsc`** — root script (own `init()` per AGENTS.md 1b;
   `quality_of_life.gsc` untouched, still at its ceiling). Waits for
   `start_zombie_round_logic`, then — if `level.zmqol_fightdist_watchdog` is unset — sets it
   and threads `scripts\zm\locs\loc_common::fix_stuck_fight_distance()`. Same proven repair,
   now on every map and gamemode.
2. **`scripts\zm\locs\loc_common.gsc`**
   - `init()` now honours the shared single-flight flag (no double watchdog on the arenas;
     loc copy wins there because it installs first, at map spawn).
   - `zmqol_at_own_barrier()` piece test tightened: only fully `"open"` pieces count as gone
     (was stock's open+opening). A zombie at a window with any pre-open piece is left to
     stock — restarting find_flesh there is the documented vault-through mechanism.
3. **`scripts\zm\zmqol_barriers.gsc`**
   - `zmqol_barriers_boards_up()` strict: only `"open"` counts as down. A piece mid-rip or
     targetted keeps the inside node disabled. The vault is animscripted so a normal tear is
     unaffected; `"closing"` (rebuild) pieces count as up, which is correct.
   - NEW `zmqol_barriers_heal_stranded_pieces()` (threaded from `init()`): every 0.5 s, a
     piece held in `targetted_by_zombie`/`opening` for > 15 s is reverted with build_all's
     proven triple (default model, `"closed"`, show) and logged
     (`[zm_qol] BARRIERS: reverted a strand ...`). The swarm then re-tears it normally.
     15 s is far longer than a real single-piece tear (~1 s per chunk_health point).
4. **`mod.json`** — `2.18.2` → `2.18.3`.

Residual (documented, stock-bounded): an entrance-flow vault through a just-stranded board
is possible for up to 15 s until the healer reverts it; stock leaves it open forever.

## Remaining steps (needs a working shell)

```bat
:: one issue per branch, from the current tree
git status                      :: expect only the 4 files above (+ this handoff)
git stash push -- scripts/zm/zmqol_barriers.gsc mod.json   :: park the barrier half
git checkout -b fix/zombie-ai-fightdist-global
git add scripts/zm/zmqol_ai_fightdist.gsc scripts/zm/locs/loc_common.gsc
git commit -m "Zombie AI: run the fight-distance repair on every map, and keep the watchdog off mid-rip windows"
git push origin fix/zombie-ai-fightdist-global
git stash pop
git checkout -b fix/barrier-strand-heal
git add scripts/zm/zmqol_barriers.gsc mod.json
git commit -m "Barriers: count a mid-rip board as standing, and revert tear pieces no zombie will finish"
git push origin fix/barrier-strand-heal
:: merge both into the tree you build, then:
build.bat
```

(`build.bat` offline if a deploy audit is in progress; the gates — perk popup, weapon ports,
hotload — all run inside it. None of this touches perk text or weapon assets.)

## Live verification checklist (Farm or any non-loc survival location)

- Boot Farm survival, console shows `[zm_qol] loc_common::init reached` absent but the
  watchdog live: spawn a zombie, `getaiarray`-free check is the log line itself —
  `[zm_qol] zombie AI: restored pathenemyfightdist to 64 ...` appears within seconds of a
  broken zombie (force one: shoot a zombie climbing a window so its thread dies mid-sequence).
- Tear a window with a zombie, kill it mid-rip (shoot through the boards), wait 15 s:
  `[zm_qol] BARRIERS: reverted a strand opening piece ...` and the board is standing again;
  the next zombie tears it normally and does NOT vault through.
- With a board mid-rip, a retargeted zombie outside does not come through the window.
- Sanity on one loc arena (Church/Docks): exactly one watchdog (no double repair lines per
  second), Carpenter still drops, rebuilds still re-gate.

## Why this session could not finish

The DSH sandbox failed to grant write on the workspace for every shell spawn (Win32 5 on
`SetNamedSecurityInfoW`), so git/build/deploy/game were all unreachable; the approved
one-shot ACL repair could not run for the same reason (the harness fails before executing
anything). The `diagnose-windows-sandbox-acl` report was never produced for that reason.
A prior incident with the same signature on `modding-jobs` was repaired on 2026-10-11
morning (checkpoint 296) — the workspace copy may need the same treatment before the next
build attempt.
