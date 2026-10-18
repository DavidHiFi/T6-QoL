# T6-QoL: rules for every agent

These are the rules for any AI agent working on this repository: Claude Code, Codex, OpenCode or any
other, whoever it works for. `.claude/CLAUDE.md` only imports this file. If a rule here is wrong, fix it here
in a pull request. Do not keep a private copy that disagrees: the other maintainer's agents cannot see
your machine, so a rule that lives only in your notes does not exist for them.

People-facing contribution steps are in `CONTRIBUTING.md`. This file is the single source of rules.

## Who decides

- **DavidHiFi** owns the repository and the mod. He has the final say on direction, on what ships and
  on releases.
- **SickoHours** is a maintainer with write access.
- **Outside contributors** work from forks (`CONTRIBUTING.md`).
- **People decide; agents do the work.** An agent does not change the mod's direction, merge, approve,
  publish a release, change repository settings, or close someone else's issue or pull request unless
  its own person tells it to in that session.
- Agents work through their person's GitHub account and say in the pull request that an agent did the
  work.

The repository is public and players install from Releases. Keep `main` in a state a maintainer would
be willing to release.

## Words with a specific meaning here

- **main**: the shared branch. Nothing is pushed to it directly.
- **Draft PR**: GitHub's draft state. Writing "draft" in the description does not make a PR a draft.
- **Built**: a build script finished and its gates passed. It says nothing about the game.
- **Loaded**: the game started a map with this build and the console showed no script errors.
- **Played**: someone did the in-game actions the change affects and saw the expected result.
- **The five mod files**: `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, `mod.all.sabs`, the core of
  a player's `mods/zm_qol` folder. A development deploy also writes `deployed-by.txt` and may fill its
  `images/` folder; texture installs are in `README.md`. Anything else found there (a bundled custom
  map, say) is off the mainline: find out what put it there before treating it as normal.
- **Gate**: a check under `tools/` that a build script runs and that stops the build when it fails.
- **Donor**: a tracked fastfile or sound bank under `zone_source/` that the build copies assets out
  of, because no other source for those assets exists. Losing one loses the mod.
- **Zone file**: a `zone_source/*.zone` recipe naming what `build_ff.bat` links into `mod.ff`.

## Where things live and which build ships them

| Path | What it is | Ends up in | Built by |
|---|---|---|---|
| `scripts/zm/*.gsc`, `maps/mp/` | server scripts (`quality_of_life.gsc` is the main one; per-map code goes in `scripts/zm/zm_<map>/` and `scripts/zm/locs/`) | `mod.iwd` | `build.bat` |
| `*.csc` under `scripts/` and `clientscripts/` | client scripts | `mod.ff` (`build_ff.bat` stages the current copies) | `build_ff.bat`, then `build.bat` |
| `ui/`, `ui_mp/`, `weapons/`, `aitype/`, `fx/`, `xanim/`, `attachmentunique/`, `images_menu/` | menus (Lua) and raw assets (full list in `pack_iwd.ps1`) | `mod.iwd` | `build.bat` |
| `zone_source/` | zone files and donors; `zone_source/mod.zone` is the active recipe | `mod.ff` | `build_ff.bat` |
| `zone_assets/`, `soundbank/`, `sound/` | materials, images, sound aliases and audio the Linker reads | `mod.ff`, `mod.all.sabl`, `mod.all.sabs` | `build_ff.bat` |
| `tools/` | gates, the weapon-port tools (`tools/port-weapon/README.md`), the port contract file | not shipped | - |
| `installer/` | the release installer (`installer/Windows Install.bat`) | the release zip | by hand at release |

Anything a zone file declares is linked into `mod.ff`. Check with `grep -n "<path>" zone_source/*.zone`
before choosing a build.

## Before you edit

1. Read this file. Run `git status` and keep anything you did not make.
2. Start a branch from the latest shared `main` in a checkout that only this task uses (its own clone
   or `git worktree add`). Two agents never share a checkout. Maintainers work in this repository:
   `git fetch origin`, then branch from `origin/main`. In a fork, `origin` is the fork: add this
   repository as `upstream`, `git fetch upstream`, and branch from `upstream/main`.
3. Check for overlap: `gh pr list --state open` and `gh issue list`. If an open PR or issue covers the
   same bug or the same files, stop and tell your person. The maintainers agree on the order first.
4. The work needs an issue with one assignee. Maintainers assign themselves; outside contributors ask.
5. Say in the issue before you start if you will change one of the files where parallel work collides:
   `scripts/zm/quality_of_life.gsc`, `build.bat`, `build_ff.bat`, `zone_source/*.zone`,
   `installer/Mod Files/qol-installer.ps1`, `ui_mp/t6/menus/privategamelobby_project.lua`.

## How a change reaches main

Status: SickoHours proposed these steps and the version and release rules below on 2026-10-17, and
DavidHiFi has not yet confirmed them. Follow them unless DavidHiFi says otherwise; he may change them by
PR.

1. **One issue, one branch, one PR.** Name the branch `fix/`, `feature/`, `docs/` or `chore/` plus a
   short slug. A fix lives in exactly one PR. (PR #18 carried the same EMP fix that PR #20 merged.)
2. **Open a draft PR** after the first commit and fill in the template.
3. **Commit only this issue's files.** No reformatting, renames or cleanup on the side; open an issue
   for those.
4. **Stay current with main.** Merge the latest shared `main` (`origin/main`, or `upstream/main` in a
   fork) into your branch before asking for review, and again whenever it moves. Do not rebase a branch someone else may have pulled.
5. **Resolve conflicts by keeping both changes.** Never take one side wholesale on a file you did not
   write. Afterwards, confirm the other side's change is still there and rerun the gates. List each
   conflicted file in the PR and how you resolved it. Merges here have silently dropped finished fixes
   before (`df6ae7ff`, `5f81a03c`, and the fix PR #20 had to restore).
6. **Restoring a lost fix?** Cite the commit it originally came from.
7. **Mark the PR ready** when Built, Loaded and Played are each filled in with a result, "not tested"
   and the reason, or "not applicable" (a docs-only change, for example).
8. **The other maintainer approves before merge.** Their agent reviews in a fresh session that did not
   write the change: it reads the whole diff, runs the gates it can, checks the PR's claims against the
   code, and posts its findings as a PR review. Their person decides whether to approve.
9. **Merge with GitHub's merge button** after approval, when the author's person says so. Then delete
   the branch.
10. **Urgent exception:** DavidHiFi may merge a fix for a broken published release before review. The
    PR says so, and the review happens afterwards.
11. **Never** push to `main`, push a merge commit made locally onto `main`, or force-push `main` or
    someone else's branch. Force-push your own branch only while nobody has reviewed it.
12. **Versions:** a normal PR does not change the version in `mod.json`. The release-prep PR bumps it.

GitHub can enforce part of this: required pull requests, a required approval, dismissal of stale
approvals and no force pushes. Those are repository settings only the owner can change.
`.github/CODEOWNERS` only *requests* a review from the other maintainer, and does so only when a PR
is marked ready.

## Rules the code depends on

Each of these cost a broken build or a defect players saw.

- **`scripts/zm/quality_of_life.gsc` is at a compiled-size ceiling.** Adding code to it breaks
  unrelated functions with `Unresolved external` at map load, and the symbol the engine names is never
  the one you touched. Put new behaviour in its own script under `scripts/zm/` that installs itself
  from its own `init()`.
- **The hellhound location deny-list exists twice and both copies must match:**
  `zmqol_enable_dog_rounds()` in `scripts/zm/quality_of_life.gsc` (the server refuses the round) and
  the `excludeLocations` list in `ui_mp/t6/menus/privategamelobby_project.lua` (the lobby hides the
  option). Both name tunnel, diner, cornfield and power. Changing only one leaves either a switch that
  does nothing or a hidden option the server still honours.
- **The perk pop-up text is pinned.** The titles and descriptions in `getPerkName()` and
  `getPerkDesc()` in `scripts/zm/quality_of_life.gsc` were approved on screen and are locked
  word-for-word by `tools/check-perk-popup.ps1`, which `build.bat` runs first. Change them only when a
  maintainer asks, and update the gate's table in the same commit. Never bring back "Double Tap 2.0",
  "Jugger-Nog", "Vulture Aid Elixir" or Jugg's "100 to 250". (`scripts/zm/wunderfizz.gsc` has its own
  `getPerkName()`; it is not the pinned one.)
- **No `%` in any `settext` string.** The game drew "33%" as "33.".
- **Raw weapon files under `weapons/zm/` stay under 20,480 bytes.** Plutonium refuses larger ones, and a
  box weapon that names a refused file can crash the map (`build.bat` step [0/9]). Trim a new file rather than adding it to the gate's
  exception list.
- **No map-specific references in global `scripts/zm/` scripts.** Map code goes in the per-map folders.
- **Line endings are never converted.** `.gitattributes` is `* -text`, so Git stores bytes as they
  are. Keep each file's existing endings; they are mixed even within one file type. Every `.bat` must
  stay CRLF: an LF-only `build_ff.bat` would not run (`961212cb`). After editing a file, compare
  `file <name>` with the copy on `main`.
- **Build outputs are never committed:** the root `mod.ff`, `mod.iwd`, `mod.all.sabl`, `mod.all.sabs`,
  their copies under `installer/Mod Files/`, `Optionals/` and the other outputs `.gitignore` lists.
  GitHub rejects files over 100 MB. The donors under `zone_source/` *are* tracked inputs: change one
  only on purpose and say why in the PR.
- **Do not treat duplicate-looking files as disposable.** Donor assets, staged client scripts, runtime
  image pixels and UI files under both lookup roots (`ui/` and `ui_mp/`) can each have a distinct role.
- **`zone_source/mod.zone` is the recipe.** The empty root `mod.zone` is unused.
  `zone_source/mod_base.zone` is generated by `build_ff.bat regen`; do not edit it by hand.
- **No developer paths or personal details** in shipped source comments, UI text or committed files.
- **Try GSC/CSC experiments by hotloading first:** put a loose probe script under
  `%LOCALAPPDATA%\Plutonium\storage\t6\raw\scripts\zm\` and reload the map. No build and no change to
  the mod are needed. Delete the probe afterwards; a loose script left there shadows the mod on every
  boot.

### Weapon ports

Start from `tools/port-weapon/README.md`. Register every port in `tools/weapon-port-contracts.json`
before its first link. `tools/check-weapon-port.py` runs in both build scripts. A port is done only when:

- both forms (normal and `_upgraded`) read with every field, including the upgraded form's
  `attachViewModel*` and `attachWorldModel*`;
- every model, effect, tracer and icon its definitions name is in `mod.ff` or on all six stock maps;
- it has its own camo table, `camo_qol_<gun>`, that no stock zone owns (a map's own copy of a shared
  name wins on that map). Slots 3 (stock Pack-a-Punch, animated camos off), 8 (animated) and 12
  (Origins, animated off) each override every one of the gun's base materials; a slot with no entry
  for a material draws it black;
- every sound alias its definitions and notetracks use is in
  `soundbank/mod.all.aliases.additions.csv`, with its audio in `sound/`;
- someone has played it on a map that is not the donor's: Pack-a-Punched it with animated camos on,
  and again with them off, then fired, reloaded, sprinted and looked at the upgraded gun each time. No
  offline check sees a notetrack or a wrong camo.

## Building and checking

**Needs:** Windows, Windows PowerShell and Python 3 on `PATH`, since `build.bat` runs four Python gates.
`build_ff.bat` also needs:

- OpenAssetTools' Linker, found through `OAT_BASE`. Its default is the owner's own folder, and the
  Wave Gun swell needs his patched Linker.
- A Black Ops II install, found through `BO2_DIR`.

`tools/check-gib-models.py` needs `T6_RAW`, or it skips.

**A fresh clone cannot build on its own.** Since v2.19.0 the built `mod.ff`, `mod.all.sabl` and
`mod.all.sabs` are not in Git, and `build.bat offline` stops at step [3/9] without them. Get them one
of two ways, and say which in the PR:

- run `build_ff.bat`;
- copy them from the `Mod Files` folder of the release zip that matches `main`.

If no release zip matches `main`, ask the owner instead of guessing.

| You changed | Build | Then check in game |
|---|---|---|
| `.gsc`, Lua menus, raw weapon, aitype or fx files | `build.bat offline` | load a map the change affects and do the action |
| `.csc`, or anything a zone file declares | `build_ff.bat`, then `build.bat offline` | the same, plus the asset or sound itself |
| `installer/` | none | run `installer/Windows Install.bat` on Windows and check what it installed |
| docs only | none | check that every path and command you wrote exists |

`build.bat` without `offline` also deploys into the local Plutonium folder and cleans its loose
`raw\scripts`. Run it only on purpose, never during a review.

**On Linux or macOS**, the build scripts do not run. These Python gates do, with `python3`:

- `tools/check-weapon-port.py --source-only`
- `tools/check-betty-parity.py`
- `tools/check-client-fx-precache.py`
- `tools/check-gib-models.py`

The PowerShell gates need `pwsh` and have not been tried off Windows. To play a build, install the
five files by hand (README, "Install the mod by hand").

## Evidence

Every PR records these separately, each with the details that let someone repeat it:

- **Built:** the source commit, whether the working tree was clean, and where `mod.ff` and the banks
  came from (built from this commit, or copied from which release).
- **Loaded:** the map and mode, and the console result.
- **Played:** OS, map, mode, location, solo or co-op, settings changed, actions taken and what
  happened.
- **Performance**, when the change could affect it.

The version string in the Mods menu carries a commit stamp (`tools/stamp-mod-json.ps1`). It is a hint,
not proof: it is stamped even when the binaries are older than the source. When you hand a build to
the other maintainer, include the sha256 of the five files. Anything not tested is written as **not
tested**. A passing build never closes a gameplay problem.

Unfinished work is described in its PR or issue: what is done, what is left, and what is untested. Do
not add new handoff files to the repository root.

## Private notes, logs and secrets

- Personal and machine-specific notes stay outside the repository, or in ignored files such as
  `CLAUDE.local.md`. `.gitignore` lists the ignored names.
- Anything an agent needs to work correctly belongs in this file or under `tools/`, added by PR.
- Never commit credentials, tokens, console logs, crash logs or installer logs.
- In issues and PR comments, paste only the relevant error lines. Remove user names, home folder
  paths, IP addresses and other players' names.

## Releases (DavidHiFi; proposed, see "How a change reaches main")

1. Start from `main` with a release-prep PR that bumps the version in `mod.json`.
2. After it merges, build from that commit and tag it.
3. Attach the mod zip, the HD texture pack and the controller icons.
4. Download the published zip, extract it, and confirm the five mod files and the installer layout
   are there.
5. Open every download link in `README.md`.
6. Note the tag and commit in the release text. (v2.19.1 was published with no zip attached: issue
   #19.)

## When you finish

Tell your person:

- the PR link and what changes for players;
- the Built, Loaded and Played status, and what is not tested;
- anything waiting on the other maintainer.
