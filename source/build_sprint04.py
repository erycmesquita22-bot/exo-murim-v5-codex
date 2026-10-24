#!/usr/bin/env python3
"""EXO Murim Sprint 04: authored ground paint cleanup and building approach paths.
Source: Sprint 03 full project. Geometry of old mesh and collisions is immutable.
All textures are authored procedural painting with deterministic seed, no third-party assets.
"""
from pathlib import Path
import json, math, hashlib, random
import numpy as np
from scipy.ndimage import zoom, gaussian_filter
from PIL import Image, ImageDraw, ImageFont
from shapely.geometry import LineString, box
from shapely.ops import nearest_points
import trimesh
ROOT=Path(__file__).resolve().parents[1]
TD=ROOT/'terrain_sprint04';TD.mkdir(exist_ok=True)
PRE=ROOT/'previews_sprint04';PRE.mkdir(exist_ok=True)
arch=json.loads((ROOT/'architecture_sprint02/manifest_sprint02.json').read_text())['placements']
R=2048
X=np.linspace(-118,118,R,dtype=np.float32)[None,:]
Z=np.linspace(-112,112,R,dtype=np.float32)[:,None]
base=np.zeros((R,R,3),np.float32)
rng=np.random.default_rng(4404)
# Non-periodic multiscale artistic pigment wash: no periodic checkerboard.
def cloudy(scale):
    sz=max(4,int(round(R/scale)))
    noise=rng.normal(0,1,(sz,sz)).astype(np.float32)
    arr=zoom(noise,(R/sz,R/sz),order=1)
    return arr[:R,:R]
large=gaussian_filter(cloudy(220),16)
mid=cloudy(58)
fine=cloudy(11)
micro=cloudy(2.5)
wash=large*10.5+mid*7+fine*3.8+micro*1.5
# Slight intrinsic cool/warm color drift across the valley. Green remains readable.
base[:,:,0]=83+wash+3*np.sin(X*.042+Z*.071)
base[:,:,1]=111+wash*.94+4*np.cos(X*.038-Z*.029)
base[:,:,2]=76+wash*.83+4*np.sin(Z*.03)
# Road axes are the same as the Sprint 01 village layout.
roads=[([(-14,-112),(-14,-94),(-12,-76),(-9,-54),(-8,-34),(-11,-11),(-11,6),(-14,27),(-13,46),(-9,70),(-10,98)],4.1),
([(-10,-19),(-22,-19),(-35,-21),(-48,-21)],3.6),
([(-11,4),(2,6),(18,10),(29,21),(39,38),(44,44)],3),
([(-14,39),(-29,48),(-48,62),(-65,83)],2.7),
([(-12,-53),(4,-53),(14,-41),(31,-33)],2.8),
([(12,-35),(24,-22),(39,-13),(44,-9)],2.6)]
segments=[(a,b,w) for points,w in roads for a,b in zip(points[:-1],points[1:])]
mainpaths=[LineString(a) for a,w in roads]
allroads=LineString([(-14,-112),(-14,-94)])
# Distance-to-path layer, computed at 1/2 res then bilinear upscale (fine at ~11 cm / pixel).
D=1024;xx=np.linspace(-118,118,D,dtype=np.float32)[None,:];zz=np.linspace(-112,112,D,dtype=np.float32)[:,None]
def path_mask(seglist):
    out=np.zeros((D,D),np.float32)+999
    for (ax,az),(bx,bz),width in seglist:
        vx=bx-ax;vz=bz-az
        t=np.clip(((xx-ax)*vx+(zz-az)*vz)/(vx*vx+vz*vz+1e-7),0,1)
        d=np.sqrt((xx-ax-vx*t)**2+(zz-az-vz*t)**2)-width*.5
        out=np.minimum(out,d)
    return out
