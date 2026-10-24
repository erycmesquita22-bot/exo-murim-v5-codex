"""EXO S07 original authored route to Yunseong outskirts. Python 3, PIL, numpy, scipy, trimesh.
Produces geometry+painted assets; no third-party mesh or texture assets.
"""
from pathlib import Path
from math import sin,cos,pi,exp
import json,random
import numpy as np
from scipy.ndimage import gaussian_filter
from PIL import Image,ImageDraw,ImageFont
import trimesh
ROOT=Path(__file__).resolve().parents[1]; (ROOT/'models').mkdir(exist_ok=True); (ROOT/'textures').mkdir(exist_ok=True)
R=random.Random(703)
WIDTH=128.;LENGTH=720.;HALFW=64.;HALFL=360.
def road_x(z):return 8*sin((z+22)/91.)+5*sin((z-12)/42.)
def road_h(z):return 1.0+2.8*(.5-.5*cos(pi*(360-z)/720))+0.45*sin((z+25)/105)
def height(x,z):
 d=abs(x-road_x(z));shoulder=max(0.,d-6.)
 rolling=.10*sin(x*.071+z*.011)+.12*cos(z*.066-x*.026)
 ridge=(shoulder/55.)**1.65*(8.5+1.6*sin(z/58.+x/23.))
 east=max(0.,(x-road_x(z)-27.)/40.)**1.8*2.1
 return road_h(z)+rolling*(min(shoulder/8.,1.)) +ridge+east

# Author-painted route color map: one contiguous UV atlas matching actual terrain faces.
W,H=2048,4096
rng=np.random.default_rng(20271023)
def noise(h,w,scale):
 sh=(max(2,int(h/scale)),max(2,int(w/scale)))
 raw=rng.normal(0,1,sh).astype(np.float32)
 from PIL import Image as Im
 return np.asarray(Im.fromarray(raw,mode='F').resize((w,h),Im.Resampling.BICUBIC),dtype=np.float32)
Y,X=np.mgrid[0:H,0:W].astype(np.float32)
z=360.-Y/(H-1)*720.;x=-64.+X/(W-1)*128.
center=8*np.sin((z+22)/91.)+5*np.sin((z-12)/42.)
d=np.abs(x-center)
n1=noise(H,W,100);n2=noise(H,W,24);n3=noise(H,W,5)
v=n1*11+n2*4+n3*1.6
base=np.zeros((H,W,3),dtype=np.float32);base[:]=[95,129,87]
# Hillside vegetation darkening and irregular ink-treated meadow
base+=v[...,None]*np.array([.6,.9,.46],dtype=np.float32)
outer=np.clip((d-30)/33,0,1)[...,None]
base=base*(1-outer*.34)+np.array([65,97,73])*outer*.34
# Shoulder brushed pale grasses and ochre exposed earth
shoulder=np.clip((10.3-d)/3.7,0,1);road=np.clip((4.15-d)/1.0,0,1)
base=base*(1-shoulder[...,None]*.79)+np.array([147,132,91])*shoulder[...,None]*.79
base=base*(1-road[...,None]*.87)+np.array([181,153,103])*road[...,None]*.87
# subtler two wheel-ruts with varying soil and very slight diffuse brush edges
ruts=np.exp(-((d-2.12)/.29)**2)*.30
base=base*(1-ruts[...,None])+np.array([126,107,82])*ruts[...,None]
# illustrated roadside narrow herbs and pebbly paths
# No periodic sine-dot pattern: it became visibly repetitive from third-person view.
# Organic brushwork is placed stochastically on the opaque painted albedo below.
# small stone-grain on carriageway; keep painterly not repetitive
speck=(rng.random((H,W))>.993)&(d<5.8)
base[speck]=[105,100,86]
base=np.uint8(np.clip(base,0,255))
paint=Image.fromarray(base,'RGB');pd=ImageDraw.Draw(paint,'RGBA')
# soft nonperiodic flecks grouped into plausible plants rather than a sine lattice
for i in range(5200):
 zz=R.uniform(-357,357);xx=R.uniform(-62,62)
 dist=abs(xx-road_x(zz))
 if dist<6.5: continue
 px=int((xx+64)/128*(W-1));py=int((360-zz)/720*(H-1))
 if 9<px<W-9 and 9<py<H-9:
  a=R.randint(3,12);b=R.randint(1,5)
  shade=(40,77,42,38) if R.random()<.62 else (186,197,117,39)
  pd.ellipse((px-a,py-b,px+a,py+b),fill=shade)
