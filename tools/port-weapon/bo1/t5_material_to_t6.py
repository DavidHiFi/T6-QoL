"""t5_material_to_t6.py - rebuild a Black Ops 1 weapon material as a T6 one.

The recipe is the one this mod already ships and plays: the BO1 L96A1's
materials in mod.ff (mtl_t5_l96a1_base etc., from zm_refreshed) are exactly
this shape. T6's lit weapon techset `mc_lit_sm_r0c0n0s0o0_3z86zq2z` with:

    specularMap   <- the T5 specularMap
    normalMap     <- the T5 normalMap ($identitynormalmap when absent)
    occlusionMap  <- $gray            (T5 has no occlusion map)
    colorMap      <- the T5 colorMap
    colorDetailMap<- camo_off_pattern (so the PaP camo tables can override it)

T5's env/reflection map and envMapParms have no slot on the T6 techset and
are dropped. Everything else (state bits, sort key, surface flags) is taken
from a working T6 weapon material, so the result is a T6 material that only
differs from the Blast-O-Matic's in names.

    python t5_material_to_t6.py <t5 materials dir> <out dir> [--rename OLD=NEW ...]

--rename renames the material (file and name) so it can never collide with a
name BO2 owns; images keep their names (they ship beside the material).
"""
import copy
import json
import sys
from pathlib import Path

TEMPLATE = Path(r'H:\Plutonium\t6\mods\zm_qol\zone_assets\materials\mtl_t9_gallo_blastomatic_body.json')
WEAPON_TECHSET = 'mc_lit_sm_r0c0n0s0o0_3z86zq2z'


def convert(t5, template):
    src = {t.get('name'): t['image'] for t in t5.get('textures', []) if t.get('name')}
    if 'colorMap' not in src:
        raise ValueError('no colorMap: not a lit weapon material')
    out = copy.deepcopy(template)
    out['techniqueSet'] = WEAPON_TECHSET
    want = {
        'specularMap': src.get('specularMap', '$white'),
        'normalMap': src.get('normalMap', '$identitynormalmap'),
        'occlusionMap': '$gray',
        'colorMap': src['colorMap'],
        'colorDetailMap': 'camo_off_pattern',
    }
    for t in out['textures']:
        t['image'] = want[t['name']]
    for c in out.get('constants', []):
        if c.get('name') == 'colorDetailScale':
            t5c = {k.get('name'): k.get('literal') for k in t5.get('constants', [])}
            if 'colorDetailScale' in t5c:
                c['literal'] = t5c['colorDetailScale']
    return out


def main():
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    renames = dict(a.split('=', 1) for a in sys.argv[3:] if '=' in a)
    template = json.loads(TEMPLATE.read_text(encoding='utf-8'))
    dst.mkdir(parents=True, exist_ok=True)
    for f in sorted(src.rglob('*.json')):
        t5 = json.loads(f.read_text(encoding='utf-8'))
        if t5.get('_type') != 'material':
            continue
        try:
            t6 = convert(t5, template)
        except ValueError as e:
            print(f'skip {f.stem}: {e}')
            continue
        name = renames.get(f.stem, f.stem)
        (dst / f'{name}.json').write_text(json.dumps(t6, indent=4), encoding='utf-8')
        print(f'ok   {f.stem} -> {name}: ' + ', '.join(f'{t["name"]}={t["image"]}' for t in t6['textures']))


if __name__ == '__main__':
    main()
