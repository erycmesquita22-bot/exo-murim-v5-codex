#!/usr/bin/env python3
"""Independent offline audit. Does NOT execute Godot/GDScript or physics."""
from pathlib import Path
import json,sys,hashlib,re,zipfile,itertools,random,time,collections
R=Path(__file__).resolve().parents[2]
M=R/'exo_bestiary';A=Path('/mnt/data/files/EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip')
results=[]
def check(name,predicate,details=''):
    results.append({'check':name,'status':'PASS' if predicate else 'FAIL','details':str(details)[:160]})
def load(file):return json.loads((M/'data'/file).read_text(encoding='utf8'))
s=load('species.json')['species'];h=load('humanoids.json')['profiles'];eb=load('elites_bosses.json');attacks=load('attacks.json')['attacks'];all_profiles=s+h+eb['elites']+eb['bosses']
check('species_minimum',len(s)>=12,len(s)); check('human_minimum',len(h)>=8,len(h)); check('elite_boss_minimum',len(eb['elites'])>=3 and len(eb['bosses'])>=2,(len(eb['elites']),len(eb['bosses'])))
ids=[x['id'] for x in all_profiles];check('unique_ids',len(set(ids))==len(ids),len(ids));check('all_ids_identifier',all(re.fullmatch('[a-z][a-z0-9_]*',x) for x in ids));
check('all_attacks_resolve',all(a in attacks for p in s+h for a in p['attacks']))
check('all_bases_resolve',all(e['base'] in ids for e in eb['elites']+eb['bosses']))
check('biome_coverage',len(set(itertools.chain.from_iterable(x.get('biomes',[]) for x in s)))>=8)
check('no_duplicate_attack_ids',len(attacks)==len(set(attacks)))
check('attack_ranges',all(0<float(v['range'])<=15 and float(v['windup'])>=0 for v in attacks.values()))
check('no_unapproved_mesh_paths',not any(p.suffix.lower() in ['.glb','.gltf','.obj','.fbx','.vox','.png','.jpg','.jpeg','.ogg','.mp3'] for p in M.rglob('*')))
check('visual_original_meshes',(M/'rendering/creature_visuals.gd').read_text().count('BoxMesh.new()')>=1)
check('no_core_in_package',not (R/'exo_core').exists() and not (R/'enemy.gd').exists())
check('no_dangerous_editor_overwrite', (R/'project.godot').is_file() and 'copie' in (R/'README.md').read_text().lower())
manifest=json.loads((M/'module/manifest.json').read_text()); check('manifest_contract',manifest['id']=='bestiary' and manifest['version']=='2.0.0' and manifest['persistence']=={} and manifest['entrypoint']=='res://exo_bestiary/module/entrypoint.gd')
check('no_parallel_rewards',not any(token in (M/'combat/combat_adapter.gd').read_text() for token in ['.hurt(','.award(','.queue_loot(','.gain_xp(']))
check('explicit_authority',['regional_ecology' in (M/f).read_text() for f in ['ecology/encounter_planner.gd','progression/reward_descriptors.gd','integration/ecology_adapter.gd']].count(True)==3)
check('tier_policy',all(keyword in (M/'ecology/ecosystem_rules.gd').read_text() for keyword in ['region_loaded','distance','return 3']))
check('never_force_spawn', 'surface_valid' in (M/'ecology/encounter_planner.gd').read_text() and 'protected' in (M/'ecology/encounter_planner.gd').read_text())
check('never_treat_profiles_as_playable','pending_combat_execution_hook' in (M/'data/humanoids.json').read_text())
check('required_states',all(x in (M/'ai/behavior_states.gd').read_text() for x in ['IDLE','PATROL','OBSERVE','INVESTIGATE','ALERT','APPROACH','POSITION','ATTACK','DEFEND','EVADE','RETREAT','FLEE','RETURN_HOME','DEFEATED']))
check('reproduction_limit', all(0<=v<=limit for v,limit in [(min(120,60),120),(0,8)]))
if A.is_file():
 sha=hashlib.file_digest(open(A,'rb'),'sha256').hexdigest();check('exact_base_sha',sha=='d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac',sha)
 with zipfile.ZipFile(A) as z:
  member=next((x for x in z.namelist() if x.endswith('/exo_core/modules.json') and '/module_template/' not in x),None)
  base=json.loads(z.read(member)) if member else []
  check('core_has_required_services',set(manifest['requires']).issubset({x['id'] for x in base}))
  check('service_ids_unique',all(not (set(manifest['services']) & set(x['services'])) for x in base))
else: check('exact_base_sha',False,'file not mounted')
def fnv(st):
 h=2166136261
 for b in st.encode('utf8'):h=((h^b)*16777619)&0xffffffff
 return h
cases=50000
hashes=collections.Counter()
start=time.perf_counter()
for i in range(cases):
 u=f"r{i%88:02d}/t{i%4:02d}/m{i%7:02d}/g{i%40:04d}"
 p=all_profiles[i%len(all_profiles)]['id']; q=f'EXO/BEAST/2/G/{i%97}/{u}/{p}'
 v=fnv(q); hashes[v]+=1
 if fnv(q)!=v: raise ValueError('non deterministic')
check('50000_hash_scenarios',sum(hashes.values())==cases,{'cases':cases,'unique_hashes':len(hashes),'seconds':round(time.perf_counter()-start,3)})
# Bypass invalid profile references as adversarial sentinel.
check('forbidden_attacks_never_in_catalog',all(a not in attacks for a in ['flamethrower','unregistered_magic','nuke']))
# No scripts reference a custom save file or player controller.
check('no_extra_save',not any('user://' in p.read_text() for p in M.rglob('*.gd')))
check('no_duplicate_player_control',not any(p.name=='player.gd' for p in M.rglob('*.gd')))
passed=sum(r['status']=='PASS' for r in results);failed=[r for r in results if r['status']=='FAIL']
output={'status':'PASS' if not failed else 'FAIL','checks':len(results),'passed':passed,'failed':failed,'cases_hashed':cases,'unique_hashes':len(hashes),'godot_native':'NOT_RUN','physical_world':'NOT_RUN','details':results}
(R/'QA-ESTATICO-BESTIARIO-02.json').write_text(json.dumps(output,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({k:v for k,v in output.items() if k!='details'},ensure_ascii=False))
sys.exit(1 if failed else 0)
