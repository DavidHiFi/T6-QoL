r"""port_weapon.py - scaffold a weapon port into zm_qol from a T6-form source tree.

This is the Blast-O-Matic port (2026-09-25, accepted by the player on the first
try) turned into one command. It does every mechanical step that port did by
hand, and refuses on every trap that port hit. The judgement calls stay with
the agent and are listed in the plan it prints; the port-weapon skill walks
through them.

INPUT: a source tree in T6 raw OAT form - the layout SadSlothXL's t6-ports and
every OAT `zone_raw\mod` folder uses:

    <src>/weapons/<base_def>, <src>/weapons/<upgraded_def>   raw WEAPONFILE defs
    <src>/xmodel/*.json + <src>/model_export/*.glb           models
    <src>/materials/*.json, <src>/images/*.iwi               art
    <src>/camo/<table>.json                                  PaP camo table (optional)
    <src>/soundbank/*.aliases.csv + <src>/sound/**.wav       audio (optional)
    <src>/iwd/mod/xanim/* or <src>/xanim/*                   view animations
    <src>/english/localizedstrings/*.str                     display names (optional)

A gun from another game with no T6 source is first converted INTO this layout
(Saluki / Greyhound export -> Blender / CAST -> GLB; see the skill), then fed
here. A gun that already lives in a retail T6 zone does not need this tool at
all: declare its assets in a zone and --load the map (mod_blundergat.zone).

USAGE
    python tools/port-weapon/port_weapon.py plan  --src <dir> --name <gun> [options]
    python tools/port-weapon/port_weapon.py apply --src <dir> --name <gun> [options]

    --name        short id, lower case: becomes <name>_zm, <name>_upgraded_zm,
                  scripts/zm/<name>.gsc, zone_source/mod_<name>.zone,
                  camo_qol_<name>, `.give <name>`
    --base-def / --upgraded-def   source def file names (auto-detected when the
                  source has exactly one *_upgraded_* def and one other)
    --display / --display-pap     English names (default: read from the source .str)
    --cost        box cost (default 1500, stock's 870 box price)
    --vox         weapon pack vox key (default from the source registration
                  script, else by weaponClass: spread -> wpck_shotgun ...)
    --maps        all | notomb (default notomb: Origins has 0-1 spare precache
                  slots; putting a gun there is a trade the user decides)
    --credit      "who - url", written into the zone banner

`plan` writes nothing and prints every decision and every refusal. `apply`
writes into the tree it is run from (run it from a worktree, never from the
live tree while another thread builds) and then runs the weapon-port gate.
After apply: build_ff.bat, build.bat offline, then a live boot. The skill has
the full order and the live checklist.
"""

import argparse
import csv
import io
import json
import os
import re
import shutil
import struct
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CEILING = 20480
BOUNCE = re.compile(r'^(parallel|perpendicular).*Bounce$', re.IGNORECASE)
ATTACH_OFFSET = re.compile(r'^attachWorldModelOffset(Pitch|Yaw|Roll)[1-8]$')
ANIM_KEYS = {"dtp_in", "dtp_loop", "dtp_out", "dtp_empty_in", "dtp_empty_loop", "dtp_empty_out"}
MODEL_KEY = re.compile(r"(?:gunModel|worldModel|attachViewModel|attachWorldModel)\d*$")
STOCK_MAPS = ["zm_transit", "zm_nuked", "zm_highrise", "zm_prison", "zm_buried", "zm_tomb"]
# Zombies reads three rows of a camo table: 3 = index 39 (stock PaP, animated
# camos OFF), 8 = index 40 (animated, and stock Mob), 12 = index 45 (stock
# Origins). quality_of_life.gsc::get_pack_a_punch_weapon_options has the table.
PAP_SLOTS = (3, 8, 12)
VOX_BY_CLASS = {"spread": "wpck_shotgun", "mg": "wpck_mg", "smg": "wpck_smg",
                "rifle": "wpck_rifle", "sniper": "sniper", "rocketlauncher": "launcher",
                "pistol": "", "pistol spread": ""}
PAD = 44


# ---------------------------------------------------------------- weapon defs
def load_def(path):
    parts = Path(path).read_bytes().decode('latin-1').split('\\')
    if parts[0] != 'WEAPONFILE':
        raise ValueError(f'{path}: not a WEAPONFILE')
    body = parts[1:]
    pairs = [(body[i], body[i + 1]) for i in range(0, len(body) - 1, 2)]
    return pairs, body[len(pairs) * 2:]


