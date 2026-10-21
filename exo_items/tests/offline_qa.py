#!/usr/bin/env python3
"""Offline MODEL of the GDScript rules, NOT an execution of Godot/GDScript.

Use native/qa_native.gd for authoritative parity and save-integrity tests.
"""
import json, hashlib, random, math, pathlib, collections, time, sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
DATA=ROOT/'data'
def load(name):return json.loads((DATA/name).read_text(encoding='utf8'))
profiles=load('profiles.json'); rarities=load('rarities.json'); materials=load('materials.json'); affixes=load('affixes.json'); legacy=load('legacy_reference.json')['rules']
by_affix={a['id']:a for a in affixes}; rarmap={r['id']:r for r in rarities}
caps=legacy['caps']; costs={'damage_pct':320,'move_pct':500,'guard':12,'mana_regen':20,'stamina_regen':12,'elemental_pct':200,'agilidade':15,'inteligencia':15}
failures=[]; counts=collections.Counter(); stats=collections.Counter(); unique=set(); signatures=set(); sample=[]
def ok(cond,label):
 counts['assertions']+=1
 if not cond and len(failures)<50:failures.append(label)
def compatible(affix,family,ref,tags,chosen):
 if family not in affix['families']:return False
 if affix['refs'] and ref not in affix['refs']:return False
 if affix['tags_any'] and not any(t in tags for t in affix['tags_any']):return False
 for cid in chosen:
  prior=by_affix[cid]
  if prior['group']==affix['group'] or cid in affix['excludes'] or affix['id'] in prior['excludes']:return False
 return True

def weighted_pick(rng, options):
 total=sum(int(a['weight']) for a in options)
 if total<=0:return None
 roll=rng.randrange(total)
 for a in options:
  roll-=int(a['weight'])
  if roll<0:return a
 return None

def cost(st):return round(sum(v*costs[k] for k,v in st.items()),3)
def budget(r,level,q,mat):return min(100.,float(r['budget'])+min(6.,level/20.)+q*2.+mat['power'])
def fit(st,r,level,q,mat):
 st=st.copy(); b=budget(r,level,q,mat)
 for _ in range(6):
  if cost(st)<=b:break
  scale=b/max(.001,cost(st))
  for key in st:
   st[key]=math.floor(st[key]*scale) if key in ('guard','agilidade','inteligencia') else max(0,round(st[key]*scale,3))
 for _ in range(1000):
  if cost(st)<=b:break
  floats=[k for k,v in st.items() if k not in ('guard','agilidade','inteligencia') and v>=.001]
  if not floats:break
  key=max(floats,key=lambda k:costs[k])
  st[key]=max(0,round(st[key]-.001,3))
 return st

def generate(seed,source,family,ref,level,quality,rarity_id,material_id=None):
 profile=profiles[family][ref]; key=f'{seed}|{source}|{family}|{ref}|{level}|{quality}|{rarity_id}|{material_id or ""}|1|v2'
 rng=random.Random(int(hashlib.sha256(key.encode()).hexdigest()[:15],16))
 rarity=rarmap[rarity_id]
 mat=next((m for m in materials if m['id']==material_id),None) if material_id else rng.choice([m for m in materials if family in m['families']])
 if mat is None or family not in mat['families']:return None
 chosen=[];selected=[]
 for idx in range(rarity['affixes']):
  slot='prefix' if idx==0 else 'suffix' if idx==1 else None
  opts=[a for a in affixes if (slot is None or a['slot']==slot) and compatible(a,family,ref,profile['tags'],chosen)]
  a=weighted_pick(rng,opts)
  if not a:break
  chosen.append(a['id']);selected.append(a)
 st={}
 if family=='weapon':st['damage_pct']=round(.01+min(.095,rarity['rank']*.013+rng.uniform(0,.015)),3)
 for a in selected:
  for k,bounds in a['stats'].items():
   val=rng.uniform(*bounds)
   if k in ('guard','agilidade','inteligencia'):val=math.floor(val+0.5)
   st[k]=min(float(caps[k]), round(st.get(k,0.)+val,3))
 st=fit(st,rarity,level,quality,mat)
 return {'schema':2,'mode':'preview_only','id':'exo2/'+hashlib.sha256(key.encode()).hexdigest()[:40], 'seed':seed,'source':source,'family':family,'base_id':ref,'material_id':mat['id'],'rarity_id':rarity_id,'level':level,'quality':quality,'tier':1,'request_rarity':rarity_id,'request_material':material_id or '', 'affixes':chosen,'stats':st}

