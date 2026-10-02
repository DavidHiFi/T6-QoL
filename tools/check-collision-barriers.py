"""Source gate for survival collision visibility; does not prove engine behavior."""

import argparse
import re
from pathlib import Path


def source(path):
    return re.sub(r"/\*.*?\*/|//[^\n]*", "", path.read_text(encoding="utf-8-sig"), flags=re.S)


def body(text, name):
    match = re.search(r"^" + name + r"\([^\n]*\)\s*\{", text, re.M)
    assert match, f"Missing function {name}"
    start = match.end()
    depth = 1
    for pos in range(start, len(text)):
        depth += (text[pos] == "{") - (text[pos] == "}")
        if depth == 0:
            return text[start:pos]
    raise AssertionError(f"Unclosed function {name}")


def check(root):
    locs = root / "scripts/zm/locs"
    common = source(locs / "loc_common.gsc")
    barrier = body(common, "barrier")
    guard = r'if\s*\(issubstr\(model,\s*"collision_"\)\)\s*\{\s*barrier hide\(\);\s*\}'
    assert re.search(r'barrier setModel\(model\);\s*' + guard, barrier), "Collision models must be hidden independently of disconnect_paths"
    assert len(re.findall(r"\bhide\(", barrier)) == 1, "Scenery must remain visible"
    assert 'spawn("script_model", origin, 1)' in barrier, "Preserve solid path-blocking spawn"
    assert 'spawn("script_model", origin)' in barrier, "Preserve ordinary scenery spawn"
    assert re.search(r'if\s*\(disconnect_paths\)\s*\{\s*barrier disconnectPaths\(\);\s*\}', barrier), "Preserve conditional zombie path blocker"

    protected = [barrier, body(common, "increase_pap_collision")]
    for filename, model in [
        ("loc_common.gsc", "zm_collision_perks1"),
        ("zm_transit_loc_diner.gsc", "zm_collision_transit_diner_survival"),
        ("zm_transit_loc_cornfield.gsc", "zm_collision_transit_cornfield_survival"),
    ]:
        text = source(locs / filename)
        assert re.search(r'collision setmodel\("' + model + r'"\);\s*collision hide\(\);', text), f"{model} must be hidden"
        if filename != "loc_common.gsc":
            protected.append(body(text, "init_barriers"))
    for text in protected:
        assert not re.search(r"\b(?:notsolid|delete|connectpaths|ghost)\s*\(", text, re.I), "Do not remove collision or reconnect blocked paths"

    calls = []
    for path in sorted(locs.glob("*.gsc")):
        calls.extend((path.name, model) for model in re.findall(r'loc_common::barrier\("([^"\n]+)"', source(path)))
    walls = [(path, model) for path, model in calls if "collision_" in model]
    assert walls, "No collision-wall callers found"
    assert all(model.startswith("collision_") for _, model in walls), "Collision naming must use the collision_ prefix"
    print(f"check-collision-barriers: PASS, {len(walls)} collision calls in {len(set(path for path, _ in walls))} locations, {len(calls) - len(walls)} scenery calls, 3 direct collision models")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        check(args.root)
    except AssertionError as error:
        parser.exit(1, f"check-collision-barriers: FAIL, {error}\n")
