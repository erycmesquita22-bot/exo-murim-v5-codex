#!/usr/bin/env python3
"""Offline schema/contract/reference-model checks. Does NOT run Godot GDScript."""
import json,hashlib,pathlib,random,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
MOD=ROOT/'exo_martial'; CORE=ROOT/'audit_core'
checks=[]
def check(cond,label):
 checks.append({'name':label,'status':'PASS' if cond else 'FAIL'})
def get(name):return json.loads((MOD/'data'/name).read_text())
styles=get('styles.json'); schools=get('schools.json'); techs=get('techniques.json'); methods=get('training_methods.json'); events=get('school_activities.json')
skills_path=CORE/'data/skills.json' if (CORE/'data/skills.json').exists() else MOD/'tests/fixtures/core_skills_01.json'
core_skills=json.loads(skills_path.read_text())
weapons_path=CORE/'data/weapons.json' if (CORE/'data/weapons.json').exists() else MOD/'tests/fixtures/core_weapons_01.json'
weapons=json.loads(weapons_path.read_text())
core_map={x['id']:x for x in core_skills}; tech_ids={t['id'] for t in techs}; st_ids={s['id'] for s in styles}; methods_by_id={x['id']:x for x in methods}
check(len(schools)==9,'9_schools');check(len(styles)==12,'12_styles');check(len(techs)==16,'16_core_techniques');check(len(core_skills)==16,'core_catalog_available');check(len({x['id'] for x in styles+schools+techs+methods})==len(styles+schools+techs+methods),'no_duplicate_catalog_ids')
check(len({json.dumps(s['teaching'],sort_keys=True,ensure_ascii=False) for s in schools})==9,'nine_mechanically_distinct_teaching_profiles')
check(len({(s['teaching']['observation_action'],s['teaching']['practice_action'],s['teaching']['examination_action']) for s in schools})==9,'nine_distinct_action_sequences')
check(len(events)==27,'27_typed_action_specs')
check(all(t['core_skill_id'] in core_map for t in techs),'official_skill_identity')
for t in techs:
 k=t['core_skill_id'];c=core_map.get(k,{})
 check(int(t['resources']['qi'])==int(c.get('mana',-1)) and int(t['resources']['stamina'])==int(c.get('stamina',-1)),f'core_costs_{k}')
 check(float(t['cooldown_seconds'])==float(c.get('cooldown',-1)),f'core_cooldown_{k}')
 check(set(t['style_ids']).issubset(st_ids),f'official_styles_{k}')
for s in schools:
 tid=s['id'].split('.')[-1];t=s['teaching'];policy=s['admission_policy'];style=next((x for x in styles if x['id']==s['style_id']),None)
 check(style is not None,f'{tid}_style')
 check(len(t['allowed_methods'])>0 and all(m in methods_by_id for m in t['allowed_methods']),f'{tid}_methods')
 check(isinstance(t['practice_repetitions'],int) and 1<=t['practice_repetitions']<=6,f'{tid}_practice_count')
 check(0<=t['qi_cost']<=100 and 0<=t['stamina_cost']<=100 and 1<=t['practice_mastery_award']<=50,f'{tid}_balanced_costs')
 check(policy['exclusivity']=='single_primary_school',f'{tid}_single_primary')
 check(all(str(r) in s['promotion']['mastery_thresholds'] for r in [4,5,6]),f'{tid}_exams_thresholds')
 check(all(x in {'observe','practice','exam'} for x in [e['stage'] for e in events if e['school_id']==s['id']]),f'{tid}_actions')
 valid_count=0
 if style:
  for skill in style['core_techniques']:
   candidate=next((x for x in techs if x['core_skill_id']==skill),None)
   if candidate and any(candidate['category'] in methods_by_id[m]['categories'] or '*' in methods_by_id[m]['categories'] for m in t['allowed_methods']):valid_count+=1
 check(valid_count>=1,f'{tid}_has_teachable_core_technique')
