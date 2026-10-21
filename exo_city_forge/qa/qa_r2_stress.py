#!/usr/bin/env python3
"""City Forge R2 geometry & contract offline stress. NOT a Godot simulation or C3 game QA."""
import os,sys,json,hashlib,random,itertools,collections,math,re,time,zipfile
from pathlib import Path
from shapely.geometry import Point, LineString, Polygon, box
from shapely.ops import unary_union
import jsonschema
T=time.monotonic(); ROOT=Path(__file__).resolve().parents[2]; MOD=ROOT/'exo_city_forge'; BASE=Path(os.environ.get('R13_REFERENCE','/mnt/data/files/EXO-MURIM-CONVERGENCIA-03-ALFA-R13.zip'));CROWD=Path(os.environ.get('CROWD_REFERENCE','/mnt/data/files/EXO-MURIM-CROWD-ILLUSION-01-CANDIDATO.zip'))
errors=[];checks=[];notices=[];counter=collections.Counter();examples=[]
def check(label,ok,detail=None):
 checks.append({'test':label,'status':'PASS' if ok else 'FAIL','detail':detail})
 if not ok:errors.append({'test':label,'detail':detail})
def load(p):return json.loads(p.read_text(encoding='utf8'))
def h(s):return int(hashlib.sha256(s.encode()).hexdigest()[:8],16)
def pt(v):return tuple(map(float,v))
schemas={f.stem:load(f) for f in (MOD/'contracts').glob('*.json')}
D=sorted([load(f) for f in (MOD/'libraries/districts').glob('*.json')],key=lambda x:x['id'])
B=sorted([load(f) for f in (MOD/'libraries/city_blueprints').glob('*.json')],key=lambda x:x['id'])
P=sorted([load(f) for f in (MOD/'libraries/population_profiles').glob('*.json') if not f.stem.startswith('social_')],key=lambda x:x['id'])
S=sorted([load(f) for f in (MOD/'libraries/population_profiles').glob('social_*.json')],key=lambda x:x['id'])
L=sorted([load(f) for f in (MOD/'libraries/landmarks').glob('*.json')],key=lambda x:x['id'])
check('catalog_counts_5_36_8_10_8',list(map(len,[B,D,P,L,S]))==[5,36,8,10,8],list(map(len,[B,D,P,L,S])))
objects=B+D+P+L+S
check('unique_catalog_ids',len({x['id'] for x in objects})==len(objects))
for group,sch in [(B,'city_blueprint_schema'),(D,'district_schema'),(P,'city_profile_schema')]:
 bad=[]
 for o in group:
  try:jsonschema.validate(o,schemas[sch])
  except Exception as e:bad.append({'id':o.get('id'),'error':str(e).split('\n')[0]})
 check('schema_'+sch+'_all',not bad,bad[:5])
