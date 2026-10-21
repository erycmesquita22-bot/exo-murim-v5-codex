#!/usr/bin/env python3
"""Run the REAL Godot suites: python tools/run_genesis_qa.py /path/to/Godot [--render]."""
from pathlib import Path
import subprocess,sys,json
root=Path(__file__).resolve().parents[1]
engine=sys.argv[1]
rows=[]
suites=[('import',['--headless','--editor','--import','--quit']),('atlas_io',['--headless','--script','tests/atlas_io.gd']),('stress',['--headless','--script','tests/plan_stress.gd','--','2048']),('contracts_first',['--headless','--script','tests/contracts.gd']),('contracts_reopen',['--headless','--script','tests/contracts.gd']),('physics',['--headless','--fixed-fps','60','--script','tests/physics_surfaces.gd']),('walk',['--headless','--fixed-fps','60','--script','tests/playable.gd']),('walk_preloaded',['--headless','--fixed-fps','60','--script','tests/playable.gd','--','preload'])]
if '--render' in sys.argv:
 suites += [('captures',['--script','tests/playable.gd','--','capture']),('benchmark',['--script','tests/benchmark_genesis.gd'])]
for name,args in suites:
 try:
  r=subprocess.run([engine,'--path',str(root),'--audio-driver','Dummy',*args],capture_output=True,text=True,timeout=600)
  output=r.stdout+r.stderr
  ok=r.returncode==0 and not any(marker in output for marker in ['SCRIPT ERROR','ERROR:','FAIL '])
  (root/'evidence'/('rerun-'+name+'.log')).write_text(output)
 except subprocess.TimeoutExpired:
  ok=False
 rows.append({'name':name,'passed':ok});print(('PASS ' if ok else 'FAIL ')+name,flush=True)
 if not ok:break
(root/'evidence/rerun-summary.json').write_text(json.dumps(rows,indent=2))
sys.exit(0 if rows and all(r['passed'] for r in rows) else 1)
