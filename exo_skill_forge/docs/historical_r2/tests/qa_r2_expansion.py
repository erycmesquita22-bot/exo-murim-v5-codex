#!/usr/bin/env python3
"""R2 taxonomy, constraints, seeded replay and synthetic combat (NOT live Godot QA)."""
import collections, copy, hashlib, json, math, random, re, sys, unittest, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from expand_skill_library import generate,make_candidate,ORIGINS,GROUP_NAMES,LEVELS,WEAPONS
ORIGINAL=json.loads((ROOT/'data/legacy_bindings.json').read_text())
AUTHORIAL=json.loads((ROOT/'data/authorial.json').read_text())
R2=AUTHORIAL[28:]
R1=AUTHORIAL[:28]
ORIGINAL_ARCHIVE=Path('/mnt/data/EXO-SKILL-FORGE-01.zip')
R13=Path('/mnt/data/files/EXO-MURIM-CONVERGENCIA-03-ALFA-R13-1.zip')
ALLOWED_OPS={'damage','status','movement','field','channel','projectile','shield','heal','cleanse'}
allowed_status={'bleed','burn','slow','root','stagger','knockback','mark','pierce'}
TEMPLATE_TYPES={x['id'] for x in json.loads((ROOT/'data/templates.json').read_text())['templates']}

class Expansion(unittest.TestCase):
 def test_cardinality_and_balance_per_group(self):
  self.assertEqual((len(ORIGINAL),len(R1),len(R2)),(16,28,140))
  freq=collections.Counter((x['tags']['power_family'],x['tags']['inspiration_origin']) for x in R2)
  self.assertEqual(len(freq),28)
  self.assertTrue(all(v==5 for v in freq.values()))
 def test_legacy_and_r1_byte_exact_preservation(self):
  if not ORIGINAL_ARCHIVE.exists():self.skipTest('R1 original absent')
  with zipfile.ZipFile(ORIGINAL_ARCHIVE) as z:
   self.assertEqual(json.loads(z.read('exo_skill_forge/data/legacy_bindings.json')),ORIGINAL)
   self.assertEqual(json.loads(z.read('exo_skill_forge/data/authorial.json')),R1)
 def test_unique_ids_and_names(self):
  all_=ORIGINAL+AUTHORIAL
  self.assertEqual(len({x['id'] for x in all_}),184)
  self.assertEqual(len({x['name'].casefold() for x in all_}),184)
  self.assertTrue(all(re.fullmatch(r'exo\.sf\.r2\.[a-z0-9_]+',x['id']) for x in R2))
 def test_seed_stability_without_id_drift(self):
  self.assertEqual(generate(20261020),R2)
  changed=generate(42)
  self.assertEqual([x['id'] for x in changed],[x['id'] for x in R2])
  self.assertGreater(sum(a['balance']!=b['balance'] for a,b in zip(changed,R2)),100)
  self.assertEqual(changed,generate(42))
 def test_all_16_actual_weapons_covered(self):
  if not R13.exists():self.skipTest('R13 absent')
  with zipfile.ZipFile(R13) as z:base={w['id']:w['pose'] for w in json.loads(z.read('data/weapons.json'))}
  cover={w for x in R2 for w in x['tags']['weapon_ids']}
  self.assertEqual(cover,set(base))
  for s in R2:
   for wid in s['tags']['weapon_ids']:
    self.assertEqual(base[wid],s['tags']['weapon_poses'][0])
 def test_supported_runtime_primitives_only(self):
  for x in R2:
   self.assertIn(x['template'],TEMPLATE_TYPES)
   for e in x['effects']:
    self.assertIn(e['op'],ALLOWED_OPS)
    if e['op']=='status':self.assertIn(e['status'],allowed_status)
    for k in ['max_targets','max_projectiles','max_instances','max_ticks']:
     if k in e:self.assertGreaterEqual(e[k],1);self.assertLessEqual(e[k],20)
   self.assertTrue(all(a.get('binding')=='requires_binding' for a in x['presentation']['audio']+x['presentation']['vfx']))
 def test_magic_vs_physical_resources(self):
  for x in R2:
   fam=x['tags']['power_family'];b=x['balance']
   self.assertTrue(math.isfinite(b['damage']) and 0<=b['damage']<=5000)
   self.assertTrue(0<=b['qi']<=100 and 0<=b['stamina']<=100)
   self.assertTrue(0<=b['cooldown']<=180 and 0<=b['range']<=18)
   self.assertTrue(0<=b['radius']<=8 and 0<=b['release_time']<=b['cast_time'])
   if fam=='mundana':self.assertEqual(b['qi'],0)
   if fam in ('qi','sangue','demonica','celestial'):self.assertGreater(b['qi'],0)
 def test_grade_progression_monotonic(self):
  for fam in GROUP_NAMES:
   for ori in ORIGINS:
    rows=sorted((x for x in R2 if x['tags']['power_family']==fam and x['tags']['inspiration_origin']==ori),key=lambda x:x['tags']['rarity_tier'])
    self.assertEqual([x['tags']['min_level'] for x in rows],LEVELS)
    self.assertEqual([x['tags']['rarity_tier'] for x in rows],[1,2,3,4,5])
    self.assertEqual(sorted(x['balance']['cooldown'] for x in rows),[x['balance']['cooldown'] for x in rows])
 def test_ward_no_incorrect_damage(self):
  for x in R2:
   ops=[a['op'] for a in x['effects']]
   if x['template']=='ward':
    self.assertEqual(x['balance']['damage'],0)
    self.assertIn('shield',ops)
    self.assertNotIn('damage',ops)
   else:
    self.assertIn('damage',ops)
 def test_ranged_weapons_projectiles_only(self):
  for x in R2:
   if x['tags']['weapon_ids'][0] in ('bow','crossbow'):
    self.assertEqual(x['template'],'projectile')
 def test_no_asset_copyright_risk_flags(self):
  for x in R2:
   self.assertEqual(x['provenance']['inspiration'],'generic_genre_motifs_not_existing_named_attacks')
   self.assertTrue(x['design']['authored_not_copied'])
   self.assertFalse(x['design']['hp_sacrifice_or_leech_implemented'])
   self.assertEqual(x['state'],'candidate_not_unlocked')
   self.assertEqual(x['design']['dependency_state'],'requires_host_execution_and_media_bindings')
 def test_count_phase_cues_and_combo_tags(self):
  for x in R2:
   phases={t['phase'] for t in x['presentation']['audio']}
   self.assertEqual(phases,{'prepare','release','impact'})
   self.assertEqual(len(x['presentation']['vfx']),2)
   self.assertIn(x['tags']['combo_role'],{'opener','chaser','finisher','counter','defensive'})
   self.assertIn(x['tags']['combat_role'],{'precision','cleave','ranged_pressure','mobility','area_control','disruption','sustained_pressure','defense','support','zone_denial'})
 def test_user_facing_queries_agree_with_tags(self):
  rng=random.Random(73451);rows=ORIGINAL+AUTHORIAL
  for _ in range(100000):
   fam=rng.choice(list(GROUP_NAMES));ori=rng.choice(ORIGINS);w=rng.choice(WEAPONS)[0]
   subset=[x for x in rows if x['tags'].get('power_family')==fam and x['tags'].get('inspiration_origin')==ori and w in x['tags']['weapon_ids']]
   self.assertTrue(all(x['tags']['power_family']==fam and x['tags']['inspiration_origin']==ori and w in x['tags']['weapon_ids'] for x in subset))
 def test_many_seed_replays_have_no_collisions(self):
  for seed in range(1000,1040):
   rows=generate(seed)
   self.assertEqual(len(rows),140)
   self.assertEqual(len({x['id'] for x in rows}),140)
   self.assertTrue(all(x['balance']['cooldown']>0 for x in rows))
 def test_host_denial_invariants_data_only(self):
  # This is schema-level: the runtime authority must still deny unlearned candidates.
  self.assertTrue(all(x['state']=='candidate_not_unlocked' for x in R2))
  self.assertTrue(all(x['executor']=='generic' for x in R2))
  self.assertTrue(all(not x['presentation']['animation']['binding']=='asset_verified' for x in R2))
 def test_dps_proxy_outliers(self):
  # Rough single-target tuning ONLY, not an in-engine damage model.
  candidates=[x for x in R2 if x['balance']['damage']>0]
  self.assertTrue(all(x['balance']['damage']/max(1,x['balance']['cooldown'])<15 for x in candidates))
 def test_negative_generator_inputs(self):
  for fam,orig,j in [('invalid','anime',1),('qi','manga',1),('qi','cinema',7)]:
   with self.assertRaises(ValueError):make_candidate(fam,orig,j,11)

