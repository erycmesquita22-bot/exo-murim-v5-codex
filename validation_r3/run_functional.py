"""python validation_r3/run_functional.py /path/to/Godot4.6.2 [--only npc_day]

Native Godot processes, sequential. Python only launches and records them.
Run from this project directory after importing it in the editor once.
"""
import json,pathlib,subprocess,sys,time
root=pathlib.Path(__file__).resolve().parents[1]
engine=str(pathlib.Path(sys.argv[1]).resolve())
suites=[('lifecycle_A','lifecycle',['A']),('lifecycle_B','lifecycle',['B']),('lifecycle_C','lifecycle',['C']),('repeat_combat','repeat_combat',[]),('inventory_reopen','inventory_reopen',[]),('npc_day','npc_day',[]),('npc_reopen','npc_reopen',[])]
if '--only' in sys.argv:
    selected=sys.argv[sys.argv.index('--only')+1]
    suites=[row for row in suites if row[0]==selected]
rows=[]
for name,script,args in suites:
    command=[engine,'--headless','--fixed-fps','60','--path',str(root),'--script','res://validation_r3/'+script+'.gd',*(['--',*args] if args else [])]
    target=root/'validation_r3/logs'/('reproduce_'+name+'.log')
    began=time.monotonic()
    with target.open('w') as log:
        try:code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=1800).returncode
        except subprocess.TimeoutExpired:code=-1;log.write('\nTIMEOUT\n')
    content=target.read_text(errors='replace')
    ok=code==0 and not any(s in content for s in ['SCRIPT ERROR','ERROR:','leaked','still in use'])
    rows.append({'suite':name,'status':'PASS' if ok else 'FAIL','exit':code,'seconds':time.monotonic()-began,'command':command})
    (root/'validation_r3/results/reproduced_executions.json').write_text(json.dumps(rows,indent=2))
    print(name,rows[-1]['status'],flush=True)
sys.exit(int(not rows or any(row['status']!='PASS' for row in rows)))
