#!/usr/bin/env python3
"""EXO World Genesis v2: deterministic logical planning of 88 zoned regions.

Purely a *world planner*. Not a Godot terrain/physics renderer. Algorithms are
new for EXO. Implementation uses SciPy and NetworkX as a research laboratory.
The JSON file is the source of truth for downstream generators.
"""
from __future__ import annotations
import argparse, collections, hashlib, json, math, time
from pathlib import Path
import numpy as np
import networkx as nx
from scipy.spatial import Delaunay

N = 88
QUOTAS = {'settlement':23,'ruins':12,'dungeon_approach':10,'wild':43}
BIOMES = ['grassland','temperate_forest','bamboo_forest','dry_valley','wetland','rocky_highlands','alpine','mixed_woodland']
EXTENT = 512.0


def stable_u64(*parts):
    s='|'.join(map(str,parts)).encode('utf8')
    return int.from_bytes(hashlib.blake2b(s,digest_size=8,person=b'EXO_GEN2').digest(),'big')


def noise(x,y,seed,scale):
    """Vectorized, smooth cubic interpolation of reproducible integer value noise."""
    x=np.asarray(x)*scale; y=np.asarray(y)*scale
    i=np.floor(x).astype(np.int64);j=np.floor(y).astype(np.int64)
    fx=x-i;fy=y-j
    u=fx*fx*(3-2*fx);v=fy*fy*(3-2*fy)
    def h(dx,dy):
        a=(i+dx).astype(np.uint64)*np.uint64(0x9E3779B185EBCA87)
        b=(j+dy).astype(np.uint64)*np.uint64(0xC2B2AE3D27D4EB4F)
        k=np.uint64(seed&((1<<64)-1))
        z=(a^b^k)
        z^=z>>np.uint64(30);z*=np.uint64(0xBF58476D1CE4E5B9)
        z^=z>>np.uint64(27);z*=np.uint64(0x94D049BB133111EB)
        z^=z>>np.uint64(31)
        return ((z>>np.uint64(11)).astype(float)/(2**53))*2-1
    q00=h(0,0);q10=h(1,0);q01=h(0,1);q11=h(1,1)
    return (q00*(1-u)+q10*u)*(1-v)+(q01*(1-u)+q11*u)*v


def fbm(x,y,seed,octaves=(2.1,4.0,8.0,15.5),weights=(.52,.27,.14,.07)):
    out=np.zeros_like(np.asarray(x,dtype=float))
    for k,(freq,w) in enumerate(zip(octaves,weights)):
        out+=w*noise(x,y,stable_u64(seed,'oct',k),freq)
    return out


def terrain_and_climate(pts,seed):
    x=pts[:,0]; y=pts[:,1]
    # Per-seed mountain chain + coherent crag ridges; not independently random biomes.
    rseed=stable_u64(seed,'ridge')
    ridge_phase=((rseed%10000)/10000)*math.tau
    ridge_center=.50+.19*np.sin(y*4.5+ridge_phase)+.07*np.cos(y*11.2-ridge_phase)
    ridge_dist=np.abs(x-ridge_center)
    mountain=np.exp(-(ridge_dist/.13)**2)*(.38+.20*np.abs(noise(x,y,stable_u64(seed,'ridge_detail'),5)))
    upland=np.abs(fbm(x,y,stable_u64(seed,'upland'),(1.8,3.9,7.8),(.58,.28,.14)))
    broad=.5+.37*fbm(x,y,stable_u64(seed,'land'))
    height=np.clip(.16+.55*broad+mountain+.15*upland-.04,0,1)
    # Annual rain, dominant winds from west; mountain chains cast a mild rain shadow.
    rain_base=.66+.54*fbm(x,y,stable_u64(seed,'moisture'),(1.7,4.5,9),(.55,.31,.14))
    rain_shadow=.13*np.clip(x-ridge_center,0,1)/.45*np.exp(-(ridge_dist/.34)**2)
    humidity=np.clip(rain_base+ .11*np.cos(3*y+.4)-rain_shadow-.07*height,0,1)
    temp=np.clip(.91-.34*np.abs(y-.48)*2-.46*height+.16*fbm(x,y,stable_u64(seed,'temperature'))+.05,0,1)
    return height,humidity,temp


