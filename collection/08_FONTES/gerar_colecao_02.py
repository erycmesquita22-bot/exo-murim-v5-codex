from __future__ import annotations
import os, math, random, hashlib, json, shutil, itertools, zipfile
from pathlib import Path
from collections import Counter
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import trimesh

ROOT=Path(__file__).resolve().parents[1]
OLD=ROOT
ROOT.mkdir(parents=True,exist_ok=True)
for fld in ['01_SOLOS','02_PAREDES_RUINAS','03_PISOS','04_TRANSICOES','05_DECALQUES','06_OBJETOS_GLB','08_FONTES']:
 if OLD!=ROOT:shutil.copytree(OLD/fld,ROOT/fld,dirs_exist_ok=True)
for fld in ['00_CATALOGO','07_DOCUMENTACAO','09_TOPOGRAFIA_GLB','10_ARQUITETURA_GLB','11_RUINAS_GLB','12_NATUREZA_GLB','13_CENAS_DEMO']:
 (ROOT/fld).mkdir(exist_ok=True)
N=128
fontp='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';fontb='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def font(s,b=False):return ImageFont.truetype(fontb if b else fontp,s)
def stable(s):return int.from_bytes(hashlib.sha256(str(s).encode()).digest()[:4],'little')
def C(h):return tuple(bytes.fromhex(h.lstrip('#')))[:3]
def blend(a,b,t):return tuple(int(max(0,min(255,a[i]*(1-t)+b[i]*t))) for i in range(3))
def noise(name,levels=3):
 rng=np.random.default_rng(stable(name));out=np.zeros((N,N),np.float32)
 for sc,weight in [(4,.50),(16,.32),(32,.12),(64,.06)][:levels+1]:
  vv=rng.random((sc+1,sc+1),dtype=np.float32);vv[-1,:]=vv[0,:];vv[:,-1]=vv[:,0]
  f=np.arange(N)*sc/N;xi=f.astype(int);a=f-xi;a=a*a*(3-2*a)
  p0=vv[xi[:,None],xi[None,:]]*(1-a[:,None])*(1-a[None,:])+vv[xi[:,None],xi[None,:]+1]*(1-a[:,None])*a[None,:]
  p1=vv[xi[:,None]+1,xi[None,:]]*(1-a[:,None])*(1-a[None,:])+vv[xi[:,None]+1,xi[None,:]+1]*(a[None,:]*a[:,None])
  # use scipy? corrected interpolation explicitly below
  p1=vv[xi[:,None]+1,xi[None,:]]*(1-a[None,:])+vv[xi[:,None]+1,xi[None,:]+1]*a[None,:]
  out+=weight*(p0*(1-a[:,None])+p1*a[:,None])
 return out

