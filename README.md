<div align="center">

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/32a1cfbd-7ece-4a91-9690-82691bed24b1" />

# Quality Of Life

**An extensive overhaul mod for Call of Duty: Black Ops II - Zombies on [Plutonium](https://plutonium.pw).**

Extra Campaign and Multiplayer weapons in the Mystery Box, 4 wonder weapons ported straight from the unreleased DLC5, bonus Survival maps, and a user-friendly Settings menu that you can configure to your heart's content in-game.

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

Arrow keys to move, **Enter** to choose, **Q** to quit. The mod install needs no admin rights and leaves nothing running. Mod files go inside Plutonium's folder; the optional Start menu shortcuts go in your user Start menu. The installer can also fetch the optional extras: the HD texture and custom sound packs, controller icons, ReShade, backups, and a full uninstaller.

**Start menu shortcuts** are one of its options — pick it and you can reach **Quality Of Life Mod** (this installer) and **Plutonium ReShade Watcher** by pressing the Windows key and typing. They point at the folder you unzipped to, so keep it somewhere you're happy to leave it; the uninstall list removes them again.

### Standalone downloads

Neither needs the mod installed:

| Download | Size | What it is |
|---|---|---|
| [**HD Texture Pack**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/HD.Texture.Pack.zip) | 525 MB | Higher-resolution textures, animated Pack-a-Punch camo, and much more. Unzip and drop the `images` folder into `%LOCALAPPDATA%\Plutonium\storage\t6\`. |
| [**Controller Icons**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/Controller.Icons.Pack.zip) | 184 KB | PlayStation 5, Nintendo Switch and Xbox One button prompts. Pick one of the three folders inside and copy the `.iwi` files into `%LOCALAPPDATA%\Plutonium\storage\t6\images\`. |

<details>
<summary><b>Install the mod by hand (Windows and Linux)</b></summary>

<br>

On **Linux** (Wine, Proton, Lutris, Bottles) there is no automated installer — install by hand; it works like any other Plutonium mod.

1. Download the release zip and open the **`Mod Files`** folder inside it.
2. Create a folder called `zm_qol` in `%LOCALAPPDATA%\Plutonium\storage\t6\mods\` *(on Linux, the same path inside your Plutonium prefix).*
3. Copy these five files into it: `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, `mod.all.sabs`. Nothing else is needed.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

</details>

---

## Notes

> [!IMPORTANT]
> **Plutonium deletes ReShade every time it starts** — it clears anything it doesn't recognise out of its own `bin` folder. Launch with **`Play BO2 with ReShade.bat`** (inside `Mod Files`, or as the **Plutonium ReShade Watcher** Start menu shortcut) and leave its window open while you play; it puts ReShade back each time. Closing the window uninstalls nothing.

> [!NOTE]
> **Still in beta.** Some of the newest features haven't had a full play-through yet. Anything that turns out broken gets fixed or pulled.
>
> **Cloning the repo does not give you a playable mod** — `mod.iwd` is a build output and isn't tracked in git. Use the release.

> [!WARNING]
> **Known issue.** Choosing **INSTANT EXIT** straight after a **FAST RESTART** can drop the game to a `LUI_ERROR` dialog. The fault is inside Plutonium's own `MainMenuOG.lua`, which this mod neither ships nor overrides, so it can't be fixed from the mod's side. Leaving the match with Escape → INSTANT EXIT on its own is unaffected.

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

## What's in the mod

### Weapons

**More guns in the Mystery Box:** Storm PSR, Dragunov, SPAS-12, SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6 and Tac-45.

**Black Ops 1 classics:** M60, L96A1, Browning HP and RPG-7.

**DLC5 wonder weapons:** Wave Gun, Thundergun, Wunderwaffe DG-2 and Winter's Howl.

Origins and Buried skip some of these so the maps still load — everything else is in the box on every map.

**Small gunplay touches:** the Pack-a-Punched SPAS-12 and the Python reload in one go. Bouncing Betties join the box and share the Claymore slot, so one mine type at a time. The Jet Gun takes a real weapon slot and respects Mule Kick — it still overheats, but never breaks.

### Bonus Survival maps

| Base map | Locations |
|---|---|
| TranZit | Diner, Power Station, Tunnel |
| Die Rise | Shopping Mall, Dragon Rooftop, Sweatshop |
| Mob of the Dead | Cell Block |
| Buried | Borough |
| Origins | The Crazy Place |

### Gameplay

* **Der Wunderfizz** — the random perk machine, on every map.
* **No perk limit** — hold as many as you like, or set a cap of 1–12 in the pre-game lobby.
* **Better Speed Cola** — an optional switch that also speeds up window boarding and drinking perks.
* **Instant Pack-a-Punch** — Cold War-style, no wait. Toggle it in the settings menu.
* **Bonfire Sale** — BO1's Pack-a-Punch sale from *Five*: 1,000-point upgrades for 30 seconds. Part of **Custom Power-Ups**, on every map except Mob of the Dead and Buried.
* **Solo Easter Eggs** — a pre-game lobby switch (TranZit, Die Rise, Mob of the Dead, Buried, Origins) that scales the main quest to your actual party size instead of always demanding four. On Mob of the Dead you can fly the plane alone. Off by default, Classic only.

### Map-specific touches

* **Die Rise** — the Sliquifier can be Pack-a-Punched. Treyarch built the upgraded gun and left it in the files without ever hooking it up; here it kills at any round. There's also a Semtex wallbuy.
* **TranZit (Diner Survival)** — a Semtex wallbuy by the doorway.

### Look and feel

* **Animated Pack-a-Punch camo** — every upgraded gun gets an animated camo on all six maps; turn it off and each map uses its own stock camo. Needs the [HD Texture Pack](#standalone-downloads).
* **Ray Gun skin** — Green Run, Die Rise and Nuketown use Buried's remade Ray Gun model instead of the old Black Ops 1 one, in the box and in players' hands.
* **Timers and counters** — game and round timers with configurable colours, plus a Cold War-style round counter.
* **Health bar** — bottom left, with your health as a number. Turns yellow, then red when the next hit would down you. Shields get their own bar above it.
* **Subtitles** — optional dialogue subtitles on every map (HUD tab: OFF / SUBTITLES / SUBTITLES + NAMES). Covers the crew, announcers, Maxis, Samantha and each map's extra voices. The lines were transcribed from the game audio, so the odd word may be off.
* **Scoreboard emblems** — every map shows its own crew emblem instead of the missing-texture checkerboard the DLC maps used to draw.
* **Hitmarkers** — pick your hit, kill, crit and downed sounds, or turn them off.
* **In-game menu** — mechanics, rules, HUD and audio options with no console commands, including a **VOICE LINES** switch for your character's chatter.
* **Third person** and **knife lunge** — two switches on the GAME 3 tab. Third person moves the camera behind you; turning knife lunge off stops the melee pull so you knife where you stand.
* **Extras** — tap-to-interact controller support under the standard Gamepad menu, plus a tailored *Cinematic Colour Grading* ReShade preset.

---

<details>
<summary><b>Building from source</b></summary>

<br>

For script and menu changes, run `build.bat offline` to repack and verify the five
mod files locally. This does not compile scripts or install anything. `build.bat`
without arguments also deploys the mod, refreshes the installer bundle, and
reconciles global Plutonium overrides; review its output for skipped copies or
preserved conflicts.

Asset changes use `build_ff.bat` and the existing legacy OpenAssetTools setup;
they can require untracked asset sources and donor files. The root `mod.zone` is
an unused empty legacy file; `zone_source/mod.zone` is the active fastfile recipe.
A successful pack or link does not establish startup or gameplay compatibility.

</details>

## Contribute To Support Development

The mod is free and always will be. Any amount of support is greatly appreciated, and I do sincerely hope you enjoy my little project. :-)

[![Support DavidHiFi on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/davidhifi)

---

## Credits

* **Author:**
  * Myself, [DavidHiFi](https://github.com/DavidHiFi)

| Who | What |
|---|---|
| **Synarxis** — *Inspiration* | This project wouldn't exist without their kindness & support. |
| **sehteria** — *T6-ZM-Expanded* | The mod this one grew out of — extra weapons & perks on all maps. |
| **SadSlothXL** | The Death Machine power-up — the drop, the weapon swap and its sounds. |
| **Logo2K** — [Zombies Declassified](https://github.com/Logo-2K/zombies-declassified) | The native T6 Wave Gun package — Treyarch's DLC5 models, animations, effects, weapon defs, sounds and script. |
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | The extra Survival locations, the Bouncing Betty carry animations, the two lines that let Pack-a-Punch take the Sliquifier, and confirming which two checks stand between a solo player and Mob of the Dead's Final Flight. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The Die Rise Semtex wall buy. |
| **Fraaagaaa** — [Strat Tester](https://github.com/Fraaagaaa/Strat-Tester-BO2) | Every destination in the teleport list except Nuketown's three, which are the map's own respawn points. |
| **B2ORG** — [T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH)<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The basis for most of the patches — rebuilt against the game's own scripts rather than copied wholesale. |
| **Hadi77KSA** — [Any Player EE Scripts](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts)<br><sub>building on work by **CCDeroga**, **teh_bandit**, **DaddyDontStop**, **shyperson0/znchi** and **Stick Gaming/Nathan3197**</sub> | The Solo Easter Eggs option — the quest steps that scale to the number of players on TranZit, Die Rise, Buried and Origins. |

Built on [**Plutonium**](https://plutonium.pw), with **OpenAssetTools** and **xensik**'s **gsc-tool**. The optional ReShade install ships unmodified work by **crosire** ([ReShade](https://reshade.me)), **Barbatos Bachiko**, **Alex Tuduran**, **Marot Satil** and the **GShade** project, **Ioxa**, **Lord of Lunacy**, **prod80**, and **NVIDIA**.

> Missing or wrong credit? Open an issue and it'll be fixed.

---

**Disclaimers/Other Information:**

Most of this mod's code was built with the help of AI coding assistants; however, **ANY** and **ALL** artwork is human-made. I understand how controversial the usage of AI in any form is perceived to be, and that this will come as a disappointment to some; any criticism is understandable — I am not a coder, nor have I ever claimed to be. This project's initial intention was for it to be used by me, and me only. I have decided to open this project up as I understand that this could be quite resourceful.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
