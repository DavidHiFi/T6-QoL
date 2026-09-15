# Quality Of Life: project instructions

Read the workspace `../../../AGENTS.md` first. Project-specific references are
in the sibling `../zm_qol - dev/AI_CONTEXT.md` and `../zm_qol - dev/CLAUDE.md`.
Read the latest checkpoint in `../zm_qol - dev/.agents/` and preserve outstanding
gameplay checks. These are local development references, not release payloads.

- Check `git status` before editing; preserve existing user work.
- One branch per issue, always on GitHub (workspace `AGENTS.md`, user
  2026-09-11): create the `fix/...` branch before editing, commit only that
  issue's files, push it to `origin`. Never stack issues on one branch.
- The five mod files are `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, and
  `mod.all.sabs`. Raw GSC/Lua sources are packed into `mod.iwd`. A build that
  ships extra files alongside these (a bundled custom map, say) is off the
  mainline — check what put them there before treating it as the norm.
- The hellhound location deny-list exists TWICE and the copies must agree:
  `zmqol_enable_dog_rounds()` in `scripts/zm/quality_of_life.gsc` makes the
  server refuse the round, and an `excludeLocations` filter in
  `ui_mp/t6/menus/privategamelobby_project.lua` removes the lobby row. Both
  currently read tunnel, diner, cornfield, power. Change one and you must
  change the other: GSC alone leaves the user a switch that does nothing, Lua
  alone leaves a hidden option the server would still honour.
- `scripts/zm/quality_of_life.gsc` is ON A COMPILED-BYTECODE CEILING. Adding
  code to it breaks unrelated functions with `Unresolved external` at map load,
  and the symbol the engine names is never the one you touched. Put new
  behaviour in its own raw script under `scripts/zm/` that installs itself from
  its own `init()`. Full rule and measurements: workspace `AGENTS.md` item 1b.
- THIS MOD IS ALSO AT THE ENGINE'S WEAPON-ASSET CEILING. Adding weapon defs
  crashes map load: `0xC0000005`, with `last gsc error message 'unknown weapon
  <some other gun>'` inside `zmqol_include_variant` / `zmqol_mp_weapons_init`.
  Measured 2026-09-15, twice, deterministically, by adding 20 defs. As with the
  bytecode ceiling the gun the engine names is NEVER the cause — it is whatever
  was being registered when the pool ran dry. Do not add weapon assets without
  freeing slots first; replace names, or choose the files before the game starts
  (installer / Optionals) where the count never changes.
  🛑 `Loaded weapon:` counts in a rotated console log are NOT per-load and will
  mislead you — one log with 351 of them ended normally. Read the crash dump:
  `%LOCALAPPDATA%\Plutonium\crashdumps\*.txt` names the gsc error and callstack.
- ANY NEW MENU ROW WHOSE "ON" STATE CAN FAIL AT LOAD IS A CRASH LOOP, because
  QoL rows archive. `seta <dvar> "1"` persists into
  `storage\t6\players\mods\zm_qol\plutonium_zm.cfg`, so one flip keeps crashing
  across restarts and clearing it means editing that file, not just the script.
  Gate such a feature in code, or do not ship the row.
- `build.bat offline` packs and verifies locally. `build.bat` without arguments
  also installs and reconciles global Plutonium overrides. Do not run deployment
  during an offline audit.
  🛑 NEVER run deployment while the game is running: replacing the ~190 MB
  `mod.iwd` under a live process kills it mid weapon-load with no crash
  signature. Its `[9/9]` step also moves loose probe scripts out of
  `storage\t6\raw\scripts\` into `storage\t6\backups\raw-foreign-parked\`, which
  will silently remove another session's hotload probe.
- `build_ff.bat` retains the legacy `tools/oat-windows` pipeline. Its active
  recipe is `zone_source/mod.zone`; the empty root `mod.zone` is unused.
  Preserve donors and untracked asset sources. Do not retrofit a JSON recipe.
- For GSC/CSC experiments, hotload first: drop a loose probe script under
  `%LOCALAPPDATA%\Plutonium\storage\t6\raw\scripts\` (mirroring the mod's
  `scripts\zm\` layout) and reload the map — no `build.bat`, no mod edit.
  Full rule in the workspace `AGENTS.md` ("GSC hotload"). Delete the probe
  when done; stale loose scripts shadow the mod on every boot.
- Keep the bundled JSON toolchain separate. Its offline verification outputs
  belong under the workspace `modding-jobs/`, outside source/include trees.
- `* -text` in `.gitattributes` is intentional. Preserve binary data and source
  line endings; Windows batch scripts use CRLF.
- Do not infer duplicate files are disposable: donor assets, staged client
  scripts, runtime image pixels, and UI files under both lookup roots can each
  have distinct roles.
- Do not introduce map-specific references into global `scripts/zm/` scripts.
- Keep developer-specific paths out of shipped source comments and UI text.
- Record build, installation, startup, gameplay and performance separately.
  Successful offline checks do not close gameplay items in the queue.