def newtexture(name,kind,palette,folder):
 colors=np.array([C(h) for h in palette],np.uint8)
 ns=noise(name);idx=np.clip((ns*(len(colors)-.01)).astype(int),0,len(colors)-1)
 img=Image.fromarray(colors[idx],'RGB');d=ImageDraw.Draw(img);r=random.Random(stable(name+'sprinkle'))
 if kind in ('grass','moss'):
  for _ in range(360 if kind=='grass' else 200):
   x,y=r.randrange(N),r.randrange(N);length=r.randrange(2,6)
   shade=colors[r.choice((0,1,2,-2))]
   d.line((x,y,x+r.choice((-2,0,1)),y-length),fill=tuple(shade),width=1)
 elif kind in ('earth','sand'):
  for _ in range(250):
   x,y=r.randrange(N),r.randrange(N);k=r.randrange(1,4);col=tuple(colors[r.randrange(len(colors))]);d.rectangle((x,y,x+k,y+r.randrange(1,3)),fill=col)
 elif kind=='stone':
  for _ in range(170):
   x,y=r.randrange(N),r.randrange(N);k=r.randrange(2,8);d.line((x,y,x+k,y+r.randrange(-2,3)),fill=tuple(colors[r.choice([0,1,-1])]),width=1)
 elif kind in ('brick','slab'):
  img=Image.new('RGB',(N,N),C(palette[0]));d=ImageDraw.Draw(img);hh=16 if kind=='brick' else 32;ww=32
  for iy in range(0,N//hh):
   off=ww//2 if iy%2 else 0
   for ix in range(-2,7):
    x=ix*ww+off;y=iy*hh;col=C(palette[(ix*7+iy*3)% (len(palette)-1)+1]);d.rectangle((x+2,y+2,x+ww-2,y+hh-2),fill=col)
    d.line((x+3,y+3,x+ww-4,y+3),fill=blend(col,(236,223,192),.18),width=1)
    if (ix+iy)%7==0:d.line((x+7,y+5,x+13,y+hh-5),fill=C(palette[0]),width=1)
 elif kind=='wood':
  img=Image.new('RGB',(N,N),C(palette[0]));d=ImageDraw.Draw(img)
  for iy in range(8):
   x=iy*16;col=C(palette[1+iy%(len(palette)-1)]);d.rectangle((x+2,0,x+14,127),fill=col)
   for _ in range(11):
    y=r.randrange(N);d.line((x+5,y,x+11,y+r.randrange(8,20)),fill=C(palette[0]),width=1)
 p=ROOT/folder/(name+'.png');img.save(p);return p

NEW_SOILS=[
 ('grama_montanha','grass',['#354934','#4b6542','#69804b','#83995c','#9da978','#b0b18b']),
 ('terra_raizes','earth',['#332d29','#514434','#68563e','#856c4e','#ac8c66','#c7a780']),
 ('sedimento_rio','sand',['#5a5c50','#787b67','#959785','#b2ac91','#d5c5a6','#ebdebb']),
 ('pedra_xisto','stone',['#29333b','#40515a','#5a6a70','#79858a','#a2aca7','#c4c7b9']),
 ('pedra_calcaria','stone',['#4d4f48','#696b60','#888a7c','#a9ac9b','#c5c4b1','#e0dcc6']),
 ('terra_pedregosa','earth',['#453f37','#60594c','#796f5d','#9a8a6d','#b6a482','#d4c3a0']),
 ('musgo_ruina','moss',['#233b2d','#34523a','#456b47','#63835b','#8d9d76','#b1ae88']),
 ('folhagem_prado','grass',['#2e4736','#426b41','#597e48','#71914d','#879a50','#adac69']),
 ('lama_margem','earth',['#2a302b','#43483a','#5c604c','#777963','#92947d','#ada992']),
 ('areia_pedregosa','sand',['#706959','#8f8369','#ae9d7b','#c7b18b','#d8cba7','#eee0bb']),
 ('grama_inverno','grass',['#3c4947','#536459','#6f7b69','#899386','#b3b5a1','#d4d0bd']),
 ('terra_cinza','earth',['#414141','#575854','#71736c','#909188','#adada1','#cfcbba']),
]
NEW_WALLS=[
 ('tijolo_ruina_silicificado','brick',['#2d3034','#525b5e','#718081','#929c96','#b8bcb0','#d5d2bf']),
 ('tijolo_ruina_queimado','brick',['#25272b','#36383c','#4c4c50','#67615b','#8c7d6b','#ae9780']),
 ('bloco_arenito_vermelho','brick',['#613a30','#884c39','#a86649','#bf8460','#d69f7b','#e1b699']),
 ('pedra_templo_lavrada','slab',['#394a4d','#587074','#799397','#a0adab','#c5c7b4','#e1dbc1']),
 ('barro_palha','earth',['#5d513e','#847352','#aa9066','#c0a981','#d6c096','#e8d5b0']),
 ('madeira_templo_escura','wood',['#242329','#443436','#69453d','#855740','#a47855','#c69f74']),
 ('madeira_viga_cobre','wood',['#432b27','#5d3930','#8a4e3c','#b3654c','#cf8060','#e1a47c']),
 ('pedra_calcaria_cortada','brick',['#53594f','#778274','#9da897','#bac3ac','#d8d9c1','#f0e9d5']),
 ('tijolo_limo','brick',['#35423c','#556c5b','#71836a','#99a38c','#afb39c','#c6c4ae']),
 ('revestimento_oriental_ocre','earth',['#625044','#85684e','#b08b61','#d2a979','#e7c69a','#f1dbc0']),
]
NEW_FLOORS=[
 ('laje_rachada','slab',['#343c41','#525e61','#738082','#93a09b','#b4bcb3','#d2d0c0']),
 ('piso_escada_desgastado','slab',['#474744','#66675e','#8b8b7b','#aeaa98','#c7beab','#e3d6bf']),
 ('piso_madeira_mercado','wood',['#2d2926','#594235','#876248','#a87f57','#c99e6d','#e0bc8c']),
 ('piso_madeira_altar','wood',['#282b2d','#37454b','#45606d','#688591','#91a6aa','#bdc2b8']),
 ('piso_telhas_escuras','brick',['#202c31','#35484d','#4a6166','#628087','#84999a','#a8b3aa']),
 ('piso_telha_carmesim','brick',['#3a282d','#66333a','#93444a','#b05854','#ca7c65','#e1a181']),
 ('laje_pedra_musgo','slab',['#34433b','#526855','#799078','#a0ae95','#b6bba5','#d8d1ba']),
 ('piso_ruina_areia','slab',['#685c47','#857358','#aa9069','#c4a97c','#ddc49a','#ecddba']),
]
for name,k,p in NEW_SOILS:newtexture(name,k,p,'01_SOLOS')
for name,k,p in NEW_WALLS:newtexture(name,k,p,'02_PAREDES_RUINAS')
for name,k,p in NEW_FLOORS:newtexture(name,k,p,'03_PISOS')

# Additional corner-coherent terrain masks; corner bits TL=1,TR=2,BR=4,BL=8.
TRANS_PAIRS=[
 ('grama_montanha','pedra_xisto'),('sedimento_rio','seixos'),('terra_raizes','solo_florestal'),
 ('musgo_ruina','laje_rachada'),('grama_viva','terra_umida'),('terra_pedregosa','cascalho'),
 ('grama_inverno','pedra_calcaria'),('folhagem_prado','trilha_batida')
]
u=np.tile(np.arange(N,dtype='float32')[None,:]/(N-1),(N,1));v=u.T
trans=[]
for top,base in TRANS_PAIRS:
 dr=ROOT/'04_TRANSICOES'/f'{base}__para__{top}';dr.mkdir(parents=True,exist_ok=True)
 with Image.open(ROOT/'01_SOLOS'/f'{top}.png') as inp:top_rgb=np.array(inp.convert('RGB'),np.uint8)
 rs=noise('trans'+top+base);edge=np.minimum.reduce([u,1-u,v,1-v]);wave=(rs-.5)*.22*np.minimum(1,edge*14)
 for mask in range(16):
  tl,tr,br,bl=[int(bool(mask & b)) for b in (1,2,4,8)]
  field=(tl*(1-u)*(1-v)+tr*u*(1-v)+br*u*v+bl*(1-u)*v)
  if mask==0:a=np.zeros((N,N),np.uint8)
  elif mask==15:a=np.full((N,N),255,np.uint8)
  else:a=(np.clip((field-.5+wave)*12+.5,0,1)*255).astype('uint8')
  Image.fromarray(np.dstack((top_rgb,a)),'RGBA').save(dr/f'msc4_{mask:02d}.png')
 trans.append({'upper':top,'lower':base,'folder':str(dr.relative_to(ROOT)),'variants':16,'corner_mask':'TL1_TR2_BR4_BL8'})

# Transparent detail decals, grounded to projected mesh or applied in shader.
for kind,color in [('limo_verde',(49,100,58)),('limo_azulado',(69,109,107)),('flores_brancas',(220,213,181)),('petalas_cerejeira',(208,131,140)),('rachadura_areia',(73,65,51)),('sujeira_ruina',(73,74,66)),('pedras_rios',(128,136,125)),('fungos_sombra',(156,136,118))]:
 r=random.Random(stable(kind));im=Image.new('RGBA',(128,128));d=ImageDraw.Draw(im)
 for j in range(65 if 'flores' not in kind else 32):
  x,y=r.randrange(6,123),r.randrange(6,123);rx=r.randrange(1,5);ry=r.randrange(1,4)
  d.ellipse((x-rx,y-ry,x+rx,y+ry),fill=(*color,r.randrange(120,231)))
 im.save(ROOT/'05_DECALQUES'/f'{kind}.png')

class Geo:
 def __init__(self,name):self.name=name;self.parts=[]
 def add(self,m,col):
  col=C(col) if isinstance(col,str) else col
  m.visual.vertex_colors=np.tile([*col,255],(len(m.vertices),1)).astype('uint8')
  self.parts.append((m,col))
 def cube(self,pos,ext,col):
  m=trimesh.creation.box(extents=ext);m.apply_translation(pos);self.add(m,col)
 def cyl(self,pos,r,h,col,sides=8):
  m=trimesh.creation.cylinder(radius=r,height=h,sections=sides)
  m.apply_transform(trimesh.transformations.rotation_matrix(-math.pi/2,[1,0,0]));m.apply_translation(pos);self.add(m,col)
 def cone(self,pos,r,h,col,sides=7):
  m=trimesh.creation.cone(radius=r,height=h,sections=sides)
  m.apply_transform(trimesh.transformations.rotation_matrix(-math.pi/2,[1,0,0]));m.apply_translation(pos);self.add(m,col)
 def roof(self,pos,w,d,h,col):
  x,y,z=pos;vs=np.array([[-w/2,0,-d/2],[w/2,0,-d/2],[0,h,-d/2],[-w/2,0,d/2],[w/2,0,d/2],[0,h,d/2]],float)
  faces=np.array([[0,1,2],[3,5,4],[0,2,5],[0,5,3],[2,1,4],[2,4,5],[1,0,3],[1,3,4]],int)
  m=trimesh.Trimesh(vertices=vs,faces=faces,process=False);m.apply_translation((x,y,z));self.add(m,col)
 def beam(self,a,b,thick,col):
  a=np.asarray(a,float);b=np.asarray(b,float);dv=b-a;dist=np.linalg.norm(dv)
  if dist<1e-5:return
  m=trimesh.creation.box(extents=(thick,dist,thick));m.apply_transform(trimesh.geometry.align_vectors([0,1,0],dv/dist));m.apply_translation((a+b)/2);self.add(m,col)
 def rock(self,pos,size,col,seed):
  rr=np.random.default_rng(seed);v=rr.normal(size=(24,3));v/=np.linalg.norm(v,axis=1)[:,None];v*=np.array(size)
  m=trimesh.convex.convex_hull(v);m.apply_translation(pos);self.add(m,col)
 def save(self,folder):
  p=folder/(self.name+'.glb');s=trimesh.Scene()
  for i,(m,c) in enumerate(self.parts):s.add_geometry(m,geom_name=f'{self.name}_part_{i:03d}')
  p.write_bytes(s.export(file_type='glb'));return p

STONE='#66736d';STONE_LIGHT='#abb2a2';STONE_DARK='#3e4a4b';MOSS='#55745a';WOOD='#503d32';WOOD_L='#987452';PLASTER='#beb09b';ROOF_RED='#974b42';ROOF_TEAL='#425e65';GOLD='#ba9963'

def topo(n,variant):
 a=Geo(n);r=random.Random(stable(n))
 if n.startswith('penhasco') or n.startswith('encosta'):
  h=4.4 if 'alto' in n else 2.6 if 'baixo' in n else 3.1
  if 'canto' in n:h=3.8
  for k in range(9):
   x=-1.7+(k%3)*1.7;z=(k//3-1)*.95
   hh=h*(.72+.09*((k*7)%5));a.cube((x,hh*.5,z), (1.78,hh,1.08),[STONE_DARK,STONE,'#7b8980'][k%3])
   if k%2==0:a.rock((x+.18,hh-.3,z-.2),(.65,.4,.7),'#929d91',stable(n+str(k)))
  a.cube((0,h+.05,0),(5.4,.13,3.2),'#547455' if 'musgoso' in n else '#767c67')
  if 'canto' in n:
   for k in range(4):a.cube((-2.4,1.0+k*.7,1+k*.7),(.9,2+k*.2,1.6),STONE)
 elif n.startswith('rocha') or n.startswith('pedra') or n.startswith('estrato'):
  count=9 if 'pilha' in n else 4
  for k in range(count):
   x=r.uniform(-1.55,1.55);z=r.uniform(-1.5,1.5);h=r.uniform(.5,1.55)
   if 'monolito' in n:h=r.uniform(3,5)
   a.rock((x,h*.48,z),(r.uniform(.35,1.0),h*.54,r.uniform(.35,1.0)),[STONE,STONE_DARK,'#95a299'][k%3],stable(n+str(k)))
  if 'musgo' in n:a.cube((0,.23,0),(2.8,.13,2.3),MOSS)
 elif n.startswith('margem'):
  a.cube((0,.4,-1.1),(4,.8,1.75),STONE)
  a.cube((0,.92,-1.0),(4.1,.17,1.9),'#64866c')
  for k in range(5):
   z=-.6+k*.3;a.cube((-1.55+k*.8,.17,z),(.8,.34,.38),STONE_LIGHT)
 elif n.startswith('plataforma') or n.startswith('patamar'):
  a.cube((0,.32,0),(4,.65,4),STONE)
  a.cube((0,.71,0),(4.2,.13,4.2),STONE_LIGHT)
  for i in (-1,0,1):a.cube((i*1.3,.78,1.93),(1.25,.05,.12),STONE_DARK)
 elif n.startswith('rampa'):
  for k in range(6):a.cube((0,.13+(k*.28),1.8-k*.65),(3.4,.25,.70),STONE if k%2 else STONE_LIGHT)
 elif n.startswith('entrada_caverna'):
  for x in (-1.45,1.45):
   a.rock((x,1.45,0),(1.25,1.55,1.5),STONE_DARK,stable(n+str(x)))
  a.rock((0,3.1,0),(2,1.15,1.7),STONE,stable(n+'top'))
  a.cube((0,.12,.25),(2.7,.24,2.1),'#393a3a')
 else:raise ValueError(n)
 return a

def arch(n,k):
 a=Geo(n); col=ROOF_TEAL if 'jade' in n or 'teal' in n else ROOF_RED if 'vermelho' in n or 'carmesim' in n else WOOD
 if n.startswith('parede') or n.startswith('painel') or n.startswith('divisoria'):
  window='janela' in n;door='porta' in n;plaster=PLASTER if 'ocre' not in n else '#bf986e'
  a.cube((0,.22,0),(4,.44,.45),STONE)
  if not (window or door):a.cube((0,1.65,0),(3.65,2.64,.26),plaster)
  if window:
   for x in [-1.05,1.05]:a.cube((x,1.5,0),(1.5,2.4,.24),plaster)
   a.cube((0,2.65,0),(1.0,.65,.24),plaster)
   for yy in [1.0,1.65,2.3]:a.cube((0,yy,.17),(1.2,.09,.09),WOOD)
   for xx in [-.46,0,.46]:a.cube((xx,1.7,.17),(.08,1.4,.1),WOOD)
  if door:
   for x in [-1.2,1.2]:a.cube((x,1.52,0),(1.4,2.36,.25),plaster)
   a.cube((0,2.75,0),(1.1,.47,.25),plaster)
  for x in [-1.88,1.88]:a.cube((x,1.5,0),(.23,3.0,.50),WOOD)
  a.cube((0,3.05,0),(4.25,.28,.55),WOOD)
  if 'laca' in n:a.cube((0,3.28,0),(4.24,.08,.56),ROOF_RED)
  if 'pedra' in n:a.cube((0,1.65,0),(4,.17,.58),STONE_LIGHT)
 elif n.startswith('base') or n.startswith('fundacao'):
  a.cube((0,.35,0),(4,.7,4),STONE if 'pedra' in n else WOOD)
  a.cube((0,.75,0),(4.1,.12,4.1),STONE_LIGHT)
  for x in [-1.6,-.8,0,.8,1.6]:a.cube((x,.76,2.0),(.09,.07,.11),STONE_DARK)
 elif n.startswith('pilar') or n.startswith('coluna'):
  a.cube((0,.18,0),(1,.36,1),STONE)
  a.cube((0,1.76,0),(.34,3.15,.34),WOOD)
  for y in [1.0,3.15]:a.cube((0,y,0),(.48,.17,.48),GOLD if 'dourado' in n else '#384d50')
  a.cube((0,3.42,0),(.92,.23,.92),WOOD_L)
 elif n.startswith('telhado') or n.startswith('cumeeira'):
  if 'cumeeira' in n:
   a.cube((0,.85,0),(4.1,.23,.33),WOOD)
   for z in [-.12,.12]:a.cube((0,1.01,z),(4.2,.16,.13),col)
   for x in [-1.9,-1.1,-.3,.5,1.3,1.9]:a.cube((x,1.05,0),(.13,.22,.40),col)
  else:
   w=4.8 if 'canto' not in n else 2.45
   a.roof((0,1.0,0),w,4.6,1.0,col)
   a.cube((0,.92,0),(w,.18,4.6),WOOD)
   for z in [-2.14,-1.49,-.84,-.19,.46,1.11,1.76,2.14]:
    for xx in [-1.65,-.55,.55,1.65]:
     if abs(xx)>w/2-.15:continue
     a.beam((xx,1.07,z),(xx*0.24,1.82,z),.052,'#6a6e70' if col==ROOF_TEAL else '#ac6455')
   a.cube((0,1.87,0),(.24,.16,4.75),WOOD)
   for zz in [-2.23,2.23]:a.cube((0,1.03,zz),(w,.19,.15),col)
 elif n.startswith('porta'):
  for x in [-.95,.95]:a.cube((x,1.45,0),(.16,2.9,.2),WOOD)
  a.cube((0,2.97,0),(2.2,.28,.3),WOOD)
  for x in [-.45,.45]:a.cube((x,1.4,0),(.89,2.7,.13),WOOD_L if 'madeira' in n else '#596e6a')
  for x in [-.7,-.3,.3,.7]:a.cube((x,1.4,.11),(.055,2.5,.04),WOOD)
 elif n.startswith('escada') or n.startswith('degrau'):
  for k in range(6):a.cube((0,.13+.22*k,1.6-.52*k),(3.1,.26,.54),WOOD_L if 'madeira' in n else STONE)
 elif n.startswith('beiral'):
  a.cube((0,.85,0),(4.3,.22,.46),WOOD)
  a.cube((0,1.04,0),(4.4,.17,.6),col)
  for x in [-1.9,-.95,0,.95,1.9]:a.beam((x,.75,0),(x,.23,.6),.12,WOOD)
 elif n.startswith('passarela'):
  for j in range(9):a.cube((0,.5,-2+j*.5),(2.3,.15,.45),WOOD_L)
  for x in [-1.0,1.0]:
   for z in [-1.75,.15,1.75]:a.cube((x,1.25,z),(.15,1.4,.16),WOOD)
   a.cube((x,1.76,0),(.13,.11,4.1),WOOD)
 elif n.startswith('janela_lattice'):
  for x in [-1.2,1.2]:a.cube((x,1.2,0),(.17,2.4,.19),WOOD)
  for y in [.15,2.25]:a.cube((0,y,0),(2.6,.16,.2),WOOD)
  for x in [-.7,-.25,.25,.7]:a.cube((x,1.2,.02),(.09,2.1,.12),WOOD)
  for y in [.65,1.2,1.75]:a.cube((0,y,.02),(2.5,.08,.12),WOOD)
 else:raise ValueError(n)
 return a

def ruin(n,k):
 a=Geo(n);r=random.Random(stable(n))
 if n.startswith('muro') or n.startswith('parede') or n.startswith('corredor'):
  damaged=('destruido' in n or 'quebrado' in n or 'ruina' in n)
  col=STONE if 'arenito' not in n else '#a28b72'
  for iy in range(6):
   for ix in range(7):
    x=-1.8+ix*.6+(iy%2)*.2;y=.25+iy*.48
    if damaged and ((ix in (4,5,6) and iy>2) or (ix==2 and iy>4)) and r.random()>.23:continue
    a.cube((x,y,0),(.56,.43,.54),col if (ix+iy)%3 else STONE_LIGHT)
    if (ix+iy)%11==0:a.cube((x,y+.13,.28),(.31,.06,.06),STONE_DARK)
  if 'canto' in n or 'T_' in n:
   for j in range(6):
    a.cube((-1.8,.25+j*.48,1.0),(.5,.43,2),STONE)
  if 'corredor' in n:
   a.cube((0,.07,1.9),(4,.14,4),STONE_DARK)
   if 'T_' in n:a.cube((1.3,.07,0),(2.8,.14,4),STONE_DARK)
 elif n.startswith('arco') or n.startswith('portal'):
  for x in [-1.55,1.55]:
   for iy in range(6):a.cube((x,.28+iy*.52,0),(.6,.47,.85),STONE if iy%3 else STONE_LIGHT)
  a.cube((0,3.2,0),(3.9,.47,1),STONE)
  a.cube((0,3.65,0),(4.3,.30,1.16),STONE_DARK)
  if 'musgo' in n:a.cube((-.9,3.9,0),(.85,.11,.95),MOSS)
 elif n.startswith('coluna') or n.startswith('pilar'):
  h=3.5 if 'inteiro' in n else r.uniform(1.6,2.6)
  a.cube((0,.2,0),(1.15,.4,1.1),STONE)
  a.cube((0,.2+h/2,0),(.68,h,.66),STONE_LIGHT)
  a.cube((0,h+.33,0),(1.05,.24,1.05),STONE)
  if 'musgo' in n:a.cube((.26,h-.22,.2),(.42,.2,.35),MOSS)
 elif n.startswith('laje') or n.startswith('piso'):
  for ix in range(4):
   for iz in range(4):
    if 'partido' in n and (ix+iz)%7==0:continue
    y=.15 if (ix+iz)%4 else .13
    a.cube((-1.5+ix,y,-1.5+iz),(.96,.25,.95),STONE if (ix+iz)%3 else STONE_LIGHT)
 elif n.startswith('escada'):
  for i in range(7):
   if i==4 and 'quebrada' in n:continue
   a.cube((0,.14+i*.3,1.9-i*.6),(3.8,.28,.63),STONE if i%2 else STONE_LIGHT)
 elif n.startswith('altar'):
  a.cube((0,.33,0),(3,.66,3),STONE)
  a.cube((0,.87,0),(2.5,.47,2.3),STONE_LIGHT)
  for x in [-1,1]:a.cube((x,1.8,-.7),(.35,1.4,.4),STONE_DARK)
  a.cube((0,1.65,0),(1.2,.5,1.2),'#57706a')
 elif n.startswith('entulho'):
  for j in range(19):
   x=r.uniform(-1.8,1.8);z=r.uniform(-1.5,1.5);h=r.uniform(.2,.6)
   a.cube((x,h/2,z),(r.uniform(.2,.8),h,r.uniform(.22,.66)),STONE if j%2 else STONE_LIGHT)
 elif n.startswith('barricada'):
  for x in [-1.4,-.6,.2,1.0]:a.beam((x,.16,-.4),(x+(.5 if x<0 else -.5),1.8,.5),.24,WOOD)
 elif n.startswith('portao'):
  for x in [-1.55,1.55]:a.cube((x,1.65,0),(.55,3.3,.78),STONE)
  a.cube((0,3.48,0),(3.9,.65,.9),STONE)
  for x in [-1.15,-.6,0,.6,1.15]:a.cube((x,1.47,.2),(.12,2.9,.17),'#353b3d')
 else:raise ValueError(n)
 return a

def nature(n,k):
 a=Geo(n);r=random.Random(stable(n))
 if n.startswith('bambu'):
  for j in range(3 if 'grupo' in n else 1):
   x=r.uniform(-.65,.65) if 'grupo' in n else 0;z=r.uniform(-.65,.65) if 'grupo' in n else 0;h=r.uniform(3,4.8)
   a.cyl((x,h/2,z),.09,h,'#718a51',8)
   for i in range(4):
    y=(i+1)*h/5;a.cyl((x,y,z),.12,.06,'#384b32',8)
    a.beam((x,y,z),(x+(.6 if i%2 else -.6),y+.42,z+.2),.06,'#536d42')
    for off in [-.25,.25]:a.cube((x+(.70 if i%2 else -.70),y+.42+off,z+.15),(.71,.08,.22),'#597b43')
 elif n.startswith('arvore'):
  h=5.5 if 'alta' in n else 3.6
  a.cyl((0,h*.42,0),.24,h*.84,WOOD,7)
  for k,(x,y,z) in enumerate([(-.65,h*.81,0),(.65,h*.84,.4),(0,h,0),(0,h*.76,-.6)]):
   a.rock((x,y,z),(.9,.75,.88), '#537456' if 'sombria' in n else '#899c6b',stable(n+str(k)))
 elif n.startswith('pinheiro'):
  a.cyl((0,2.15,0),.22,4.3,WOOD,8)
  for i in range(4):a.cone((0,1.1+i*.85,0),1.35-i*.19,1.8,'#315548' if i%2 else '#496a50',8)
 elif n.startswith('rochedo'):
  for i in range(7):
   h=r.uniform(.8,2.8);a.rock((r.uniform(-1.25,1.25),h*.45,r.uniform(-1.2,1.2)),(.6,h*.56,.8),STONE if i%2 else STONE_DARK,stable(n+str(i)))
 else:raise ValueError(n)
 return a

TOPO=[
 'penhasco_baixo_reto','penhasco_alto_reto','penhasco_baixo_musgoso','penhasco_canto_interno','penhasco_canto_externo','encosta_escarpada',
 'encosta_pedregosa','rocha_pilha_grande','rocha_pilha_baixa','rocha_monolito','rocha_monolito_musgo','pedra_xisto_grupo',
 'estrato_pedra_montanha','margem_rio_grama','margem_rio_pedra','plataforma_rochosa','patamar_montanha','rampa_escadaria_pedra','entrada_caverna_rochosa'
]
ARCH=[
 'parede_reboco_claro','parede_reboco_ocre','parede_madeira_laca','parede_pedra_templo','painel_janela_lattice','painel_porta_livre',
 'divisoria_papel_janela','fundacao_pedra','base_madeira_templo','pilar_madeira_dourado','coluna_madeira_escura',
 'telhado_vermelho_4m','telhado_teal_4m','telhado_canto_vermelho','telhado_canto_jade','cumeeira_vermelha','cumeeira_jade',
 'beiral_vermelho','beiral_teal','porta_madeira_dupla','porta_laca_jade','escada_madeira_templo','degrau_pedra_cidade',
 'passarela_guarda','janela_lattice_quadrada'
]
RUINS=[
 'muro_ruina_cinza','muro_ruina_arenito','parede_ruina_destruido','parede_ruina_canto','parede_ruina_T_juncao',
 'corredor_ruina_reto','corredor_ruina_T_juncao','arco_portal_antigo','arco_portal_musgo','portal_ruina_cinza',
 'coluna_ruina_inteiro','coluna_ruina_musgo','pilar_ruina_quebrado','laje_ruina_inteira','laje_ruina_partida',
 'escada_ruina_inteira','escada_ruina_quebrada','altar_ruina_antigo','entulho_ruina_grande','barricada_ruina_madeira','portao_ruina_ferro'
]
NATURE=['bambu_alto_folhas','bambu_grupo_rio','arvore_alta_sombria','arvore_baixa_prado','pinheiro_escarpado','rochedo_rio_musgoso']

NEW_GLBS=[]
for group,names,func in [('09_TOPOGRAFIA_GLB',TOPO,topo),('10_ARQUITETURA_GLB',ARCH,arch),('11_RUINAS_GLB',RUINS,ruin),('12_NATUREZA_GLB',NATURE,nature)]:
 for i,n in enumerate(names):
  g=func(n,i);f=g.save(ROOT/group)
  allverts=np.concatenate([m.vertices for m,col in g.parts]);lo=allverts.min(axis=0);hi=allverts.max(axis=0)
  triangle_count=sum(len(m.faces) for m,_ in g.parts)
  NEW_GLBS.append({'id':n,'category':group,'file':str(f.relative_to(ROOT)),'bounds_m':list(map(lambda x:round(float(x),3),hi-lo)),'ground_pivot':True,
                   'triangles':triangle_count, 'static_solid':not ('arvore' in n and False), 'grid_m':4.0 if group in ['09_TOPOGRAFIA_GLB','10_ARQUITETURA_GLB','11_RUINAS_GLB'] else 0,
                   'collision_hint':'static_compound_convex_or_trimesh' if group=='09_TOPOGRAFIA_GLB' else 'static_simplified_box_or_compound',
                   'prototype':True})
  print('glb',n,triangle_count,flush=True)

# Validate new geometry by loading each exported GLB; useful before generating approvals.
for x in NEW_GLBS:
 s=trimesh.load(ROOT/x['file'],force='scene')
 assert len(s.geometry)>0 and sum(len(m.faces) for m in s.geometry.values())>0,x
 assert all(np.isfinite(m.vertices).all() for m in s.geometry.values()),x

old_manifest=OLD/'07_DOCUMENTACAO/MANIFESTO_ASSETS.json'
if not old_manifest.exists():old_manifest=ROOT/'07_DOCUMENTACAO/MANIFESTO_COLECAO_01.json'
legacy=json.loads(old_manifest.read_text())
count_original=legacy['terrain_materials']+legacy['wall_materials']+legacy['floor_materials']+legacy['transition_tiles']+legacy['decal_png']+len(legacy['objects_glb'])
manifest={'title':'EXO-Murim — Colecao Ambiental 02: Fundacao do Mundo Regional','status':'ASSETS DE APROVACAO — NAO INTEGRADO AO JOGO','coordinate_system':'+Y up, metre-ish world units, centered ground origin','base_collection':'01',
 'base_resources':{'soils':legacy['terrain_materials'],'walls':legacy['wall_materials'],'floors':legacy['floor_materials'],'transitions':legacy['transition_tiles'],'decals':legacy['decal_png'],'glb':len(legacy['objects_glb'])},
 'new_resources':{'soils':len(NEW_SOILS),'walls':len(NEW_WALLS),'floors':len(NEW_FLOORS),'transitions':len(TRANS_PAIRS)*16,'decals':8,'glb':len(NEW_GLBS)},
 'total_unique_resources':count_original+len(NEW_SOILS)+len(NEW_WALLS)+len(NEW_FLOORS)+len(TRANS_PAIRS)*16+8+len(NEW_GLBS),
 'transition_pairs_02':trans,'new_glbs':NEW_GLBS,'legacy_glbs':legacy['objects_glb'],
 'limitations':['Sem colisor integrado em cenas Godot','Modelos GLB low-poly candidatos, ainda sem LODs ou animacoes','Gerador regional de 88 mapas nao integrado','Colisao e sockets devem ser ajustados na engine','Nenhuma das cenas demonstrativas e jogavel; pranchas mostram composicao de assets reais']}
(ROOT/'07_DOCUMENTACAO'/'MANIFESTO_COLECAO_02.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'07_DOCUMENTACAO'/'MANIFESTO_COLECAO_01.json').write_text(json.dumps(legacy,ensure_ascii=False,indent=2),encoding='utf-8')
print('MANIFEST:',manifest['new_resources'],'TOTAL',manifest['total_unique_resources'],flush=True)

# Edge-matched tile finishing: both edges share the same values, while center stays unmodified.
# This is a prototype-friendly guarantee of color continuity on repeated UV tiles.
def enforce_tile_edges(p,band=12):
 arr=np.array(Image.open(p).convert('RGB'),np.float32)
 for k in range(band):
  alpha=(band-k)/band
  avg=(arr[:,k].copy()+arr[:,-1-k].copy())*.5
  arr[:,k]=arr[:,k]*(1-alpha)+avg*alpha
  arr[:,-1-k]=arr[:,-1-k]*(1-alpha)+avg*alpha
 for k in range(band):
  alpha=(band-k)/band
  avg=(arr[k].copy()+arr[-1-k].copy())*.5
  arr[k]=arr[k]*(1-alpha)+avg*alpha
  arr[-1-k]=arr[-1-k]*(1-alpha)+avg*alpha
 Image.fromarray(np.uint8(np.clip(arr,0,255)),'RGB').save(p)

for folder in ['01_SOLOS','02_PAREDES_RUINAS','03_PISOS']:
 for file in (ROOT/folder).glob('*.png'):enforce_tile_edges(file)
# Replace old and new mask RGBs with the edge-matched upper texture. Preserve the MSC4 alpha.
for directory in (ROOT/'04_TRANSICOES').iterdir():
 if not directory.is_dir() or '__para__' not in directory.name:continue
 top=directory.name.split('__para__',1)[1]
 src=ROOT/'01_SOLOS'/f'{top}.png'
 if not src.exists():src=ROOT/'03_PISOS'/f'{top}.png'
 if not src.exists():continue
 rgb=np.array(Image.open(src).convert('RGB'),np.uint8)
 for imagefile in directory.glob('msc4_*.png'):
  rgba=np.array(Image.open(imagefile).convert('RGBA'))
  rgba[:,:,:3]=rgb
  Image.fromarray(rgba,'RGBA').save(imagefile)
print('Finished seamless edges and refreshed overlay RGB in terrain transitions.',flush=True)
