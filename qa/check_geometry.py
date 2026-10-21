#!/usr/bin/env python3
"""G1/G2 offline: AABB orientado, reservas e porta, variantes/profiles, GLBs reais.
Spec independente reconstitui a montagem declarada em detail_pass.gd e modular_kit.gd.
Nao prova runtime de Godot, nem navegacao por NavMesh; exige QA engine + screenshot.
"""
import json,math,sys,collections
from pathlib import Path
import numpy as np
import trimesh
ROOT=Path(__file__).resolve().parents[1]
assets=json.loads((ROOT/'catalog.json').read_text())['assets']
cat={item['id']:item for item in assets}
fail=[];checks=0;examples=[];cases=0;tested_files=0

def ok(cond,label):
 global checks
 checks+=1
 if not cond:fail.append(label)

def rot_bounds(name,loc,yaw=0.0):
 bounds=cat[name]['bounds']; c=math.cos(yaw);s=math.sin(yaw)
 xyz=[]
 for x in bounds[0][0],bounds[1][0]:
  for y in bounds[0][1],bounds[1][1]:
   for z in bounds[0][2],bounds[1][2]:xyz.append((loc[0]+x*c+z*s,loc[1]+y,loc[2]-x*s+z*c))
 return np.min(xyz,axis=0),np.max(xyz,axis=0)

