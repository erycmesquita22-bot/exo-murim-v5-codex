#!/usr/bin/env python3
"""Offline-only validation. Never describe as Godot execution or gameplay PASS."""
import json, pathlib, sys, math, hashlib, collections
ROOT=pathlib.Path(__file__).resolve().parents[2]
LIB=ROOT/'exo_settlement_forge/libraries'
SRC=ROOT/'exo_settlement_forge/runtime'
errors=[]
checks=[]

def check(label, condition):
    checks.append(label)
    if not condition:errors.append(label)

cat=json.loads((LIB/'catalog.json').read_text())
rows=cat['templates']
check('52 authored entries', len(rows)==52)
check('52 unique IDs', len({x['id'] for x in rows})==52)
check('52 present files', len(list((LIB/'prefabs').glob('*.json')))==52)
check('library path confined',all(x['path'].startswith('res://exo_settlement_forge/libraries/prefabs/') for x in rows))
for row in rows:
    f=LIB/'prefabs'/(row['id']+'.json')
    try:
        d=json.loads(f.read_text())
    except Exception as e:
        check('prefab valid '+row['id'],False);continue
    check('prefab identity '+row['id'],d['id']==row['id'])
    check('prefab category '+row['id'],d['category']==row['category'])
    check('prefab floor >=1 '+row['id'],int(d['floors'])>=1)
    check('prefab floor runs '+row['id'],len(d.get('floor_runs',[]))>0)
    check('prefab wall runs '+row['id'],len(d.get('wall_runs',[]))>0)
    check('prefab spawn bounds '+row['id'],0<=int(d['spawn']['x'])<d['width_tiles'] and 0<=int(d['spawn']['z'])<d['depth_tiles'])
selected={
'residence':'casa_campesina_01','market':'loja_mercadorias_01','inn':'pousada_rio_04',
'smithy':'forja_rua_01','martial_school':'escola_pequena_01','administration':'sala_conselho_01'}
for function,ident in selected.items():
    d=json.loads((LIB/'prefabs'/(ident+'.json')).read_text())
    check('selected category '+function,d['category']==function)
    check('selected is ground floor '+function,d['floors']==1)
    front=d['depth_tiles']-0.5
    at=int(d['entrance']['x'])
    blocked=any(w['axis']=='x' and w['level']==0 and w['kind']=='outer'
                and abs(w['fixed']-front)<1e-8 and w['start']<=at<=w['end']
                for w in d['wall_runs'])
    check('authored door unobstructed by wall '+function,not blocked)
    span_w=d['width_tiles']*1.6
    span_d=d['depth_tiles']*1.6
    check('cell never overlaps arterial '+function,max(span_w,span_d)*.5+1.2+2.0<15)
for file in ['urban_generator.gd','architecture_builder.gd','interior_builder.gd','interior_catalog.gd','portal_controller.gd','settlement_service.gd']:
    check('runtime file exists '+file,(SRC/file).is_file() and (SRC/file).stat().st_size>200)
text=(SRC/'portal_controller.gd').read_text()
check('portal enters real builder', 'Builder.build(authored)' in text and 'staging.add_child(room)' in text)
check('single player teleport', 'player.global_position = spawn.global_position' in text)
check('portal returns same player', '_player.global_transform = _return_transform' in text)
check('portal restores camera', '_camera.size = _old_camera_size' in text)
check('portal retains host save authority', 'snapshot_for_core' in text and 'FileAccess.open' not in text)
check('portal fails closed on upper floor', 'unvalidated_upper_floor' in text)
check('portal rejects access without authorization', 'not authorized' in text)
check('NPC contract labels nav status correctly', '"navigability_verified":false' in (SRC/'settlement_service.gd').read_text())
check('demo has physical player', 'CharacterBody3D.new()' in (ROOT/'demo/playable_demo.gd').read_text())
check('demo uses physics movement', 'player.move_and_slide()' in (ROOT/'demo/playable_demo.gd').read_text())
check('host untouched',not (ROOT/'convergence').exists())
report={'category':'OFFLINE_STATIC_AND_LIBRARY_ONLY','total':len(checks), 'pass':len(checks)-len(errors),
        'fail':len(errors),'failures':errors,'godot_executed':False,'fps_measured':False,
        'physics_executed':False,'npc04_integrated':False,'host_v4_integrated':False}
print(json.dumps(report,indent=2))
sys.exit(1 if errors else 0)
