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
- To port a weapon, start with the `port-weapon` skill
  (`H:\Claude\tools\skills\port-weapon\SKILL.md`). It picks the route from what
  source exists: someone's T6 port, a retail zone, another mod, or an extraction
  from any Call of Duty on this PC. `tools/port-weapon/port_weapon.py plan` /
  `apply` does the mechanical half from a T6 raw source tree, and
  `tools/port-weapon/live/` holds the probe, headless capture, deploy and
  installed-build check. The Blast-O-Matic (SadSlothXL, 2026-09-25) went through
  this route and the player accepted it on the first build.
- Every weapon port, map-to-map or game-to-game, is registered in
  `tools/weapon-port-contracts.json` BEFORE its first link. `build_ff.bat`
  runs `tools/check-weapon-port.py` before linking (sources) and after
  (readback of the new `mod.ff` plus image pixels in the client's banks);
  `build.bat` runs the readback again. A port is not done until all of these
  hold, and each item below is a defect a player has already seen:
  - Both forms (normal and `_upgraded`) read with every field, including the
    upgraded form's `attachViewModel*` / `attachWorldModel*`. The Blundergat's
    missing armor attachment drew a screen-filling black block on reload.
  - Every model, effect, tracer and icon a def names is in `mod.ff` or on all
    six stock maps. A missing fx logs one `Could not load fx` line and the gun
    fires with no flash. The Linker copies fx out of a `--load`ed zone; only
    the Unlinker cannot dump them.
  - Its own camo table, named `camo_qol_<gun>`, that no stock zone owns (a
    map's own copy of a shared name wins on that map). Slot 3 (stock PaP,
    animated camos OFF), slot 8 (animated) and slot 12 (Origins OFF) each
    override the gun's own base material. A slot with no entry for the gun
    draws it black.
  - Every sound alias its def and notetracks fire is in
    `soundbank/mod.all.aliases.additions.csv`, with its payload in `sound/`.
  - Then a live test on a map that is not the donor's: pack it with ANIMATED
    CAMOS on and again with it off, fire, reload, sprint, and look at the gun.
    No offline check sees a notetrack or a wrong-looking camo.