# author-selected cart path accents, earth wash texture, irregular hatching
for i in range(2100):
 zz=R.uniform(-355,355);xx=road_x(zz)+R.uniform(-36,36)
 px=int((xx+64)/128*(W-1));py=int((360-zz)/720*(H-1))
 if 10<px<W-10 and 5<py<H-5:
  if abs(xx-road_x(zz))<5: continue
  col=(35,67,46,55) if R.random()<.71 else (236,222,163,53)
  dx=R.randint(2,12);dy=R.randint(2,8)
  pd.line((px-dx,py,px+dx,py+dy),fill=col,width=R.randint(1,3))
paint.save(ROOT/'textures'/'S07_Haneul_Route_Ground_2048x4096.png',optimize=True)

# Second 1024px illustrated texture atlas for wood/stone/ink/fabric/roof.
colors=[('#8b6349','madeira quente'),('#443d38','tinta borda'),('#d6c39e','pedra clara'),('#59575a','telha cinza'),('#a4754a','corda'),('#8f9c84','folhas'),('#eee2c0','papel'),('#936342','madeira escura'),('#bcae8d','arenito'),('#6b7759','musgo'),('#383f4d','faixa azul'),('#a17451','terra'),('#c4a676','dourado'),('#494f44','pinho'),('#a3b5ad','agua rasa'),('#d0cfbe','branco tinta')]
PA=1024;TILE=256; atlas=Image.new('RGB',(PA,PA));ad=ImageDraw.Draw(atlas,'RGBA');rr=random.Random(55)
for idx,(hue,label) in enumerate(colors):
 x0=idx%4*TILE;y0=idx//4*TILE;rgb=tuple(bytes.fromhex(hue[1:]));ad.rectangle((x0,y0,x0+255,y0+255),fill=rgb+(255,))
 for i in range(750):
  xx=x0+rr.randrange(7,248); yy=y0+rr.randrange(7,248)
  ac=rr.randint(0,20);delta=-16 if i%3 else 22
  ad.line((xx,yy,xx+rr.randrange(1,8),yy+rr.randrange(-1,2)), fill=tuple(max(0,min(255,v+delta)) for v in rgb)+(ac+27,),width=1)
 for edge in range(4):ad.rectangle((x0+edge,y0+edge,x0+255-edge,y0+255-edge),outline=(24,31,32,155),width=1)
atlas.save(ROOT/'textures'/'S07_Roadside_Ink_Atlas_1024.png')

# Trimesh mesh with unit UVs, glTF exported in Godot Y-up space automatically.
xs=np.linspace(-64,64,65);zs=np.linspace(-360,360,289)
V=[];UV=[]
for z0 in zs:
 for x0 in xs:
  V.append((float(x0),float(height(x0,z0)),float(z0)))
  UV.append(((x0+64)/128,1-(360-z0)/720))
F=[];nx=len(xs)
for j in range(len(zs)-1):
 for i in range(nx-1):
  a=j*nx+i;b=a+1;c=a+nx;dd=c+1
  # positive upward normals for shared vertices
  F.extend([(a,c,b),(b,c,dd)])
mesh=trimesh.Trimesh(vertices=np.array(V),faces=np.array(F),process=False)
mesh.visual=trimesh.visual.texture.TextureVisuals(uv=np.array(UV),material=trimesh.visual.material.PBRMaterial(baseColorTexture=paint,metallicFactor=0,roughnessFactor=.99,doubleSided=True,name='EXO_S07_WorldPaint'))
scene=trimesh.Scene();scene.add_geometry(mesh,geom_name='GROUND_WALK_HWA02_HWA01',node_name='GROUND_WALK_HWA02_HWA01')
scene.export(ROOT/'models'/'S07_Rota_Haneul_Yunseong_Terrain.glb')