def select_biomes(pts,height,wet,temp,graph):
    """Constrained bioclimatic classification. Keeps rare niches, limits monopolies.

    A biome has a physical suitability cost; repairs choose the smallest extra
    cost rather than drawing a rare biome at random. This is NOT an ecological
    simulation, but an explicit quality-controlled biome distribution.
    """
    climate=np.stack([height,wet,temp],axis=1)
    niches=np.asarray([
      [.34,.43,.67], [.43,.68,.52], [.34,.76,.73], [.27,.24,.76],
      [.23,.85,.57], [.72,.45,.35], [.89,.46,.22], [.46,.55,.58]])
    weights=np.asarray([1.6,1.9,1.5])
    d=((climate[:,None,:]-niches[None,:,:])**2*weights).sum(axis=2)
    # Out-of-range biomes have strongly penalized, but not impossible, costs.
    d[height>.56,4]+=1.5
    d[height<.68,6]+=1.3
    d[height<.55,5]+=.3
    d[wet<.5,2]+=.2
    choice=np.argmin(d,axis=1)
    counts=np.bincount(choice,minlength=len(BIOMES))
    # Prevent a single common biome from covering almost half the world.
    for iteration in range(200):
        over=[int(k) for k in range(len(BIOMES)) if counts[k]>32]
        if not over:break
        candidates=[]
        for old in over:
            for i in np.where(choice==old)[0]:
                for new in range(len(BIOMES)):
                    if new==old or counts[new]>=30:continue
                    cost=float(d[i,new]-d[i,old])
                    candidates.append((cost,int(i),new,old))
        if not candidates:break
        _,i,new,old=min(candidates)
        choice[i]=new;counts[old]-=1;counts[new]+=1
    # Ensure *at least six* compatible niches, selecting the cheapest candidates
    # rather than fabricating environmental data. This also prevents 1-cell rarity.
    while np.count_nonzero(counts)<6:
        missing=[k for k in range(len(BIOMES)) if counts[k]==0]
        candidates=[]
        for new in missing:
            for i in range(N):
                old=int(choice[i])
                if counts[old]<=2:continue
                candidates.append((float(d[i,new]-d[i,old]),i,new,old))
        if not candidates:break
        _,i,new,old=min(candidates)
        choice[i]=new;counts[old]-=1;counts[new]+=1
    return [BIOMES[int(k)] for k in choice]


def layout(seed):
    rng=np.random.default_rng(stable_u64(seed,'sites'))
    # Stratified quasi-blue-noise scaffold: 11 by 8 ensures no long empty deserts.
    pts=np.array([[(ix+.5+rng.uniform(-.35,.35))/11,
                   (iy+.5+rng.uniform(-.35,.35))/8]
                  for iy in range(8) for ix in range(11)],dtype=float)
    perm=rng.permutation(N)
    return pts[perm]


def candidate_graph(pts,h,wet):
    tri=Delaunay(pts)
    edges=set()
    for a,b,c in tri.simplices:
        for u,v in ((a,b),(a,c),(b,c)):edges.add(tuple(sorted((int(u),int(v)))))
    graph=nx.Graph();graph.add_nodes_from(range(N))
    for a,b in edges:
        length=float(np.linalg.norm(pts[a]-pts[b]))
        elevation=float(abs(h[a]-h[b])); humid=float(abs(wet[a]-wet[b]))
        cost=length*(1+2.3*elevation+.26*humid)
        graph.add_edge(a,b,weight=cost,length=length)
    return graph


