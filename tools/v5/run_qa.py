#!/usr/bin/env python3
"""Runs real Godot suites. Engine exit code, outcome and runtime diagnostics all matter."""
from pathlib import Path
import argparse,json,os,re,subprocess,time,sys
ROOT=Path(__file__).resolve().parents[2]
SUITES={
 'fauna_regions':('exo_bestiary/tests/qa_c03_r4_regional_fauna.gd','C03_R4_NATIVE_FAUNA ',None),
 'murim_field_combat':('qa/v5/murim_field_combat.gd','V5_MURIM_FIELD_COMBAT ',None),
 'skill_runtime_sweep':('qa/v5/skill_runtime_sweep.gd','V5_SKILL_RUNTIME_SWEEP ',None),
 'terrain_water':('qa/v5/terrain_water.gd','V5_TERRAIN_WATER ',None),
 'reported_bugs':('qa/v5/reported_bugs.gd','V5_REPORTED_BUGS ',None),
 'drive_updates':('qa/v5/drive_updates.gd','V5_DRIVE_UPDATES ',None),
 'interior_safety':('qa/v5/interior_safety.gd','V5_INTERIOR_SAFETY ',None),
 'resources':('qa/v5/parse_all.gd','V5_PARSE_RESULT ',None),
 'npc04':('npc_system04/tests/qa_npc04_native.gd','NPC04 NATIVE UNIT PASS',None),
 'worldgen_probe':('worldgen_v5/qa/native_probe.gd','WG5_NATIVE_PROBE ',None),
 'core':('exo_core/tests/qa_core.gd','EXO_CORE_QA ',None),
 'core_contracts':('exo_core/tests/qa_core_integrations_r3.gd','C03_R3_CORE_INTEGRATIONS_QA ',None),
 'items_atomic':('exo_items/tests/qa_atomic_r3_native.gd','QA_ATOMIC_R3_NATIVE ',None),
 'economy':('exo_economy/tests/qa_r5_native.gd','ECONOMY R5 NATIVE checks=',None),
 'martial':('exo_martial/tests/qa_r2_native.gd','EXO_MARTIAL_R2_NATIVE_QA ',None),
 'city_gates':('exo_core/tests/qa_integration.gd','R3_RESULT exo_core_integration','validation_r3/results/exo_core_integration.json'),
 'campaign':('qa/v5/integration.gd','V5_INTEGRATION_RESULT ',None),
 'gameplay':('qa/v5/gameplay.gd','R3_RESULT v5_gameplay','validation_r3/results/v5_gameplay.json'),
 'dungeon':('qa/v5/dungeon.gd','R3_RESULT v5_dungeon','validation_r3/results/v5_dungeon.json'),
 'world_regions':('qa/v5/world_regions.gd','V5_REGIONS_RESULT ',None),
}
p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','/workspace/tools/godot-4.6.2/Godot_v4.6.2-stable_linux.x86_64'));p.add_argument('--output',type=Path,default=ROOT/'qa/v5/output');p.add_argument('--suite',choices=list(SUITES),action='append');a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
for directory in ['cache','config','userdata']:(out/directory).mkdir(exist_ok=True)
version_env=dict(os.environ,XDG_CACHE_HOME=str(out/'cache'),XDG_DATA_HOME=str(out/'userdata'),XDG_CONFIG_HOME=str(out/'config'))
version=subprocess.check_output([a.godot,'--version'],text=True,env=version_env).strip()
if not version.startswith('4.6.2.stable.official.'):raise SystemExit('Required official Godot 4.6.2; received '+version)
rows=[]
for name in a.suite or SUITES:
 script,marker,result_file=SUITES[name];suite_cache=out/'cache'/name;suite_cache.mkdir(parents=True,exist_ok=True);env=dict(os.environ,XDG_DATA_HOME=str(out/'userdata'/name),XDG_CONFIG_HOME=str(out/'config'),XDG_CACHE_HOME=str(suite_cache));cmd=[a.godot,'--headless','--fixed-fps','60','--path',str(ROOT),'--script','res://'+script];start_ns=time.time_ns();start=time.monotonic();log=out/(name+'.log')
 with log.open('w') as f:
  try:code=subprocess.run(cmd,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:code=124
 text=log.read_text(errors='replace');errors=[line for line in text.splitlines() if re.match(r'^(SCRIPT ERROR:|ERROR:)',line)];present=marker in text;detail=None
 if result_file:
  path=ROOT/result_file
  if path.exists() and path.stat().st_mtime_ns>=start_ns:
   detail=json.loads(path.read_text());(out/(name+'.json')).write_text(json.dumps(detail,indent=2))
  else:present=False
 else:
  for line in text.splitlines():
   if line.startswith(marker) and '{' in line:
    try:detail=json.loads(line[line.index('{'):])
    except json.JSONDecodeError:pass
 failures=(detail or {}).get('failures',(detail or {}).get('failed',[]));ok=code==0 and present and not errors and not failures
 row={'suite':name,'status':'PASS' if ok else 'FAIL','exit_code':code,'command':cmd,'duration_seconds':round(time.monotonic()-start,3),'outcome_present':present,'runtime_errors':errors,'result':detail};rows.append(row);print(name,row['status'],flush=True)
 (out/'summary.json').write_text(json.dumps({'engine':version,'suites':rows,'status':'PASS' if all(r['status']=='PASS' for r in rows) else 'FAIL'},indent=2))
sys.exit(0 if all(r['status']=='PASS' for r in rows) else 1)