def dump_def(pairs, tail):
    flat = ['WEAPONFILE']
    for k, v in pairs:
        flat += [k, v]
    return '\\'.join(flat + tail).encode('latin-1')


def trim_def(pairs, tail, problems, label):
    """The two trims zm_qol has proven, in order, each only when needed."""
    size = len(dump_def(pairs, tail))
    notes = []
    if size >= CEILING:
        bad = [k for k, v in pairs if BOUNCE.match(k) and v.strip() not in ('0', '0.0', '')]
        if bad:
            problems.append(f'{label}: non-zero bounce keys {bad[:3]} - cannot drop them safely')
        pairs = [(k, v) for k, v in pairs if not BOUNCE.match(k)]
        notes.append('dropped the 60 all-zero bounce keys')
        size = len(dump_def(pairs, tail))
    if size >= CEILING:
        bad = [k for k, v in pairs if ATTACH_OFFSET.match(k) and v.strip() not in ('0', '0.0', '')]
        if bad:
            problems.append(f'{label}: still {size} B and attachWorldModelOffset keys are non-zero')
        else:
            pairs = [(k, v) for k, v in pairs if not ATTACH_OFFSET.match(k)]
            notes.append('dropped the 24 all-zero attachWorldModelOffset keys')
            size = len(dump_def(pairs, tail))
    if size >= CEILING:
        problems.append(f'{label}: {size} B after both trims, over the {CEILING} B raw-def ceiling')
    return pairs, size, notes


# ---------------------------------------------------------------- source scan
def find(src, *globs):
    out = []
    for g in globs:
        for p in sorted(Path(src).glob(g)):
            if p not in out:
                out.append(p)
    return out


def scan_source(src):
    s = {}
    s['defs'] = [p for p in find(src, 'weapons/*', 'weapons/zm/*') if p.is_file()]
    s['xmodels'] = find(src, 'xmodel/*.json')
    s['glbs'] = find(src, 'model_export/*.glb')
    s['materials'] = find(src, 'materials/*.json', 'materials/**/*.json')
    s['images'] = find(src, 'images/*.iwi')
    s['camos'] = find(src, 'camo/*.json')
    s['aliases'] = find(src, 'soundbank/*.aliases.csv', 'soundbank/*.csv')
    s['xanims'] = [p for p in find(src, 'iwd/mod/xanim/*', 'xanim/*') if p.is_file()]
    s['strs'] = find(src, 'english/localizedstrings/*.str', 'english/**/*.str')
    s['scripts'] = find(src, 'iwd/mod/scripts/**/*.gsc', 'scripts/**/*.gsc')
    return s


def read_str(paths):
    out = {}
    for p in paths:
        ref = None
        for line in p.read_text(encoding='utf-8', errors='replace').splitlines():
            m = re.match(r'\s*REFERENCE\s+(\S+)', line)
            if m:
                ref = m.group(1)
                continue
            m = re.match(r'\s*LANG_ENGLISH\s+"(.*)"', line)
            if m and ref:
                out[ref] = m.group(1)
                ref = None
    return out


def source_vox(scripts):
    for p in scripts:
        m = re.search(r'add_zombie_weapon\([^;]*?,[^;]*?,[^;]*?,\s*\d+\s*,\s*"([^"]*)"',
                      p.read_text(encoding='utf-8', errors='replace'))
        if m:
            return m.group(1)
    return None


def wav_fmt_len(path):
    with open(path, 'rb') as f:
        head = f.read(64)
    i = head.find(b'fmt ')
    return struct.unpack('<I', head[i + 4:i + 8])[0] if i >= 0 else None


def material_names_in_glb(path):
    b = Path(path).read_bytes()
    n = struct.unpack('<I', b[12:16])[0]
    j = json.loads(b[20:20 + n])
    return {m.get('name') for m in j.get('materials', [])}


# ---------------------------------------------------------------- stock data
def stock_owned():
    """(kind, name) owned by any stock zone the gate caches, and the set every map has."""
    d = ROOT / 'tools' / 'stock-zone-assets'
    per = {}
    for f in d.glob('*.txt'):
        per[f.stem] = {tuple(l.split(',', 1)) for l in f.read_text(encoding='utf-8').split('\n') if l}
    any_owned = set().union(*per.values()) if per else set()
    maps = [per[m] for m in STOCK_MAPS if m in per]
    everywhere = set.intersection(*maps) if len(maps) == 6 else set()
    for z in ('common_zm', 'patch_zm'):
        everywhere |= per.get(z, set())
    return any_owned, everywhere


