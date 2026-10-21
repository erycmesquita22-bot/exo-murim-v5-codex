#!/usr/bin/env python3
"""R8 source and artifact regressions. These do NOT run/parse GDScript in Godot."""
import pathlib,hashlib,json,sys,re,zipfile
from collections import Counter
ROOT=pathlib.Path(__file__).resolve().parents[1]
SOURCE=pathlib.Path('/mnt/data/EXO-MURIM-CONVERGENCIA-03-ALFA-R7.zip')
checks=[]
def check(name, condition, detail=''):
 checks.append({'id':name,'status':'PASS' if condition else 'FAIL','type':'STATIC','evidence':str(detail)[:500]})
def get(rel):return (ROOT/rel).read_text(encoding='utf-8')
assert SOURCE.exists(),'R7 zip not available for immutable comparison'
check('R7_SHA_256',hashlib.sha256(SOURCE.read_bytes()).hexdigest()=='b1c8e0dc59688c7d360daafa85abd47bb37bef205e5d3b20065e9e0b3dfc0163')
with zipfile.ZipFile(SOURCE) as z:
 check('R7_CRC',z.testzip() is None)
 original={x.filename:hashlib.sha256(z.read(x)).hexdigest() for x in z.infolist() if not x.is_dir()}
changed={ 'exo_core/modules.json','exo_core/core.gd','exo_martial/module.gd','convergence/game.gd','project.godot'}
for path,sha in original.items():
 f=ROOT/path
 check('R7_KEPT_'+path, f.is_file() and (path in changed or hashlib.sha256(f.read_bytes()).hexdigest()==sha))
newfiles={'convergence/martial_host_r8.gd','convergence/tests/qa_c03_r8_native.gd'}
for n in newfiles:check('R8_NEW_'+n,(ROOT/n).is_file())
mods=json.loads(get('exo_core/modules.json'))
m=[i for i in mods if i.get('id')=='exo_martial']
check('REGISTER_ONCE',len(m)==1)
check('REGISTER_OFFICIAL_R2',bool(m) and m[0].get('entrypoint')=='res://exo_martial/module.gd' and m[0].get('version')=='1.2.0')
check('MARTIAL_NARRATIVE_AND_NPC_DEPENDENCIES',bool(m) and 'narrative' in m[0].get('requires',{}) and 'living_world' in m[0].get('requires',{}))
check('NO_DUPLICATE_SERVICES',len([i for i in mods for s in i.get('services',[]) if s=='martial'])==1)
core=get('exo_core/core.gd');host=get('convergence/martial_host_r8.gd');world=get('convergence/game.gd');module=get('exo_martial/module.gd')
section=core.split('func confirm_martial_enrollment_atomic',1)[1].split('func npc(',1)[0]
check('CORE_ATOMIC_METHOD_PRESENT','func confirm_martial_enrollment_atomic' in core)
check('CORE_ATOMIC_SINGLE_SAVE',section.count('world.save_progress()')==1)
check('CORE_ATOMIC_NARRATIVE_OWNER','authorized_master_disciple.gd' in section and '.stage(' in section)
check('CORE_ATOMIC_R2_ENGINE','Engine.confirm(save.data,learner,master)' in section)
check('CORE_ATOMIC_VALIDATE_BOTH','narrative_state.gd' in section and 'state_r2.gd' in section)
check('CORE_ATOMIC_MEMORY_ROLLBACK','save.data=snapshot' in section)
check('CORE_ATOMIC_RECEIPT_CHECK','receipt.length()>120' in section and 'application' in section)
check('CORE_REJECTS_SPLIT_NARRATIVE','use_core_atomic_martial_enrollment' in core.split('func request_master_disciple_change',1)[1])
check('MODULE_REJECTS_SPLIT_MARTIAL','use_core_atomic_martial_enrollment' in module)
check('MASTER_IS_REAL_NPC','_resident(master_id)' in host and 'actor.identity.get("role","")' in host)
check('REAL_WORLDGEN_STATION','world.active_region.monument_stations' in host and 'master_station' in host)
check('SITE_WAS_BUILT','world.active_region.data.monumental_plans' in host and 'martial_grand' in host)
check('SITE_LINE_OF_SIGHT','PhysicsRayQueryParameters3D' in host and 'intersect_ray' in host)
check('SITE_BOUNDED_DISTANCE','distance_to(pos)>7.0' in host)
check('SITE_FACTION_POLICY','school_id' in host and 'profile.get("school_id"' in host)
check('REAL_PLAYER_INTERACTION','handle_master_interaction(actor)' in world and 'func interact()' in world)
check('HOST_PROOF_NOT_ALWAYS_TRUE','return true' not in host.split('func trusted_social_proof',1)[1].split('func admission_attestation',1)[0])
check('LAB_PROOFS_NOT_TRUSTED','return false' in host.split('func trusted_lesson_proof',1)[1].split('func _show',1)[0])
check('NO_FORGED_TRIALS','"proofs_completed":0' in host and '"trial_verified":false' in host)
check('NO_DIRECT_SKILL_UNLOCK','cultivation.learn(' not in host and '.known.append(' not in host and '.learned.append(' not in host)
check('FEATURE_DISABLE','exo_murim/r8/martial_enabled' in world and 'exo_murim/r8/martial_enabled' in get('project.godot'))
for name,count in [('schools',9),('styles',12),('techniques',16)]:
 data=json.loads(get('exo_martial/data/'+name+'.json'))
 check('OFFICIAL_'+name.upper()+'_COUNT',len(data)==count)
 check('OFFICIAL_'+name.upper()+'_UNIQUE',len({i['id'] for i in data})==count)
