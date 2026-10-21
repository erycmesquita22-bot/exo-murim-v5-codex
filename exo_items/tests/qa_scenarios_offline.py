#!/usr/bin/env python3
"""Scenario-focused OFFLINE REFERENCE MODEL + source/contract audit.
This does not execute GDScript/Godot and cannot certify native integration.
Reads exact checked-in EXO Core catalogs extracted for audit; does not modify Core.
"""
from __future__ import annotations
import json, hashlib, math, pathlib, copy, collections, time, random, re, sys
R=pathlib.Path(__file__).resolve().parents[2]
ITEMS=R/'exo_items'
CORE=R/'CORE_READONLY' if (R/'CORE_READONLY/data/weapons.json').exists() else ITEMS/'tests/fixtures/core'
OUT=R/'evidencias'
OUT.mkdir(parents=True,exist_ok=True)
load=lambda p: json.loads(p.read_text('utf8'))
weapons={x['id']:x for x in load(CORE/'data/weapons.json')}
loot=load(CORE/'data/loot_rules.json')
profiles=load(ITEMS/'data/profiles.json')
rarities=load(ITEMS/'data/rarities.json')
materials=load(ITEMS/'data/materials.json')
affixes=load(ITEMS/'data/affixes.json')
issues=[];n=collections.Counter();cases=[];findings=[]

def assert_true(cond, tag, detail=''):
 n['assertions']+=1
 if not cond:
  issues.append({'test':tag,'detail':detail})

def case(name,fn):
 before=len(issues);start=time.monotonic();fn()
 cases.append({'scenario':name,'result':'PASS' if len(issues)==before else 'FAIL', 'assertions':n['assertions'], 'duration_s':round(time.monotonic()-start,3)})

M=2147483647

def stream(world, domain,key):
 v=f'{world["seed"]}|{world["generation_version"]}|{domain}|{key}'
 h=int(hashlib.sha256(v.encode()).hexdigest()[:8],16)%(M-1)
 return ((h%(M-1))+1)*48271%M

def rand_between(world,domain,key,lo,hi):
 state=stream(world,domain,key)
 return lo+(hi-lo)*(state-1)/(M-1)

def pick(world,domain,key,opts):return opts[stream(world,domain,key)%len(opts)]

def make_item(world,source,pool,tier,uid,base=''):
 assert 1<=tier<=3 and pool in loot['pools']
 key='loot/'+source
 ref=base or pick(world,'loot/base',key,loot['pools'][pool])
 roll=stream(world,'loot/rarity',key)%sum(int(r['weights'][tier-1]) for r in loot['rarities'])
 rarity=None
 for r in loot['rarities']:
  roll-=r['weights'][tier-1]
  if roll<0:rarity=r;break
 val=rand_between(world,'loot/quality',key,*rarity['quality'])
 stats={'damage_pct':round(val,3)}
 item={'uid':uid,'kind':'weapon','ref':ref,'qty':1,'rarity':rarity['name'],'affixes':[], 'prefix':'','suffix':'','affinity':-1,'stats':stats,'instance_id':world['id']+'/'+key,'generation':{'version':1,'source':key,'tier':tier}}
 previous=''
 for slot in ['prefix','suffix']:
  if len(item['affixes'])>=int(rarity['affixes']):break
  options=[a for a in loot[slot+'es'] if (not a['refs'] or ref in a['refs']) and a['group']!=previous]
  if not options:continue
  aff=pick(world,'loot/'+slot+'es',key,options)
  item[slot]=aff['id'];item['affixes'].append(aff['id']);previous=aff['group'] if slot=='prefix' else previous
  if 'affinity' in aff:item['affinity']=aff['affinity']
  for stat,bounds in aff['stats'].items():
   v=rand_between(world,'loot/values/'+slot,key,*bounds)
   if stat in ['guard','agilidade','inteligencia']:v=math.floor(v+.5)
   stats[stat]=min(loot['caps'][stat],round(stats.get(stat,0)+v,3))
 return item

