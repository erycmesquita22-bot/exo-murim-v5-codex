import time,sys,json,collections,traceback,hashlib,random
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from world_genesis_v2 import plan
from region_synth_v2 import generate,validate
now=time.perf_counter();errors=[];causes=collections.Counter();total=0;slopes=[];counts=[]
for seed in range(400):
 try:
  w=plan(seed)
  classes=('settlement','ruins','dungeon_approach')
  for cls in classes:
   rid=next(i for i,r in enumerate(w['regions']) if r['kind']==cls)
   rg=generate(w,rid,cells=96);check=validate(rg);total+=1
   slopes.append(check['max_road_grade_m']);counts.append(check['building_count'])
   if not check['ok']:
    errors.append({'seed':seed,'rid':rid,'cls':cls,'checks':check['checks'],'slope':check['max_road_grade_m']})
    for k,v in check['checks'].items():
     if not v:causes[k]+=1
 except Exception as e:
  errors.append({'seed':seed,'error':repr(e)});causes['exception']+=1
 if (seed+1)%100==0:print('worlds',seed+1,'generated regions',total,'failures',len(errors),'seconds',round(time.perf_counter()-now,1),flush=True)
r={'worlds':400,'region_samples':total,'failed_count':len(errors),'failed_checks':dict(causes),
 'max_road_grade_m':max(slopes),'min_buildings':min(counts),
 'failure_examples':errors[:20],'seconds':round(time.perf_counter()-now,2)}
Path(__file__).with_name('region_stress_results.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r,indent=2))
