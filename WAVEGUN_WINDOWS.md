# Wave Gun: Windows stock-map work

Target: T6-QoL, starting at `34e61b2`, on TranZit, Nuketown, Die Rise and Mob
of the Dead. The existing Buried/Origins exclusions still apply.

## Implemented

- Each firing thread owns its enemy list, impulse vectors and pacing counter.
  The three network-frame waits after every tenth target no longer expose
  that shot's arrays to another player's firing thread. Recheck target
  existence after the waits and stop dispatching if the shooter disconnects.
- Wave Gun FX handles live in `level.zmqol_mgun_effects`, so a map resetting
  `level._effect` cannot remove them. Effect names and gameplay values are unchanged.

The changed server script compiled with the installed Windows gsc-tool through
CoD Modding Tools. This is compile validation, not multiplayer or gameplay
acceptance. The development package uses the existing fastfile and sound banks;
it does not contain a new swelling renderer.

## Swelling remains unfinished

The provided historical handoff describes a different Der Riese implementation:
ten-stage server visuals in a standalone repository, then 60 body stages and
20 stages per head in Arsenal. Neither implementation, its generator, nor its
acceptance record was found in this workspace. T6-QoL's client script currently
only registers the box weapons; its server uses the instant-burst fallback on
stock maps. The handoff's gameplay acceptance does not apply to this checkout.

Stock-map work needs native death-animation registration on both AIType sides,
matching animation-tree/state-definition assets, early matching actor fields,
and a cosmetic renderer with animation-phase synchronization and independent
cleanup. Generated geometry must cover each map's actual bodies and attached
heads, preserve absent limbs/heads, and fit the remaining model budget. Do not
register 60 stages for every stock body without measuring that budget.

Local stock model exports exist under `t6/assets/All BO2 Zombies xModels
(.MA, .OBJ, .XE, .SMD)`. They are inputs for new asset work, not the accepted
generated models. Some exported material names use a `bo2_` prefix and need
mapping back to actual T6 material identities before linking.

The normal OAT backend failed to extract Moon's development fastfile with a
zero-sized delayed block. The existing separate `tools/oat-dlc5` backend, with
its documented `OAT_MIN_BLOCK_MB=384`, successfully extracted the raw files.
No backend was changed or repointed. The recovered `zm_moon_basic.asd` and
`.atr` contain the twelve microwave sizzle death animations and zap states.
Existing experimental stock animtrees in `zone_assets` are deliberately
undeclared; they have not been enabled by this work.

## 2026-09-09 (later session): the model-swap route was costed, and rejected on count

The handoff's third route — don't deform the model, **replace** it with pre-expanded
stages — is the only one of its three that clears both blockers above. It was accepted
in game on Der Riese. It still does not survive the port, and the reason is arithmetic,
not opinion:

- Der Riese was **one body family plus four heads** and still hit `G_ModelIndex:
  overflow` at 301 models, forcing the cut to 60 + 4x20.
- Stock is not one family. `c_zom_zombie*` resolves to **468 distinct names** across the
  shipped scripts, and every base body carries **seven gib forms** (`_g_larmoff`,
  `_g_legsoff`, `_g_llegoff`, `_g_lowclean`, `_g_rarmoff`, `_g_rlegoff`, `_g_upclean`).
  A zombie that has lost an arm renders as its gib form, so those need swell stages too
  or it snaps back to intact mid-burst.
- Counted from `t6\assets\All BO2 Zombies xModels`: TranZit **10 base bodies + 4 heads**,
  Die Rise **8 + 5**, Mob **5 heads** (bodies under a non-`c_zom_zombie` prefix),
  Nuketown reuses TranZit's set.
- TranZit alone, at the handoff's own 10-stage fidelity: 10 x 8 forms x 10 = **~800 new
  models for one map**. At Arsenal's 60 stages, **~4,800**. Against a budget that already
  overflowed at 301, on a mod that is already at the weapon-table ceiling on Origins
  (checkpoint 246).

Not attempted. If it is ever revisited it needs a fidelity/scope decision first, not
more asset work.

## The fourth route: `setscale()` on the actor — boot-tested and rejected

The experimental actor-scale route compiled, but the clean TranZit boot on 2026-09-09
settled the question: this engine rejected `setscale` as an unresolved external while
loading `scripts/zm/zapgun.gsc`, before any dvar gate could run, and shut the server down.
The entire route was removed. Keeping even a disabled call would make every map unloadable.

## Final stock-map fallback in v2.15.14

The runnable fallback now supplies every effect the stock-map engine can support without
the missing DLC5 actor state/material: the microwave sizzle alias, eye-blood effect, a
brief held corpse, the spine mist, the original pop variants, and deterministic death and
cleanup. The combined/split weapon flow, upgraded forms, per-shot targeting, denizens,
damage callbacks and Pack-a-Punch registration remain intact.

It does **not** float or inflate stock-map zombies. That visual is not honestly claimable:
the float is the absent `zm_death_sizzle` actor animation state and the inflation is Moon's
DLC5 swell renderer. The two practical substitutes were rejected by evidence above:
pre-expanded models exceed the model index by hundreds on TranZit alone, and actor scaling
prevents the map from loading. This limitation must stay explicit in release notes rather
than being presented as the original Moon visual.

## Local evidence

All paths below are relative to `H:/Plutonium/modding-jobs`:

- `wavegun-stock-compile-001`: unchanged baseline script compilation.
- `wavegun-stock-compile-002`: repaired server script compilation.
- `wavegun-stock-evidence`: command responses and exit codes.
- `wavegun-moon-raw-001`: retained standard-OAT failure and receipt.
- `wavegun-moon-legacy-raw-001`: patched-donor extraction and log.
- `wavegun-swell-compile-001`: the swell change compiling, exit 0.
- `wavegun-swell-probe-001/-002`: the invented-builtin probe that shows a clean
  compile does not validate builtin names.
- `final-audit-20260909-001/audio-sizzle-001`: the shipped sizzle payload inspected as
  PCM 48 kHz mono, 4.775292 seconds.
- `final-audit-20260909-001/compile-audit-harness-003`: the temporary live-audit harness
  compiled before deployment. The harness was removed before the release build.
- The final clean TranZit audit reported PASS for the loaded sizzle alias and for a live
  actor traversing the sizzle/burst/death path; it also stayed running under the original
  process. The console transcript and screenshots are retained under the same audit root.

The final audit launched its own throwaway Plutonium session, installed the test build,
loaded the mod from the menu, loaded TranZit, and checked fresh engine state and logs.
Audio audibility, co-op concurrency and horde-scale visual performance remain human
acceptance items; the asset, callback and single-live-target paths are verified.
