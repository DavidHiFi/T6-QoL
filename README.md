<div align="center">

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/32a1cfbd-7ece-4a91-9690-82691bed24b1" />

# Quality Of Life

**A quality-of-life overhaul for Call of Duty: Black Ops II Zombies on [Plutonium](https://plutonium.pw).**

More guns in the Mystery Box, DLC5 wonder weapons, new Survival maps, and an in-game options menu.

<a href="https://github.com/DavidHiFi/T6-QoL/releases/latest">
<img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F%20DOWNLOAD%20LATEST%20RELEASE-2EA043?style=for-the-badge&labelColor=161B22" alt="Download the latest release" height="42">
</a>

<br><br>

<img src="https://img.shields.io/github/v/release/DavidHiFi/T6-QoL?style=flat-square&label=version&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/github/downloads/DavidHiFi/T6-QoL/total?style=flat-square&label=downloads&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/badge/platform-Windows-5865F2?style=flat-square&labelColor=161B22">

</div>

---

## Installation

Install Plutonium and run it once so its folders exist, then close it.

1. [Download the latest release](https://github.com/DavidHiFi/T6-QoL/releases/latest) and unzip it anywhere.
2. Run **`Windows Install.bat`**.
3. Choose **INSTALL → The mod** and confirm.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

The installer also offers the HD texture pack, sound pack, controller icons, ReShade, backups, Start menu shortcuts, and a full uninstaller.

### Standalone downloads

| Download | Size | What it is |
|---|---|---|
| [**HD Texture Pack**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/HD.Texture.Pack.zip) | 525 MB | Higher-resolution textures and the animated Pack-a-Punch camo. Drop the `images` folder into `%LOCALAPPDATA%\Plutonium\storage\t6\`. |
| [**Controller Icons**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/Controller.Icons.Pack.zip) | 184 KB | PS5, Switch and Xbox One button prompts. Copy one folder's `.iwi` files into `%LOCALAPPDATA%\Plutonium\storage\t6\images\`. |

<details>
<summary><b>Install by hand (Windows and Linux)</b></summary>

<br>

On **Linux** (Wine, Proton, Lutris, Bottles) install by hand, like any other Plutonium mod.

1. Open the **`Mod Files`** folder in the release zip.
2. Create a folder called `zm_qol` in `%LOCALAPPDATA%\Plutonium\storage\t6\mods\` (the same path inside your prefix on Linux).
3. Copy in `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl` and `mod.all.sabs`.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

</details>

---

## Before you play

> [!NOTE]
> **Still in beta.** Some features have not had a full play-through yet.
>
> Cloning the repo will not give you a playable mod. Grab a [release](https://github.com/DavidHiFi/T6-QoL/releases/latest) instead.

> [!IMPORTANT]
> **Plutonium wipes ReShade every time it launches.** Start the game with **`Play BO2 with ReShade.bat`** and leave its window open while you play.

> [!WARNING]
> **INSTANT EXIT right after FAST RESTART** can throw a `LUI_ERROR` prompt. The cause is inside Plutonium's own scripts, not this mod.

---

## Features

### Weapons

- **Extra Mystery Box guns:** Storm PSR, Dragunov, SPAS-12, SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6, Tac-45.
- **Black Ops 1 guns:** M60 (The Pig), L96A1 (L115 Isolator), Browning HP (Bap), RPG-7 (Rocket Propelled Grievance). Everywhere except Origins.
- **DLC5 wonder weapons:** Wave Gun, Thundergun, Wunderwaffe DG-2, Winter's Howl. Everywhere except Origins and Buried.
- **Faster reloads:** the PaP SPAS-12 loads all 24 shells at once; the Python loads all six.
- **Bouncing Betties:** join the box and share the Claymore slot.
- **Jet Gun:** takes a weapon slot; overheats but never breaks.
- **Starting pistol:** spawn with the map's pistol, M1911, Mauser, or TAC-45.
- **No box limits:** duplicates, both Ray Guns, no wonder-weapon caps. Switch on the GAME tab.

### Perks and power-ups

- **Der Wunderfizz** on every map.
- **No perk limit:** take as many as you want, or cap it between 1 and 12.
- **Perma-perks:** a PERMA-PERKS switch on the GAME tab.
- **Better Speed Cola:** a GAME tab switch for faster windows and perk drinks.
- **Instant Pack-a-Punch:** no wait. Toggle it in settings.
- **Solo Easter Eggs:** run the main quests solo or with fewer than four players.
- **Custom power-ups (GAME tab):**
  - Bonfire Sale: 1,000-point Pack-a-Punch for 30 seconds. Not on Mob or Buried.
  - Blood Money: 1-2,500 points.
  - Zombie Blood: zombies ignore you for 30 seconds. Not on Mob or Buried.
  - Death Machine: the Black Ops 1 minigun.

### HUD and interface

- **Subtitles:** every voice on every map (HUD tab: OFF / SUBTITLES / SUBTITLES + NAMES).
- **Health bar:** bottom left; yellow on damage, red before you go down; shield bar above.
- **Timers and counters:** game and round timers with colours, plus a Cold War round counter.
- **Hitmarkers:** pick your hit, kill, crit and downed sounds, or turn them off.
- **Scoreboard emblems:** each map shows its own crew.
- **Cheats:** god mode, ghost, infinite ammo, infinite sprint, fly, rapid fire, one shot, no power, round jumps, points, teleport.
- **Options:** everything is configurable in game, no console needed.

### Presentation

- **Animated Pack-a-Punch camo:** Dark Matter on every upgraded gun. Needs the HD Texture Pack; off uses stock camo.
- **Ray Gun model:** the Buried and Origins model on every map.
- **Third person:** camera behind you (GAME 3 tab).
- **Knife lunge:** off means no melee pull (GAME 3 tab).
- **Extras:** tap-to-interact controller support and a Cinematic Colour Grading ReShade preset.

---

## Maps

Nine added Survival starts, plus a few tweaks you only get on one map.

### TranZit

- **New starts:** Diner, Power Station, Tunnel.
- **Diner:** Pack-a-Punch on the roof, restored wall buys, riot shield buildable, teddy bears.

### Die Rise

- **New starts:** Shopping Mall, Dragon Rooftop, Sweatshop.
- **Sliquifier:** can be Pack-a-Punched, kills at any round.
- **Semtex wall buy.**

### Mob of the Dead

- **New start:** Cell Block.
- **Final Flight:** can be done solo.

### Buried

- **New start:** Borough.
- **Borough:** seven perk machines, Vulture Aid through the Wunderfizz.

### Origins

- **New start:** The Crazy Place.
- **Crazy Place:** four wall buys, four floating perk bottles that shuffle, Pack-a-Punch. No box or Wunderfizz inside.

### Nuketown

- **Hellhound rounds:** missing sounds and effects restored.
- **Teleports:** the three destinations are the map's own respawn points.

---

<details>
<summary><b>In-game chat commands</b></summary>

<br>

Use a `.`, `!` or `/` prefix, or bind them to keys. Type `.help` for the current list.

```text
.help                     Show / hide the in-game command list
.give <weapon> [pap]      Give any weapon ('.give list' shows what's available)
.round <n> / .endround    Set or skip the current round
.god / .ghost / .fly      Invincibility, noclip, flight
.infammo / .infsprint     Infinite ammo and sprint
.pack / .unpack           Pack-a-Punch or unpack the held weapon
.giveperks / .removeperks Grant or remove perks
.pay <player> <amount>    Send points to another player
.character <1-4>          Pick your own character
.shield / .staff <elem>   Spawn a shield or an Origins elemental staff
```

</details>

---

<details>
<summary><b>Building from source</b></summary>

<br>

Run `build.bat offline` to repack and check the mod files locally. `build.bat` on its own also deploys the mod and refreshes the installer bundle.

Asset changes use `build_ff.bat`, which needs untracked asset sources and donor files. The root `mod.zone` is unused; `zone_source/mod.zone` is the active recipe. A clean pack does not prove the mod runs.

</details>

---

## Support the project

The mod is free and always will be. Any amount of support is greatly appreciated, and I do sincerely hope you enjoy my little project. :-)

[![Support DavidHiFi on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/davidhifi)

---

## Credits

**Author:** [DavidHiFi](https://github.com/DavidHiFi)

| Who | What |
|---|---|
| **Synarxis** | Inspiration. This project would not exist without their support. |
| **sehteria** | T6-ZM-Expanded, the mod this one grew out of. |
| **SadSlothXL** | The Death Machine power-up: the drop, the weapon swap and its sounds. |
| **Logo2K** ([Zombies Declassified](https://github.com/Logo-2K/zombies-declassified)) | The native T6 Wave Gun package: Treyarch's DLC5 models, animations, effects, weapon defs, sounds and script. |
| **Jbleezy** ([BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined)) | The extra Survival locations, the Bouncing Betty carry animations, the two lines that let Pack-a-Punch take the Sliquifier, and confirming the checks between a solo player and Mob of the Dead's Final Flight. |
| **5and5** ([BO2-Remix](https://github.com/5and5/BO2-Remix)) | The Die Rise Semtex wall buy. |
| **Fraaagaaa** ([Strat Tester](https://github.com/Fraaagaaa/Strat-Tester-BO2)) | Every teleport destination except Nuketown's three, which are the map's own respawn points. |
| **B2ORG** ([T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH))<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The basis for most of the patches, rebuilt against the game's own scripts. |
| **Hadi77KSA** ([Any Player EE Scripts](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts))<br><sub>building on work by **CCDeroga**, **teh_bandit**, **DaddyDontStop**, **shyperson0/znchi** and **Stick Gaming/Nathan3197**</sub> | The Solo Easter Eggs option. |

Built on [Plutonium](https://plutonium.pw), with **OpenAssetTools** and **xensik**'s **gsc-tool**. The optional ReShade install ships unmodified work by **crosire** ([ReShade](https://reshade.me)), **Barbatos Bachiko**, **Alex Tuduran**, **Marot Satil** and the **GShade** project, **Ioxa**, **Lord of Lunacy**, **prod80**, and **NVIDIA**.

> Missing or wrong credit? Open an issue and it will be fixed.

---

## How this was made

Most of this mod's code was written with AI coding assistants (Claude Code, OpenCode and others). All artwork is human-made. I am not a programmer and have never claimed to be. The project started as something for me to play, and I opened it up because other people might get some use out of it.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