def r_hash_string(name):
    value = 0
    for ch in name.encode('latin-1'):
        value = ((33 * value) ^ (ch | 0x20)) & 0xFFFFFFFF
    return value


def startup_bank_hashes():
    """Image name hashes in the .ipak banks the client opens on every map (same
    list and reader as tools/check-weapon-port.py). Empty when BO2 is absent."""
    bo2 = Path(os.environ.get('BO2_DIR', r'F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II'))
    found = set()
    for bank in ('patch_zm', 'base', 'zm', 'mp', 'dlczm0_load_zm', 'dlczm0', 'dlczm1', 'dlczm2', 'dlczm3', 'dlczm4'):
        path = bo2 / 'zone' / 'all' / f'{bank}.ipak'
        if not path.is_file():
            continue
        with path.open('rb') as h:
            magic, _v, _s, sections = struct.unpack('<4sIII', h.read(16))
            if magic != b'KAPI':
                continue
            table = [struct.unpack('<IIII', h.read(16)) for _ in range(sections)]
            for kind, offset, _l, count in table:
                if kind == 1:
                    h.seek(offset)
                    data = h.read(count * 16)
                    found.update(struct.unpack_from('<I', data, i * 16 + 4)[0] for i in range(count))
    return found


def mod_owned_names():
    names = set()
    for z in (ROOT / 'zone_source').glob('*.zone'):
        for line in z.read_text(encoding='utf-8-sig', errors='replace').splitlines():
            line = line.split('//', 1)[0].strip()
            if ',' in line and not line.startswith('>'):
                k, n = line.split(',', 1)
                names.add((k.strip(), n.strip().lstrip(',')))
    return names


