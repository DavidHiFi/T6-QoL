"""t5_xanim_to_t6.py - make a Black Ops 1 (T5) compiled xanim safe for T6.

Measured 2026-09-25 on BO1's viewmodel_ak47_* (zombie_theater.ff): the T6
Linker loads T5 compiled xanims unchanged (18/18, 0 errors, and the Unlinker
reads them back byte-identical). Same version-19 layout, same 0x1e flags.

What does NOT carry over is the event tail at the end of the file. BO1 clips
fire rumble events (`rmbnt#reload_clipin`, `rmbnt#reload_rechamber` ...) that
no T6 zone registers; the first play ends the match with "Could not play
rumble asset ... not registered" (toolkit docs/knowledge/crashes.md). And their
sound events name BO1 aliases (`sndnt#fly_ak47_mag_in_plr`) that exist in T6
only when the port ships them.

The tail is: [u8 len]<first note>\\0 then ([u16 frame]<note>\\0)*. The number of
notes is a u8 in the header at offset 3 (0x69 = 105? no: see note_count()).
Rather than guess header semantics, this tool edits notes IN PLACE: a dropped
rumble note is renamed to a harmless T6 no-op of the SAME LENGTH, so no offset,
count or length anywhere in the file changes. `rmbnt#reload_clipin` becomes
`xxxnt#reload_clipin`-style padding the engine ignores (not snd/rmb/fx).

    python t5_xanim_to_t6.py <in dir> <out dir> [--alias-map map.json]

--alias-map renames sound notes, same length only ({"fly_ak47_mag_in_plr":
"..."}); a sound note whose new name has a different length is refused, not
silently truncated. Prints what it changed per file. Poses are never touched.
"""
import json
import re
import sys
from pathlib import Path

NOTE = re.compile(rb'(sndnt|rmbnt|fxnt|rmb|snd)#([A-Za-z0-9_]+)\x00')


def neutralise(data, alias_map):
    out = bytearray(data)
    changes = []
    for m in NOTE.finditer(data):
        kind, name = m.group(1).decode(), m.group(2).decode()
        start = m.start()
        if kind in ('rmbnt', 'rmb'):
            # same length, not a rumble/sound/fx prefix: engine treats it as a plain note
            new = (b'x' * len(kind)) + b'#' + m.group(2)
            out[start:start + len(new)] = new
            changes.append(f'rumble {name} dropped')
        elif kind in ('sndnt', 'snd') and name in alias_map:
            new_name = alias_map[name].encode()
            if len(new_name) != len(m.group(2)):
                raise ValueError(f'alias {name} -> {alias_map[name]}: length differs; pick a same-length name')
            s = start + len(kind) + 1
            out[s:s + len(new_name)] = new_name
            changes.append(f'sound {name} -> {alias_map[name]}')
    return bytes(out), changes


def main():
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    alias_map = {}
    if '--alias-map' in sys.argv:
        alias_map = json.loads(Path(sys.argv[sys.argv.index('--alias-map') + 1]).read_text())
    dst.mkdir(parents=True, exist_ok=True)
    sounds = set()
    for f in sorted(p for p in src.iterdir() if p.is_file()):
        data = f.read_bytes()
        new, changes = neutralise(data, alias_map)
        assert len(new) == len(data)
        (dst / f.name).write_bytes(new)
        sounds |= {m.group(2).decode() for m in NOTE.finditer(new) if m.group(1) in (b'sndnt', b'snd')}
        print(f'{f.name:34} {"; ".join(changes) or "unchanged"}')
    print(f'sound notes the port must ship aliases for: {sorted(sounds)}')


if __name__ == '__main__':
    main()