check('KEEP_R7_WORLDGEN',(ROOT/'genesis/region_data.gd').is_file())
check('KEEP_DUNGEON_R6',(ROOT/'exo_dungeon/module/entrypoint.gd').is_file())
check('KEEP_ITEM_R6',(ROOT/'exo_items/integration/atomic_reward_adapter.gd').is_file())
check('KEEP_CREATURE_VISUALS',(ROOT/'exo_creature_harmonizacao02/integration/runtime_visual_binding.gd').is_file())
check('TERRAIN_BRANCH_NOT_OVERLAID','genesis/region_data.gd' not in changed and 'genesis/region_scene.gd' not in changed)
# JSON files have real syntax; count entries, separate from gameplay proof.
jfiles=list(ROOT.rglob('*.json'))
failed_json=[]
for f in jfiles:
 try:json.loads(f.read_text(encoding='utf-8'))
 except Exception as e:failed_json.append((str(f.relative_to(ROOT)),str(e)))
check('JSON_ALL_VALID',not failed_json,{'count':len(jfiles),'failed':failed_json[:5]})
# Literal preload existence; historical labs may contain known stale refs.
all_gd=list(ROOT.rglob('*.gd'))
unresolved=[]
for f in all_gd:
 for path in re.findall(r'preload\("res://([^"\r\n]+)"\)',f.read_text(encoding='utf-8',errors='replace')):
  if not (ROOT/path).exists():unresolved.append((str(f.relative_to(ROOT)),path))
newbad=[x for x in unresolved if x[0] in {'exo_core/core.gd','exo_martial/module.gd','convergence/game.gd','convergence/martial_host_r8.gd','convergence/tests/qa_c03_r8_native.gd'}]
check('R8_PRELOADS_EXIST',not newbad,{'all_unresolved':unresolved[:12],'new_bad':newbad})
result={'suite':'EXO-Murim C03 ALFA R8 source audit','date':'2026-10-19','baseline_sha256':'b1c8e0dc59688c7d360daafa85abd47bb37bef205e5d3b20065e9e0b3dfc0163','note':'Source/reference checks, not native parser, functional enrollment, FPS, or gameplay','checks':checks,'passed':sum(t['status']=='PASS' for t in checks),'failed':sum(t['status']=='FAIL' for t in checks),'gdscripts_inspected_for_preload':len(all_gd),'json_files_parsed':len(jfiles),'unresolved_preloads':unresolved,'native_godot':'NOT_RUN'}
(ROOT/'C03_TRANSFERENCIA/QA-C03-ALFA-R8-ESTATICO.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({k:result[k] for k in ['passed','failed','gdscripts_inspected_for_preload','json_files_parsed','unresolved_preloads','native_godot']},ensure_ascii=False,indent=2))
sys.exit(1 if result['failed'] else 0)
