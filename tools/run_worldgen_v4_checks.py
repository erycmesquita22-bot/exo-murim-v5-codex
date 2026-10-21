from pathlib import Path
import subprocess,os,json,sys
W=Path(__file__).resolve().parents[1];engine=sys.argv[1]
os.chdir(W)
Path('WORLDGENESIS_V4/reproduced').mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env.setdefault('XDG_DATA_HOME',str(W/'WORLDGENESIS_V4/qa-userdata'));rows=[]
steps=[('genesis/v4/qa_data.gd',[],'WG4_DATA_RESULT'),('genesis/v4/qa_physical.gd',[],'WG4_PHYSICAL_RESULT'),('genesis/v4/qa_physical.gd',['--reopen'],'WG4_PHYSICAL_RESULT')]
for seed in [707,18026]:
 for reopen in [False,True]:steps.append(('genesis/v4/qa_new_campaign.gd',['--seed='+str(seed)]+(['--reopen'] if reopen else []),'WG4_NEW_CAMPAIGN_RESULT'))
steps.extend([('convergence/tests/qa_v4_integration.gd',[],'V4_RESULT'),('convergence/tests/qa_v4_integration.gd',['--reopen'],'V4_RESULT'),('convergence/tests/qa_c03_r12_native.gd',[],'R12_NATIVE_PARSE')])
for i,(script,args,marker) in enumerate(steps):
 r=subprocess.run([engine,'--headless','--path',str(W),'--script',script]+(['--']+args if args else []),env=env,capture_output=True,text=True,timeout=240)
 out=r.stdout+r.stderr;ok=r.returncode==0 and marker in out and not any(t in out for t in ['ERROR:','SCRIPT ERROR','FAIL ']) and (marker=='R12_NATIVE_PARSE' or '"failures":[]' in out)
 name='%02d-%s%s'%(i,Path(script).stem,'-reopen' if '--reopen' in args else '')
 Path('WORLDGENESIS_V4/reproduced/'+name+'.log').write_text(out);row=dict(case=name,status='PASS' if ok else 'FAIL',code=r.returncode);rows.append(row);print(row,flush=True)
 Path('WORLDGENESIS_V4/reproduced/summary.json').write_text(json.dumps(rows,indent=2))
