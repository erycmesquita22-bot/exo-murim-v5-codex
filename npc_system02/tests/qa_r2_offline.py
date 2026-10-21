#!/usr/bin/env python3
"""External model/static QA for NPC02 R2. Not a Godot/GDScript execution."""
from pathlib import Path
import hashlib, json, random, time, re, statistics
ROOT=Path(__file__).resolve().parents[2]
SCRIPTS=Path(__file__).resolve().parents[1]
checked=0; failed=[]; elapsed={}
def check(x,msg):
 global checked
 checked+=1
 if not x:failed.append(msg)

def context(a,b):
 if not a['id'] or a['id']==b['id']:return 0
 pts=0
 if a['home'] and a['home']==b['home']:pts+=6
 if a['work'] and a['work']==b['work']:pts+=7
 if a['work'] and a['work']==b['home'] and a['work']!=a['home']:pts+=2
 if b['work'] and b['work']==a['home'] and b['work']!=b['home']:pts+=2
 if a['faction'] and a['faction']==b['faction'] and pts:pts+=2
 if a['role']==b['role'] and pts:pts+=1
 return pts

def match(roster):
 ordered=sorted(roster,key=lambda p:p['id']); pairs=[]
 for i,p in enumerate(ordered):
  for j in range(i+1,len(ordered)):
   q=ordered[j];sc=context(p,q)
   if sc>=6:pairs.append((-sc,hashlib.sha256((p['id']+'|'+q['id']).encode()).hexdigest(),p['id'],q['id']))
 pairs.sort();out={x['id']:[] for x in ordered}
 for _,_,a,b in pairs:
  if len(out[a])<3 and len(out[b])<3:out[a].append(b);out[b].append(a)
 return {id:sorted(v) for id,v in out.items()}

def remember(store,other_id,now,valence):
 if other_id not in store and len(store)>=8:
  oldest=min(store,key=lambda x:(store[x]['last_clock'],x));store.pop(oldest)
 old=store.get(other_id,{'count':0,'warmth':0,'next_clock':-1})
 if now<old['next_clock']:return False
 store[other_id]={'last_clock':now,'count':min(100,old['count']+1),'warmth':max(-10,min(10,old['warmth']+valence)),'next_clock':now+75,'last_valence':valence}
 return True

start=time.perf_counter()
for name in ['profile.gd','social.gd','planner.gd','director.gd','crowd.gd','stations.gd']:
 p=SCRIPTS/name;check(p.is_file(),'missing_'+name)
 txt=p.read_text()
 check(txt.startswith('extends RefCounted'),'extends_'+name)
 check('\r' not in txt and len(txt)<25000,'format_'+name)
 # Lexical delimiters outside strings/comments, no AST or GDScript parser claims.
 filtered=[]
 for line in txt.splitlines():
  quote=None;esc=False
  for c in line:
   if quote:
    if esc:esc=False;continue
    if c=='\\':esc=True;continue
    if c==quote:quote=None
   elif c in ('"',"'"):quote=c
   elif c=='#':break
   else:filtered.append(c)
 stack=[];op={'(':')','[':']','{':'}'}
 for c in filtered:
  if c in op:stack.append(op[c])
  elif c in op.values():
   if not stack or stack.pop()!=c:failed.append('unbalanced_'+name);break
 check(not stack,'open_delimiter_'+name)
 for rel in re.findall(r'preload\("res://([^\"]+)"\)',txt):
  if rel.startswith('npc_system02/'):check((ROOT/rel).exists(),'missing_preload_'+rel)
for key in ['narrative/society/relationship_system.gd','living_world/state.gd','ai_core/world_clock.gd']:
 check((Path('/mnt/data/work/EXO-Murim-Cidade-Viva-01-R2')/key).exists(),'upstream_contract_'+key)
ss=(SCRIPTS/'social.gd').read_text()
for code in ['if not ah.is_empty()','if not aw.is_empty()','if not af.is_empty()','return remember(a,bid,now,response_a) and remember(b,aid,now,response_b)','get_bond(narrative,a,b)','MAX_CONTACTS := 8','records.erase(eldest)']:
 check(code in ss,'missing_contract_'+code)
check('social_memory' in (SCRIPTS/'profile.gd').read_text(),'social_memory_schema')
check('MEMORY_TTL := 6480.0' in ss,'memory_ttl_3d')
check('var response_a: int=-1' in ss and 'var response_b: int=-1' in ss,'asymmetric_memory')
check('Social.meet(' in (SCRIPTS/'director.gd').read_text(),'meeting_pipeline')
check('"patrol_leg":patrol_leg' in (ROOT/'convergence/resident.gd').read_text(),'patrol_snapshot')
check('"narrative":' not in (ROOT/'convergence/resident.gd').read_text(),'no_duplicate_narrative')
elapsed['static_s']=round(time.perf_counter()-start,4)
start=time.perf_counter()
for seed in [101,816204,72502,349812,15]:
 for region in range(88):
  for count in [6,16,35,65,72]:
   roster=[]
   for i in range(count):
    roster.append({'id':f'npc/r{region:02d}/s{seed}/{i:03d}','home':f'h{i//3}' if i>3 else '',
      'work':f'w{i//5}' if i>3 else '', 'role':['resident','merchant','disciple','guard','farmer'][i%5],
      'faction':['community','market','school','guard','community'][i%5] if i>3 else ''})
   linked=match(roster)
   check(len(linked)==count,f'match_count_{seed}_{region}_{count}')
   for p in roster:
    lid=p['id']
    check(len(linked[lid])<=3,'degree_'+lid)
    for friend in linked[lid]:check(lid in linked[friend],'reciprocal_'+lid)
   for p in roster[:4]:check(len(linked[p['id']])==0,'empty fields '+p['id'])
   rev=match(list(reversed(roster)))
   check(linked==rev,f'order_dependency_{seed}_{region}_{count}')
elapsed['relationship_model_s']=round(time.perf_counter()-start,3)
start=time.perf_counter()
for seed in [101,816204,15,99284]:
 for region in range(88):
  for i in range(32):
   memoryA={};memoryB={};last=-1
   for step in range(32):
    now=step*80.0
    who=f'npc/{seed}/{region}/{i}_{step%12}'
    a=remember(memoryA,who,now,1 if step%4 else -1)
    b=remember(memoryB,'reciprocal_'+str(step%12),now,1 if step%4 else -1)
    check(len(memoryA)<=8 and len(memoryB)<=8,f'bounded_{seed}_{region}_{i}_{step}')
    check(a==b,f'parallel_{seed}_{region}_{i}_{step}')
    if step%12==0 and step>=12:check(who not in memoryA or memoryA[who]['count']<=100,'counter_bound')
elapsed['memory_model_s']=round(time.perf_counter()-start,3)
status={'suite':'NPC-System-02-R2-offline-REFERENCE-MODEL_AND_STATIC','checks':checked,'failures':failed[:60], 'failure_count':len(failed),'timings':elapsed,'godot_native':'NOT_RUN','limitations':['Relationship matching and memory progression use a Python reference model, not GDScript runtime','Lexical syntax checks do not compile Godot scripts','No measured FPS / CPU / pathfinding / collisions']}
( SCRIPTS/'tests'/'qa_r2_offline_results.json').write_text(json.dumps(status,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(status,ensure_ascii=False))
raise SystemExit(1 if failed else 0)
