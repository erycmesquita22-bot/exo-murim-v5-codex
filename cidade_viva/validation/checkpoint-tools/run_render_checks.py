from pathlib import Path
import os,subprocess,time,socket,json
base=Path(__file__).resolve().parent
root=base/'project/EXO-Murim-EXO-Visual-01'
env=os.environ.copy();env['DISPLAY']='localhost:102';env['LIBGL_ALWAYS_SOFTWARE']='1'
env['LD_LIBRARY_PATH']=str(base/'engine/xroot/usr/lib/x86_64-linux-gnu')
with (base/'engine/final-xvfb.log').open('w') as xf:
 server=subprocess.Popen([str(base/'engine/xroot/usr/bin/Xvfb'),':102','-screen','0','1280x800x24','-ac','-nolisten','unix','-nolisten','local','-listen','tcp'],stdout=xf,stderr=subprocess.STDOUT,env=env)
 try:
  for _ in range(50):
   try:
    s=socket.create_connection(('127.0.0.1',6102),timeout=.2);s.close();break
   except OSError:time.sleep(.1)
  rows=[]
  for name,script,flags in [('capture-delivery','capture_live.gd',['--fixed-fps','60']),('benchmark-delivery','benchmark_urban.gd',[])]:
   cmd=[str(base/'engine/Godot_v4.6.2-stable_linux.x86_64'),*flags,'--rendering-method','gl_compatibility','--audio-driver','Dummy','--path',str(root),'--script','res://cidade_viva/tests/'+script]
   t=time.monotonic();log=base/'qa'/f'{name}.log'
   with log.open('w') as f:code=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,env=env,timeout=500).returncode
   text=log.read_text(errors='replace')
   ok=code==0 and not any(x in text for x in ['SCRIPT ERROR','ERROR:','FAIL ','failures=["'])
   row={'script':script,'command':cmd,'exit':code,'status':'PASS' if ok else 'FAIL','seconds':time.monotonic()-t,'display':'Xvfb/Mesa llvmpipe'}
   rows.append(row);print(json.dumps(row),flush=True)
   (root/'cidade_viva/validation/rendered-summary.json').write_text(json.dumps(rows,indent=2))
   (root/'cidade_viva/validation'/f'{name}.log').write_text(text)
   if not ok:raise SystemExit(1)
 finally:
  server.terminate();server.wait(timeout=10)
