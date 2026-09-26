r"""t5_def_to_t6.py - rebuild a Black Ops 1 weapon def as a complete T6 def.

The rule every port in this mod follows (pat playbook port-a-bo3-weapon.md
step 5): start from the COMPLETE native T6 def of the same kind, then carry
over the donor's values for every field T6 also has. Field-prefix copying
missed a field once; this is key-by-key.

  template   a shipped zm_qol def with the same weaponClass and fireType
             (rifle/Full Auto -> tar21qol_zm, the most complete rifle), so all
             of T6's fields exist with working values
  carried    every BO1 value whose key is a T6 field. That covers the BO1 gun's
             models, anims, sounds, damage, clip, ranges, timing, spread,
             recoil and hit locations
  kept T6    icons, tracer, muzzle flash, shell eject, shell casing and
             playerAnimType, because BO1's names for those (hud_icon_ak47,
             fx_rifle1_flash_base ...) are BO1 assets T6 does not ship. BO2
             owns an equivalent for each on every map, so the gun gets a flash,
             a tracer and an icon everywhere
  dropped    BO1-only keys (64 on the AK-47: the bounce table, hollowPoint,
             fullMetalJacket ...) and camera anims the engine owns

    python t5_def_to_t6.py <t5 def> <out def> [--template <t6 def>]
Prints what it kept, carried and dropped.
"""
import re
import sys
from pathlib import Path

ZM = Path(r'H:\Plutonium\t6\mods\zm_qol\weapons\zm')
TEMPLATES = {
    ('rifle', 'Full Auto'): 'tar21qol_zm',
    ('rifle', 'Single Shot'): 'm14_upgraded_zm',
    ('rifle', 'Burst'): 'm16qol_zm',
    ('smg', 'Full Auto'): 'mp7_zm',
    ('mg', 'Full Auto'): 'mk48_zm',
    ('spread', 'Single Shot'): 'spas_zm',
    ('spread', 'Full Auto'): 'saiga12qol_zm',
    ('pistol', 'Single Shot'): 'fnp45_zm',
    ('sniper', 'Single Shot'): 't5_l96a1_zm',
    ('rocketlauncher', 'Single Shot'): 'rpg_zm',
}
# T6 names what the BO1 def names only as BO1 assets: keep the template's.
KEEP_T6 = {
    'hudIcon', 'killIcon', 'ammoCounterIcon', 'dpadIcon', 'indicatorIcon',
    'hudIconRatio', 'killIconRatio', 'ammoCounterIconRatio', 'dpadIconRatio', 'indicatorIconRatio',
    'tracerType', 'viewFlashEffect', 'worldFlashEffect', 'viewShellEjectEffect', 'worldShellEjectEffect',
    'viewLastShotEjectEffect', 'worldLastShotEjectEffect', 'shellCasing', 'shellCasingPlayer',
    'playerAnimType', 'camo', 'attachments', 'attachmentUniques',
}


def load(path):
    parts = Path(path).read_bytes().decode('latin-1').split('\\')
    assert parts[0] == 'WEAPONFILE', path
    body = parts[1:]
    return [(body[i], body[i + 1]) for i in range(0, len(body) - 1, 2)], body[len(body) // 2 * 2:]


ASSET_KIND = {'hudIcon': 'material', 'killIcon': 'material', 'ammoCounterIcon': 'material', 'dpadIcon': 'material',
              'indicatorIcon': 'material', 'tracerType': 'tracer', 'viewFlashEffect': 'fx', 'worldFlashEffect': 'fx',
              'viewShellEjectEffect': 'fx', 'worldShellEjectEffect': 'fx', 'viewLastShotEjectEffect': 'fx',
              'worldLastShotEjectEffect': 'fx'}
STOCK = Path(__file__).resolve().parents[2] / 'stock-zone-assets'


def on_every_map():
    """(kind, name) every stock map provides: in all six map zones or a shared one."""
    maps = ['zm_transit', 'zm_nuked', 'zm_highrise', 'zm_prison', 'zm_buried', 'zm_tomb']
    sets = []
    for z in maps + ['common_zm', 'patch_zm']:
        f = STOCK / f'{z}.txt'
        sets.append({tuple(l.split(',', 1)) for l in f.read_text(encoding='utf-8').splitlines() if l} if f.is_file() else set())
    return set.intersection(*sets[:6]) | sets[6] | sets[7]


def convert(t5_path, out_path, template=None):
    t5_pairs, _ = load(t5_path)
    t5 = dict(t5_pairs)
    if template is None:
        name = TEMPLATES.get((t5.get('weaponClass'), t5.get('fireType')))
        if not name:
            raise SystemExit(f'no template for weaponClass={t5.get("weaponClass")} fireType={t5.get("fireType")}; '
                             'pass --template <a zm_qol def of the same kind>')
        template = ZM / name
    t6_pairs, tail = load(template)
    t6_keys = [k for k, _ in t6_pairs]
    carried, kept = [], []
    out = []
    everywhere = on_every_map()
    for k, v in t6_pairs:
        if k in ASSET_KIND and t5.get(k) and (ASSET_KIND[k], t5[k]) in everywhere:
            # BO2 ships the BO1 gun's own icon / flash / tracer on every map: keep it
            out.append((k, t5[k]))
            if t5[k] != v:
                carried.append(k)
        elif k in KEEP_T6:
            kept.append(k)
            out.append((k, v))
        elif k.endswith('CameraAnim'):
            out.append((k, ''))
        elif k in t5:
            if t5[k] != v:
                carried.append(k)
            out.append((k, t5[k]))
        elif k.endswith('Anim') or k.startswith('dtp_') or re.fullmatch(
                r'(gunModel|worldModel|attachViewModel|attachWorldModel)\d*|attach(View|World)ModelTag\d*', k):
            # a slot BO1 does not fill must not keep the template gun's clip or
            # model; empty means the engine uses the base clip for that state
            out.append((k, ''))
        elif 'Sound' in k and v and not v.startswith(('fly_generic', 'wpn_generic', 'wpn_ammo')):
            out.append((k, ''))
        else:
            out.append((k, v))
    dropped = sorted(set(t5) - set(t6_keys))
    flat = ['WEAPONFILE']
    for k, v in out:
        flat += [k, v]
    Path(out_path).write_bytes('\\'.join(flat + tail).encode('latin-1'))
    return Path(template).name, carried, kept, dropped


def main():
    args = sys.argv[1:]
    template = None
    if '--template' in args:
        i = args.index('--template')
        template = Path(args[i + 1])
        del args[i:i + 2]
    tname, carried, kept, dropped = convert(args[0], args[1], template)
    print(f'template {tname}: carried {len(carried)} BO1 values, kept {len(kept)} T6 asset fields, '
          f'dropped {len(dropped)} BO1-only keys')


if __name__ == '__main__':
    main()