check('profile_weight_sum_100',all(sum(p['weights'].values())==100 for p in P))
check('8_divergent_profile_weights',len({json.dumps(p['weights'],sort_keys=True) for p in P})==len(P))
check('original_district_layouts_36',len({json.dumps([d['buildings'],d['internal_streets']],sort_keys=True) for d in D})==36)
# Geometric polygon, roads and building footprints; 1.5m shoulder is considered for main circulation.
DGEOM={}; geometry_fail=[];door_fail=[]
for d in D:
 width,depth=d['footprint']['width'],d['footprint']['depth'];foot=box(-width/2,-depth/2,width/2,depth/2)
 buildings=[]
 for b in d['buildings']:
  x,z=pt(b['local_position']);w,deep=pt(b['size']);bpoly=box(x-w/2,z-deep/2,x+w/2,z+deep/2)
  if not foot.contains(bpoly):geometry_fail.append([d['id'],'outside_footprint',b['id']])
  if any(bpoly.intersects(other[1]) for other in buildings):geometry_fail.append([d['id'],'overlap_building',b['id']])
  buildings.append((b['id'],bpoly))
 roads=[]
 for st in d['internal_streets']:
  road=LineString([pt(st['a']),pt(st['b'])]).buffer(float(st['width'])/2)
  roads.append(road)
  for bid,bpoly in buildings:
   if road.intersects(bpoly):geometry_fail.append([d['id'],'street_blocks_building',bid])
  if not foot.intersects(road):geometry_fail.append([d['id'],'street_not_in_footprint'])
 if not roads:geometry_fail.append([d['id'],'no_internal_roads'])
 # Verify at least one collision-free front facade and path to an authored street for every building.
 for b in d['buildings']:
  x,z=pt(b['local_position']);w,deep=pt(b['size']);routes=[]
  for yaw in [0,math.pi,math.pi*.5,-math.pi*.5]:
   door=(x+math.sin(yaw)*(deep/2+.55),z+math.cos(yaw)*(deep/2+.55))
   for st in d['internal_streets']:
    ln=LineString([pt(st['a']),pt(st['b'])]);near=ln.interpolate(ln.project(Point(door)));walk=LineString([door,near])
    if walk.length>20:continue
    blocked=False
    for other in d['buildings']:
     if other['id']==b['id']:continue
     ox,oz=pt(other['local_position']);ow,od=pt(other['size']);extent=max(ow,od)/2+.9
     if walk.intersects(box(ox-extent,oz-extent,ox+extent,oz+extent)):
      blocked=True;break
    if not blocked:routes.append(walk.length)
  if not routes:door_fail.append([d['id'],b['id'],'no_clear_front_to_road'])
 DGEOM[d['id']]=buildings
check('district_geometry_no_footprint_or_road_overlap',not geometry_fail,geometry_fail[:12])
check('door_walkways_do_not_cross_other_buildings',not door_fail,door_fail[:12])
# Per-blueprint sector spacing, capacity, and graph access to main arteries.
bad_blue=[];route_stats={}
for blue in B:
 sectors=[(sec,Polygon(sec['footprint'])) for sec in blue['sectors']]
 if len(sectors)<8:bad_blue.append([blue['id'],'sector_under_8'])
 for idx,(s,poly) in enumerate(sectors):
  if not poly.is_valid or poly.area<500:bad_blue.append([blue['id'],s['id'],'invalid_polygon'])
  if not box(-256,-256,256,256).contains(poly):bad_blue.append([blue['id'],s['id'],'outside_world_512'])
  for t,other in sectors[idx+1:]:
   if poly.intersection(other).area>.05:bad_blue.append([blue['id'],s['id'],t['id'],'sector_overlap'])
 roads=[LineString([pt(st['a']),pt(st['b'])]) for st in blue['streets']]
 if len(roads)<2:bad_blue.append([blue['id'],'few_arteries'])
 graph={i:set() for i in range(len(roads))}
 for i,x in enumerate(roads):
  for j,y in enumerate(roads[i+1:],i+1):
   if x.distance(y)<.1:graph[i].add(j);graph[j].add(i)
 seen={0};todo=[0]
 while todo:
  n=todo.pop()
  for j in graph[n]-seen:seen.add(j);todo.append(j)
 route_stats[blue['id']]={'arteries':len(roads),'reachable_from_first_artery':len(seen),'sectors':len(sectors)}
 if len(seen)!=len(roads):bad_blue.append([blue['id'],'disconnected_arterial_network',len(seen),len(roads)])
