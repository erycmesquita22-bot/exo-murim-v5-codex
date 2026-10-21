"""Sequential native regression gate; pass the absolute Godot executable path."""
import json,pathlib,subprocess,sys,time
root=pathlib.Path(__file__).resolve().parents[2]
out=root/'cidade_viva'/'validation';out.mkdir(exist_ok=True)
suites=[n+'.gd' for n in ['tests','release_qa','discovery_qa','fidelity_qa','consolidation_qa','ruins_martial_qa','assets_qa','stabilization_qa','quality09_qa','martial_qa','procedural_qa','legacy_audio_qa','war_qa']]
suites+=['exo_core/tests/qa_core.gd','exo_core/tests/qa_new_module.gd','fortifications/qa_river_gate.gd','exo_visual/tests/qa_visual.gd','cidade_viva/tests/qa_live.gd','exo_core/tests/qa_integration.gd','validation_r3/npc_day.gd','validation_r3/npc_reopen.gd']
suites.insert(0,'cidade_viva/tests/qa_cidade_viva.gd')
suites.insert(1,'cidade_viva/tests/qa_flat_floor.gd')
suites=[s.replace('validation_r3/npc_day.gd','cidade_viva/tests/qa_day_fast.gd') for s in suites]
retry='--retry-failed' in sys.argv or '--resume' in sys.argv
rows=json.loads((out/'summary.json').read_text()) if retry and (out/'summary.json').exists() else []
if retry:
 passed={r['script'] for r in rows if r['status']=='PASS'}
 suites=[s for s in suites if s not in passed]
for script in suites:
 name=script.replace('/','_').removesuffix('.gd')
 cmd=[sys.argv[1],'--headless','--fixed-fps','5' if 'qa_day_fast' in script else '60','--audio-driver','Dummy','--path',str(root),'--script','res://'+script]
 start=time.monotonic();code=-1
 log=out/(name+'.log')
 if retry and log.exists():
  import shutil
  shutil.copy2(log,out/(name+'.before-fix.log'))
 with log.open('w') as f:
  process=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT)
  while process.poll() is None:
   time.sleep(.25)
   current=log.read_text(errors='replace')
   if 'SCRIPT ERROR' in current or time.monotonic()-start>(650 if 'qa_day_fast' in script else 150):
    process.terminate()
    try:process.wait(timeout=5)
    except subprocess.TimeoutExpired:process.kill();process.wait()
    if 'SCRIPT ERROR' not in current:f.write('\nTIMEOUT\n')
    break
  code=process.wait()
 text=(out/(name+'.log')).read_text(errors='replace')
 ok=code==0 and not any(x in text for x in ['SCRIPT ERROR','ERROR:','FAIL ','FALHOU','TIMEOUT'])
 row={'script':script,'status':'PASS' if ok else 'FAIL','exit_code':code,'seconds':time.monotonic()-start,'command':cmd}
 previous=next((i for i,r in enumerate(rows) if r['script']==script),None)
 if previous is None:rows.append(row)
 else:rows[previous]=row
 (out/'summary.json').write_text(json.dumps(rows,indent=2))
 print(name,row['status'],round(row['seconds'],2),flush=True)
sys.exit(int(any(x['status']=='FAIL' for x in rows)))