def choose_routes(full,seed,loop_goal=26):
    """Geographically planar network, with explicit degree repair before loops."""
    tree=nx.minimum_spanning_tree(full,weight='weight')
    graph=nx.Graph(tree)
    # Occasionally an MST has five exits on one node. Replace one connection
    # by a valid alternate edge connecting the same two tree components.
    for _ in range(30):
        over=[v for v,d in graph.degree() if d>4]
        if not over:break
        success=False
        for root in over:
            for a,b in sorted(graph.edges(root),key=lambda edge:full[edge[0]][edge[1]]['weight'],reverse=True):
                saved=dict(graph[a][b]);graph.remove_edge(a,b)
                comp=set(nx.node_connected_component(graph,a))
                options=[]
                for u,v,edata in full.edges(data=True):
                    if (u in comp)==(v in comp):continue
                    if graph.degree(u)>=4 or graph.degree(v)>=4:continue
                    options.append((edata['weight'],u,v,edata))
                if options:
                    _,u,v,edata=min(options,key=lambda x:x[0]);graph.add_edge(u,v,**edata)
                    success=True;break
                graph.add_edge(a,b,**saved)
            if success:break
        if not success:break
    rng=np.random.default_rng(stable_u64(seed,'roads'))
    candidates=[]
    for a,b,d in full.edges(data=True):
        if graph.has_edge(a,b):continue
        candidates.append((d['weight']*(.90+.20*rng.random()),a,b))
    candidates.sort()
    for allow_triangles in (False,True):
        for _,a,b in candidates:
            if graph.number_of_edges()-N+1>=loop_goal:break
            if graph.has_edge(a,b) or max(graph.degree(a),graph.degree(b))>=4:continue
            if not allow_triangles and nx.shortest_path_length(graph,a,b)<3:continue
            graph.add_edge(a,b,**full[a][b])
    return graph


def pick_categories(seed,pts,h,wet,biomes,g,spawn):
    kinds=['wild']*N;kinds[spawn]='settlement'
    hop=nx.single_source_shortest_path_length(g,spawn)
    # A graph-wide covering strategy places essential services near every region.
    # The first three settlements are deliberately placed near the starter region.
    settlements=[spawn]
    paths=dict(nx.all_pairs_shortest_path_length(g))
    safety=[v for v in g.neighbors(spawn) if h[v]<.68 and biomes[v] not in ('alpine','rocky_highlands')]
    for i in safety[:2]:
        if kinds[i]=='wild':kinds[i]='settlement';settlements.append(i)
    while len(settlements)<23:
        permitted=[i for i in range(N) if kinds[i]=='wild' and h[i]<.70 and biomes[i]!='alpine']
        if not permitted:permitted=[i for i in range(N) if kinds[i]=='wild']
        def score(i):
            near=min(paths[i][j] for j in settlements)
            euclid=min(np.linalg.norm(pts[i]-pts[j]) for j in settlements)
            terrain=.2 if h[i]>.62 else 0
            return (near*1.2+.6*euclid-.35*terrain+.06*g.degree(i),stable_u64(seed,'settlement',i))
        pick=max(permitted,key=score)
        kinds[pick]='settlement';settlements.append(pick)
    # Service coverage repair (not seed rejection): swap distant service points
    # into underserved branches until every playable region has a nearby hub.
    path_matrix=np.asarray([[paths[i][j] for j in range(N)] for i in range(N)],dtype=np.int16)
    for iteration in range(40):
        current=path_matrix[:,settlements].min(axis=1)
        if int(current.max())<=4:break
        old_quality=(int(current.max()),int(current.sum()))
        best=None
        # Evaluating alternate settlement sites uses the exact graph distance.
        unselected=[i for i in range(N) if kinds[i]=='wild']
        for candidate in unselected:
            for old in settlements:
                if old==spawn:continue
                alts=[i for i in settlements if i!=old]+[candidate]
                nd=path_matrix[:,alts].min(axis=1)
                score=(int(nd.max()),int(nd.sum()))
                if score<old_quality and (best is None or score<best[0]):
                    best=(score,old,candidate)
        if best is None:break
        _,old,candidate=best
        settlements.remove(old);settlements.append(candidate)
        kinds[old]='wild';kinds[candidate]='settlement'
    # Keep rare rewards away from start; place highland ruins where plausible.
    def jitter(i,kind):return (stable_u64(seed,kind,i)%100000)/100000
    ruins=sorted((i for i in range(N) if kinds[i]=='wild' and hop[i]>=2),
        key=lambda i:(.68*h[i]+.18*(1-wet[i])+.025*hop[i]+.12*jitter(i,'ruin')),reverse=True)
    if len(ruins)<12:ruins += [i for i in range(N) if kinds[i]=='wild' and i not in ruins]
    for i in ruins[:12]:kinds[i]='ruins'
    dungeons=sorted((i for i in range(N) if kinds[i]=='wild' and hop[i]>=3),
        key=lambda i:(.70*h[i]+.18*(1-wet[i])+.020*hop[i]+.12*jitter(i,'dungeon')),reverse=True)
    if len(dungeons)<10:dungeons += [i for i in range(N) if kinds[i]=='wild' and hop[i]>=2 and i not in dungeons]
    for i in dungeons[:10]:kinds[i]='dungeon_approach'
    return kinds,hop


