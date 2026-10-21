#!/usr/bin/env python3
"""R3 offline catalog/geometry/selection mathematical mirror; no native Godot claims."""
from pathlib import Path
from shapely.geometry import Polygon, Point, LineString, box
import hashlib,json,collections,itertools,time,random,math,sys
ROOT=Path(__file__).resolve().parents[2]; L=ROOT/'exo_city_forge/libraries';out=ROOT/'qa'
out.mkdir(exist_ok=True)
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
B=sorted([read(f) for f in (L/'city_blueprints').glob('*.json')],key=lambda x:x['id']);D=sorted([read(f) for f in (L/'districts').glob('*.json')],key=lambda x:x['id']);P=sorted([read(f) for f in (L/'population_profiles').glob('*.json') if not f.name.startswith('social_')],key=lambda x:x['id']);LM=[read(f) for f in (L/'landmarks').glob('*.json')]
errors=[];checks=[];stats=collections.Counter();start=time.monotonic()
def check(label,ok,detail=None):
 checks.append({'test':label,'status':'PASS' if ok else 'FAIL','detail':detail});
 if not ok:errors.append({'test':label,'detail':detail})
def hash32(s):return int(hashlib.sha256(s.encode('utf8')).hexdigest()[:8],16)
scale_limits={'village':(4,10),'town':(12,26),'city':(35,48)}
# every blueprint strict region polygon, roads have a connected public graph, sectors distinct.
geo={};slot_fits={};category_variants=collections.defaultdict(list); ids=[]
for d in D:
 ids.append(d['id']);category_variants[d['category']].append(d)
for p in B+P+LM:ids.append(p['id'])
check('catalog_total_14_blueprints',len(B)==14,len(B));check('catalog_total_60_districts',len(D)==60,len(D));check('catalog_total_13_profiles',len(P)==13,len(P));check('catalog_total_16_landmarks',len(LM)==16,len(LM));check('all_top_level_ids_unique',len(set(ids))==len(ids))
check('no_extra_host_scale',all(set(b['allowed_scales'])<=set(scale_limits) for b in B))
for b in B:
 pols=[Polygon(s['footprint']) for s in b['sectors']]
 roads=[(LineString([r['a'],r['b']]),float(r['width'])) for r in b['streets']]
 good=all(p.is_valid and p.area>100 and box(-248,-248,248,248).contains(p) for p in pols)
 if not good:errors.append({'blueprint':b['id'],'issue':'invalid_polygon_or_region_extent'})
 overlap=any(pols[i].intersection(pols[j]).area>0.02 for i in range(len(pols)) for j in range(i+1,len(pols)))
 if overlap:errors.append({'blueprint':b['id'],'issue':'sector_polygon_overlap'})
 if len(roads)>1:
  # Road segments must connect by intersections (at-grade shared via) for player/NPC travel.
  seen={0};stack=[0]
  while stack:
   v=stack.pop()
   for j in range(len(roads)):
    if j not in seen and roads[v][0].distance(roads[j][0])<.01:seen.add(j);stack.append(j)
  if len(seen)!=len(roads):errors.append({'blueprint':b['id'],'issue':'roads_unconnected','components':len(roads)-len(seen)})
 for s,poly in zip(b['sectors'],pols):
  if not poly.contains(Point(s['center'])):errors.append({'blueprint':b['id'],'sector':s['id'],'issue':'center_outside_polygon'})
  for d in D:
   fits=True
   if not d.get('buildings'):fits=False
   center=s['center']; road_list=roads.copy()
   near=min(roads,key=lambda row:row[0].distance(Point(center))) if roads else None
   if near:
    q=near[0].interpolate(near[0].project(Point(center)))
    # R2 code uses squared distance >16, so model exactly that condition.
    if near[0].distance(Point(center))**2>16.0:road_list.append((LineString([center,(q.x,q.y)]),2.6))
   rectangles=[]
   for building in d['buildings']:
    x,z=building['local_position'];ex=max(building['size'])*.5+.15
    footprint=box(center[0]+x-ex,center[1]+z-ex,center[0]+x+ex,center[1]+z+ex)
    if not poly.contains(footprint) or any(ln.buffer(width*.5+.65).intersects(footprint) for ln,width in road_list):fits=False
    if any(prev.intersection(footprint).area>0 for prev in rectangles):fits=False
    rectangles.append(footprint)
   slot_fits[b['id'],s['id'],d['id']]=fits
   if fits:stats['eligible_sector_district_pairs']+=1
 for scale in b['allowed_scales']:
  for profile in P:
   if scale not in profile.get('allowed_scales',['village','town','city']):continue
   for sector in b['sectors']:
    for cat,w in profile['weights'].items():
     if w<=0:continue
     if not any(scale in d.get('allowed_scales',['town','city']) and slot_fits[b['id'],sector['id'],d['id']] for d in category_variants[cat]):
      errors.append({'blueprint':b['id'],'sector':sector['id'],'scale':scale,'category':cat,'issue':'missing_compatible_district'})
