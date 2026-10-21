#!/usr/bin/env python3
"""EXO-Murim: regional planning *prototype* (NOT a terrain renderer).

Deterministic for a given NumPy+SciPy+NetworkX environment; exported JSON snapshots
are the canonical results for this prototype. Runtime-Godot RNG equivalence is
NOT guaranteed. No third-party project source code is copied.
"""
from __future__ import annotations
import json, hashlib, math, argparse, time
from pathlib import Path
from dataclasses import dataclass
import numpy as np
import networkx as nx
from scipy.spatial import Delaunay
from scipy.ndimage import gaussian_filter, map_coordinates

N=88
CATEGORIES={"settlement":23,"ruins":12,"dungeon_approach":10,"wild":43}
BIOMES=['grassland','temperate_forest','bamboo_forest','dry_valley','wetland','rocky_highlands','alpine','mixed_woodland']
BORDER=256.0


def normalized(grid):
    a,b=np.quantile(grid,[.02,.98]);return np.clip((grid-a)/(b-a+1e-9),0.,1.)


def field(rng, height=192, width=192, sigmas=(46,19,7), weights=(.64,.27,.09)):
    result=np.zeros((height,width), dtype=np.float64)
    for sigma,weight in zip(sigmas,weights):
        sample=rng.standard_normal((height,width))
        blurred=gaussian_filter(sample,sigma=sigma,mode='reflect')
        result+=normalized(blurred)*weight
    return normalized(result)


def sample(field_,sites):
    return map_coordinates(field_, [sites[:,1]*(field_.shape[0]-1), sites[:,0]*(field_.shape[1]-1)],order=1,mode='nearest')


def sites_88(rng):
    # Jittered stratified Poisson-like points; grid cells are deliberately
    # randomized spatially and used ONLY to distribute the 88 region centers.
    pts=[]
    for iy in range(8):
        for ix in range(11):
            pts.append(((ix+.5+rng.uniform(-.38,.38))/11,
                        (iy+.5+rng.uniform(-.38,.38))/8))
    arr=np.array(pts,dtype=float)
    rng.shuffle(arr)
    return arr


def unique_delaunay_edges(sites):
    edges=set()
    for tri in Delaunay(sites).simplices:
        for i,j in ((tri[0],tri[1]),(tri[1],tri[2]),(tri[2],tri[0])):
            a,b=sorted((int(i),int(j)));edges.add((a,b))
    return sorted(edges)


def biome(alt,temp,wet):
    if alt>.80:return 'alpine'
    if alt>.66:return 'rocky_highlands'
    if wet>.74 and alt<.42:return 'wetland'
    if temp>.45 and wet>.61:return 'bamboo_forest'
    if wet<.33:return 'dry_valley'
    if wet>.51:return 'temperate_forest'
    if alt<.39:return 'grassland'
    return 'mixed_woodland'


def portal_point(src,dst,side=256):
    delta=dst-src
    axis=0 if abs(delta[0])>=abs(delta[1]) else 1
    c=[0.,0.]
    c[axis]=(side/2)*np.sign(delta[axis])
    other=1-axis
    # Minor side-offset stays in legal range and follows neighbor bearing.
    c[other]=float(np.clip(delta[other]/max(1e-7,abs(delta[axis]))*(side/3),-side*.35,side*.35))
    return [round(c[0],3),round(c[1],3)]


