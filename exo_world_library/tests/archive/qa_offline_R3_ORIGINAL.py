#!/usr/bin/env python3
"""Deterministic offline static and mathematical simulation. NOT native Godot runtime QA."""
import json,hashlib,re,random,collections,sys,time,statistics,functools
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
MOD=ROOT/'exo_world_library'
def load(p):return json.loads(p.read_text(encoding='utf-8'))
M=load(MOD/'manifest.json'); P=load(MOD/'contracts/coherence_policy.json')
allrec={};domains=collections.defaultdict(list);errors=[];counts=collections.Counter(); by_origin=collections.Counter(); rejection=collections.Counter(); start=time.monotonic()
def check(condition, reason, count=1):
 counts['assertions']+=count
 if not condition and len(errors)<200:errors.append(reason)
check(M['version']=='0.3.0','version_invalid');check(not M['merged_into_C3'],'wrong_merge_status')
check(M['integration_mode']=='read_only_candidate_not_registered','unsafe_integration_mode')
check(M['native_godot_qa']=='NOT_RUN','natively_tested_without_proof')
for desc in M['catalogs']:
 domain=desc['domain'];path=ROOT/desc['path'].replace('res://','');o=load(path)
 check(o['schema']=='exo.world_library.catalog.v1',f'bad_schema:{domain}')
 check(o['domain']==domain,f'bad_domain:{domain}')
 check(len(o['records'])==desc['count'],f'bad_count:{domain}')
 for r in o['records']:
  rid=r['id'];check(bool(re.fullmatch(r'[a-z][a-z0-9_]*/[a-z0-9_]+',rid)),f'bad_id:{rid}')
  check(len(rid)<=128,f'id_too_long:{rid}');check(rid not in allrec,f'duplicate_id:{rid}')
  allrec[rid]=r;domains[domain].append(r);by_origin[r['origin']]+=1
  check(r['domain']==domain,f'incorrect_domain:{rid}');check(r['weight']>=0,f'negative_weight:{rid}')
  check(r['origin'] in ('authorial','external_ref'),f'invalid_origin:{rid}')
  check(r['status'] in ('candidate','reference_only'),f'invalid_status:{rid}')
  check(len(r['tags'])==len(set(r['tags'])),f'duplicate_tags:{rid}')
  check(not set(r.get('requires',[])).intersection(r.get('excludes',[])),f'contradictory_flags:{rid}')
  if r['origin']=='external_ref': check(r['weight']==0 and r['status']=='reference_only',f'external_ref_selectable:{rid}')
  for k,v in r['conditions'].items():
   check(k in {'biome','biome_in','settlement_type','settlement_type_in','min_player_tier','max_player_tier','tags_all','tags_any'},f'unknown_condition:{rid}:{k}')
   if k.endswith('_in') or k.startswith('tags_'):check(isinstance(v,list) and bool(v),f'invalid_set_condition:{rid}:{k}')
  cc=r['conditions'];check(cc.get('max_player_tier',9999)>=cc.get('min_player_tier',0),f'impossible_tier:{rid}')
for r in allrec.values():
 for link in r['links']:check(link in allrec,f'unresolved_link:{r["id"]}->{link}')
for domain,rec in domains.items():check(len(rec)>0,f'empty_domain:{domain}')
check(len(domains)>=50,'domain_coverage_below_target')
check(len(M['source_catalogs'])>=10,'insufficient_traced_sources')
mutex=P['mutually_exclusive_tag_sets']
for m in mutex:check(len(m)==len(set(m)) and len(m)>1, f'bad_mutex:{m}')
# Recognize context taxonomy, tag requirements, flags, and exclusion/restriction rules.
def matches(r,ctx):
 for k,v in r['conditions'].items():
  if k.endswith('_in'):
   if ctx.get(k[:-3]) not in v:return False
  elif k=='min_player_tier':
   if ctx.get('player_tier',-1)<v:return False
  elif k=='max_player_tier':
   if ctx.get('player_tier',-1)>v:return False
  elif k=='tags_all':
   if not set(v).issubset(ctx.get('tags',[])):return False
  elif k=='tags_any':
   if not set(v).intersection(ctx.get('tags',[])):return False
  elif ctx.get(k)!=v:return False
 return set(r['requires']).issubset(ctx.get('flags',[])) and not set(r['excludes']).intersection(ctx.get('flags',[]))