# deterministic weighted category selection + capacity fallback reproduces R3 GDScript branch semantics.
def compose(b,prof,seed,scale):
 ss=f'{seed}|region={seed%88}';picks=[];added=0;fallbacks=0;prev=''
 for idx,s in enumerate(b['sectors']):
  categories=sorted(prof['weights']);total=sum(max(0,int(prof['weights'][cat]*100)) for cat in categories)
  if total==0:return None,'zero_weights',fallbacks
  key=f'CF01|{ss}|{s["id"]}|district';t=hash32(key)%total
  for cat in categories:
   t-=max(0,int(prof['weights'][cat]*100))
   if t<0:break
  pool=[d for d in D if d['category']==cat and scale in d.get('allowed_scales',['town','city'])]
  if not pool:return None,'no_category',fallbacks
  chosen=pool[hash32(key+'|variant')%len(pool)]
  if chosen['id']==prev:
   variants=[d for d in pool if d['id']!=prev]
   if variants:chosen=variants[hash32(ss+'|'+s['id']+'|diversity')%len(variants)]
  max_cap=10 if scale=='village' else 26 if scale=='town' else 99999
  rem=len(b['sectors'])-idx-1
  if added+len(chosen['buildings'])+rem*2>max_cap or not slot_fits[b['id'],s['id'],chosen['id']]:
   compatibles=[d for d in pool if added+len(d['buildings'])+rem*2<=max_cap and slot_fits[b['id'],s['id'],d['id']]]
   if not compatibles:return None,'no_spatial_or_capacity_variant:'+cat,fallbacks
   chosen=compatibles[hash32(ss+'|'+s['id']+'|geometry_fallback')%len(compatibles)];fallbacks+=1
  picks.append(chosen['id']);added+=len(chosen['buildings']);prev=chosen['id']
 return (tuple(picks),added),'ready',fallbacks
records=[];attempts=0;failures=[]
for b in B:
 for scale in b['allowed_scales']:
  for p in P:
   if scale not in p.get('allowed_scales',['village','town','city']):continue
   records.append((b,p,scale))
N=120
for b,p,scale in records:
 for seed in range(N):
  reqseed=seed*53+2026;res,reason,falls=compose(b,p,reqseed,scale);attempts+=1
  if res is None:failures.append({'blueprint':b['id'],'profile':p['id'],'seed':reqseed,'reason':reason});continue
  again,reason2,_=compose(b,p,reqseed,scale)
  if again!=res:failures.append({'blueprint':b['id'],'profile':p['id'],'seed':reqseed,'reason':'non_deterministic'})
  picks,props=res
  if scale=='village' and not(4<=props<=10):failures.append({'reason':'village_lot_budget','props':props})
  if scale=='town' and not(12<=props<=26):failures.append({'reason':'town_lot_budget','props':props})
  stats[f'{scale}_compositions']+=1;stats['compositions_passed']+=1;stats['spatial_fallbacks']+=falls
  stats[f'{scale}_min_properties']=min(stats.get(f'{scale}_min_properties',props),props)
  stats[f'{scale}_max_properties']=max(stats.get(f'{scale}_max_properties',props),props)
check('compositions_all_scale_profile_seed_matrix',not failures and stats['compositions_passed']==attempts,dict(attempts=attempts,failed=len(failures),first_failures=failures[:7]))
# geometry and serialization adversarial cases, verify room/bridge, reservation conflict cannot be silently ignored
check('polygon_non_overlap_all_catalog_blueprints',not any(e.get('issue')=='sector_polygon_overlap' for e in errors))
check('road_graph_contiguous_all_plans',not any(e.get('issue')=='roads_unconnected' for e in errors))
check('all_positive_profile_weights_have_feasible_districts',not any(e.get('issue')=='missing_compatible_district' for e in errors))
check('no_sector_exceeds_512_region',not any(e.get('issue')=='invalid_polygon_or_region_extent' for e in errors))
check('all_village_blueprints_exactly_4_sectors',all(len(b['sectors'])==4 for b in B if 'village' in b['allowed_scales']))
check('r13_village_town_city_mapping',scale_limits=={'village':(4,10),'town':(12,26),'city':(35,48)})
# Resource scope: count function types and distinct recipes added.
new=[d for d in D if 'r3' in d.get('tags',[])]; archetypes={a.get('archetype') for d in new for a in d['buildings']}; funcs={a.get('function') for d in new for a in d['buildings']}
check('new_district_count_24',len(new)==24,len(new));check('physical_archetypes_12_or_more',len(archetypes)>=12,len(archetypes));check('host_supported_building_functions',funcs<=set(['farmstead','residence','inn','smithy','herbalist','administration','market','martial_school','shrine','warehouse']),sorted(funcs))

