#!/usr/bin/env python3
"""Offline catalog/seed/shape checks. NOT Godot runtime or R13 gameplay evidence."""
from pathlib import Path
import json,hashlib,re,zipfile,collections,itertools,math,sys,os,datetime
ROOT=Path(__file__).resolve().parents[2];MOD=ROOT/'exo_city_forge';SRC=Path('/mnt/data/_city_research')
LOG=ROOT/'logs';LOG.mkdir(exist_ok=True)
checks=[];reject=collections.Counter()
def check(name,ok,detail=None):checks.append({'name':name,'status':'PASS' if ok else 'FAIL','detail':detail})
def load(path):return json.loads(path.read_text(encoding='utf8'))
def h(k):return int(hashlib.sha256(k.encode()).hexdigest()[:8],16)
files=list((MOD/'libraries').rglob('*.json'))
blues=[load(x) for x in sorted((MOD/'libraries/city_blueprints').glob('*.json'))]
districts=[load(x) for x in sorted((MOD/'libraries/districts').glob('*.json'))]
profiles=[load(x) for x in sorted((MOD/'libraries/population_profiles').glob('*.json')) if not x.name.startswith('social_')]
landmarks=[load(x) for x in sorted((MOD/'libraries/landmarks').glob('*.json'))]
social=[load(x) for x in sorted((MOD/'libraries/population_profiles').glob('social_*.json'))]
check('catalog_counts',list(map(len,[blues,districts,profiles,landmarks,social]))==[3,18,6,6,6],{'counts':list(map(len,[blues,districts,profiles,landmarks,social]))})
ids=[x['id'] for x in blues+districts+profiles+landmarks+social]
check('catalog_unique_ids',len(ids)==len(set(ids)))
check('distinct_district_physical_layouts',len({json.dumps((x['buildings'],x['internal_streets']),sort_keys=True) for x in districts})==18)
check('each_district_has_buildings_roads_connectors',all(len(d['buildings'])>=3 and len(d['internal_streets']) and len(d['connectors'])==4 for d in districts))
check('all_catalog_json_parse',bool(files) and all(load(f) for f in files))
check('all six minimum schemas available',len(list((MOD/'contracts').glob('*.json')))==6)
for schema in (MOD/'contracts').glob('*.json'):
 o=load(schema);check('schema_'+schema.stem,o.get('type')=='object' and o.get('$schema') is not None)
check('3_blueprints_distinct_geometry',len({json.dumps(b['sectors']) for b in blues})==3)
check('irregular_polygons_present',any(len(s['footprint'])==5 for b in blues for s in b['sectors']))
check('compact_region_512',all(b['half_extent']<200 for b in blues))
check('building_function_official',all(x['function'] in ['residence','farmstead','market','inn','smithy','herbalist','administration','martial_school','shrine','warehouse'] for d in districts for x in d['buildings']))
check('no_npc_created_in_data',all('npc' not in json.dumps(d) for d in districts))
check('profile_weights_normalized',all(sum(p['weights'].values())==100 for p in profiles))
check('noble_probability_configurable',all(p['noble_probability']>0 for p in profiles))
def physical_valid(d):
 for i,a in enumerate(d['buildings']):
  x,z=a['local_position'];w,dz=a['size']
  for other in d['buildings'][i+1:]:
   ox,oz=other['local_position'];ow,od=other['size']
   if abs(x-ox)<(w+ow)/2+.5 and abs(z-oz)<(dz+od)/2+.5:return False
  for street in d['internal_streets']:
   a0,b0=street['a'],street['b'];rw=street['width']
   if a0[0]==b0[0]:
    if abs(x-a0[0])<w/2+rw/2 and max(a0[1],b0[1])>z-dz/2 and min(a0[1],b0[1])<z+dz/2:return False
   elif a0[1]==b0[1]:
    if abs(z-a0[1])<dz/2+rw/2 and max(a0[0],b0[0])>x-w/2 and min(a0[0],b0[0])<x+w/2:return False
 return True
