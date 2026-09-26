"""Every weapon def each BO1 zombies zone owns, so a port knows where a gun (and its
Pack-a-Punched twin) lives. Writes bo1_zm_weapons.json."""
import json
import subprocess
from pathlib import Path

BO1 = Path(r'F:\SteamLibrary\steamapps\common\Call of Duty Black Ops\zone\Common')
UNLINKER = r'H:\Plutonium\tools\oat-dlc5\Unlinker.exe'
out = {}
for ff in sorted(BO1.glob('zombie_*.ff')):
    lst = subprocess.run([UNLINKER, '--list', str(ff)], capture_output=True, text=True).stdout
    weapons = sorted(l.split(', ', 1)[1] for l in lst.splitlines()
                     if l.startswith('weapon, ') and not l.startswith('weapon, ,'))
    out[ff.stem] = weapons
    print(f'{ff.stem:28} {len(weapons):3}  {", ".join(w for w in weapons if "upgraded" not in w)[:180]}')
Path(__file__).with_name('bo1_zm_weapons.json').write_text(json.dumps(out, indent=1), encoding='utf-8')
where = {}
for z, ws in out.items():
    for w in ws:
        where.setdefault(w, []).append(z)
print()
print('ak47:', {w: z for w, z in where.items() if 'ak47' in w})
