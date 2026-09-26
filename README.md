<div align="center">

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/32a1cfbd-7ece-4a91-9690-82691bed24b1" />

# Quality Of Life

**A major overhaul for Call of Duty: Black Ops II Zombies on [Plutonium](https://plutonium.pw).**

Adds almost every Campaign and Multiplayer weapon to the Mystery Box, four unreleased DLC5 wonder weapons, bonus Survival maps, and an in-game Settings menu.

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

Install Plutonium and run it once so its folders exist, then close it. Then pick either route below - they install the same mod.

### With the mod manager

[**Quality of Life Series**](https://github.com/DavidHiFi/QualityOfLifeSeries) is a small app that installs, updates and removes this mod for you, and manages every other mod in your Plutonium folders as well.

1. [Download it](https://github.com/DavidHiFi/QualityOfLifeSeries/releases/latest) - the setup installs it like any other program, or the portable zip runs as-is.
2. Open it and go to **Black Ops II (T6)**.
3. Choose **The mod → Install**. The HD textures go in with it, so there is nothing else to add.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

It backs up anything it replaces, keeps your saved menu settings across updates, and tells you when a newer release is out.

### With the release installer

1. [Download the latest release](https://github.com/DavidHiFi/T6-QoL/releases/latest) and unzip it anywhere.
2. Run **`Windows Install.bat`**.
3. Choose **INSTALL → The mod** and confirm.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

Use the arrow keys to move, **Enter** to choose, and **Q** to quit. No admin rights are needed. The installer can also add texture and sound packs, controller icons, ReShade, backups, Start menu shortcuts, and an uninstaller.

The optional Start menu shortcuts open the installer and ReShade Watcher. They point to the extracted folder, so do not move or delete it while using them.

### Standalone downloads

Neither needs the mod installed. Installing the mod already puts the HD textures
in place for you, so you only need these if you want the art on its own — they
are no longer updated.

| Download | Size | What it is |
|---|---|---|
| [**HD Texture Pack**](https://github.com/DavidHiFi/T6-QoL/releases/download/v2.15.44/HD.Texture.Pack.zip) | 525 MB | The same higher-resolution textures the mod already carries, for use without it. Unzip and drop the `images` folder into `%LOCALAPPDATA%\Plutonium\storage\t6\`. |
| [**Controller Icons**](https://github.com/DavidHiFi/T6-QoL/releases/download/v2.15.44/Controller.Icons.Pack.zip) | 184 KB | PlayStation 5, Nintendo Switch and Xbox One button prompts. Pick one of the three folders inside and copy the `.iwi` files into `%LOCALAPPDATA%\Plutonium\storage\t6\images\`. |

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
> **Plutonium removes ReShade when it starts.** Launch with **`Play BO2 with ReShade.bat`** or the **Plutonium ReShade Watcher** shortcut, then leave its window open while playing.

> [!NOTE]
> **Still in beta.** Some of the newest features haven't had a full play-through yet. Anything that turns out broken gets fixed or pulled.
>
> **Cloning the repo does not give you a playable mod** — `mod.iwd` is a build output and isn't tracked in git. Use the release.

> [!WARNING]
> **Known issue.** Using **INSTANT EXIT** straight after **FAST RESTART** can cause a `LUI_ERROR`. This comes from Plutonium's `MainMenuOG.lua`, not the mod. **INSTANT EXIT** works normally otherwise.

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
.infammo / .bclip         Infinite reserves, or a magazine that never empties
.infsprint                Sprint without tiring
.pack / .unpack           Pack-a-Punch or unpack the held weapon
.giveperks / .removeperks Grant or remove perks
.pay <player> <amount>    Send points to another player
.character <1-4>          Pick your own character (each player, not the host's choice)
.shield / .staff <elem>   Spawn a shield or an Origins elemental staff
```

</details>

---

## Building from source

Run `build.bat offline` to repack and verify script or menu changes without
installing them. Run `build.bat` to build, deploy, and update the installer.

Build assets with `build_ff.bat`. It uses `zone_source/mod.zone` and may need
untracked source assets or donor files. A successful build still needs in-game testing.

## Contribute To Support Development

The mod is free and always will be. Any amount of support is greatly appreciated, and I do sincerely hope you enjoy my little project. :-)

[![Support DavidHiFi on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/davidhifi)

---

## Weapons

* **Campaign and Multiplayer guns/equipment in the box:**
  * Storm PSR
  * Dragunov
  * SPAS-12
  * SWAT-556
  * FAL OSW
  * Mk 48
  * QBB LSW
  * MP7
  * Vector K10
  * MSMC
  * Peacekeeper
  * Crossbow
  * XPR-50
  * Titus-6
  * Tac-45

* **DLC5 wonder weapons:**
  * The Wave Gun
  * Thundergun
  * Wunderwaffe DG-2
  * Winter's Howl
  * All four are in the Mystery Box on every map except Origins and Buried.

* **Black Ops 1 guns in the box:**
  * M60 — Pack-a-Punches into **The Pig**
  * L96A1 — Pack-a-Punches into the **L115 Isolator**
  * Browning HP — Pack-a-Punches into **Bap**
  * RPG-7 — Pack-a-Punches into the **Rocket Propelled Grievance**
  * All four appear on every map except Origins, which lacks enough weapon precache slots.

* **Black Ops Cold War guns in the box:**
  * Blast-O-Matic, the Gallo SA12 mastercraft. It Pack-a-Punches into the **H-NGM-N**, with its own sounds, animations and the stock and animated Pack-a-Punch camos.
  * It appears on every map except Origins, which lacks enough weapon precache slots.

* **Old-school guns in the box:**
  * MM1 Grenade Launcher, the twelve-round revolver launcher from the Black Ops II campaign. It Pack-a-Punches into the **Parasitic MIST**.
  * Browning HP Dual Wield, a Browning in each hand. It Pack-a-Punches into the **Grand Puissances**.
  * Both appear on Nuketown and Buried, including Buried Maze. The MM1 also appears on Die Rise, Origins, TranZit survival locations and Mob's Docks. TranZit classic and Mob classic have no safe room in the weapon table for either gun.

* **Reloads that don't waste your time:**
  * The Pack-a-Punched SPAS-12 loads all 24 shells in one go instead of feeding them in one by one.
  * The Python loads all six rounds at once, the way its Pack-a-Punched version always has.

* **Bouncing Betties:**
  * Multiplayer proximity mines appear in the Mystery Box on every map. Betties and Claymores replace each other and share the equipment button.

* **Jet Gun clean-up:**
  * The Jet Gun uses a normal weapon slot and works with Mule Kick. It still overheats but no longer breaks.

* **Pack-a-Punchable Sliquifier:**
  * Die Rise's Sliquifier can be upgraded into Treyarch's unused **Sl1qu1f13r**.
  * The upgrade kills at any round. The standard Sliquifier is unchanged.

---

## Maps, Power-ups, and Perks

**Bonus Survival maps:**
* **TranZit**
  * Diner
  * Power Station
  * Tunnel
* **Die Rise**
  * Shopping Mall
  * Dragon Rooftop
  * Sweatshop
* **Mob of the Dead**
  * Cell Block
* **Buried**
  * Borough
* **Origins**
  * The Crazy Place

* **Der Wunderfizz Machine on all maps:**
  * The random perk machine is available on every map, not just Origins.

* **No perk limit:**
  * Carry as many as you like by default, or set a cap of 1–12 from the pre-game lobby.

* **Better Speed Cola:**
  * A **BETTER SPEED COLA** switch on the GAME tab. With it on, Speed Cola also boards up windows faster and drinks perk bottles faster.

* **Solo Easter Eggs:**
  * The **SOLO EASTER EGGS** option scales the main quests on TranZit, Die Rise, Buried, Origins, and Mob of the Dead to the current player count. It is off by default and only appears in Classic mode.

* **Instant Pack-a-Punch:**
  * Instant Pack-a-Punch, like in Call of Duty: Black Ops Cold War - Zombies. It can be turned on or off in the settings menu.

* **Bonfire Sale:**
  * BO1's Pack-a-Punch power-up, from *Five*. Pick it up and Pack-a-Punch costs 1,000 points instead of 5,000 for thirty seconds. Part of the **Custom Power-Ups** option, on every map except Mob of the Dead and Buried.

---

## Presentation

* **Animated Pack-a-Punch camo:**
  * Every Pack-a-Punched gun gets the *Dark Matter* animated camo on all six maps; switch it off and each map uses its own stock PaP camo. Installing the mod installs those textures too, so the option works out of the box.

* **Ray Gun skin:**
  * Green Run, Die Rise, and Nuketown use the newer Ray Gun model for the upgraded gun, Mystery Box preview, dropped weapons, and other players.

* **Timers and counters:**
  * Game and round timers with configurable colours, plus a Cold War round counter.

* **Health bar:**
  * A health bar changes from green to yellow after damage and red near death. A second bar shows shield health.

* **Subtitles:**
  * The HUD menu can show subtitles with optional speaker names on every map in solo and co-op. It covers characters, announcers, radios, quest dialogue, and other map voices. Overlapping lines stack on screen. The text was machine-transcribed, so some words may be wrong.

* **Scoreboard crew emblems:**
  * The scoreboard shows the correct crew emblem for each map and mode instead of a missing texture.

* **Hitmarkers:**
  * Selectable hit, kill, crit and downed sounds, or off entirely if you prefer.

* **In-game menu:**
  * Mechanics, gameplay rules, HUD and audio options are all toggleable in game — no console commands. That includes a **VOICE LINES** switch for your character's spoken lines.

* **Third person:**
  * A **THIRD PERSON** switch on the GAME 3 tab puts the camera behind your character. Off is the normal view.

* **Knife lunge:**
  * A **KNIFE LUNGE** switch on the GAME 3 tab. On is the normal game. Off removes the melee charge that pulls you onto a zombie, so you knife where you stand.

* **Mud:**
  * A **NO MUD SLOWDOWN** switch on the GAME 3 tab. Turn it on and Origins mud stops dragging you down — you run and walk through it at full speed, in the main map and in every Origins survival and grief location.

* **Extras:**
  * Native "Tap to Interact" controller support under the standard Gamepad menu, and a tailored *Cinematic Colour Grading* ReShade preset.

---

## Credits

* **Author:**
  * Myself, [DavidHiFi](https://github.com/DavidHiFi)

| Who | What |
|---|---|
| **Synarxis** — *Inspiration* | This project wouldn't exist without their kindness & support. |
| **sehteria** — *T6-ZM-Expanded* | The mod this one grew out of — extra weapons & perks on all maps. |
| **SadSlothXL** — [t6-ports](https://github.com/SadSlothXL/t6-ports) | The Death Machine power-up — the drop, the weapon swap and its sounds — and the Blast-O-Matic port: its models, animations, textures, sounds and camo table. |
| **Mario Woopsie** — MOTD Old School Weapons (Nexus Mods) | The MM1 and Browning HP Dual Wield ports: the zombies weapon definitions, the Browning's left-hand models and both Pack-a-Punch names. |
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

Most of this mod's code was developed with several **AI coding agents**, including Claude Code, Codex, and OpenCode. No single AI agent made the project. All artwork is human-made. I originally built the mod for personal use and later released it for others to use and improve.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
