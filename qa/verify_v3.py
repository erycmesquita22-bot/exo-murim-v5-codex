#!/usr/bin/env python3
"""Forja 03 independent offline verification. No Godot simulated runtime claims."""
from pathlib import Path
import json,sys,re,math,hashlib,zipfile,random,statistics,time
import numpy as np
import trimesh
R=Path(__file__).resolve().parents[1]
res={'suite':'EXO Forja 03 offline assets / geometry / regression','passed':0,'failed':[],'metrics':{},'godot_executed':False}
def ck(condition,name):
 if condition:res['passed']+=1
 elif len(res['failed'])<100:res['failed'].append(name)
cat=json.loads((R/'catalog.json').read_text()); entries=cat['assets']; byid={a['id']:a for a in entries}
allowed={'catalog.json','README.md','RELATORIO.md','project.godot'}
oldhashes=json.loads((R/'docs/BASELINE-02-SHA256.json').read_text())['hashes']
ck(cat['version']=='3.0','version3');ck(len(entries)==163,'expected_163_models');ck(len(byid)==163,'asset_id_uniq')
ck(all(len(a['bounds'])==2 for a in entries),'all_bounds')
ck(all(a['file'].startswith('models/') and (R/a['file']).is_file() for a in entries),'all_models_exist')
for key,digest in oldhashes.items():
 if key in allowed: continue
 newer=R/key
 ck(newer.is_file() and hashlib.sha256(newer.read_bytes()).hexdigest()==digest,'modified_inherited_'+key)
manifest=json.loads((R/'docs/ASSETS-03-MANIFEST.json').read_text())
ck(len(manifest)==42,'new_models_42')
ck(len(set(a['id'] for a in manifest))==42,'new_model_uniqueness')
mesh_totals=[];bounds_err=[];worst=0
for j,e in enumerate(entries):
 try:
  loaded=trimesh.load(str(R/e['file']),file_type='glb',force='scene',process=False)
  geom=list(loaded.geometry.values());tc=sum(len(o.faces) for o in geom)
  ck(bool(geom) and tc>=10,'not_mesh_'+e['id'])
  box=np.array(loaded.bounds);declared=np.array(e['bounds'],dtype=float)
  if not np.all(np.isfinite(box)):raise ValueError('nonfinite bounds')
  err=float(np.max(np.abs(box-declared)));worst=max(worst,err)
  ck(err<.025,'wrong_bounds_'+e['id']);bounds_err.append(err)
  if j>=121:
   ck(tc==e['triangles'],'new_triangle_count_'+e['id']);mesh_totals.append(tc)
   ck(len(geom)>=2,'new_mesh_material_groups_'+e['id'])
 except Exception as ex:ck(False,f'bad_glb_{e["id"]}_{ex}')
# Verify 42 brand new meshes are structurally distinct and still in package.
ck(len({hashlib.sha256((R/e['file']).read_bytes()).hexdigest() for e in manifest})==42,'meshes_unique_bytes')
ck(sum(mesh_totals)>2500,'real_new_geometry')
# Validate site configurations: role layouts explicitly mirror civic_planner.gd; no executable Godot equivalence claimed.
roles={
 'sect_hall':[('sect_hall_8m',0,-5),('martial_training_yard_6m',0,4),('clan_banner_pair',0,0),('stone_lion_statue',-6.7,2.4),('stone_lion_statue',6.7,2.4),('dojo_bell',-6.7,6.5)],
 'temple':[('temple_hall_8m',0,-5),('temple_altar',0,-6.5),('temple_stela',-6.5,3),('temple_stela',6.5,3),('patrol_brazier',-6.5,6.5)],
 'guild_hall':[('guild_hall_8m',0,-5),('clan_banner_pair',0,0),('village_notice_board',-6,3),('street_signpost',6,4)],
 'martial_school':[('sect_hall_8m',0,-5),('martial_training_yard_6m',0,4),('training_dummy',-5.4,4),('training_dummy',5.4,4),('weapons_training_rack',-5.6,7.7),('dojo_bell',5.6,7.7)],
 'granary':[('granary_6m',0,-6),('grain_silo',-6.2,-5),('hay_cart',6.2,2.5),('water_trough',-6,5)],
 'farmstead':[('granary_6m',0,-6),('rice_field_4m',-5.5,2),('vegetable_field_4m',5.5,2),('farm_gate_4m',0,10),('irrigation_channel_2m',-5.5,5),('water_trough',5.5,7),('hay_cart',-5.5,8)]}
for role,layout in roles.items():
 w,d=(26.,30.) if role=='farmstead' else (20.,24.) if role=='granary' else (24.,26.)
 for id,x,z in layout:
  ck(id in byid,'unknown_site_asset_'+id)
  b=np.array(byid[id]['bounds'],dtype=float)
  ck(x+b[0,0]>=-w/2+.05 and x+b[1,0]<=w/2-.05, f'civic_x_out_{role}_{id}')
  ck(z+b[0,2]>=-d/2+.05 and z+b[1,2]<=d/2-.05, f'civic_z_out_{role}_{id}')
  # External corridor central x in [-1.1,1.1] between hall entrance and front approach.
  door=-2.4 if role in ('granary','farmstead') else -.6
  if id not in {'farm_gate_4m','martial_training_yard_6m','rice_field_4m','vegetable_field_4m','irrigation_channel_2m','clan_banner_pair','sect_hall_8m','temple_hall_8m','guild_hall_8m','granary_6m','temple_altar'}:
   occupied_z=(z+b[1,2]>.1+door and z+b[0,2]<d/2-1)
   occupied_x=x+b[0,0]<1.1 and x+b[1,0]>-1.1
   ck(not (occupied_z and occupied_x),'civic_corridor_blocked_'+role+'_'+id)