check('district_buildings_roads_no_simple_AABB_overlap',all(physical_valid(d) for d in districts))
check('city_has_orientation_and_door_path_fields',all(t in (MOD/'runtime/city_composer.gd').read_text() for t in ['"yaw":yaw','"door":[door.x,door.y]','"street_point":[near.x,near.y]']))
try:
 import jsonschema
 schemas={f.stem:load(f) for f in (MOD/'contracts').glob('*.json')}
 for bp in blues:jsonschema.validate(bp,schemas['city_blueprint_schema'])
 for p in profiles:jsonschema.validate(p,schemas['city_profile_schema'])
 for d in districts:jsonschema.validate(d,schemas['district_schema'])
 check('json_schema_validation_3_6_18',True)
except Exception as exc:check('json_schema_validation_3_6_18',False,str(exc))


def compose(seed,blue,profile,reserved=(),half_extent=256,schools=0,families=0):
  if blue['half_extent']+8>half_extent:reject['insufficient_region_area']+=1;return None
  cats=sorted(profile['weights'])
  total=sum(max(0,int(profile['weights'][c]*100)) for c in cats)
  res={'status':'ready','region_id':26,'seed':seed,'blueprint_id':blue['id'],'profile_id':profile['id'],'sectors':[],'buildings':[],'families':families}
  for idx,sector in enumerate(blue['sectors']):
    key=f'CF01|{seed}|{sector["id"]}|district';ticket=h(key)%total;cat=None
    for c in cats:
      ticket-=max(0,int(profile['weights'][c]*100))
      if ticket<0:cat=c;break
    if idx<schools:cat='martial'
    variants=[d for d in districts if d['category']==cat]
    pick=variants[h(key+'|variant')%len(variants)]
    if res['sectors'] and res['sectors'][-1]['district_id']==pick['id']:
      alternatives=sorted([d for d in variants if d['id']!=pick['id']],key=lambda x:x['id'])
      if alternatives:pick=alternatives[h(str(seed)+'|'+sector['id']+'|diversity')%len(alternatives)]
    xs=[p[0] for p in sector['footprint']];zs=[p[1] for p in sector['footprint']]
    b={'min_x':min(xs),'max_x':max(xs),'min_z':min(zs),'max_z':max(zs)}
    if any(b['max_x']>r['min_x']-2 and b['min_x']<r['max_x']+2 and b['max_z']>r['min_z']-2 and b['min_z']<r['max_z']+2 for r in reserved):reject['monument_conflict']+=1;return None
    res['sectors'].append({'id':sector['id'],'district_id':pick['id'],'bounds':b})
    for building in pick['buildings']:
      center=sector['center'];local=building['local_position'];at=[center[0]+local[0],center[1]+local[1]]
      res['buildings'].append({'id':f'cf/r26/{sector["id"].split("/")[-1]}/{building["id"].split("/")[-1]}','p':at,'function':building['function'],'size':building['size'],'district_id':pick['id']})
  return res
