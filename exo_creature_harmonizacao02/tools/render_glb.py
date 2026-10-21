#!/usr/bin/env python3
"""CPU evidence render from actual exported glTF POSITION/index/texture, not concept art/Godot."""
from pathlib import Path
import sys,json,struct,math,io
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from numba import njit
from build_harmonizacao import parse_glb,raw_accessor,OUT,jsonout,preferred

@njit(cache=True)
def raster(canvas,depth,polys,zvals,colors):
 h,w=depth.shape
 for k in range(len(polys)):
  p=polys[k];ax,ay=p[0];bx,by=p[1];cx,cy=p[2]
  area=(bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
  if abs(area)<1e-4:continue
  x0=max(0,int(math.floor(min(ax,bx,cx))));x1=min(w-1,int(math.ceil(max(ax,bx,cx))))
  y0=max(0,int(math.floor(min(ay,by,cy))));y1=min(h-1,int(math.ceil(max(ay,by,cy))))
  for iy in range(y0,y1+1):
   py=iy+.5
   for ix in range(x0,x1+1):
    px=ix+.5
    u=((bx-px)*(cy-py)-(by-py)*(cx-px))/area
    v=((cx-px)*(ay-py)-(cy-py)*(ax-px))/area
    q=1-u-v
    if min(u,v,q)<-.00001:continue
    zv=u*zvals[k,0]+v*zvals[k,1]+q*zvals[k,2]
    if zv>depth[iy,ix]:
     depth[iy,ix]=zv
     canvas[iy,ix,:]=colors[k,:]

def render(path,eye=(2.5,2.0,3.4),width=365,height=280,vertices_override=None):
 b=Path(path).read_bytes();d,bb=parse_glb(b); prim=d['meshes'][0]['primitives'][0]
 verts=np.array(vertices_override if vertices_override is not None else raw_accessor(d,bb,prim['attributes']['POSITION']),dtype=np.float64);f=np.array(raw_accessor(d,bb,prim['indices']),dtype=np.int32).reshape(-1,3)
 uv=np.array(raw_accessor(d,bb,prim['attributes']['TEXCOORD_0']),dtype=np.float64)
 # Texture referenced through GLB image bufferView
 tex=d['images'][0]; bv=d['bufferViews'][tex['bufferView']];im=Image.open(io.BytesIO(bytes(bb[bv.get('byteOffset',0):bv.get('byteOffset',0)+bv['byteLength']]))).convert('RGB');atlas=np.asarray(im)
 vcoord=uv[f].mean(axis=1);tw,th=im.size
 coord_u=np.clip(np.floor((vcoord[:,0]%1)*tw).astype(np.int32),0,tw-1);coord_v=np.clip(np.floor((vcoord[:,1]%1)*th).astype(np.int32),0,th-1)
 facec=atlas[coord_v,coord_u].astype(np.float64)
 face_normal=np.cross(verts[f[:,1]]-verts[f[:,0]],verts[f[:,2]]-verts[f[:,0]]);norm=np.linalg.norm(face_normal,axis=1);face_normal=face_normal/np.maximum(1e-8,norm[:,None]);light=np.array([.4,.8,.5]);light/=np.linalg.norm(light)
 shading=np.clip(.61+.44*np.maximum(face_normal@light,0),.35,1.12)
 facec=np.uint8(np.clip(facec*shading[:,None],0,255))
 eye=np.array(eye,float);eye/=np.linalg.norm(eye);right=np.cross(np.array([0.,1.,0]),eye);right/=np.linalg.norm(right);up=np.cross(eye,right)
 x=verts@right;y=verts@up;z=verts@eye
 minx,maxx=np.min(x),np.max(x);miny,maxy=np.min(y),np.max(y)
 sc=min((width-52)/max(.1,maxx-minx),(height-54)/max(.1,maxy-miny));px=(x-(minx+maxx)/2)*sc+width/2;py=height/2-(y-(miny+maxy)/2)*sc
 polys=np.stack([px[f],py[f]],axis=-1);zv=z[f].copy()
 bg=np.zeros((height,width,3),np.uint8)
 for iy in range(height):
  bg[iy,:,:]=[int(28+9*iy/height),int(34+12*iy/height),int(44+15*iy/height)]
 depth=np.full((height,width),-1e9,np.float64)
 raster(bg,depth,np.asarray(polys,np.float64),np.asarray(zv,np.float64),facec)
 return Image.fromarray(bg)

fontp='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';font=ImageFont.truetype(fontp,16);small=ImageFont.truetype(fontp,12)
root=Path('/mnt/data');preview=OUT/'evidencias';preview.mkdir(exist_ok=True)
items=[(k,v['recommended_variant']['source']) for k,v in jsonout['assets_by_species'].items()]
W,H=365,320; ncols=4;sheet=Image.new('RGB',(W*ncols,math.ceil(len(items)/ncols)*H),(19,25,34))
for i,(id,source) in enumerate(items):
 f=OUT/'models'/id/(source+'.glb');rendered=render(f)
 dr=ImageDraw.Draw(rendered);dr.rectangle([0,0,365,29],fill=(18,23,33));dr.text((12,6),id.replace('_',' ').upper(),font=font,fill=(235,230,210))
 tile=Image.new('RGB',(W,H),(24,30,40));tile.paste(rendered,(0,0));dt=ImageDraw.Draw(tile);dt.text((12,286),f'{source.upper()} | GLB REAL | {id}',font=small,fill=(171,193,207))
 tile.save(preview/(id+'_frente_isometrica.png'))
 sheet.paste(tile,((i%ncols)*W,(i//ncols)*H))
sheet.save(preview/'GALERIA-MODELOS-REAIS-17-ESPECIES.png',optimize=True)

samples=['wolf','boar','tiger','snake','desert_scorpion','stone_guardian','spirit_deer','mountain_goat']
shots=[('frente_3_4',(2.5,1.8,3.2)),('perfil',(0.4,1.55,4.8)),('traseira',(-3.,1.8,-2.))]
multi=Image.new('RGB',(365*3,322*len(samples)),(23,29,39))
for i,id in enumerate(samples):
 for j,(angle,eye) in enumerate(shots):
  rec=jsonout['assets_by_species'][id];source=rec['recommended_variant']['source'];f=OUT/'models'/id/(source+'.glb')
  rend=render(f,eye=eye)
  d=ImageDraw.Draw(rend);d.rectangle((0,0,365,28),fill=(18,23,34));d.text((12,5),id+'  •  '+angle,font=small,fill=(241,227,205))
  tile=Image.new('RGB',(365,322),(24,30,40));tile.paste(rend,(0,0));ImageDraw.Draw(tile).text((12,288),source+' | modelo 3D / GLB',font=small,fill=(150,181,202));multi.paste(tile,(j*365,i*322))
multi.save(preview/'MULTIANGULOS-8-ESPECIES.png',optimize=True)
print('RENDERED',sheet.size,multi.size)