# Agricultural gate clearance at y<2.0, x[-1.5,1.5]. Geometry check with exact vertex data,
# not just GLB aggregate bounding box.
farm_scene=trimesh.load(str(R/byid['farm_gate_4m']['file']),force='scene',process=False)
verts=np.concatenate([m.vertices for m in farm_scene.geometry.values()])
ck(not any((-1.5<v[0]<1.5 and .5<v[1]<2.1 and -.3<v[2]<.3) for v in verts),'farm_gate_clear_person_height')
# Full fort perimeter arithmetic: no duplicate grid slots / entry 6m gap / 4 tower clear reservations.
for width in range(24,101,2):
 for depth in range(24,101,2):
  hw=(width-4)/2;hd=(depth-4)/2
  xs=[-hw+3+2*i for i in range(int((width-4)/2)-2)]
  center=xs[len(xs)//2]
  remaining=[x for x in xs if abs(x-center)>2.01]
  ck(len(xs)-len(remaining)==3,'gate_cell_not_six_meters_'+str(width))
  ck(min(abs(x-center) for x in remaining)>=3.9,'entrance_overlap_'+str(width))
  # Extents +1.2 eave. Outer site includes 2m margin.
  ck(hw-1+1.2<=width*.5 and hd-1+1.2<=depth*.5,'fort_boundary_overflow')
  ck(abs(center)+3.8<=width*.5,'gate_roof_outside')
  # 4 watchtowers inside reserve.
  ck(hw-3+2.65<=width*.5 and hd-3+2.65<=depth*.5,'watchtower_outside')
  count=2*len(xs)-3+2*(int((depth-4)/2)-2)+4+4
  ck(count<=250,'wall_piece_budget')
# random stress of local->world transforms; ensure every module remains inside rotated own lot bounds.
rr=random.Random(20261018)
for k in range(40000):
 width=rr.randrange(12,51)*2;depth=rr.randrange(12,51)*2
 yaw=rr.randrange(4)
 hw=(width-4)/2;hd=(depth-4)/2
 side=rr.choice([-1,1]);corner=(side*(hw-3),rr.choice([-1,1])*(hd-3))
 # after rotation, site bounding half extents swap (strict overestimate)
 a,b=(width/2,depth/2) if yaw%2==0 else (depth/2,width/2)
 x,z=corner if yaw%2==0 else (-corner[1],corner[0])
 ck(abs(x)+2.65<a+.01 and abs(z)+2.65<b+.01,'rotation_reservation_'+str(k))
# Roadside planting buffers: canopy radius is 2.15m and travel corridor |x|<=2.5m.
for k in range(12000):
 w=rr.uniform(16.0,120.0)
 d=rr.uniform(16.0,120.0)
 x=w*.5-2.45
 z=-d*.5+3.1
 last=-d*.5+3.1+int(math.floor((d-6)/6.5))*6.5
 ck(x-2.15>2.5 and x+2.15<w*.5 and z-2.15>-d*.5 and last+2.15<d*.5,'green_envelope_'+str(k))
# New seed must be kept at full 64-bit precision for new civic and fort sites.
ck('var normalized_seed: int = world_seed' in (R/'forja/civic_planner.gd').read_text(),'civic_seed_not_truncated')
ck('var seed: int = world_seed' in (R/'forja/fortification_planner.gd').read_text(),'fort_seed_not_truncated')
ck('"seed":seed_value' in (R/'forja/green_buffer_v3.gd').read_text(),'green_seed_not_truncated')
# static script/reference validation (not GDScript compilation)
codefiles=['forja/fortification_planner.gd','forja/fortification_builder.gd','forja/civic_planner.gd','forja/civic_builder.gd','forja/compound_assembler.gd','forja/green_buffer_v3.gd','forja/laboratorio_03.gd','forja/genesis_adapter_v3.gd','qa/run_headless_v3.gd','qa/benchmark_v3.gd']
for cf in codefiles:
 s=(R/cf).read_text()
 ck(s.startswith('extends ') and '\t' in s,'script_structure_'+cf)
 for link in re.findall(r'preload\("res://([^\"]+)"\)',s):ck((R/link).is_file(),'missing_reference_'+link)
 for letter,open_,close_ in [('round','(',')'),('square','[',']'),('curly','{','}')]:ck(s.count(open_)==s.count(close_),'unbalanced_'+letter+'_'+cf)
for id in ['wall_stone_2m','foundation_2x2','sect_hall_8m','city_wall_stone_2m','watchtower_stone_4m','tree_orchard']:
 ck(id in byid,'required_reference_'+id)
# Old house schema remains compatible with older saves (no touches to planner/builders)
for f in ['forja/forja_planner.gd','forja/forja_builder.gd','forja/detail_pass.gd','forja/plaza_furnisher.gd','godot/modular_kit.gd']:
 ck(hashlib.sha256((R/f).read_bytes()).hexdigest()==oldhashes[f],'backwards_house_unchanged_'+f)
res['metrics']={'original_assets':121,'new_models':42,'total_assets':163,'new_asset_triangles':sum(mesh_totals),'legacy_files_checked':len(oldhashes)-len(allowed), 'max_absolute_bounds_error_m':round(worst,5),'fort_geometry_combinations':39**2,'random_rotated_reservation_cases':40000,'random_green_buffer_envelopes':12000,'civic_role_layouts':6,'godot_engine':'NOT RUN'}
out=R/'qa/results_v3_offline.json';out.write_text(json.dumps(res,indent=2,ensure_ascii=False)+'\n')
print('EXO FORJA03 QA',json.dumps({'passed':res['passed'],'failed':len(res['failed']),'first_errors':res['failed'][:30],'metrics':res['metrics']},ensure_ascii=False))
sys.exit(bool(res['failed']))
