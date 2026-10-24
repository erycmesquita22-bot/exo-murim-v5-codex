#!/usr/bin/env python3
"""EXO HWA-02 hand-authored geometry-preserving Murim terrain material sprint.
Pillow + numpy + trimesh; original illustrations are programmatic brush strokes,
not borrowed assets. Terrain baked in atlas coordinates, no embedded game character changes.
"""
from pathlib import Path
import math, os, shutil, json, random, hashlib, time
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import trimesh
ST=time.time(); SRC=Path(os.environ.get('EXO_BASE_PROJECT', Path(__file__).resolve().parents[1])).resolve()
DST=Path(os.environ.get('EXO_REBUILD_DESTINATION', SRC.parent / (SRC.name+'_REPAINTED'))).resolve()
if SRC == DST:raise RuntimeError('Never rebuild into active project path; choose a separate EXO_REBUILD_DESTINATION')
if DST.exists():shutil.rmtree(DST)
shutil.copytree(SRC,DST,ignore=shutil.ignore_patterns('.godot','*.import'))
TD=DST/'terrain_sprint01'; TD.mkdir(); (TD/'tiles').mkdir(); (DST/'previews').mkdir(exist_ok=True)
PRE=DST/'previews'; rng=random.Random(10603)
S=512
TILES=[
 ('grama_bambu','#58794e','grass'),('grama_pinheiros','#496b4a','grass'),('grama_sol','#7c9857','grass'),('grama_sombra','#375b49','grass'),
 ('terra_rural','#94795e','soil'),('terra_ocre','#b18d68','soil'),('estrada_batida','#c2a17d','path'),('trilha_escura','#957657','path'),
 ('margem_sedimento','#b5a48b','bank'),('margem_umida','#766e60','bank'),('pedra_praca','#a4a395','stone'),('pedra_antiga','#868b80','stone'),
 ('grama_flores','#68865b','flowers'),('grama_escassa','#87916a','grass'),('solo_arrozal','#685947','field'),('cascalho_fino','#908374','pebble')]

def rgbs(hex):return np.array([int(hex[j:j+2],16) for j in (1,3,5)],dtype=np.float32)
def mixrgb(base,n):return tuple(max(0,min(255,int(v+n))) for v in base)

def stamped(draw,kind,x,y,scale,base,seed):
    # Periodic painting guarantees visually seamless edges.
    for ox in (-S,0,S):
      for oy in (-S,0,S):
        xx=x+ox; yy=y+oy
        if not (-32<xx<S+32 and -32<yy<S+32):continue
        if kind in ('grass','flowers'):
          w=scale; grassdark=mixrgb(base,-48); light=mixrgb(base,45)
          # Calligraphic tufts; ink strokes fade toward the tip.
          cc=grassdark+(seed.randrange(65,170),);cs=light+(seed.randrange(60,155),)
          draw.line([(xx-w*.72,yy+w*.36),(xx-w*.27,yy-w*.4),(xx,yy-w*.64)],fill=cc,width=1)
          draw.line([(xx+w*.18,yy+w*.47),(xx+w*.14,yy-w*.3),(xx+w*.48,yy-w*.55)],fill=cc,width=1)
          draw.arc((xx-w*.3,yy-w*.6,xx+w*.6,yy+w*.4),190,290,fill=cs,width=1)
          if kind=='flowers' and seed.random()<.10:
             c=seed.choice([(245,222,173,230),(238,214,207,220),(246,240,214,225)])
             r=seed.choice([2,3,4]); draw.ellipse((xx-r,yy-r,xx+r,yy+r),fill=c)
             draw.ellipse((xx-1,yy-1,xx+1,yy+1),fill=(150,114,61,230))
        elif kind in ('soil','path','bank','field','pebble'):
          r=seed.randint(1,4) if kind!='pebble' else seed.randint(2,6)
          cc=mixrgb(base,seed.choice([-45,-26,24,34]))+(seed.randint(56,190),)
          draw.ellipse((xx-r*1.8,yy-r*.7,xx+r*1.8,yy+r*.9),fill=cc)
          if kind in ('soil','path','field') and seed.random()<.3:
            draw.arc((xx-6,yy-3,xx+10,yy+5),180,330,fill=mixrgb(base,-38)+(seed.randint(85,130),),width=1)
        else:
          cc=mixrgb(base,-35)+(seed.randint(100,210),)
          # Irregular ancient stone joints, avoids an obvious modern square tile grid.
          if seed.random()<.4:
            draw.line([(xx,yy),(xx+scale*2.0,yy-1),(xx+scale*2.5,yy+scale*.32)],fill=cc,width=2)
          else:
            draw.line([(xx,yy),(xx+scale*.1,yy+scale),(xx+scale*1.3,yy+scale*1.4)],fill=cc,width=1)

