#!/usr/bin/env python3
"""Verify contractual registration WITHOUT writing to official ZIP or modifying core."""
from pathlib import Path
import zipfile,hashlib,json,sys,copy
ROOT=Path(__file__).resolve().parents[2]
BASE=Path('/mnt/data/files/EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip')
mod=json.loads((ROOT/'exo_bestiary/module/manifest.json').read_text())
record={'test':'EXO_BESTIARY_REGISTRY_DRY_RUN','baseline_sha256':'','checks':{},'status':'BLOCKED'}
if not BASE.exists():
 print('BLOCKED: baseline not mounted');sys.exit(2)
with BASE.open('rb') as stream:
 record['baseline_sha256']=hashlib.file_digest(stream,'sha256').hexdigest()
with zipfile.ZipFile(BASE) as z:
 name=next(n for n in z.namelist() if n.endswith('/exo_core/modules.json') and '/module_template/' not in n)
 old=z.read(name);mods=json.loads(old)
 record['checks']['base_zip_crc']=z.testzip() is None
record['checks']['base_sha_confirmed']=record['baseline_sha256']=='d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac'
record['checks']['no_duplicate_module_id']=mod['id'] not in [m['id'] for m in mods]
record['checks']['required_modules_available']=all(k in [m['id'] for m in mods] for k in mod['requires'])
record['checks']['no_duplicate_services']=all(not (set(mod['services']) & set(m['services'])) for m in mods)
record['checks']['all_expected_keys']=all(k in mod for k in ['id','version','requires','optional','services','publishes','consumes','persistence','entrypoint'])
new_mods=copy.deepcopy(mods)+[mod]
record['checks']['exactly_one_addition']=len(new_mods)==len(mods)+1 and new_mods[:len(mods)]==mods
with zipfile.ZipFile(BASE) as z:
 record['checks']['unchanged_original_json']=(z.read(name)==old)
record['status']='PASS' if all(record['checks'].values()) else 'FAIL'
record['note']='Dry-run schema + read-only ZIP; registry.initialize() and runtime hooks NOT_RUN'
(ROOT/'QA-INTEGRACAO-DRY-RUN.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(record,ensure_ascii=False))
sys.exit(record['status']!='PASS')
