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

## Local evidence

All paths below are relative to `H:/Plutonium/modding-jobs`:

- `wavegun-stock-compile-001`: unchanged baseline script compilation.
- `wavegun-stock-compile-002`: repaired server script compilation.
- `wavegun-stock-evidence`: command responses and exit codes.
- `wavegun-moon-raw-001`: retained standard-OAT failure and receipt.
- `wavegun-moon-legacy-raw-001`: patched-donor extraction and log.

No game, launcher, or vendor GUI was launched. Nothing was installed into
Plutonium. Installation, startup, swelling, blood, sound, co-op and horde
performance acceptance remain outstanding for this development work.
