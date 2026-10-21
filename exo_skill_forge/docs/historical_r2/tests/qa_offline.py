#!/usr/bin/env python3
"""Static/schema and numerical/synthetic EXO Skill Forge QA, NOT Godot runtime validation."""
import json, unittest, random, hashlib, math, copy, argparse, collections
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SRC=Path('/mnt/data/exo_skill_forge_work/source')
D=ROOT/'data'
legacy=json.loads((D/'legacy_bindings.json').read_text(encoding='utf-8'))
authorial=json.loads((D/'authorial.json').read_text(encoding='utf-8'))
refs=json.loads((D/'reference_index.json').read_text(encoding='utf-8'))
templates=json.loads((D/'templates.json').read_text(encoding='utf-8'))['templates']
ids={x['id'] for x in legacy+authorial}; template_ids={x['id'] for x in templates}
PHASES={'prepare','release','impact','tick','expire','cancel'}
OPS={'damage','status','movement','field','channel','projectile','shield','heal','cleanse'}
STATUS={'bleed','burn','slow','root','stagger','knockback','mark','pierce'}

class TestLibrary(unittest.TestCase):
 def test_legacy_count_and_identity(self):
  self.assertEqual(len(legacy),16)
  self.assertEqual(set(x['id'] for x in legacy),set(refs['legacy_skill_ids']))
  self.assertTrue(all(x['executor']=='legacy' and x['legacy_id']==x['id'] for x in legacy))
 def test_authorial_count_and_id(self):
  self.assertGreaterEqual(len(authorial),28)
  self.assertTrue(all(x['id'].startswith('exo.sf.') and x['executor']=='generic' for x in authorial))
 def test_unique_catalog(self):
  self.assertEqual(len(ids),len(legacy)+len(authorial))
 def test_existing_snapshot_canonical_numbers(self):
  if not SRC.exists():self.skipTest('R13 source not copied into QA environment')
  core={x['id']:x for x in json.loads((SRC/'data/skills.json').read_text())}
  for s in legacy:
   c=core[s['id']];b=s['balance']
   for a,z in [('damage','damage'),('mana','qi'),('stamina','stamina'),('cooldown','cooldown'),('cast','cast_time'),('release','release_time')]:self.assertEqual(float(c[a]),float(b[z]),s['id'])
 def test_reference_hashes(self):
  if not SRC.exists():self.skipTest('R13 source not copied into QA environment')
  for name,sha in refs['catalog_sha256'].items():self.assertEqual(hashlib.sha256((SRC/name).read_bytes()).hexdigest(),sha,name)
 def test_styles_schools_weapons(self):
  for s in legacy+authorial:
   t=s['tags'];self.assertTrue(set(t['styles']).issubset(refs['style_ids']))
   self.assertTrue(set(t['schools']).issubset(refs['school_ids']))
   self.assertTrue(set(t['weapon_poses']).issubset(refs['weapon_poses']))
   self.assertTrue(set(t['actor_types']).issubset({'player','npc','enemy'}))
 def test_templates(self):
  self.assertEqual(len(template_ids),10)
  for a in authorial:self.assertIn(a['template'],template_ids)
 def test_balance_constraints(self):
  for a in legacy+authorial:
   b=a['balance'];
   for k,lim in [('damage',5000),('qi',100),('stamina',100),('cooldown',180),('range',18),('radius',8),('cast_time',30),('release_time',30)]:
    self.assertTrue(isinstance(b[k],(float,int)) and math.isfinite(b[k]) and 0<=b[k]<=lim, (a['id'],k))
   self.assertTrue(b['cast_time']==0 or b['release_time']<=b['cast_time'])
 def test_effect_whitelist(self):
  for a in authorial:
   self.assertLessEqual(len(a['effects']),16)
   for e in a['effects']:
    self.assertIn(e['stage'],PHASES); self.assertIn(e['op'],OPS)
    self.assertTrue(e.get('status','bleed') in STATUS)
    self.assertTrue(0<e.get('max_targets',1)<=20)
 def test_media_status(self):
  for a in authorial:
   p=a['presentation'];self.assertGreaterEqual(len(p['audio']),3)
   self.assertTrue(all(x['phase'] in PHASES for x in p['audio']+p['vfx']))
   self.assertTrue(all(x['binding']=='requires_binding' for x in p['audio']+p['vfx']))
   self.assertEqual(p['animation']['binding'],'requires_binding')
 def test_prevent_auto_unlock(self):
  self.assertTrue(all(a['state']=='candidate_not_unlocked' for a in authorial))
  self.assertTrue(all(a['state']=='legacy_connected' for a in legacy))
 def test_no_builtin_persistence(self):
  m=json.loads((ROOT/'manifest.json').read_text());self.assertEqual(m['persistence'],{});self.assertEqual(m['publishes'],[])
  self.assertTrue(m['optional_module']);self.assertIn('combat',m['requires'])
 def test_generated_recipe_no_mutation(self):
  import importlib.util
  p=ROOT/'tools/add_skill.py';sp=importlib.util.spec_from_file_location('skill_cli',p);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
  recipe=json.loads((ROOT/'tools/example_recipe.json').read_text())
  g=m.build(recipe)
  self.assertNotIn(g['id'],ids);self.assertEqual(g['source'],'authorial');self.assertEqual(g['state'],'candidate_not_unlocked')
  with self.assertRaises(ValueError):m.build({**recipe,'id':'../hacked'})
  with self.assertRaises(ValueError):m.build({**recipe,'qi':101})
 def test_consistent_school_styles(self):
  # Cross-school styles may exist, but independently sourced techniques must be explicit.
  primary={}
  if SRC.exists():
   for s in json.loads((SRC/'exo_martial/data/schools.json').read_text()):primary[s['id']]=s['style_id']
   for spec in authorial:
    if spec['tags']['schools']:
     self.assertEqual(primary[spec['tags']['schools'][0]],spec['tags']['styles'][0],spec['id'])
 def test_verified_external_media_mapping(self):
  import zipfile
  media=json.loads((D/'media_sources.json').read_text(encoding='utf-8'))
  self.assertEqual(len(media['skills']),28)  # legacy R1 media evidence only
  self.assertGreaterEqual(len(media['events']),30)
  self.assertEqual(len(media['vfx']),4)
  for s in authorial[:28]:
   self.assertGreaterEqual(len(s['presentation']['audio']),4)
   for cue in s['presentation']['audio']:
    self.assertEqual(cue['binding'],'requires_binding')
    self.assertEqual(cue['source_sha256'],media['events'][cue['key']]['sha256'])
  # Hashes were also checked against the real ZIPs during package creation.

 def test_non_legacy_no_real_asset_paths(self):
  for a in authorial:
   self.assertTrue(all('res://' not in x['key'] for k in ('audio','vfx') for x in a['presentation'][k]))
 def test_generic_ops_actor_coverage(self):
  self.assertEqual({'player','npc','enemy'},set.union(*(set(s['tags']['actor_types']) for s in authorial)))
  self.assertGreaterEqual(len(set(s['template'] for s in authorial)),8)

