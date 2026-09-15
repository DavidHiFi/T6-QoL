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
- `build.bat offline` packs and verifies locally. `build.bat` without arguments
  also installs and reconciles global Plutonium overrides. Do not run deployment
  during an offline audit.
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