def portal_placement(pa,pb,extent,seed,a,b):
    vector=pb-pa
    axis=0 if abs(vector[0])>=abs(vector[1]) else 1
    perp=1-axis
    direction=1 if vector[axis]>0 else -1
    offset=np.clip(vector[perp]/(abs(vector[axis])+1e-9)*extent*.25,-extent*.29,extent*.29)
    # A shared offset, never two independent portal rolls, and a mandatory clear buffer.
    value=[0.,0.];value[axis]=direction*(extent/2-2);value[perp]=float(offset)
    inverse=[0.,0.];inverse[axis]=-direction*(extent/2-2);inverse[perp]=float(-offset)
    return list(map(lambda v:round(v,3),value)),list(map(lambda v:round(v,3),inverse)),axis


def hydrology(seed,pts,h,wet,full):
    # A strictly downhill DAG for macro river routing; Delaunay geographic neighbors,
    # not necessarily roads. True watershed simulation is future work.
    downstream={}
    sinks=[]
    for i in range(N):
        lower=[j for j in full.neighbors(i) if h[j]<h[i]-1e-6]
        if lower:
            downstream[i]=min(lower,key=lambda j:(h[j],np.linalg.norm(pts[i]-pts[j])))
        else:downstream[i]=None;sinks.append(i)
    rainfall=np.clip(.2+.8*wet,0.03,1.0)
    flow=np.asarray(rainfall,dtype=float)
    for i in np.argsort(-h):
        dest=downstream[int(i)]
        if dest is not None:flow[dest]+=flow[i]
    rivers=[]
    for i in range(N):
        if downstream[i] is None:continue
        if flow[i]>2.3:
            rivers.append({'from':i,'to':downstream[i],'flow':round(float(flow[i]),3)})
    return [{'region':i,'to':downstream[i],'flow':round(float(flow[i]),3),'sink':downstream[i] is None} for i in range(N)],rivers