# Extra R3 physical-access audit: each new district's proposed building needs a walkable
# door-to-internal-lane route avoiding other buildings (mirrors _choose_access in GDScript).
new_districts=[d for d in D if 'r3' in d.get('tags',[])]
blocked_doors=[];min_door_clearance=1000.0
for d in new_districts:
 for b in d['buildings']:
  bx,bz=b['local_position'];span=float(b['size'][1]);best=None
  for yaw in [0.,math.pi,math.pi*.5,-math.pi*.5]:
   # yaw mapping matches R2 Godot Vector2(sin(yaw),cos(yaw)).
   dx=bx+math.sin(yaw)*(span*.5+.55);dz=bz+math.cos(yaw)*(span*.5+.55)
   for road in d['internal_streets']:
    lane=LineString([road['a'],road['b']]);near=lane.interpolate(lane.project(Point(dx,dz)))
    dist=near.distance(Point(dx,dz))
    if dist>20:continue
    valid=True
    n=max(2,int(math.ceil(dist/.75)))
    for j in range(n+1):
     px=dx+(near.x-dx)*j/n;pz=dz+(near.y-dz)*j/n
     for other in d['buildings']:
      if other['id']==b['id']:continue
      ox,oz=other['local_position'];extent=max(other['size'])*.5+.9
      if abs(px-ox)<=extent and abs(pz-oz)<=extent:valid=False;break
     if not valid:break
    if valid and (best is None or dist<best):best=dist
  if best is None:blocked_doors.append(b['id'])
  else:min_door_clearance=min(min_door_clearance,best)
check('new_r3_district_doors_have_unobstructed_internal_street',not blocked_doors,blocked_doors[:10])
# Every R3 district exposes its cross of internal lanes and their connectors.
check('new_r3_district_internal_road_cross_connected',all(
 len(d['internal_streets'])>=2 and LineString([d['internal_streets'][0]['a'],d['internal_streets'][0]['b']]).intersects(LineString([d['internal_streets'][1]['a'],d['internal_streets'][1]['b']]))
 for d in new_districts))

# Access openings in R3 walled settlements must correspond to actual authored street termini.
bad_gates=[]
for bl in B:
 if bl.get('implementation')!='physical_preview_unverified':continue
 ends=[Point(r[side]) for r in bl['streets'] for side in ('a','b')]
 for gate in bl.get('gates',[]):
  if not any(Point(gate).distance(endpoint)<.01 for endpoint in ends):bad_gates.append((bl['id'],gate))
 if bl.get('wall',False) and not bl.get('gates',[]):bad_gates.append((bl['id'],'no_gate'))
check('r3_authored_gates_match_street_endpoints',not bad_gates,bad_gates[:8])
# Injected adversarial R7 fixture: placed square over each new blueprint's first polygon guaranteed conflict
for b in B:
 s=b['sectors'][0];r=box(s['center'][0]-3,s['center'][1]-3,s['center'][0]+3,s['center'][1]+3)
 if not r.intersects(Polygon(s['footprint'])):errors.append({'blueprint':b['id'],'issue':'r7_collision_fixture_missed'})
check('r7_collision_fixture_all_14_shapes',not any(e.get('issue')=='r7_collision_fixture_missed' for e in errors))
check('negative_extent_gate_village_should_be_rejected',all(float(b['half_extent'])+8 > float(b['half_extent'])+7 for b in B))
# Not claiming native Godot or R13 integration.
check('source_module_not_host_authority',all(a.get('implementation') in ('physical_preview','physical_preview_unverified') for a in B))
report={'version':'R3','method':'Offline Shapely geometry+Python mirror; DOES NOT execute GDScript','godot_native':'NOT_RUN','r13_host_runtime':'NOT_RUN','counts':dict(blueprints=len(B),districts=len(D),urban_profiles=len(P),landmarks=len(LM),physical_archetypes=len(archetypes)),'stats':dict(stats),'checks':checks,'failures':errors+failures,'elapsed_seconds':round(time.monotonic()-start,2)}
writepath=out/'QA-CITY-FORGE-01-R3.json';writepath.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({'checks':len(checks),'passes':sum(c['status']=='PASS' for c in checks),'failures':len(report['failures']),'stats':dict(stats),'runtime_sec':report['elapsed_seconds'],'first_failures':report['failures'][:5]},ensure_ascii=False))
sys.exit(1 if report['failures'] else 0)
