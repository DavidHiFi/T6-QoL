#!/usr/bin/env python3
"""Refuse host-only feature switches in client resource setup. Exit 0 clean, 1 findings, 2 input error."""
import argparse
import json
from pathlib import Path
import re
import tempfile

SWITCHES = ('zmqol_vulture', 'zmqol_ww', 'zmqol_diner_shield',
            'zmqol_mp_weapons', 'emp_all_maps', 'zmqol_wallbuy_box', 'zmqol_claymore_diner_enabled')

# The client files that register what these switches control. A run that did not read every one
# of them proves nothing, so it is an input error rather than a clean result.
REQUIRED = ('scripts/zm/zm_expanded.csc', 'scripts/zm/zapgun.csc', 'scripts/zm/teslagun.csc',
            'scripts/zm/thundergun.csc', 'scripts/zm/Freeze.csc', 'scripts/zm/zm_transit/zm_transit.csc')


def code_only(text):
    # Blank comments but keep their newlines, so reported lines match the file.
    return re.sub(r'//[^\n]*|/\*[\s\S]*?\*/', lambda m: '\n' * m.group().count('\n'), text)


def check(root):
    findings, inspected = [], []
    for path in sorted([*(root / 'scripts').rglob('*.csc'), *(root / 'clientscripts').rglob('*.csc')]):
        data = path.read_bytes()
        if data.startswith(b"\x80GSC"):
            continue  # Compiled stock inputs have no source-level dvar calls to inspect.
        inspected.append(path.relative_to(root).as_posix())
        code = code_only(data.decode("utf-8"))
        for switch in SWITCHES:
            for match in re.finditer(r'getdvar(?:int(?:default)?)?\s*\(\s*#?"' + switch + '"', code, re.I):
                findings.append({'file': inspected[-1], 'line': code[:match.start()].count('\n') + 1,
                                 'switch': switch, 'fix': 'Register resources from map/mode facts; gate acquisition on the server.'})
    return findings, inspected


def self_test():
    # A gated client registration must be found, and a skipped required file must refuse.
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        for rel in REQUIRED:
            (root / rel).parent.mkdir(parents=True, exist_ok=True)
            (root / rel).write_text('init()\n{\n}\n')
        (root / REQUIRED[0]).write_text('init()\n{\n    /* two\n       lines */\n    if ( !getdvarintdefault( "zmqol_vulture", 1 ) )\n        return;\n}\n')
        findings, inspected = check(root)
        if [(f['file'], f['line'], f['switch']) for f in findings] != [(REQUIRED[0], 5, 'zmqol_vulture')]:
            return 'a gated registration was not reported at its line'
        (root / REQUIRED[1]).write_bytes(b'\x80GSC')
        if REQUIRED[1] in check(root)[1]:
            return 'a compiled required file counted as inspected'
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--self-test', action='store_true', help='check the checker on a planted fixture')
    args = parser.parse_args()
    if args.self_test:
        error = self_test()
        print(json.dumps({'ok': error is None, 'self_test': error or 'passed'}))
        return 1 if error else 0
    if not (args.root / 'scripts/zm/quality_of_life.gsc').is_file():
        print(json.dumps({'ok': False, 'error': 'Pass --root pointing to a T6-QoL source checkout.'}))
        return 2
    findings, inspected = check(args.root)
    missing = [rel for rel in REQUIRED if rel not in inspected]
    if missing:
        print(json.dumps({'ok': False, 'error': 'Required client sources were not read as source.', 'missing': missing}))
        return 2
    print(json.dumps({'ok': not findings, 'findings': findings, 'switches': list(SWITCHES),
                      'inspected': len(inspected)}, indent=2))
    return int(bool(findings))


if __name__ == '__main__':
    raise SystemExit(main())