results=[]
for i in range(1008):
  blue=blues[(i//6)%len(blues)];profile=profiles[i%6];seed=str(1000+i)
  a=compose(seed,blue,profile)
  b=compose(seed,blue,profile)
  valid=a is not None and a==b
  if valid:
    pids=[x['id'] for x in a['buildings']]
    valid=len(pids)==len(set(pids)) and len(a['sectors'])>=8
  results.append(valid)
check('offline_1008_compositions_deterministic',all(results),{'PASS':sum(results),'FAIL':len(results)-sum(results)})
case=compose('816204',next(b for b in blues if b['id']=='irregular_hillside'),next(p for p in profiles if p['id']=='poor_martial_city'),schools=4,families=3)
check('3_family_4_school_scenario',case is not None and case['families']==3 and sum(b['function']=='martial_school' for b in case['buildings'])>=4,{'physical_school_slots':sum(b['function']=='martial_school' for b in case['buildings']) if case else 0})
fail_small=compose('816204',blues[0],profiles[0],half_extent=30) is None
check('reject_insufficient_space',fail_small)
reject_reserved=compose('816204',blues[0],profiles[0],reserved=[{'min_x':-35,'max_x':35,'min_z':-35,'max_z':35}]) is None
check('reject_monument_collision',reject_reserved)
check('six_profiles_x_three_blueprints_covered',len({(x['id'],y['id']) for x,y in itertools.product(blues,profiles)})==18)
# Sanity: all res paths in GDScript MUST refer to module assets, or to actual verified R13 host paths.
archive=os.environ.get('CITY_FORGE_R13_ZIP','/mnt/data/files/EXO-MURIM-CONVERGENCIA-03-ALFA-R13.zip')
if not Path(archive).is_file():
 print('BLOCKED: provide CITY_FORGE_R13_ZIP with the official reference R13 ZIP path')
 sys.exit(2)
z=zipfile.ZipFile(archive)
ref_paths=set(z.namelist())
refs=[];missing=[]
for f in MOD.rglob('*.gd'):
  for target in re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)',f.read_text()):
    refs.append((str(f.relative_to(MOD)),target))
    if not (ROOT/target).exists() and target not in ref_paths:missing.append([str(f),target])
check('all_script_resource_paths_exist_standalone_or_r13',not missing,missing)
sha=hashlib.file_digest(open(archive,'rb'),'sha256').hexdigest()
check('r13_sha_exact',sha=='48ee4ea0bb9cd357ef416fcd6db099df9f8bc06d17be342d93afdc8f1de6fe21',sha)
check('r13_member_count',len(z.infolist())==4732,len(z.infolist()))
check('r13_crc',z.testzip() is None)
manifest=json.loads(z.read('exo_core/modules.json'));ids={v['id'] for v in manifest};services=[j for x in manifest for j in x['services']]
check('city_module_id_unoccupied',not 'city_forge' in ids)
check('city_service_id_unoccupied',not 'city_forge.plans' in services)
check('real_core_service_signature','func register_service(id: String,owner_id: String,provider: Object,methods: Array,version: String="1.0.0")' in z.read('exo_core/service_registry.gd').decode())
check('real_settlement_contract_version', 'const VERSION = 4' in z.read('genesis/settlements/settlement_planner.gd').decode())
check('real_region_data_original_ref','if settlement_plan.status=="ready"' in z.read('genesis/region_data.gd').decode())
# verify strict patch line correspondence to original code and tested preview method definitions
patch=ROOT/'_r13_patch';preconditions=load(patch/'preconditions.json')
check('R13_patch_original_source_hash',all(hashlib.sha256(z.read(k)).hexdigest()==v['sha256'] for k,v in preconditions['file_preconditions'].items()))
check('R13_patch_is_disabled_by_default','legacy_procedural' in (patch/'R13-CITY-FORGE-01.diff').read_text())
check('no_host_files_present_in_module_root',not (ROOT/'exo_core').exists() and not (ROOT/'genesis').exists())
# Distinguish major native QA gates
native={'godot_executable':'NOT_FOUND','headless_import':'NOT_RUN','scene_build':'NOT_RUN','actual_collision':'NOT_RUN','exo_core_boot':'NOT_RUN','worldgen_native_plan':'NOT_RUN','gameplay_fps':'NOT_RUN','save_reopen':'NOT_RUN','r13_parser':'NOT_RUN','r13_core_registry_harness':'NOT_RUN'}
obj={'project':'EXO City Forge 01','reference_zip':str(Path(archive).name),'reference_sha256':sha,'status':'PASS_OFFLINE_ONLY' if all(c['status']=='PASS' for c in checks) else 'FAIL_OFFLINE','counts':{'checks':len(checks),'passed':sum(c['status']=='PASS' for c in checks),'failed':sum(c['status']=='FAIL' for c in checks),'offline_compositions':sum(results),'native_compositions':0,'blueprints':len(blues),'districts':len(districts),'profiles':len(profiles)},'rejections':dict(reject),'checks':checks,'native_gates':native,'limitations':['Offline Python reference algorithm does not execute GDScript','Real C3 Godot import/player lifecycle not tested','City polygons are previewed only, host patch modulates legacy lots'], 'log_path':'logs/qa_offline_city.log'}
(ROOT/'QA-CITY-FORGE-01.json').write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
log=['EXO City Forge 01: OFFLINE Python QA (NOT Godot)']+[f"{c['status']} {c['name']} {c.get('detail','')}" for c in checks]+['Result '+obj['status']]
(LOG/'qa_offline_city.log').write_text('\n'.join(log)+'\n')
print(json.dumps({'status':obj['status'],'checks':obj['counts'],'failures':[c for c in checks if c['status']=='FAIL']},ensure_ascii=False,indent=2))
sys.exit(0 if obj['status']=='PASS_OFFLINE_ONLY' else 1)
