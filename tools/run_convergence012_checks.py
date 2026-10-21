#!/usr/bin/env python3
"""Run sequentially: python3 tools/run_convergence012_checks.py /path/to/godot.
Use --rendered for assets and the playable script, with a working display.
"""
import json,pathlib,subprocess,sys,time
root=pathlib.Path(__file__).resolve().parents[1]
engine=sys.argv[1];out=root/'convergence/validation012/final';out.mkdir(parents=True,exist_ok=True)
historical=['tests','release_qa','discovery_qa','fidelity_qa','consolidation_qa','ruins_martial_qa','stabilization_qa','quality09_qa','martial_qa','procedural_qa','legacy_audio_qa','war_qa','qa093','qa0932','qa0933','qa094','qa0942','qa0943','qa0944','qa0945','qa0946']
suites=[(n,['--script','res://'+n+'.gd']) for n in historical]
suites += [('living',['--script','res://living_world/tests/qa_living_world.gd']),('forja',['--script','res://qa/run_headless.gd']),('atlas',['--script','res://tests/plan_stress.gd']),('settlements',['--script','res://tests/settlement_core.gd','--','50']),('extremes',['--script','res://tests/settlement_extreme.gd','--','10000']),('surfaces',['--script','res://tests/physics_surfaces.gd']),('grades',['--script','res://tests/settlement_grades.gd']),('integration',['--script','res://convergence/qa.gd']),('reopen',['--script','res://convergence/reopen.gd']),('encounter',['--script','res://convergence/encounter_qa.gd']),('pilots',['--script','res://convergence/pilot_walk.gd'])]
suites += [('architecture012',['--script','res://convergence/architecture_qa.gd']),('roof012',['--script','res://convergence/roof_qa.gd']),('geometry012',['--script','res://convergence/geometry012.gd']),('materials012',['--script','res://convergence/material_qa.gd']),('routines012',['--script','res://convergence/routine_qa.gd']),('routine_reopen012',['--script','res://convergence/routine_reopen.gd'])]
if '--rendered' in sys.argv:suites=[('assets_rendered',['--script','res://assets_qa.gd']),('playable_rendered',['--script','res://convergence/legacy_playable.gd'])]
rows=[]
for name,args in suites:
 command=[engine,*([] if '--rendered' in sys.argv else ['--headless']),'--fixed-fps','60','--path',str(root),*args]
 t=time.monotonic();log=out/(name+'.log');code=-1
 with log.open('w') as f:
  try:code=subprocess.run(command,stdout=f,stderr=subprocess.STDOUT,timeout=900).returncode
  except subprocess.TimeoutExpired:f.write('\nTIMEOUT\n')
 s=log.read_text(errors='replace');ok=code==0 and not any(x in s for x in ['SCRIPT ERROR','ERROR:','FAIL ','FALHOU','leaked','still in use'])
 rows.append(dict(suite=name,status='PASS' if ok else 'FAIL',exit=code,seconds=time.monotonic()-t,command=command))
 (out/('rendered.json' if '--rendered' in sys.argv else 'summary.json')).write_text(json.dumps(rows,indent=2))
 print(name,rows[-1]['status'],round(rows[-1]['seconds'],2),flush=True)
sys.exit(int(not all(r['status']=='PASS' for r in rows)))