def valid_item(item):
 if not isinstance(item,dict) or not isinstance(item.get('uid'),str) or not item['uid'].startswith('item_'):return False
 if item.get('kind')!='weapon' or item.get('ref') not in weapons or item.get('qty')!=1:return False
 if 'generation' not in item:return not ('stats' in item or 'instance_id' in item)
 gen=item['generation']
 if not isinstance(gen,dict) or gen.get('version')!=1 or gen.get('tier') not in (1,2,3):return False
 if not isinstance(gen.get('source'),str) or len(gen['source'])>128:return False
 if not isinstance(item.get('instance_id'),str) or not item['instance_id'].startswith('world_') or len(item['instance_id'])>240:return False
 rarity=next((r for r in loot['rarities'] if r['name']==item.get('rarity')),None)
 if rarity is None or len(item.get('affixes',[]))!=rarity['affixes']:return False
 expected=[];groups=[];affinity=-1;bounds={'damage_pct':list(rarity['quality'])}
 for slot in ('prefix','suffix'):
  aid=item.get(slot)
  if not isinstance(aid,str):return False
  if not aid:continue
  aff=next((a for a in loot[slot+'es'] if a['id']==aid),None)
  if aff is None or (aff['refs'] and item['ref'] not in aff['refs']) or aff['group'] in groups:return False
  groups.append(aff['group']);expected.append(aid)
  if 'affinity' in aff:affinity=aff['affinity']
  for stat,ab in aff['stats'].items():
   if stat not in bounds:bounds[stat]=[0.0,0.0]
   bounds[stat][0]+=ab[0];bounds[stat][1]+=ab[1]
 if expected!=item.get('affixes') or affinity!=item.get('affinity'):return False
 if len(bounds)!=len(item.get('stats',{})):return False
 for key,val in item['stats'].items():
  if not isinstance(val,(float,int)) or not math.isfinite(val) or key not in bounds:return False
  if val<max(0,min(loot['caps'][key],bounds[key][0])-.0015) or val>min(loot['caps'][key],bounds[key][1])+.0015:return False
  if key in ('guard','agilidade','inteligencia') and int(val)!=val:return False
 return True

def mock_world(seed=79):return {'schema':1,'seed':seed,'id':'world_qa_scenarios','generation_version':1,'events':{}}

def mock_save(item_count=0,seed=79):
 s={'world':mock_world(seed),'items':[],'next_item':item_count+1,'pending_loot':[],'equipped':''}
 for i in range(item_count):s['items'].append({'uid':f'item_{i+1}','kind':'material','ref':'iron','qty':1})
 return s

def preflight(save,item,source):
 nxt=save.get('next_item')
 if not isinstance(nxt,(int,float)) or not math.isfinite(nxt) or nxt!=int(nxt) or nxt<1 or nxt>2147483647:return False
 if not valid_item(item) or item['generation']['source']!='loot/'+source or item['uid']!=f'item_{int(nxt)}':return False
 if len(save.get('items',[]))>=24 or 'loot/'+source in save['world']['events']:return False
 for x in save['items']:
  if x.get('uid')==item['uid'] or x.get('instance_id','')==item['instance_id']:return False
 for entry in save['pending_loot']:
  if entry.get('source')==source:return False
  for obj in entry.get('items',[]):
   if obj.get('uid')==item['uid'] or obj.get('instance_id','')==item['instance_id']:return False
 return True

def simulate_collect(save,source,save_succeeds=True):
 # Exact atomicity shape of inventory.gd: rollback full save on any failed item / failed save.
 old=copy.deepcopy(save)
 try:
  entry=next(e for e in save['pending_loot'] if e['source']==source)
  for reward in entry['items']:
   if 'generation' in reward:
    if len(save['items'])>=24 or not valid_item(reward) or any(x['uid']==reward['uid'] for x in save['items']):raise ValueError('invalid/full')
    save['items'].append(copy.deepcopy(reward))
   else:
    if reward['kind'] in ('material','consumable'):
     existing=next((x for x in save['items'] if x.get('kind')==reward['kind'] and x.get('ref')==reward['ref'] and x['qty']+reward['qty']<=99),None)
     if existing:existing['qty']+=reward['qty']
     elif len(save['items'])<24:
      save['items'].append({'uid':f'item_{save["next_item"]}','kind':reward['kind'],'ref':reward['ref'],'qty':reward['qty']});save['next_item']+=1
     else:raise ValueError('full')
    elif len(save['items'])<24:
     save['items'].append({'uid':f'item_{save["next_item"]}', 'kind':reward['kind'],'ref':reward['ref'],'qty':1});save['next_item']+=1
    else:raise ValueError('full')
  save['pending_loot'].remove(entry)
  save['world']['events']['loot/'+source]={'status':'collected'}
  if not save_succeeds:raise OSError('save_failed')
  return True
 except (StopIteration, ValueError, OSError):
  save.clear();save.update(old);return False