# ---------------------------------------------------------------- plan
def build_plan(a):
    src = Path(a.src)
    s = scan_source(src)
    p = {'refuse': [], 'warn': [], 'decide': [], 'writes': [], 'notes': []}
    name = a.name.lower()
    if not re.fullmatch(r'[a-z][a-z0-9_]{1,24}', name):
        p['refuse'].append(f'--name {a.name!r}: use lower case letters, digits, underscore')
    base_out, up_out = f'{name}_zm', f'{name}_upgraded_zm'
    camo_out = f'camo_qol_{name}'
    p.update(name=name, base_out=base_out, up_out=up_out, camo_out=camo_out, src=src, scan=s)

    # --- defs
    defs = s['defs']
    base_src = next((d for d in defs if d.name == a.base_def), None) if a.base_def else None
    up_src = next((d for d in defs if d.name == a.upgraded_def), None) if a.upgraded_def else None
    if not up_src:
        ups = [d for d in defs if 'upgraded' in d.name]
        up_src = ups[0] if len(ups) == 1 else None
    if not base_src and up_src:
        rest = [d for d in defs if d != up_src]
        base_src = rest[0] if len(rest) == 1 else None
    if not base_src or not up_src:
        p['refuse'].append(f'could not pick the two defs from {[d.name for d in defs]}; pass --base-def/--upgraded-def')
        return p
    p['base_src'], p['up_src'] = base_src, up_src
    bp, bt = load_def(base_src)
    up, ut = load_def(up_src)
    bd, ud = dict(bp), dict(up)

    # --- display names
    strings = read_str(s['strs'])
    disp_key_b, disp_key_u = bd.get('displayName', ''), ud.get('displayName', '')
    display = a.display or strings.get(disp_key_b)
    display_pap = a.display_pap or strings.get(disp_key_u)
    if not display or not display_pap:
        p['decide'].append(f'display names: base {disp_key_b!r} -> {display!r}, PaP {disp_key_u!r} -> {display_pap!r}; '
                           'pass --display/--display-pap if either is None')
    p['strings'] = {disp_key_b: display, disp_key_u: display_pap}

    # --- camo table: one table, both forms, a name no stock zone owns
    camo_src_name = ud.get('camo') or bd.get('camo')
    camo_src = next((c for c in s['camos'] if c.stem == camo_src_name), None) if camo_src_name else None
    if not camo_src and s['camos']:
        camo_src = s['camos'][0]
    if not camo_src:
        p['refuse'].append('no camo table in the source. Build one from a same-class stock table in '
                           'zone_assets/camo (camo_spas / camo_qol_870mcs) with this gun\'s base materials '
                           'renamed in, then rerun')
        return p
    p['camo_src'] = camo_src

    # --- materials the camo must cover: every camo-able material on the models
    mats = {m.stem: json.loads(m.read_text(encoding='utf-8')) for m in s['materials']}
    glb_mats = set()
    for g in s['glbs']:
        glb_mats |= material_names_in_glb(g)
    missing_mats = sorted(glb_mats - set(mats))
    camo = json.loads(camo_src.read_text(encoding='utf-8'))
    slots = camo.get('camoMaterials', [])
    # The parts the author camo'd: the union over the three PaP slots. A part no
    # slot maps (a shell casing, a glowing meter) was left bare on purpose.
    authored = set()
    for i in PAP_SLOTS:
        if i < len(slots):
            authored |= {o['baseMaterial'] for m in slots[i]['materials'] for o in m['materialOverrides']}
    detail = {m for m, d in mats.items() if any(t.get('name') == 'colorDetailMap' for t in d.get('textures', []))}
    camo_able = sorted(authored & set(mats)) or sorted(detail)
    bare = sorted(detail - set(camo_able))
    if bare:
        p['notes'].append(f'parts with a camo detail map that no PaP slot covers, left bare as the author did: {bare}')
    p['camo_able'] = camo_able
    fill = {}
    for i in PAP_SLOTS:
        if i >= len(slots):
            p['refuse'].append(f'camo table has {len(slots)} slots; slot {i} is missing')
            continue
        mapped = {o['baseMaterial'] for m in slots[i]['materials'] for o in m['materialOverrides']}
        gap = [m for m in camo_able if m not in mapped]
        if gap:
            fill[i] = gap
    p['camo_fill'] = fill
    if fill:
        p['notes'].append('camo slots with gaps get the nearest mapped part\'s camo material: '
                          + '; '.join(f'slot {i}: {g}' for i, g in fill.items()))

    # --- images: every image a material names needs pixels on every map, and
    #     must not be a name a stock map zone owns (mod.ff loads first, so it
    #     would replace that map's own copy of the image header).
    any_owned, everywhere = stock_owned()
    shipped = {i.stem for i in s['images']}
    mod_images = {f.stem for f in (ROOT / 'zone_assets' / 'images').glob('*.iwi')}
    stock_img = {}
    for f in (Path(__file__).parent / 'stock-images').glob('*.txt'):
        for n in f.read_text(encoding='utf-8').splitlines():
            if n:
                stock_img.setdefault(n, []).append(f.stem)
    banks = startup_bank_hashes()
    for m, d in sorted(mats.items()):
        for t in d.get('textures', []):
            img = t['image']
            if img in shipped or img in mod_images:
                continue
            owners = sorted(stock_img.get(img, []))
            shared = [o for o in owners if o in ('common_zm', 'patch_zm')]
            maps = [o for o in owners if o in STOCK_MAPS]
            if shared or len(maps) == 6:
                continue
            if maps:
                p['decide'].append(f'image {img} (material {m}) belongs to {maps} only. Linking it makes mod.ff '
                                   "carry that map's image header and override it there. Point the material at a "
                                   'mod-owned image instead (qolwf_crystal_n / _bub_c / _c / _e for crystal and glow layers)')
            elif r_hash_string(img) not in banks:
                p['refuse'].append(f'image {img} (material {m}) has no pixels anywhere: not shipped, not in any '
                                   'stock zone, not in a startup .ipak. It would draw black. Ship the .iwi')
    if missing_mats:
        p['refuse'].append(f'models name materials the source does not carry: {missing_mats}')

    # --- sounds
    alias_rows, bad_fmt, missing_wav, prefixes = [], [], [], set()
    for f in s['aliases']:
        rows = list(csv.reader(io.StringIO(f.read_text(encoding='utf-8', errors='replace'))))
        if not rows or rows[0][:2] != ['Name', 'FileSource']:
            continue
        for r in rows[1:]:
            if not r or not r[0]:
                continue
            rel = r[1].replace('\\', '/')
            if rel.lower().startswith('raw/'):
                rel = rel[4:]
            wav = src / rel
            if not wav.is_file():
                missing_wav.append(r[1])
            elif wav_fmt_len(wav) not in (16, None):
                bad_fmt.append(rel)
            alias_rows.append(r)
            prefixes.add(r[0].split('_')[0] + '_' + r[0].split('_')[1] + '_' if r[0].count('_') >= 2 else r[0])
    p['alias_rows'], p['alias_prefixes'] = alias_rows, sorted(prefixes)
    if missing_wav:
        p['refuse'].append(f'{len(missing_wav)} alias rows name audio the source lacks, e.g. {missing_wav[:2]}')
    if bad_fmt:
        p['warn'].append(f'{len(bad_fmt)} WAVs have a non-16-byte fmt chunk; OAT shifts their PCM by the extra '
                         f'bytes. Re-encode them to plain PCM first (ffmpeg -i in.wav -c:a pcm_s16le out.wav): {bad_fmt[:3]}')
    stock_alias = []
    alias_names = {r[0] for r in alias_rows}
    add_csv = ROOT / 'soundbank' / 'mod.all.aliases.additions.csv'
    have = {r[0] for r in csv.reader(io.StringIO(add_csv.read_text(encoding='utf-8', errors='replace'))) if r}
    clash = sorted(alias_names & have)
    if clash:
        p['refuse'].append(f'alias names already in mod.all: {clash[:5]} - rename the gun\'s aliases')
    for k, v in list(bd.items()) + list(ud.items()):
        if 'Sound' in k and v and v not in alias_names and not v.startswith(('fly_generic', 'wpn_generic', 'wpn_ammo')):
            stock_alias.append(v)
    if stock_alias:
        p['notes'].append(f'defs also name aliases the source does not define (resolve from the map banks): '
                          f'{sorted(set(stock_alias))[:6]}')

    # --- anims: every anim a def names must be staged
    xanims = {x.name: x for x in s['xanims']}
    named = set()
    for d in (bd, ud):
        for k, v in d.items():
            if v and (k.endswith('Anim') or k in ANIM_KEYS):
                named.add(v)
    missing_anim = sorted(n for n in named if n not in xanims)
    p['xanims'] = sorted(n for n in named if n in xanims)
    if missing_anim:
        p['refuse'].append(f'defs name anims the source lacks: {missing_anim}')
    notes_by_anim = {}
    for n in p['xanims']:
        b = xanims[n].read_bytes()
        found = sorted({m.decode() for m in re.findall(rb'sndnt#[a-z0-9_]+', b)})
        rumble = re.findall(rb'rmbnt#[a-z0-9_]+', b)
        if rumble:
            p['refuse'].append(f'anim {n} carries rumble notetracks {rumble[:2]}; they end the match on first play')
        for t in found:
            alias = t.split('#', 1)[1]
            if alias not in alias_names:
                p['warn'].append(f'anim {n} fires notetrack sound {alias} that no source alias defines')
        notes_by_anim[n] = found
    p['notetracks'] = notes_by_anim
    reload_anims = [bd.get(k) for k in ('reloadAnim', 'reloadEmptyAnim', 'reloadStartAnim', 'reloadEndAnim') if bd.get(k)]
    if reload_anims and not any(notes_by_anim.get(r) for r in reload_anims):
        p['warn'].append('no reload anim carries a sound notetrack: the reload will be silent')

    # --- models every def names
    xmodel_names = {x.stem for x in s['xmodels']}
    need_models = sorted({v for d in (bd, ud) for k, v in d.items() if v and MODEL_KEY.fullmatch(k)})
    for m in need_models:
        if m not in xmodel_names and ('xmodel', m) not in everywhere:
            p['refuse'].append(f'def names xmodel {m} that neither the source nor every stock map has')
    p['xmodels'] = sorted(xmodel_names & set(need_models))

    # --- fx / tracer / rumble / icons: named by the defs, must exist everywhere
    for k, v in list(bd.items()) + list(ud.items()):
        if not v or v.lower() == 'none':
            continue
        kind = ('fx' if re.search(r'(Flash|ShellEject|LastShotEject)Effect$', k) else
                'tracer' if k == 'tracerType' else
                'material' if k in ('hudIcon', 'killIcon', 'ammoCounterIcon', 'dpadIcon') else None)
        if kind and (kind, v) not in everywhere and (kind, v) not in mod_owned_names():
            p['decide'].append(f'{k} names {kind} {v}, not on every stock map and not in mod.ff: declare it in the '
                               'zone (the Linker copies fx out of a --loaded zone) or swap for a stock one')

    # --- name collisions with stock zones and with the mod
    new_names = ({('xmodel', x) for x in p['xmodels']} | {('xanim', x) for x in p['xanims']} |
                 {('material', m) for m in mats} | {('image', i) for i in shipped} | {('camo', camo_out)})
    stock_hits = sorted(n for n in new_names if n in any_owned or (n[0] == 'image' and n[1] in stock_img))
    mod_hits = sorted(n for n in new_names if n in mod_owned_names())
    if stock_hits:
        p['refuse'].append(f'{len(stock_hits)} new names are owned by a stock zone (mod.ff would override the map): {stock_hits[:4]}')
    if mod_hits:
        p['refuse'].append(f'{len(mod_hits)} names already in the mod: {mod_hits[:4]}')
    for out in (base_out, up_out):
        if (ROOT / 'weapons' / 'zm' / out).exists():
            p['refuse'].append(f'weapons/zm/{out} already exists')

    # --- ammo pool: base and upgraded must not share an ammo name with another gun
    for label, d in (('base', bd), ('upgraded', ud)):
        ammo = d.get('ammoName', '')
        others = []
        for f in (ROOT / 'weapons' / 'zm').iterdir():
            if f.name in (base_out, up_out):
                continue
            try:
                if dict(load_def(f)[0]).get('ammoName') == ammo:
                    others.append(f.name)
            except Exception:
                pass
        if others:
            p['decide'].append(f'{label} ammoName {ammo!r} is shared with {others[:3]}: holding both drains one pool. '
                               f'Default fix: set both forms to {ud.get("ammoName") if label == "base" else name!r}')
    p['ammo_fix'] = ud.get('ammoName') if dict(bp).get('ammoName') != ud.get('ammoName') else None

    # --- attachments: a PaP def that declares attachments needs a pap_attach row
    for label, d in (('base', bd), ('upgraded', ud)):
        if d.get('attachments'):
            p['decide'].append(f'{label} def declares attachments {d["attachments"]!r}: clear the field or add a '
                               'zm/pap_attach_qol.csv row (the v1.89.3 crash)')

    # --- trims
    bp2, bsize, bnotes = trim_def([(k, v) for k, v in bp], bt, p['refuse'], base_out)
    up2, usize, unotes = trim_def([(k, v) for k, v in up], ut, p['refuse'], up_out)
    p['defsizes'] = (bsize, usize, bnotes, unotes)

    # --- registration values
    vox = a.vox or source_vox(s['scripts']) or VOX_BY_CLASS.get(bd.get('weaponClass', ''), '')
    p['vox'], p['cost'] = vox, a.cost
    p['maps'] = a.maps
    if a.maps == 'all':
        p['warn'].append('--maps all puts the gun on Origins, which has 0-1 spare precache slots. Budget it '
                         'by boot, and read the crashdump .txt if it dies on "unknown weapon" (names an innocent gun)')
    p['credit'] = a.credit
    return p


