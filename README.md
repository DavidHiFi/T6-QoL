<div align="center">

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/32a1cfbd-7ece-4a91-9690-82691bed24b1" />

# Quality Of Life

**A quality-of-life overhaul for Call of Duty: Black Ops II Zombies on [Plutonium](https://plutonium.pw).**

Campaign and Multiplayer weapons in the Mystery Box, four wonder weapons from the unreleased DLC5, extra Survival locations, and an in-game options menu.

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
4. Launch Plutonium T6, then open **Zombies → Mods → Quality Of Life**.

Arrow keys move, **Enter** chooses, **Q** quits. Installing needs no admin rights and leaves nothing running. The mod files go inside Plutonium's folder, and the optional Start menu shortcuts go in your user Start menu. The installer can also fetch the extras: HD textures, the custom sound pack, controller icons, ReShade, backups, and a full uninstaller.

Start menu shortcuts point at the folder you unzipped to, so keep it somewhere permanent. The uninstall list removes them again.

### Standalone downloads

These work without the mod installed.

| Download | Size | What it is |
|---|---|---|
| [**HD Texture Pack**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/HD.Texture.Pack.zip) | 525 MB | Higher-resolution textures, animated Pack-a-Punch camo, and more. Unzip and drop the `images` folder into `%LOCALAPPDATA%\Plutonium\storage\t6\`. |
| [**Controller Icons**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/Controller.Icons.Pack.zip) | 184 KB | PlayStation 5, Nintendo Switch and Xbox One button prompts. Pick one of the three folders and copy the `.iwi` files into `%LOCALAPPDATA%\Plutonium\storage\t6\images\`. |

<details>
<summary><b>Install by hand (Windows and Linux)</b></summary>

<br>

On **Linux** (Wine, Proton, Lutris, Bottles) there is no automated installer. Install by hand, the same way as any other Plutonium mod.

1. Open the **`Mod Files`** folder in the release zip.
2. Create a folder called `zm_qol` in `%LOCALAPPDATA%\Plutonium\storage\t6\mods\` (on Linux, the same path inside your Plutonium prefix).
3. Copy these five files into it: `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, `mod.all.sabs`. Nothing else is needed.
4. Launch Plutonium T6, then open **Zombies → Mods → Quality Of Life**.

</details>

---

## Before you play

> [!NOTE]
> **The mod is in beta.** Some features have not had a full play-through yet. Anything that turns out broken gets fixed or pulled.
>
> **A clone of this repo is not a playable mod.** `mod.iwd` is a build output and is not tracked in git. Download a release instead.

> [!IMPORTANT]
> **Plutonium deletes ReShade every time it starts.** It clears anything it does not recognise out of its own `bin` folder. Launch with **`Play BO2 with ReShade.bat`** (in `Mod Files`, or as the **Plutonium ReShade Watcher** Start menu shortcut) and leave its window open while you play. It puts ReShade back on each launch. Closing the window uninstalls nothing.

> [!WARNING]
> **Known issue.** Leaving a match with **INSTANT EXIT** right after a **FAST RESTART** can open a `LUI_ERROR` dialog. The fault is inside Plutonium's own `MainMenuOG.lua`, which this mod does not ship or override, so it cannot be fixed from here. **INSTANT EXIT** on its own is unaffected.

---

## Features

### Weapons

**Extra guns in the Mystery Box:** Storm PSR, Dragunov, SPAS-12, SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6 and Tac-45.

**Black Ops 1 classics, with their Pack-a-Punch versions:** M60 (The Pig), L96A1 (L115 Isolator), Browning HP (Bap) and RPG-7 (Rocket Propelled Grievance).

**DLC5 wonder weapons:** the Wave Gun, Thundergun, Wunderwaffe DG-2 and Winter's Howl, ported from the unreleased DLC5.

Origins and Buried leave the DLC5 wonder weapons out of the box, and Origins also leaves out the Black Ops 1 guns because they overran its weapon precache table and stopped the map loading. Every other map has the full set.

**Starting pistol.** A lobby row picks the pistol you spawn with: the map's own, the M1911, the Mauser, or the TAC-45.

**Faster reloads.** The Pack-a-Punched SPAS-12 loads all 24 shells at once, and the Python loads all six rounds at once, which its upgraded version always did.

**Bouncing Betties.** The multiplayer proximity mine joins the box and shares the Claymore slot, so you carry one mine type at a time and either one uses the same equipment button.

**Jet Gun.** Carried as a normal primary that cycles with your other guns instead of living in an equipment slot, so it costs a weapon slot and respects Mule Kick. It still overheats, but it never breaks.

**No box limits.** On by default: the box can hand out duplicates, the Ray Gun Mk 1 and Mk 2 can both appear, and wonder weapons are no longer capped. Turn the switch off for vanilla box rules.

### Perks and power-ups

**Der Wunderfizz on every map.** The random perk machine is available everywhere, not just Origins.

**No perk limit.** Carry as many perks as you like, or set a cap of 1 to 12 in the pre-game lobby.

**Perma-perks.** A **PERMA-PERKS** switch on the GAME tab turns on every permanent perk the map has from the start, with no challenge progress needed. Off by default, Classic only, and it never adds a perma-perk to a map that does not have one.

**Better Speed Cola.** A **BETTER SPEED COLA** switch on the GAME tab. With it on, Speed Cola also boards up windows faster and drinks perk bottles faster.

**Instant Pack-a-Punch.** Cold War style, no wait. Toggle it on or off in the options menu.

**Solo Easter Eggs.** A **SOLO EASTER EGGS** switch in the pre-game lobby on TranZit, Die Rise, Mob of the Dead, Buried and Origins. Turn it on and the main quest scales to the number of players in the lobby instead of always demanding four. On Mob of the Dead that means the Final Flight can be boarded alone, and finishing it awards **Pop Goes the Weasel**; which ending you get still depends on whether you are the Weasel, exactly as it does for a full team. Off by default, and the row only appears on those five maps in Classic.

**Custom power-ups.** A **CUSTOM POWER-UPS** row on the GAME tab switches these drops on or off.

- **Bonfire Sale** (from *Five*): Pack-a-Punch costs 1,000 points for thirty seconds. Every map except Mob of the Dead and Buried.
- **Blood Money**: 1 to 2,500 points to whoever picks it up. Every map.
- **Zombie Blood**: thirty seconds where every zombie ignores you. TranZit, Nuketown, Die Rise and Origins.
- **Death Machine**: the Black Ops 1 minigun power-up. Every map.

### HUD and interface

**Subtitles.** Optional subtitles on every map (HUD tab: OFF / SUBTITLES / SUBTITLES + NAMES). They cover the crew, the announcer, and each map's extra voices, from Maxis and Samantha to Brutus and the bus driver. Lines are machine-transcribed from the game audio, so the odd word can be off.

**Health bar.** A bottom-left bar with your health as a number. It turns yellow once you take damage and red when the next hit would down you, and a carried shield adds its own bar above it.

**Timers and counters.** Game and round timers with configurable colours, plus a Cold War style round counter.

**Hitmarkers.** Pick your hit, kill, crit and downed sounds, or turn hitmarkers off.

**Scoreboard emblems.** The scoreboard shows the crew that belongs to the map you are on. Origins, Buried, Mob of the Dead and Die Rise get their own; Green Run and Nuketown keep the TranZit survivors in Classic and show the character you picked in Survival.

**In-game options menu.** Mechanics, gameplay rules, HUD and audio all have rows in the pause menu, with no console commands needed. That includes a **VOICE LINES** switch for your character's spoken lines.

**CHEATS tab.** Toggles for god mode, ghost, infinite ammo, infinite sprint, fly, rapid fire, one shot one kill and no power needed (perks and doors work without power), plus one-shot rows for changing the round, killing the horde, ending the round, setting points, and teleporting to landmarks on each map.

### Presentation

**Animated Pack-a-Punch camo.** Every upgraded gun gets the *Dark Matter* animated camo on all six maps. Switch it off and each map uses its own stock Pack-a-Punch camo. The textures ship in the [HD Texture Pack](#standalone-downloads), so install that for the option to do anything.

**Ray Gun model.** Black Ops II quietly ships two Ray Guns: the remade model from Buried and Origins, and the older Black Ops 1 model the other maps use. This mod puts the remade model on every map, including the Pack-a-Punched gun, the box, the floor and other players' hands.

**Third person.** A **THIRD PERSON** switch on the GAME 3 tab puts the camera behind your character. Off is the normal view.

**Knife lunge.** A **KNIFE LUNGE** switch on the GAME 3 tab. On is the normal game. Off removes the melee charge that pulls you onto a zombie, so you knife where you stand.

**Extras.** Native tap-to-interact controller support under the standard Gamepad menu, plus a tailored *Cinematic Colour Grading* ReShade preset.

---

## Maps

The mod adds nine Survival starts across the six maps, and a few tweaks that only exist on one map.

### TranZit

- Survival starts: **Diner**, **Power Station** and **Tunnel**.
- Diner is a full build-out: Pack-a-Punch on the roof, the MP5K and Galvaknuckles wall buys switched back on, Semtex and claymore wall buys, the buildable riot shield, and the three teddy bears with the secret song.
- Solo Easter Eggs are available.

### Die Rise

- Survival starts: **Shopping Mall**, **Dragon Rooftop** and **Sweatshop**.
- The **Sliquifier** can be Pack-a-Punched. Treyarch built the upgraded gun, named it the **Sl1qu1f13r**, and left it in the files without connecting it to a machine. The upgraded one kills at any round, because the goo and its chain reaction ignore zombie health. The unpacked Sliquifier is untouched.
- A Semtex wall buy.
- Solo Easter Eggs are available.

### Mob of the Dead

- Survival start: **Cell Block**.
- Solo Easter Eggs are available. The Final Flight can be boarded alone, and finishing it awards **Pop Goes the Weasel**; which ending you get still depends on whether you are the Weasel, exactly as it does for a full team.
- No Bonfire Sale or Zombie Blood drops here. Its clientfield budget is full.

### Buried

- Survival start: **Borough**.
- Borough is rebuilt from script: seven perk machines placed by the mod, Vulture Aid handed out through the Wunderfizz, and its own box and wall buy layout.

### Origins

- Survival start: **The Crazy Place**, the elemental chamber arena played as a standalone map.
- Inside the arena: four wall buys (Skorpion EVO, SCAR-H, MG08 and KSG), four perk machines that appear as floating bottles and shuffle between the corners, and Pack-a-Punch in the middle. There is no mystery box or Wunderfizz in the arena.
- Solo Easter Eggs are available.

### Nuketown

- The hellhound rounds were silent and invisible in stock, because their effects and sounds live in a fastfile the map never loads. The mod ships them back.
- The teleport row's three destinations are the map's own respawn points.

---

<details>
<summary><b>In-game chat commands</b></summary>

<br>

Use a `.`, `!` or `/` prefix, or bind them to keys. Type `.help` in game for the current list.

```text
.help                     Show / hide the in-game command list
.give <weapon> [pap]      Give any weapon ('.give list' shows what's available)
.round <n> / .endround    Set or skip the current round
.god / .ghost / .fly      Invincibility, noclip, flight
.infammo / .infsprint     Infinite ammo and sprint
.pack / .unpack           Pack-a-Punch or unpack the held weapon
.giveperks / .removeperks Grant or remove perks
.pay <player> <amount>    Send points to another player
.character <1-4>          Pick your own character (each player, not the host's choice)
.shield / .staff <elem>   Spawn a shield or an Origins elemental staff
```

</details>

---

<details>
<summary><b>Building from source</b></summary>

<br>

For script and menu changes, run `build.bat offline` to repack and verify the five mod files locally. This does not compile scripts or install anything. `build.bat` without arguments also deploys the mod, refreshes the installer bundle, and reconciles global Plutonium overrides; check its output for skipped copies or preserved conflicts.

Asset changes use `build_ff.bat` and the legacy OpenAssetTools setup; they can need untracked asset sources and donor files. The root `mod.zone` is an unused empty legacy file, and `zone_source/mod.zone` is the active fastfile recipe. A successful pack or link does not prove the mod starts or plays.

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
| **sehteria** | T6-ZM-Expanded, the mod this one grew out of, with extra weapons and perks on all maps. |
| **SadSlothXL** | The Death Machine power-up: the drop, the weapon swap and its sounds. |
| **Logo2K** ([Zombies Declassified](https://github.com/Logo-2K/zombies-declassified)) | The native T6 Wave Gun package: Treyarch's DLC5 models, animations, effects, weapon defs, sounds and script. |
| **Jbleezy** ([BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined)) | The extra Survival locations, the Bouncing Betty carry animations, the two lines that let Pack-a-Punch take the Sliquifier, and confirming the checks between a solo player and Mob of the Dead's Final Flight. |
| **5and5** ([BO2-Remix](https://github.com/5and5/BO2-Remix)) | The Die Rise Semtex wall buy. |
| **Fraaagaaa** ([Strat Tester](https://github.com/Fraaagaaa/Strat-Tester-BO2)) | Every teleport destination except Nuketown's three, which are the map's own respawn points. |
| **B2ORG** ([T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH))<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The basis for most of the patches, rebuilt against the game's own scripts. |
| **Hadi77KSA** ([Any Player EE Scripts](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts))<br><sub>building on work by **CCDeroga**, **teh_bandit**, **DaddyDontStop**, **shyperson0/znchi** and **Stick Gaming/Nathan3197**</sub> | The Solo Easter Eggs option: quest steps that scale to the number of players on TranZit, Die Rise, Buried and Origins. |

Built on [Plutonium](https://plutonium.pw), with **OpenAssetTools** and **xensik**'s **gsc-tool**. The optional ReShade install ships unmodified work by **crosire** ([ReShade](https://reshade.me)), **Barbatos Bachiko**, **Alex Tuduran**, **Marot Satil** and the **GShade** project, **Ioxa**, **Lord of Lunacy**, **prod80**, and **NVIDIA**.

> Missing or wrong credit? Open an issue and it will be fixed.

---

## How this was made

Most of this mod's code was written with AI coding assistants (Claude Code, OpenCode and others), directed and tested by me. All artwork is human-made. I am not a programmer and have never claimed to be, and I would rather be upfront about the AI use than have anyone find out later. The project started as something for me to play; I opened it up because other people might get some use out of it.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
