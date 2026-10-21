"""Independent postcondition checks of the synthetic EXO Settlement Genesis V05 mirror.
This tests a Python *approximation*, not GDScript/Godot engine behavior.
"""
import math, random, json, sys, time, collections
from pathlib import Path
from probe import SCALES,random_gates,terrain_factory,plan,dist_seg,norm,vec,add

def verify(result,gates,rivers,sample):
    issues=[];roads=result['streets'];lots=result['lots'];well=result['well']
    if not result['ready']:return issues
    if len(lots)!=result['target']:issues.append('count')
    if well is None:issues.append('missing_well');return issues
    p=well['p']
    if not math.isfinite(p[0]+p[1]):issues.append('nonfinite_well')
    if min(dist_seg(p,(0.,0.),g) for g in gates)<18.5-1e-7:issues.append('well_gate')
    if rivers and min(dist_seg(p,(72.,72.),r) for r in rivers)<14-1e-7:issues.append('well_river')
    road_dist=min(dist_seg(p,a,b) for a,b in roads)
    if road_dist<7-1e-7 or road_dist>26+1e-7:issues.append('well_road_range')
    if max(abs(p[0]),abs(p[1]))>240:issues.append('well_bounds')
    for k,L in enumerate(lots):
        q=L['p'];pad=L['halfsize']
        if not math.isfinite(q[0]+q[1]):issues.append('nonfinite_lot')
        if max(abs(q[0]),abs(q[1]))>232:issues.append('lot_bounds')
        if min(dist_seg(q,(0,0),g) for g in gates)<pad+12-1e-7:issues.append('lot_gate')
        if rivers and min(dist_seg(q,(72,72),r) for r in rivers)<pad+11-1e-7:issues.append('lot_river')
        if min(dist_seg(q,a,b) for a,b in roads)<pad+3.5-1e-7:issues.append('lot_over_road')
        if norm(vec(q,p))<pad+well['halfsize']+3-1e-7:issues.append('well_overlap')
        if dist_seg(q,p,well['street_point'])<pad+well['halfsize']+1-1e-7:issues.append('well_route_blocked')
        if dist_seg(p,L['door'],L['street_point'])<well['halfsize']+1-1e-7:issues.append('well_blocks_door')
        if norm(vec(L['door'],L['street_point']))>29-6.1+1e-7:issues.append('door_distance')
        for j,M in enumerate(lots):
            if j==k:continue
            m=M['p']
            if norm(vec(q,m))<pad+M['halfsize']+5-1e-7:issues.append('parcel_overlap')
            if dist_seg(m,L['door'],L['street_point'])<M['halfsize']+1-1e-7:issues.append('path_blocked')
    return issues

def run(n,start=0,out=None):
    t0=time.monotonic();c=collections.Counter();examples=[]
    for i in range(start,start+n):
        rng=random.Random(198617+7919*i)
        scale=rng.choice(list(SCALES))
        biome=rng.choice(['grassland','temperate_forest','bamboo_forest','dry_valley','wetland','rocky_highlands','alpine','mixed_woodland'])
        mode=rng.choices(['flat','normal','moderate','steep','extreme'],[1,6,2,2,1])[0]
        gates=random_gates(rng,rng.randint(1,4))
        rivers=[rng.choice(random_gates(rng,1)) for _ in range(rng.randint(0,3))]
        sample=terrain_factory(i,biome,mode)
        data=plan(scale,i*7919+2003,gates,rivers,sample,recovery=True)
        c['total']+=1
        if not data['ready']:
            c['explicit_invalid']+=1;continue
        c['ready']+=1;c['checked_lots']+=len(data['lots'])
        issues=verify(data,gates,rivers,sample)
        if issues:
            c['failing_ready']+=1
            c.update('issue_'+x for x in set(issues))
            if len(examples)<20:examples.append({'index':i,'issues':issues[:10],'scale':scale,'lots':len(data['lots'])})
        # Contract reproducibility within this Python model (not native Godot RNG).
        if i%157==0:
            b=plan(scale,i*7919+2003,gates,rivers,sample,recovery=True)
            if (b['ready'],b['target'],[x['p'] for x in b['lots']],b['well'])!=(data['ready'],data['target'],[x['p'] for x in data['lots']],data['well']):
                c['non_deterministic']+=1
    result={'kind':'EXTERNAL_SYNTHETIC_PROPERTIES_NOT_GODOT','count':dict(c),'duration_sec':round(time.monotonic()-t0,2),'examples':examples,'start':start}
    if out:Path(out).write_text(json.dumps(result,indent=2,ensure_ascii=False))
    print(json.dumps(result,ensure_ascii=False));return result
if __name__=='__main__':run(int(sys.argv[1]) if len(sys.argv)>1 else 2000,int(sys.argv[2]) if len(sys.argv)>2 else 0,sys.argv[3] if len(sys.argv)>3 else None)