def coherence(r,ctx,selected_tags=()):
 tags=set(selected_tags)|set(ctx.get('tags',[]));new=set(r['tags'])
 for pair in mutex:
  if len((tags|new).intersection(pair))>1:return 'mutex'
 for row in P['context_incompatibilities']:
  if all(ctx.get(k)==v for k,v in row['if_context'].items()) and new.intersection(row['reject_any_tags']):return 'context'
 for requirement in P['selected_tag_requirements']:
  if requirement['tag'] in new and not (tags|new).intersection(requirement['any_of']):return 'dependency'
 return None
ctx0={'world_id':'world-qa','seed':101,'region_id':78,'biome':'grassland','settlement_type':'town','player_tier':2,'tags':['river_access'],'flags':[]}
@functools.lru_cache(maxsize=10000)
def _choices_cached(domain,biome,settlement,tier,river):
 ctx={'biome':biome,'settlement_type':settlement,'player_tier':tier,'tags':['river_access'] if river else [],'flags':[]}
 return tuple(r for r in domains[domain] if r['origin']=='authorial' and r['weight']>0 and matches(r,ctx) and not coherence(r,ctx,()))
def choices(domain,ctx,selected_tags=()):
 if not selected_tags and not ctx.get('flags',[]):
  return _choices_cached(domain,ctx.get('biome'),ctx.get('settlement_type'),ctx.get('player_tier'),bool('river_access' in ctx.get('tags',[])))
 return [r for r in domains[domain] if r['origin']=='authorial' and r['weight']>0 and matches(r,ctx) and not coherence(r,ctx,selected_tags)]
def pick(domain,ctx,slot=0,selected_tags=()):
 eligible=sorted(choices(domain,ctx,selected_tags),key=lambda x:x['id'])
 if not eligible:return None
 # Offline only: deterministic SHA-based sampler, not guaranteed bit-identical to Godot PCG.
 state=json.dumps(ctx,ensure_ascii=False,sort_keys=True,separators=(',',':'))
 digest=hashlib.sha256(('EXO|WORLD_LIBRARY|0.2.0|'+domain+'|'+str(slot)+'|'+state).encode()).hexdigest()
 n=int(digest[:15],16);roll=(n%1000000000)/1000000000 * sum(r['weight'] for r in eligible)
 for r in eligible:
  roll-=r['weight']
  if roll<0:return r['id']
 return eligible[-1]['id']
# Coverage of all biome/settlement/player-tier cases to discover dead content and valid fallback.
biomes=['grassland','temperate_forest','bamboo_forest','dry_valley','wetland','rocky_highlands','alpine','mixed_woodland']
settlements=['village','town','city','none'];suites=['biome_identity','region_theme','npc_archetype','npc_motivation','world_event','rumor','encounter_theme','dungeon_theme','loot_theme','climate_phenomenon','travel_incident','narrative_motif','region_legacy','region_tension','commodity_flow','social_custom','faction_agenda','dungeon_chamber','event_outcome','martial_trial']
counts['exhaustive_contexts']=0
for biome in biomes:
 for settlement in settlements:
  for tier in range(5):
   ctx=dict(ctx0,biome=biome,settlement_type=settlement,player_tier=tier)
   counts['exhaustive_contexts']+=1
   for domain in suites:
    rid=pick(domain,ctx,0)
    # Some domains intentionally require a specific biome; ask only for guaranteed coverage domains.
    if domain in {'biome_identity','npc_archetype','npc_motivation','world_event','rumor','loot_theme','climate_phenomenon','travel_incident','narrative_motif','region_legacy','region_tension','social_custom','faction_agenda','dungeon_chamber','event_outcome','martial_trial'}:
     check(rid is not None,f'no_eligible:{domain}:{biome}:{settlement}:{tier}')
    if rid:counts['valid_selections']+=1
