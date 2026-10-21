#!/usr/bin/env python3
"""R7 source-only QA. DOES NOT parse Godot / execute game scenes."""
from pathlib import Path
import json, re, hashlib, sys
root=Path(__file__).resolve().parent.parent
baseline=Path('/mnt/data/C03_ALFA_R6_WORK')
checks=[]
def check(name,result,detail=''):
 checks.append({'id':name,'type':'STATIC','status':'PASS' if result else 'FAIL','evidence':detail})

def source(path):return (root/path).read_text(encoding='utf-8')
new=['genesis/monument_reservations_r7.gd','exo_monumental/tests/qa_c03_r7_native.gd']
mod=['project.godot','convergence/game.gd','convergence/region.gd','genesis/region_data.gd','genesis/settlements/settlement_planner.gd','exo_monumental/integration/interior_bridge.gd','exo_core/integrations/monumental_plans.gd']
for path in new+mod:
 check('R7_EXISTS_'+Path(path).stem,(root/path).is_file(),path)
for file in root.rglob('*.json'):
 try:json.loads(file.read_text(encoding='utf-8'))
 except Exception as ex:check('JSON_'+str(file.relative_to(root)),False,str(ex))
else:check('JSON_PROJECT',True,'All JSON documents parsed')
if baseline.is_dir():
 src={str(x.relative_to(baseline)):hashlib.sha256(x.read_bytes()).hexdigest() for x in baseline.rglob('*') if x.is_file()}
 dst={str(x.relative_to(root)):hashlib.sha256(x.read_bytes()).hexdigest() for x in root.rglob('*') if x.is_file()}
 for path in src:
  if path not in dst:check('NO_DELETE_'+path,False)
 check('NO_DELETIONS',set(src)<=set(dst),f'R6 files {len(src)}')
 permitted=set(mod)|set(new)|{'C03_TRANSFERENCIA/qa_r7_static.py','C03_TRANSFERENCIA/INSTRUCOES-CONTINUACAO-WORK.md','C03_TRANSFERENCIA/ESTADO-INTEGRACAO-C03.json'}
 changed=[path for path in src if path in dst and src[path]!=dst[path]]
 check('R6_DIFF_SCOPE',set(changed)<=permitted,'changed:'+','.join(changed))
 for path in ['exo_dungeon/module/entrypoint.gd','exo_items/integration/atomic_reward_adapter.gd','inventory.gd','exo_core/core.gd','regional_ecology/director.gd','exo_creatures/visuals/visual_catalog.gd']:
  if path in src:check('OWNER_UNCHANGED_'+path,src[path]==dst.get(path),path)
 monfile=source('genesis/monument_reservations_r7.gd')
 reg=source('genesis/region_data.gd');setl=source('genesis/settlements/settlement_planner.gd')
 game=source('convergence/game.gd');scene=source('convergence/region.gd')
 core=source('exo_core/integrations/monumental_plans.gd');bridge=source('exo_monumental/integration/interior_bridge.gd')
 checks2={
 'WORLDGEN_FIRST_RESERVATION':reg.index('Monuments.plan_new(self)')<reg.index('Settlement.plan(spec,gates,rivers'),
 'SETTLEMENT_WELL_RESERVATION':'_reserved_hit(p, 5.0, reservations)' in setl,
 'SETTLEMENT_LOT_RESERVATION':'_reserved_hit(p, pad + 4.0, monument_reservations)' in setl,
 'SETTLEMENT_STREET_SINGLE_OWNER':'var streets: Array=future_streets' in setl,
 'REGIONAL_PINNED':'pinned_monuments' in reg and 'monumental_r7' in game,
 'LEGACY_VISITED_SKIP':'"mode":"legacy"' in game,
 'REGIONAL_FLAG_OPT_OUT':'exo_murim/r7/monuments_enabled' in reg,
 'ACTUAL_WORLD_RECEIPT':'"authority":"WorldGenesis"' in monfile and '"approved":true' in monfile,
 'FOOTPRINT_STREET_TEST':'_segment_crosses(street.a,street.b' in monfile,
 'FOOTPRINT_WATER_TEST':'_segment_crosses(data.river_hub,river.p' in monfile,
 'CITY_PERIMETER_PROTECTION':'Monuments._segment_crosses(wall.a,wall.b' in reg,
 'ROLLBACK_FAILED_SETTLEMENT':'settlement_plan_rejected_reserved_site' in reg,
 'NO_EXTRA_ATLAS_GENERATOR':'WorldPlanner.plan(' not in monfile,
 'BUILDER_EXISTING':'Builder.build(self,plan,receipt)' in scene,
 'BUILDER_RECEIPT_VALIDATION':'Builder.validate_receipt(plan,receipt)' in scene,
 'ROTATION_Q123':'posmod(facing,4)' in bridge and '\t\t\t3:dx=-front' in bridge,
 'INSTITUTIONAL_SCENE':'INSTITUTIONAL_SCENE.instantiate()' in game,
 'PORTAL_E_INTERACTION':'_near_institutional_portal()' in game and '_enter_institutional_interior(institutional)' in game,
 'INSTITUTION_SAVE_ENTRY_ROLLBACK':'save_entry_failed' in game,
 'INSTITUTION_SAVE_EXIT_ROLLBACK':'save_return_failed' in game,
 'INSTITUTION_NO_EXTERIOR_SNAPSHOT':'or _institutional_inside():return' in game,
 'INSTITUTION_RESTORE_FROM_PERSISTENCE':'_restore_institutional_after_region_load()' in game,
 'INSTITUTION_RECOVERY_NO_OVERWRITE':'if not restoring_region and not save_progress()' in game,
 'NPC_STATION_CATALOG':'monument_stations.append' in scene and 'available_stations' in core,
 'CORE_READONLY_RESERVATIONS':'regional_receipts' in core and 'register_service("monuments.plans"' in core,
 'NO_QA_LAB_RECEIPT_IN_GAME':'\"authority\":\"QA_LAB_ONLY\"' not in scene and '\"authority\":\"QA_LAB_ONLY\"' not in monfile,
 'NATIVE_QA_INSTRUCTIONS':'for seed in [101,816204,707,18026]:' in source('exo_monumental/tests/qa_c03_r7_native.gd'),
 'FAMILIES_5':all(x in monfile for x in ['martial_medium','martial_grand','temple_monumental','fortress','ancestral_ruins']),
 }
