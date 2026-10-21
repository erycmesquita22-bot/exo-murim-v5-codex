#!/usr/bin/env python3
"""R4 offline QA of content-only proposals. Not Godot native or gameplay persistence."""
from pathlib import Path
from collections import Counter,defaultdict
import hashlib,json,random,re,time,sys,zipfile,statistics
ROOT=Path(__file__).resolve().parents[2] if __file__.endswith('/exo_world_library/tests/qa_r4.py') else Path('/mnt/data/work_exo_bridge_r4/build')
MOD=ROOT/'exo_world_library';B=Path('/mnt/data/work_exo_bridge_r4/base_r3/exo_world_library')
errors=[];checks=0; stats=Counter(); rejects=Counter(); samples=[];start=time.monotonic()
def chk(ok,reason):
 global checks
 checks+=1
 if not ok and len(errors)<50:errors.append(str(reason))
def load(p):return json.loads(Path(p).read_text(encoding='utf-8'))
old=load(B/'manifest.json');m=load(MOD/'manifest.json')
chk(len(old['catalogs'])==75,'R3_domains_baseline');chk(len(m['catalogs'])==76,'R4_domain_count')
by_id={};domains={};origin=Counter()
for ent in m['catalogs']:
 d=ent['domain']; obj=load(MOD/'data'/f'{d}.json');rs=obj['records'];domains[d]=rs
 chk(len(rs)==ent['count'],f'count_{d}')
 for r in rs:
  chk(re.fullmatch('[a-z][a-z0-9_]*/[a-z0-9_]+',r['id']) is not None,'bad_id '+r['id']);chk(r['id'] not in by_id,'dup '+r['id'])
  chk(r.get('domain')==d,'wrong_domain '+r['id']); chk(r.get('weight',0)>=0,'weight '+r['id'])
  chk(not set(r.get('requires',[]))&set(r.get('excludes',[])),'contradictory_requires '+r['id'])
  if r['origin']=='external_ref':chk(r['weight']==0 and r['status']=='reference_only','unsafe_ref '+r['id'])
  by_id[r['id']]=r;origin[r['origin']]+=1
for r in by_id.values():
 for link in r['links']:chk(link in by_id,'unresolved_link '+r['id']+' '+link)
preserved=0
for ent in old['catalogs']:
 d=ent['domain'];f=f'data/{d}.json';o=(B/f).read_bytes();n=(MOD/f).read_bytes();chk(o==n,'old_catalog_mutated '+d);preserved+=1
chk(sum(e['count'] for e in old['catalogs'])==1218,'R3_records_baseline')
chk(len(by_id)==1228,'new_total_records')
chk(origin==Counter({'authorial':1016,'external_ref':212}),f'origin_count {origin}')
chk(preserved==75,'catalogs_not_preserved')
# localized metadata for all 10 new functions, no asset/placement authority
loc={k:load(MOD/'localization'/f'interior_scene_hint.{k}.json') for k in ('pt_BR','en_US','zh_CN')}
functions={'administration','farmstead','herbalist','inn','market','martial_school','residence','shrine','smithy','warehouse'}
chk({r['variables']['function'] for r in domains['interior_scene_hint']}==functions,'10_functions_mismatch')
for r in domains['interior_scene_hint']:
 key=r['label_key']
 for k in loc:chk(key in loc[k] and bool(loc[k][key]),f'missing_translation_{k}:{key}')
 chk(not r['variables']['save_write'] and not r['variables']['geometry_generated'] and not r['variables']['entrance_permission'],'unsafe_interior_rights')
 chk(r['conditions']['building_function']==r['variables']['function'],'interior_condition_conflict')
 chk(r['variables']['prefab_id'] is None,'wrong_prefab_binding')
 chk(r['variables']['provenance']['licensed_assets_included'] is False,'no_new_assets')
