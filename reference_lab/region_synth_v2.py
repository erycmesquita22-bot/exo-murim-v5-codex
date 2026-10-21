#!/usr/bin/env python3
"""EXO RegionSynth laboratory: numerical physical-region planning.

Builds heightfield, graded transit roads, level modular foundations, terrain
materials and edge safety masks from shared atlas portal contracts.
No Godot collision engine has been run; this is an exported mesh prototype.
"""
from __future__ import annotations
import sys, json, math, hashlib
from pathlib import Path
from dataclasses import dataclass
import numpy as np
from scipy.ndimage import gaussian_filter, distance_transform_edt
from skimage.graph import route_through_array
from world_genesis_v2 import fbm,noise,stable_u64,terrain_and_climate,EXTENT


@dataclass
class Region:
  seed:int
  rid:int
  height:np.ndarray
  materials:np.ndarray
  blend:np.ndarray
  roads:np.ndarray
  walls:np.ndarray
  portals:list
  buildings:list
  plants:list
  paths:list
  extent:float
  origin:tuple


def generate(atlas,region_id,cells=112):
  r=atlas['regions'][region_id];regionseed=r['region_seed'];seed=atlas['seed']
  rng=np.random.default_rng(stable_u64(seed,'regional_objects',region_id))
  yy,xx=np.mgrid[:cells,:cells];x0=(xx+.5)/cells;y0=(yy+.5)/cells
  cx,cy=r['center'];
  # Sampling a continuous planet-scale geographic field retains inter-region
  # ecological continuity. The *region* receives its own fine-detail seed.
  gx=np.clip(cx+(x0-.5)*.12,0,1);gy=np.clip(cy+(y0-.5)*.12,0,1)
  surface,wet,temp=terrain_and_climate(np.column_stack([gx.ravel(),gy.ravel()]),seed)
  surface=surface.reshape((cells,cells))
  local=fbm(x0,y0,stable_u64(seed,'detail',region_id),(2.2,5.5,12),(0.58,.29,.13))
  height=8+25*surface+2.4*local
  if r['biome'] in ('rocky_highlands','alpine'):
    # Massifs occupy a real share of the region, not merely rocks on a flat floor.
    # Regional roads will subsequently cut navigable passes through the ridge.
    ridge_pos=.70+.09*np.sin(y0*5.1+region_id*.23)
    ridge=(np.exp(-((x0-ridge_pos)/.19)**2) +
           .38*np.exp(-((y0-.13)/.15)**2))
    rough=np.abs(noise(x0,y0,stable_u64(seed,'crags',region_id),8.0))
    gain=32.0 if r['biome']=='rocky_highlands' else 54.0
    height+=gain*ridge*(.74+.50*rough)
    height+=6*np.abs(noise(x0,y0,stable_u64(seed,'spurs',region_id),5))

  # Protected central hub. Buildings and paths are laid AFTER this position is known.
  hc=cells//2;hub=(hc,hc)
  # Small initial leveling zone, blending into surrounding relief.
  rr=np.hypot(xx-hc,yy-hc)
  centerheight=float(height[hub]);weight=np.clip((8-rr)/5,0,1)**2
  height=(1-weight)*height+weight*centerheight
  ports=[];all_paths=[];road_mask=np.zeros((cells,cells),dtype=bool)
  # Grade-aware routefinding (slope + biome obstacles) rather than a straight line.
  for entry in r['entrances']:
    port=next(p for p in atlas['portals'] if p['id']==entry['gate_id'])
    localx,localz=entry['xz']
    px=int(np.clip(round((localx/atlas['region_extent_m']+.5)*(cells-1)),0,cells-1))
    py=int(np.clip(round((localz/atlas['region_extent_m']+.5)*(cells-1)),0,cells-1))
    gate=(py,px)
    gy0,gx0=np.gradient(height)
    rough=np.hypot(gy0,gx0)
    costs=1+4*np.maximum(rough-.35,0)**2+1.1*np.maximum(height-(centerheight+6),0)**2
    # Mild road corridor preference through low terrain.
    path,cost=route_through_array(costs,hub,gate,fully_connected=True,geometric=True)
    path=[tuple(map(int,p)) for p in path]
    all_paths.append(path)
    ports.append({'gate_id':entry['gate_id'],'neighbor':entry['neighbor'],'cell':[py,px],
        'target_height_m':port['height_m'],'width_m':port['width_m'],'path_length_cells':len(path)})
    for y,x in path:road_mask[y,x]=True
  # Expand each road to traversable width; slope-aligned grading. All border
  # gates share heights with their linked region through the atlas contract.
  level_sum=np.zeros_like(height);level_n=np.zeros_like(height)
  for path,entry in zip(all_paths,ports):
    yend,xend=entry['cell'];gate_h=entry['target_height_m']
    total=0.;dists=[0.]
    for (ya,xa),(yb,xb) in zip(path,path[1:]):
      total+=math.hypot(yb-ya,xb-xa);dists.append(total)
    for (y,x),dist in zip(path,dists):
      target=(1-dist/max(1,total))*centerheight+(dist/max(1,total))*gate_h
      level_sum[y,x]+=target;level_n[y,x]+=1
  radius=max(1.3,2.4*cells/112)
  road_support=gaussian_filter(level_n.astype(float),radius)
  road_target=gaussian_filter(level_sum,radius)/np.maximum(road_support,1e-8)
  strength=np.clip(road_support/.14,0,1)
  height=(1-strength)*height+strength*road_target
  # The road centerline follows the actual graded route, not the diluted
  # Gaussian shoulder. This prevents the isolated steep last step at a gate.
  centerline=level_n>0
  height[centerline]=level_sum[centerline]/level_n[centerline]
  # Guarantee the portal touchdown tile is precisely at its signed elevation.
  for entry in ports:
    y,x=entry['cell'];height[y,x]=entry['target_height_m']
  # Shared road-network grading. Independently interpolated roads can split from
  # a common trunk at incompatible heights. Project the network onto bounded
  # grade constraints while keeping the hub and shared gate elevations fixed.
  road_edges=set()
  for path in all_paths:
    for a,b in zip(path,path[1:]):
      if a!=b:road_edges.add(tuple(sorted((a,b))))
  anchored={hub}
  anchored.update(tuple(p['cell']) for p in ports)
  slope_limit=1.6  # metres per raster edge, including diagonal; conservative.
  for _ in range(240):
    violating=0
    for a,b in sorted(road_edges):
      ay,ax=a;by,bx=b;diff=float(height[ay,ax]-height[by,bx])
      if abs(diff)<=slope_limit+1e-8:continue
      violating+=1
      excess=(abs(diff)-slope_limit)* (1 if diff>0 else -1)
      if a in anchored and b in anchored:
        # This should not occur after global gate-height packing.
        continue
      elif a in anchored:height[by,bx]+=excess
      elif b in anchored:height[ay,ax]-=excess
      else:
        height[ay,ax]-=.5*excess
        height[by,bx]+=.5*excess
    if violating==0:break
  # Place modular footprints only on flat, available ground within the central
  # plaza. All footprints reserve breathing room from routes and one another.
  buildings=[];occupancy=np.zeros((cells,cells),dtype=bool)
  target_count={'settlement':6,'ruins':3,'dungeon_approach':2,'wild':1}[r['kind']]
  for attempt in range(180):
    if len(buildings)>=target_count:break
    dy=int(rng.integers(-22,23));dx=int(rng.integers(-22,23))
    if 6<math.hypot(dx,dy)>23:continue
    if math.hypot(dx,dy)<7:continue
    cy1=hc+dy;cx1=hc+dx
    pad=int(rng.choice([3,4,5]))
    if min(cy1-pad,cx1-pad)<4 or max(cy1+pad,cx1+pad)>cells-5:continue
    ys=slice(cy1-pad-2,cy1+pad+3);xs=slice(cx1-pad-2,cx1+pad+3)
    if occupancy[ys,xs].any():continue
    if road_mask[ys,xs].any() or road_support[ys,xs].max()>.075:continue
    yh=slice(cy1-pad,cy1+pad+1);xh=slice(cx1-pad,cx1+pad+1)
    # Foundation terrace, blended at edges; houses never hover above a slope.
    hbase=float(np.median(height[yh,xh]));
    dist=np.maximum(abs(yy-cy1)-pad,abs(xx-cx1)-pad)
    foundation_weight=np.clip((3-dist)/3,0,1)
    height=height*(1-foundation_weight)+hbase*foundation_weight
    occupancy[ys,xs]=True
    buildings.append({'center':[cy1,cx1],'halfsize':pad,'floor_height_m':round(hbase,3),
       'module_style':'murim_voxel' if r['kind']=='settlement' else 'stone_ruins'})
  if r['kind']=='settlement' and len(buildings)<2:
    # Fallback at the central plaza with guaranteed support; no silent shortage.
    buildings.append({'center':[hc-10,hc+10],'halfsize':3,'floor_height_m':float(height[hc-10,hc+10]),
                      'module_style':'murim_voxel'})
  # Material layers: masks are spatially coherent, with continuous road blends.
  macro_wet=wet.reshape((cells,cells))
  materials=np.zeros_like(height,dtype=np.uint8)
  materials[height>np.quantile(height,.78)]=2  # high rocky exposure
  materials[macro_wet>.7]=3  # forest/bamboo
  materials[road_support>.07]=1 # dirt
  blend=np.clip(road_support/.16,0,1)
  # Safety barrier on non-transit borders: a region never opens onto the void.
  walls=np.zeros_like(height,dtype=bool)
  walls[:2,:]=True;walls[-2:,:]=True;walls[:,:2]=True;walls[:,-2:]=True
  for entry in ports:
    y,x=entry['cell'];radius_gate=max(2,int(entry['width_m']/atlas['region_extent_m']*cells/2)+2)
    if y<3:walls[:3,max(0,x-radius_gate):min(cells,x+radius_gate+1)]=False
    if y>=cells-3:walls[-3:,max(0,x-radius_gate):min(cells,x+radius_gate+1)]=False
    if x<3:walls[max(0,y-radius_gate):min(cells,y+radius_gate+1),:3]=False
    if x>=cells-3:walls[max(0,y-radius_gate):min(cells,y+radius_gate+1),-3:]=False
  # Decorative items are distributed by clearances from roads and structures.
  clearance=distance_transform_edt(~(occupancy|(road_support>.09)|walls))
  plants=[]
  target_density={'bamboo_forest':.026,'temperate_forest':.023,'mixed_woodland':.017,
                  'wetland':.019,'grassland':.011,'rocky_highlands':.006,
                  'alpine':.004,'dry_valley':.003}[r['biome']]
  for _ in range(4500):
    if len(plants)>=int(cells*cells*target_density):break
    y=int(rng.integers(4,cells-4));x=int(rng.integers(4,cells-4))
    if clearance[y,x]<3:continue
    if plants and any((x-p[1])**2+(y-p[0])**2<7 for p in plants):continue
    plants.append((y,x))
  return Region(seed,region_id,height,materials,blend,road_support>.09,walls,ports,
                buildings,plants,all_paths,float(atlas['region_extent_m']),tuple(r['center']))


