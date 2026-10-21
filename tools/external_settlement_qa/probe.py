"""External geometric mirror of settlement_planner.gd for independent failure discovery.
NOT a run of the GDScript program or Godot terrain; terrain sampled using synthetic stress models.
"""
from __future__ import annotations
import math, random, hashlib, json, collections, time, sys
from pathlib import Path
H=256
SCALES={'village':(4,10),'town':(12,26),'city':(35,48)}
def vec(a,b):return (a[0]-b[0],a[1]-b[1])
def add(a,b):return (a[0]+b[0],a[1]+b[1])
def mul(a,k):return (a[0]*k,a[1]*k)
def dot(a,b):return a[0]*b[0]+a[1]*b[1]
def norm(a):return math.hypot(*a)
def nearest(p,a,b):
    v=vec(b,a);vv=dot(v,v)
    t=max(0,min(1,dot(vec(p,a),v)/vv)) if vv else 0
    return add(a,mul(v,t))
def dist_seg(p,a,b):return norm(vec(p,nearest(p,a,b)))
def terrain_factory(seed,biome,mode):
    rng=random.Random(seed);ang=rng.random()*6.28;ox=rng.uniform(-100,100);oz=rng.uniform(-100,100)
    amp={'grassland':4,'temperate_forest':4,'bamboo_forest':4,'dry_valley':4,'wetland':4,'rocky_highlands':32,'alpine':52,'mixed_woodland':4}.get(biome,4)
    if mode=='flat':amp=0
    if mode=='moderate':amp=min(amp,8)
    if mode=='steep':amp=max(amp,30)
    if mode=='extreme':amp=max(amp,52)
    def sample(p):
        x,y=p
        # Approximation deliberately not asserted to be Godot's FastNoiseLite.
        n=(.68*math.sin((x+ox)*.012)*math.cos((y+oz)*.013)+.32*math.cos(x*.026+ang)*math.sin(y*.018+ang))
        res=8+amp*n
        if amp>10:res+=amp*math.exp(-((x-H*.58)/45)**2)*(.7+.3*math.sin(y*.015))
        return res
    return sample

def plan(scale, seed, gates, rivers, terrain, half=256, hub=(72,72), recovery=False):
    rng=random.Random(seed)
    target=rng.randint(*SCALES[scale]);forward=mul(gates[0],1/norm(gates[0]));side=(-forward[1],forward[0]); spacing=21 if scale=='village' else 22
    reach={'village':103,'town':103,'city':145}[scale] if recovery else {'village':70,'town':103,'city':145}[scale]
    roads=[(mul(forward,-reach),mul(forward,reach)),(mul(side,-reach),mul(side,reach))]
    if scale in ('town','city') or (recovery and scale=='village' and (len(gates)>=3 or len(rivers)>=2)):
        for direction in (-1,1):
            offset=mul(side,spacing*2*direction);roads.append((add(offset,mul(forward,-reach)),add(offset,mul(forward,reach))))
    if scale=='city':
        for direction in (-1,1):
            offset=mul(forward,spacing*2*direction);roads.append((add(offset,mul(side,-reach)),add(offset,mul(side,reach))))
    well=None
    if recovery:
        for radius in (28.,35.,44.,54.,65.,76.,88.):
            for k in range(16):
                ang=math.pi*.25+math.tau*k/16
                wp=add(mul(forward,radius*math.cos(ang)),mul(side,radius*math.sin(ang)))
                if abs(wp[0])>half-16 or abs(wp[1])>half-16:continue
                if min(dist_seg(wp,(0,0),g) for g in gates)<18.5:continue
                if rivers and min(dist_seg(wp,hub,r) for r in rivers)<14:continue
                rd, sp=min((dist_seg(wp,a,b),nearest(wp,a,b)) for a,b in roads)
                if rd<7 or rd>26:continue
                vals=[terrain(add(wp,d)) for d in ((0,0),(-5,-5),(5,-5),(5,5),(-5,5))]
                if max(vals)-min(vals)>8:continue
                well={'p':wp,'halfsize':2.5,'street_point':sp}
                break
            if well:break
        if not well:return {'ready':False,'target':target,'lots':[],'stats':collections.Counter({'no_safe_well_site':1}),'streets':roads,'well':None}
    candidates=[];limit=({'village':6,'town':6,'city':7} if recovery else {'village':5,'town':6,'city':7})[scale]
    for gx in range(-limit,limit):
        for gy in range(-limit,limit):
            p=add(mul(side,(gx+.5)*spacing),mul(forward,(gy+.5)*spacing))
            score=dot(p,p)+rng.uniform(-140,140)
            candidates.append((score,gx,gy,p))
    candidates.sort(key=lambda x:(x[0],x[1]*50+x[2]))
    lots=[];pad=5.5;stats=collections.Counter()
    for cutoff in (1.25,3.5,8.):
        for _,gx,gy,p in candidates:
            if len(lots)>=target:break
            if norm(p)<22 or abs(p[0])>half-24 or abs(p[1])>half-24:stats['bounds']+=1;continue
            if min(dist_seg(p,(0,0),g) for g in gates)<pad+12:stats['gates']+=1;continue
            if rivers and min(dist_seg(p,hub,r) for r in rivers)<pad+11:stats['rivers']+=1;continue
            if any(norm(vec(p,L['p']))<pad+L['halfsize']+5 for L in lots):stats['occupied']+=1;continue
            if recovery:
                if norm(vec(p,well['p']))<pad+well['halfsize']+3:stats['well_overlap']+=1;continue
                if dist_seg(p,well['p'],well['street_point'])<pad+well['halfsize']+1:stats['well_access']+=1;continue
            best=(float('inf'),None,None)
            for ra,rb in roads:
                q=nearest(p,ra,rb);d=norm(vec(p,q))
                if d<best[0]:best=d,q,(ra,rb)
            if best[0]<pad+3.5 or best[0]>29:stats['street']+=1;continue
            vals=[terrain(add(p,d)) for d in ((0,0),(-5,-5),(5,-5),(5,5),(-5,5))]
            spread=max(vals)-min(vals)
            if spread>cutoff:stats['slope']+=1;continue
            toward=mul(vec(best[1],p),1/norm(vec(best[1],p)))
            door=add(p,mul(toward,pad+.6))
            if any(dist_seg(L['p'],door,best[1])<L['halfsize']+1 for L in lots):stats['access']+=1;continue
            if recovery:
                if dist_seg(well['p'],door,best[1])<well['halfsize']+1:stats['well_blocks_access']+=1;continue
                if any(dist_seg(p,L['door'],L['street_point'])<pad+1 for L in lots):stats['blocks_prior_access']+=1;continue
            lots.append({'p':p,'door':door,'street_point':best[1],'frontage':best[0],'halfsize':pad,'spread':spread})
        if len(lots)>=target:break
    return {'ready':len(lots)==target,'target':target,'lots':lots,'stats':stats,'streets':roads,'well':well}

