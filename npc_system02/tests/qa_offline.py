#!/usr/bin/env python3
"""EXO-Murim NPC02: static checks + external model exercises. NOT Godot native QA."""
import hashlib, json, math, random, re, time, tracemalloc, copy
from pathlib import Path
import argparse
from collections import Counter, defaultdict
from zipfile import ZipFile
parser=argparse.ArgumentParser(description="NPC02 offline model/static verification; not Godot QA")
parser.add_argument("--project",default=str(Path(__file__).resolve().parents[2]),help="Godot project root with NPC02 patch")
parser.add_argument("--base",default="/mnt/data/bases/EXO-Murim-Cidade-Viva-01-R2-PROJETO(1).zip",help="Exact original project ZIP for contract diff")
args=parser.parse_args()
root=Path(args.project)
base=Path(args.base)
if not (root/"project.godot").exists():parser.error("--project must point to a real Godot project root")
if not base.exists():parser.error("--base must point to the original Cidade Viva R2 ZIP")
changed=['convergence/game.gd','convergence/resident.gd','living_world/bridge.gd']
new=['npc_system02/profile.gd','npc_system02/planner.gd','npc_system02/crowd.gd','npc_system02/director.gd','npc_system02/tests/qa_logic.gd','npc_system02/tests/qa_world.gd']
checks=[]
def check(value,label): checks.append({'name':label,'pass':bool(value)}); return bool(value)
with ZipFile(base) as z:
 pre='EXO-Murim-Cidade-Viva-01-R2/'
 old_files={x[len(pre):]:z.read(x) for x in z.namelist() if x.startswith(pre) and x.endswith(('.gd','.json','.tscn','.godot'))}
 for f in changed:check((root/f).read_bytes()!=old_files[f], 'existing_file_edited:'+f)
 for f in new:check(f not in old_files and (root/f).is_file(),'new_source_exists:'+f)
 for f in ['main.gd','exo_core/core.gd','exo_core/modules.json','living_world/people.gd','living_world/state.gd','convergence/region.gd','convergence/occupancy.gd']:
  check((root/f).read_bytes()==old_files[f],'original_contract_unchanged:'+f)
 missing=[];num_preloads=0
 for f in changed+new:
  src=(root/f).read_text()
  for m in re.finditer(r'preload\("res://([^"\n]+)"\)',src):
   num_preloads+=1
   if not (root/m.group(1)).is_file():missing.append((f,m.group(1)))
  check(src.count('(')==src.count(')'),'paren_balance:'+f)
  check(src.count('[')==src.count(']'),'square_balance:'+f)
 check(not missing,'all_preloaded_resources_exist')
 check('npc_director.tick' in (root/'convergence/game.gd').read_text(),'director_connected_to_region')
 check('player.collision_mask|8' in (root/'convergence/game.gd').read_text(),'bidirectional_player_collision')
 check('snapshot_clock' in (root/'convergence/resident.gd').read_text(),'offline_clock_restore')
 check('state.actors[actor.identity.id]=actor.snapshot(float(state.clock))' in (root/'convergence/game.gd').read_text(),'clock_saved_in_authoritative_snapshot')
 check('Profile.enrich' in (root/'living_world/bridge.gd').read_text(),'profile_saved_through_living_world')
 check('crowd.near(actor)' in (root/'npc_system02/director.gd').read_text(),'spatial_hash_enabled')
 check('collision_mask=1|2|4|8' in (root/'convergence/resident.gd').read_text(),'npc_physical_mask')
 check('npc_system02' not in (root/'exo_core/modules.json').read_text(),'no_new_core_domain')
# Mirror exact hash/RNG formulas in Godot seed_stream.gd. Exercise model separately; not a GDScript test.
def below(seed,id,purpose,count):
 st=f'EXO|NPC02|{seed}|{id}|{purpose}'
 x=int(hashlib.sha256(st.encode()).hexdigest()[:8],16)%(2147483647-1)
 return (((x%(2147483647-1)+1)*48271)%2147483647)%max(1,count)