def print_plan(p):
    print(f"== port plan: {p.get('name')}")
    if 'base_src' in p:
        s = p['scan']
        print(f"source        {p['src']}")
        print(f"defs          {p['base_src'].name} -> {p['base_out']}   {p['up_src'].name} -> {p['up_out']}")
        b, u, bn, un = p['defsizes']
        print(f"def sizes     {b} B / {u} B after trims ({'; '.join(sorted(set(bn + un))) or 'no trim needed'})")
        print(f"models        {len(p['xmodels'])} xmodels, {len(s['glbs'])} GLB files")
        print(f"anims         {len(p['xanims'])} named by the defs (unreferenced source anims are not staged)")
        print(f"art           {len(s['materials'])} materials, {len(s['images'])} images")
        print(f"camo          {p['camo_src'].name} -> {p['camo_out']}  (camo-able parts: {len(p['camo_able'])})")
        print(f"sound         {len(p['alias_rows'])} alias rows, prefixes {p['alias_prefixes']}")
        print(f"strings       {p['strings']}")
        print(f"register      cost {p['cost']}, vox {p['vox']!r}, maps {p['maps']}")
        nt = {k: v for k, v in p['notetracks'].items() if v}
        print(f"notetracks    {sum(len(v) for v in nt.values())} sound notetracks in {len(nt)} anims")
    for key, title in (('refuse', 'REFUSE'), ('decide', 'DECIDE'), ('warn', 'WARN'), ('notes', 'NOTE')):
        for line in p[key]:
            print(f'{title:7} {line}')
    print('RESULT  ' + ('refused - fix the REFUSE lines' if p['refuse'] else
                        'ready to apply' + (' (answer the DECIDE lines first)' if p['decide'] else '')))


