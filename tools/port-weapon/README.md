# tools/port-weapon

One command for the mechanical half of a weapon port, plus the helpers the live
check uses. The full procedure, including how to get a gun that nobody has ported
out of another Call of Duty, is the `port-weapon` skill
(`H:\Claude\tools\skills\port-weapon\SKILL.md`). Read that first.

| File | What it does |
|---|---|
| `port_weapon.py plan --src <dir> --name <gun>` | Reads a T6 raw source tree and prints every decision and every refusal. Writes nothing. |
| `port_weapon.py apply ...` | Writes the defs, zone, models, anims, art, camo, sounds, strings, registration gsc, csc twin and gate contract, then runs `check-weapon-port.py`. |
| `selftest.py <t6-ports clone> <scratch>` | Rebuilds SadSlothXL's Blast-O-Matic from its source into a throwaway tree and checks it field for field against the shipped gun. Run it after changing `port_weapon.py`. |
| `stock-images/*.txt` | Image names each stock zone owns (Unlinker listings). The plan uses them to refuse an image name a map owns and to find map-only images. |
| `live/zzz_portcheck.gsc.template` | A read-only probe that prints registration, clip and stock. Replace `GUN`, gate it, drop it in `raw\scripts\zm\`, and remove it after. |
| `live/capture-window.ps1 <hwnd> <out.png>` | Headless screenshot of the game window. It never takes focus. |
| `live/deploy.ps1 -Tree <worktree> -Job <job>` | Backs up the install, then deploys a worktree's build. Refuses while the game runs or a probe is loose. |
| `live/verify-installed.py <tree> <gun>` | Checks the installed files against the tree, plus the gun's camo, defs and gsc in what the game reads. |

The source layout `port_weapon.py` reads is the one OpenAssetTools uses for T6
(`zone_raw\mod\`): `weapons\`, `xmodel\*.json` + `model_export\*.glb`,
`materials\`, `images\*.iwi`, `camo\`, `soundbank\*.csv` + `sound\`, `xanim\`
(or `iwd\mod\xanim\`), and `english\localizedstrings\*.str`. A gun from another
game is converted into this layout first (the skill, section 2).

Proven on: the Blast-O-Matic (2026-09-25, accepted by the player). The selftest
reproduces it.
