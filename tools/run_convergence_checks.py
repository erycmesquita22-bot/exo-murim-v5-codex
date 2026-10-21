#!/usr/bin/env python3
"""Godot 4.6.2 runtime gate. Every PASS requires execution and clean engine output."""
import pathlib,subprocess,json,sys,time
root=pathlib.Path(__file__).resolve().parents[1]
engine=sys.argv[1]
out=root/'convergence/validation';out.mkdir(exist_ok=True)
rows=[]
suites=[('import',['--editor','--import','--quit']),('forja',['--script','res://qa/run_headless.gd']),('living',['--script','res://living_world/tests/qa_living_world.gd']),('settlements',['--script','res://tests/settlement_core.gd','--','50']),('extremes',['--script','res://tests/settlement_extreme.gd','--','10000']),('terrain',['--script','res://tests/physics_surfaces.gd']),('integration',['--script','res://convergence/qa.gd']),('reopen',['--script','res://convergence/reopen.gd']),('combat',['--script','res://convergence/encounter_qa.gd']),('pilot_walk',['--script','res://convergence/pilot_walk.gd'])]
for name,args in suites:
 start=time.monotonic()
 try:
  result=subprocess.run([engine,'--headless','--fixed-fps','60','--path',str(root),*args],capture_output=True,text=True,timeout=600)
  text=result.stdout+result.stderr
  ok=result.returncode==0 and not any(x in text for x in ['SCRIPT ERROR','ERROR:','FAIL ','FALHOU'])
 except subprocess.TimeoutExpired as e:
  text=(e.stdout or b'').decode(errors='replace')+'\nTIMEOUT';ok=False
 (out/(name+'.log')).write_text(text)
 rows.append({'suite':name,'status':'PASS' if ok else 'FAIL','seconds':time.monotonic()-start})
 print(rows[-1],flush=True)
(out/'summary.json').write_text(json.dumps(rows,indent=2))
sys.exit(0 if all(r['status']=='PASS' for r in rows) else 1)