# Add authored doorway approaches. Never relocate residences or extend roads across the river.
obstacles=[]
for p in arch:
    if not p['id'].startswith('FAMILY_COURTYARD'):
        w,d=p['dimensions']; x,z=p['x'],p['z']
        obstacles.append((p['id'],box(x-w*.5-0.35,z-d*.5-.35,x+w*.5+.35,z+d*.5+.35)))
approaches=[]
for p in arch:
    if p['id'].startswith('FAMILY_COURTYARD'):continue
    x,z=p['x'],p['z'];w,d=p['dimensions']; yaw=p['yaw']
    # Main entrance faces local +Z on this original architectural kit.
    face=np.array([math.sin(yaw),math.cos(yaw)])
    door=np.array([x,z])+face*(d/2+1.15)
    best=None
    for mainline in mainpaths:
        other=nearest_points(LineString([tuple(door),tuple(door+.01)]),mainline)[1]
        dest=np.array([other.x,other.y]); length=float(np.linalg.norm(dest-door))
        if length>27:continue
        conn=LineString([door,dest]); hits=sum(1 for name,rec in obstacles if name!=p['id'] and conn.intersects(rec))
        # We prefer unobstructed approaches and do not force links through buildings.
        score=length+hits*120
        if best is None or score<best[0]:best=(score,dest,hits,length)
    if best is not None and best[2]==0:
        dest=best[1]
        # explicit threshold/step + connecting trail segment
        approaches.append({'from':p['id'],'door':[round(float(v),2) for v in door],'road':[round(float(v),2) for v in dest],'distance_m':round(best[3],1)})
        segments.append((tuple(door),tuple(dest),1.65))
    else:
        approaches.append({'from':p['id'],'door':[round(float(v),2) for v in door],'road':None,'distance_m':None,'status':'manual_placement_pending'})
roadDist=path_mask(segments)
# Edge deformation at consistent world coordinates; blend into worn earth not sharp stripes.
edge=.33*np.sin(xx*.63+zz*.29)+.18*np.sin(zz*.97-xx*.31)+.12*np.cos(xx*1.67+zz*.27)
roadDist+=edge
# apron near buildings and tea house avoids grass ending flush at walls
apron=np.ones((D,D),np.float32)*999
for name,rec in obstacles:
    x0,z0,x1,z1=rec.bounds
    dx=np.maximum(np.maximum(x0-xx,xx-x1),0); dz=np.maximum(np.maximum(z0-zz,zz-z1),0)
    dist=np.sqrt(dx*dx+dz*dz)
    apron=np.minimum(apron,dist)
# large village yard / farm family courtyard; the previous map had square stone patches,
# now make edges worn rather than ruler-straight.
def rect_distance(cx,cz,hw,hd):
    dx=np.maximum(np.abs(xx-cx)-hw,0);dz=np.maximum(np.abs(zz-cz)-hd,0)
    return np.sqrt(dx*dx+dz*dz)
plaza=np.minimum(rect_distance(-11,5,8.7,7.4),rect_distance(-48,-32,12.5,9.7))
river_center=66+8*np.sin((zz+20)/41)+zz*.045
bank=np.abs(xx-river_center)
# agricultural soil only in terraced fields west/south, not on roads.
rice=np.ones((D,D),np.float32)*999
for j in range(3):
  for k in range(2):
    cx=-91+j*17;cz=37+k*22
    if cx<-80 and cz>65:continue
    rice=np.minimum(rice,rect_distance(cx,cz,6.7,8.7))
# blend curve soft border 1.5–3m, terrain remains exactly same physical mesh
smooth=lambda a:np.clip(a,0,1)
rd=smooth((2.4-roadDist)/3.7)
side=smooth((6.1-roadDist)/5.6)*.47
ap=smooth((2.0-apron)/2.8)*.56
stone=smooth((1.5-plaza-.25*np.sin(xx*.61+zz*.42))/2.6)
wet=smooth((21-bank)/10)*.52
rice_mask=smooth((1.6-rice)/2.1)*.60
# Ground high/low palette over non-periodic color drift.
def up(a):
    return np.asarray(Image.fromarray(np.uint8(np.clip(a*255,0,255))).resize((R,R),Image.Resampling.BICUBIC),dtype=np.float32)/255