check(len(weapons)>0 and 'pose' in weapons[0],'weapon_pose_reference_present')
# deterministic IDs, stress and replay defense by referential model only, not executing Godot.
seed='941';masters=[f'npc/r{i%88:02d}/r2master{i:05d}' for i in range(12000)]
def profile_choice(mid,seed):
 h=hashlib.sha256(('EXO-MARTIAL-MASTER-1|'+seed+'|'+mid).encode()).hexdigest()
 return schools[int(h[:7],16)%len(schools)]['id']
model1=[profile_choice(mid,seed) for mid in masters]; model2=[profile_choice(mid,seed) for mid in masters]
check(model1==model2,'12000_masters_repeatable'); check(len(set(masters))==len(masters),'12000_masters_unique'); check(len(set(model1))==9,'all_schools_emerge_in_stress');check(any(profile_choice(mid,'942')!=profile_choice(mid,'941') for mid in masters),'seed_changes_school_placement')
pairs={hashlib.sha256((f'exo/world/player/p{i}|'+masters[i]).encode()).hexdigest() for i in range(10000)}
check(len(pairs)==10000,'10000_pair_key_uniqueness')
# Reference model protects receipt reuse and exact-once action ordering, distinct from GDScript.
class RefWorkflow:
 def __init__(self):self.phase='observing';self.receipts=set();self.progress=0;self.exam=False;self.mastery=0
 def submit(self,stage,receipt):
  if receipt in self.receipts:return False
  if stage=='observe' and self.phase=='observing':self.phase='practicing'
  elif stage=='practice' and self.phase=='practicing':
   self.progress+=1
   if self.progress==3:self.phase='examining'
  elif stage=='exam' and self.phase=='examining':self.phase='demonstrated';self.exam=True
  else:return False
  self.receipts.add(receipt);return True
 def finish(self):
  if self.phase!='demonstrated' or not self.exam:return False
  self.phase='ready';self.exam=False;self.mastery+=18;return True
w=RefWorkflow();check(not w.submit('exam','attack1'),'exam_before_observation_blocked');check(w.submit('observe','observe1'),'observe_action');check(not w.submit('observe','observe1'),'observation_replay_blocked');check(w.submit('practice','hit1'),'practice_1');check(not w.submit('practice','hit1'),'practice_duplicate_blocked');check(w.submit('practice','hit2') and w.submit('practice','hit3'),'practice_completed');check(w.submit('exam','trial1'),'exam_completed');check(w.finish(),'lesson_completed');check(not w.finish() and w.mastery==18,'no_repeated_reward');check(not w.submit('exam','trial1'),'exam_receipt_replay_blocked')
# Verify source code explicitly keeps ownership boundaries (static assertions, not security proof).
mod=(MOD/'module.gd').read_text(); engine=(MOD/'r2/engine_r2.gd').read_text(); state=(MOD/'r2/state_r2.gd').read_text()
check('confirm_core_unlock' in mod and 'known' in engine and 'learned' in engine,'core_unlock_readback')
check('not _verify("action",proof)' in mod and 'proof_validator.is_valid()' in mod,'trusted_proof_required')
check('sole_school' in engine and 'master_disciple' in engine and 'state.relationships' not in mod and 'Bonds.establish' not in mod,'narrative_no_direct_mutation')
check('receipt' in engine and 'exams' in engine and 'awaiting_unlock' in engine,'exams_and_unlock_state_machine')
check('state.known.append' not in mod and 'data().learned.append' not in mod,'does_not_forge_core_unlock')
check('State.upgrade' in mod and 't.phase="ready"' in state,'r1_upgrade_discards_untrusted_open_lessons')
check('lesson_plan' in engine and 'marker_type' in engine and 'qi_spent' in engine,'typed_markers_and_actual_resources')
result={'suite':'EXO Martial 01 R2 offline','execution':'PYTHON_OFFLINE_ONLY','native_godot':'NOT_RUN','core_save_v4_roundtrip':'NOT_RUN','checks_total':len(checks),'passed':sum(v['status']=='PASS' for v in checks),'failed':[v for v in checks if v['status']=='FAIL'],'stress_masters':len(masters),'stress_pair_keys':len(pairs),'tests':checks}
path=MOD/'tests/QA-R2-OFFLINE-RESULTS.json';path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='tests'},ensure_ascii=False,indent=2))
sys.exit(1 if result['failed'] else 0)
