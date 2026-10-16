# Contributing

Thanks for helping T6 QoL. The mod is GSC for Call of Duty: Black Ops 2 on Plutonium, so most testing happens in game.

## Ways to help

- Report in-game bugs with the mod settings involved
- Send GSC fixes
- Test changes across the game modes the mod touches

## Getting set up

From the repo root, `build.bat offline` repacks and verifies without installing. `build.bat` builds, deploys and runs the installer, and `build_ff.bat` rebuilds texture assets (it may need donor files that are not tracked here). If the game crashes, `save_crash_log.bat` collects a log.

## Checks before a pull request

- Run `build.bat offline` so the repack verifies
- Test in game on Plutonium; desktop-only checks cannot prove a GSC change

## Where to submit

Open issues and pull requests in this repository.