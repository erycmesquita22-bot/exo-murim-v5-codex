"""EXO Fortifications 01 - massive deterministic stress test for independent reference planner.
Run: python tools/stress_fortifications.py --cases 30000
This DOES NOT execute GDScript/Godot and must not be described as in-engine QA.
"""
import argparse,random,math,json,time,sys,collections
from pathlib import Path
from fortification_reference import plan,validate,digest,length,sub,dpointseg

def region(case,scale,hard=False):
 rng=random.Random(0xA51E+(case*982451653))
 theta=rng.uniform(-math.pi,math.pi);forward=(math.sin(theta),math.cos(theta));side=(-forward[1],forward[0]);origin=(0,0)
 def p(u,v):return (round(u*side[0]+v*forward[0],7),round(u*side[1]+v*forward[1],7))
 step=22. if scale=='city' else 18.
 reach=145. if scale=='city' else 72. if scale=='town' else 54.
 streets=[{'a':p(0,-reach),'b':p(0,reach),'width':7.,'kind':'main'},
          {'a':p(-reach,0),'b':p(reach,0),'width':5.,'kind':'cross'}]
 if scale in ('city','town'):
  for v in (-2*step,2*step):streets.append({'a':p(v,-reach),'b':p(v,reach),'width':4.5,'kind':'side_street'})
 if scale=='city':
  for v in (-2*step,2*step):streets.append({'a':p(-reach,v),'b':p(reach,v),'width':4.5,'kind':'market_street'})
 count=rng.randint(*( (35,48) if scale=='city' else (12,26) if scale=='town' else (4,10)))
 lots=[];pool=[]
 if scale=='city':
  # Real planner places 11m lots on an 22m grid near civic roads; select similar placements.
  for x in range(-5,5):
   for y in range(-5,5):
    if abs(x)+abs(y)<1:continue
    pool.append((x*22+11.,y*22+11.))
 else:
  for x in range(-4,5):
   for y in range(-4,5):
    if abs(x)+abs(y)<1:continue
    pool.append((x*18+9.,y*18+9.))
 rng.shuffle(pool)
 for i,(u,v) in enumerate(pool[:count]):
  pos=p(u,v);target=min(streets,key=lambda s: dpointseg(pos,s['a'],s['b']))
  a=target['a'];b=target['b'];vx=b[0]-a[0];vy=b[1]-a[1]
  t=max(0.,min(1.,((pos[0]-a[0])*vx+(pos[1]-a[1])*vy)/(vx*vx+vy*vy)))
  foot=(a[0]+t*vx,a[1]+t*vy);dist=length(sub(pos,foot));dd=sub(foot,pos);m=max(1e-9,length(dd));door=(pos[0]+dd[0]/m*6.1,pos[1]+dd[1]/m*6.1)
  lots.append({'id':f'r{case%88:02d}_l{i:03d}','p':pos,'halfsize':5.5,'frontage':dist,'door':door,'street_point':foot,'function':'farmstead' if i==0 else 'inn' if scale=='town' and i==1 else 'residence'})
 gate_count=rng.randint(2,4)
 gates=[]
 for k in range(gate_count):
  ang=theta+2*math.pi*k/gate_count+rng.uniform(-.35,.35)
  ga=(math.sin(ang)*256,math.cos(ang)*256)
  gates.append({'p':ga,'width':float(rng.choice([6,8,10])),'id':f'portal{k}'})
 rivers=[]
 if rng.random()<(0.42 if hard else .25):
  ang=rng.uniform(-math.pi,math.pi)
  rivers.append({'p':(math.sin(ang)*256,math.cos(ang)*256)})
 height_seed=rng.randint(0,999999)
 if hard:amp=rng.choice([0,1.5,5.,10.,25.]);freq=rng.choice([.02,.07,.25,.7])
 else:amp=rng.choice([0,.12,.45,1.5]);freq=rng.choice([.02,.04,.08])
 def terrain(pt):
  x,y=pt
  # No engineered city terrace on adversarial inputs, for extreme slope handling.
  relief=amp*(math.sin(x*freq+height_seed*.01)*math.cos(y*freq+.13))
  relief+=amp*.33*math.sin(x*.11+y*.15+height_seed)
  if not hard and scale=='city':relief*=max(0.,min(1.,(math.hypot(x,y)-150)/28))
  return 12.+relief
 return {'ready':True,'region_id':case%88,'scale':scale,'lots':lots,'streets':streets,'fixtures':[{'p':p(12.,12.),'halfsize':2.5}],
         'gates':gates,'rivers':rivers,'river_hub':(72.,72.),'half_extent':256.,'height':terrain}