def random_gates(rng,n):
    pts=[]
    for _ in range(n):
        axis=rng.randint(0,1);sgn=rng.choice([-1,1]);offset=rng.uniform(-148,148)
        p=[0,0];p[axis]=254*sgn;p[1-axis]=offset;pts.append(tuple(p))
    return pts

def probe(n=10000, output=None, start=0):
    atlas_path=str(Path(__file__).resolve().parents[2] / 'evidence/native_atlas_seed101.json')
    atlas=json.load(open(atlas_path));contracts={p['id']:p for p in atlas['portals']}
    collected=[]
    for r in atlas['regions']:
        if r['kind']!='settlement':continue
        gates=[tuple(e['xz']) for e in r['entrances']]
        rivers=[]
        for edge in atlas['rivers_macro']:
            if edge['from']!=r['id'] and edge['to']!=r['id']:continue
            nb=atlas['regions'][edge['to'] if edge['from']==r['id'] else edge['from']]
            delta=(nb['center'][0]-r['center'][0],nb['center'][1]-r['center'][1])
            axis=0 if abs(delta[0])>=abs(delta[1]) else 1
            p=[0.,0.];p[axis]=(-1 if delta[axis]<0 else 1)*H
            p[1-axis]=max(-148,min(148,delta[1-axis]/abs(delta[axis])*100))
            rivers.append(tuple(p))
        collected.append((r['settlement_scale'],r['biome'],gates,rivers,'real_atlas_101_r%02d'%r['id']))
    aggregate=collections.Counter();reasons=collections.Counter();examples=[];samples=[];t0=time.perf_counter()
    for i in range(start,start+n):
        rng=random.Random(198617+7919*i)
        if i<len(collected):
            scale,biome,gates,rivers,label=collected[i];mode='normal'
        else:
            scale=rng.choice(list(SCALES))
            biome=rng.choice(['grassland','temperate_forest','bamboo_forest','dry_valley','wetland','rocky_highlands','alpine','mixed_woodland'])
            mode=rng.choices(['flat','normal','moderate','steep','extreme'],[1,6,2,2,1])[0]
            gates=random_gates(rng,rng.randint(1,4))
            rivers=[rng.choice(random_gates(rng,1)) for _ in range(rng.randint(0,3))]
            label=f'synth_{i}'
        sample=terrain_factory(i,biome,mode)
        result=plan(scale, i*7919+2003, gates,rivers,sample,recovery=True)
        aggregate['total']+=1;aggregate[f'{scale}_total']+=1;aggregate[f'{mode}_total']+=1
        reasons.update(result['stats'])
        if result['ready']:
            aggregate['ready']+=1;aggregate[f'{scale}_ready']+=1;aggregate[f'{mode}_ready']+=1
        else:
            aggregate['invalid']+=1;aggregate[f'{scale}_invalid']+=1;aggregate[f'{mode}_invalid']+=1
            missing=result['target']-len(result['lots'])
            aggregate['missing_lots']+=missing
            if len(examples)<24:examples.append({'case':label,'scale':scale,'biome':biome,'mode':mode,'gates':gates,'rivers':rivers,'target':result['target'],'actual':len(result['lots']),'rejects':dict(result['stats'])})
        if i<6:samples.append({'case':label,'scale':scale,'target':result['target'],'actual':len(result['lots'])})
    d={'engine':'EXTERNAL_PYTHON_MIRROR_NOT_GODOT','test_cases':n,'starting_index':start,'elapsed_s':round(time.perf_counter()-t0,2),'counts':dict(aggregate),'reject_reasons':dict(reasons),'failure_examples':examples,'real_atlas_cases':len(collected),'real_atlas_previews':samples}
    if output:Path(output).write_text(json.dumps(d,indent=2,ensure_ascii=False))
    print(json.dumps({k:v for k,v in d.items() if k not in ('reject_reasons','failure_examples')},indent=2))
    print('first failures:',examples[:5]);return d
if __name__=='__main__':probe(int(sys.argv[1]) if len(sys.argv)>1 else 10000,sys.argv[2] if len(sys.argv)>2 else None,int(sys.argv[3]) if len(sys.argv)>3 else 0)
