#!/usr/bin/env python3
"""python tools/run_work_checkpoint_checks.py /path/to/Godot4.6.2
Runs isolated fixture saves. Does not measure hardware performance.
"""
from pathlib import Path
import subprocess,sys,json
root=Path(__file__).resolve().parents[1]
out=root/'WORK_CHECKPOINT'/'rerun';out.mkdir(parents=True,exist_ok=True)
engine=sys.argv[1]
scripts=['convergence/tests/qa_c03_r12_native.gd','convergence/tests/qa_c03_r13_bootstrap_native.gd','exo_core/tests/qa_persistence01p.gd','exo_items/tests/qa_atomic_r3_native.gd','exo_dungeon/tests/qa_c03_r6_native.gd','convergence/tests/qa_work_campaign.gd','convergence/tests/qa_work_dungeon.gd','convergence/tests/qa_work_jade.gd','convergence/tests/qa_work_world_scan.gd','convergence/tests/qa_work_road_corridors.gd']
rows=[]
for script in scripts:
 modes=[[],['--','--reopen']] if script.endswith(('qa_work_campaign.gd','qa_work_dungeon.gd')) else [[]]
 for extra in modes:
  args=[engine,'--headless','--path',str(root)]
  if script.endswith('qa_work_jade.gd'):args+=['--fixed-fps','5']
  args+=['--script',script]+extra
  name=Path(script).stem+('_reopen' if extra else '')
  try:
   r=subprocess.run(args,capture_output=True,text=True,timeout=240)
   output=r.stdout+r.stderr;status=r.returncode==0 and not any(t in output for t in ['SCRIPT ERROR','ERROR:','FAIL '])
  except subprocess.TimeoutExpired as ex:
   output=str(ex);status=False
  (out/(name+'.log')).write_text(output,encoding='utf-8')
  rows.append({'script':script,'reopen':bool(extra),'status':'PASS' if status else 'FAIL'})
  print(rows[-1],flush=True)
(out/'summary.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
sys.exit(0 if all(x['status']=='PASS' for x in rows) else 1)