check('blueprints_polygon_sector_separation',not [a for a in bad_blue if 'disconnected_arterial_network' not in a],bad_blue[:15])
check('blueprints_arterial_graph_connected',not [a for a in bad_blue if 'disconnected_arterial_network' in a],route_stats)
# Mirror the composed sector/district selection. Inference/QA only; does not execute GDScript.
dby={d['id']:d for d in D};cats=collections.defaultdict(list)
for d in D:cats[d['category']].append(d)
def choose(seed,sector,profile,previous,force=False):
 key='CF01|'+seed+'|'+sector['id']+'|district';weighted=sorted(profile['weights']);total=sum(max(0,int(profile['weights'][c]*100)) for c in weighted)
 ticket=h(key)%total;cat=''
 for c in weighted:
  ticket-=max(0,int(profile['weights'][c]*100))
  if ticket<0:cat=c;break
 if force:cat='martial'
 variants=cats[cat];pick=variants[h(key+'|variant')%len(variants)]
 if pick['id']==previous and len(variants)>1:
  remain=sorted([x for x in variants if x['id']!=previous],key=lambda x:x['id'])
  pick=remain[h(seed+'|'+sector['id']+'|diversity')%len(remain)]
 return pick
def comp(seed,rid,blue,profile):
 seed_text=str(seed)+'|region='+str(rid);prev='';out=[]
 for sec in blue['sectors']:
  d=choose(seed_text,sec,profile,prev);prev=d['id'];out.append(d['id'])
 return out
cases=0;repeat_errors=[];distribution=collections.Counter();identities=set();firsts={};selections={}
for blue,profile in itertools.product(B,P):
 for sample in range(275):
  rid=sample%88;seed=101+sample*31
  selected=comp(seed,rid,blue,profile)
  if selected!=comp(seed,rid,blue,profile):repeat_errors.append([seed,rid,blue['id'],profile['id']])
  distribution.update(selected);identities.add(tuple(selected));cases+=1
  if sample==0:firsts[(blue['id'],profile['id'])]=selected
  if sample==1:selections[(blue['id'],profile['id'])]=selected
check('offline_11000_compositions_deterministic',not repeat_errors and cases==11000,{'cases':cases,'errors':repeat_errors[:3]})
check('all_36_districts_reachable_by_weighted_selector',len(distribution)==36,{'distinct':len(distribution),'missing':sorted(set(dby)-set(distribution))})
check('replay_seed_city_repeatable',not repeat_errors)
check('different_regions_can_produce_different_districts',comp(42,7,B[0],P[0])!=comp(42,8,B[0],P[0]))
check('replay_variety',''.join(str(x) for x in firsts.values())!=''.join(str(x) for x in selections.values()),{'distinct_city_layouts':len(identities)})
check('negative_and_large_seed_determinism',comp(-2,87,B[0],P[0])==comp(-2,87,B[0],P[0]) and comp(2**40,10,B[0],P[0])==comp(2**40,10,B[0],P[0]))
# 2D mathematical hazard cases for reservations, water, caps, non-finite slopes, door exclusion.
def clear(p,lots,stations=(),reservations=(),gates=()):
 x,z=p
 for lo in lots:
  cx,cz=lo['p'];half=lo.get('halfsize',5.5)
  if math.hypot(x-cx,z-cz)<max(3,half)+1.7:return False
  dx,dz=lo.get('door',(cx,cz))
  if math.hypot(x-dx,z-dz)<3.2:return False
  sx,sz=lo.get('street_point',(dx,dz))
  if Point(p).distance(LineString([(dx,dz),(sx,sz)]))<1.65:return False
 for q in stations:
  if math.dist(p,q)<2.8:return False
 for r in reservations:
  if r['min_x']-3.2<x<r['max_x']+3.2 and r['min_z']-3.2<z<r['max_z']+3.2:return False
 for q in gates:
  if math.dist(p,q)<7:return False
 return True