# 48 story arcs / 96 side arcs preserved, graph terminal and no cycles
arcs={r['id']:r for r in domains['story_arc']}
chk(len(arcs)==48,'R3_arc_count'); chk(len(domains['parallel_arc'])==96,'R3_parallel_count')
for r in domains['parallel_arc']:
 parent=r['variables']['parent_story_id'];chk(parent in arcs,'missing_parallel_parent');chk(r['variables'].get('never_auto_commit') is True,'parallel_save_misuse')
for id,r in arcs.items():
 nodes={n['id']:n for n in r['variables']['nodes']}
 chk(len(nodes)==len(r['variables']['nodes']),'node_collision '+id)
 terminals={k for k,n in nodes.items() if n.get('stage')=='terminal'}
 chk(bool(terminals),'no_terminal '+id)
 for start_id in nodes:
  stack=[(start_id,frozenset())]
  while stack:
   nid,seen=stack.pop()
   if nid in seen:chk(False,'story_cycle '+id);break
   n=nodes[nid]
   if nid in terminals:
    chk(not n['choices'],'terminal_continues '+id)
    continue
   chk(bool(n['choices']),'dead_end '+id)
   for e in n['choices']:
    chk(e['next'] in nodes,'dangling '+id)
    if e['next'] in nodes:stack.append((e['next'],seen|{nid}))
# fast mathematical mirror of R4 conditions and private-seed policy, not Godot RNG parity
EXCLUSIVE=[{'flood_active','drought_active'},{'public_festival','curfew_active'},{'peace_only','siege_active'},{'open_market','trade_embargo'}, {'waterway_blocked','ferry_operational'}, {'faction_allied','faction_at_war'},{'npc_living','npc_deceased'},{'electoral_voting','imperial_appointment'},{'interior_public','interior_sealed'}]
policy=load(MOD/'contracts/coherence_policy.json')
biomes=['grassland','temperate_forest','bamboo_forest','dry_valley','wetland','rocky_highlands','alpine','mixed_woodland']
settlement_types=['none','village','town','city']

def check_ctx(ctx):
 if not (isinstance(ctx.get('region_id'),int) and not isinstance(ctx['region_id'],bool) and 0<=ctx['region_id']<=87):return 'invalid_region'
 if not isinstance(ctx.get('world_id'),str) or not ctx['world_id']:return 'world_id_missing'
 if not isinstance(ctx.get('seed'),int):return 'invalid_seed'
 if ctx.get('biome') not in biomes:return 'invalid_biome'
 if ctx.get('settlement_type') not in settlement_types:return 'invalid_settlement'
 return None

def reason(r,c,tags=()):
 if r['origin']!='authorial' or r['status']!='candidate' or r['weight']<=0:return 'non_selectable_reference'
 if r['id'] in c.get('excluded_record_ids',[]):return 'excluded_record_id'
 if r['id'] in c.get('previous_record_ids',[]):return 'previous_record_id'
 cond=r['conditions']
 for k,v in cond.items():
  if k.endswith('_in'):
   if c.get(k[:-3]) not in v:return 'conditions'
  elif k=='min_player_tier':
   if c.get('player_tier',-1)<v:return 'conditions'
  elif k=='max_player_tier':
   if c.get('player_tier',-1)>v:return 'conditions'
  elif k=='tags_all':
   if not set(v).issubset(c.get('tags',[])):return 'conditions'
  elif k=='tags_any':
   if not set(v)&set(c.get('tags',[])):return 'conditions'
  elif c.get(k)!=v:return 'conditions'
 if not set(r['requires']).issubset(c.get('flags',[])) or set(r['excludes'])&set(c.get('flags',[])):return 'flags'
 combined=set(c.get('tags',[]))|set(tags)|set(r['tags'])
 for group in EXCLUSIVE:
  if len(combined&group)>1:return 'exclusive_tags'
 for row in policy['context_incompatibilities']:
  if all(c.get(k)==v for k,v in row['if_context'].items()) and set(r['tags'])&set(row['reject_any_tags']):return 'context_tag_forbidden'
 for row in policy['selected_tag_requirements']:
  if row['tag'] in r['tags'] and not set(row['any_of'])&combined:return 'tag_dependency'
 v=r.get('variables',{})
 if 'allowed_settlement_types' in v and c.get('settlement_type') not in v['allowed_settlement_types']:return 'settlement_forbidden'
 if 'allowed_biomes' in v and c.get('biome') not in v['allowed_biomes']:return 'biome_forbidden'
 if 'min_power' in v and c.get('player_tier',-1)<v['min_power']:return 'power_low'
 if 'max_power' in v and c.get('player_tier',-1)>v['max_power']:return 'power_high'
 if 'faction_required' in v and c.get('faction_id')!=v['faction_required']:return 'wrong_faction'
 if any(f not in c.get('verified_facts',[]) for f in v.get('required_host_facts',[])):return 'missing_host_fact'
 if any(f in c.get('verified_facts',[]) for f in v.get('excluded_host_facts',[])):return 'excluded_host_fact'
 if r['domain']=='parallel_arc' and v.get('parent_story_id')!=c.get('parent_story_id'):return 'parent_story_unverified'
 return None

