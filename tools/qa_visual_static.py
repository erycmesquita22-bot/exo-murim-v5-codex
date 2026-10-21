#!/usr/bin/env python3
"""EXO Visual 01: structural checks only; NOT an engine execution substitute."""
import hashlib,json,re,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
checks=[]
def check(name,ok,detail=''):
 checks.append({'test':name,'status':'PASS' if ok else 'FAIL','kind':'STATIC','evidence':detail})
manifest=json.loads((ROOT/'exo_core/modules.json').read_text())
check('modules_10',len(manifest)==10,'count='+str(len(manifest)))
ids=[m['id'] for m in manifest]
check('unique_module_ids',len(ids)==len(set(ids)),str(ids))
services=[x for m in manifest for x in m['services']]
check('unique_services',len(services)==len(set(services)),str(services))
check('original_modules_present',all(x in ids for x in ('persistence','world','living_world','inventory','combat','journey','narrative','appearance','architecture')),str(ids))
check('visual_contract',any(m['id']=='visual' and m.get('entrypoint')=='res://exo_visual/module.gd' and not m.get('persistence') and m.get('services')==['exo_visual'] for m in manifest))
from collections import defaultdict
available={m['id']:m['version'] for m in manifest}
check('dependencies_exist',all(dep in available for m in manifest for dep in list(m['requires'])+list(m['optional'])))
spec=(ROOT/'exo_visual/spec.gd').read_text()
driver=(ROOT/'exo_visual/driver.gd').read_text()
graphics=(ROOT/'graphics.gd').read_text()
ui=(ROOT/'ui/pages/settings.gd').read_text()
required=['shadow_quality','water_quality','grass_density','wind','particles','weapon_trails','afterimages','glow','ssao','ssr','ssil','texture_filter','material_detail','render_scale','resolution','fps_limit','fxaa','character_shadows']
check('settings_schema_present',all(f'"{key}"' in spec for key in required))
check('legacy_hud_preserved',all(f'"{key}"' in graphics for key in ('ornaments','paper','preview_motion','camera_shake','hud','interface')))
check('advanced_ui_uses_schema','spec.OPTIONS' in ui and 'option_available' in ui and 'set_option' in ui)
check('no_save_domain_added','save_coordinator' not in (ROOT/'exo_visual/module.gd').read_text())
check('renderer_capability_gate','forward_only' in spec and 'renderer_is_forward' in spec and 'not available' in ui or ('forward_only' in spec and 'renderer_is_forward' in spec and 'select_node.disabled=not available' in ui))
check('same_ground_textures',(ROOT/'genesis/region_scene.gd').read_text().count('res://textures/terrain_approved/')>0)
check('river_direction_data_used','set_shader_parameter("flow_direction",direction)' in (ROOT/'genesis/region_scene.gd').read_text())
check('collision_and_worldgen_not_duplicated',not (ROOT/'exo_visual/region_data.gd').exists() and not (ROOT/'exo_visual/worldgen.gd').exists())
check('river_gate_r2_present',(ROOT/'fortifications/river_gate.gd').exists() and (ROOT/'exo_core/tests/qa_fluvial_integration.gd').exists())
check('core_saved_file_exists',(ROOT/'exo_core/persistence/save_coordinator.gd').exists())
check('afterimage_snapshot_real_rig','world.model.find_children' in (ROOT/'exo_visual/afterimage.gd').read_text())
new_files=[p for p in (ROOT/'exo_visual').rglob('*') if p.is_file()]
refs=[]
for p in new_files+[ROOT/'graphics.gd',ROOT/'ui/pages/settings.gd',ROOT/'genesis/region_scene.gd',ROOT/'combat/player_combat.gd']:
 if p.suffix not in {'.gd','.gdshader'}:continue
 for res in re.findall(r'\b(?:preload|load)\("res://([^"\n]+)"\)',p.read_text()):
  refs.append((p.relative_to(ROOT).as_posix(),res))
missing=[{'from':frm,'resource':res} for frm,res in refs if not (ROOT/res).exists()]
check('visual_preloaded_resources_exist',not missing,repr(missing[:20]))
for name in ['water','grass_wind','terrain_pixel','terrain_pixel_mips','terrain_linear']:
 p=ROOT/'exo_visual/shaders'/f'{name}.gdshader'
 check('shader_source_'+name,p.exists() and p.read_text().lstrip().startswith('shader_type spatial;'))
failures=[x['test'] for x in checks if x['status']=='FAIL']
print(json.dumps({'tests':checks,'pass':len(checks)-len(failures),'fail':len(failures),'note':'Static source checks only; Godot not invoked.'},indent=2,ensure_ascii=False))
sys.exit(1 if failures else 0)
