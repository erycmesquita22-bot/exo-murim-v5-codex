#!/usr/bin/env python3
"""Launch actual engine-based EXO Settlement Genesis 05 QA and save evidence.
Requires a locally installed Godot binary. Fails early if missing.
Usage: python tools/run_settlement_qa.py /path/to/godot [synthetic_count]
"""
import sys,subprocess,shutil,json,time,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
EVIDENCE=ROOT/'evidence'/'settlement_v05_real'

def main():
    if len(sys.argv)<2:
        print('ERROR: provide an existing Godot executable path; no engine run occurred',file=sys.stderr)
        return 2
    engine=shutil.which(sys.argv[1]) or sys.argv[1]
    if not Path(engine).is_file():
        print(f'ERROR: Godot binary not found: {engine}',file=sys.stderr)
        return 2
    count=min(100000,max(100,int(sys.argv[2]))) if len(sys.argv)>2 else 10000
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    suites=[
      ('import',['--headless','--editor','--import','--quit'],480),
      ('atlas_native',['--headless','--script','res://tests/plan_stress.gd','--','2048'],600),
      ('settlement_core',['--headless','--script','res://tests/settlement_core.gd','--','1000'],1200),
      ('settlement_extreme',['--headless','--script','res://tests/settlement_extreme.gd','--',str(count)],1200),
      ('settlement_geometry',['--headless','--script','res://tests/settlement_geometry.gd'],1200),
      ('grade_seed101',['--headless','--script','res://tests/settlement_grades.gd','--','101'],1200),
      ('grade_seed816204',['--headless','--script','res://tests/settlement_grades.gd','--','816204'],1200),
    ]
    outputs=[]
    for name,args,timeout in suites:
        tick=time.monotonic()
        try:
            run=subprocess.run([engine,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,timeout=timeout)
            stdout=run.stdout;stderr=run.stderr;code=run.returncode
            pass_flag=code==0 and all(marker not in stdout+stderr for marker in ('SCRIPT ERROR','Parse Error','ERROR:','FAIL '))
        except subprocess.TimeoutExpired as e:
            stdout=(e.stdout or b'').decode(errors='replace') if isinstance(e.stdout,bytes) else (e.stdout or '')
            stderr=(e.stderr or b'').decode(errors='replace') if isinstance(e.stderr,bytes) else (e.stderr or '')
            code='TIMEOUT';pass_flag=False
        (EVIDENCE/(name+'.log')).write_text(stdout+'\n--- STDERR ---\n'+stderr)
        outputs.append({'name':name,'status':'PASS' if pass_flag else 'FAIL','exit_code':code,'elapsed_sec':round(time.monotonic()-tick,2),'log':str(EVIDENCE/(name+'.log'))})
        print(outputs[-1],flush=True)
        if not pass_flag:break
    (EVIDENCE/'summary.json').write_text(json.dumps({'engine':str(engine),'synthetic_count_requested':count,'results':outputs},indent=2))
    return 0 if all(x['status']=='PASS' for x in outputs) and len(outputs)==len(suites) else 1
if __name__=='__main__':sys.exit(main())