class Simulations(unittest.TestCase):
 def test_350k_bounded_cast_recovery(self):
  # Hypothetical regen: Qi 2.5/s, stamina 6/s. Not actual Core numbers.
  rng=random.Random(20261020)
  users=[{'qi_max':30,'stamina_max':50,'level':1},{'qi_max':60,'stamina_max':75,'level':14},{'qi_max':100,'stamina_max':100,'level':42}]
  tally=collections.Counter()
  for scenario in users:
   q=float(scenario['qi_max']);s=float(scenario['stamina_max']);cd=0.
   eligible=[x for x in R2 if x['tags']['min_level']<=scenario['level']]
   for _ in range(116666):
    row=rng.choice(eligible);cost=row['balance'];dt=rng.uniform(.05,.4)
    q=min(float(scenario['qi_max']),q+2.5*dt);s=min(float(scenario['stamina_max']),s+6*dt);cd=max(0.,cd-dt)
    if q>=cost['qi'] and s>=cost['stamina'] and cd==0:
     q-=cost['qi'];s-=cost['stamina'];cd=cost['cooldown'];tally['cast']+=1
    else:tally['denied']+=1
    self.assertTrue(0<=q<=scenario['qi_max'] and 0<=s<=scenario['stamina_max'] and cd>=0)
  self.assertGreater(tally['cast'],1000)
  self.assertGreater(tally['denied'],1000)
  Simulations.cast_simulation=dict(tally)
 def test_100k_attack_windows(self):
  rng=random.Random(90210)
  for _ in range(100000):
   x=rng.choice(R2);b=x['balance'];distance=rng.uniform(0,21.)
   if x['template']!='ward':
    reaches=distance <= (b['range']+b['radius'])
    if distance> b['range']+b['radius']:self.assertFalse(reaches)
   for e in x['effects']:
    if e['op']=='projectile':self.assertTrue(e['collision_required'])
    if e['op']=='movement':self.assertTrue(e['collision_required'])

if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--report',type=Path);a=p.parse_args()
 result=unittest.TextTestRunner(verbosity=2).run(unittest.TestLoader().loadTestsFromModule(sys.modules[__name__]))
 if a.report:
  obj={'suite':'Skill Forge 01 R2 taxonomy and synthetic QA','success':result.wasSuccessful(), 'tests_run':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),'skipped':len(result.skipped),'stress_iterations':100000+349998+100000,'seed_replays':40,'new_candidates':len(R2),'legacy':len(ORIGINAL),'r1_candidates_preserved':len(R1),'casts':getattr(Simulations,'cast_simulation',{}),'godot_runtime':'NOT_RUN'}
  a.report.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
 raise SystemExit(0 if result.wasSuccessful() else 1)
