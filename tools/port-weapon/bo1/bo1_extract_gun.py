r"""bo1_extract_gun.py - pull a Black Ops 1 gun out of the installed game into
the T6 raw source layout that tools\port-weapon\port_weapon.py consumes.

    python bo1_extract_gun.py <bo1 zone name> <bo1 weapon def> <out dir>
    python bo1_extract_gun.py zombie_theater ak47_zm  H:\...\ak47_src

Everything comes from `F:\SteamLibrary\steamapps\common\Call of Duty Black Ops`:

  weapon def   Unlinker --include-assets weapon over zone\Common\<zone>.ff
  xmodels      --include-assets xmodel --model-format GLB; T5 JSON gets the
               T6 lighting-origin fields
  materials    t5_material_to_t6.py (T6 lit weapon techset, the L96A1 recipe);
               material slots the zone holds only as bare references (scopes,
               mags, flamer: attachment parts a zombies def never shows) are
               pointed at the gun's body material inside the GLB
  images       the zone's DDS, else BO1 main\*.iwd T5 IWI -> DDS (--t5);
               then DDS -> T6 IWI (--t6)
  xanims       every anim the def names; T5 compiled xanims load in the T6
               Linker unchanged; t5_xanim_to_t6.py neutralises rumble notetracks
  sounds       every alias the def and notetracks fire, from
               raw\soundaliases\*.csv, payloads decoded by bo1_snd_to_wav.py.
               Aliases are written in the T6 60-column layout under a private
               <prefix>_ name so nothing shadows a stock BO2 alias

Measured 2026-09-25 on the AK-47 whose files sit in zombie_theater.ff (it is
not a Kino weapon): a full scratch link (2 xmodels, 3 materials, 8 images, 18
xanims) is 0 errors. The output still goes through port_weapon.py plan/apply,
which adds the PaP form, camo table, registration and gate contract.
"""
import csv
import json
import re
import shutil
import struct
import subprocess
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
BO1 = Path(r'F:\SteamLibrary\steamapps\common\Call of Duty Black Ops')
OAT = Path(r'H:\Plutonium\tools\oat-dlc5')
CONV = Path(r'H:\Plutonium\tools\oat-windows\ImageConverter.exe')
sys.path.insert(0, str(HERE))
import t5_material_to_t6 as t5mat   # noqa: E402
import t5_xanim_to_t6 as t5anim     # noqa: E402
import bo1_snd_to_wav as t5snd      # noqa: E402

T6_ALIAS_HEADER = ('Name,FileSource,Secondary,Storage,Bus,VolumeGroup,DuckGroup,Duck,ReverbSend,CenterSend,VolMin,'
                   'VolMax,DistMin,DistMaxDry,DistMaxWet,DryMinCurve,DryMaxCurve,WetMinCurve,WetMaxCurve,LimitCount,'
                   'EntityLimitCount,LimitType,EntityLimitType,PitchMin,PitchMax,PriorityMin,PriorityMax,'
                   'PriorityThresholdMin,PriorityThresholdMax,PanType,Pan,Looping,RandomizeType,Probability,StartDelay,'
                   'EnvelopMin,EnvelopMax,EnvelopPercent,OcclusionLevel,IsBig,DistanceLpf,FluxType,FluxTime,Subtitle,'
                   'Doppler,ContextType,ContextValue,Timescale,IsMusic,IsCinematic,FadeIn,FadeOut,Pauseable,'
                   'StopOnEntDeath,StopOnPlay,DopplerScale,FutzPatch,VoiceLimit,IgnoreMaxDist,NeverPlayTwice').split(',')
# The Blast-O-Matic's own shipped rows are the templates: a player fire row, an
# npc fire row and a foley row, all already proven in game.
TEMPLATES = {
    'plr': 't9_gallo_fire_plr', 'npc': 't9_gallo_fire_npc', 'foley': 't9_gallo_reload_end',
}
ADDITIONS = Path(r'H:\Plutonium\t6\mods\zm_qol\soundbank\mod.all.aliases.additions.csv')


def run(args, **kw):
    return subprocess.run([str(a) for a in args], capture_output=True, text=True, **kw)


