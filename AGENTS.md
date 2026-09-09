# Quality Of Life: project instructions

Read the workspace `../../../AGENTS.md` first. Project-specific references are
in the sibling `../zm_qol - dev/AI_CONTEXT.md` and `../zm_qol - dev/CLAUDE.md`.
Read the latest checkpoint in `../zm_qol - dev/.agents/` and preserve outstanding
gameplay checks. These are local development references, not release payloads.

- Check `git status` before editing; preserve existing user work.
- Keep `main` stable. Perform fixes and features on short-lived task branches, and do not merge them until their required offline and gameplay checks pass.
- Keep each commit limited to one coherent task. Separate unrelated existing changes instead of silently combining them.
- Run the relevant checks again from the merged `main` commit before treating a change as released.
- The five mod files are `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, and
  `mod.all.sabs`. Raw GSC/Lua sources are packed into `mod.iwd`.
- `build.bat offline` packs and verifies locally. `build.bat` without arguments
  also installs and reconciles global Plutonium overrides. Do not run deployment
  during an offline audit.
- `build_ff.bat` retains the legacy `tools/oat-windows` pipeline. Its active
  recipe is `zone_source/mod.zone`; the empty root `mod.zone` is unused.
  Preserve donors and untracked asset sources. Do not retrofit a JSON recipe.
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
