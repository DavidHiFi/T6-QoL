"""gen_swell_models.py - Wave Gun swell copies of the stock zombie models.

The friend's build-11 Der Riese swell (halo_wg_*), done for our four maps.
For every stock zombie body and head the gun can kill it writes a copy named
zqwg_<stock name> that is identical to the stock model except:

  * every vertex normal is WELDED: all vertices that share a position (across
    every surface of the model) get the renormalised sum of their normals.
    BO1 Moon's bloat pushes each vertex along its normal; on a stock mesh a
    hard edge carries two normals, so the push tears the mesh open there
    (c_zom_zombie1_body01 has 115 such seams, most over 60 degrees). Welded,
    the whole body inflates as one surface. Measured on the friend's
    halo_wg_body1 against Der Riese's c_ger_honorguard_zombie_body1: same
    positions, UVs and weights, 1,428 split normals -> 0, plain mean.
  * its lit materials are zqwg_ copies of the stock ones on the swell
    techsets (mc_sw4_3d_char_cloth_4z8fq5wu_dlc5 / ..._skin_j92387z3_dlc5),
    whose vertex shaders carry Moon's one extra line. Unlit eye layers, gore
    and anything else keep their stock material.

Inputs:  stock\<zone>\  (Unlinker dumps: xmodel, material, techniqueset)
Outputs: <checkout>\zone_assets\{xmodel,model_export,materials\mc}\zqwg_*
         swell-zone-lines.txt, swell-table.json
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glbio import load, save, read, write

JOB = os.path.dirname(os.path.abspath(__file__))
ZA = os.path.join(JOB, 'checkout', 'zone_assets')
PREFIX = 'zqwg_'

SWELL_TECH = {
    'mc_sw4_3d_char_cloth_4z8fq5wu': 'mc_sw4_3d_char_cloth_4z8fq5wu_dlc5',
    'mc_sw4_3d_char_skin_j92387z3': 'mc_sw4_3d_char_skin_j92387z3_dlc5',
}

# Per map: the bodies and heads its basic zombies spawn with (stock character
# scripts via enum_models.py), plus Die Rise's Jumping Jack. c_zom_zombie9_*
# is TranZit grief/encounter only and is left out to save model indices.
EXTRA = {'zm_highrise': (['c_zom_leaper_body'], ['c_zom_leaper_head'])}


def zone_of(name, where):
    if name in where:
        return where[name]
    for z in os.listdir(os.path.join(JOB, 'stock')):
        if os.path.exists(os.path.join(JOB, 'stock', z, 'xmodel', name + '.json')):
            return z
    raise SystemExit('no stock dump carries ' + name)


def weld(js, binary):
    """Average normals over every vertex that shares a position, all primitives."""
    groups = {}
    prims = []
    for mesh in js['meshes']:
        for prim in mesh['primitives']:
            a = prim['attributes']
            pos = read(js, binary, a['POSITION'])
            nrm = read(js, binary, a['NORMAL'])
            prims.append((a['NORMAL'], pos, nrm))
            for p, n in zip(pos, nrm):
                k = (round(p[0], 3), round(p[1], 3), round(p[2], 3))
                s = groups.get(k)
                if s is None:
                    groups[k] = [n[0], n[1], n[2]]
                else:
                    s[0] += n[0]; s[1] += n[1]; s[2] += n[2]
    split = 0
    for acc, pos, nrm in prims:
        out = []
        for p, n in zip(pos, nrm):
            s = groups[(round(p[0], 3), round(p[1], 3), round(p[2], 3))]
            l = math.sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2])
            w = (s[0] / l, s[1] / l, s[2] / l) if l > 1e-6 else tuple(n)
            if math.dist(w, n) > 0.05:
                split += 1
            out.append(w)
        write(js, binary, acc, out)
    return split


def main():
    models = json.load(open(os.path.join(JOB, 'stock-models.json')))
    where = json.load(open(os.path.join(JOB, 'model-zone.json')))
    for sub in ('xmodel', 'model_export', os.path.join('materials', 'mc')):
        os.makedirs(os.path.join(ZA, sub), exist_ok=True)

    table = {}          # map -> [[stock, copy], ...]
    made_models = {}
    made_mats = {}
    moved = 0
    for mapname, v in models.items():
        bodies = [m for m in v['bodies'] if not m.startswith('c_zom_zombie9')]
        heads = list(v['heads'])
        eb, eh = EXTRA.get(mapname, ([], []))
        bodies += eb
        heads += eh
        table[mapname] = []
        for name in bodies + heads:
            copy = PREFIX + name
            table[mapname].append([name, copy])
            if name in made_models:
                continue
            z = zone_of(name, where)
            base = os.path.join(JOB, 'stock', z)
            xj = json.load(open(os.path.join(base, 'xmodel', name + '.json')))
            n_swell = 0
            for lod in xj['lods']:
                src = os.path.join(base, lod['file'].replace('/', os.sep))
                js, binary = load(src)
                moved += weld(js, binary)
                # EVERY surface gets its own zqwg_ material, not only the lit
                # ones. A stock name left on the copy is an undeclared
                # dependency, and one no --load zone carries (Nuketown's _u /
                # _ub eye layers - zm_nuked.ff is not loaded) is resolved from
                # zone_assets instead, where the v2.15.46 json still points at
                # the NORMAL-reading eye swell techset: that would override
                # every Nuketown head with the draw that made heads vanish in
                # v2.16.1. Own names cannot collide with a stock asset at all.
                for mt in js.get('materials', []):
                    mname = mt['name']
                    mpath = os.path.join(base, 'materials', mname.replace('/', os.sep) + '.json')
                    if not os.path.exists(mpath):
                        raise SystemExit('no stock material dump for %s on %s' % (mname, name))
                    mj = json.load(open(mpath))
                    tech = mj.get('techniqueSet')
                    newname = 'mc/' + PREFIX + mname.split('/', 1)[1]
                    mt['name'] = newname
                    if tech in SWELL_TECH:
                        n_swell += 1
                    if newname not in made_mats:
                        if tech in SWELL_TECH:
                            mj['techniqueSet'] = SWELL_TECH[tech]
                        mj.pop('thermalMaterial', None)
                        json.dump(mj, open(os.path.join(ZA, 'materials', newname.replace('/', os.sep) + '.json'), 'w'), indent=4)
                        made_mats[newname] = mname
                stem = os.path.basename(lod['file'])
                newfile = 'model_export/' + stem.replace(name, copy, 1)
                save(os.path.join(ZA, newfile.replace('/', os.sep)), js, binary)
                lod['file'] = newfile
            if not n_swell:
                print('WARN no swell surface on', name)
            json.dump(xj, open(os.path.join(ZA, 'xmodel', copy + '.json'), 'w'), indent=4)
            made_models[name] = copy
            print('made', copy, 'lods', len(xj['lods']), 'swell surfaces', n_swell)

    lines = ['material,' + m for m in sorted(made_mats)] + ['xmodel,' + made_models[m] for m in sorted(made_models)]
    open(os.path.join(JOB, 'swell-zone-lines.txt'), 'w').write('\n'.join(lines) + '\n')
    json.dump(table, open(os.path.join(JOB, 'swell-table.json'), 'w'), indent=1)
    print('models', len(made_models), 'materials', len(made_mats), 'normals changed', moved)
    for mp, t in table.items():
        print(mp, 'precache', len(t))


if __name__ == '__main__':
    main()
