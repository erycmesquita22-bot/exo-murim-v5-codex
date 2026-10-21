import time,sys,collections,statistics,json,hashlib,argparse
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from world_genesis_v2 import plan,validate
ap=argparse.ArgumentParser();ap.add_argument('--count',type=int,default=1000);ap.add_argument('--start',type=int,default=0);args=ap.parse_args()
start=time.perf_counter();failed=[];checks=collections.Counter();maxbiomes=[];biome_count=[];elapsed=[];badexamples=[];links=[];rivers=[];services=[]; signatures=set()
for n in range(args.count):
  seed=args.start+n;t=time.perf_counter()
  try:
    w=plan(seed);report=validate(w);elapsed.append((time.perf_counter()-t)*1000)
    maxbiomes.append(report['max_biome_count']);biome_count.append(len(report['biomes']));links.append(report['links']);rivers.append(report['rivers']);services.append(report['nearservices_hops_max'])
    if not report['ok']:
      failed.append(seed)
      for key,value in report['checks'].items():
        if not value:checks[key]+=1
      if len(badexamples)<25:badexamples.append({'seed':seed,'failed':[k for k,v in report['checks'].items() if not v], 'biomes':report['biomes']})
    if n<100:
      sig=hashlib.sha256(json.dumps(w,sort_keys=True).encode()).hexdigest();signatures.add(sig)
      if w!=plan(seed):raise AssertionError('nondeterministic')
  except Exception as e:
    failed.append(seed);checks['exception']+=1
    if len(badexamples)<25:badexamples.append({'seed':seed,'exception':repr(e)})
  if n%500==499:print('completed',n+1,'failures',len(failed),'seconds',round(time.perf_counter()-start,1),flush=True)
result={'count':args.count,'seed_start':args.start,'failed_count':len(failed),'error_rate_observed':len(failed)/args.count,
 'failed_seed_sample':failed[:30],'failed_checks':dict(checks),'failure_examples':badexamples,
 'biome_diversity':dict(collections.Counter(biome_count)),'max_biome_count':{'min':min(maxbiomes),'median':statistics.median(maxbiomes),'max':max(maxbiomes)},
 'connections':{'min':min(links),'max':max(links)},'rivers':{'min':min(rivers),'max':max(rivers),'median':statistics.median(rivers)},
 'nearservices_hops_max':max(services),'deterministic_100_seeds':len(signatures)==100,
 'milliseconds_per_world':{'mean':round(statistics.mean(elapsed),2),'median':round(statistics.median(elapsed),2),'p95':round(sorted(elapsed)[int(.95*len(elapsed))],2)},'total_seconds':round(time.perf_counter()-start,2)}
(Path(__file__).parent/'stress_results.json').write_text(json.dumps(result,indent=2,ensure_ascii=False))
print(json.dumps({k:v for k,v in result.items() if k not in ('failed_seed_sample','failure_examples')},indent=2,ensure_ascii=False))