def mix(rgb,alpha):
    global base
    a=up(alpha)
    base=base*(1-a[:,:,None])+np.asarray(rgb,dtype=np.float32)[None,None,:]*a[:,:,None]+wash[:,:,None]*a[:,:,None]*.32
mix((143,119,91),side)
mix((183,149,110),rd)
mix((164,147,121),ap)
mix((157,158,141),stone)
mix((106,130,99),wet)
mix((108,99,77),rice_mask)
# Transparent painted strokes: uneven darker paint under pavers and winding loose grit.
final=Image.fromarray(np.uint8(np.clip(base,0,255)),'RGB').convert('RGBA')
draw=ImageDraw.Draw(final,'RGBA')
rand=random.Random(51023)
def coord(x,z):return ((x+118)/236*R,(z+112)/224*R)
# Small independent details with no repetitive tiles; all markings are in map coordinates.
for i in range(10000):
    x=rand.uniform(-116,116);z=rand.uniform(-110,110)
    px,py=coord(x,z)
    # sample base pigment; draw dainty ink grass clusters in grassy regions
    v=final.getpixel((min(R-1,int(px)),min(R-1,int(py))))
    if v[1]>v[0]*1.13 and v[1]>v[2]*1.17:
        width=rand.uniform(1.4,5.2)
        col=(35,65,46,rand.randint(40,92)) if rand.random()<.72 else (176,179,109,rand.randint(35,80))
        draw.arc((px-width,py-width*.75,px+width,py+width*.8),190,310,fill=col,width=1)
        if rand.random()<.22:
            draw.line((px-1,py+3,px+2,py-3),fill=(24,63,38,78),width=1)
    elif rand.random()<.65:
        rad=rand.choice([.6,.7,1.1,1.4,2.1])
        col=(79,66,59,rand.randint(35,75)) if rand.random()<.5 else (242,218,171,rand.randint(30,65))
        draw.ellipse((px-rad,py-rad*.7,px+rad,py+rad*.7),fill=col)
# Older village stone courtyard: draw fine irregular joints, not even square tiles.
for cx,cz,r1,r2 in [(-11,5,7.8,6.6),(-48,-32,11.8,8.8)]:
    for iz in np.arange(cz-r2+.8,cz+r2,1.7):
        stagger=rand.uniform(-.6,.6)
        for ix in np.arange(cx-r1+1,cx+r1,2.45):
            if abs(ix+stagger-cx)>r1-1:continue
            xx0,yy0=coord(ix+stagger,iz)
            width=rand.uniform(8,14)
            draw.arc((xx0-width*.5,yy0-3,xx0+width*.8,yy0+3),12,168,fill=(53,58,57,42),width=1)
# gentle wheel ruts along the main road in a few segments, broken/interrupted for ink style
for (ax,az),(bx,bz),w in segments[:12]:
    vx=bx-ax;vz=bz-az;L=max(.1,math.hypot(vx,vz));nx=-vz/L;nz=vx/L
    for offset in (-.75,.8):
        for t in np.arange(.13,.9,.075):
            if rand.random()<.18:continue
            x0=ax+vx*t+nx*offset;z0=az+vz*t+nz*offset
            x1=ax+vx*min(.96,t+.05)+nx*offset;z1=az+vz*min(.96,t+.05)+nz*offset
            draw.line((*coord(x0,z0),*coord(x1,z1)),fill=(91,76,60,49),width=1)
