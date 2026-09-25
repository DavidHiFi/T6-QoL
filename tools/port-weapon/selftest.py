"""Self-test for tools/port-weapon/port_weapon.py. Needs the shipped Blast-O-Matic.

Clones Sloth's untouched Blast-O-Matic source with every t9_gallo name renamed
to t9_gtest (so it does not collide with the shipped gun), applies the
answers the plan asks for, runs `apply` into a throwaway copy of the zm_qol
tree, and checks the result against what the hand port shipped. Nothing here
touches the real worktree or the live mod.
"""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Usage: python tools/port-weapon/selftest.py <sloth-t6-ports clone> <scratch dir>
#   git clone https://github.com/SadSlothXL/t6-ports  (Weapons/zm/blasrtomatic)
TREE = Path(__file__).resolve().parents[2]
SRC = Path(sys.argv[1]) / 'Weapons/zm/blasrtomatic/zone_raw/mod'
WORK = Path(sys.argv[2])
if WORK.exists():
    shutil.rmtree(WORK)

# 1. renamed donor: every t9_gallo -> t9_gtest in names AND in file contents
donor = WORK / 'donor'
for f in SRC.rglob('*'):
    if f.is_dir():
        continue
    rel = str(f.relative_to(SRC)).replace('t9_gallo', 't9_gtest')
    dst = donor / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    data = f.read_bytes()
    if f.suffix in ('.json', '.csv', '.str', '.gsc', '.csc') or 'weapons' in f.parts:
        data = data.replace(b't9_gallo', b't9_gtest').replace(b'T9_GALLO', b'T9_GTEST')
    elif f.suffix == '.glb':
        pass  # GLB chunk lengths are stored; the material rename is done below
    elif 'xanim' in f.parts:
        # notetracks name aliases; same-length rename keeps the xanim byte layout
        data = data.replace(b't9_gallo', b't9_gtest')
    dst.write_bytes(data)
# xanims keep their names inside the file only as notetracks; rename files only
# (done above). GLB material names must match the renamed material JSONs: rewrite
# the JSON chunk and fix its length.
import struct
for g in (donor / 'model_export').glob('*.glb'):
    b = g.read_bytes()
    n = struct.unpack('<I', b[12:16])[0]
    j = b[20:20 + n].replace(b't9_gallo', b't9_gtest')
    assert len(j) == n, 'same-length rename keeps the GLB chunk intact'
    g.write_bytes(b[:20] + j + b[20 + n:])

# 2. answers to the plan's DECIDE lines, applied to the donor like an agent would
for m in ('mtl_t9_gtest_blastomatic_power', 'mtl_t9_gtest_blastomatic_power_pap'):
    p = donor / 'materials' / f'{m}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    for t in d['textures']:
        t['image'] = {'mtl_p6_zm_tm_crystal_n': 'qolwf_crystal_n',
                      '~-gmtl_p6_zm_tm_crystal_bubbles_c': 'qolwf_crystal_bub_c',
                      '~-gmtl_p6_zm_tm_crystal_c': 'qolwf_crystal_c'}.get(t['image'], t['image'])
    p.write_text(json.dumps(d, indent=4))

# 3. throwaway copy of the tree (only what the tool reads and writes)
tree = WORK / 'tree'
for rel in ('tools', 'weapons/zm', 'zone_source', 'soundbank', 'scripts/zm',
            'zone_assets/camo', 'zone_assets/english', 'zone_assets/images'):
    src = TREE / rel
    dst = tree / rel
    if rel == 'zone_assets/images':
        dst.mkdir(parents=True, exist_ok=True)
        for f in src.glob('qolwf_crystal_*.iwi'):
            shutil.copyfile(f, dst / f.name)
        continue
    if rel == 'zone_source':
        dst.mkdir(parents=True, exist_ok=True)
        for f in src.glob('*.zone'):
            shutil.copyfile(f, dst / f.name)
        continue
    shutil.copytree(src, dst, ignore=shutil.ignore_patterns('*.bak*'))
(tree / 'zone_assets' / 'materials').mkdir(parents=True, exist_ok=True)

tool = tree / 'tools/port-weapon/port_weapon.py'
cmd = [sys.executable, str(tool), 'apply', '--src', str(donor), '--name', 'selftestgun',
       '--credit', 'SadSlothXL - selftest', '--force']
res = subprocess.run(cmd, capture_output=True, text=True)
print(res.stdout[-3000:])
print(res.stderr[-2000:])

