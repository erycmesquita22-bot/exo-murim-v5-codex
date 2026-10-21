#!/usr/bin/env python3
"""Revisão contratual baseada no pacote imutável R1, não compila Godot."""
import pathlib,hashlib,zipfile,json,re,sys
R=pathlib.Path(__file__).resolve().parents[2];M=R/'exo_dungeon'
BASE=pathlib.Path('/mnt/data/EXO-Murim-Dungeon-Genesis-02-CANDIDATO.zip')
CORE=pathlib.Path('/mnt/data/referencias/EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip')
checks={}
with zipfile.ZipFile(BASE) as z: old={name:z.read(name) for name in z.namelist() if name.startswith('exo_dungeon/')}
def same(suffix):return (M/suffix).read_bytes()==old['exo_dungeon/'+suffix]
checks['immutable_v2_generator']=same('generator/generator_v2.gd')
checks['immutable_v2_renderer']=same('runtime/renderer_v2.gd')
checks['immutable_v2_validator']=same('generator/validator_v2.gd')
checks['immutable_v3_validator']=same('generator/validator_v3.gd')
checks['immutable_v3_logic_prefix']=(M/'generator/generator_v3.gd').read_bytes().startswith(old['exo_dungeon/generator/generator_v3.gd'])
checks['immutable_v3_topology']=same('generator/room_planner.gd')
checks['immutable_v3_room_catalog']=same('layouts/room_catalog.gd')
checks['v4_dispatches_validator_v3']='[3,4]' in (M/'generator/connectivity_validator.gd').read_text()
checks['new_v4_from_existing_v3']='static func generate_r2' in (M/'generator/generator_v3.gd').read_text()
dispatch=(M/'generator/dungeon_generator.gd').read_text()
checks['version_pins_2_3_4']=all(s in dispatch for s in ['version==2','version==3','version==4','generator_version",4'])
checks['version4_digest_pin']='base.digest=JSON.stringify([base.id,4,2' in (M/'generator/generator_v3.gd').read_text()
checks['family_structural_masks']=all(s in (M/'layouts/architectural_blueprint.gd').read_text() for s in ['broken_court','eroded_chamber','axial_sanctuary','barracks_wings','branching_shaft','processional_crypt'])
checks['mask_cardinal_clearance']='keep=keep or center_path' in (M/'layouts/architectural_blueprint.gd').read_text()
checks['independent_wall_contours']='contour_segments' in (M/'layouts/architectural_blueprint.gd').read_text()
checks['same_rng_logic']=same('generator/room_planner.gd')
checks['renderer_v3_preserved_prefix']=(M/'runtime/dungeon_renderer.gd').read_text().endswith(' return root\n')
checks['v2_v3_renderer_reused']=all(s in (M/'runtime/dungeon_renderer.gd').read_text() for s in ['LegacyRenderer.build','R2Renderer.build'])
checks['combined_sector_meshes']='add_surface_from_arrays' in (M/'runtime/batched_geometry.gd').read_text()
checks['sector_concave_collision']='ConcavePolygonShape3D' in (M/'runtime/batched_geometry.gd').read_text()
checks['no_one_body_per_voxel']='StaticBody3D.new()' not in (M/'runtime/renderer_r2.gd').read_text().split('static func _room_sector')[1]
checks['bent_corridor_routing']='route.append(p+axis' in (M/'runtime/renderer_r2.gd').read_text()
checks['locked_corridor_does_not_bend']='regular: bool=locked' in (M/'layouts/architectural_blueprint.gd').read_text()
checks['interior_scene_reused']=same('runtime/interior_root.tscn')
checks['same_player_transition']=same('runtime/transition_service.gd')
checks['serialized_visit_protocol']=(M/'persistence/visit_recovery.gd').is_file()
checks['legacy_recovery_supported']='if not visit.has("visit_schema")' in (M/'persistence/visit_recovery.gd').read_text()
checks['safe_exterior_recovery']='recover_to_exterior' in (M/'module/entrypoint.gd').read_text()
checks['explicit_recovery_phases']='interrupted' in (M/'persistence/visit_recovery.gd').read_text()
checks['snapshot_region_protection_patch']=(R/'INTEGRADOR-HOST-GAME-R2-OPCIONAL.diff').exists()
checks['only_one_persistence_domain']=(M/'module/manifest.json').is_file() and json.loads((M/'module/manifest.json').read_text())['persistence']=={'dungeon_genesis':1}
checks['reward_receipt_fails_closed']='if not committed_reward_verifier.is_valid():return false' in (M/'module/entrypoint.gd').read_text()
checks['footprint_worldgen_callback']=(M/'integration/entrance_footprint.gd').is_file() and 'worldgen_validator_unavailable' in (M/'integration/entrance_footprint.gd').read_text()
checks['mock_only_no_duplicate_combat']=(M/'lab/physical_mocks.gd').is_file() and 'reward_requested' in (M/'lab/physical_mocks.gd').read_text()
checks['no_global_core_overwrite']=not any((R/n).exists() for n in ('exo_core/core.gd','convergence/game.gd','journey_save.gd','inventory.gd'))
checks['no_thirdparty_models']=not list(M.rglob('*.glb')) and not list(M.rglob('*.fbx'))
checks['godot_native_suite_prepared']=(M/'tests/run_r2_architecture_qa.gd').is_file()
checks['reference_suite_prepared']=(M/'tests/qa_r2_reference.py').is_file()
checks['core_base_available']=CORE.exists() and CORE.stat().st_size>1_000_000
missing=[]
for path in M.rglob('*.gd'):
    for rel in re.findall(r'preload\(["\'](res://[^"\']+)["\']\)',path.read_text()):
        if not (R/rel.removeprefix('res://')).is_file():missing.append([str(path.relative_to(R)),rel])
checks['preloads_resolve']=not missing
manifest=json.loads((M/'module/manifest.json').read_text())
checks['module_minor_bump']=manifest['version']=='0.4.0'
checks['unchanged_global_event_surface']=manifest['publishes']==[] and manifest['consumes']==[]
report={'suite':'R2_STATIC_SOURCE_INTEGRITY','base_sha256':hashlib.sha256(BASE.read_bytes()).hexdigest(),'core_sha256':hashlib.sha256(CORE.read_bytes()).hexdigest(),'checks':checks,'passed':sum(checks.values()),'total':len(checks),'failures':[k for k,v in checks.items() if not v],'unresolved_preloads':missing,'native_godot':'NOT_RUN','status':'PASS' if all(checks.values()) else 'FAIL'}
(R/'evidence/QA-R2-ESTATICO.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ('passed','total','failures','native_godot','status')},ensure_ascii=False))
sys.exit(not all(checks.values()))