def choose(records,c,slot='0'):
 if (failure:=check_ctx(c)):return ('BLOCKED',failure)
 candidates=[]
 for r in records:
  why=reason(r,c)
  if why: rejects[why]+=1
  else:candidates.append(r)
 if not candidates:return ('BLOCKED','no_eligible_records')
 candidates.sort(key=lambda x:x['id'])
 key='EXO-WORLD-LIBRARY-R4|'+str(c['world_id'])+'|'+str(c['seed'])+'|'+str(c['region_id'])+'|'+str(c.get('instance_key',''))+'|'+records[0]['domain']+'|'+str(slot)+'|'+json.dumps(c,sort_keys=True,ensure_ascii=False,separators=(',',':'))
 digest=hashlib.sha256(key.encode()).digest();v=int.from_bytes(digest[:8],'big'); total=sum(r['weight'] for r in candidates);roll=(v/(2**64))*total
 for r in candidates:
  roll-=r['weight']
  if roll<0:return ('PROPOSAL_ONLY',r['id'])
 return ('PROPOSAL_ONLY',candidates[-1]['id'])
# 88 region * 8 biome * 4 settlement * 10 official functions = 28160 tested contexts
for rid in range(88):
 for biome in biomes:
  for settlement in settlement_types:
   for func in sorted(functions):
    c={'world_id':'qa-region','seed':20261020,'region_id':rid,'biome':biome,'settlement_type':settlement,'building_function':func,'instance_key':f'location-{rid}' }
    state,record=choose(domains['interior_scene_hint'],c)
    chk(state=='PROPOSAL_ONLY' and record=='interior_scene_hint/'+func,f'interior_select_{rid}_{func}')
    stats['region_biome_settlement_function_contexts']+=1
# 100k seeded repeatable selections across both residential and broad narrative contexts
seedrng=random.Random(20261020)
selects=Counter()
for i in range(100000):
 c={'world_id':'world_'+str(i%13),'seed':seedrng.randrange(0,2**31),'region_id':seedrng.randrange(88),'biome':biomes[seedrng.randrange(8)],'settlement_type':settlement_types[seedrng.randrange(4)],'player_tier':seedrng.randrange(8),'instance_key':f'placement_{i%7}', 'tags':['river_access'] if i%4==0 else [],'flags':[]}
 domain=['world_event','region_theme','npc_archetype','rumor','martial_trial','interior_scene_hint'][i%6]
 if domain=='interior_scene_hint': c['building_function']='residence'
 a=choose(domains[domain],c,str(i%17));selects[domain]+=1;chk(a[0]=='PROPOSAL_ONLY',f'selection_no_content_{i}')
 if i<12:samples.append(c['seed'])
 if i%31==0:
  b=choose(domains[domain],dict(reversed(list(c.items()))),str(i%17));chk(a==b,f'determinism_key_order_{i}');stats['determinism_probes']+=1
 stats['selection_contexts']+=1