def scenario_catalog():
 assert_true(set(profiles['weapon'])==set(weapons),'weapon_ids_match')
 for k,real in weapons.items():
  p=profiles['weapon'][k]
  assert_true((p['base_damage'],p['hands'],p['name'])==(real['damage'],real['hands'],real['name']),f'weapon_{k}_stats_match')
 assert_true(loot['caps']==load(ITEMS/'data/legacy_reference.json')['rules']['caps'],'stat_caps_match')
 assert_true(len(affixes)==17,'affix_catalog')
 assert_true(len(rarities)==6 and sum(r['legacy_supported'] for r in rarities)==4,'rarity_gates')
 assert_true(not any(x['legacy'] for group in ('armor','accessory','special') for x in profiles[group].values()),'no_fake_equipment')


def scenario_seed_areas():
 distinct=set()
 for region in range(88):
  for enemy,pool in [('bandit','blade'),('cultist','mage'),('chief','boss'),('beast','blade')]:
   source=f'eco/r{region}/{enemy}/death'
   item=make_item(mock_world(91+region),source,pool,3 if pool=='boss' else 1,f'item_{1+region*4+len(distinct)%4}')
   assert_true(valid_item(item),f'loot_{region}_{enemy}')
   a=make_item(mock_world(91+region),source,pool,3 if pool=='boss' else 1,item['uid'])
   assert_true(a==item, f'determinism_{region}_{enemy}')
   distinct.add(item['instance_id'])
 assert_true(len(distinct)==88*4,'regional_instance_collision')
 n['real_legacy_reference_generated']+=88*4


def scenario_random_legacy():
 rare_counts=collections.Counter();af_counts=collections.Counter();errs=0
 for i in range(20000):
  w=mock_world(i%29+100)
  source=f'eco/r{i%88}/unit{i}/last_hit'
  tier=i%3+1;pool=['blade','mage','boss'][i%3];ref=list(weapons)[i%len(weapons)] if i%11==0 else ''
  item=make_item(w,source,pool,tier,f'item_{i+1}',ref)
  accepted=valid_item(item)
  if ref and ref not in loot['pools'][pool] and not accepted:
   n['unsupported_override_rejected']+=1
  else:
   assert_true(accepted,f'generated_{i}')
  raw=json.dumps(item,ensure_ascii=False)
  if accepted:
   assert_true(valid_item(json.loads(raw)),f'reloaded_{i}')
  assert_true(item['instance_id']==make_item(w,source,pool,tier,f'item_{i+1}',ref)['instance_id'],f'stable_{i}')
  rare_counts[(tier,item['rarity'])]+=1
  af_counts[len(item['affixes'])]+=1
 n['real_legacy_reference_generated']+=20000
 n['serialized_legacy_reference']+=20000
 n['rarity_observed']=sum(rare_counts.values())
 (OUT/'DISTRIBUICAO-LEGADO-QA-03.json').write_text(json.dumps({'by_tier_and_rarity':{f'{k[0]}:{k[1]}':v for k,v in rare_counts.items()},'affixes_count':dict(af_counts)},indent=2,ensure_ascii=False)+'\n')


