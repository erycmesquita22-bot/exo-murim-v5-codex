from pathlib import Path
import numpy as np, random, trimesh, json
from PIL import Image,ImageDraw,ImageFilter
p=Path(__file__).resolve().parents[1];dest=p/'infrastructure_sprint05'
img=Image.new('RGB',(1024,1024),(78,129,134)); rng=np.random.default_rng(503)
noise=rng.normal(0,1,(48,72));n=Image.fromarray(np.uint8(np.clip(127+noise*33,0,255)),'L').resize((1024,1024),Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(5))
a=np.asarray(n,dtype=np.float32)-127;px=np.empty((1024,1024,3),np.uint8)
px[:,:,0]=np.uint8(np.clip(76+a*.36,0,255));px[:,:,1]=np.uint8(np.clip(127+a*.53,0,255));px[:,:,2]=np.uint8(np.clip(133+a*.56,0,255))
img=Image.fromarray(px);overlay=Image.new('RGBA',(1024,1024));d=ImageDraw.Draw(overlay,'RGBA');rand=random.Random(819)
for j in range(1800):
 x=rand.randrange(1024);y=rand.randrange(1024);w=rand.randint(4,27)
 d.arc((x-w,y-rand.randrange(2,5),x+w,y+rand.randrange(3,9)),192,336,fill=(205,223,206,rand.randint(20,75)),width=1)
for j in range(420):
 x=rand.randrange(1024);y=rand.randrange(1024);w=rand.randint(6,18)
 d.arc((x-w,y-4,x+w,y+6),20,160,fill=(35,80,91,rand.randint(25,60)),width=1)
img=Image.alpha_composite(img.convert('RGBA'),overlay).convert('RGB')
tex=dest/'EXO_Rio_Hwa_Watercolor_1024.png';img.save(tex,optimize=True)
# Reconstruct a narrow, authored water ribbon inside the real carved channel.
# Original surface crossed coarse terrain triangles, causing shoreline sawteeth.
# Never modify the physical terrain in this Sprint; water is non-collidable.
zs=np.arange(-109,111,3,dtype=float)
verts=[];faces=[]
for z in zs:
 center=66+8*np.sin((z+20)/41)+z*.045
 for sign in (-1,1):
  verts.append((center+sign*5.25,-.52,z))
for j in range(len(zs)-1):
 left=j*2;right=left+1;nl=left+2;nr=left+3
 faces.append((left,nl,right))
 faces.append((right,nl,nr))
m=trimesh.Trimesh(vertices=np.asarray(verts),faces=np.asarray(faces),process=False)
verts=m.vertices
# The original UVs repeated the full texture PER TRIANGLE, producing bright sawtooth strips.
# UV coordinate comes exclusively from stable world X/Z, even across all triangle seams.
uv=np.column_stack(((verts[:,0]-40)/56,1-(verts[:,2]+112)/224))
m.visual=trimesh.visual.texture.TextureVisuals(uv=uv,material=trimesh.visual.material.PBRMaterial(name='EXO_Hwa_River_Illustrated',baseColorTexture=img,roughnessFactor=1,metallicFactor=0,doubleSided=True))
scene=trimesh.Scene();scene.add_geometry(m,geom_name='HWA_River_S05_SeamlessWater',node_name='HWA_River_S05_SeamlessWater');scene.export(str(dest/'HWA02_River_S05.glb'))
manifest=dest/'data/manifest_sprint05.json';data=json.loads(manifest.read_text());data['river_uv_fix']={'replaced_old_visual':True,'same_geometry_as_original':False,'uv_mapping':'new water ribbon with world XZ UV and consistently upward face normals','new_visual':'infrastructure_sprint05/HWA02_River_S05.glb','water_surface_y':-.52,'boat_travel':'not implemented','shoreline_policy':'10.5m visible water ribbon stays inside existing terrain channel to prevent triangulated shoreline artifacts'};manifest.write_text(json.dumps(data,ensure_ascii=False,indent=2))
print('river GLB',m.faces.shape,'uv',uv.shape,'done')