# Shapes from original material color palette (separate UVs per box face).
class Painter:
 def __init__(self):self.v=[];self.f=[];self.uv=[]
 def quad(self,p,col):
  i=len(self.v);self.v.extend(p);self.f.extend([(i,i+1,i+2),(i,i+2,i+3)])
  ci=col;cx=(ci%4)*TILE;cy=(ci//4)*TILE;pad=6
  self.uv.extend([((cx+pad)/PA,1-(cy+TILE-pad)/PA),((cx+TILE-pad)/PA,1-(cy+TILE-pad)/PA),((cx+TILE-pad)/PA,1-(cy+pad)/PA),((cx+pad)/PA,1-(cy+pad)/PA)])
 def box(self,pos,dim,col):
  x,y,z=pos;dx,dy,dz=np.asarray(dim)*.5
  p=[(x-dx,y-dy,z-dz),(x+dx,y-dy,z-dz),(x+dx,y+dy,z-dz),(x-dx,y+dy,z-dz),(x-dx,y-dy,z+dz),(x+dx,y-dy,z+dz),(x+dx,y+dy,z+dz),(x-dx,y+dy,z+dz)]
  for ids in ((0,1,2,3),(5,4,7,6),(4,0,3,7),(1,5,6,2),(3,2,6,7),(4,5,1,0)):
   self.quad([p[i] for i in ids],col)
 def roof(self,cx,cy,cz,w,d,height,col):
  # angular paired gable roof with dark ink under-eaves, long overhang
  a=(cx-w/2,cy,cz-d/2);b=(cx+w/2,cy,cz-d/2)
  c=(cx-w/2,cy,cz+d/2);dd=(cx+w/2,cy,cz+d/2)
  e=(cx,cy+height,cz-d/2);f=(cx,cy+height,cz+d/2)
  self.quad([a,c,f,e],col);self.quad([e,f,dd,b],col)
  self.quad([a,e,b,b],1) if False else None
  # underside eave edges / ridge keep anchored
  self.box((cx,cy-.06,cz-d/2), (w+.1,.09,.13),1)
  self.box((cx,cy-.06,cz+d/2), (w+.1,.09,.13),1)
  self.box((cx,cy+height,cz),(.14,.14,d),1)
 def export(self):
  m=trimesh.Trimesh(vertices=np.array(self.v,dtype=float),faces=np.array(self.f,dtype=int),process=False)
  m.visual=trimesh.visual.texture.TextureVisuals(uv=np.array(self.uv),material=trimesh.visual.material.PBRMaterial(baseColorTexture=atlas,metallicFactor=0,roughnessFactor=1,doubleSided=True,name='S07_Roadside_Ink'))
  return m

# Designed physical set pieces: milestone, old arch, shrine at side, border approach.
dec=Painter();solid=Painter()
def ground(x,z):return height(x,z)
def post(x,z,hgt=2.4):
 y=ground(x,z);solid.box((x,y+hgt/2,z),(.28,hgt,.30),0);dec.box((x,y+hgt+.08,z),(.42,.16,.42),3)
# north village departure — 2 posts and a painted cross-beam in entrance style
for z0,label in [(321,'HAN')]:
 cx=road_x(z0); y=ground(cx,z0)
 for dx in [-5.5,5.5]:post(cx+dx,z0,3.65)
 solid.box((cx,y+3.62,z0),(12,.31,.55),7)
 dec.roof(cx,y+3.83,z0,12.7,2.0,1.0,3)
 # wooden inscription beam: geometric sign, text rendered using separate texture never pretend ancient chinese
 dec.box((cx,y+3.03,z0),(3.6,.88,.14),10)
# road trip stations with marker posts on safe verges
for z0 in [245,155,42,-74,-180,-265]:
 xx=road_x(z0)+9.2;y=ground(xx,z0)
 solid.box((xx,y+.64,z0),(.60,1.28,.48),8);dec.box((xx,y+1.39,z0),(.94,.24,.77),2)
 dec.box((xx,y+.99,z0-.248),(.30,.11,.04),1)
# roadside guarded caravan rest (-90) with roof raised on columns
for z0,off in [(-80,-17),(135,18)]:
 xx=road_x(z0)+off;yy=ground(xx,z0)
 # raised floor plinth, 4 beams and shade roof, roadside never intersects path
 solid.box((xx,yy+.18,z0),(7.8,.35,5.4),8)
 for sx in (-3.45,3.45):
  for sz in (-2.12,2.12):solid.box((xx+sx,yy+1.72,z0+sz),(.24,3.0,.26),0)
 solid.box((xx,yy+3.27,z0),(7.6,.24,5.0),7)
 dec.roof(xx,yy+3.47,z0,8.5,5.9,1.2,3)
 for zz in (z0-.5,z0+.6):
  dec.box((xx-1.0,yy+.53,zz),(.9,.7,.45),0)
  dec.box((xx+1.0,yy+.47,zz),(.85,.6,.5),8)
# An elevated stone foundation for the Murim road shrine. The actual shrine building
# is instanced from our approved S02 architecture kit at runtime.
sx=road_x(65)-29;sz=65;sy=ground(sx,sz)
solid.box((sx,sy+.22,sz),(8.0,.4,7.0),8)

# roadside boundary stones and grounded road curvature (no fake random buildings)
for z0 in np.linspace(-300,300,41):
 xc=road_x(z0)
 for sd in [-1,1]:
  xx=xc+sd*6.45;yy=ground(xx,z0)
  dec.box((xx,yy+.14,z0),(.18,.28,.48),8)
# yunseong outskirts wall fragments, leaving road open
for sd in [-1,1]:
 xc=road_x(-334)+sd*12;zz=-337; yy=ground(xc,zz)
 solid.box((xc,yy+1.15,zz),(12.0,2.3,1.3),8)
 for px in [-5.,0.,5.]:solid.box((xc+px,yy+1.55,zz),(.58,3.1,1.75),7)
 dec.box((xc,yy+2.48,zz),(12.5,.25,1.65),3)
models=trimesh.Scene()
for name,obj in [('LANDMARK_DECOR_S07',dec),('LANDMARK_COLLIDE_S07',solid)]:models.add_geometry(obj.export(),geom_name=name,node_name=name)
models.export(ROOT/'models'/'S07_Roadside_Landmarks.glb')

points=[{'id':'S07_WAYMARK_VILLAGE','z':321,'type':'village_departure'},
        {'id':'S07_POI_PINE_CROSSING','z':240,'type':'pine_trail'},
        {'id':'S07_POI_ROADSIDE_SHRINE','z':65,'type':'shrine'},
        {'id':'S07_POI_CARAVAN_REST','z':-80,'type':'rest'},
        {'id':'S07_POI_PROVINCIAL_WALL','z':-318,'type':'city_outskirts'}]
manifest={'schema':'exo.world.s07.1','base':'EXO Haneul V1.0 Sprint 6','status':'BUILD_AWAITING_ENGINE_QA','atlas_source':'EXO_Murim_Atlas_HWA01_V0_1','route_id':'ROAD-02-01','regions':['HWA-02','ROAD-02-01','HWA-01_OUTSKIRTS_STAGING'],'extent_local_m':{'width':128,'length':720},'scene_position_isolated':[1200,0,-1200],'route_entry_local':[road_x(340),height(road_x(340),340)+.5,340],'route_return_local':[road_x(328),height(road_x(328),328)+.5,328], 'route_terminal_local':[road_x(-328),height(road_x(-328),-328)+.5,-328], 'route_waypoints':[{'id':p['id'],'kind':p['type'],'local':[road_x(p['z']),height(road_x(p['z']),p['z']),p['z']]} for p in points], 'implemented_city':False, 'no_new_npc_ai':True,'notes':'HWA01 city is a visible gateway and arrival staging only, not a full authored city.'}
(ROOT/'data'/'manifest_sprint07.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('S07_BUILD',mesh.faces.shape,len(dec.f)+len(solid.f),'manifest',ROOT/'data'/'manifest_sprint07.json')
