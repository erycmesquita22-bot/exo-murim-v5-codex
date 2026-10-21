#!/usr/bin/env python3
"""Smoketest installer on a minimal EXO R13 contract mirror, not on gameplay Godot."""
import json,hashlib,sys,tempfile,unittest,zipfile
from pathlib import Path
MOD=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(MOD/'tools'))
from install_preview import install
SOURCE=Path('/mnt/data/files/EXO-MURIM-CONVERGENCIA-03-ALFA-R13-1.zip')

class InstallChecks(unittest.TestCase):
 def setUp(self):
  if not SOURCE.exists():self.skipTest('R13 source absent')
  self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
  self.root=Path(self.temp.name)/'EXO'
  self.root.mkdir()
  refs=json.loads((MOD/'data/reference_index.json').read_text())
  with zipfile.ZipFile(SOURCE) as z:
   for key in list(refs['catalog_sha256'])+['project.godot','exo_core/modules.json']:
    path=self.root/key;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(key))
  self.original=(self.root/'exo_core/modules.json').read_bytes()
 def test_preview_without_registration(self):
  install(self.root,False)
  self.assertTrue((self.root/'exo_skill_forge/data/expansion_r2.json').exists())
  self.assertEqual((self.root/'exo_core/modules.json').read_bytes(),self.original)
 def test_registration_has_one_record_and_backup(self):
  install(self.root,True)
  backup=(self.root/'exo_core/modules.json.pre_skill_forge01.bak')
  self.assertEqual(backup.read_bytes(),self.original)
  mods=json.loads((self.root/'exo_core/modules.json').read_text())
  self.assertEqual(sum(x['id']=='exo_skill_forge' for x in mods),1)
  self.assertEqual(mods[-1]['version'],'1.1.0')
 def test_reinstallation_refuses_to_overwrite(self):
  install(self.root,False)
  with self.assertRaises(RuntimeError):install(self.root,True)
  self.assertEqual((self.root/'exo_core/modules.json').read_bytes(),self.original)
 def test_wrong_hash_rejected_without_copy(self):
  f=self.root/'data/skills.json';f.write_bytes(f.read_bytes()+b'\n')
  with self.assertRaises(RuntimeError):install(self.root,True)
  self.assertFalse((self.root/'exo_skill_forge').exists())
  self.assertEqual((self.root/'exo_core/modules.json').read_bytes(),self.original)
if __name__=='__main__':
 import argparse
 a=argparse.ArgumentParser();a.add_argument('--report',type=Path);opts=a.parse_args()
 result=unittest.TextTestRunner(verbosity=2).run(unittest.TestLoader().loadTestsFromModule(sys.modules[__name__]))
 if opts.report:opts.report.write_text(json.dumps({'suite':'Skill Forge R2 guarded install','runtime':'Python contract mirror (not Godot)','tests_run':result.testsRun,'success':result.wasSuccessful(),'skipped':len(result.skipped),'failures':len(result.failures)+len(result.errors)},indent=2)+'\n')
 raise SystemExit(0 if result.wasSuccessful() else 1)