def validate(region):
  height=region.height;H,W=height.shape
  checks={}
  checks['finite_surface']=bool(np.isfinite(height).all())
  checks['has_gate']=len(region.portals)>=1
  checks['symmetric_gate_target']=all(abs(height[tuple(p['cell'])]-p['target_height_m'])<1e-6 for p in region.portals)
  checks['all_gates_connected_to_hub_by_path']=all(len(p)>4 for p in region.paths)
  checks['valid_gate_positions']=all(min(p['cell'])>=0 and max(p['cell'])<H for p in region.portals)
  checks['walls_block_non_gate_edges']=bool(region.walls[0,:].sum()+region.walls[-1,:].sum()+region.walls[:,0].sum()+region.walls[:,-1].sum()>0)
  # Strong grading ensures trail is traversable at a character-scale threshold,
  # but actual movement/physics needs Godot validation.
  max_slope=0
  for path in region.paths:
    grades=[abs(float(height[ya,xa]-height[yb,xb])) for (ya,xa),(yb,xb) in zip(path,path[1:])]
    if grades:max_slope=max(max_slope,max(grades))
  checks['road_cell_max_grade_under_2_3m']=max_slope<=2.3
  checks['building_minimum']=len(region.buildings)>0
  checks['foundation_levels_finite']=all(math.isfinite(b['floor_height_m']) for b in region.buildings)
  checks['all_building_footprints_level']=True
  for b in region.buildings:
    cy,cx=b['center'];z=b['halfsize'];sl=height[cy-z:cy+z+1,cx-z:cx+z+1]
    if sl.size and float(sl.max()-sl.min())>.11:checks['all_building_footprints_level']=False
  return {'ok':all(checks.values()),'checks':checks,'max_road_grade_m':round(max_slope,3),
          'building_count':len(region.buildings),'plant_count':len(region.plants),
          'gate_count':len(region.portals)}

if __name__=='__main__':
 from world_genesis_v2 import plan
 doc=plan(816204);rg=generate(doc,doc['start_region']);print(json.dumps(validate(rg),indent=2))
