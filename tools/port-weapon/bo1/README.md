# tools/port-weapon/bo1: Black Ops 1 guns straight from the game

Pulls a BO1 gun out of the installed game
(`F:\SteamLibrary\steamapps\common\Call of Duty Black Ops`) into the source
layout `port_weapon.py` reads. Nobody's port is needed.

```
python tools\port-weapon\bo1\bo1_extract_gun.py <bo1 zone> <weapon def> <new out dir>
python tools\port-weapon\port_weapon.py plan  --src <out dir> --name <gun> --display "..." --display-pap "..."
python tools\port-weapon\port_weapon.py apply --src <out dir> --name <gun> --display "..." --display-pap "..."
```

`list_bo1_zm_weapons` below shows which zone holds which gun. The zone is where
the files came from, not a map. Kino's zone carries the AK-47's files, but the
AK-47 is not a Kino weapon.

| Script | What it does |
|---|---|
| `bo1_extract_gun.py` | Runs the whole pipeline for one gun: both forms, models, materials, images, anims, sounds |
| `t5_def_to_t6.py` | Builds a complete T6 def: the closest native template, BO1's value for every shared field, BO1's own icon, flash and tracer where BO2 ships them on every map |
| `t5_material_to_t6.py` | Rebuilds a BO1 weapon material on T6's lit weapon techset, the shipped L96A1's recipe |
| `t5_xanim_to_t6.py` | Neutralises BO1's rumble notetracks, which crash T6 on first play, and renames sound notetracks at the same length |
| `bo1_snd_to_wav.py` | Decodes BO1's `snd_asset` audio (xWMA, MS-ADPCM at 262 bytes per channel per block, and the few RIFF files) to 16-bit PCM WAV at 44.1 or 48 kHz |

## What each part rests on (measured 2026-09-25)

- **Animations**: BO1 compiled xanims load in the T6 Linker unchanged: 18/18,
  0 errors, readback byte-identical.
- **Sound**: 8,777 of BO1's `raw\sound` files decode. Header layout comes from
  DTZxPorter's BassDrop (`H:\Plutonium\tools\BassDrop-Enhanced`).
- **Pack-a-Punch form**: BO1's `main\*.iwd` holds every zombies def as
  `weapons/sp/<name>`, each with its `_upgraded_zm` twin. The PaP def is the
  full base def with the upgraded file's values laid over it.
- **Images**: from the zone dump when it has pixels, otherwise from
  `main\*.iwd` (T5 IWI, then ImageConverter `--t5` to DDS, then `--t6`).
- **Materials**: the zone often holds attachment materials (scopes, mags) only
  as bare references. Their mesh slots are pointed at the gun's body material,
  because a zombies def never shows those parts.
- **Aliases**: private names (`wpn_` becomes `bo1_`, `fly_` becomes `fb1_`), so
  nothing shadows a BO2 or zm_qol alias or the user's sound pack.

End-to-end proof: the AK-47 extracted from `zombie_theater.ff`, applied with
`port_weapon.py`, and linked by the mod's own `build_ff.bat`. The link had 0
errors, and the gate's source, readback and `--pixels` passes all passed.
Compared with the tree's previous `mod.ff`, 0 assets were removed and 32 added
(2 xmodel, 18 xanim, 3 material, 6 image, 1 camo, 2 localize), all named for
the gun, and none collides with a stock zone. The job folder is
`modding-jobs\noporting-probe-001\`.