# ---------------------------------------------------------------- apply
def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)


def apply(p, a):
    name, src, s = p['name'], p['src'], p['scan']
    za = ROOT / 'zone_assets'
    # defs
    for src_def, out, extra in ((p['base_src'], p['base_out'], {}), (p['up_src'], p['up_out'], {})):
        pairs, tail = load_def(src_def)
        edits = {'camo': p['camo_out']}
        if p['ammo_fix']:
            edits.update(ammoName=p['ammo_fix'], clipName=p['ammo_fix'])
        pairs = [(k, edits.get(k, v)) for k, v in pairs]
        if 'camo' not in dict(pairs):
            pairs.append(('camo', p['camo_out']))
        pairs, size, _ = trim_def(pairs, tail, [], out)
        (ROOT / 'weapons' / 'zm' / out).write_bytes(dump_def(pairs, tail))
    # art, models, anims
    for f in s['xmodels'] + s['glbs'] + s['materials'] + s['images']:
        rel = f.relative_to(src)
        copy(f, za / rel)
    xanims = {x.name: x for x in s['xanims']}
    for n in p['xanims']:
        copy(xanims[n], za / 'xanim' / n)
    # camo: renamed, gaps filled from the part nearest in the slot's first material
    camo = json.loads(p['camo_src'].read_text(encoding='utf-8'))
    for i, gap in p['camo_fill'].items():
        mats = camo['camoMaterials'][i]['materials']
        first = mats[0]['materialOverrides']
        if not first:
            continue
        donor = first[0]['camoMaterial']
        for base in gap:
            first.append({'baseMaterial': base, 'camoMaterial': donor})
    (za / 'camo' / f"{p['camo_out']}.json").write_text(json.dumps(camo, indent=4), encoding='utf-8')
    # sound: payloads under sound/<name>/, rows appended with raw\ paths
    add_csv = ROOT / 'soundbank' / 'mod.all.aliases.additions.csv'
    text = add_csv.read_text(encoding='utf-8', errors='replace')
    out_rows = []
    for r in p['alias_rows']:
        rel = r[1].replace('\\', '/')
        rel = rel[4:] if rel.lower().startswith('raw/') else rel
        tail = rel[len('sound/'):] if rel.startswith('sound/') else rel
        dst_rel = f'sound/{name}/{tail}'
        copy(src / rel, ROOT / dst_rel)
        r = list(r)
        r[1] = 'raw\\' + dst_rel.replace('/', '\\')
        out_rows.append(r)
    if out_rows:
        buf = io.StringIO()
        csv.writer(buf, lineterminator='\n').writerows(out_rows)
        add_csv.write_text(text + ('' if text.endswith('\n') else '\n') + buf.getvalue(), encoding='utf-8')
    # strings
    str_path = za / 'english' / 'localizedstrings' / 'mod.str'
    st = str_path.read_text(encoding='utf-8')
    block = f'// {p["name"]} - weapon port (tools/port-weapon)\n'
    for ref, eng in p['strings'].items():
        if ref and eng and f'REFERENCE           {ref}\n' not in st:
            block += f'REFERENCE           {ref}\nLANG_ENGLISH        "{eng}"\n\n'
    str_path.write_text(st.replace('ENDMARKER', block + 'ENDMARKER', 1), encoding='utf-8')
    # zone
    zone = [
        '// ' + '=' * 76,
        f'//  mod_{name}.zone  -  generated by tools/port-weapon/port_weapon.py',
        f'//  Source: {p["credit"] or src}',
        '//  Defs ship raw in weapons\\zm\\ and are NOT declared here. Materials and',
        '//  images come along as xmodel sub-assets. Every anim the two defs name.',
        '// ' + '=' * 76, '']
    zone += [f'xmodel,{x}' for x in p['xmodels']] + ['', f'camo,{p["camo_out"]}', '']
    zone += [f'xanim,{x}' for x in p['xanims']]
    (ROOT / 'zone_source' / f'mod_{name}.zone').write_text('\n'.join(zone) + '\n', encoding='utf-8')
    mz = ROOT / 'zone_source' / 'mod.zone'
    mzt = mz.read_text(encoding='utf-8')
    if f'include,mod_{name}' not in mzt:
        mz.write_text(mzt.rstrip('\n') + f'\ninclude,mod_{name}\n', encoding='utf-8')
    # server registration: its own file, never quality_of_life.gsc
    gate = ('    if ( level.script == "zm_tomb" )\n    {\n'
            f'        println( "[zm_qol] {name}: held back on zm_tomb - no precache budget" );\n'
            '        return;\n    }\n\n') if p['maps'] == 'notomb' else ''
    disp_ref = dict(load_def(ROOT / 'weapons' / 'zm' / p['base_out'])[0]).get('displayName')
    gsc = f'''// {name}.gsc - registers the ported {p["strings"].get(disp_ref) or name} in the mystery box.
// Generated by tools/port-weapon/port_weapon.py. Own file on purpose:
// quality_of_life.gsc is full on symbols (AGENTS.md item 1b).

#include maps\\mp\\_utility;
#include common_scripts\\utility;
#include maps\\mp\\zombies\\_zm_utility;
//  add_zombie_weapon() lives here; without it the map dies on "Unresolved external".
#include maps\\mp\\zombies\\_zm_weapons;

init()
{{
{gate}    precacheitem( "{p["base_out"]}" );
    precacheitem( "{p["up_out"]}" );

    include_weapon( "{p["base_out"]}" );
    include_weapon( "{p["up_out"]}", 0 );

    add_zombie_weapon( "{p["base_out"]}", "{p["up_out"]}", &"{disp_ref}", {p["cost"]}, "{p["vox"]}", "", undefined, 1 );

    println( "[zm_qol] {name}: registered on " + level.script );
}}
'''
    (ROOT / 'scripts' / 'zm' / f'{name}.gsc').write_text(gsc, encoding='utf-8')
    # client twin
    csc = ROOT / 'scripts' / 'zm' / 'zm_expanded.csc'
    ct = csc.read_text(encoding='utf-8')
    anchor = '\t//  v2.9.13 - THE EMP GRENADE.'
    if f'"{p["base_out"]}"' not in ct and anchor in ct:
        cond = '\tif ( !b_tomb )\n\t{\n' if p['maps'] == 'notomb' else '\t{\n'
        twin = (f'\t//  {name} - weapon port, server twin scripts\\zm\\{name}.gsc (same map test).\n' + cond +
                f'\t\tclientscripts\\mp\\zombies\\_zm_weapons::include_weapon( "{p["base_out"]}" );\n'
                f'\t\tclientscripts\\mp\\zombies\\_zm_weapons::include_weapon( "{p["up_out"]}", 0 );\n\t}}\n\n')
        csc.write_text(ct.replace(anchor, twin + anchor, 1), encoding='utf-8')
    elif anchor not in ct:
        print(f'WARN    zm_expanded.csc anchor moved: add the client include for {p["base_out"]} by hand')
    # gate contract
    cp = ROOT / 'tools' / 'weapon-port-contracts.json'
    contracts = json.loads(cp.read_text(encoding='utf-8'))
    contracts['ports'] = [c for c in contracts['ports'] if c.get('name') != name]
    contracts['ports'].append({
        'name': name, 'zone': f'zone_source/mod_{name}.zone',
        'weapons': [p['base_out'], p['up_out']], 'camo': p['camo_out'],
        'camoBaseMaterials': p['camo_able'], 'camoSlots': list(PAP_SLOTS),
        'soundPrefixes': p['alias_prefixes'], 'rawMaterials': common_prefix(p['camo_able']) or p['camo_able'][0]})
    cp.write_text(json.dumps(contracts, indent=2) + '\n', encoding='utf-8')
    print(f'applied: weapons/zm/{p["base_out"]}, {p["up_out"]}, zone_source/mod_{name}.zone, '
          f'scripts/zm/{name}.gsc, zm_expanded.csc twin, {len(out_rows)} alias rows, contract')