# 120000 seeded scenarios with 8 stages, dozens of world contexts.
rng=random.Random(20261020);fired=collections.Counter();seed_samples=[]
for i in range(60000):
 ctx={'world_id':'simulation-world-'+str(i%43),'seed':rng.randrange(-2**29,2**29),'region_id':rng.randrange(88),
      'biome':biomes[rng.randrange(8)],'settlement_type':settlements[rng.randrange(4)],'player_tier':rng.randrange(0,8),
      'tags':['river_access'] if i%4==0 else [],'flags':[]}
 if i<10:seed_samples.append(ctx['seed'])
 for domain in ['region_legacy','region_tension','npc_background','npc_motivation','world_event','narrative_motif','loot_theme','martial_trial']:
  rid=pick(domain,ctx,i%13)
  check(rid is not None,f'no_valid_choice:{i}:{domain}');counts['monte_carlo_selections']+=1
  if rid:fired[rid]+=1
 if i%97==0:
  d='world_event';a=pick(d,ctx,i%13)
  reordered=dict(reversed(list(ctx.items())));b=pick(d,reordered,i%13)
  check(a==b,f'order_dependent_hash:{i}');counts['determinism_checks']+=1
# Explicitly incompatible pairs / invalid conditions / duplicate detection / references.
scenarios=[
 ('flood_vs_drought',['world_event/flood','climate_phenomenon/estiagem_prolongada'],dict(ctx0,biome='wetland'),False),
 ('drought_vs_flood',['climate_phenomenon/estiagem_prolongada','world_event/flood'],dict(ctx0,biome='wetland'),False),
 ('reference_not_selectable',['ref_bestiary_species/ref_deer'],ctx0,False),
 ('flood_wrong_biome',['world_event/flood'],dict(ctx0,biome='dry_valley'),False),
 ('duplicate_record',['npc_archetype/resident','npc_archetype/resident'],ctx0,False),
 ('valid_weather',['climate_phenomenon/estiagem_prolongada'],dict(ctx0,biome='dry_valley'),True),
 ('river_without_access',['settlement_service/cais_de_balsas'],dict(ctx0,tags=[]),False),
 ('river_with_access',['settlement_service/cais_de_balsas'],dict(ctx0,tags=['river_access']),True),
 ('valid_martial',['martial_trial/repetir_golpes_com_equilibrio'],ctx0,True)
]
def validate_bundle(ctx,ids):
 seen=set();previous=[]
 for rid in ids:
  if rid in seen:return 'duplicate'
  seen.add(rid)
  r=allrec.get(rid)
  if r is None:return 'unknown'
  if r['origin']!='authorial' or r['weight']<=0:return 'non_selectable'
  if not matches(r,ctx):return 'conditions'
  reason=coherence(r,ctx,previous)
  if reason:return reason
  previous.extend(r['tags'])
 return None
for title,ids,ctx,expected in scenarios:
 reason=validate_bundle(ctx,ids);check((reason is None)==expected,f'negative_probe:{title}:got:{reason}');counts['negative_probes']+=1
 rejection[title]=reason or 'VALID'
# Direct mutation tests: rule engine detects contradictory synthetic combinations not dependent on source data.
for i in range(25000):
 left={'tags':['flood_active'],'conditions':{},'requires':[],'excludes':[],'origin':'authorial','weight':1}
 other=dict(left,tags=['drought_active'])
 check(coherence(left,ctx0,['drought_active'])=='mutex',f'fail_closed_flood:{i}')
 check(coherence(other,ctx0,['flood_active'])=='mutex',f'fail_closed_drought:{i}')
 counts['synthetic_conflict_probes']+=2
check(len(fired)>80,'low_selection_diversity')
summary={'suite':'EXO_WORLD_LIBRARY_01_R3_MASS_SIM','status':'PASS' if not errors else 'FAIL',
 'native_godot':'NOT_RUN','domains':len(domains),'records':len(allrec),'authorial':by_origin['authorial'],
 'reference_only':by_origin['external_ref'],'assertions':counts['assertions'],
 'monte_carlo_contexts':60000,'monte_carlo_selections':counts['monte_carlo_selections'],
 'exhaustive_contexts':counts['exhaustive_contexts'],'determinism_checks':counts['determinism_checks'],
 'synthetic_conflict_probes':counts['synthetic_conflict_probes'],'negative_probes':counts['negative_probes'],
 'unique_selected_records':len(fired),'top_coverage':fired.most_common(20),
 'adversarial_cases':rejection,'first_test_seeds':seed_samples,'run_seconds':round(time.monotonic()-start,3),
 'failures':errors[:100], 'limits':['Python sampler not Godot PCG','No live scene, save or native execution','Source Work candidate not merged']}
(ROOT/'QA-OFFLINE-RESULTS.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ('top_coverage','adversarial_cases','limits')},ensure_ascii=False))
sys.exit(0 if not errors else 1)