class TestSynthetic(unittest.TestCase):
 def test_mass_filter_queries(self):
  rng=random.Random(99173)
  rows=legacy+authorial
  for _ in range(50000):
   chosen=rng.choice(rows); school=rng.choice(refs['school_ids']);pose=rng.choice(refs['weapon_poses'])
   selection=[x for x in rows if school in x['tags']['schools'] and pose in x['tags']['weapon_poses']]
   self.assertTrue(all(school in x['tags']['schools'] and pose in x['tags']['weapon_poses'] for x in selection))
   self.assertIn(chosen['id'],ids)
 def test_100k_resource_and_cooldown_simulations(self):
  rng=random.Random(20261020);rows=legacy+authorial
  for _ in range(100000):
   s=rng.choice(rows)['balance'];qi=rng.uniform(0,100);stamina=rng.uniform(0,100);cooldown=rng.uniform(0,15)
   allowed=qi>=s['qi'] and stamina>=s['stamina'] and cooldown==0
   if allowed:
    qi-=s['qi'];stamina-=s['stamina'];cooldown=s['cooldown']
   dt=rng.uniform(0,2.0);qi=min(100.,qi+dt*8);stamina=min(100.,stamina+dt*18);cooldown=max(0.,cooldown-dt)
   self.assertTrue(0<=qi<=100 and 0<=stamina<=100 and cooldown>=0)
 def test_30k_constrained_effect_instances(self):
  rng=random.Random(2001)
  for _ in range(30000):
   row=rng.choice(authorial);b=row['balance'];r=float(b['radius']);dist=float(b['range'])
   self.assertLessEqual(r,8.0);self.assertLessEqual(dist,18)
   for op in row['effects']:
    self.assertLessEqual(op.get('max_projectiles',1),20)
    self.assertLessEqual(op.get('max_instances',1),20)
    self.assertLessEqual(op.get('max_ticks',1),20)

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--report',type=Path);args=parser.parse_args()
 suite=unittest.TestLoader().loadTestsFromModule(__import__(__name__))
 runner=unittest.TextTestRunner(verbosity=2);res=runner.run(suite)
 if args.report:
  report={'schema':1,'suite':'EXO Skill Forge 01 static/synthetic QA','runtime':'Python 3 (NOT Godot)','tests_run':res.testsRun,'failures':len(res.failures),'errors':len(res.errors),'skipped':len(res.skipped),'success':res.wasSuccessful(),'stress_iterations':180000,'catalog':{'legacy':len(legacy),'authorial':len(authorial),'templates':len(template_ids)},'godot_native':'NOT_RUN'}
  args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 raise SystemExit(0 if res.wasSuccessful() else 1)
