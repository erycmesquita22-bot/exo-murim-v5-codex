"""Static-only offline tests. Native Godot engine validation is separate."""
from pathlib import Path
import json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
recipes=list((ROOT/'exo_vfx_forge'/'recipes').glob('*.json'))
assert len(recipes)==10,'Expected ten recipes'
ids=set()
for path in recipes:
    data=json.loads(path.read_text())
    assert data['vfx_id'] not in ids
    ids.add(data['vfx_id'])
    for p in ('low','medium','high'):
        assert p in data['quality_profiles']
    assert data['license_state']=='ORIGINAL_PROJECT'
    out=ROOT/'PREVIEWS-VFX-03'/data['family']
    frames=sorted(out.glob('frame_*.png'))
    assert len(frames)==16
    atlas=Image.open(out/(data['family']+'_atlas_8x2.png'))
    assert atlas.size==(4096,1024)
    for i,path in enumerate(frames):
        f=Image.open(path)
        assert f.size==(512,512) and f.mode=='RGBA'
        cropped=atlas.crop(((i%8)*512,(i//8)*512,((i%8)+1)*512,((i//8)+1)*512))
        assert hashlib.sha256(cropped.tobytes()).digest()==hashlib.sha256(f.tobytes()).digest()
print('STATIC PASS: 10 recipes, 160 RGBA frames, 10 exact atlases. Godot NOT TESTED.')