def placed_parts(width,stories,arch,profile):
 parts=[]
 def add(id,x,y,z,r=0):parts.append((id,(x,y,z),r))
 xs=[-width/2+1+i*2 for i in range(width//2)]
 doorx=xs[len(xs)//2]
 # Original approved physical kit: build_house(), 4/6/8 widths, two layers.
 for x in xs:
  for z in [-1,1]:
   add('foundation_2x2',x,0,z)
   if stories==2:add('floor_wood_2x2',x,3,z)
 for level in range(stories):
  y=.4+level*2.6
  for i,x in enumerate(xs):
   has_door=level==0 and i==len(xs)//2
   add('wall_door_2m' if has_door else 'wall_window_2m',x,y,2)
   if has_door:add('door_double',x,y,2.01)
   add('wall_solid_2m',x,y,-2,math.pi)
  for side in [-1,1]:
   for z in [-1,1]:add('wall_window_2m',side*width/2,y,z,side*math.pi/2)
 if stories==2:add('balcony_2m',width/2,3,0,math.pi/2)
 top=.4+stories*2.6
 for x in xs:
  for yaw in [0,math.pi]:add('roof_slope_2x2',x,top,0,yaw)
  add('roof_eave_2m',x,top,2)
  add('roof_eave_2m',x,top,-2,math.pi)
  add('roof_ridge_2m',x,top+1,0)
 for side in [-1,1]:
  add('roof_gable_4m',side*width/2,top,0)
  for z in [-2.35,2.35]:add('roof_end_ornament',side*width/2,top-.1,z,0 if side>0 else math.pi)
  add('roof_end_ornament',side*width/2,top+1.15,0,0 if side>0 else math.pi)
 add('stairs_2m',doorx,0,2)
 for x in [doorx-.85,doorx+.85]:add('lantern_01',x,2.15,2.2)
 left=-width/2+1
 obstacles=[]
 def solid(x,z,sx,sz,label):obstacles.append((x,z,sx,sz,label))
 if arch=='standard':add('bamboo_planter_box',left,0,3.75)
 if arch=='veranda':
  add('public_timber_bench',left,0,3.65)
  solid(left,3.65,1.62,.43,'veranda_bench')
  for side in [-1,1]:add('veranda_bamboo_railing_2m',side*(width/2+.85),0,3.3,math.pi/2)
 if arch=='merchant':
  add('market_cloth_awning_2m',left,2.55,2.35)
  add('merchant_counter_2m',left,0,3.45)
  solid(left,3.45,1.98,.75,'merchant_counter')
  add('shop_hanging_sign',left,2.47,2.6)
 if arch=='teahouse':
  add('market_cloth_awning_2m',left,2.55,2.35)
  add('tea_table_with_stools',left,0,3.8)
  solid(left,3.8,1.97,1,'tea_table')
  add('shop_hanging_sign',left,2.57,2.65)
 if arch=='forge':
  add('blacksmith_forge_hearth',left,0,3.70)
  solid(left,3.7,1.60,1.12,'forge_hearth')
  add('blacksmith_anvil',left,0,2.70)
  solid(left,2.7,1.16,.60,'anvil')
 if arch=='herb_shop':
  add('facade_lattice_2m',left,.4,2.17)
  add('herb_drying_rack',left,0,3.18)
  add('herbalist_medicine_jars',left,0,4.10)
  add('shop_hanging_sign',left,2.55,2.58)
 if arch=='inn':
  add('facade_lattice_2m',left,3.0,2.17)
  add('silk_vertical_banner',left,2.25,2.52)
  add('shop_hanging_sign',left,3.08,2.57)
  add('public_timber_bench',left,0,3.70)
  solid(left,3.7,1.62,.43,'inn_bench')
 if arch=='courtyard':
  add('courtyard_entry_gate',doorx,0,6.2)
  for side in [-1,1]:
   solid(doorx+side*1.25,6.2,.26,.32,'gate_post')
   add('courtyard_wall_2m',doorx+side*2.45,0,6.2)
   solid(doorx+side*2.45,6.2,2.0,.4,'front_wall')
   add('courtyard_wall_2m',side*3.45,0,4.95,math.pi/2)
   solid(side*3.45,4.95,.4,2.0,'side_wall')
  for z in [3.8,5.6]:add('stone_courtyard_paving_2m',doorx,0,z)
  add('bamboo_planter_box',-2.05,0,4.5)
 if profile!='low':
  if arch!='courtyard':
   for x in xs:add('roof_tile_eave_2m',x,top,2.48)
  if arch in ['merchant','herb_shop','inn']:add('woven_market_baskets',left,0,4.28)
  elif arch=='teahouse':add('silk_vertical_banner',width/2+.6,2.2,2.5)
  elif arch=='forge':add('smith_tool_rack',left,1.2,2.22)
  elif arch=='courtyard':
   add('stone_garden_lantern',2.22,0,4.8)
   solid(2.22,4.8,.85,.85,'stone_lantern')
  elif arch=='veranda':add('silk_vertical_banner',left,2.2,2.45)
  else:add('facade_lattice_2m',left,.4,2.17)
 if profile=='high':
  for side in [-1,1]:add('roof_ridge_finial',side*(width/2+.06),top+1.1,0)
  if arch in ['merchant','herb_shop','inn']:add('grain_sack_stack',-width/2-.6,0,4.2)
  elif arch=='teahouse':add('tea_ceramic_shelf',left,0,2.40)
  elif arch=='forge' and width>=6:
   add('village_grain_millstone',width/2-1,0,3.70)
   solid(width/2-1,3.7,1.3,1.3,'millstone')
  elif arch=='courtyard':add('bronze_incense_burner',-2.05,0,5.65)
  elif arch=='standard':
   add('stone_garden_lantern',-width/2-.8,0,4.05) # alternative basket variation occupies same side space
 return parts,obstacles,doorx

for item in assets:
 path=ROOT/item['file']
 s=trimesh.load(path,force='scene')
 tested_files+=1
 b=s.bounds
 ok(b is not None and np.isfinite(b).all(),'finite_geometry_'+item['id'])
 if b is not None:
  expected=np.asarray(item['bounds'],dtype=float)
  ok(np.allclose(b,expected,atol=0.0006),'catalog_bounds_'+item['id'])
  ok(len(s.geometry)>0 and all(len(x.faces)>0 for x in s.geometry.values()),'nonempty_mesh_'+item['id'])
  if item['family']=='forja_v2':
   ok(sum(len(x.faces) for x in s.geometry.values()) < 2000,'low_poly_new_'+item['id'])

for width in [4,6,8]:
 for stories in [1,2]:
  for arch in ['standard','veranda','merchant','teahouse','forge','herb_shop','inn','courtyard']:
   if arch=='courtyard' and width!=6:continue
   if arch=='inn' and (width==4 or stories==1):continue
   for profile in ['low','medium','high']:
    parts,obstacles,doorx=placed_parts(width,stories,arch,profile)
    xmin=-width/2-1.35;xmax=width/2+1.35;zmin=-2.65
    zmax=6.95 if arch=='courtyard' else 4.95
    # Base + decorations; validate meshes oriented in scene against reserved plot
    bounds=[rot_bounds(*v) for v in parts]
    mn=np.min([b[0] for b in bounds],axis=0);mx=np.max([b[1] for b in bounds],axis=0)
    ok(mn[0]>=xmin-1e-3 and mx[0]<=xmax+1e-3 and mn[2]>=zmin-1e-3 and mx[2]<=zmax+1e-3,
       f'envelope_{width}_{stories}_{arch}_{profile}_{mn.tolist()}_{mx.tolist()}')
    # Approach from actual door to roadside stays horizontally clear of SOLID decor.
    for sx,sz,sw,sd,label in obstacles:
     # Need not check solids placed behind front door (y above); solids only ground obstacles in set.
     touching=(sx+sw/2>doorx-.95+1e-4 and sx-sw/2<doorx+.95-1e-4 and sz+sd/2>3.05 and sz-sd/2<(9.2 if arch=='courtyard' else 5.35))
     ok(not touching,f'entry_blocked_{width}_{stories}_{arch}_{profile}_{label}')
    # For every valid width courtyard, gate post is on either side of 1.9m approach corridor.
    if arch=='courtyard':ok(abs(doorx)<1e-6 and zmax>=6.90,f'courtyard_entry_{width}')
    cases+=1
    if width==6 and stories==2 and profile=='high':examples.append({'archetype':arch,'footprint':[round(float(mn[0]),2),round(float(mn[2]),2),round(float(mx[0]),2),round(float(mx[2]),2)],'reserved':[xmin,zmin,xmax,zmax],'parts':len(parts)})

report={'kind':'forja_02_geometry_and_walkway_offline','passed':checks-len(fail),'failed':len(fail),'failures':fail[:100],'total_failures':len(fail),'glbs_parsed':tested_files,'geometric_combinations':cases,'profiles':3,'details':examples,'engine_navigation_tested':False}
(ROOT/'qa/geometry_results_v2.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({'passed':report['passed'],'failed':report['failed'],'glbs_parsed':tested_files,'geometric_combinations':cases,'failures':report['failures'][:14]},indent=2,ensure_ascii=False))
sys.exit(bool(fail))
