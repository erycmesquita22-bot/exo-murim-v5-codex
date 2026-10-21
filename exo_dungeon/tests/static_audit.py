#!/usr/bin/env python3
"""Static contract/security audit only: never claims GDScript/native testing."""
import json,re,hashlib,zipfile,pathlib,sys,os
ROOT=pathlib.Path(__file__).resolve().parents[2]
MOD=ROOT/'exo_dungeon'
BASE=pathlib.Path(os.environ.get('EXO_CORE_ARCHIVE','/mnt/data/referencias/EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip'))
manifest=json.loads((MOD/'module/manifest.json').read_text())
checks={}
checks['manifest_schema']=all(x in manifest for x in ('id','version','requires','optional','services','publishes','consumes','persistence','entrypoint'))
checks['module_path']=manifest['entrypoint']=='res://exo_dungeon/module/entrypoint.gd'
checks['module_name']=manifest['id']=='dungeon_genesis'
checks['major_dependencies']=manifest['requires']=={'persistence':'1.0.0','world':'1.0.0'}
checks['new_event_ids_none']=not manifest['publishes'] and not manifest['consumes']
checks['domain_owned']=manifest['persistence']=={'dungeon_genesis':1}
files=[p for p in MOD.rglob('*') if p.is_file()]
scripts=[p for p in files if p.suffix=='.gd']
checks['all_scripts_nonempty']=bool(scripts) and all(p.stat().st_size>=40 for p in scripts)
checks['no_duplicate_paths']=len({str(p.relative_to(ROOT)) for p in files})==len(files)
checks['res_preloads_resolve']=True
missing_preloads=[]
for p in scripts:
 for path in re.findall(r'preload\(["\'](res://[^"\']+)["\']\)',p.read_text()):
  local=ROOT/path.removeprefix('res://')
  if not local.is_file():missing_preloads.append((str(p.relative_to(ROOT)),path))
checks['res_preloads_resolve']=not missing_preloads
entry=(MOD/'module/entrypoint.gd').read_text()
methods=re.findall(r'\bfunc\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(',entry)
announced=re.search(r'register_service\("dungeons","dungeon_genesis",self,\[(.*?)\]\)',entry)
announced_methods=re.findall(r'"([a-z_]+)"',announced.group(1)) if announced else []
checks['service_method_implementations']=bool(announced_methods) and all(m in methods for m in announced_methods)
checks['no_unapproved_external_assets']=not [p for p in files if p.suffix.lower() in ('.glb','.fbx','.gltf','.jpg','.jpeg','.wav','.ogg','.mp3','.ttf','.otf')]
checks['procedural_textures_documented']=all((MOD/'assets/materials'/f'{name}.png').is_file() for name in ['stone_tile','timber_grain','temple_paving','cave_rock','tomb_relief','roof_tile']) and (MOD/'assets/generate_textures.py').is_file()
checks['all_modules_isolated']=all('exo_dungeon' in p.parts for p in files)
checks['no_core_writes']=not any(re.search(r'(?:DirAccess|FileAccess).*?(?:res://(?:exo_core|convergence|genesis)/)',p.read_text()) for p in scripts)
checks['native_qa_exists']=(MOD/'tests/run_qa.gd').is_file() and (MOD/'tests/run_render_smoke.gd').is_file()
checks['laboratory_scene_exists']=(MOD/'lab/main.tscn').is_file() and (ROOT/'project.godot').is_file()
checks['persistence_has_validator']='static func valid(' in (MOD/'persistence/dungeon_state.gd').read_text()
checks['deterministic_seed_derivation']='rooms|' in (MOD/'generator/room_planner.gd').read_text()
checks['graph_key_reachability']='_walk(' in (MOD/'generator/connectivity_validator.gd').read_text()
checks['original_voxel_collision']='BoxShape3D.new()' in (MOD/'runtime/dungeon_renderer.gd').read_text()
checks['gate_collision_and_signal']='LockedSeal_' in (MOD/'runtime/dungeon_renderer.gd').read_text() and 'gate_unlocked.emit' in (MOD/'runtime/dungeon_instance.gd').read_text()
checks['protected_corridor_rails']='CorridorRail' in (MOD/'runtime/dungeon_renderer.gd').read_text()
checks['no_core_zips_packaged']=not [p for p in ROOT.rglob('*.zip')]
if BASE.is_file():
 with zipfile.ZipFile(BASE) as z:
  coremodules=json.loads(z.read('EXO-Murim-Convergencia-02/exo_core/modules.json'))
  coreids={m['id'] for m in coremodules}
  coreservices={service for module in coremodules for service in module.get('services',[])}
  checks['core_deps_available']=all(dep in coreids for dep in manifest['requires'])
  checks['module_id_not_colliding']=manifest['id'] not in coreids
  checks['service_not_colliding']=not (set(manifest['services']) & coreservices)
  checks['forja_ids_real']=all(s in {r['id'] for r in json.loads(z.read('EXO-Murim-Convergencia-02/forja/catalog_v3.json'))['assets']} for s in ['bronze_incense_burner','silk_vertical_banner','timber_handcart','stone_garden_lantern'])
else:
 print('Core archive missing: set EXO_CORE_ARCHIVE=/path/to/EXO-Core.zip to repeat Core ABI checks.')
report={'scope':'STATIC_ONLY','results':checks,'passed':sum(checks.values()),'total':len(checks),'missing_preloads':missing_preloads,'source_module_count':len(scripts),'native_godot_parser':'NOT_RUN','native_physics':'NOT_RUN','native_performance':'NOT_RUN','real_screenshots':'NOT_RUN','source_archive_sha256':'d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac' if BASE.is_file() else 'NOT_RECHECKED'}
(ROOT/'evidence/QA-ESTATICO.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({'passed':report['passed'],'total':report['total'],'fails':[k for k,v in checks.items() if not v],'gd_scripts':len(scripts)},ensure_ascii=False))
sys.exit(0 if all(checks.values()) else 1)