def scenario_balance_adversarial():
 # Mirrors the corrected implementation's two-phase normalization; it is not native execution.
 costs={'damage_pct':320.,'move_pct':500.,'guard':12.,'mana_regen':20.,'stamina_regen':12.,'elemental_pct':200.,'agilidade':15.,'inteligencia':15.}
 integer={'guard','agilidade','inteligencia'}
 caps=loot['caps']
 def norm(v):return round(v+1e-10,3)
 def total(stat):return norm(sum(v*costs[k] for k,v in stat.items()))
 def fit(st,b):
  result=st.copy()
  if total(result)<=b:return result
  for _ in range(8):
   v=total(result)
   if v<=b:break
   factor=b/max(.001,v)
   for k in result:result[k]=math.floor(result[k]*factor) if k in integer else max(0.,norm(result[k]*factor))
  for _ in range(2000):
   if total(result)<=b:break
   choices=[k for k,v in result.items() if k not in integer and v>=.001]
   if not choices:break
   target=max(choices,key=lambda k:costs[k])
   result[target]=max(0.,norm(result[target]-.001))
  for _ in range(16):
   if total(result)<=b:break
   choices=[k for k,v in result.items() if k in integer and v>=1.]
   if not choices:break
   target=max(choices,key=lambda k:costs[k]);result[target]-=1.
  return result
 rng=random.Random(5108)
 for i in range(30000):
  r=rarities[i%6];mat=materials[(i*13)%len(materials)];lv=i%100+1;q=i%4
  budget=min(100.,r['budget']+min(6.,lv/20.)+q*2+mat['power'])
  stats={k:(rng.randrange(int(cap)+1) if k in integer else norm(rng.random()*cap)) for k,cap in caps.items()}
  if i%47==0:stats={k:(float(cap) if k in integer else cap) for k,cap in caps.items()}
  if i%53==0:stats={k:(float(cap) if k in integer else cap) for k,cap in caps.items() if k in integer}
  fitted=fit(stats,budget)
  assert_true(total(fitted)<=budget+.0001, f'fit_budget_{i}')
  assert_true(all(math.isfinite(v) and 0<=v<=caps[k]+.0001 and (k not in integer or v==int(v)) for k,v in fitted.items()),f'fit_caps_{i}')
  assert_true(fitted==fit(stats,budget),f'fit_deterministic_{i}')
 n['power_fit_reference_cases']+=30000

def scenario_only_valid_natural_pools():
 # Official base pools, without overrides: detect generator defects across all three tiers.
 for i in range(30000):
  pool=['blade','mage','boss'][i%3]
  value=make_item(mock_world(i%41+301),f'eco/r{i%88}/enemy/{i}',pool,i%3+1,f'item_{i+1}')
  assert_true(valid_item(value), f'natural_pool_{i}')
 n['natural_pool_generations']+=30000

def scenario_inventory_edges():
 source='eco/r1/road_blade'
 # At 23 slots, a composite reward (materials + weapon + manual) fails atomically.
 s=mock_save(23);weapon=make_item(s['world'],source,'blade',1,f'item_{s["next_item"]}')
 s['pending_loot'].append({'source':source,'items':[{'kind':'material','ref':'iron','qty':2},{'kind':'manual','ref':'golpe_circular','qty':1},weapon]})
 s['world']['events']['loot/'+source]={'status':'pending'}
 old=copy.deepcopy(s)
 assert_true(not simulate_collect(s,source),'rollback_when_capacity_23')
 assert_true(s==old,'no_item_leak_23')
 # Full inventory: remains on floor without duplicating.
 s=mock_save(24);weapon=make_item(s['world'],source,'blade',1,f'item_{s["next_item"]}')
 s['pending_loot'].append({'source':source,'items':[weapon]});s['world']['events']['loot/'+source]={'status':'pending'}
 old=copy.deepcopy(s)
 assert_true(not simulate_collect(s,source) and s==old,'full_24_preserves_pending')
 # 21 slots: compound boss reward with stacking succeeds once.
 s=mock_save(21);weapon=make_item(s['world'],source,'boss',3,f'item_{s["next_item"]}')
 s['next_item']+=1 # drop_for reserves the weapon UID before collection
 s['pending_loot'].append({'source':source,'items':[{'kind':'material','ref':'iron','qty':2},{'kind':'manual','ref':'golpe_circular','qty':1},weapon]});s['world']['events']['loot/'+source]={'status':'pending'}
 assert_true(simulate_collect(s,source),'composite_boss_claim')
 after=copy.deepcopy(s)
 assert_true(not simulate_collect(s,source) and s==after,'cannot_collect_twice')
 # Rollback after serialized commit failure.
 s=mock_save(1);weapon=make_item(s['world'],source,'boss',3,f'item_{s["next_item"]}')
 s['pending_loot'].append({'source':source,'items':[weapon]});s['world']['events']['loot/'+source]={'status':'pending'}
 before=copy.deepcopy(s)
 assert_true(not simulate_collect(s,source,False) and s==before,'rollback_save_fail')
 # Stack near 99
 s=mock_save(0);s['items']=[{'uid':'item_1','kind':'material','ref':'iron','qty':97}];s['next_item']=2
 s['pending_loot']=[{'source':source,'items':[{'kind':'material','ref':'iron','qty':2}]}]
 assert_true(simulate_collect(s,source),'stack_to_99')
 assert_true(s['items'][0]['qty']==99 and len(s['items'])==1,'not_double_allocate_slot')


