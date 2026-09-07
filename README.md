<div align="center">

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/32a1cfbd-7ece-4a91-9690-82691bed24b1" />

# Quality Of Life

**An extensive overhaul mod for Call of Duty: Black Ops II - Zombies on [Plutonium](https://plutonium.pw).**

Almost all Campaign weapons and every single Multiplayer weapon in the Mystery Box, 4 wonder weapons ported straight from the unreleased DLC5, bonus Survival maps, and a user-friendly Settings menu that you can configure to your heart's content in-game.

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

Arrow keys to move, **Enter** to choose, **Q** to quit. No admin rights, nothing left running, and no game file is touched — everything goes inside Plutonium's own folder. The installer can also fetch the optional extras: the HD texture and custom sound packs, controller icons, ReShade, backups, and a full uninstaller.

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

* **Bouncing Betties:**
  * The multiplayer proximity mine, in the Mystery Box on every map except Origins and Buried. They sit alongside your Claymores rather than replacing them, and use their own equipment button.

* **Jet Gun clean-up:**
  * It's carried as a normal primary that cycles with your other guns instead of living in an equipment slot, so it costs a real weapon slot and respects Mule Kick. Still overheats, never breaks.

---

## Maps, Power-ups, and Perks

**Bonus Survival maps:**
* **TranZit**
  * Diner
  * Power Station
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

* **Solo Easter Eggs:**
  * A **SOLO EASTER EGGS** switch in the pre-game lobby on TranZit, Die Rise, Buried and Origins. Turn it on and the main quest scales to however many players are actually in the lobby, instead of always demanding four. Off by default, and the row is only shown on those four maps in Classic — never on Survival or Grief.

* **Instant Pack-a-Punch:**
  * Instant Pack-a-Punch, like in Call of Duty: Black Ops Cold War - Zombies. It can be turned on or off in the settings menu.

* **Bonfire Sale:**
  * BO1's Pack-a-Punch power-up, from *Five*. Pick it up and Pack-a-Punch costs 1,000 points instead of 5,000 for thirty seconds. Part of the **Custom Power-Ups** option, on every map except Mob of the Dead and Buried.

---

## Presentation

* **Animated Pack-a-Punch camo:**
  * Every Pack-a-Punched gun gets the *Dark Matter* animated camo on all six maps; switch it off and each map uses its own stock PaP camo. The textures ship in the [HD Texture Pack](#standalone-downloads), so install that for the option to do anything.

* **Timers and counters:**
  * Game and round timers with configurable colours, plus a Cold War round counter.

* **Hitmarkers:**
  * Selectable hit, kill, crit and downed sounds, or off entirely if you prefer.

* **In-game menu:**
  * Mechanics, gameplay rules, HUD and audio options are all toggleable in game — no console commands. That includes a **VOICE LINES** switch for your character's spoken lines.

* **Third person:**
  * A **THIRD PERSON** switch on the GAME 3 tab puts the camera behind your character. Off is the normal view.

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
| **SadSlothXL** | The Death Machine power-up — the drop, the weapon swap and its sounds. |
| **Logo2K** — [Zombies Declassified](https://github.com/Logo-2K/zombies-declassified) | The native T6 Wave Gun package — Treyarch's DLC5 models, animations, effects, weapon defs, sounds and script. |
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | The extra Survival locations and the Bouncing Betty carry animations. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The Die Rise weapon changes — the Sliquifier's pre-nerf behaviour and the Semtex wall buy. |
| **Fraaagaaa** — [Strat Tester](https://github.com/Fraaagaaa/Strat-Tester-BO2) | Every destination in the teleport list except Nuketown's three, which are the map's own respawn points. |
| **B2ORG** — [T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH)<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The basis for most of the patches — rebuilt against the game's own scripts rather than copied wholesale. |
| **Hadi77KSA** — [Any Player EE Scripts](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts)<br><sub>building on work by **CCDeroga**, **teh_bandit**, **DaddyDontStop**, **shyperson0/znchi** and **Stick Gaming/Nathan3197**</sub> | The Solo Easter Eggs option — the quest steps that scale to the number of players on TranZit, Die Rise, Buried and Origins. |

Built on [**Plutonium**](https://plutonium.pw), with **OpenAssetTools** and **xensik**'s **gsc-tool**. The optional ReShade install ships unmodified work by **crosire** ([ReShade](https://reshade.me)), **Barbatos Bachiko**, **Alex Tuduran**, **Marot Satil** and the **GShade** project, **Ioxa**, **Lord of Lunacy**, **prod80**, and **NVIDIA**.

> Missing or wrong credit? Open an issue and it'll be fixed.

---

**Disclaimers/Other Information:**

This mod's code is mostly made using **Claude Code AI**; however, **ANY** and **ALL** artwork is human-made. I understand how controversial the usage of AI in any form is perceived to be, and that this will come as a disappointment to some; any criticism is understandable — I am not a coder, nor have I ever claimed to be. This project's initial intention was for it to be used by me, and me only. I have decided to open this project up as I understand that this could be quite resourceful.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