for k,v in checks2.items():check(k,v)
layouts=json.loads(source('exo_monumental/catalog/layouts.json'))['layouts']
check('ELEVEN_LAYOUTS',len(layouts)==11,len(layouts))
check('SIXTY_TWO_STATIONS',sum(len(item.get('stations',[])) for item in layouts.values())==62,sum(len(item.get('stations',[])) for item in layouts.values()))
# Baseline assets/art provenance maintained.
for path in ['exo_monumental/runtime/builder.gd','exo_monumental/runtime/interior_builder.gd','exo_monumental/catalog/layouts.json','exo_monumental/catalog/site_contracts.json']:
 check('AUTHOR_ORIGINAL_'+Path(path).name,(baseline/path).read_bytes()==(root/path).read_bytes())
# New preloads must have concrete source files, except built-in classes (not counted here).
missing=[]
for path in new+mod:
 if not path.endswith('.gd'):continue
 for target in re.findall(r'preload\("res://([^"\n]+)"\)',source(path)):
  if not (root/target).exists():missing.append(path+' -> '+target)
check('NEW_PRELOAD_REFERENCES',not missing,str(missing))
pass_count=sum(x['status']=='PASS' for x in checks);fails=[x for x in checks if x['status']=='FAIL']
report={'kind':'SOURCE_ONLY_NOT_GODOT','tests':checks,'pass_count':pass_count,'fail_count':len(fails),'native_qa':'NOT_RUN_ENGINE_UNAVAILABLE',
 'native_required':['Godot 4.6.2 editor import/parser','Forja GLB import/meshes/collision','seed/regional determinism and fortifications 14/26/78','interior entry/exit/reopen/death','Dungeon R6 and fauna R5 regression','Ryzen Vega8 benchmark']}
(root/'C03_TRANSFERENCIA'/'QA-C03-ALFA-R7-MATRIZ.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print('R7 SOURCE QA',pass_count,'PASS',len(fails),'FAIL')
for x in fails:print('FAIL',x['id'],x.get('evidence',''))
sys.exit(1 if fails else 0)