def load_def(path):
    words = path.read_bytes().decode('latin-1').split('\\')
    return dict(zip(words[1::2], words[2::2]))


def main():
    zone, weapon, out = sys.argv[1], sys.argv[2], Path(sys.argv[3])
    ff = BO1 / 'zone' / 'Common' / f'{zone}.ff'
    if not ff.is_file():
        sys.exit(f'no {ff}')
    if out.exists():
        sys.exit(f'{out} exists; pick a new folder')
    dump = out.parent / (out.name + '_bo1dump')
    r = run([OAT / 'Unlinker.exe', '--include-assets', 'weapon,xmodel,xanim,material,image',
             '--model-format', 'GLB', '--image-format', 'DDS',
             '--search-path', f'{BO1 / "zone" / "Common"};{BO1 / "zone" / "English"}', '-o', dump, ff])
    wdef = dump / 'weapons' / weapon
    if not wdef.is_file():
        sys.exit(f'{zone}.ff has no weapon {weapon}; available: {sorted(p.name for p in (dump / "weapons").iterdir())}')
    for sub in ('weapons', 'xmodel', 'model_export', 'materials', 'images', 'xanim', 'sound', 'soundbank'):
        (out / sub).mkdir(parents=True, exist_ok=True)
    shutil.copyfile(wdef, out / 'weapons' / weapon)
    # The Pack-a-Punched def is not in the map zone, but BO1's main\*.iwd carries
    # every zombies weapon def as a raw file (weapons/sp/<name>, 189 of them,
    # every gun with its _upgraded_zm twin).
    up_name = weapon.replace('_zm', '_upgraded_zm') if weapon.endswith('_zm') else weapon + '_upgraded'
    for iwd in sorted((BO1 / 'main').glob('*.iwd')):
        z = zipfile.ZipFile(iwd)
        if f'weapons/sp/{up_name}' in z.namelist():
            # The raw iwd def is BO1-authored and sparse (530 keys vs the zone
            # dump's full 745). Build the PaP def the way every port here does:
            # start from the COMPLETE base def and overlay only the keys the
            # upgraded file sets, in the base def's key order.
            words = z.read(f'weapons/sp/{up_name}').decode('latin-1').split('\\')
            up_vals = dict(zip(words[1::2], words[2::2]))
            base_words = wdef.read_bytes().decode('latin-1').split('\\')
            keys = base_words[1::2]
            vals = dict(zip(base_words[1::2], base_words[2::2]))
            merged = [(k, up_vals.get(k, vals[k])) for k in keys]
            flat = ['WEAPONFILE'] + [x for kv in merged for x in kv]
            (out / 'weapons' / up_name).write_bytes('\\'.join(flat).encode('latin-1'))
            extra = sorted(set(up_vals) - set(keys))
            if extra:
                print(f'NOTE {up_name}: BO1-only keys dropped (no T6 field): {extra}')
            break
    else:
        print(f'WARN no {up_name} in BO1 main\\*.iwd: the port gets no Pack-a-Punch form from BO1')
    # Both forms become complete T6 defs (t5_def_to_t6.py): the closest native
    # template, BO1's values for every shared field, T6 assets where BO2 has no
    # copy of BO1's.
    import t5_def_to_t6 as t5def
    for f in list((out / 'weapons').iterdir()):
        tname, carried, kept, dropped = t5def.convert(f, f)
        print(f'def  {f.name}: template {tname}, {len(carried)} BO1 values carried, {len(dropped)} BO1-only keys dropped')
    d = load_def(wdef)
    up = out / 'weapons' / up_name
    if up.is_file():
        # the PaP form's own models and anims must come along too
        du = load_def(up)
        d = {**du, **d, **{f'__up_{k}': v for k, v in du.items()}}

    # models
    models = sorted({v for k, v in d.items() if v and re.fullmatch(r'(?:__up_)?(gunModel|worldModel)\d*', k)})
    glbs = []
    for m in models:
        xj = dump / 'xmodel' / f'{m}.json'
        if not xj.is_file():
            print(f'WARN model {m} not in this zone')
            continue
        x = json.loads(xj.read_text(encoding='utf-8'))
        x['_game'] = 't6'
        x.setdefault('lightingOriginOffset', {'x': 0.0, 'y': 0.0, 'z': 0.5})
        x.setdefault('lightingOriginRange', 0.5)
        for lod in x['lods']:
            glbs.append(lod['file'])
            shutil.copyfile(dump / lod['file'], out / lod['file'])
        (out / 'xmodel' / f'{m}.json').write_text(json.dumps(x, indent=4), encoding='utf-8')

    # materials: convert those the zone owns, repoint bare references at the body
    mats = set()
    for g in glbs:
        b = (out / g).read_bytes()
        n = struct.unpack('<I', b[12:16])[0]
        mats |= {m['name'] for m in json.loads(b[20:20 + n]).get('materials', [])}
    template = json.loads(t5mat.TEMPLATE.read_text(encoding='utf-8'))
    owned = []
    for m in sorted(mats):
        src = dump / 'materials' / f'{m}.json'
        if not src.is_file():
            continue
        try:
            t6 = t5mat.convert(json.loads(src.read_text(encoding='utf-8')), template)
        except ValueError:
            continue
        dst = out / 'materials' / f'{m}.json'
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(json.dumps(t6, indent=4), encoding='utf-8')
        owned.append(m)
    body = next((m for m in owned if 'gunset' in m and 'attach' not in m and 'plastic' not in m), owned[0] if owned else None)
    bare = [m for m in mats if m not in owned]
    if bare and body:
        for g in glbs:
            p = out / g
            b = p.read_bytes()
            n = struct.unpack('<I', b[12:16])[0]
            j = json.loads(b[20:20 + n])
            for mat in j.get('materials', []):
                if mat['name'] in bare:
                    mat['name'] = body
            new = json.dumps(j, separators=(',', ':')).encode()
            new += b' ' * ((-len(new)) % 4)
            rest = b[20 + n:]
            p.write_bytes(b[:8] + struct.pack('<I', 20 + len(new) + len(rest)) + struct.pack('<I', len(new)) + b[16:20] + new + rest)

    # images
    need = set()
    for f in (out / 'materials').rglob('*.json'):
        need |= {t['image'] for t in json.loads(f.read_text(encoding='utf-8'))['textures']}
    need = {i for i in need if not i.startswith('$') and i != 'camo_off_pattern'}
    work = out.parent / (out.name + '_img')
    work.mkdir(exist_ok=True)
    missing = []
    for img in need:
        src = dump / 'images' / f'{img}.dds'
        if src.is_file():
            shutil.copyfile(src, work / src.name)
        else:
            missing.append(img)
    if missing:
        for iwd in sorted((BO1 / 'main').glob('*.iwd')):
            z = zipfile.ZipFile(iwd)
            idx = {Path(n).stem.lower(): n for n in z.namelist() if n.lower().endswith('.iwi')}
            for img in list(missing):
                if img.lower() in idx:
                    (work / f'{img}.iwi').write_bytes(z.read(idx[img.lower()]))
                    missing.remove(img)
        run([CONV, '--t5', *work.glob('*.iwi')], cwd=work)
        for p in work.glob('*.iwi'):
            p.unlink()
    run([CONV, '--t6', *work.glob('*.dds')], cwd=work)
    for p in work.glob('*.iwi'):
        shutil.move(str(p), out / 'images' / p.name)
    shutil.rmtree(work, ignore_errors=True)

    # anims the def names (not camera anims, which the engine owns), rumble neutralised
    anims = sorted({v for k, v in d.items() if v and (k.endswith('Anim') or k.startswith('dtp_'))
                    and not k.endswith('CameraAnim')})
    raw_notes = {}
    for a in anims:
        src = dump / 'xanim' / a
        if not src.is_file():
            print(f'WARN anim {a} not in this zone')
            continue
        data, _ = t5anim.neutralise(src.read_bytes(), {})
        raw_notes[a] = data
    notes = {m.group(2).decode() for data in raw_notes.values() for m in t5anim.NOTE.finditer(data)
             if m.group(1) in (b'sndnt', b'snd')}

    # Private alias names. BO1's names (wpn_ak47_fire_plr ...) are often already
    # BO2 or zm_qol names, and a mod alias that shares a stock name shadows the
    # user's sound pack. A notetrack string is fixed-length inside the xanim, so
    # every rename keeps the length: the first 3 characters become "b1_" style
    # ("wpn_ak47_fire_plr" -> "b1_ak47_fire_plr" is shorter, so instead the
    # prefix is overwritten in place: "wpn_" -> "bo1_", "fly_" -> "fb1_").
    def private(name):
        head, _, rest = name.partition('_')
        new = {'wpn': 'bo1', 'fly': 'fb1', 'evt': 'eb1', 'zmb': 'zb1'}.get(head, 'b' + head[1:] if len(head) > 1 else head)
        return f'{new}_{rest}' if rest else name
    rename = {}

    # sounds: aliases the def or notetracks fire, from BO1's alias CSVs
    want = {v for k, v in d.items() if 'Sound' in k and v} | notes
    t5rows = {}
    for f in (BO1 / 'raw' / 'soundaliases').glob('*.csv'):
        rows = list(csv.reader(f.open(encoding='latin-1', errors='replace')))
        if rows and rows[0][:2] == ['name', 'file']:
            for r in rows[1:]:
                if r and r[0] in want:
                    t5rows.setdefault(r[0], []).append(r)
    t6tpl = {}
    for r in csv.reader(ADDITIONS.open(encoding='utf-8', errors='replace')):
        for key, name in TEMPLATES.items():
            if r and r[0] == name and key not in t6tpl:
                t6tpl[key] = r
    stock_generic = {'fly_generic_', 'wpn_generic_', 'wpn_ammo_'}
    out_rows = []
    for alias, rows in sorted(t5rows.items()):
        if any(alias.startswith(s) for s in stock_generic):
            continue
        for r in rows:
            rel = r[1].replace('\\', '/')
            srcs = [BO1 / 'raw' / 'sound' / rel] if rel.lower().endswith('.wav') else sorted((BO1 / 'raw' / 'sound' / rel).glob('*.wav'))
            for s in srcs:
                if not s.is_file():
                    continue
                dst_rel = Path('sound') / 'bo1' / s.relative_to(BO1 / 'raw' / 'sound')
                try:
                    t5snd.convert(s, out / dst_rel)
                except Exception as e:
                    print(f'WARN sound {s.name}: {e}')
                    continue
                kind = 'plr' if alias.endswith('_plr') and 'fire' in alias else 'npc' if 'fire' in alias else 'foley'
                row = list(t6tpl[kind])
                rename[alias] = private(alias)
                row[0] = rename[alias]
                row[1] = 'raw\\' + str(dst_rel).replace('/', '\\')
                row[2] = ''
                out_rows.append(row)

    # apply the private names: anim notetracks (same length) and both defs
    for a, data in raw_notes.items():
        same_len = {k: v for k, v in rename.items() if len(k) == len(v)}
        data, _ = t5anim.neutralise(data, same_len)
        (out / 'xanim' / a).write_bytes(data)
    for wf in (out / 'weapons').iterdir():
        words = wf.read_bytes().decode('latin-1').split('\\')
        for i in range(2, len(words), 2):
            key = words[i - 1]
            if 'Sound' in key and words[i] in rename:
                words[i] = rename[words[i]]
            elif key.endswith('CameraAnim'):
                words[i] = ''
        wf.write_bytes('\\'.join(words).encode('latin-1'))
    with (out / 'soundbank' / 'mod.all.aliases.csv').open('w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh, lineterminator='\n')
        w.writerow(T6_ALIAS_HEADER)
        w.writerows(out_rows)

    print(f'{weapon}: {len(models)} models, {len(owned)} materials (+{len(bare)} bare refs -> {body}), '
          f'{len(list((out / "images").glob("*.iwi")))} images, {len(list((out / "xanim").iterdir()))} anims, '
          f'{len(out_rows)} sound rows for {len({r[0] for r in out_rows})} aliases')
    print(f'next: python tools\\port-weapon\\port_weapon.py plan --src {out} --name <gun> '
          '(the PaP form, camo table and registration come from there)')


if __name__ == '__main__':
    main()