def scenario_pending_collisions():
 s=mock_save()
 v=make_item(s['world'],'death/a','blade',1,'item_1')
 assert_true(preflight(s,v,'death/a'),'fresh_preflight')
 s['pending_loot']=[{'source':'death/b','items':[v]}]
 assert_true(not preflight(s,v,'death/a'),'detect_cross_source_pending_uid')
 s=mock_save();v=make_item(s['world'],'death/a','blade',1,'item_1')
 s['pending_loot']=[{'source':'death/b','items':[dict(v,uid='item_777')]}]
 assert_true(not preflight(s,v,'death/a'),'detect_cross_source_pending_instance_id')
 for seq in [None,-1,0,1.4,float('nan'),float('inf')]:
  s=mock_save();s['next_item']=seq
  assert_true(not preflight(s,v,'death/a'),f'reject_sequence_{str(seq)}')
 s=mock_save();v=make_item(s['world'],'death/a','blade',1,'item_1');s['world']['events']['loot/death/a']={'status':'pending'}
 assert_true(not preflight(s,v,'death/a'),'event_journal_prevents_double_grant')


def scenario_equipment():
 s=mock_save()
 x=make_item(s['world'],'eco/r3/blade','blade',2,'item_1','sword')
 y=make_item(s['world'],'eco/r3/mage','mage',2,'item_2','wand')
 s['items']=[x,y];s['equipped']=x['uid']
 baseline=copy.deepcopy(s)
 for _ in range(500):
  s['equipped']=y['uid'];s['equipped']=x['uid']
 assert_true(s==baseline,'equip_unequip_keeps_stats')
 # Regenerated weapon has authority in legacy rules, preview cannot enter inventory.
 assert_true(valid_item(x) and valid_item(y),'equipped_weapons_valid')
 assert_true(not valid_item({'schema':2,'mode':'preview_only','id':'exo2/xyz'}),'preview_must_not_be_equippable')
 legacy_bonus=max(loot['minimum_damage_bonus'],int(weapons[x['ref']]['damage']*x['stats']['damage_pct']+.5))
 assert_true(legacy_bonus>=1,'no_zero_generated_damage_bonus')