def make_tile(name,hx,kind,n):
  base=rgbs(hx); y,x=np.mgrid[0:S,0:S].astype(np.float32)
  # Seamless periodic pigment wash, with handcrafted grain.
  wave= 9*np.sin(2*np.pi*x/S*2+.31*n)*np.cos(2*np.pi*y/S*3+.61*n) + 4.7*np.cos(2*np.pi*x/S*5+1.3*n)*np.sin(2*np.pi*y/S*4+.2*n)
  wave+=3.5*np.cos(2*np.pi*x/S*7+1.9*n)*np.cos(2*np.pi*y/S*8+2.8*n)
  seed=np.random.default_rng(2039+n*139);grain=seed.normal(0,2.2,(S,S))
  out=np.zeros((S,S,3),np.uint8)
  out[:,:,0]=np.clip(base[0]+wave+grain+2,0,255)
  out[:,:,1]=np.clip(base[1]+wave*.86+grain,0,255)
  out[:,:,2]=np.clip(base[2]+wave*.65+grain-1,0,255)
  img=Image.fromarray(out,'RGB').convert('RGBA');d=ImageDraw.Draw(img,'RGBA');seed=random.Random(6673+n*127)
  count=700 if kind in ('grass','flowers') else (470 if kind in ('soil','path','pebble') else 310)
  for q in range(count):
    xx=seed.randrange(S);yy=seed.randrange(S);ss=seed.randrange(3,11)
    stamped(d,kind,xx,yy,ss,base,seed)
  if kind in ('stone',):
    for row in range(0,S,89):
      for col in range(0,S,102):
        xx=col+seed.randrange(-23,24); yy=row+seed.randrange(-18,19)
        for ox in (-S,0,S):
          for oy in (-S,0,S):
            p=(xx+ox,yy+oy)
            d.arc((p[0]-18,p[1]-5,p[0]+60,p[1]+34),190,350,fill=tuple(mixrgb(base,-40))+(80,),width=2)
  # Preserve material appearance: all opaque, authored, no tile border.
  img=img.convert('RGB');img.save(TD/'tiles'/f'{name}_512.png',optimize=True)
  return img