# 4. checks against the hand port
ok = True
def check(label, cond):
    global ok
    ok &= bool(cond)
    print(f'{"PASS" if cond else "FAIL"}  {label}')

sys.path.insert(0, str(tree / 'tools/port-weapon'))
import port_weapon as pw
bd = dict(pw.load_def(tree / 'weapons/zm/selftestgun_zm')[0])
ud = dict(pw.load_def(tree / 'weapons/zm/selftestgun_upgraded_zm')[0])
hand_b = dict(pw.load_def(TREE / 'weapons/zm/blastomatic_zm')[0])
hand_u = dict(pw.load_def(TREE / 'weapons/zm/blastomatic_upgraded_zm')[0])
check('apply exit 0 (gate PASS)', res.returncode == 0)
check('both defs under 20480 B', all((tree / 'weapons/zm' / n).stat().st_size < 20480 for n in ('selftestgun_zm', 'selftestgun_upgraded_zm')))
check('both forms name camo_qol_selftestgun', bd.get('camo') == ud.get('camo') == 'camo_qol_selftestgun')
check('base ammo no longer shared with the 870', bd.get('ammoName') != '12 gauge 870mcs')
norm = lambda d: {k: v.replace('t9_gtest', 't9_gallo').replace('T9_GTEST', 'T9_GALLO') for k, v in d.items()}
skip = {'camo', 'ammoName', 'clipName'}
diff_b = {k for k in set(norm(bd)) | set(hand_b) if k not in skip and norm(bd).get(k) != hand_b.get(k)}
diff_u = {k for k in set(norm(ud)) | set(hand_u) if k not in skip and norm(ud).get(k) != hand_u.get(k)}
check(f'base def equals the hand port field for field (diff {sorted(diff_b)[:4]})', not diff_b)
check(f'upgraded def equals the hand port field for field (diff {sorted(diff_u)[:4]})', not diff_u)
camo = json.loads((tree / 'zone_assets/camo/camo_qol_selftestgun.json').read_text(encoding='utf-8'))
parts = [f'mtl_t9_gtest_blastomatic_{p}' for p in ('barrel', 'barrel_cover', 'body', 'forend', 'lazer', 'misc', 'muzzle', 'pgrip', 'pump', 'stock', 'triggergroup')]
for i in (3, 8, 12):
    mapped = {o['baseMaterial'] for m in camo['camoMaterials'][i]['materials'] for o in m['materialOverrides']}
    check(f'camo slot {i} maps all 11 parts', set(parts) <= mapped)
zone = (tree / 'zone_source/mod_selftestgun.zone').read_text(encoding='utf-8')
check('zone declares 4 xmodels, 27 xanims, the camo', zone.count('\nxmodel,') == 4 and zone.count('\nxanim,') == 27 and 'camo,camo_qol_selftestgun' in zone)
check('mod.zone includes it', 'include,mod_selftestgun' in (tree / 'zone_source/mod.zone').read_text(encoding='utf-8'))
gsc = (tree / 'scripts/zm/selftestgun.gsc').read_text(encoding='utf-8')
check('gsc registers with _zm_weapons include and the Origins hold-back', '#include maps\\mp\\zombies\\_zm_weapons;' in gsc and 'zm_tomb' in gsc and '1500, "wpck_shotgun"' in gsc)
csc = (tree / 'scripts/zm/zm_expanded.csc').read_text(encoding='utf-8')
check('csc twin on the same map test', 'include_weapon( "selftestgun_zm" )' in csc and csc.count('if ( !b_tomb )') >= 3)
rows = [l for l in (tree / 'soundbank/mod.all.aliases.additions.csv').read_text(encoding='utf-8').splitlines() if l.startswith('t9_gtest')]
check(f'29 alias rows appended ({len(rows)})', len(rows) == 29)
check('every alias payload staged', all((tree / r.split(',')[1][4:].replace('\\', '/')).is_file() for r in rows))
check('every notetrack sound resolves to an alias (no WARN)', 'no source alias defines' not in res.stdout)
contract = [c for c in json.loads((tree / 'tools/weapon-port-contracts.json').read_text(encoding='utf-8'))['ports'] if c['name'] == 'selftestgun']
check('gate contract registered', len(contract) == 1)
s = (tree / 'zone_assets/english/localizedstrings/mod.str').read_text(encoding='utf-8')
check('display names added', 'WEAPON_T9_GTEST_BLASTOMATIC_ZM' in s and '"H-NGM-N"' in s.split('selftestgun')[-1])
print('SELFTEST ' + ('PASS' if ok else 'FAIL'))
sys.exit(0 if ok else 1)
