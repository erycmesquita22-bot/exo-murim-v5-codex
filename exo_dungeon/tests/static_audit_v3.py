#!/usr/bin/env python3
"""Auditoria estrutural: não compila GDScript nem roda Godot."""
import pathlib, json, hashlib, zipfile, re, sys
R=pathlib.Path(__file__).resolve().parents[2]
M=R/'exo_dungeon'
REF=pathlib.Path('/mnt/data/EXO-Murim-Dungeon-Genesis-01-POLIDO-R2.zip')
CORE=pathlib.Path('/mnt/data/referencias/EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip')
checks={}
with zipfile.ZipFile(REF) as z:
    original={n:z.read(n) for n in z.namelist() if n.startswith('exo_dungeon/')}
checks['v2_renderer_byte_preserved']=(M/'runtime/renderer_v2.gd').read_bytes()==original['exo_dungeon/runtime/dungeon_renderer.gd']
checks['v2_validator_byte_preserved']=(M/'generator/validator_v2.gd').read_bytes()==original['exo_dungeon/generator/connectivity_validator.gd']
checks['v2_generator_logic_preserved']=(M/'generator/generator_v2.gd').read_text().replace('res://exo_dungeon/generator/validator_v2.gd','res://exo_dungeon/generator/connectivity_validator.gd')==original['exo_dungeon/generator/dungeon_generator.gd'].decode()
with zipfile.ZipFile(CORE) as z:
    modules=json.loads(z.read('EXO-Murim-Convergencia-02/exo_core/modules.json'))
manifest=json.loads((M/'module/manifest.json').read_text())
coreids={x['id']:x['version'] for x in modules}
coreservices={service for module in modules for service in module['services']}
checks['no_module_collision']=manifest['id'] not in coreids
checks['no_service_collision']=not (set(manifest['services']) & coreservices)
checks['requires_available']=set(manifest['requires']).issubset(coreids)
checks['optional_available']=set(manifest['optional']).issubset(coreids)
checks['version_incremented']=manifest['version']=='0.4.0'
checks['single_save_domain']=manifest['persistence']=={'dungeon_genesis':1}
checks['no_new_global_events']=manifest['publishes']==manifest['consumes']==[]
script=(M/'module/entrypoint.gd').read_text()
checks['v2_visits_pin_version']='request["generator_version"]=int(existing[dungeon_id].generator_version)' in script
checks['service_exposes_interactions']=all('"'+x+'"' in script for x in ['enter_instance','leave_instance','interact_active','interaction_hint','recover_visit_context'])
checks['outside_anchor_saved']=all(key in (M/'persistence/visit_recovery.gd').read_text() for key in ['"outside_position"','"descriptor"','"entrance_anchor"'])
checks['no_core_global_files_in_package']=not any((R/x).exists() for x in ('exo_core/core.gd','convergence/game.gd','journey_save.gd'))
checks['host_patch_is_reference_only']=(R/'INTEGRADOR-HOST-GAME-OPCIONAL.diff').is_file() and not (R/'convergence/game.gd').exists()
checks['instanced_scene']=(M/'runtime/interior_root.tscn').is_file() and 'res://exo_dungeon/runtime/interior_root.gd' in (M/'runtime/interior_root.tscn').read_text()
checks['same_actor']=('current_actor=actor' in (M/'runtime/transition_service.gd').read_text()) and 'actor.reparent(' not in (M/'runtime/transition_service.gd').read_text()
checks['return_anchor']="actor.global_position=outside_position" in (M/'runtime/transition_service.gd').read_text()
checks['exterior_state_restored']="_resume_exterior()" in (M/'runtime/transition_service.gd').read_text()
checks['world_id_gate']=all(x in script for x in ['"wrong_region"','"too_far"'])
checks['exploration_key_gate_secret_portal'] = all(x in (M/'runtime/exploration_logic.gd').read_text() for x in ['"key"','"gate"','"secret"','"floor"','"exit"'])
checks['texture_generator_included']=(M/'assets/generate_textures.py').is_file()
checks['texture_assets_six']=len(list((M/'assets/materials').glob('*.png')))==6
checks['no_binary_thirdparty_media']=not any(p.suffix.lower() in ('.fbx','.glb','.gltf','.mp3','.ogg','.wav') for p in M.rglob('*') if p.is_file())
checks['native_suite_scripts_exist']=all((M/'tests'/x).exists() for x in ['run_qa.gd','run_mechanics_qa.gd','run_render_smoke.gd','run_instance_qa.gd'])
checks['lab_playtest_exists']=(M/'lab/playtest.tscn').is_file() and (M/'lab/playtest.gd').is_file()
checks['reference_evidence_exists']=(R/'evidence/QA-DUNGEON02-GEOMETRIA-REFERENCIA.json').is_file()
checks['reference_test_pass']=json.loads((R/'evidence/QA-DUNGEON02-GEOMETRIA-REFERENCIA.json').read_text())['status']=='PASS'
checks['source_scripts_not_empty']=all(len(p.read_text())>30 for p in M.rglob('*.gd'))
missing=[]
for p in M.rglob('*.gd'):
 for path in re.findall(r'preload\(["\'](res://[^"\']+)["\']\)',p.read_text()):
  if not (R/path.removeprefix('res://')).is_file():missing.append((str(p),path))
checks['all_preloads_exist']=not missing
report={'test':'EXO_DUNGEON02_STATIC_ONLY','checks':checks,'passed':sum(checks.values()),'total':len(checks),'failures':[k for k,v in checks.items() if not v],'missing_preloads':missing,'native_parser':'NOT_RUN','native_physics':'NOT_RUN'}
(R/'evidence/QA-DUNGEON02-ESTATICO.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({'passed':report['passed'],'total':report['total'],'failed':report['failures']},ensure_ascii=False))
sys.exit(0 if all(checks.values()) else 1)
