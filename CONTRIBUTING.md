# Contributing

Thanks for helping Quality Of Life. It is a Black Ops II Zombies mod for Plutonium, so most testing
happens in the game. The rules every contributor and every AI agent follows are in
[AGENTS.md](AGENTS.md); this page walks through them.

## Report a bug

Open an issue with the **Bug report** form. The most useful reports include:

- the version from the Mods menu
- map, mode and location
- solo or co-op, and how many players
- which settings you changed
- the steps that make it happen

For a crash or script error, the game's console log is
`%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`. In a checkout, `save_crash_log.bat`
copies it into `../zm_qol - dev/crashlogs/`, beside the checkout. Before posting, paste only the lines
around the error. Remove your Windows user name, folder paths, IP addresses and
other players' names.

## Before you start work

- Find or open an issue for the change and comment that you would like to take it. A maintainer
  assigns it, so only one person works on each issue.
- Check the open pull requests. If one already touches the same files or the same bug, say so on the
  issue first.
- Changes to the shared hub files (`scripts/zm/quality_of_life.gsc`, the build scripts, the zone files,
  the installer, the lobby menu) need a word on the issue before you start.

## Set up

You need Windows, Windows PowerShell and Python 3 on `PATH`.

- `build.bat offline` repacks `mod.iwd` and runs the checks without installing anything.
- `build.bat` also installs the build into your Plutonium folder.
- `build_ff.bat` rebuilds `mod.ff` and the sound banks. It needs OpenAssetTools' Linker (`OAT_BASE`) and
  a Black Ops II install (`BO2_DIR`).

The Wave Gun swell needs the owner's patched Linker.

**A fresh clone cannot build by itself.** The built `mod.ff`, `mod.all.sabl` and `mod.all.sabs` are not
in Git, and `build.bat offline` stops without them. Run `build_ff.bat`, or copy those three files from
the `Mod Files/zm_qol` folder of the release zip that matches `main`. If none matches, ask on your issue.
[AGENTS.md](AGENTS.md#building-and-checking) shows which build each kind of change needs.

**On Linux**, the build scripts do not run, but the Python checks in `tools/` do. To play a build, install
it by hand (README, "Install the mod by hand").

## Make a pull request

If you are not a maintainer, work from a fork:

1. Fork the repository, clone your fork, and add this repository as `upstream`.
2. Start a branch from the latest `main`:
   `git fetch upstream` then `git switch -c fix/short-name upstream/main`. Use `fix/`, `feature/`,
   `docs/` or `chore/`.
3. Commit only the changes for that issue. Do not convert line endings. `.bat` files must stay CRLF.
4. Push to your fork, open a pull request against `main` here, and mark it as a draft until it is ready.
5. Fill in the template. Before asking for review, merge the latest `main` into your branch.

Maintainers branch inside this repository and follow the same steps. They also follow the review rules
in [AGENTS.md](AGENTS.md#how-a-change-reaches-main).

Use GitHub's own draft state rather than writing "draft" in the description.

## What "tested" means here

A pull request reports three things separately:

- **Built**: the build finished and its checks passed.
- **Loaded**: a map started with the build and the console showed no script errors.
- **Played**: someone did what the change affects in the game and it worked.

Each one says which commit, map, mode and settings were used. Anything not tried is written as **not
tested** with the reason, and a section that does not apply (a docs-only change, say) says **not
applicable**. A build that passes does not prove gameplay.

## Using AI agents

Agents are welcome; most of this mod was written with them. Agents follow [AGENTS.md](AGENTS.md), and
`.claude/CLAUDE.md` loads it for Claude Code. Say in the pull request which agent did the work. You are
responsible for what your agent submits: read its summary, run the checks that apply, and say what
was not tested and why before asking for review.

## Review and merge

The maintainers are DavidHiFi (owner) and SickoHours. The proposed rule (see AGENTS.md) is that every
pull request, including a maintainer's, gets an approval from a maintainer who did not write it. DavidHiFi has the final say on what goes into
the mod. Maintainers merge with GitHub's merge button.

## Credit and license

The mod is MIT licensed, and contributions are accepted under the same license. If a change uses
someone else's work, it must have their permission or a compatible license. Add them to the Credits
table in the README in the same pull request.
