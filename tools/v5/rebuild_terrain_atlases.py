#!/usr/bin/env python3
"""Pack the current manifest's owned PNGs without altering their artwork.
Each 256px tile has an 8px periodic gutter; manifest and shader use 272px cells.
"""
from pathlib import Path
import json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
manifest=json.loads((ROOT/'exo_terrain_forge/worldgen/terrain_texture_manifest.json').read_text())
materials={x['id']:x for x in manifest['materials']}
checks=[]
for name,spec in manifest['runtime_atlases'].items():
    columns,rows=int(spec['columns']),int(spec['rows'])
    atlas=Image.new('RGBA',(columns*272,rows*272))
    for key,tile in spec['tiles'].items():
        source=materials[key]
        path=ROOT/source.get('optimized_path',source['path']).removeprefix('res://')
        image=Image.open(path).convert('RGBA')
        if image.size!=(256,256):raise ValueError((str(path),image.size))
        # Periodic wrap, including corners; no stretched outer texels.
        padded=Image.new('RGBA',(272,272))
        for y in range(-1,2):
            for x in range(-1,2):padded.paste(image,(8+x*256,8+y*256))
        offset=(int(tile['col'])*272,int(tile['row'])*272)
        atlas.paste(padded,offset)
        crop=atlas.crop((offset[0]+8,offset[1]+8,offset[0]+264,offset[1]+264))
        assert crop.tobytes()==image.tobytes()
        checks.append({'atlas':name,'tile':key,'source':str(path.relative_to(ROOT)),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'exact_pixel_match':True})
    assert list(atlas.size)==spec['resolution']
    atlas.save(ROOT/spec['path'].removeprefix('res://'))
(ROOT/'docs/v5/terrain-atlas-packing.json').write_text(json.dumps(checks,indent=2)+'\n')
print('Packed',len(checks),'tiles; exact source pixels and periodic gutters verified.')