def plan(seed:int, extent=EXTENT, loops=26):
    pts=layout(seed)
    height,wet,temp=terrain_and_climate(pts,seed)
    full=candidate_graph(pts,height,wet)
    g=choose_routes(full,seed,loops)
    biomes=select_biomes(pts,height,wet,temp,g)
    permitted=[i for i in range(N) if height[i]<.63 and biomes[i] not in ('rocky_highlands','alpine') and g.degree(i)>=2]
    if not permitted:permitted=[i for i in range(N) if g.degree(i)>=2]
    spawn=min(permitted,key=lambda i:(abs(height[i]-.34)*1.4+.7*np.linalg.norm(pts[i]-[.5,.5])+.5*max(0,.38-wet[i])))
    kinds,hops=pick_categories(seed,pts,height,wet,biomes,g,spawn)
    regions=[]
    for i in range(N):
        r={'id':i,'center':[round(float(v),6) for v in pts[i]],
           'biome':biomes[i],'kind':kinds[i],
           'elevation':round(float(height[i]),5),'humidity':round(float(wet[i]),5),
           'temperature':round(float(temp[i]),5),'difficulty':min(6,1+hops[i]//3),
           'region_seed':stable_u64(seed,'region',i)&((1<<63)-1),'entrances':[],
           'biome_weights':{},'asset_palette':biomes[i]}
        regions.append(r)
    # Settlement scale is generated from actual graph access and terrain.
    # 4 cities, 7 towns and 12 villages are a subdivision of the 23 settlement
    # regions, not extra regions. Spawn identity is preserved as a home village.
    settlement_ids=[i for i,k in enumerate(kinds) if k=='settlement' and i!=spawn]
    ranked=sorted(settlement_ids,key=lambda i:(g.degree(i)*2,
        len(nx.single_source_shortest_path_length(g,i,cutoff=3)),
        -abs(float(height[i])-.38),stable_u64(seed,'rank',i)),reverse=True)
    # Select additional 1 hub if the spawn happens to be a city-qualified site.
    for rank,i in enumerate(ranked):
        regions[i]['settlement_scale']='city' if rank<4 else 'town' if rank<11 else 'village'
    regions[spawn]['settlement_scale']='village'
    for r in regions:
        if r['kind']=='ruins':r['site_variant']=['fallen_temple','ancient_fort','forgotten_shrine'][stable_u64(seed,'ruins',r['id'])%3]
        elif r['kind']=='dungeon_approach':r['site_variant']=['cave_entrance','crypt','cliff_gate'][stable_u64(seed,'dungeon',r['id'])%3]
        elif r['kind']=='wild':r['site_variant']=['field','hunting_ground','scenic_ruins','river_crossing'][stable_u64(seed,'wild',r['id'])%4]
    ports=[]
    for a,b in sorted((min(a,b),max(a,b)) for a,b in g.edges()):
        z=stable_u64(seed,'portal',a,b)
        width=(6,8,10,12)[z%4]
        off_a,off_b,axis=portal_placement(pts[a],pts[b],extent,seed,a,b)
        # 12 meters of reserve corridor each side; elevation is identical by contract.
        gate_height=round(float(6+25*min(height[a],height[b])),3)
        pid=f'gate_{a:02}_{b:02}'
        p={'id':pid,'a':a,'b':b,'from_a':off_a,'from_b':off_b,
           'axis':axis,'width_m':width,'height_m':gate_height,
           'clear_radius_m':14,'preload_distance_m':42,
           'direction_a_to_b':'opposite_facing','transit':'fade_or_stream'}
        ports.append(p)
        regions[a]['entrances'].append({'gate_id':pid,'neighbor':b,'xz':off_a})
        regions[b]['entrances'].append({'gate_id':pid,'neighbor':a,'xz':off_b})
    # Physical gate reservations: no two entrances may overlap along the same
    # border, even when both adjacent regions lie in roughly one direction.
    portal_by_id={p['id']:p for p in ports}
    for region in regions:
        groups={}
        for entry in region['entrances']:
            pos=entry['xz'];axis=0 if abs(pos[0])>=abs(pos[1]) else 1
            side=(axis,1 if pos[axis]>0 else -1)
            groups.setdefault(side,[]).append(entry)
        for (axis,sign),items in groups.items():
            if len(items)<=1:continue
            other=1-axis
            items.sort(key=lambda e:e['xz'][other])
            orig=[e['xz'][other] for e in items]
            mid=float(sum(orig)/len(orig))
            minsep=30.0
            mid=max(-(extent*.34)+(len(items)-1)*minsep/2,
                    min((extent*.34)-(len(items)-1)*minsep/2,mid))
            for k,e in enumerate(items):
                coord=round(mid+(k-(len(items)-1)/2)*minsep,3)
                e['xz'][other]=coord
                p=portal_by_id[e['gate_id']]
                key='from_a' if p['a']==region['id'] else 'from_b'
                p[key][other]=coord
    # Nearby gates on the same border require compatible shared elevations.
    # Otherwise two overlapping road corridors would demand incompatible
    # heights even though their portal coordinates were separated.
    parent={p['id']:p['id'] for p in ports}
    def find_gate(x):
        while parent[x]!=x:
            x=parent[x]
        return x
    def union_gate(a,b):
        ra,rb=find_gate(a),find_gate(b)
        if ra!=rb:parent[max(ra,rb)]=min(ra,rb)
    for region in regions:
        groups={}
        for entry in region['entrances']:
            pos=entry['xz'];axis=0 if abs(pos[0])>=abs(pos[1]) else 1
            side=(axis,1 if pos[axis]>0 else -1)
            groups.setdefault(side,[]).append(entry)
        for (axis,sign),items in groups.items():
            items=sorted(items,key=lambda e:e['xz'][1-axis])
            for a,b in zip(items,items[1:]):
                if abs(a['xz'][1-axis]-b['xz'][1-axis])<70:
                    union_gate(a['gate_id'],b['gate_id'])
    clusters={}
    for p in ports:clusters.setdefault(find_gate(p['id']),[]).append(p)
    for cluster in clusters.values():
        if len(cluster)<2:continue
        level=round(sum(p['height_m'] for p in cluster)/len(cluster),3)
        for p in cluster:p['height_m']=level
    # Palette transitions are shared *contracts*, not locally guessed after
    # loading. Rendering may choose autotile masks/shaders for their boundary.
    for p in ports:
        ba=regions[p['a']]['biome'];bb=regions[p['b']]['biome']
        p['boundary_palette']={'a':ba,'b':bb,
          'transition_width_m':0 if ba==bb else 48,
          'autotile':'dual_grid_terrain' if ba!=bb else 'native'}
    hydro,rivers=hydrology(seed,pts,height,wet,full)
    for r in regions:
        near=collections.Counter(regions[e['neighbor']]['biome'] for e in r['entrances'])
        foreign=[(b,c) for b,c in near.items() if b!=r['biome']]
        if foreign:
            secondary=max(foreign,key=lambda a:(a[1],-stable_u64(seed,'ecotone',r['id'],a[0])%10000))[0]
            r['biome_weights']={r['biome']:.8,secondary:.2}
        else:r['biome_weights']={r['biome']:1.0}
        r['entrances'].sort(key=lambda e:e['neighbor'])
    return {'version':2,'algorithm':'EXO_WORLD_GENESIS_LAB_2','seed':seed,
       'region_count':N,'region_extent_m':extent,'start_region':spawn,
       'regions':regions,'portals':ports,'hydrology_macro':hydro,'rivers_macro':rivers,
       'quotas':QUOTAS,'caveat':'Logical atlas only. No runtime Godot collision, full rivers, real structures or region streaming.'}


def validate(doc):
    r=doc['regions'];ports=doc['portals'];g=nx.Graph();g.add_nodes_from(range(N))
    g.add_edges_from((p['a'],p['b']) for p in ports)
    counts=collections.Counter(x['kind'] for x in r)
    biomecounts=collections.Counter(x['biome'] for x in r)
    start=doc['start_region'];dist=nx.single_source_shortest_path_length(g,start)
    settlements={x['id'] for x in r if x['kind']=='settlement'}
    dungeons={x['id'] for x in r if x['kind']=='dungeon_approach'}
    sources=nx.multi_source_dijkstra_path_length(g,settlements,weight=None)
    nearservices=max(sources.values())
    portal_ids=[p['id'] for p in ports]
    gates_symmetric=True
    gates_separated=True
    for node in r:
        sides={}
        for entry in node['entrances']:
            pos=entry['xz'];axis=0 if abs(pos[0])>=abs(pos[1]) else 1
            side=(axis,1 if pos[axis]>0 else -1)
            sides.setdefault(side,[]).append(pos[1-axis])
        if any(min(abs(a-b) for idx,a in enumerate(values) for b in values[idx+1:])<24 for values in sides.values() if len(values)>1):
            gates_separated=False;break
    for p in ports:
        ea=[e for e in r[p['a']]['entrances'] if e['gate_id']==p['id']]
        eb=[e for e in r[p['b']]['entrances'] if e['gate_id']==p['id']]
        if len(ea)!=1 or len(eb)!=1 or ea[0]['neighbor']!=p['b'] or eb[0]['neighbor']!=p['a']:
            gates_symmetric=False;break
        if abs(ea[0]['xz'][p['axis']]+eb[0]['xz'][p['axis']])>.001:gates_symmetric=False;break
    downstream={x['region']:x['to'] for x in doc['hydrology_macro']}
    checks={
       'exact_88':len(r)==N,
       'quotas':dict(counts)==QUOTAS,
       'connected':nx.is_connected(g),
       'multiple_loops':g.number_of_edges()>=N+19,
       'max_four_exits':max(dict(g.degree()).values())<=4,
       'safe_spawn':r[start]['kind']=='settlement' and r[start]['biome'] not in ('alpine','rocky_highlands'),
       'dungeons_far_from_spawn':all(dist[x]>=2 for x in dungeons),
       'services_within_4_hops':nearservices<=4,
       'minimum_six_biomes':len(biomecounts)>=6,
       'biome_concentration_below_40_percent':max(biomecounts.values())<=35,
       'gate_ids_unique':len(set(portal_ids))==len(portal_ids),
       'gate_pairs_symmetric':gates_symmetric,
       'gates_nonoverlapping_per_side':gates_separated,
       'finite_height_climate':all(all(math.isfinite(x[k]) for k in ('elevation','humidity','temperature')) for x in r),
       'settlement_subtypes_4_7_12':collections.Counter(x.get('settlement_scale') for x in r if x['kind']=='settlement')=={'city':4,'town':7,'village':12},
       'biome_weight_sum_1':all(abs(sum(x['biome_weights'].values())-1)<1e-8 for x in r),
       'shared_border_palettes':all(p['boundary_palette']['a']==r[p['a']]['biome'] and p['boundary_palette']['b']==r[p['b']]['biome'] for p in ports),
       'downhill_drainage':all(t is None or r[t]['elevation']<r[i]['elevation']+1e-4 for i,t in downstream.items()),
       'river_edges_downhill':all(r[x['to']]['elevation']<r[x['from']]['elevation']+1e-4 for x in doc['rivers_macro']),
    }
    return {'ok':all(checks.values()),'checks':checks,'links':len(ports),'cycles':len(ports)-N+1,
            'biomes':dict(biomecounts),'max_biome_count':max(biomecounts.values()),
            'nearservices_hops_max':nearservices,'rivers':len(doc['rivers_macro'])}


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--seed',type=int,default=816204)
    ap.add_argument('--output',default='world_seed_816204.json');args=ap.parse_args()
    t=time.perf_counter();w=plan(args.seed);result=validate(w);assert result['ok'],result
    Path(args.output).write_text(json.dumps(w,ensure_ascii=False,indent=2))
    print(json.dumps({'ms':round((time.perf_counter()-t)*1000,2),'result':result},indent=2))
if __name__=='__main__':main()
