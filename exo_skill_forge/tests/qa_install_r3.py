#!/usr/bin/env python3
"""C3 WORK minimal candidate patch roundtrip; temporary file copies ONLY, NEVER edits original."""
import json,os,pathlib,subprocess,tempfile,unittest,zipfile
P=pathlib.Path(__file__).resolve().parents[1]
ARCHIVE=pathlib.Path(os.environ.get('EXO_WORK_REFERENCE_ZIP','/mnt/data/files/EXO-MURIM-CONVERGENCIA-03-WORK-CANDIDATO-01.zip'))

class R3IntegrationPatchTests(unittest.TestCase):
 def setUp(self):
  if not ARCHIVE.exists():self.skipTest('BLOCKED: source C3 Work not present')
  self.t=tempfile.TemporaryDirectory();self.addCleanup(self.t.cleanup);self.root=pathlib.Path(self.t.name)
  with zipfile.ZipFile(ARCHIVE) as z:
   for name in ('exo_core/modules.json','exo_core/core.gd'):
    p=self.root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(z.read(name))
  self.before={name:(self.root/name).read_bytes() for name in ('exo_core/modules.json','exo_core/core.gd')}
  self.patch=P/'integration/PATCH-SKILL-C3-WORK-PROPOSTO.diff'
 def cmd(self,*args):
  return subprocess.run(['patch','--batch','-p1',*args],cwd=self.root,input=self.patch.read_bytes(),capture_output=True)
 def test01_patch_clean_dry_run(self):self.assertEqual(self.cmd('--dry-run').returncode,0)
 def test02_patch_applies_and_has_unique_module(self):
  self.assertEqual(self.cmd().returncode,0)
  registry=json.loads((self.root/'exo_core/modules.json').read_text());self.assertEqual(sum(x['id']=='exo_skill_forge' for x in registry),1)
  found=next(x for x in registry if x['id']=='exo_skill_forge');self.assertEqual(found['version'],'1.2.0')
  self.assertEqual(found['persistence'],{});self.assertEqual(found['services'],['skill_forge'])
  self.assertIn('skill_forge_catalog_only_authorial_host_unbound',(self.root/'exo_core/core.gd').read_text())
 def test03_unapplied_core_unmodified(self):
  self.assertEqual(self.before,{name:(self.root/name).read_bytes() for name in self.before})
 def test04_second_apply_denied(self):
  self.assertEqual(self.cmd().returncode,0)
  self.assertNotEqual(self.cmd('--forward').returncode,0)
  self.assertEqual(sum(x['id']=='exo_skill_forge' for x in json.loads((self.root/'exo_core/modules.json').read_text())),1)
 def test05_reverse_rollback_byte_exact(self):
  self.assertEqual(self.cmd().returncode,0)
  self.assertEqual(self.cmd('-R').returncode,0)
  self.assertEqual(self.before,{name:(self.root/name).read_bytes() for name in self.before})
 def test06_no_extra_files_created_by_patch(self):
  self.assertEqual(self.cmd().returncode,0)
  files=sorted(str(x.relative_to(self.root)) for x in self.root.rglob('*') if x.is_file() and not x.name.endswith('.rej') and not x.name.endswith('.orig'))
  self.assertEqual(files,['exo_core/core.gd','exo_core/modules.json'])
if __name__=='__main__':unittest.main(verbosity=2)