def common_prefix(names):
    if not names:
        return ''
    pre = os.path.commonprefix(names)
    return pre if len(pre) >= 6 else ''


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('mode', choices=['plan', 'apply'])
    ap.add_argument('--src', required=True)
    ap.add_argument('--name', required=True)
    ap.add_argument('--base-def')
    ap.add_argument('--upgraded-def')
    ap.add_argument('--display')
    ap.add_argument('--display-pap')
    ap.add_argument('--cost', type=int, default=1500)
    ap.add_argument('--vox')
    ap.add_argument('--maps', choices=['notomb', 'all'], default='notomb')
    ap.add_argument('--credit', default='')
    ap.add_argument('--force', action='store_true', help='apply even with DECIDE lines open')
    a = ap.parse_args()
    p = build_plan(a)
    print_plan(p)
    if a.mode == 'plan':
        return 1 if p['refuse'] else 0
    if p['refuse']:
        return 1
    if p['decide'] and not a.force:
        print('apply stopped: answer the DECIDE lines (edit the source or pass the option), or --force')
        return 1
    apply(p, a)
    import subprocess
    return subprocess.run([sys.executable, str(ROOT / 'tools' / 'check-weapon-port.py'), '--source-only']).returncode


if __name__ == '__main__':
    raise SystemExit(main())
