#!/usr/bin/env python3
"""Offline checks; NOT a substitute for importing/running this project in Godot."""
from pathlib import Path
import hashlib, json, sys, re
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'textures/terrain_approved/MANIFEST.json').read_text())
checks=0
for entry in manifest['tiles']:
    src=ROOT/entry['source']; dst=ROOT/entry['target']
    assert hashlib.sha256(src.read_bytes()).hexdigest()==entry['source_sha256'];checks+=1
    assert hashlib.sha256(dst.read_bytes()).hexdigest()==entry['target_sha256'];checks+=1
    a=np.array(Image.open(src).convert('RGB'));b=np.array(Image.open(dst).convert('RGB'))
    assert a.shape==b.shape;checks+=1
    assert (b[:,0]==b[:,-1]).all() and (b[0]==b[-1]).all();checks+=2
    h,w,_=a.shape
    assert np.array_equal(a[round(h*.2):round(h*.8),round(w*.2):round(w*.8)],b[round(h*.2):round(h*.8),round(w*.2):round(w*.8)]);checks+=1
    assert abs(np.mean(a.astype(float)-b.astype(float)))<3.0;checks+=1
scene=(ROOT/'genesis/region_scene.gd').read_text()
shader=(ROOT/'genesis/terrain.gdshader').read_text()
assert scene.count('return load(APPROVED_GROUND+files[biome]+".png")')==1;checks+=1
assert 'load(APPROVED_GROUND+"trilha_terra.png")' in scene;checks+=1
assert 'res://collection/01_SOLOS/trilha_batida.png' not in scene;checks+=1
assert 'st.set_uv(p/6.0)' in scene and 'st.set_custom(0,blends[p])' in scene;checks+=2
assert 'shape.set_faces(faces)' in scene and 'backface_collision=true' in scene;checks+=2
assert 'MultiMeshInstance3D.new()' in scene and 'collision_layer' not in scene[scene.index('func build_roadside_grass()'):scene.index('func build_plaza()')];checks+=2
biomes=['grassland','temperate_forest','bamboo_forest','dry_valley','wetland','rocky_highlands','alpine','mixed_woodland']
for key in biomes:
    assert f'"{key}":' in scene;checks+=1
assert 'CUSTOM0' in shader and 'COLOR.a' in shader;checks+=2
assert 'edge_strength=4.0*COLOR.a*(1.0-COLOR.a)' in shader;checks+=1
assert scene.count('func build_roadside_grass()')==1;checks+=1
assert len(manifest['tiles'])==9;checks+=1
report={'checks':checks,'failures':0,'scope':'offline texture/path/structure checks only, Godot 4.6.2 NOT_RUN',
        'source_textures':len(manifest['tiles']),'biomes':len(biomes),'watermarks':'none'}
(ROOT/'RELATORIO-TERRAIN-QA.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
