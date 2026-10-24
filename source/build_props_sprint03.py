"""EXO-Murim | Sprint 03. Original Murim hand-painted prop atlas and reusable 3D meshes.
No source meshes/graphics from third parties. Godot 4.7.2 Compatibility, Y-up.
Regenerate: python source/build_props_sprint03.py
"""
from __future__ import annotations
import math, random, json, hashlib
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
import trimesh

ROOT=Path(__file__).resolve().parents[1]
P=ROOT/'props_sprint03';(P/'kit').mkdir(parents=True,exist_ok=True);(P/'textures').mkdir(exist_ok=True)
rng=random.Random(3003)
PIG={
 'wood_dark':'#3B3533','wood_mid':'#795B45','wood_light':'#B48E63','wood_cut':'#D0A978','wood_moss':'#5D5A46',
 'bamboo':'#78945E','bamboo_shadow':'#455D43','bamboo_light':'#B0BA7C','leaf_dark':'#2F5441','leaf_mid':'#53825C','leaf_lite':'#80A77C',
 'pine_ink':'#2C4B43','pine_blue':'#497368','stone':'#A3A7A0','stone_dark':'#656E70','stone_warm':'#C4B9A1',
 'paper':'#E8DDBE','paper_warm':'#DBC798','fabric_red':'#AD624D','fabric_red_dark':'#76443F','fabric_blue':'#5C7482','rope':'#9D8061',
 'bronze':'#B78A50','iron':'#333F47','pottery':'#B78565','clay_dark':'#73594E','grass':'#5B8F5E','grass_lite':'#9AB56F',
 'flower':'#DBA47C','water':'#7199A0'
}
T=256; NC=6; NW=NC*T; NH=math.ceil(len(PIG)/NC)*T
atlas=Image.new('RGB',(NW,NH));d=ImageDraw.Draw(atlas)
def tup(s):return tuple(int(s[i:i+2],16) for i in (1,3,5))
def col(c,a):return tuple(max(0,min(255,int(x+a))) for x in c)
for ix,(name,hx) in enumerate(PIG.items()):
 r=random.Random(19047+ix*917);base=tup(hx);bx=ix%NC*T;by=ix//NC*T
 d.rectangle((bx,by,bx+T-1,by+T-1),fill=base)
 # hand-painted parallel hatching, dots, irregular ink strokes
 for _ in range(2100):
  x=bx+r.randrange(4,T-4);y=by+r.randrange(4,T-4)
  a=r.randrange(-12,13); d.point((x,y),fill=col(base,a))
 if name.startswith('wood'):
  for _ in range(95):
   y=by+r.randrange(4,252);x=bx+r.randrange(1,150);k=r.randrange(12,70)
   d.line((x,y,x+k,y+r.randrange(-2,3)),fill=col(base,r.choice([-38,-22,18,28])),width=r.choice([1,1,2]))
  if name=='wood_cut':
   for rad in range(14,112,17):d.arc((bx+128-rad,by+128-rad/2,bx+128+rad,by+128+rad/2),0,360,fill=col(base,-28),width=2)
 elif 'bamboo' in name:
  for x in range(bx+10,bx+260,49):
   d.line((x,by+3,x,by+250),fill=col(base,-25),width=3)
   for y in range(by+45,by+250,60):d.line((x-6,y,x+9,y),fill=col(base,26),width=3)
 elif name.startswith('leaf') or name.startswith('pine'):
  for _ in range(210):
   x=bx+r.randrange(3,248);y=by+r.randrange(3,248)
   d.line((x,y,x+r.randrange(3,22),y+r.randrange(-11,-1)),fill=col(base,r.choice([-28,-14,18,34])),width=r.choice([1,2,2]))
 elif name.startswith('stone'):
  for _ in range(45):
   x=bx+r.randrange(8,244);y=by+r.randrange(8,244)
   d.line((x,y,x+r.randrange(3,18),y+r.randrange(-4,5)),fill=col(base,-27),width=1)
  for _ in range(18):
   x=bx+r.randrange(3,250);y=by+r.randrange(4,250);d.arc((x,y,x+r.randrange(5,19),y+r.randrange(4,13)),0,150,fill=col(base,23),width=2)
 elif name.startswith('fabric') or name=='paper' or name=='paper_warm':
  for y in range(by+8,by+250,11):
   d.line((bx+5,y,bx+250,y),fill=col(base,7 if (y//11)%2 else -7),width=1)
  for x in range(bx+8,bx+250,14):
   d.line((x,by+5,x,by+250),fill=col(base,-4),width=1)
 elif name=='rope':
  for y in range(by-12,by+T+25,13):
   d.line((bx,y,bx+T,y+T//6),fill=col(base,-36),width=2)
 elif name.startswith('grass'):
  for _ in range(160):
   x=bx+r.randrange(5,245);y=by+r.randrange(4,245)
   d.line((x,y,x+r.randrange(-7,8),y-r.randrange(6,20)),fill=col(base,r.choice([-24,16,35])),width=1)
 elif name=='pottery' or name=='clay_dark':
  for _ in range(70):
   x=bx+r.randrange(5,245);y=by+r.randrange(5,245)
   d.arc((x,y,x+r.randrange(2,14),y+r.randrange(2,7)),160,345,fill=col(base,-25),width=1)
 # No atlas border: UV padded for independent material swatches
atlas.save(P/'textures'/'EXO_Murim_Props_HandPainted_1536.png',optimize=True)
IDX={n:i for i,n in enumerate(PIG)}
def uv(name,pad=8):
 i=IDX[name];x=i%NC*T;y=i//NC*T
 return ((x+pad)/NW,1-(y+T-pad)/NH),((x+T-pad)/NW,1-(y+T-pad)/NH),((x+T-pad)/NW,1-(y+pad)/NH),((x+pad)/NW,1-(y+pad)/NH)

class Mesh:
 def __init__(self,name):self.name=name;self.V=[];self.F=[];self.U=[]
 def quad(self,pts,material):
  k=len(self.V);self.V.extend(pts);self.F.extend(((k,k+1,k+2),(k,k+2,k+3)));self.U.extend(uv(material))
 def box(self,x,y,z,w,h,depth,material):
  x0=x-w/2;x1=x+w/2;y0=y-h/2;y1=y+h/2;z0=z-depth/2;z1=z+depth/2
  for q in [[(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)],[(x1,y0,z0),(x0,y0,z0),(x0,y1,z0),(x1,y1,z0)],[(x0,y0,z0),(x0,y0,z1),(x0,y1,z1),(x0,y1,z0)],[(x1,y0,z1),(x1,y0,z0),(x1,y1,z0),(x1,y1,z1)],[(x0,y1,z1),(x1,y1,z1),(x1,y1,z0),(x0,y1,z0)],[(x0,y0,z0),(x1,y0,z0),(x1,y0,z1),(x0,y0,z1)]]:self.quad(q,material)
 def beam(self,a,b,radius,material):
  a=np.array(a,dtype=float);b=np.array(b,dtype=float);v=b-a
  if np.linalg.norm(v)<1e-4:return
  f=v/np.linalg.norm(v);t=np.cross(f,[0,1,0]);
  if np.linalg.norm(t)<.005:t=np.cross(f,[0,0,1])
  t=t/np.linalg.norm(t)*radius/2;u=np.cross(f,t);u=u/np.linalg.norm(u)*radius/2
  lo=[a-t-u,a+t-u,a+t+u,a-t+u];hi=[b-t-u,b+t-u,b+t+u,b-t+u]
  for j in range(4):self.quad((lo[j],lo[(j+1)%4],hi[(j+1)%4],hi[j]),material)
  self.quad(lo[::-1],material);self.quad(hi,material)
 def frustum(self,cx,z0,y0,y1,r0,r1,n,material):
  # rings around Y axis, local XZ center; optional taper
  low=[(cx+r0*math.cos(i*math.tau/n),y0,z0+r0*math.sin(i*math.tau/n)) for i in range(n)]
  top=[(cx+r1*math.cos(i*math.tau/n),y1,z0+r1*math.sin(i*math.tau/n)) for i in range(n)]
  for j in range(n):self.quad((low[j],low[(j+1)%n],top[(j+1)%n],top[j]),material)
 def plate(self,points,col,twosided=True):
  self.quad(points,col)
  if twosided:self.quad(points[::-1],col)
 def transform(self,x,y,z,angle=0,scale=1):
  c=math.cos(angle);s=math.sin(angle)
  verts=[]
  for a,b,d in self.V:verts.append((x+scale*(c*a+s*d),y+scale*b,z+scale*(-s*a+c*d)))
  o=Mesh(self.name);o.V=verts;o.F=self.F;o.U=self.U;return o
 def trimesh(self):
  m=trimesh.Trimesh(vertices=np.asarray(self.V,dtype=np.float32),faces=np.asarray(self.F,dtype=np.int32),process=False)
  m.visual=trimesh.visual.texture.TextureVisuals(uv=np.asarray(self.U,dtype=float),material=trimesh.visual.material.PBRMaterial(baseColorTexture=atlas,roughnessFactor=1,metallicFactor=0,doubleSided=True,name='EXO_Sprint03_InkPaint'))
  return m

def well(b):
 b.frustum(0,0,.03,.55,1.35,1.38,12,'stone_dark')
 b.frustum(0,0,.56,.92,1.40,1.37,12,'stone')
 b.frustum(0,0,.93,1.06,1.54,1.53,12,'stone_warm')
 # well dark well-hole - top polygon radial
 b.box(0,1.045,0,1.65,.03,1.60,'iron')
 for xx in (-1.13,1.13):
  b.box(xx,1.78,0,.21,2.05,.24,'wood_dark');b.box(xx,2.78,0,.39,.30,.4,'wood_light')
 b.beam((-1.3,2.77,0),(1.3,2.77,0),.22,'wood_mid')
 b.frustum(0,0,2.25,2.52,.22,.22,10,'wood_cut')
 b.beam((0,2.4,0),(0,1.62,0),.07,'rope')
 b.frustum(0,0,1.17,1.65,.40,.46,10,'wood_mid')
 for k in range(8):
  a=k*math.tau/8;b.beam((.45*math.cos(a),1.4,.45*math.sin(a)),(.42*math.cos(a),1.65,.42*math.sin(a)),.07,'wood_dark')

def lantern(b):
 b.box(0,1.75,0,.2,3.5,.2,'wood_dark');b.box(0,.16,0,.54,.30,.54,'stone')
 b.beam((0,3.35,0),(.95,3.35,0),.18,'wood_mid')
 b.beam((.86,3.32,0),(.86,2.52,0),.065,'iron')
 b.frustum(.86,0,2.06,2.58,.34,.45,8,'fabric_red')
 b.frustum(.86,0,2.52,2.66,.49,.22,8,'bronze')
 b.frustum(.86,0,1.97,2.05,.20,.36,8,'bronze')
 for i in range(5):
  x=.86+.13*math.cos(i*math.tau/5);z=.13*math.sin(i*math.tau/5)
  b.beam((x,1.97,z),(x,1.61,z),.028,'rope')

def pagoda(b):
 b.frustum(0,0,0,.43,.38,.41,8,'stone_dark');b.box(0,.54,0,.56,.46,.56,'stone');b.box(0,1.15,0,.75,.65,.75,'stone')
 for x in [-.29,.29]:b.box(x,1.15,.39,.06,.49,.07,'stone_dark')
 b.box(0,1.58,0,1.02,.15,1.02,'stone_dark')
 b.frustum(0,0,1.62,2.04,.76,.24,8,'stone')
 b.frustum(0,0,2.05,2.12,.21,.25,8,'stone_dark')

def barrel(b):
 b.frustum(0,0,.10,.48,.46,.56,10,'wood_mid');b.frustum(0,0,.48,.97,.56,.48,10,'wood_mid')
 for y in [.21,.79]:b.frustum(0,0,y,y+.09,.53,.54,10,'iron')
 b.frustum(0,0,.97,1.02,.42,.42,10,'wood_cut')

def crate(b):
 b.box(0,.51,0,1.07,1.02,1.07,'wood_mid')
 for x in [-.48,.48]:
  b.box(x,.51,.552,.09,.94,.1,'wood_dark');b.box(x,.51,-.552,.09,.94,.1,'wood_dark')
 for y in [.11,.91]:
  b.box(0,y,.552,1.12,.09,.1,'wood_light');b.box(0,y,-.552,1.12,.09,.1,'wood_light')
 for z in [-.55,.55]:b.beam((-.46,.15,z),(.44,.86,z),.086,'wood_dark')
 b.box(0,1.06,0,1.12,.1,1.12,'wood_light')

def basket(b):
 b.frustum(0,0,.10,.58,.55,.70,10,'rope');b.frustum(0,0,.55,.68,.70,.71,10,'wood_dark')
 b.frustum(0,0,.54,.63,.61,.59,10,'pottery')
 for i in range(12):
  a=i*math.tau/12
  b.beam((.63*math.cos(a),.1,.63*math.sin(a)),(.7*math.cos(a),.54,.7*math.sin(a)),.047,'rope')

def cart(b):
 b.box(0,1.25,0,2.5,.24,1.5,'wood_mid');b.box(0,1.52,0,2.42,.10,1.45,'wood_cut')
 for z in [-.74,.74]:b.box(0,1.62,z,2.65,.50,.13,'wood_mid')
 for x in [-1.2,1.2]:b.box(x,1.62,0,.14,.50,1.44,'wood_mid')
 # visual wheels rings each side of cart with wheel axis X
 for side in [-1,1]:
  x=side*1.39
  for i in range(12):
   a=i*math.tau/12;an=(i+1)*math.tau/12
   b.beam((x,.57+math.cos(a)*.62,math.sin(a)*.62),(x,.57+math.cos(an)*.62,math.sin(an)*.62),.16,'wood_dark')
  for i in range(8):
   a=i*math.tau/8;b.beam((x,.57,0),(x,.57+.61*math.cos(a),.61*math.sin(a)),.09,'wood_light')
  b.box(x,.57,0,.19,.22,.22,'bronze')
 for sx in [-.75,.75]:b.beam((sx,1.16,.85),(sx,1.01,2.6),.18,'wood_mid')

def market(b):
 for x in (-1.7,1.7):
  for z in (-1.2,1.2):b.box(x,1.8,z,.16,3.6,.16,'wood_dark')
 b.box(0,1.35,0,3.35,.16,1.5,'wood_mid')
 b.box(0,1.2,0,3.2,.15,1.35,'wood_cut')
 # sloped awning from rear y3.6 to front y2.92, with accent edging
 b.plate([(-2,3.56,-1.47),(2,3.56,-1.47),(2,2.92,1.65),(-2,2.92,1.65)],'fabric_blue')
 b.beam((-2,2.92,1.65),(2,2.92,1.65),.15,'fabric_red_dark')
 for x in [-1.35,-.45,.45,1.35]:b.beam((x,3.5,-1.3),(x,2.89,1.57),.045,'fabric_red')
 for x in [-1.1,0,1.1]:b.box(x,1.5,0,.7,.18,.6,'pottery')

def bench(b):
 b.box(0,.67,0,2.3,.14,.65,'wood_mid');b.box(0,1.14,-.32,2.3,.66,.12,'wood_mid')
 for x in [-.87,.87]:b.box(x,.37,0,.18,.72,.45,'wood_dark')

def fence(b):
 for x in [-1.45,0,1.45]:
  b.box(x,.72,0,.22,1.45,.22,'wood_dark');b.frustum(x,0,1.37,1.60,.20,0,4,'wood_light')
 for y in [.40,1.04]:b.box(0,y,0,3.25,.15,.14,'wood_mid')

def sign(b):
 b.box(0,1.6,0,.16,3.2,.18,'wood_dark')
 b.box(0,2.42,.08,1.28,.84,.17,'wood_mid')
 b.box(0,2.42,.18,1.08,.62,.06,'paper_warm')
 # neutral original knots motifs -- family banners remain separate
 b.beam((-.35,2.57,.225),(.35,2.57,.225),.035,'iron')
 b.beam((0,2.58,.23),(0,2.28,.23),.035,'iron')
 b.box(0,3.14,0,.24,.17,.25,'bronze')

def banner(b):
 b.box(0,2.23,0,.15,4.46,.15,'wood_dark')
 b.beam((0,4.20,0),(1.18,4.20,0),.13,'wood_mid')
 # two quads, slash-cut bottom, fine ink border and tassel
 b.plate([(.3,4.03,.06),(1.28,4.03,.06),(1.28,2.65,.06),(.3,2.65,.06)],'fabric_red')
 b.beam((.32,4.02,.09),(1.27,4.02,.09),.06,'iron')
 for i in range(5):b.beam((.4+i*.20,2.67,.055),(.4+i*.20,2.36-(i%2)*.06,.055),.038,'rope')

def bamboo(b):
 rr=random.Random(42)
 for i in range(5):
  x,z=[(-.52,.2),(.36,-.4),(.72,.36),(-.18,-.60),(.1,.45)][i];ht=[4.2,5.0,4.5,3.9,4.8][i]
  b.frustum(x,z,0,ht,.095,.055,7,'bamboo' if i%2 else 'bamboo_shadow')
  for yy in np.arange(.50,ht,.58):
   b.frustum(x,z,yy,yy+.045,.114,.115,7,'bamboo_light')
  for h in [ht*.73,ht*.85,ht*.94]:
   for j in range(4):
    a=j*math.pi/2+i*.37+h;ln=.9+(i%2)*.3
    base=(x,h,z);tip=(x+math.cos(a)*ln,h+.16,z+math.sin(a)*ln)
    b.beam(base,tip,.054,'bamboo_shadow')
    for side in [-1,1]:
     dx=math.cos(a);dz=math.sin(a);ox=-dz*.22*side;oz=dx*.22*side
     b.plate([base,(x+dx*.52+ox,h+.22,z+dz*.52+oz),tip,(x+dx*.52-ox,h+.08,z+dz*.52-oz)],'leaf_mid' if i%2 else 'leaf_dark')

def pine(b):
 b.frustum(0,0,0,5.0,.20,.105,8,'wood_dark')
 for k,(height,r) in enumerate([(2.3,1.60),(3.35,1.36),(4.35,1.00),(5.1,.55)]):
  # serrated low-poly needles, not overlapping pyramids of cubes
  for j in range(8):
   angle=j*math.tau/8;rr=r*(.85 if j%2==0 else 1.1)
   b.plate([(0,height+.62,0),(rr*math.cos(angle-.38),height-.55,rr*math.sin(angle-.38)),(rr*math.cos(angle+.38),height-.55,rr*math.sin(angle+.38)),(.11*math.cos(angle),height+.25,.11*math.sin(angle))], 'pine_ink' if k%2 else 'pine_blue')

def shrub(b):
 for x,z,r,h in [(-.5,.02,.64,.84),(.2,-.18,.78,1.14),(.66,.35,.59,.84),(-.05,.55,.51,.7)]:
  b.frustum(x,z,.05,h,r*.85,r*.55,7,'leaf_dark')
  b.frustum(x,z,h*.45,h+.28,r*.77,.0,7,'leaf_mid')
  for i in range(5):
   a=(i+1)*math.tau/5;b.plate([(x,h*.68,z),(x+.25*math.cos(a),h+.22,z+.25*math.sin(a)),(x+.36*math.cos(a),h*.47,z+.36*math.sin(a)),(x,h*.65,z)],'leaf_lite')

def grass(b):
 for i in range(6):
  a=i*math.tau/6;r=.33+(i%3)*.08;hh=.5+(i%3)*.18
  b.plate([(0,.03,0),(r*math.cos(a-.42),hh*.4,r*math.sin(a-.42)),(r*math.cos(a),hh,r*math.sin(a)),(r*math.cos(a+.42),hh*.4,r*math.sin(a+.42))], 'grass_lite' if i%3==0 else 'grass')

def reeds(b):
 for i in range(7):
  a=i*math.tau/7;rr=.4+(i%2)*.2;ht=1.1+(i%4)*.23
  x=rr*math.cos(a);z=rr*math.sin(a)
  b.beam((x,0,z),(x+.08,ht,z-.07),.045,'bamboo_shadow')
  b.frustum(x+.08,z-.07,ht-.24,ht+.12,.075,.09,6,'clay_dark')
  for j in (0,1):b.plate([(x,.2+j*.29,z),(x+.4,ht*.52+j*.19,z+.21),(x+.12,ht*.70+j*.12,z+.09),(x,.2+j*.29,z)],'leaf_mid')

def rock(b):
 for x,z,r,h,c in [(-.55,.1,.68,.52,'stone'),(.27,-.20,.84,.73,'stone_dark'),(.60,.53,.48,.38,'stone_warm')]:
  b.frustum(x,z,.0,h,r,.23*r,7,c)

def flower(b):
 for i in range(5):
  a=i*math.tau/5;r=.26;ht=.49+(i%3)*.17;x=r*math.cos(a);z=r*math.sin(a)
  b.beam((x,0,z),(x,ht,z),.032,'grass')
  for j in range(5):
   aa=j*math.tau/5;b.plate([(x,ht,z),(x+.13*math.cos(aa),ht+.12,z+.13*math.sin(aa)),(x+.08*math.cos(aa+.7),ht+.19,z+.08*math.sin(aa+.7)),(x,ht,z)],'flower')
  b.box(x,ht+.03,z,.075,.05,.07,'bronze')

def footbridge(b):
 # deliberately standalone until a mapped stream location is approved
 for s in (-1,1):
  for z in (-1.35,1.35):
   b.box(s*2.3,.70,z,.24,1.4,.24,'wood_dark')
  b.beam((s*2.3,1.02,-1.4),(s*2.3,1.02,1.4),.14,'wood_mid')
 for i in range(14):
  x=-2.35+i*(4.7/13)
  y=.73+.49*(1-(x/2.35)**2)
  b.box(x,y,0,.32,.17,3.1,'wood_mid' if i%4 else 'wood_light')
 for s in (-1,1):
  for i in range(8):
   x=-2.30+i*.65;h=.73+.49*(1-(x/2.35)**2)
   b.box(x,h+.49,s*1.33,.10,.90,.12,'wood_dark')
  b.beam((-2.3,1.50,s*1.33),(2.3,1.50,s*1.33),.12,'wood_mid')

BUILDERS={
 'WELL_STONE':well,'LANTERN_POST':lantern,'STONE_PAGODA_LANTERN':pagoda,'BARREL':barrel,'CRATE':crate,'RICE_BASKET':basket,
 'CART_WOOD':cart,'MARKET_STALL':market,'BENCH':bench,'FENCE_SECTION':fence,'SIGNBOARD':sign,'BANNER':banner,
 'BAMBOO_CLUSTER':bamboo,'PINE_YOUNG':pine,'SHRUB':shrub,'GRASS_TUFT':grass,'RIVER_REEDS':reeds,'ROCK_CLUSTER':rock,'WILDFLOWERS':flower,'FOOTBRIDGE_SMALL':footbridge,
}
KIT={}
for name,cb in BUILDERS.items():
 m=Mesh('KIT_'+name);cb(m);KIT[name]=m
 scene=trimesh.Scene();scene.add_geometry(m.trimesh(),geom_name=name,node_name=name)
 scene.export(str(P/'kit'/f'{name}.glb'))

# Physical placements are deliberately reviewed coordinates, separate from authored meshes.
# House exclusion and ground elevation come from the canonical HWA02 Sprint 2 manifests.
manifest=json.loads((ROOT/'data'/'HWA02_manifest.json').read_text())
houses=manifest['placements']
def ground(x,z):
 center=66+8*math.sin((z+20)/41)+z*.045
 return .2+.17*math.sin(x*.072+z*.013)+.17*math.cos(z*.093-x*.024)+max(0,(-x-57)/55)**1.8*11.5+max(0,(-z-65)/45)*max(0,(-x-55)/65)*6-2.25*max(0,1-abs(x-center)/12)**1.35
placements=[]
def safe(x,z,padding=3):
 for h in houses:
  xx,zz=h['position_xz'];w,dd=h['dimensions_wd']
  if abs(x-xx)<w/2+padding and abs(z-zz)<dd/2+padding:return False
 # Family courtyard is bounded: avoid flooding active area with random plants.
 if -72<x<-24 and -66<z<-22:return False
 return True

def add(name,x,z,rot=0,scale=1,interactive=False):
 assert name in KIT
 # prop base Y follows exact same generator as architectural ground
 placements.append({'id':f'S03_{len(placements)+1:03d}_{name}','kind':name,'x':round(x,3),'y':round(ground(x,z)+.07,3),'z':round(z,3),'yaw_deg':rot,'scale':scale,'collidable':interactive})

# Hand-curated points for grounded prop dressing.
manual={
 'WELL_STONE':[(-18,6,10)],
 'LANTERN_POST':[(-11,-4,0),(-1,-4,180),(22,-7,0),(33,-8,180),(-50,-20,0),(-63,-21,0),(9,-52,0),(17,-55,160)],
 'STONE_PAGODA_LANTERN':[(-81,-43,0),(-73,-36,0),(-57,-18,0)],
 'BARREL':[(-15,-5,0),(-14,-6,0),(19,-8,0),(20,-8,0),(-22,10,0),(14,-43,0),(33,30,0)],
 'CRATE':[(-19,5,0),(-19,6,0),(-20,5,0),(-21,17,0),(-9,-21,0),(24,-28,0),(21,-31,0),(17,-42,0)],
 'RICE_BASKET':[(-45,57,0),(-49,59,0),(-27,64,0),(-18,58,0),(26,25,0),(15,43,0)],
 'CART_WOOD':[(-16,-25,0),(-14,27,90),(18,9,0)],
 'MARKET_STALL':[(-10,6,90),(17,-11,270)],
 'BENCH':[(-22,3,20),(-9,15,25),(-30,-6,90),(27,8,0),(-57,-17,0)],
 'SIGNBOARD':[(-17,-11,45),(17,-26,0),(-29,8,20)],
 'BANNER':[(-59,-19,0),(-37,-19,0)],
 'FENCE_SECTION':[(-44,64,0),(-41,64,0),(-38,64,0),(-29,66,0),(-26,66,0)],
 'BAMBOO_CLUSTER':[(-84,-13,0),(-79,5,30),(-82,22,0),(-85,37,0),(-74,62,0),(-58,87,0),(-9,79,0),(23,85,0),(42,75,0),(45,-61,0),(39,-77,0)],
 'PINE_YOUNG':[(-91,-50,0),(-83,-76,0),(-96,17,0),(-77,85,0),(2,92,0),(46,-89,0)],
 'ROCK_CLUSTER':[(-81,-54,0),(-94,-29,0),(-73,-9,0),(48,-68,0),(-74,82,0),(17,81,0)],
 'RIVER_REEDS':[(53,-62,0),(54,-45,0),(55,-27,0),(55,-7,0),(57,13,0),(59,39,0),(57,60,0)],
}
SOLID={'WELL_STONE','LANTERN_POST','STONE_PAGODA_LANTERN','BARREL','CRATE','CART_WOOD','MARKET_STALL','BENCH','SIGNBOARD','BANNER'}
for kind,rows in manual.items():
 for x,z,a in rows:
  # major curated props should not block house footprints; will audit explicitly
  add(kind,x,z,a,1,kind in SOLID)
# Smaller dressing: rejection sampling around occupied lots, the river, and existing main roads.
rnd=random.Random(8301)
for kind,num in [('SHRUB',33),('GRASS_TUFT',100),('WILDFLOWERS',47)]:
 accepted=0
 for j in range(num*80):
  if accepted>=num:break
  x=rnd.uniform(-94,48);z=rnd.uniform(-92,91)
  if abs(x)<22 and abs(z)<20 and kind!='WILDFLOWERS':continue
  if kind=='SHRUB' and not safe(x,z,5):continue
  if kind!='SHRUB' and not safe(x,z,2):continue
  if not (x<40 or z<15):continue
  if abs(x-58)<5:continue
  if kind=='SHRUB' and x>25 and z<30:continue
  add(kind,x,z,rnd.randrange(0,360),round(rnd.uniform(.75,1.28),2),False)
  accepted+=1
 assert accepted==num,(kind,accepted)

# Group 25-30 of the instances into separate named scene meshes, for visibility and future reuse.
# Collidable major props stay isolated, decorative vegetation batched by species and zones.
sc=trimesh.Scene();stats=[]
for ix,p in enumerate(placements):
 name=p['kind'];model=KIT[name].transform(p['x'],p['y'],p['z'],math.radians(p['yaw_deg']),p['scale'])
 node=('PROP_COLLIDE_' if p['collidable'] else 'PROP_DECOR_')+f'{ix:03d}_{name}'
 mesh=model.trimesh();sc.add_geometry(mesh,geom_name=node,node_name=node)
 stats.append({'name':node,'triangles':len(mesh.faces),'collidable':p['collidable']})
sc.export(str(P/'HWA02_Props_Vegetation_S03.glb'))

counts={name:sum(p['kind']==name for p in placements) for name in BUILDERS}
summary={'sprint':'03','provenance':'original source code, geometry and digitally painted textures','source_base':'EXO Haneul V0.6 Sprint02','engine':'Godot 4.7.2 GL Compatibility','kit_count':len(KIT),'kit_assets':list(KIT),'instances_count':len(placements),'instances_by_type':counts,'scene_triangles':sum(s['triangles'] for s in stats),'solids_count':sum(p['collidable'] for p in placements),'physics':'prop colliders for major street items only; minor vegetation decorative','mesh':'HWA02_Props_Vegetation_S03.glb','atlas':'textures/EXO_Murim_Props_HandPainted_1536.png','placements':placements,'policy':'unchanged world heights, no house relocation, no bridge placed without actual mapped stream','tested_in_engine':False}
(P/'manifest_sprint03.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
print(json.dumps({'kit':len(KIT),'instances':len(placements),'triangles':summary['scene_triangles'],'collidable':summary['solids_count'],'by_type':counts},ensure_ascii=False))
