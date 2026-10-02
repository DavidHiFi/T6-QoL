"""Negative regressions for the player-reported world float defects."""
import copy
import importlib.util
import json
import struct
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('world_grip', HERE / 'check-world-grip.py')
wg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wg)


class WorldGripTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contract = json.loads(wg.CONTRACT.read_text())

    def model(self, name):
        return wg.glb(wg.ROOT / 'zone_assets/model_export' / f'{name}.glb')

    def test_both_world_hands_and_muzzles(self):
        for name, root in [('t7_bloodhound_world', 'tag_weapon'),
                           ('t7_bloodhound_world_lh', 'tag_weapon1')]:
            doc, data = self.model(name)
            self.assertEqual([], wg.check_model(doc, data, root, self.contract['models'][name]))

    def test_view_root_names_are_rejected_only_in_world_models(self):
        for name, root, old in [('t7_bloodhound_world', 'tag_weapon', 'j_gun'),
                               ('t7_bloodhound_world_lh', 'tag_weapon1', 'j_gun1')]:
            doc, data = self.model(name)
            doc['nodes'][doc['skins'][0]['joints'][0]]['name'] = old
            self.assertTrue(wg.check_model(doc, data, root, self.contract['models'][name]))
        for name, expected in [('t7_bloodhound_view', 'j_gun'), ('t7_bloodhound_view_lh', 'j_gun1')]:
            doc, _ = self.model(name)
            self.assertEqual(expected, doc['nodes'][doc['skins'][0]['joints'][0]]['name'])

    def test_renaming_without_moving_vertices_fails(self):
        name = 't7_bloodhound_world'
        doc, data = self.model(name)
        data = bytearray(data)
        dx, dy, dz = self.contract['models'][name]['translationFromDonorCoD']
        seen = set()
        for mesh in doc['meshes']:
            for primitive in mesh['primitives']:
                aid = primitive['attributes']['POSITION']
                if aid in seen:
                    continue
                seen.add(aid)
                acc = doc['accessors'][aid]
                view = doc['bufferViews'][acc['bufferView']]
                start = view.get('byteOffset', 0) + acc.get('byteOffset', 0)
                for i in range(acc['count']):
                    pos = start + i * view.get('byteStride', 12)
                    x, y, z = struct.unpack_from('<3f', data, pos)
                    struct.pack_into('<3f', data, pos, x - dx, y - dz, z + dy)
        errors = wg.check_model(doc, data, 'tag_weapon', self.contract['models'][name])
        self.assertTrue(any('vertices' in error for error in errors))

    def test_stale_muzzle_and_root_transform_fail(self):
        name = 't7_bloodhound_world'
        doc, data = self.model(name)
        for mutate in ['muzzle', 'root']:
            bad = copy.deepcopy(doc)
            node = bad['nodes'][1 if mutate == 'muzzle' else bad['skins'][0]['joints'][0]]
            node['translation'][0] += 1
            self.assertTrue(wg.check_model(bad, data, 'tag_weapon', self.contract['models'][name]))

    def test_rpg_class_cannot_return_on_rifle_grips(self):
        definitions = {p.name: wg.fields(p) for p in (wg.ROOT / 'weapons/zm').iterdir() if p.is_file()}
        self.assertEqual([], wg.check_categories(definitions, self.contract))
        for name in ['tesla_gun_zm', 'tesla_gun_upgraded_zm', 'thundergun_zm', 'thundergun_upgraded_zm']:
            bad = copy.deepcopy(definitions)
            bad[name]['weaponClass'] = 'rocketlauncher'
            self.assertTrue(wg.check_categories(bad, self.contract))
        # BO1 retail: Wunderwaffe keeps the rifle reload, Thundergun the crossbow one.
        for name, wrong in [('tesla_gun_zm', 'crossbow'), ('thundergun_zm', 'default')]:
            bad = copy.deepcopy(definitions)
            bad[name]['playerAnimType'] = wrong
            self.assertTrue(wg.check_categories(bad, self.contract))


if __name__ == '__main__':
    unittest.main()