final=final.convert('RGB')
texture=TD/'EXO_Haneul_Ground_Polished_S04_2048.png';final.save(texture,optimize=True)
# Replace the embedded original terrain texture WITHOUT changing mesh, UV or elevation.
# Pull canonical untouched terrain geometry from the BASE environment, not from an obsolete terrain-asset version.
source=ROOT/'model/HWA02_Nature_And_TerrainCollision_S02.glb'
original=trimesh.load(source,force='scene',process=False)
mesh=original.geometry['Terrain'].copy()
vs=mesh.vertices.copy(); fs=mesh.faces.copy()
# World-space planar UVs: X and Z, no dependency on atlas UVs of the legacy art.
uvs=np.column_stack(((vs[:,0]+118.0)/236.0, 1.0-(vs[:,2]+112.0)/224.0))
mesh.visual=trimesh.visual.texture.TextureVisuals(uv=uvs, material=trimesh.visual.material.PBRMaterial(name='EXO_Murim_InkGround_S04_Polished',baseColorTexture=final,metallicFactor=0.,roughnessFactor=1.,doubleSided=True))
# Smooth normals across duplicated vertices that share the same physical X/Z grid point.
# Before this correction the GLB produces dramatic concentric facet bands under sunlight.
from collections import defaultdict
acc=np.zeros_like(vs,dtype=np.float64); adj=defaultdict(list)
for i,v in enumerate(vs):adj[(round(float(v[0]),3),round(float(v[2]),3))].append(i)
for tri,n in zip(fs,mesh.face_normals):
    for i in tri:acc[i]+=n
for group in adj.values():
    mean=acc[group].sum(axis=0);mean/=max(np.linalg.norm(mean),1e-8)
    acc[group]=mean
mesh.vertex_normals=acc
scene=trimesh.Scene();scene.add_geometry(mesh,geom_name='Terrain_InkGround',node_name='Terrain_InkGround')
meshfile=TD/'HWA02_Terrain_Murim_Polished_S04.glb';scene.export(str(meshfile))
loaded=next(iter(trimesh.load(meshfile,force='scene',process=False).geometry.values()))
assert np.allclose(loaded.vertices,vs) and np.array_equal(loaded.faces,fs) and np.allclose(loaded.visual.uv,uvs)
# Review print: full-world map and detail crop of village square
font=None
try:font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22)
except:pass
preview=final.resize((950,950),Image.Resampling.LANCZOS)
pd=ImageDraw.Draw(preview)
pd.text((18,18),'EXO MURIM  /  HWA02  /  SOLO POLIDO S04',font=font,fill=(238,230,196),stroke_width=2,stroke_fill=(31,48,40))
preview.save(PRE/'01_TERRAIN_FULLMAP_S04.png')
# Independent mini-panels (actual texture crops, not mockups)
points=[('PRACA',-11,5),('ESTRADA',-12,35),('SOLAR',-48,-32),('MARGEM',52,5)]
board=Image.new('RGB',(1050,1090),(238,232,217));bd=ImageDraw.Draw(board)
for i,(label,cx,cz) in enumerate(points):
    left,top=coord(cx-23,cz-23); right,bottom=coord(cx+23,cz+23)
    crop=final.crop((int(left),int(top),int(right),int(bottom))).resize((505,500),Image.Resampling.LANCZOS)
    sx=10+(i%2)*525;sy=10+(i//2)*540
    board.paste(crop,(sx,sy));bd.text((sx+15,sy+465),label,font=font,fill=(255,246,214),stroke_width=2,stroke_fill=(22,39,35))
board.save(PRE/'02_SOLO_QUATRO_ZONAS_S04.png')
report={'sprint':'04','ground_mesh_preserved_exactly':True,'ground_vertices':len(vs),'ground_triangles':len(fs),'architecture_count':len(arch),'connected_entrances':sum('road' in v and v['road'] is not None for v in approaches),'approaches':approaches,'texture_resolution':[R,R], 'textures':{'world':str(texture.relative_to(ROOT)),'glb':str(meshfile.relative_to(ROOT))},'source_provenance':'original procedural authoring, no borrowed art'}
(TD/'manifest_sprint04.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf8')
print('SPRINT04_TERRAIN_DONE',json.dumps({'approaches':report['connected_entrances'],'triangles':len(fs),'texture':str(texture)}),flush=True)
