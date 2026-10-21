import sys,time,json,collections
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from world_genesis_v2 import plan,validate
from region_synth_v2 import generate,validate as validate_region
start=time.perf_counter();w=plan(816204); errors=[];bytype=collections.Counter();bad=[]
for rid in range(88):
 try:
  r=generate(w,rid,cells=112)
  v=validate_region(r)
  bytype[w['regions'][rid]['kind']]+=1
  if not v['ok']:errors.append({'region':rid,'checks':v['checks'],'maxgrade':v['max_road_grade_m']})
 except Exception as e:errors.append({'region':rid,'exception':repr(e)})
r={'seed':816204,'regions':88,'failed_count':len(errors),'categories':dict(bytype),'errors':errors[:30], 'time_seconds':round(time.perf_counter()-start,2)}
Path(__file__).with_name('test_full88_results.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r,indent=2))
