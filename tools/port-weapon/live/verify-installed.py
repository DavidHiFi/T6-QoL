"""Usage: python verify-installed.py <tree the build came from> [<gun name>]

Proves from the INSTALLED mod, not the source tree, that the game will load
this build: the five files hash-match the tree, and a ported gun's pieces are
in the files the game reads. A green build and a clean git status say nothing
about what is installed; another checkout's build.bat may have replaced it.
"""
import hashlib
import os
import subprocess
import sys
import zipfile

LIVE = os.path.join(os.environ['LOCALAPPDATA'], 'Plutonium', 'storage', 't6', 'mods', 'zm_qol')
TREE = sys.argv[1] if len(sys.argv) > 1 else r'H:\Plutonium\t6\mods\zm_qol'
GUN = sys.argv[2] if len(sys.argv) > 2 else None
UNLINKER = r'H:\Plutonium\tools\oat-dlc5\Unlinker.exe'


def sha(path):
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()[:12]


def iwd_entries(path):
    z = zipfile.ZipFile(path)
    return {n: hashlib.sha1(z.read(n)).hexdigest() for n in z.namelist() if not n.endswith('/')}


ok = True
for name in ('mod.ff', 'mod.iwd', 'mod.all.sabl', 'mod.all.sabs', 'mod.json'):
    a, b = os.path.join(LIVE, name), os.path.join(TREE, name)
    same = os.path.isfile(a) and os.path.isfile(b) and sha(a) == sha(b)
    if not same and name == 'mod.iwd' and os.path.isfile(a) and os.path.isfile(b):
        # A repack changes zip timestamps, not contents: compare entry by entry.
        same = iwd_entries(a) == iwd_entries(b)
    ok &= same
    print(f'{name:14} installed={sha(a) if os.path.isfile(a) else "MISSING"} '
          f'tree={sha(b) if os.path.isfile(b) else "MISSING"} {"OK" if same else "DIFFERS"}')

stamp = os.path.join(LIVE, 'deployed-by.txt')
if os.path.isfile(stamp):
    print('deployed-by:', open(stamp).read().strip().replace('\n', ' | '))

if GUN:
    z = zipfile.ZipFile(os.path.join(LIVE, 'mod.iwd'))
    names = {n.lower() for n in z.namelist()}
    # The camo table is whatever the INSTALLED def names, not a guess from the gun's name.
    camo = None
    real = {n.lower(): n for n in z.namelist()}.get(f'weapons/zm/{GUN}_upgraded_zm')
    if real:
        words = z.read(real).decode('latin-1').split('\\')
        camo = dict(zip(words[1::2], words[2::2])).get('camo')
    listing = subprocess.run([UNLINKER, '--list', os.path.join(LIVE, 'mod.ff')], capture_output=True,
                             text=True, errors='replace').stdout
    hit = bool(camo) and f'camo, {camo}' in listing
    ok &= hit
    print(f'mod.ff  camo, {str(camo):42} {"present" if hit else "ABSENT"}')
    for want in (f'weapons/zm/{GUN}_zm', f'weapons/zm/{GUN}_upgraded_zm', f'scripts/zm/{GUN}.gsc'):
        hit = want in names
        ok &= hit
        print(f'mod.iwd {want:48} {"present" if hit else "ABSENT"}')

print('INSTALLED BUILD VERIFIED' if ok else 'INSTALLED BUILD DOES NOT MATCH')
raise SystemExit(0 if ok else 1)