roles=json.loads((root/'living_world/data/people.json').read_text())['roles']
check(len(roles)==10,'ten_existing_professions_compatible')
temperaments=['prudente','sociavel','disciplinado','reservado','audacioso']
def profile(seed,rid,i):
 role=list(roles)[i%10]
 id=f'npc/r{rid:02}/{role}_{i:03}'
 pref={'guard':'disciplinado','disciple':'disciplinado','master':'disciplinado','farmer':'prudente','healer':'prudente','merchant':'sociavel','courier':'sociavel'}.get(role,'reservado')
 personality=pref if below(seed,id,'temperament',4)!=0 else temperaments[below(seed,id,'alt_temperament',5)]
 return {'id':id,'role':role,'personality':personality,'home_slot':'home-'+str(i//3),'work_slot':'work-'+str(i//4), 'routine_offset':below(seed,id,'clock',46)-22,'faction':roles[role]['faction']}
def activity(role,h):
 if h<5 or h>=21:return 'descanso'
 if role in ['guard','outlaw']:return 'ronda' if h<9 or h>=18 else 'posto'
 if role in ['master','disciple']:return 'treino' if h<12 else 'meditacao' if h<16 else 'convivio'
 if role=='farmer':return 'plantio' if h<12 else 'colheita' if h<18 else 'convivio'
 if role=='courier':return 'viagem' if h>=7 and h<19 else 'espera'
 return 'trabalho' if h>=8 and h<18 else 'convivio'
def plan(p,clock,danger=False):
 h=int(math.floor((clock+p['routine_offset']*90/60)/90))%24
 name=activity(p['role'],h)
 if p['role']=='merchant':
  if h==7:name='preparar_banca'
  elif h==18:name='fechar_banca'
  elif name=='trabalho':name='atendimento'
 elif p['role']=='healer' and name=='trabalho':name='preparar_remedios' if h<=9 else 'atendimento'
 elif p['role']=='guild_agent' and name=='trabalho':name='administracao'
 slot=('@square' if name in ('convivio','espera') else p['home_slot'] if name in ('descanso','fora_de_servico') else '@activity')
 if p['role'] in ('guard','outlaw') and name=='ronda':slot='@square' if h%2==0 else '@activity'
 if p['role']=='courier' and name=='viagem':slot='@square' if h%3==0 else '@activity'
 if danger:
  if p['role'] in ['guard','outlaw']:return ('alerta','@activity')
  if p['personality']=='audacioso':return ('observar_risco',slot)
  return ('evitar_risco',p['home_slot'])
 return (name,slot)
t0=time.perf_counter()
plans=0;day_transitions=0;identities=0
for seed in ['101','816204','7352','80033','24242']:
 for rid in range(88):
  ps=[profile(seed,rid,i) for i in range(40)]
  check(len({p['id'] for p in ps})==40,f'unique_ids_{seed}_r{rid}')
  for p in ps:
   identities+=1
   check(p==profile(seed,rid,int(p['id'].split('_')[-1])),f'identity_deterministic_{seed}_r{rid}_{p["id"]}')
   check(p['personality'] in temperaments,f'temperament_{p["id"]}')
   check(-22<=p['routine_offset']<=23,f'jitter_range_{p["id"]}')
   states=[]
   for h in range(0,24,2):
    act,slot=plan(p,h*90);states.append(slot)
    check(slot in ['@square','@activity',p['home_slot']],f'known_route_alias_{p["id"]}_{h}')
    plans+=1
   expected='alerta' if p['role'] in ['guard','outlaw'] else 'observar_risco' if p['personality']=='audacioso' else 'evitar_risco'
   check(plan(p,9*90,True)[0]==expected,f'danger_{p["id"]}')
   day_transitions+=sum(a!=b for a,b in zip(states,states[1:]))
  for p in ps: check(p==json.loads(json.dumps(p)),f'json_identity_roundtrip_{p["id"]}')
check(day_transitions>50000,'unsynchronized_daily_transitions')
# 6 simulated region visits across seeds, reconstructed via clock and JSON, no 3D navigation claims.
for seed in ['101','816204','721']:
 p=profile(seed,78,9)
 for hour_a,hour_b in [(6,14),(14,23),(23,6+24),(8,8+48),(13,19),(19,33)]:
  snapshot={'clock':hour_a*90,'slot':plan(p,hour_a*90)[1],'person':p}
  snapshot=json.loads(json.dumps(snapshot))
  check(plan(snapshot['person'],hour_b*90)[1] in ('@square','@activity',p['home_slot']),'abstract_reentry')
# Spatial hash candidate complexity comparison, using external positions, not Godot frame benchmarks.
rng=random.Random(101)
spatial_bench=[]
for n in (72,400,1200):
 positions=[(rng.uniform(-100,100),rng.uniform(-100,100)) for _ in range(n)]
 buckets=defaultdict(list)
 for x,(a,b) in enumerate(positions):buckets[(math.floor(a/2.6),math.floor(b/2.6))].append(x)
 probes=0
 for a,b in positions:
  cx,cy=math.floor(a/2.6),math.floor(b/2.6)
  for ox in (-1,0,1):
   for oy in (-1,0,1):probes+=len(buckets[(cx+ox,cy+oy)])
 comparisons=n*(n-1)
 spatial_bench.append({'simulated_population':n,'all_pairs_old':comparisons,'spatial_candidates_including_self':probes,'candidate_ratio':round(probes/comparisons,5)})
 check(probes<comparisons/3,f'spatial_hash_reduction_{n}')
model_elapsed=time.perf_counter()-t0
failed=[x for x in checks if not x['pass']]
report={'kind':'STATIC_AND_EXTERNAL_MODEL_ONLY_NOT_GODOT','base_file':base.name,'base_sha256':hashlib.sha256(base.read_bytes()).hexdigest(),'core_original_sha256':'d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac','test_counts':{'assertions':len(checks),'passed':len(checks)-len(failed),'failed':len(failed),'synthetic_identities':identities,'schedule_samples':plans,'day_transitions':day_transitions,'external_model_seconds':round(model_elapsed,3),'resolving_preloads':num_preloads},'spatial_comparison':spatial_bench,'missing_preloads':missing,'failed_assertions':failed[:30],'godot_native':'NOT_RUN_NO_BINARY','world_physics':'NOT_RUN','rendered_captures':'NONE','modified_existing_files':changed,'new_sources':new}
out=root/'npc_system02/tests/qa_offline_results.json';out.write_text(json.dumps(report,indent=2,ensure_ascii=False))
print(json.dumps({k:v for k,v in report.items() if k not in ('failed_assertions','new_sources','modified_existing_files')},ensure_ascii=False,indent=2))
if failed:exit(1)