print('Creating original illustrated tiles...',flush=True)
tiles=[]
for k,(n,h,kind) in enumerate(TILES):tiles.append(make_tile(n,h,kind,k))
AT=Image.new('RGB',(2048,2048))
for k,t in enumerate(tiles):AT.paste(t,((k%4)*512,(k//4)*512))
AT.save(TD/'EXO_Murim_16_Materiais_2048.png',optimize=True)
# Artistic labeled sheet, shows actual textures (does NOT replace their exact PNG).
board=Image.new('RGB',(1450,1590),'#e8e3d8');db=ImageDraw.Draw(board)
try:
 font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20)
 fhead=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',34)
except:font=None;fhead=None
db.text((30,20),'EXO MURIM  /  TERRAIN PALETTE 01',fill='#292f2c',font=fhead)
db.text((31,66),'16 superficies originais  •  pintura ilustrada, tinta e pigmentos naturais',fill='#5a665e',font=font)
for k,(n,h,kind) in enumerate(TILES):
 col=k%4;row=k//4;x=32+col*356;y=112+row*363
 view=tiles[k].resize((332,322),Image.Resampling.BICUBIC)
 board.paste(view,(x,y));db.rectangle((x-1,y-1,x+333,y+322),outline='#252d28',width=2)
 db.text((x+5,y+327),n.upper().replace('_',' '),fill='#29322f',font=font)
board.save(PRE/'01_PALETA_16_TEXTURAS_MURIM.png',optimize=True)

# Surface paint in global XY atlas coordinates (Godot X/Z). The geometry is unchanged.
# Bake a 4096 world map with soft paint strokes -- zero procedural checkerboard faces.
RES=2048; M=768
xm=np.linspace(-118,118,M,dtype=np.float32)[None,:]
zm=np.linspace(-112,112,M,dtype=np.float32)[:,None]
roads=[([(-14,-112),(-14,-94),(-12,-76),(-9,-54),(-8,-34),(-11,-11),(-11,6),(-14,27),(-13,46),(-9,70),(-10,98)],4.1),([(-10,-19),(-22,-19),(-35,-21),(-48,-21)],3.6),([(-11,4),(2,6),(18,10),(29,21),(39,38),(44,44)],3),([(-14,39),(-29,48),(-48,62),(-65,83)],2.7),([(-12,-53),(4,-53),(14,-41),(31,-33)],2.8),([(12,-35),(24,-22),(39,-13),(44,-9)],2.6)]
D=np.ones((M,M),np.float32)*500
for pts,w in roads:
 for (ax,az),(bx,bz) in zip(pts[:-1],pts[1:]):
  t=np.clip(((xm-ax)*(bx-ax)+(zm-az)*(bz-az))/((bx-ax)**2+(bz-az)**2+1e-5),0,1)
  ds=np.sqrt((xm-ax-t*(bx-ax))**2+(zm-az-t*(bz-az))**2)-w*.5
  D=np.minimum(D,ds)
# Courtyard + Family estate floor: fixed architecture has actually referenced these zones.
rect=lambda x,z,cx,cz,hx,hz:np.maximum(abs(x-cx)-hx,abs(z-cz)-hz)
court=np.minimum(rect(xm,zm,-11,5,12,10),rect(xm,zm,-48,-35,13,9))
# Inner family hall courtyard is stone; let garden rows remain far from it.
pave=np.minimum(rect(xm,zm,-48,-32,13,11),rect(xm,zm,-11,5,7.8,6))
# Buildings have narrow packed-earth apron to prevent grass growing directly through walls.
anchors=[(-7,-11,7,6), (8,-34,5,4),(30,15,5,4),(31,38,4.5,4),(-47,47,6,5),(-23,52,5,4),(12,-65,5,4),(4,23,5,5),(-30,17,6,5),(8,59,5,4),(28,-17,6,5),(-70,70,5,4),(-48,-52,10,6),(-65,-39,7,5),(-31,-39,7,5)]
apron=np.ones((M,M),np.float32)*500
for cx,cz,hx,hz in anchors:apron=np.minimum(apron,rect(xm,zm,cx,cz,hx,hz))
center=66+8*np.sin((zm+20)/41)+zm*.045
river=np.abs(xm-center)
river_mask=np.clip((16.0-river)/8.,0,1)
# Texture boundaries are soft and brushlike, jittered in *world* coordinates.
ink_brush=(.64*np.sin(xm*.37+np.cos(zm*.13)*2.1)+.28*np.cos(zm*.91+xm*.21)+.22*np.sin(xm*1.16-zm*.65))
D=D+ink_brush*.5
np.set_printoptions(suppress=True)
roadmask=np.clip((2.4-D)/3.6,0,1)
soilmask=np.clip((6.3-D)/4.5,0,1)*.62
apronmask=np.clip((3.0-apron)/3.3,0,1)*.67
stone=np.clip((1.8-pave)/2.0,0,1)
riverbank=np.clip((18-river)/7,0,1)
# Tile variety influenced by natural slopes, never random square cells.
meadow_noise=(np.sin(xm*.07+zm*.025)*np.cos(zm*.09-xm*.021)+.28*np.sin(xm*.17-zm*.08))
grassmix=np.clip(.35+meadow_noise*.27,0,1)
# downsample masks then upscale antialiased to scene resolution
pilmask=lambda a:Image.fromarray(np.clip(a*255,0,255).astype(np.uint8)).resize((RES,RES),Image.Resampling.BICUBIC)
print('Building atlas-space splat masks...',flush=True)
# sample repeatable painted tiles at global world positions. We sample texture at 6 m per repeat, scattering frequencies by material.
x=np.linspace(-118,118,RES,dtype=np.float32)[None,:]
z=np.linspace(-112,112,RES,dtype=np.float32)[:,None]
u0=((x+250.0)/6.0*512).astype(np.int32)%512
v0=((z+250.0)/6.0*512).astype(np.int32)%512
u1=((x+181.0)/5.25*512).astype(np.int32)%512
v1=((z+92.0)/5.25*512).astype(np.int32)%512
u2=((x+92.0)/4.6*512).astype(np.int32)%512
v2=((z+216.0)/4.6*512).astype(np.int32)%512

def sample(idx,uu=u0,vv=v0):
   a=np.asarray(tiles[idx]);return a[vv,uu].astype(np.float32)

def blend_to(arr,mask,idx,uu=u0,vv=v0,amt=1):
   m=np.asarray(pilmask(mask),np.uint8).astype(np.float32)/255.*amt
   deltas=(sample(idx,uu,vv)-arr)*m[:,:,None]
   arr+=deltas;del m,deltas

def mask_to_arr(mask):return np.asarray(pilmask(mask),np.uint8).astype(np.float32)/255
print('Painting unified ground albedo 2048...',flush=True)
# material 0 base grass with ink-wash variation and grass brightness.
arr=sample(0,u0,v0)
blend_to(arr,grassmix*.68,2,u1,v1)
blend_to(arr,np.clip((-meadow_noise-.25)*.38,0,.32),1,u2,v2)
blend_to(arr,np.clip((meadow_noise-.8)*.16,0,.18),12,u2,v2)
blend_to(arr,soilmask,4,u1,v1)
blend_to(arr,apronmask,5,u2,v2)
blend_to(arr,roadmask*.88,6,u1,v1)
blend_to(arr,stone,10,u0,v0)
blend_to(arr,riverbank*.72,8,u2,v2)
# path middle slightly worn, earthy center without bright repetitive rings
blend_to(arr,np.clip((1.25-D)/3.8,0,1)*.24,7,u0,v0)
# rice paddy fields are already physical separate patches; blend compact soil around them.
field=np.zeros((M,M),np.float32)
for cx,cz in [(-92,37),(-75,37),(-58,37),(-92,59),(-75,59),(-58,59)]:
 field=np.maximum(field,np.clip((3.0-rect(xm,zm,cx,cz,8.0,9.5))/4,0,1))
blend_to(arr,field*.48,14,u1,v1)
# Tiny ambient hand-painted speckle with small amplitude, no checkerboard.
arr=np.clip(arr,0,255).astype(np.uint8)
mapfile=TD/'EXO_Haneul_Ground_Painted_2048.png'

finished=Image.fromarray(arr,'RGB').filter(ImageFilter.GaussianBlur(radius=1.15))
finished=ImageEnhance.Brightness(finished).enhance(.87)
finished=ImageEnhance.Color(finished).enhance(.96)
finished.save(mapfile,optimize=True)
# visualization of entire terrain texture from directly baked albedo (truthful preview).
whole=Image.open(mapfile)
whole.resize((1400,1400),Image.Resampling.LANCZOS).save(PRE/'02_TEXTURA_TERRENO_APLICADA_MAPA.png',optimize=True)
# The original Terrain mesh is the exact collision reference; keeps every height,
# removes all 1.5m tile-grid UV discontinuities.
print('Exporting geometry with exact existing terrain vertices...',flush=True)
base=trimesh.load(str(SRC/'model/HWA02_Nature_And_TerrainCollision_S02.glb'),force='scene',process=False)
org=base.geometry['Terrain']
verts=np.asarray(org.vertices).copy()
uv=np.column_stack(((verts[:,0]+118.)/236.,1-(verts[:,2]+112.)/224.))
faces=org.faces.copy()
# Face orientation check; render upward for lighting; collision stays in source scene.
fn=np.cross(verts[faces[:,1]]-verts[faces[:,0]],verts[faces[:,2]]-verts[faces[:,0]])
if float(np.mean(fn[:,1]))<0:faces=faces[:,[0,2,1]]
mesh=trimesh.Trimesh(vertices=verts,faces=faces,process=False)
mesh.visual=trimesh.visual.texture.TextureVisuals(uv=uv,material=trimesh.visual.material.PBRMaterial(name='EXO_Murim_InkGround_Sprint1',baseColorTexture=whole,metallicFactor=0,roughnessFactor=1,doubleSided=True))
scene=trimesh.Scene();scene.add_geometry(mesh,geom_name='Terrain_InkGround',node_name='Terrain_InkGround')
meshpath=TD/'HWA02_Terrain_Murim_Sprint01.glb';scene.export(str(meshpath))
# KEEP game motion character V3 untouched. Only visuals hidden and new terrain instantiated.
gd=DST/'godot/HWA02_Motion_V3.gd';text=gd.read_text(encoding='utf8')
needle='    haneul_scene.name = "HaneulEnvironment"\n    add_child(haneul_scene)'
rep='''    haneul_scene.name = "HaneulEnvironment"
    add_child(haneul_scene)
    # Terrain Sprint 01 ONLY: preserve Haneul physics mesh as invisible collision source.
    # Hide old checkered terrain and raised road ribbons; new surface matches same XYZ vertices.
    for n in haneul_scene.find_children("*", "MeshInstance3D", true, false):
        if n.name in ["Terrain", "Roads"]:
            n.visible = false
    var ink_terrain: Node3D = load("res://terrain_sprint01/HWA02_Terrain_Murim_Sprint01.glb").instantiate()
    ink_terrain.name = "EXO_Haneul_Terrain_InkPainted"
    add_child(ink_terrain)'''
assert needle in text, 'Old terrain insertion anchor missing'
gd.write_text(text.replace(needle,rep),encoding='utf8')
# Art direction and QA notes; no new scripts changing locomotion.
(TD/'README.md').write_text('''# EXO-Murim — Terrain Sprint 01 / HWA-02

Original Murim/manhwa painting applied to the ACTUAL Godot terrain GLB.

## Deliverables
- `HWA02_Terrain_Murim_Sprint01.glb`: same mesh as V0.4 ground, with continuous world-space UV mapping and one embedded 2048 albedo texture.
- `EXO_Haneul_Ground_Painted_2048.png`: world albedo (RGBA free RGB); roads/courtyard/riverbank blended in author-defined physical positions.
- `EXO_Murim_16_Materiais_2048.png` plus `tiles/*.png`: 16 original individual seamless painted materials, editable/reusable.
- `previews/01_PALETA_16_TEXTURAS_MURIM.png` and `previews/02_TEXTURA_TERRENO_APLICADA_MAPA.png`: actual textures supplied, not illustrations substituted for assets.

## Installation
Open `project.godot` in Godot 4.7.2 and press F5. The original `Terrain` and `Roads` objects are visually hidden in the HWA02 scene; their collision remains in place. The replacement surface has **exactly the original terrain vertices**, preventing visual/physics mismatches from new interpolation.

## Scope
Sprint 1 ground ONLY. Buildings, river water, foliage meshes, character mesh, V3 movement/combat, AI and NPCs unchanged. Ground is fixed, no random region repositioning. Family banners still vary by seed.

## Limitations / QA
This is a stylized hand-directed **procedurally drawn** texture: strokes and masks are authored with source code; not manually illustrated by a human painter. It is our original work, not borrowed commercial content. 2048 atlas may be too large for some Android hardware and requires later sizing benchmarks/ETC2 import profile. Final visual quality needs user approval, especially close-up ground-to-building contacts and water edges.
''',encoding='utf8')
(DST/'README_SPRINT01.md').write_text('''# EXO-MURIM / HANEUL / TERRAIN SPRINT 01

This is the full Godot 4.7.2 Compatibility project, derived solely from Haneul V0.4 Character Motion V3. Install cleanly: extract to its own folder, **do not merge over an older project**. Open `project.godot`, press F5. 

**Changed:** one terrain GLB and its world-space painted material; GDScript environment visual replacement; original reusable 16-tile terrain kit. **Not changed:** player controller, 15 animations, buildings, river objects, simulation.

Texture preview: `previews/01_PALETA_16_TEXTURAS_MURIM.png` and `previews/02_TEXTURA_TERRENO_APLICADA_MAPA.png`.
''',encoding='utf8')
# Record exact source hashes and geometric invariants.
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report={'schema':'exo.murim.terrain.sprint01.v1','project':'EXO Haneul HWA02','engine':'Godot 4.7.2 / Compatibility','terrain_triangles':len(mesh.faces),'source_terrain_triangles':len(org.faces),'geometry_exact':bool(np.allclose(mesh.vertices,org.vertices)), 'world_paint_resolution':[RES,RES], 'palette_count':len(tiles), 'sources':{'base_v04_glb_sha256':sha(SRC/'model/HWA02_Nature_And_TerrainCollision_S02.glb'),'sprint01_glb_sha256':sha(meshpath),'worldpaint_sha256':sha(mapfile)},'scope':'ground mesh texture only; preserve collisions and movement'}
(DST/'terrain_sprint01/manifest.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
print('DONE',json.dumps(report), 'seconds',round(time.time()-ST,1),flush=True)