def plan(seed:int, loops:int=26):
    rng=np.random.default_rng(seed)
    pts=sites_88(rng)
    elev_noise=field(rng)
    wet_noise=field(rng,sigmas=(57,22,9))
    thermal_noise=field(rng,sigmas=(60,21,7))
    alt=np.clip(.77*sample(elev_noise,pts)+.23*np.abs(pts[:,0]-.58),0,1)
    wet=np.clip(.78*sample(wet_noise,pts)+.22*(1-abs(pts[:,1]-.5)*1.7),0,1)
    temp=np.clip(.56*sample(thermal_noise,pts)+.44*(1-np.abs(pts[:,1]-.56)*1.5)-.32*alt,0,1)
    regions=[{'id':int(i),'center':[round(float(v),6) for v in pts[i]],
              'elevation':round(float(alt[i]),4),'humidity':round(float(wet[i]),4),
              'temperature':round(float(temp[i]),4),
              'biome':biome(alt[i],temp[i],wet[i])} for i in range(N)]
    candidates=unique_delaunay_edges(pts)
    gfull=nx.Graph();gfull.add_nodes_from(range(N))
    for a,b in candidates:
        distance=float(np.linalg.norm(pts[a]-pts[b]))
        cost=distance*(1.+1.6*abs(alt[a]-alt[b])+ .5*abs(wet[a]-wet[b]))
        gfull.add_edge(a,b,weight=cost)
    tree=nx.minimum_spanning_tree(gfull,weight='weight')
    g=nx.Graph(tree)
    possible=[(a,b,d['weight']) for a,b,d in gfull.edges(data=True) if not g.has_edge(a,b)]
    possible.sort(key=lambda a:a[2]*(.82+.36*rng.random()))
    chosen=0
    for a,b,_ in possible:
        if chosen>=loops:break
        if g.degree(a)>=4 or g.degree(b)>=4:continue
        # Favor loops without trapping micro-cycles of 3 nodes.
        try: dist=nx.shortest_path_length(g,a,b)
        except nx.NetworkXNoPath:dist=10
        if dist<3:continue
        g.add_edge(a,b);chosen+=1
    # Fallback: accept triangles only if needed to hit loop target.
    for a,b,_ in possible:
        if chosen>=loops:break
        if g.has_edge(a,b) or g.degree(a)>=4 or g.degree(b)>=4:continue
        g.add_edge(a,b);chosen+=1
    distances_to_center=np.linalg.norm(pts-np.array([.5,.5]),axis=1)
    safe_candidates=[i for i in range(N) if alt[i]<.56 and g.degree(i)>=2]
    if not safe_candidates:safe_candidates=list(range(N))
    spawn=min(safe_candidates,key=lambda i:1.6*abs(alt[i]-.36)+distances_to_center[i]+.5*max(0,.3-wet[i]))
    categories={i:'wild' for i in range(N)}
    categories[spawn]='settlement'
    selected_settlements=[spawn]
    def settlement_score(i):
        proximity=min(float(np.linalg.norm(pts[i]-pts[j])) for j in selected_settlements)
        flatness=1-abs(float(alt[i])-.38)
        return 2.2*proximity+.45*flatness+.2*float(wet[i])+.1*g.degree(i)
    for _ in range(CATEGORIES['settlement']-1):
        candidates_set=[i for i in range(N) if categories[i]=='wild' and alt[i]<=.68]
        if not candidates_set: candidates_set=[i for i in range(N) if categories[i]=='wild']
        pick=max(candidates_set,key=settlement_score)
        categories[pick]='settlement';selected_settlements.append(pick)
    hop=nx.single_source_shortest_path_length(g,spawn)
    ruins_candidates=sorted((i for i in range(N) if categories[i]=='wild'),key=lambda i:(.6*float(alt[i])+.35*float(1-wet[i])+.04*hop[i]+rng.uniform(0,.12)),reverse=True)
    for i in ruins_candidates[:CATEGORIES['ruins']]:categories[i]='ruins'
    dungeon_candidates=sorted((i for i in range(N) if categories[i]=='wild' and hop[i]>1),key=lambda i:(.7*float(alt[i])+.17*(1-wet[i])+.06*hop[i]+rng.uniform(0,.15)),reverse=True)
    if len(dungeon_candidates)<10:dungeon_candidates += [i for i in range(N) if categories[i]=='wild' and i not in dungeon_candidates]
    for i in dungeon_candidates[:CATEGORIES['dungeon_approach']]:categories[i]='dungeon_approach'
    for node in regions:
        i=node['id'];node['kind']=categories[i];node['threat_tier']=int(min(5,max(1,1+hop[i]//4)))
        node['entrances']=[]
        node['region_seed']=int.from_bytes(hashlib.sha256(f'{seed}|region|{i}|algorithm_1'.encode()).digest()[:8],'big')
        node['asset_palette']={
            'alpine':'snow_stone','rocky_highlands':'stone_moss','wetland':'marsh_bamboo',
            'bamboo_forest':'bamboo_forest','grassland':'grass_earth',
            'dry_valley':'dry_earth','temperate_forest':'forest_soil',
            'mixed_woodland':'forest_grass'}[node['biome']]
    # Every graph edge becomes ONE shared portal contract, never two independent rolls.
    portals=[]
    for idx,(a,b) in enumerate(sorted(tuple(sorted(e)) for e in g.edges())):
        ra,rb=regions[a],regions[b]
        # Stable per-pair hash instead of traversal order.
        hashed=hashlib.sha256(f'{seed}|portal|{a}|{b}|v1'.encode()).digest()
        width=float([6,8,10,12][hashed[0]%4])
        level=round(12+37*float(.5*(alt[a]+alt[b])),2)
        contract={ 'id':f'p_{a}_{b}','a':a,'b':b, 'width_m':width,'height_m':level,
            'from_a':portal_point(pts[a],pts[b]),'from_b':portal_point(pts[b],pts[a]),
            'requires_fade':True}
        portals.append(contract)
        ra['entrances'].append({'portal_id':contract['id'],'neighbor_id':b,'local_xz':contract['from_a']})
        rb['entrances'].append({'portal_id':contract['id'],'neighbor_id':a,'local_xz':contract['from_b']})
    # Prototype hydrology only: continuous DOWNHILL DATA graph on Delaunay neighbors;
    # does NOT claim physically simulated flowing rivers across 3D meshes.
    drainage={i:None for i in range(N)}
    for i in range(N):
        lower=[j for j in gfull.neighbors(i) if alt[j]<alt[i]-1e-4]
        if lower:drainage[i]=min(lower,key=lambda j:(float(alt[j]),float(np.linalg.norm(pts[i]-pts[j]))))
    runoff={i:float(wet[i])*.5+.1 for i in range(N)}
    for i in sorted(range(N),key=lambda i:float(alt[i]),reverse=True):
        dst=drainage[i]
        if dst is not None:runoff[dst]+=runoff[i]
    hydro=[{'region':i,'downstream':drainage[i],'flow_proxy':round(runoff[i],4)} for i in range(N)]
    document={'schema_version':1,'algorithm':'exo_regional_planner_prototype_1','seed':int(seed),'start_region':spawn,
              'region_count':N,'region_extent_m':BORDER,
              'target_categories':CATEGORIES,'regions':regions,'portals':portals,'hydrology_macro':hydro,
              'caveat':'Logical prototype: no runtime mesh, physics, actual biome boundary grids, terrain water or Godot validation.'}
    return document


def validate(doc):
    regions=doc['regions'];ports=doc['portals'];n=len(regions)
    graph=nx.Graph();graph.add_nodes_from(range(n))
    for p in ports:graph.add_edge(p['a'],p['b'])
    from collections import Counter
    counts=Counter(r['kind'] for r in regions)
    start=doc['start_region']
    h=dict(nx.single_source_shortest_path_length(graph,start))
    passed={
      'exactly_88':n==88,
      'quotas':dict(counts)==CATEGORIES,
      'connected':nx.is_connected(graph),
      'contains_loops':graph.number_of_edges()-graph.number_of_nodes()+1>=15,
      'low_exit_density':max(dict(graph.degree()).values())<=4,
      'spawn_safe':regions[start]['kind']=='settlement' and regions[start]['biome'] not in ('alpine','rocky_highlands'),
      'settlements_avoid_alpine':all(r['biome']!='alpine' for r in regions if r['kind']=='settlement'),
      'dungeons_not_adjacent_spawn':all(h[i]>1 for i,r in enumerate(regions) if r['kind']=='dungeon_approach'),
      'unique_portals':len({p['id'] for p in ports})==len(ports),
      'symmetric_portals':all(sum(e['portal_id']==p['id'] for e in regions[p['a']]['entrances'])==1 and sum(e['portal_id']==p['id'] for e in regions[p['b']]['entrances'])==1 for p in ports),
      'finite_climate':all(all(math.isfinite(r[k]) for k in ('elevation','temperature','humidity')) for r in regions),
      'drainage_downhill':all(h['downstream'] is None or regions[h['downstream']]['elevation']<regions[h['region']]['elevation']+1e-4 for h in doc['hydrology_macro']),
    }
    return {'ok':all(passed.values()),'checks':passed,'total_links':graph.number_of_edges(),'loops':graph.number_of_edges()-n+1,
       'biomes':dict(Counter(r['biome'] for r in regions)),'max_degree':max(dict(graph.degree()).values())}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--seed',type=int,default=816204)
    parser.add_argument('--output',type=Path,default=Path('world_816204.json'))
    args=parser.parse_args()
    world=plan(args.seed)
    report=validate(world)
    assert report['ok'],report
    args.output.write_text(json.dumps(world,ensure_ascii=False,indent=2))
    print(json.dumps(report,indent=2,ensure_ascii=False))

if __name__=='__main__':main()