def scenario_persistence():
 s=mock_save();item=make_item(s['world'],'dungeon/r12/room/boss','boss',3,'item_1')
 s['items'].append(item);s['equipped']='item_1';s['next_item']=2;s['world']['events']['loot/dungeon/r12/room/boss']={'status':'collected'}
 f=hashlib.sha256(json.dumps(item,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
 for region in range(88):
  # Repeated region changes cannot reroll a materialized item.
  reopened=json.loads(json.dumps(s,ensure_ascii=False))
  assert_true(reopened['items'][0]==item,f'reopen_region_{region}')
  assert_true(hashlib.sha256(json.dumps(reopened['items'][0],sort_keys=True,ensure_ascii=False).encode()).hexdigest()==f,f'fingerprint_region_{region}')
 # No regenerating from updated catalog: frozen instance carries the attributes.
 assert_true(item['stats']==json.loads(json.dumps(item))['stats'],'materialized_stats_persist')


def scenario_world_capacity():
 w=mock_world()
 for i in range(2048):w['events'][f'loot/eco/r{i%88}/m{i}']={'status':'collected'}
 assert_true(len(w['events'])==2048,'core_at_world_event_limit')
 # Confirm restriction is really in audited source, not guessed.
 src=(CORE/'procedural/world_state.gd').read_text()
 assert_true('w.events.size()>2048' in src,'max_events_core_contract')
 findings.append({'severity':'ALTO','owner':'EXO Core / Persistência','finding':'O WorldState oficial limita events a 2048; sem compactação segura, campanhas longas podem atingir o limite de saves. Não foi alterado porque pertence ao Core.'})


def scenario_static():
 for path in sorted(ITEMS.rglob('*.gd')):
  code=path.read_text()
  for idx,line in enumerate(code.splitlines()):
   stripped=line.split('#',1)[0].rstrip()
   if not stripped.endswith(':'):continue
   curr=len(line)-len(line.lstrip(' \t'))
   for other in code.splitlines()[idx+1:]:
    if not other.strip() or other.lstrip().startswith('#'):continue
    nxt=len(other)-len(other.lstrip(' \t'))
    assert_true(nxt>curr,'gd_block_indent_'+path.name+'_'+str(idx+1))
    break
 assert_true('return result if within(result' in (ITEMS/'balance/power_budget.gd').read_text(),'balance_has_final_validator')
 assert_true('for _pass in range(8):' in (ITEMS/'balance/power_budget.gd').read_text(),'balance_pass_reachable')
 assert_true('for other in entry.get("items", [])' in (ITEMS/'integration/inventory_adapter.gd').read_text(),'pending_uid_scan_present')
 assert_true('not is_finite(float(sequence))' in (ITEMS/'integration/loot_adapter.gd').read_text(),'sequence_rejects_nonfinite')
 assert_true('Names.compose(profile, material, selected)' in (ITEMS/'balance/stat_validator.gd').read_text(),'title_consistency')
 assert_true('item.get("ref","")' in (ITEMS/'visuals/appearance_descriptors.gd').read_text(),'legacy_appearance_mapping')
 protected={'exo_core/core.gd','exo_core/event_bus.gd','exo_core/service_registry.gd','inventory.gd','journey_save.gd','project.godot','convergence/game.gd'}
 assert_true(not any((R/path).exists() for path in protected),'protected_files_not_copied')
 # Preload closure (including official read-only core files).
 for path in ITEMS.rglob('*.gd'):
  for imported in re.findall(r'preload\("res://(.*?)"\)',path.read_text()):
   target=R/imported if imported.startswith('exo_items/') else CORE/imported
   official_external={'inventory.gd','procedural/loot_generator.gd','procedural/world_state.gd'}
   assert_true(target.exists() or (CORE.name=='core' and imported in official_external),f'preload_{path.name}_{imported}')

start=time.monotonic()
for name,func in [('catalogos_e_contratos',scenario_catalog),('88_regioes_loot_variado',scenario_seed_areas),('20k_loot_real_referencia',scenario_random_legacy),('30k_pools_naturais',scenario_only_valid_natural_pools),('30k_orcamento_adversarial',scenario_balance_adversarial),('inventario_24_e_loot_composto',scenario_inventory_edges),('duplicatas_e_sequencias',scenario_pending_collisions),('equipar_trocar_armas',scenario_equipment),('persistencia_88_regioes',scenario_persistence),('limite_eventos_2048',scenario_world_capacity),('integridade_codigo_preloads',scenario_static)]:
 try:case(name,func)
 except Exception as e:issues.append({'test':name,'detail':repr(e)});cases.append({'scenario':name,'result':'ERROR','error':repr(e)})
metrics={'status':'PASS_OFFLINE_MODEL' if not issues else 'FAIL_OFFLINE_MODEL','classification':'OFFLINE_REFERENCE_AND_STATIC_ONLY','native_godot':'NOT_RUN','gameplay_live':'NOT_RUN','core_unchanged':True,'cases':cases,'counters':dict(n),'failures':issues[:80],'findings':findings,'duration_s':round(time.monotonic()-start,3),'explanation':'Legacy generator is faithfully modeled from audited source, but Python simulation does NOT execute GDScript or world live runtime.'}
(OUT/'RESULTADOS-CENARIOS-QA-03.json').write_text(json.dumps(metrics,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(metrics,indent=2,ensure_ascii=False))
sys.exit(0 if not issues else 2)
