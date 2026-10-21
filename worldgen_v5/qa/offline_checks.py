#!/usr/bin/env python3
import json,re,hashlib,subprocess,sys,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[2]
host=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path('/mnt/data/base_v4')
errors=[];passes=[]
def check(name,good,detail=''):
 (passes if good else errors).append({'id':name,'detail':detail})
for seed in ['101','816204']:
 p=host/'genesis'/('atlas_seed_'+seed+'.json')
 raw=p.read_text()
 raw=re.sub(r'("(?:seed|region_seed)"\s*:\s*)([0-9]+)',r'\1"\2"',raw)
 a=json.loads(raw)
 regions=a.get('regions',[])
 check('atlas88_'+seed,len(regions)==88)
 kinds={k:sum(x.get('kind')==k for x in regions) for k in ['settlement','ruins','dungeon_approach','wild']}
 check('quota_'+seed,kinds=={'settlement':23,'ruins':12,'dungeon_approach':10,'wild':43},str(kinds))
 check('unique_ids_'+seed,len(set(int(x['id']) for x in regions))==88)
files=[host/'convergence/game.gd',host/'convergence/region.gd',host/'worldgen_v5/runtime/settlement_handoff.gd',host/'exo_settlement_forge/runtime/settlement_service.gd']
for f in files:check('present_'+f.name,f.is_file(),str(f))
functions=set()
for f in (host/'exo_city_forge/libraries/districts').glob('*.json'):
 doc=json.loads(f.read_text())
 def visit(v):
  if isinstance(v,dict):
   if 'function' in v and isinstance(v['function'],str):functions.add(v['function'])
   for x in v.values():visit(x)
  elif isinstance(v,list):
   for x in v:visit(x)
 visit(doc)
s=(host/'worldgen_v5/runtime/settlement_handoff.gd').read_text()
mapping=set(re.findall(r'"([a-z_]+)"\s*:\s*"[a-z_0-9]+"',s.split('const INTERIORS:',1)[1].split('const NPC_ROLES:',1)[0]))
check('supported_city_functions',not bool(functions-mapping),str(sorted(functions-mapping)))
for p in (host/'exo_settlement_forge/libraries/prefabs').glob('*.json'):
 obj=json.loads(p.read_text());check('prefab_json_'+p.stem,isinstance(obj,dict))
check('flag_default_off','replace_settlements",false' in (host/'convergence/region.gd').read_text())
check('avoid_secondary_save','FileAccess.open(' not in (host/'worldgen_v5/runtime/visit_host.gd').read_text())
check('v5_host_save_hook','worldgen_v5_visit' in (host/'convergence/game.gd').read_text())
check('npc04_binary_available',(host/'npc_system04/actor.gd').exists(),'not a prerequisite for static WG5 checks')
summary={'static_checks_passed':len(passes),'static_checks_failed':len(errors),'checks_pass':passes,'checks_fail':errors,
 'godot_executable':shutil.which('godot') or shutil.which('godot4'),
 'native_runs':'NOT_RUN','npc04_integration':'BLOCKED_IF_MISSING', 'status':'NOT_HOMOLOGATED'}
(root/'logs/QA_STATIC.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False))
print(json.dumps({k:v for k,v in summary.items() if k not in ['checks_pass','checks_fail']},ensure_ascii=False,indent=2))
if errors and any(x['id']!='npc04_binary_available' for x in errors):sys.exit(2)