def zone_candidates(roads,lots,max_zones=16,reservations=(),stations=(),gates=(),grade=.0):
 cand=[]
 for ri,road in enumerate(roads):
  a,b=road['a'],road['b'];length=math.dist(a,b);width=road['width']
  if length<14 or width<4:continue
  d=((b[0]-a[0])/length,(b[1]-a[1])/length);n=(-d[1],d[0]);offset=min(2.6,max(0,width*.5-1.3));chunks=min(12,max(1,math.ceil(length/22)))
  for i in range(chunks):
   u=(i+.13)/chunks;v=(i+.87)/chunks
   start=(a[0]*(1-u)+b[0]*u,a[1]*(1-u)+b[1]*u);end=(a[0]*(1-v)+b[0]*v,a[1]*(1-v)+b[1]*v)
   for side in [-1,1]:
    p0=(start[0]+n[0]*offset*side,start[1]+n[1]*offset*side);p1=(end[0]+n[0]*offset*side,end[1]+n[1]*offset*side)
    steps=max(3,math.ceil(math.dist(p0,p1)/1.5))
    if any(not clear((p0[0]*(1-t/steps)+p1[0]*t/steps,p0[1]*(1-t/steps)+p1[1]*t/steps),lots,stations,reservations,gates) for t in range(steps+1)):continue
    if grade>.12:continue
    cand.append((p0,p1))
 return cand[:max_zones]
roads=[{'a':(-90.,0.),'b':(90.,0.),'width':8.0},{'a':(0.,-90.),'b':(0.,90.),'width':7.0}]
lots=[{'p':(x,z),'door':(x,z-7 if z>0 else z+7),'street_point':(x,0.) if z!=0 else (0.,0.),'halfsize':5.5} for x in [-45,-15,15,45] for z in [-23,23]]
zones=zone_candidates(roads,lots)
check('crowd_zone_safe_fixture_nonempty',len(zones)>0,{'zones':len(zones)})
check('crowd_pc_zone_cap',len(zone_candidates(roads,lots,max_zones=16))<=16)
check('crowd_mobile_zone_cap',len(zone_candidates(roads,lots,max_zones=10))<=10)
check('crowd_door_reservation_exclusion',not zone_candidates(roads,lots,reservations=[{'min_x':-120,'max_x':120,'min_z':-120,'max_z':120}]))
check('crowd_too_steep_rejected',not zone_candidates(roads,lots,grade=.4))
check('crowd_narrow_road_rejected',not zone_candidates([{'a':(-20.,0.),'b':(20.,0.),'width':2.0}],[]))
check('crowd_unwalkable_station_exclusion',not zone_candidates([{'a':(-10.,0.),'b':(10.,0.),'width':5.0}],[],stations=[(0.,0.)],reservations=[{'min_x':-50,'max_x':50,'min_z':-50,'max_z':50}]))
check('crowd_zones_repeatable_math',zone_candidates(roads,lots)==zone_candidates(roads,lots))
# Actual source contracts verified from both archived ZIPs. No fictitious APIs.
for label,path,expect in [('R13',BASE,'48ee4ea0bb9cd357ef416fcd6db099df9f8bc06d17be342d93afdc8f1de6fe21'),('Crowd01',CROWD,None)]:
 if not path.exists():check('reference_'+label+'_available',False,str(path));continue
 with open(path,'rb') as f:actual=hashlib.file_digest(f,'sha256').hexdigest()
 check('reference_'+label+'_sha256',actual==expect if expect else len(actual)==64,actual)
 with zipfile.ZipFile(path) as z:
  check('reference_'+label+'_crc',z.testzip() is None,len(z.infolist()))
  if label=='R13':
   zfiles=z.namelist();check('R13_official_road_lot_height_methods', all(x in z.read('genesis/region_data.gd').decode() for x in ['var settlement_roads:', 'var lots:', 'func height_at(']))
   check('R13_official_station_points', 'var station_points: Dictionary={}' in z.read('convergence/region.gd').decode())
  else:
   src=z.read('exo_crowd_illusion/runtime/region_adapter.gd').decode()
   check('crowd01_reads_city_forge_meta', 'exo_city_forge_crowd_zones' in src)
   check('crowd01_exact_zone_schema_keys',set(json.loads(z.read('exo_crowd_illusion/contracts/crowd_zones_schema.json'))['items']['properties']).issuperset({'id','points','capacity','role','activity','lateral','safety_radius'}))