def run(cases,start=0,universe=20000):
 now=time.perf_counter();errs=[];counts=collections.Counter();segments=0;gates=0;towers=0;assertions=0;maxsegments=0;first_examples={}
 samples=[]
 # Mixed realistic and adversarial: last 10% has violent slope and river/road tangencies.
 for local_i in range(cases):
  i=start+local_i
  scale=('city','town','village')[i%3]
  hard=i>=universe*9//10
  data=region(i,scale,hard=hard)
  p=plan(data);status=p['status'];counts[(scale,status)]+=1
  if status not in ('ready','partial','skipped','invalid'):errs.append((i,'invalid_status',status))
  if status in ('ready','partial'):
   violations=validate(data,p)
   assertions+=len(p['segments'])*4+len(data['lots'])+len(p['openings'])*3
   if violations:errs.append((i,'invalid_geometry',violations[:5]))
   segments+=len(p['segments']);gates+=len([x for x in p['openings'] if x['type']=='gate']);towers+=len(p['towers']);maxsegments=max(maxsegments,len(p['segments']))
   if p.get('skipped',{}).get('steep'):counts[('steep_cut',scale)]+=1
  elif status=='invalid':
   if p['errors'] not in (['no_valid_wall_segments'],):errs.append((i,'unexpected_invalid',p['errors']))
   else:counts[('explicit_rejection',scale)]+=1; assertions+=1
  # Proven reproducibility without global RNG
  if i%19==0:
   a=digest(p);b=digest(plan(data));assertions+=1
   if a!=b:errs.append((i,'non_deterministic',a,b))
  if i%40==0:
   samples.append({'case':i,'scale':scale,'status':status,'segments':len(p['segments']),
                   'openings':len(p['openings']),'towers':len(p['towers']), 'errors':p['errors']})
  if errs and len(errs)>=30:break
 elapsed=time.perf_counter()-now
 result={'title':'EXO-FORTIFICACOES-01-MASSIVE-OFFLINE-REFERENCE','scope':'Python geometric reference model; NOT Godot/GDScript runtime','cases_requested':cases,'case_start':start,'cases_executed':local_i+1,
         'invariants_checked_approx':assertions,'geometry_errors':len(errs),'sample_errors':errs[:30],
         'counts':{str(k):v for k,v in counts.items()},'wall_segments':segments,'road_gates':gates,'towers':towers,
         'maximum_wall_segments_in_case':maxsegments,'elapsed_s':round(elapsed,2),'samples':samples[:120],
         'status':'PASS' if not errs and local_i+1==cases else 'FAIL'}
 return result

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--cases',type=int,default=30000);parser.add_argument('--start',type=int,default=0);parser.add_argument('--universe',type=int,default=30000);parser.add_argument('--output',default='results/QA-FORTIFICACOES-01.json');a=parser.parse_args()
 r=run(a.cases,a.start,a.universe);Path(a.output).parent.mkdir(parents=True,exist_ok=True);Path(a.output).write_text(json.dumps(r,indent=2,ensure_ascii=False))
 print(json.dumps({k:v for k,v in r.items() if k not in ('samples',)},indent=2,ensure_ascii=False));sys.exit(0 if r['status']=='PASS' else 1)
