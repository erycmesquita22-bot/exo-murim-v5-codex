#!/usr/bin/env python3
"""Focused offline validation of the EXO-Murim C01.2 visual refinement.
The Godot execution is NOT_RUN and must be validated by Work or user Godot 4.6.2.
"""
from pathlib import Path
from hashlib import sha256
import json, math, re, zipfile
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
FILES=['genesis/terrain.gdshader','genesis/region_scene.gd','convergence/region.gd','convergence/resident.gd','convergence/game.gd']
checks=[]
def check(name, cond):
    checks.append({'name':name,'pass':bool(cond)})
    if not cond: raise AssertionError(name)
content={p:(ROOT/p).read_text('utf-8') for p in FILES}
shader=content['genesis/terrain.gdshader']; scene=content['genesis/region_scene.gd']
region=content['convergence/region.gd']; resident=content['convergence/resident.gd']; game=content['convergence/game.gd']
check('approved ground textures still selected',scene.count('return load(APPROVED_GROUND+files[biome]+".png")')==1)
check('approved road remains selected','mat.set_shader_parameter("road_tex",load(APPROVED_GROUND+"trilha_terra.png"))' in scene)
check('road coordinates unchanged', 'st.set_uv(p/6.0)' in scene and 'vec3 road=texture(road_tex,UV).rgb;' in shader)
check('foliage UV independent','small_grass_uv=UV*foliage_uv_scale' in shader and 'foliage_uv_scale = 2.45' in shader)
for ground in ['ground_tex','blend0','blend1','blend2','blend3']:
    check(f'foliage texture {ground} uses fine UV', f'texture({ground},small_grass_uv)' in shader)
check('no changed geometry/physics', 'shape.set_faces(faces)' in scene and 'stitched_height(p)' in scene and 'backface_collision=true' in scene)
check('soil gaps excluded on full road', 'bare_patch=' in shader and 'edge_strength' in shader and '1.0-road_weight' in shader)
check('decorative grass only', 'var group := MultiMeshInstance3D.new()' in scene and 'collision_layer' not in scene[scene.index('func build_roadside_grass()'):scene.index('func build_plaza()')])
check('bounded instances', 'mini(samples.size(),520)' in scene and 'multi.instance_count=count' in scene)
check('entire region candidate pass','samples.sort_custom(' in scene and 'if samples.size()>=160:break' not in scene)
check('grass gradual density',all(x in scene for x in ['d<4.1 or d>19.0','d<7.0','d<11.0','presence: float']))
check('grass dimensions short','0.23+float(k%3)*0.035' in scene)
check('shader old road mix retained','mix(ground*mix(vec3(1.0),tint,0.11),road,road_weight)' in shader)
for f in (ROOT/'textures/terrain_approved').glob('*.png'):
    im=Image.open(f)
    check('texture exists '+f.stem,im.width>=300 and im.height>=300)
check('ground atlas complete',len(list((ROOT/'textures/terrain_approved').glob('*.png')))==9)
check('deterministic resident slots', 'members.sort()' in region and 'members.find(str(person.id))' in region)
check('residents spaced more than collision capsule','float(k/2)*1.5' in region and 'base+forward*.65+side*lateral' in region)
check('square residents distributed','float(k/4)*1.35' in region)
check('NPC label only compact name','caption.text=str(identity.get("name"' in resident and 'str(identity.display_name)+"\\n"' not in resident)
check('NPC labels have outlines','caption.outline_size=6' in resident and 'caption.outline_modulate=' in resident)
check('NPC nearby separation present','separation_force' in resident and 'another==self' in resident and 'd2<2.25' in resident)
check('NPC approach maintained','if moving or not is_on_floor():move_and_slide()' in resident)
check('NPC label overlap control','func update_resident_labels() -> void:' in game and 'unproject_position(anchor)' in game)
check('label culling does not disable NPC', 'actor.caption.visible=false' in game and 'for actor in residents:' in game)
check('NPC interactions retained','actor.paused_for_talk=4' in game and 'ui.dialogue(str(actor.identity.display_name)' in game)
check('NPC save retained','save_progress()' in game and 'snapshot_region()' in game)
check('Godot version compatibility',(ROOT/'project.godot').read_text().find('gl_compatibility')>0)
# Model of the 4-person arrangement: no two stations in one building closer than 1.5m,
# assuming a walkway with sufficient length. The Godot geometry must separately confirm clearances.
positions=[(0.65,(1.25+(k//2)*1.5)*(1 if k%2==0 else -1)) for k in range(12)]
check('shared facade single row', len({p[0] for p in positions})==1)
check('door center remains clear', min(abs(p[1]) for p in positions)>=1.25)
spacing=min(math.dist(a,b) for i,a in enumerate(positions) for b in positions[i+1:])
check('shared building conceptual spacing >=1.5m', spacing>=1.5)
# Resolve all Godot res:// preloads modified scripts reference.
for path,body in content.items():
    for ref in re.findall(r'preload\("res://([^"]+)"\)',body):
        check('preload resolved '+ref, (ROOT/ref).is_file())
result={'scope':'offline source/assets/structure only; NOT a Godot runtime test',
        'passed':sum(x['pass'] for x in checks),'failed':sum(not x['pass'] for x in checks),
        'min_shared_house_spacing_m':spacing,'changes':FILES,'checks':checks,
        'godot_4_6_2':'NOT_RUN','visual_capture_in_engine':'NOT_RUN'}
(ROOT/'convergence'/'visual_refinement_offline_qa.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='checks'},ensure_ascii=False,indent=2))