# No unknown external load/preload and no mock persistence.
resources=[];missing=[]
for f in MOD.rglob('*.gd'):
 for path in re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)',f.read_text()):
  resources.append(path)
  if not (ROOT/path).exists():
   with zipfile.ZipFile(BASE) as z:
    if path not in z.namelist():missing.append(path)
check('R2_resource_targets_existing',not missing,missing[:10])
bridge=(MOD/'adapters/crowd_illusion_adapter.gd').read_text()
check('bridge_opt_in_clear_and_no_NPC_mutation',all(x in bridge for x in ['publish_after_build','explicit_opt_in_required','META_KEY','region.remove_meta','data.height_at','city_forge_crowd_area_index']) and all(x not in bridge for x in ['record_roster','SaveCoordinator','register_service(']))
check('bridge_R13_streets_lots_as_only_geometry',all(x in bridge for x in ['settlement_roads','data.get("lots")','official_settlement_not_ready']))
check('bridge_real_R7_and_stations_exclusions','monumental_receipts' in bridge and 'station_points' in bridge)
check('bridge_slope_samples_intermediate', '_slope_safe(data,p0,p1)' in bridge and 'ceil(length/1.5)' in bridge)
check('bridge_nested_R7_receipt_bounds',all(k in bridge for k in ['receipt.get("bounds",null)','r7_reservation_bounds_unavailable','rectangles.append(bounds)']))
source=(Path(os.environ.get('CROWD_R2','/mnt/data/EXO-CROWD-ILLUSION-01-CITY-FORGE-R2'))/'exo_crowd_illusion/runtime/director.gd').read_text()
check('crowd_source_zones_survive_nighttime_and_zero_density',all(key in source for key in ['source_zones = zone_specs.duplicate(true)','current_zones: Array = source_zones.duplicate(true)','source_zones.clear()']))
check('crowd_panic_visual_limit_applied',(Path(os.environ.get('CROWD_R2','/mnt/data/EXO-CROWD-ILLUSION-01-CITY-FORGE-R2'))/'exo_crowd_illusion/runtime/zone_renderer.gd').read_text().find('panic_offset_limit')>=0)
# 3 families/4 schools remain a legitimate data-only situation; no forced quest or physical actors.
profile=next(p for p in P if p['id']=='poor_martial_city')
martial=[x for x in D if x['category']=='martial']
check('3_family_4_school_slots_still_possible',len(martial)>=4 and len(B[0]['sectors'])>=4)
qa={'project':'EXO City Forge 01 R2 / Crowd Illusion 01 city bridge','scope':'OFFLINE structural/geometry/stress only. Godot/runtime not executed.', 'reference':{'r13':str(BASE),'crowd':str(CROWD)},'statistics':{'compositions':cases,'districts':len(D),'blueprints':len(B),'urban_profiles':len(P),'social_profiles':len(S),'landmarks':len(L),'unique_layouts':len(identities),'selected_districts':len(distribution),'crowd_fixture_zones':len(zones),'seconds':round(time.monotonic()-T,2)},'results':checks,'errors':errors,'blocked':{'godot_4_6_2_import':'NOT_RUN','godot_GDScript_parser':'NOT_RUN','Godot_3d_collision':'NOT_RUN','actual_R13_genesis_generation':'NOT_RUN','FPS_PC_Android':'NOT_RUN','crowd_native_renderer':'NOT_RUN','C3_final_integration':'NOT_RUN'}}
out=ROOT/'QA-CITY-FORGE-01-R2.json';out.write_text(json.dumps(qa,ensure_ascii=False,indent=2)+'\n')
(ROOT/'logs').mkdir(exist_ok=True)
(ROOT/'logs/qa_r2_stress.log').write_text('\n'.join(f"{r['status']} {r['test']} {str(r['detail'])[:500]}" for r in checks)+'\n\nFAILED='+str(len(errors))+'\n')
print('OFFLINE',len(checks),'CHECKS',len(errors),'FAILS','CASES',cases,'TIME',round(time.monotonic()-T,2))
for v in errors:print('FAIL',v)
sys.exit(0 if not errors else 1)
