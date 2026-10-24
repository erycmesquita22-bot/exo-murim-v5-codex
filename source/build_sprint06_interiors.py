#!/usr/bin/env python3
"""EXO Haneul S06 authored Murim interiors; original meshes and painted textures.
Godot world coordinates X east/Y up/Z south, rooms have an open roof for third-person camera.
Each of 15 fixed entrances maps to one unique packed room; family variants change banner, not architecture.
"""
from pathlib import Path
import math, random, json, hashlib
import numpy as np
import trimesh
from PIL import Image, ImageDraw, ImageFilter
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'interiors_sprint06'; MOD=OUT/'models'; SCN=ROOT/'godot'/'interiors'
for p in [OUT, MOD, SCN,OUT/'previews',OUT/'data']: p.mkdir(parents=True,exist_ok=True)
S=192; COLS=8; N=S*COLS
PALETTE=[
('plaster','#CFC6AD'),('plaster_shade','#B3A993'),('paper','#E9E0C9'),('paper_shade','#D4C9AF'),
('ink','#292B31'),('aged_wood','#72523F'),('wood_light','#9D7653'),('wood_dark','#4B382E'),
('floor_plank','#AC8F70'),('floor_plank_dark','#806B59'),('slate','#767B7A'),('slate_light','#A6A49A'),
('straw','#C8B381'),('straw_shadow','#967A4E'),('bamboo','#678366'),('bamboo_light','#89A17D'),
('red_fabric','#944E4A'),('blue_fabric','#505F83'),('indigo','#414A61'),('gold','#BD985E'),
('bronze','#8D7147'),('jade','#628D7C'),('porcelain','#D9DACE'),('herb','#657348'),
('herb_dark','#43573E'),('rice','#D9C4A1'),('sakura','#B78177'),('soil','#69584A'),
('leather','#4D4541'),('scroll','#DDD0B1'),('dark_fabric','#353A44'),('light_fabric','#B7AC9D'),
('wong_banner','#994745'),('wudong_banner','#49678D'),('scroll_ink','#756A62'),('faded_blue','#77849A'),
('window_lattice','#3E342F'),('tatami','#B2A383'),('ceramic','#D3C6AE'),('moss','#7A8A60'),('mountain_paint','#D8D1BB'),('bamboo_scroll','#DAD1BC'),('ink_lore','#D8C8AA')]
# first 40 colors; 8*5 rows on 1536 square atlas
img=Image.new('RGB',(N,N),(225,218,195));d=ImageDraw.Draw(img);rng=random.Random(62061)
TILES={n:i for i,(n,c) in enumerate(PALETTE)}
def hcol(h):return tuple(bytes.fromhex(h[1:]))
for idx,(name,col) in enumerate(PALETTE):
 x=(idx%COLS)*S;y=(idx//COLS)*S;base=hcol(col)
 d.rectangle((x,y,x+S-1,y+S-1),fill=base)
 for j in range(4000):
  X=x+rng.randrange(3,S-3);Y=y+rng.randrange(3,S-3);dev=rng.randrange(-16,15)
  d.point((X,Y),fill=tuple(max(0,min(255,v+dev)) for v in base))
 if name in ('plaster','plaster_shade','paper','paper_shade'):
  for j in range(23):
   xx=x+rng.randrange(10,S-12);yy=y+rng.randrange(8,S-10)
   d.arc((xx-7,yy-3,xx+8,yy+8),45,210,fill=tuple(max(0,t-21) for t in base),width=1)
 if 'wood' in name or 'plank' in name or name in ('window_lattice','tatami'):
  for j in range(17):
   yy=y+5+j*11 + rng.randint(-3,3)
   d.line([(x+8,yy),(x+S-9,yy-1)],fill=tuple(max(0,v-23) for v in base),width=1)
 if 'fabric' in name or 'banner' in name:
  for j in range(60):
   xx=x+rng.randrange(6,S-6); yy=y+rng.randrange(6,S-6)
   d.line([(xx,yy),(xx+3,yy+4)],fill=tuple(min(255,v+13) for v in base),width=1)
 if name in ('slate','slate_light'):
  for j in range(35):
   xx=x+rng.randrange(8,S-8);yy=y+rng.randrange(8,S-8)
   d.line((xx,yy,xx+5,yy+2),fill=tuple(max(0,v-26) for v in base),width=1)
 if name in ('wong_banner','wudong_banner'):
  # original fictional identity sigil; both painted to look like brushstrokes, no copied logos
  ink='#E6D5AC' if name=='wong_banner' else '#DDE7D7'; cx=x+S//2;cy=y+S//2
  d.arc((cx-42,cy-54,cx+44,cy+49),34,307,fill=ink,width=7)
  d.line((cx-40,cy+4,cx+20,cy+6),fill=ink,width=6)
  d.line((cx+5,cy-41,cx-6,cy+44),fill=ink,width=6)
  d.line((cx-18,cy-17,cx+40,cy+22),fill=ink,width=4)
 if name=='scroll_ink':
  for j in range(12):
   cy=y+12+j*14
   d.line([(x+26,cy),(x+110+rng.randrange(40),cy+2)],fill='#3D4141',width=rng.choice((2,3)))
 if name in ('mountain_paint','bamboo_scroll','ink_lore'):
  ink_color='#393E40'
  if name=='mountain_paint':
   # original Jianghu landscape in three ink washes, painted inside UV tile
   for i2,(peak,shade) in enumerate([(40,'#6F7770'),(103,'#929A89'),(141,'#737E70')]):
    points=[(x, y+138+i2*8),(x+peak-23,y+101-i2*14),(x+peak,y+28+i2*18),(x+peak+28,y+118-i2*7),(x+S,y+139+i2*5)]
    d.line(points,fill=shade,width=2)
    d.line([(x+peak,y+35+i2*18),(x+peak+4,y+80+i2*10)],fill='#4B5751',width=3)
   for j in range(12):
    X=x+rng.randrange(18,S-18);Y=y+rng.randrange(120,S-20)
    d.line((X,Y,X+20,Y-4),fill='#747F75',width=1)
  elif name=='bamboo_scroll':
   for bend in (42,86,132):
    d.line((x+bend,y+170,x+bend+10,y+30),fill='#46584C',width=4)
    for ny in (52,88,112):
     yy=y+ny
     d.line((x+bend+3,yy,x+bend-24,yy-30),fill='#637666',width=3)
     d.line((x+bend+3,yy,x+bend+27,yy-23),fill='#637666',width=3)
  else:
   for j in range(9):
    xx=x+22+(j%3)*50;yy=y+15+(j//3)*55
    d.arc((xx,yy,xx+30,yy+35),12,215,fill='#4A4B44',width=3)
    d.line((xx+6,yy+8,xx+29,yy+24),fill='#4A4B44',width=2)
 # etched/drawn ink edge on surface
 d.rectangle((x+2,y+2,x+S-3,y+S-3),outline=tuple(max(0,v-28) for v in base),width=2)
tex=OUT/'EXO_Murim_Interiors_HandPainted_1536.png'; img.save(tex)
def tile_uv(name):
 idx=TILES[name];x=idx%COLS*S;y=idx//COLS*S;p=6
 return [( (x+p)/N, 1-(y+S-p)/N ), ((x+S-p)/N,1-(y+S-p)/N), ((x+S-p)/N,1-(y+p)/N),((x+p)/N,1-(y+p)/N)]
class B:
 def __init__(self,n):self.name=n;self.v=[];self.f=[];self.uv=[]
 def quad(self,pts,col):
  k=len(self.v);self.v.extend(pts);self.uv.extend(tile_uv(col));self.f.extend([(k,k+1,k+2),(k,k+2,k+3)])
 def box(self,center,sz,col):
  x,y,z=center;a,b,c=(s/2 for s in sz)
  low=[(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y-b,z+c),(x-a,y-b,z+c)]
  hi=[(x-a,y+b,z-c),(x+a,y+b,z-c),(x+a,y+b,z+c),(x-a,y+b,z+c)]
  for p in [[low[0],low[1],hi[1],hi[0]],[low[1],low[2],hi[2],hi[1]],[low[2],low[3],hi[3],hi[2]],[low[3],low[0],hi[0],hi[3]],[hi[0],hi[1],hi[2],hi[3]],list(reversed(low))]: self.quad(p,col)
 def polygon_banner(self,x,y,z,hue):
  self.quad([(x-.45,y-.62,z),(x+.45,y-.62,z),(x+.43,y+.55,z),(x-.43,y+.55,z)],hue)
  self.quad([(x-.45,y-.60,z+.015),(x+.45,y-.60,z+.015),(x+.43,y+.50,z+.015),(x-.43,y+.50,z+.015)],hue)
  self.box((x,y+.58,z),(.99,.12,.10),'aged_wood')
 def mesh(self):
  if not self.f:return None
  mesh=trimesh.Trimesh(vertices=np.asarray(self.v,dtype=float),faces=np.asarray(self.f,dtype=int),process=False)
  mesh.visual=trimesh.visual.texture.TextureVisuals(uv=np.asarray(self.uv,dtype=float),material=trimesh.visual.material.PBRMaterial(baseColorTexture=img,roughnessFactor=1.0,metallicFactor=0.0,doubleSided=True,name='EXO_S06_Illustrated_Ink'))
  return mesh
class Room:
 def __init__(self,w,d,id):
  self.w=w;self.d=d;self.id=id;self.e=[];self.coll=[];self.components={};self.serial=0
 def group(self,name):
  if name not in self.components:self.components[name]=B(name)
  return self.components[name]
 def box(self,c,s,col,g='INTERIOR_arch'):
  self.group(g).box(c,s,col)
 def collision(self,c,s):self.coll.append({'center':list(c),'size':list(s)})
 def box_solid(self,c,s,col,g='INTERIOR_objects'):
  self.box(c,s,col,g);self.collision(c,s)
 def beam(self,a,b,rad=.12,col='aged_wood'):
  # beams orthogonal to main axis in standard Murim structures
  x1,y1,z1=a;x2,y2,z2=b
  self.box(((x1+x2)/2,(y1+y2)/2,(z1+z2)/2),(abs(x2-x1)+rad,abs(y2-y1)+rad,abs(z2-z1)+rad),col)
 def architecture(self):
  w,d=self.w,self.d;wall_h=3.35;door_gap=2.45
  self.box((0,-.15,0),(w+.7,.30,d+.7),'slate')
  self.box((0,.028,0),(w,.08,d),'floor_plank')
  # painted floor boards are thin and legible, not raised collision ridges
  for z in np.arange(-d/2+.75,d/2,1.0): self.box((0,.073,float(z)),(w-.36,.014,.026),'floor_plank_dark','FLOOR_ink_edges')
  # cream plaster interior walls, framed with visible timber posts and upper wooden lintels
  for x in (-w/2,w/2): self.box((x,wall_h/2,0),(.18,wall_h,d),'plaster')
  self.box((0,wall_h/2,-d/2),(w,wall_h,.18),'plaster')
  s=(w-door_gap)/2
  for side in (-1,1): self.box((side*(door_gap/2+s/2),wall_h/2,d/2),(s,wall_h,.18),'plaster')
  self.box((0,wall_h-0.35,d/2),(door_gap,.70,.20),'aged_wood')
  for x in (-w/2,w/2):
   for z in (-d/2,d/2):
    self.box((x,wall_h/2,z),(.23,wall_h,.23),'wood_dark')
    self.box((x,wall_h-.22,z),(.36,.24,.36),'wood_light')
  for z in (-d/2,d/2):
   self.box((0,wall_h-.14,z),(w,.26,.31),'aged_wood')
   self.box((0,.09,z),(w,.16,.25),'wood_dark')
  for x in (-w/2,w/2):self.box((x,wall_h-.12,0),(.27,.25,d),'aged_wood')
  # Exposed PERIMETER rafters rather than full-width beams crossing the third-person camera.
  # This stays roofless on purpose: the shell is a separate scene, not a cutaway of the outside house.
  for xx in (-w/2+.38,w/2-.38):
   self.box((xx,wall_h-.19,0),(.12,.13,d-.35),'wood_light','CEILING_perimeter')
  for zz in (-d/2+.35,d/2-.35):
   self.box((0,wall_h-.19,zz),(w-.35,.13,.12),'wood_light','CEILING_perimeter')
  # side screens: paper lattice grids, handmade ink outline
  for z in (-d*.26,d*.26):
   for x in (-w/2+.12,w/2-.12):
    self.box((x,1.75,z),(.033,1.72,1.35),'paper')
    for zz in np.linspace(z-.58,z+.58,5):self.box((x,1.75,float(zz)),(.08,1.8,.03),'window_lattice')
    for yy in (1.16,1.61,2.07,2.53):self.box((x,yy,z),(.08,.035,1.42),'window_lattice')
  # front door thresh flush with physical floor, family will use it both ways
  self.box((0,.025,d/2+.29),(door_gap+.35,.14,.62),'slate_light')
  self.box((0,wall_h-.72,d/2+.04),(2.7,.17,.18),'wood_dark')
  self.box((0,wall_h-.39,d/2+.075),(2.8,.55,.09),'wood_light')
 def mat(self,x,z,w=2.0,d=1.4,col='tatami'):
  self.box((x,.105,z),(w,.055,d),col,'FLOOR_mats')
  for sign in [-1,1]:
   self.box((x+sign*w*.48,.14,z),(.035,.014,d),'ink','FLOOR_ink_edges')
 def table(self,x,z,w=1.8,d=.9,height=.62):
  self.box_solid((x,height,z),(w,.16,d),'wood_light')
  for sx in (-1,1):
   for sz in (-1,1):self.box((x+sx*(w/2-.15),height/2,z+sz*(d/2-.14)),(.15,height,.15),'wood_dark')
  self.box((x,height+.09,z),(w-.23,.025,d-.22),'floor_plank')
 def stool(self,x,z):
  self.box_solid((x,.35,z),(.7,.25,.62),'wood_light')
  for dx in (-.23,.23):self.box((x+dx,.17,z),(.10,.34,.46),'aged_wood')
 def shelf(self,x,z,w=2.7,high=2.3,depth=.52):
  self.box_solid((x,high/2,z),(w,high,depth),'aged_wood')
  for y in [.43,1.00,1.58,2.16]:self.box((x,y,z-depth/2-.04),(w,.10,depth+.1),'wood_light')
  for ix in range(-2,3):
   if ix%2==0: self.box((x+ix*w*.13,1.32,z-depth/2-.11),(.17,.49,.18),'scroll')
   else:self.box((x+ix*w*.13,.68,z-depth/2-.11),(.20,.21,.17),'porcelain')
 def screen(self,x,z,rotation=False):
  if not rotation:
   self.box((x,1.55,z),(2.7,2.6,.12),'wood_dark')
   self.box((x,1.55,z-.015),(2.47,2.30,.035),'paper_shade')
   for dx in (-.75,0,.75):self.box((x+dx,1.57,z-.11),(.035,2.4,.06),'window_lattice')
   for y in [.70,1.3,1.9,2.43]:self.box((x,y,z-.11),(2.45,.036,.06),'window_lattice')
 def lamp(self,x,z,h=1.85):
  self.box((x,h/2,z),(.10,h,.10),'aged_wood')
  self.box((x,h,z),(.60,.11,.60),'ink')
  self.box((x,h+.38,z),(.43,.66,.43),'paper')
  self.box((x,h+.72,z),(.60,.11,.60),'wood_dark')
  for dx in (-.22,.22):
   for dz in (-.22,.22):self.box((x+dx,h+.38,z+dz),(.04,.68,.04),'wood_dark')
 def cushion(self,x,z,col='indigo'):
  self.box((x,.16,z),(1,.16,1.0),col)
  self.box((x,.24,z),(.86,.04,.86),'light_fabric')
 def scroll(self,x,y,z):
  self.box((x,y,z),(.58,.06,.35),'scroll');self.box((x,y+.04,z),(.49,.01,.20),'scroll_ink')
 def altar(self,x,z):
  self.table(x,z,2.7,1.0,1.02)
  self.box((x,1.43,z+.31),(1.4,.73,.14),'wood_dark')
  self.box((x,1.46,z+.225),(1.12,.55,.045),'scroll_ink')
  for sign in [-1,1]:self.lamp(x+sign*1.22,z+.15,1.40)
 def pot(self,x,z,herbal=False):
  self.box((x,.35,z),(.48,.7,.48),'ceramic')
  if herbal:
   for dx,dz in [(-.15,-.07),(.10,.02),(.02,.16)]:
    self.box((x+dx,.91,z+dz),(.035,.64,.045),'herb')
    self.box((x+dx,.95,z+dz),(.25,.25,.055),'bamboo')
 def basket(self,x,z):
  self.box((x,.29,z),(.67,.52,.59),'straw')
  self.box((x,.55,z),(.70,.1,.62),'straw_shadow')
 def bed(self,x,z):
  self.box_solid((x,.31,z),(2.2,.62,1.55),'wood_dark')
  self.box((x,.69,z),(1.95,.18,1.34),'tatami')
  self.box((x-.70,.80,z),(.44,.16,1.12),'light_fabric')
 def rack(self,x,z,weapon=False):
  self.box_solid((x,1.08,z),(2.35,2.16,.30),'aged_wood')
  if weapon:
   for xx in (x-.75,x-.25,x+.25,x+.75):
    self.box((xx,1.45,z-.22),(.12,1.7,.05),'slate_light')
    self.box((xx,.69,z-.23),(.32,.1,.13),'bronze')
  else:
   for xx in (x-.70,x-.20,x+.30,x+.77):
    self.box((xx,1.0,z-.18),(.24,.70,.22),'scroll')
 def decor(self,kind):
  w,d=self.w,self.d
  if kind=='MANOR_HALL':
   self.mat(0,0,5.3,6.5);self.altar(0,-d*.26)
   for x in (-3.9,3.9):
    for z in (-2.6,.4):self.table(x,z,1.30,.84,.55);self.cushion(x,z+1.15)
   for sx in (-1,1):self.screen(sx*5.6,-d*.12)
   self.lamp(-w*.38,0);self.lamp(w*.38,0)
  elif kind=='MANOR_TRAINING':
   self.mat(0,0,w-3,d-2,'slate')
   for sx in (-1,1):
    for z in (-2.5,1.4):self.rack(sx*(w/2-1.9),z,True)
   self.table(0,-d*.29,2.1,.8,.62);self.lamp(-w*.36,1.6);self.lamp(w*.36,1.6)
  elif kind=='MANOR_LIBRARY':
   self.mat(0,-.7,3.2,4.2);self.table(0,-.6,3.1,1.35,.71);self.scroll(0,.84,-.6)
   for sx in (-1,1):
    for z in (-3.2,-.4,2.5):self.shelf(sx*(w/2-1.1),z,1.8,2.4,.50)
   self.screen(0,-d*.33);self.lamp(-3,2.6)
  elif kind=='TEAHOUSE':
   for x in (-3.6,0,3.6):
    for z in (-2.5,1.5):
     self.mat(x,z,2.65,2.5);self.table(x,z,1.48,.95,.50)
     for dx in (-.95,.95):self.cushion(x+dx,z,'indigo')
   self.box_solid((0,.80,-d/2+1.5),(5,1.6,1.0),'aged_wood')
   for x in (-1.35,0,1.35):self.pot(x,-d/2+1.0)
   self.lamp(-5.2,3.0);self.lamp(5.2,3.0)
  elif kind=='HEALER':
   self.box_solid((0,.83,-d/2+1.4),(3.5,1.65,1.1),'aged_wood')
   for x in (-3.0,3.0):
    self.shelf(x,-d/2+1,2.1);self.pot(x,.8,True)
   self.table(0,0,2.45,1.15,.72)
   for x in (-1.0,1.0):self.basket(x,1.8)
   self.mat(0,1.5,3.6,2.2);self.screen(3,2.65)
  elif kind=='INN':
   self.box_solid((0,.86,-d/2+1.1),(4.4,1.7,1.15),'aged_wood')
   self.box((0,1.80,-d/2+1.05),(3.5,.13,1.4),'wood_light')
   for x in (-4.3,0,4.3):
    self.mat(x,1.8,2.5,2.5);self.table(x,1.8,1.6,1.12,.57)
    for dz in (-1.05,1.05):self.stool(x,1.8+dz)
   self.shelf(5.8,-d/2+1,1.5)
   self.lamp(-6,2.5);self.lamp(6,2.5)
  elif kind=='STORE':
   self.box_solid((0,.82,-d/2+1.05),(4.1,1.64,1.25),'aged_wood')
   for x in (-3,3):self.shelf(x,0,2.0)
   for x in (-3.1,-1.6,1.6,3.1):self.box_solid((x,.34,3.0),(1.0,.68,.9),'floor_plank')
   self.basket(0,2.3);self.lamp(0,0)
  elif kind=='FISHER':
   self.mat(0,0,3.2,4.6)
   self.bed(-w/2+1.7,-d/2+1.6)
   self.table(1.2,-.8,1.4,.9,.59)
   for x in (-2,0,2):self.basket(x,2.1)
   self.box((w/2-1.2,1.7,-1.7),(.18,2.65,.13),'aged_wood')
   self.box((w/2-1.2,2.4,-1.7),(.85,.12,.1),'rope' if 'rope' in TILES else 'straw')
  elif kind=='FARMHOUSE':
   self.mat(0,0,3.4,4.7);self.bed(-w/2+1.7,-d/2+1.8)
   self.table(1.1,-1.1,1.55,1.05,.55)
   self.basket(-1.7,2.3);self.basket(1.5,2.8)
   self.shelf(w/2-1.25,0,1.45)
  elif kind=='RURAL':
   self.mat(0,0,3.6,5.3)
   self.bed(-w/2+1.6,-d/2+1.7);self.table(1,0,1.5,1,.6)
   self.stool(2.1,.2);self.shelf(w/2-1.15,-d/2+1.45,1.35)
   self.pot(-w/2+1.0,1.8,True);self.lamp(0,-d/2+1.2)
  elif kind=='HUT':
   self.mat(0,0,2.7,4.4);self.bed(-1,-.6)
   self.basket(1.5,1.5);self.table(1.1,-1.8,1.2,.7,.45)
  else: raise Exception('Unknown archetype '+kind)
 def wall_art(self,kind):
  # Hand-painted fictional mountain/calligraphy compositions, central to Murim identity.
  w,d=self.w,self.d
  if kind in ('MANOR_HALL','MANOR_LIBRARY','MANOR_TRAINING','TEAHOUSE','INN','HEALER'):
   art = 'mountain_paint' if kind in ('MANOR_HALL','INN','TEAHOUSE') else 'bamboo_scroll'
   self.box((0,1.98,-d/2+.16),(2.65,1.70,.045),art,'INTERIOR_wallscroll')
   for sx in (-1,1):self.box((sx*1.35,1.98,-d/2+.12),(.055,1.81,.068),'wood_dark','INTERIOR_wallscroll')
   self.box((0,2.86,-d/2+.12),(2.85,.09,.09),'wood_dark','INTERIOR_wallscroll')
   self.box((0,1.1,-d/2+.12),(2.85,.09,.09),'wood_dark','INTERIOR_wallscroll')
  if kind=='MANOR_HALL':
   for sx in [-1,1]:
    self.box((sx*4.5,2.02,-d/2+.16),(1.12,1.66,.05),'bamboo_scroll','INTERIOR_wallscroll')
    self.box((sx*4.5,1.12,-d/2+.13),(1.18,.08,.09),'wood_dark','INTERIOR_wallscroll')
  if kind in ('RURAL','FARMHOUSE','FISHER'):
   self.box((0,2.03,-d/2+.17),(1.0,1.20,.05),'ink_lore','INTERIOR_wallscroll')
 def family_banners(self):
  if not self.id.startswith('FAMILY_'):return
  for col,mesh_name in [('wong_banner','BANNER_WONG'),('wudong_banner','BANNER_WUDONG')]:
   for xx in (-self.w*.29,self.w*.29):
    self.group(mesh_name).polygon_banner(xx,2.18,-self.d/2+.21,col)
 def build(self,kind):
  self.architecture();self.decor(kind);self.wall_art(kind);self.family_banners()
  scene=trimesh.Scene();count=0
  for name,b in self.components.items():
   mesh=b.mesh()
   if mesh is None:continue
   scene.add_geometry(mesh,geom_name=name,node_name=name);count+=len(mesh.faces)
  output=MOD/f'{self.id}.glb';scene.export(str(output))
  return count
LAYOUT={
 'FAMILY_MAIN_HALL':('MANOR_HALL',22,17),
 'FAMILY_LEFT_WING':('MANOR_TRAINING',15,12),
 'FAMILY_RIGHT_WING':('MANOR_LIBRARY',15,12),
 'TEA_HOUSE':('TEAHOUSE',16,13),
 'HERBALIST':('HEALER',13,11),
 'FISHERS_01':('FISHER',10.5,9),
 'FISHERS_02':('FISHER',10,9.5),
 'FARM_HOME_A':('FARMHOUSE',11.5,10),
 'FARM_HOME_B':('FARMHOUSE',11,10.5),
 'HOUSE_GATE':('RURAL',11,9),
 'HOUSE_CENTER':('RURAL',12,10),
 'STORE_FRONT':('STORE',13,11),
 'HOUSE_SE':('RURAL',10,9),
 'RIVERSIDE_INN':('INN',18,14),
 'FARM_HUT':('HUT',9,8)}

def scene_txt(id,kind,w,depth):
 # explicit separate PackedScenes; renderer imports GLB; collision and entrances generated by script
 return f'''[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://godot/S06_InteriorRoom.gd" id="1"]\n[ext_resource type="PackedScene" path="res://interiors_sprint06/models/{id}.glb" id="2"]\n\n[node name="S06_{id}" type="Node3D"]\nscript = ExtResource("1")\nroom_id = "{id}"\nroom_kind = "{kind}"\nroom_width = {w}\nroom_depth = {depth}\n\n[node name="Visual" parent="." instance=ExtResource("2")]\n'''
records=[]
for id,(kind,w,depth) in LAYOUT.items():
 room=Room(w,depth,id);tris=room.build(kind)
 (SCN/f'{id}.tscn').write_text(scene_txt(id,kind,w,depth))
 records.append({'id':id,'kind':kind,'width':w,'depth':depth,'triangles':tris,'collision_furniture':room.coll,'scene':f'res://godot/interiors/{id}.tscn'})
json.dump({'schema':'exo.hwa02.interiors.s06','stage_origin':[680,0,680],'entrances_fixed':True,'roof_presentation':'open-top for third person camera, roof of exterior unchanged','rooms':records,'family_variants':'shared geometry; Wong/Wudong swap painted banners only','interaction':'F near entrance; F near exit; E remains equip/unequip'},open(OUT/'data'/'rooms_manifest.json','w'),ensure_ascii=False,indent=2)
# Preview contact sheet of finished painted materials (no invented 3d renders)
from PIL import ImageFont
sheet=Image.new('RGB',(1200,1160),'#EAE4D9');dd=ImageDraw.Draw(sheet)
dd.text((24,17),'EXO-MURIM | INTERIORES | ATLAS AUTORAL S06',fill='#34333A',stroke_width=0)
for i,(name,c) in enumerate(PALETTE):
 px=(i%5)*238+10;py=(i//5)*137+52
 thumb=img.crop(((i%COLS)*S,(i//COLS)*S,(i%COLS+1)*S,(i//COLS+1)*S)).resize((117,107))
 sheet.paste(thumb,(px,py));dd.text((px+120,py+30),name[:15],fill='#393A41')
sheet.save(OUT/'previews'/'S06_Atlas_Materiais_Murim.png')
print('exported',len(records),'interiors, tris=',sum(x['triangles'] for x in records),'atlas',tex.stat().st_size)
