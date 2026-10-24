#!/usr/bin/env python3
"""Refuse host-only feature switches in client resource setup. Exit 0 clean, 1 findings, 2 input error."""
import argparse
import json
from pathlib import Path
import re

SWITCHES = ('zmqol_vulture', 'zmqol_ww', 'zmqol_diner_shield',
            'zmqol_mp_weapons', 'emp_all_maps', 'zmqol_wallbuy_box', 'zmqol_claymore_diner_enabled')


def code_only(text):
    return re.sub(r'//[^\n]*|/\*[\s\S]*?\*/', '', text)


def check(root):
    findings = []
    for path in sorted([*(root / 'scripts').rglob('*.csc'), *(root / 'clientscripts').rglob('*.csc')]):
        code = code_only(path.read_text())
        for switch in SWITCHES:
            for match in re.finditer(r'getdvar(?:int(?:default)?)?\s*\(\s*#?"' + switch + '"', code, re.I):
                findings.append({'file': str(path.relative_to(root)), 'line': code[:match.start()].count('\n') + 1,
                                 'switch': switch, 'fix': 'Register resources from map/mode facts; gate acquisition on the server.'})
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    if not (args.root / 'scripts/zm/quality_of_life.gsc').is_file():
        print(json.dumps({'ok': False, 'error': 'Pass --root pointing to a T6-QoL source checkout.'}))
        return 2
    findings = check(args.root)
    print(json.dumps({'ok': not findings, 'findings': findings, 'switches': list(SWITCHES)}, indent=2))
    return int(bool(findings))


if __name__ == '__main__':
    raise SystemExit(main())