def valid(item):
 if item is None or item['family'] not in profiles:return False
 family=item['family'];ref=item['base_id']
 if ref not in profiles[family] or item['rarity_id'] not in rarmap:return False
 rarity=rarmap[item['rarity_id']]
 mat=next((a for a in materials if a['id']==item['material_id']),None)
 if mat is None or family not in mat['families'] or not 1<=item['level']<=100 or not 0<=item['quality']<=3:return False
 if len(item['affixes'])>rarity['affixes']:return False
 seen=[]
 for aid in item['affixes']:
  a=by_affix.get(aid)
  if a is None or not compatible(a,family,ref,profiles[family][ref]['tags'],seen):return False
  seen.append(aid)
 for key,value in item['stats'].items():
  if key not in caps or not math.isfinite(value) or not 0<=value<=float(caps[key])+1e-5:return False
  if key in ('guard','agilidade','inteligencia') and not float(value).is_integer():return False
 return cost(item['stats'])<=budget(rarity,item['level'],item['quality'],mat)+.0001

start=time.perf_counter()
ok(len(profiles['weapon'])==16, 'legacy weapon profiles count')
ok(len(rarities)==6, 'rarity definitions')
ok(all(r['legacy_supported']==(i<4) for i,r in enumerate(rarities)),'only 4 approved rarities')
ok(len(legacy['prefixes'])==5 and len(legacy['suffixes'])==6,'original affixes')
ok(all(v in caps for a in affixes for v in a['stats']),'all stats approved vocabulary')
ok(all(a['id'] not in {b['id'] for b in affixes[:i]} for i,a in enumerate(affixes)),'affix IDs unique')
# 10,000 determininism & uniqueness, with two independent instantiations of the reference model.
for i in range(10_000):
 fam=list(profiles)[i%len(profiles)]
 bases=sorted(profiles[fam]); ref=bases[(i//len(profiles))%len(bases)]
 args=(79311,f'event/r{(i%88)}/unit{i}',fam,ref,i%100+1,i%4,rarities[i%6]['id'])
 a=generate(*args); b=generate(*args)
 ok(a==b,f'determinism:{i}');ok(a['id'] not in unique,f'unique:{i}')
 unique.add(a['id']);counts['deterministic_generations']+=1
 signatures.add(json.dumps({k:v for k,v in a.items() if k in ('family','base_id','rarity_id','material_id','affixes','stats')},sort_keys=True,ensure_ascii=False))
 ok(valid(a),f'generated_invalid:{i}')
 counts['affix_checks']+=1
 ok(all(compatible(by_affix[aid],fam,ref,profiles[fam][ref]['tags'],a['affixes'][:j]) for j,aid in enumerate(a['affixes'])),f'affix:{i}')
 counts['power_checks']+=1
 ok(cost(a['stats'])<=budget(rarmap[a['rarity_id']],a['level'],a['quality'],next(m for m in materials if m['id']==a['material_id']))+.0001,f'budget:{i}')
 stats['rarity_'+a['rarity_id']]+=1
 if len(sample)<20 and a['family']=='weapon':sample.append(a)
 if i<5000:
  raw=json.dumps(a,sort_keys=True,ensure_ascii=False,separators=(',',':'))
  reloaded=json.loads(raw)
  ok(a==reloaded,f'json_roundtrip:{i}');ok(valid(reloaded),f'json_validation:{i}')
  counts['serialization_cycles']+=1
# Statistical sampling of the REAL legacy tier-weight tables (reference distribution only).
for tier in range(3):
 rng=random.Random(4000+tier); distribution=collections.Counter()
 options=[(r['label'],int(r['tier_weights'][tier])) for r in rarities if r['legacy_supported']]
 total=sum(w for _,w in options)
 for _ in range(10000):
  roll=rng.randrange(total)
  for label,weight in options:
   roll-=weight
   if roll<0:
    distribution[label]+=1
    break
 for label,weight in options:
  expected=10000*weight/total
  ok(abs(distribution[label]-expected) <= max(80,6*math.sqrt(expected)),f'weighted_rarity_tier_{tier}_{label}')
 stats[f'tier_{tier+1}_sample']=dict(distribution)
 counts['rarity_weight_draws']+=10000
# adversarial range corruption/incompatible tags/duplicate event/isolation
for k,v in [('damage_pct',3.4),('move_pct',.9),('mana_regen',100),('guard',-2),('inteligencia',3)]:
 a=generate(1,'bad','weapon','sword',10,0,'rare')
 a['stats'][k]=v
 ok(not valid(a),f'bad_stat_{k}')
 counts['adversarial']+=1
for a in affixes:
 ok(bool(a['group']) and a['slot'] in ('prefix','suffix') and a['weight']>0,f'affix_schema_{a["id"]}')
 counts['adversarial']+=1
for weapon_id in profiles['weapon']:
 ok(profiles['weapon'][weapon_id]['base_damage']>0 and profiles['weapon'][weapon_id]['hands'] in (1,2) and bool(profiles['weapon'][weapon_id]['tags']),f'valid_catalog_base_{weapon_id}')
# Confirm no protected base files included in patch and every direct preload resolves.
base_files={'exo_core/core.gd','exo_core/event_bus.gd','exo_core/service_registry.gd','convergence/game.gd','convergence/region.gd','journey_save.gd','inventory.gd','project.godot'}
module_files=[p for p in ROOT.rglob('*') if p.is_file()]
ok(all(str(p.relative_to(ROOT)) not in base_files for p in module_files),'no protected file modified')
for file in ROOT.rglob('*.gd'):
 if 'fixtures' in file.parts: continue
 import re
 content=file.read_text()
 for dep in re.findall(r'preload\("res://(.*?)"\)',content):
  ok((ROOT/dep[len('exo_items/'):]).exists() if dep.startswith('exo_items/') else dep in ['inventory.gd','procedural/loot_generator.gd','procedural/world_state.gd'],f'preload_missing {file.name}:{dep}')
 counts['source_dependency_checks']+=1
# key recommendation: only legacy generation can be granted.
ok(all(not r['legacy_supported'] for r in rarities[4:]),'future rarities gated')
metrics={'status':'OFFLINE_REFERENCE_PASS' if not failures else 'OFFLINE_REFERENCE_FAIL','native_godot':'NOT_RUN','core_integration':'NOT_RUN','checks':dict(counts),'distribution':dict(stats),'unique_descriptor_instances':len(unique),'distinct_observed_stat_material_affix_combinations':len(signatures),'rarities':len(rarities),'affixes_total':len(affixes),'legacy_weapon_bases':len(profiles['weapon']),'elapsed_seconds':round(time.perf_counter()-start,3),'failures':failures,'warning':'Python is a reference data/model test; not GDScript execution or native engine validation.'}
(ROOT.parent/'evidencias'/'OFFLINE-QA-RESULTADOS.json').write_text(json.dumps(metrics,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
(ROOT.parent/'evidencias'/'EXEMPLOS-DESCRITORES-V2.json').write_text(json.dumps(sample,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
print(json.dumps(metrics,ensure_ascii=False,indent=2))
sys.exit(0 if not failures else 1)