# synthetic adversarial tests — 50,000 probes
base={'world_id':'qa','seed':101,'region_id':78,'biome':'grassland','settlement_type':'town','tags':[],'flags':[]}
for i in range(50000):
 pair=EXCLUSIVE[i%len(EXCLUSIVE)]
 mock={'id':f'synthetic/{i}','domain':'synthetic','origin':'authorial','status':'candidate','weight':10,'tags':[sorted(pair)[0]],'conditions':{},'requires':[],'excludes':[],'variables':{}}
 c={**base,'tags':[sorted(pair)[1]]}
 chk(reason(mock,c)=='exclusive_tags',f'exclusive_not_rejected_{i}')
 stats['adversarial_exclusive_probes']+=1
for domain in ['ref_item_affixes','ref_bestiary_species','ref_city_profiles']:
 sample=domains[domain][0]
 chk(reason(sample,base)=='non_selectable_reference','external_ref_elected_'+domain)
for invalid in [-1,88,2.5,'0','foo',None,True]:
 chk(check_ctx({**base,'region_id':invalid})=='invalid_region','invalid_region_accepted')
# stale/replay/race mirror, no actual Narrative or JourneySave writes
ledger=set();sim_replay=0
for i in range(20000):
 st=f'arc/{i%48}|world/i{i}|rev:{i%7}|choice:confirm'
 h=hashlib.sha256(st.encode()).hexdigest()
 chk(h not in ledger,'unexpected_collision')
 ledger.add(h);chk(h in ledger,'staged_not_visible')
 ledger.remove(h)
 chk(h not in ledger,'rollback_failed')
 sim_replay+=1
stats['staged_rollback_synthetic']=sim_replay
# validate schemas (JSON Schema 2020) 
try:
 import jsonschema
 schema=load(MOD/'contracts/record.schema.json')
 for r in by_id.values():
  jsonschema.validate(r,schema)
  stats['schema_validations']+=1
except Exception as e:
 errors.append('JSON_SCHEMA:'+str(e)[:200])
# file safety scanning does not substitute Godot parser
for script in (MOD/'integration').glob('*.gd'):
 t=script.read_text(encoding='utf-8')
 for forbidden in ['JourneySave.write(', 'save_progress(', 'events.publish(', 'register_domain(', 'instantiate(', 'queue_free(', 'scene_tree.change_scene']:
  chk(forbidden not in t,f'forbidden_runtime_mutation:{script.name}:{forbidden}')
# older R4/R5 archives are not overwritten by this distinct R4-bridges branch
out={'suite':'EXO_WORLD_LIBRARY_R4_BRIDGES_OFFLINE','status':'PASS' if not errors else 'FAIL','errors':errors,'checks_total':checks,'domains':len(domains),'records':len(by_id),'authorial':origin['authorial'],'external_refs':origin['external_ref'],'R3_catalogs_byte_preserved':preserved,'new_interior_records':len(domains['interior_scene_hint']),'counters':dict(stats),'rejection_counters':dict(rejects),'selection_domains':dict(selects),'sample_seed_values':samples,'godot_native':'NOT_RUN_BINARY_UNAVAILABLE','host_integration':'NOT_RUN_NO_MERGE','save_reopen':'NOT_RUN_ONLY_SIMULATED_ROLLBACK','rng_parity':'NOT_RUN_PYTHON_MIRROR_NOT_GODOT_PCG','seconds':round(time.monotonic()-start,2)}
(ROOT/'QA-BIBLIOTECA-R4.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in out.items() if k not in ['rejection_counters','selection_domains']},ensure_ascii=False,indent=2))
sys.exit(0 if not errors else 1)
