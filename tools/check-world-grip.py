"""Check held world skeletons and the measured third-person grip contracts.

Use --model-root on an xmodel/model_export Unlinker readback to check donor
models as well as raw sources. This checks structure, not runtime hand contact.
"""
import argparse
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / 'tools/world-grip-contracts.json'


def glb(path):
    raw = path.read_bytes()
    magic, version, total = struct.unpack_from('<4sII', raw)
    if magic != b'glTF' or version != 2 or total != len(raw):
        raise ValueError(f'{path}: invalid GLB header')
    size, kind = struct.unpack_from('<I4s', raw, 12)
    if kind != b'JSON':
        raise ValueError(f'{path}: missing GLB JSON')
    return json.loads(raw[20:20 + size]), raw[28 + size:]


def positions(doc, data):
    result = []
    seen = set()
    for mesh in doc.get('meshes', []):
        for primitive in mesh['primitives']:
            aid = primitive['attributes']['POSITION']
            if aid in seen:
                continue
            seen.add(aid)
            acc = doc['accessors'][aid]
            view = doc['bufferViews'][acc['bufferView']]
            if acc['componentType'] != 5126 or acc['type'] != 'VEC3':
                raise ValueError('expected float VEC3 positions')
            start = view.get('byteOffset', 0) + acc.get('byteOffset', 0)
            stride = view.get('byteStride', 12)
            result.extend(struct.unpack_from('<3f', data, start + i * stride)
                          for i in range(acc['count']))
    return result


def near(actual, expected, tolerance=0.001):
    return len(actual) == len(expected) and all(
        math.isfinite(a) and abs(a - b) <= tolerance for a, b in zip(actual, expected))


def check_model(doc, data, expected_root, policy=None):
    errors = []
    joints = {j for skin in doc.get('skins', []) for j in skin['joints']}
    children = {c for j in joints for c in doc['nodes'][j].get('children', [])}
    roots = [doc['nodes'][j] for j in joints - children]
    if len(roots) != 1 or roots[0].get('name') != expected_root:
        errors.append(f'world skeleton roots {[n.get("name") for n in roots]}, expected {expected_root}')
    if not policy:
        return errors
    if len(roots) == 1:
        root = roots[0]
        for key, default in [('translation', [0, 0, 0]), ('scale', [1, 1, 1])]:
            if not near(root.get(key, default), default):
                errors.append(f'world root {key} must remain {default}')
        if not near(root.get('rotation', [0, 0, 0, 1]), policy['rootRotation']):
            errors.append('world root rotation differs from the native attachment frame')
    verts = positions(doc, data)
    if not verts:
        errors.append('world mesh has no vertices')
    else:
        lo = [min(p[i] for p in verts) for i in range(3)]
        hi = [max(p[i] for p in verts) for i in range(3)]
        if not near(lo, policy['boundsMin']) or not near(hi, policy['boundsMax']):
            errors.append('world vertices differ from the measured native grip placement')
    tags = [n for n in doc['nodes'] if n.get('name') == policy['muzzleTag']]
    if len(tags) != 1 or not near(tags[0].get('translation', []), policy['muzzlePosition']):
        errors.append('world muzzle tag differs from the translated barrel')
    return errors


def fields(path):
    words = path.read_text(encoding='latin1').split('\\')
    if words[0] != 'WEAPONFILE' or len(words) % 2 != 1:
        raise ValueError(f'{path}: invalid weapon definition')
    return dict(zip(words[1::2], words[2::2]))


def check_categories(definitions, contract):
    errors = []
    for name, policy in contract['weapons'].items():
        values = definitions.get(name, {})
        for key, expected in policy.items():
            if values.get(key) != expected:
                errors.append(f'{name}: {key} is {values.get(key)!r}, expected {expected!r}')
    return errors


def run(model_root=None, stock_root=None):
    contract = json.loads(CONTRACT.read_text(encoding='utf8'))
    definitions = {p.name: fields(p) for p in (ROOT / 'weapons/zm').iterdir() if p.is_file()}
    errors = check_categories(definitions, contract)
    checked, unavailable = set(), set()
    sources = [Path(model_root)] if model_root else [ROOT / 'zone_assets']
    if stock_root:
        sources.append(Path(stock_root))
    for name, values in definitions.items():
        # Projectile and deployable origins are intentionally not hand roots.
        if values.get('inventoryType') not in ('primary', 'altmode', 'dwlefthand'):
            continue
        expected_root = 'tag_weapon1' if values.get('inventoryType') == 'dwlefthand' else 'tag_weapon'
        # Retail crossbow/RPG slot 2 is the rigid dropped/stowed model, not
        # another held grip. It has no skeleton and must not gain a hand root.
        models = {v for k, v in values.items() if k.startswith('worldModel') and v
                  and not (k == 'worldModel2' and values.get('useDroppedModelAsStowed') == '1')}
        for model in models:
            key = (model, expected_root)
            if key in checked:
                continue
            source = next((s for s in sources if (s / 'xmodel' / f'{model}.json').is_file()), None)
            if source is None:
                unavailable.add(model)
                if model in contract['models']:
                    errors.append(f'{name}: required grip model {model} is absent')
                continue
            desc = json.loads((source / 'xmodel' / f'{model}.json').read_text(encoding='utf8'))
            for lod in desc['lods']:
                try:
                    doc, data = glb(source / lod['file'])
                    errors.extend(f'{name}/{model}/{lod["file"]}: {error}' for error in
                                  check_model(doc, data, expected_root, contract['models'].get(model)))
                except (ValueError, OSError, KeyError, struct.error) as exc:
                    errors.append(f'{name}/{model}: {exc}')
            checked.add(key)
    for error in errors:
        print(f'[world-grip] FAIL: {error}')
    print(f'[world-grip] {len(definitions)} definitions inspected, {len(checked)} held model roles checked; '
          f'{len(unavailable)} models require a stock/donor readback')
    if not errors:
        print('[world-grip] PASS: roots, measured pivots, muzzle tags and grip categories')
    return 1 if errors else 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model-root', type=Path)
    parser.add_argument('--stock-model-root', type=Path)
    args = parser.parse_args()
    raise SystemExit(run(args.model_root, args.stock_model_root))
