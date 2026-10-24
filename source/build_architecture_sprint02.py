"""EXO Murim Haneul architectural sprint 02. Original geometry & digitally painted textures.
No borrowed meshes/textures. Fixed placements: family ownership changes signs, not buildings.
Y up, +Z facade, trimesh/Pillow/numpy. Generated project assets are local-owned.
"""
from pathlib import Path
import math, random, json, hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import trimesh
ROOT=Path(__file__).resolve().parents[1]
DIR=ROOT/'architecture_sprint02'; DIR.mkdir(exist_ok=True)
(DATA:=DIR/'textures').mkdir(exist_ok=True)
(KIT:=DIR/'kit').mkdir(exist_ok=True)
PALETTE={
'wall_cream':'#DED5BC','wall_warm':'#D5C8AA','wall_cool':'#CCD0C8','wall_moss':'#CACAB2','wall_sand':'#D8CEB3',
'wall_dark':'#ACA994','wall_trim':'#BEB4A0','wood_dark':'#49382E','wood':'#795741','wood_warm':'#976E4B','wood_light':'#AE8960',
'wood_shadow':'#342C2B','roof_slate':'#46515B','roof_smoke':'#59636A','roof_charcoal':'#343E48','roof_blue':'#5E7074',
'roof_ridge':'#697477','tile_cut':'#262D35','stone':'#A4A19A','stone_dark':'#6E746E','paper':'#E7DBBF',
'paper_dim':'#CBBF9F','metal_gold':'#C4A06A','bronze':'#826443','lantern':'#D9A760','ink':'#26323A',
'sign_tea':'#356F6D','sign_healer':'#55745A','sign_inn':'#9B624A','sign_shrine':'#947052','ground_ochre':'#AC9875'
}
NAMES=list(PALETTE); NCOL=6; TS=256; WIDTH=NCOL*TS; HEIGHT=math.ceil(len(PALETTE)/NCOL)*TS
atlas=Image.new('RGB',(WIDTH,HEIGHT)); painter=ImageDraw.Draw(atlas)
for i,(name,hx) in enumerate(PALETTE.items()):
 rng=random.Random(1700+i*53)
 x=(i%NCOL)*TS; y=(i//NCOL)*TS
 rgb=tuple(int(hx[k:k+2],16) for k in (1,3,5))
 painter.rectangle((x,y,x+TS-1,y+TS-1),fill=rgb)
 def mix(c,amount):return tuple(max(0,min(255,int(v+amount))) for v in c)
 # Crisp, restrained illustrated hand-painted mark-making, deterministic tileable base.
 for j in range(3300):
  px=x+rng.randint(4,TS-5);py=y+rng.randint(4,TS-5)
  delta=rng.randint(-10,9)
  painter.point((px,py),fill=mix(rgb,delta))
 if name.startswith('wall'):
  for _ in range(58):
   px=x+rng.randint(8,230);py=y+rng.randint(7,238)
   L=rng.randint(4,20)
   painter.arc((px,py,px+L,py+rng.randint(2,7)),180,332,fill=mix(rgb,-22),width=1)
  for _ in range(28):
   px=x+rng.randint(10,231);py=y+rng.randint(20,232)
   painter.line((px,py,px+rng.randint(3,14),py),fill=mix(rgb,15),width=2)
  if name in ('wall_moss','wall_dark'):
   for _ in range(26):
    px=x+rng.randint(5,247);py=y+rng.randint(170,247)
    painter.ellipse((px,py,px+12,py+5),fill=mix(rgb,-27))
 elif name.startswith('roof'):
  # overlapping curved clay tiles: staggered rows, dark undershadows and pale light-catching arcs.
  for row in range(0,TS+12,28):
   yy=y+row
   painter.line((x,yy,x+255,yy),fill=mix(rgb,-39),width=4)
   for cc in range(-25,TS+27,32):
    xx=x+cc+(16 if (row//28)%2 else 0)
    painter.arc((xx,yy-22,xx+34,yy+7),4,176,fill=mix(rgb,-28),width=3)
    painter.arc((xx+2,yy-24,xx+32,yy+2),190,345,fill=mix(rgb,32),width=2)
    painter.line((xx+15,yy-21,xx+15,yy-4),fill=mix(rgb,12),width=1)
 elif name.startswith('wood'):
  for q in range(24):
   py=y+rng.randint(5,TS-5); wig=rng.randint(-3,3)
   painter.line((x+6,py,x+TS-6,py+wig),fill=mix(rgb,rng.choice([-24,-17,20])),width=1)
   if q%4==0:
    px=x+rng.randint(32,160)
    painter.arc((px,py-7,px+27,py+7),90,270,fill=mix(rgb,-30),width=1)
 elif name.startswith('stone'):
  for row in range(0,256,48):
   painter.line((x,y+row,x+255,y+row),fill=mix(rgb,-30),width=3)
   for col in range(0,256,61):
    xx=x+col+(26 if row%96==0 else 0)
    painter.line((xx,y+row,xx,y+row+46),fill=mix(rgb,-18),width=2)
 elif name in ('paper','paper_dim'):
  for _ in range(37):
   px=x+rng.randint(8,240);py=y+rng.randint(8,243)
   painter.line((px,py,px+rng.randint(3,18),py+1),fill=mix(rgb,-13),width=1)
 elif name.startswith('sign_'):
  # Symbol is unique abstract heraldry, not borrowed characters/logos.
  gold=(225,206,159)
  painter.rounded_rectangle((x+45,y+25,x+210,y+228),radius=18,outline=gold,width=8)
  painter.line((x+78,y+105,x+178,y+105),fill=gold,width=9)
  if name=='sign_tea':
   painter.arc((x+93,y+77,x+170,y+150),0,180,fill=gold,width=8)
   painter.line((x+112,y+174,x+145,y+174),fill=gold,width=8)
  elif name=='sign_healer':
   painter.arc((x+103,y+69,x+158,y+174),205,45,fill=gold,width=9)
   painter.line((x+131,y+83,x+131,y+167),fill=gold,width=8)
  else:
   painter.polygon([(x+130,y+65),(x+164,y+120),(x+130,y+178),(x+98,y+119)],outline=gold)
# Gutter-safe UV interior 9px
atlas.save(DATA/'EXO_Murim_Architecture_InkAtlas_1536.png',optimize=True)
index={k:i for i,k in enumerate(NAMES)}
def uv(name,pad=6):
 i=index[name];tx=(i%NCOL)*TS;ty=(i//NCOL)*TS
 return [( (tx+pad)/WIDTH,1-(ty+TS-pad)/HEIGHT),((tx+TS-pad)/WIDTH,1-(ty+TS-pad)/HEIGHT),((tx+TS-pad)/WIDTH,1-(ty+pad)/HEIGHT),((tx+pad)/WIDTH,1-(ty+pad)/HEIGHT)]
class B:
 def __init__(self,name):self.name=name;self.verts=[];self.faces=[];self.uv=[];self.cx=0;self.cy=0;self.cz=0;self.yaw=0
 def place(self,x=0,y=0,z=0,yaw=0):self.cx,self.cy,self.cz,self.yaw=x,y,z,yaw
 def tr(self,p):
  x,y,z=p;c=math.cos(self.yaw);s=math.sin(self.yaw)
  return (self.cx+c*x+s*z,self.cy+y,self.cz-s*x+c*z)
 def quad(self,points,col):
  idx=len(self.verts);self.verts.extend(self.tr(p) for p in points);self.faces.extend(((idx,idx+1,idx+2),(idx,idx+2,idx+3)));self.uv.extend(uv(col))
 def box(self,c,sz,col):
  x,y,z=c;w,h,d=sz;x0=x-w/2;x1=x+w/2;y0=y-h/2;y1=y+h/2;z0=z-d/2;z1=z+d/2
  q=[[(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)],[(x1,y0,z0),(x0,y0,z0),(x0,y1,z0),(x1,y1,z0)],[(x0,y0,z0),(x0,y0,z1),(x0,y1,z1),(x0,y1,z0)],[(x1,y0,z1),(x1,y0,z0),(x1,y1,z0),(x1,y1,z1)],[(x0,y1,z1),(x1,y1,z1),(x1,y1,z0),(x0,y1,z0)],[(x0,y0,z0),(x1,y0,z0),(x1,y0,z1),(x0,y0,z1)]]
  for pts in q:self.quad(pts,col)
 def beam(self,a,c,width,depth,col):
  a=np.asarray(a,float);c=np.asarray(c,float);v=c-a;n=np.linalg.norm(v)
  if n<.001:return
  f=v/n;t=np.cross(f,[0,1,0]);
  if np.linalg.norm(t)<.04:t=np.cross(f,[1,0,0])
  t=t/np.linalg.norm(t)*width/2;r=np.cross(f,t);r=r/np.linalg.norm(r)*depth/2
  lower=[a-t-r,a+t-r,a+t+r,a-t+r];upper=[c-t-r,c+t-r,c+t+r,c-t+r]
  for j in range(4):self.quad([lower[j],lower[(j+1)%4],upper[(j+1)%4],upper[j]],col)
  self.quad(lower[::-1],col);self.quad(upper,col)
 def prism_roof_panel(self,pts,thickness,col):
  # Solid undersurface; nonzero depth means eave is never a floating single-sided sheet.
  p=[np.asarray(e,float) for e in pts];q=[v-np.array([0,thickness,0]) for v in p]
  self.quad(p,col);self.quad(q[::-1],'roof_charcoal')
  for j in range(4): self.quad([p[j],p[(j+1)%4],q[(j+1)%4],q[j]],'roof_charcoal')
 def mesh(self,texture):
  m=trimesh.Trimesh(vertices=np.array(self.verts,dtype=np.float32),faces=np.array(self.faces,dtype=np.int64),process=False)
  m.visual=trimesh.visual.texture.TextureVisuals(uv=np.array(self.uv,dtype=np.float32),material=trimesh.visual.material.PBRMaterial(baseColorTexture=texture,roughnessFactor=1.0,metallicFactor=0,doubleSided=True,name='EXO_S02_Original_InkPaint'))
  return m
G={}
def group(name):
 if name not in G:G[name]=B(name)
 return G[name]

def ground(x,z):
 center=66+8*math.sin((z+20)/41)+z*.045
 return (.2+.17*math.sin(x*.072+z*.013)+.17*math.cos(z*.093-x*.024)+max(0,(-x-57)/55)**1.8*11.5+max(0,(-z-65)/45)*max(0,(-x-55)/65)*6-2.25*max(0,1-abs(x-center)/12)**1.35)

def roof(b,w,d,wall,rise=1.40,style='rural',tile='roof_slate'):
 # Gabled tiled roof with deep eaves, clear structural collar beams and ridge support.
 e=.72 if style!='hall' else 1.0
 half=w/2+e;hl=d/2+.52;ridge=wall+rise+.11
 def fy(x,z):
  u=min(1.0,abs(x)/half);v=min(1.0,abs(z)/hl)
  return wall+.16+rise*(1-u**1.02)+(.10 if style!='rural' else .045)*(u**7)*(v**5)
 # eave sill physically sits on lintel at wall's upper edge
 for side in (-1,1):
  b.beam((side*(w/2-.35),wall-.30,-d/2),(side*(w/2-.35),wall-.30,d/2),.23,.22,'wood_dark')
  for z in np.linspace(-d/2+.3,d/2-.3,max(4,int(d/1.48))):
   b.beam((side*(w/2-.25),wall-.27,z),(side*(half-.08),fy(half-.08,z)-.11,z),.18,.15,'wood_warm')
   # decorative strut from post to rafter
   b.beam((side*(w/2-.12),wall-.68,z),(side*(w/2+.30),wall-.03,z),.14,.14,'wood_dark')
  # Panels are contiguous, double thickness, alternate minor tile colors.
  nx=max(5,round(w/2/1.20));nz=max(6,round(d/1.15))
  for i in range(nx):
   xa=side*half*(1-i/nx);xb=side*half*(1-(i+1)/nx)
   for j in range(nz):
    za=-hl+2*hl*j/nz;zb=-hl+2*hl*(j+1)/nz
    pts=[(xa,fy(xa,za),za),(xa,fy(xa,zb),zb),(xb,fy(xb,zb),zb),(xb,fy(xb,za),za)]
    b.prism_roof_panel(pts,.115, tile if (i*23+j*7)%19 else 'roof_smoke')
  # Actual end fascia and gutter edge, cut to slope.
  for end in (-hl,hl):
   for i in range(nx):
    xa=side*half*(1-i/nx);xb=side*half*(1-(i+1)/nx)
    b.beam((xa,fy(xa,end)-.095,end),(xb,fy(xb,end)-.095,end),.13,.15,'roof_charcoal')
  b.beam((side*half,fy(half,-hl)-.12,-hl),(side*half,fy(half,hl)-.12,hl),.12,.19,'roof_ridge')
 # Gables fill triangular hole beneath roof at BOTH ends, properly touching roof pitch.
 for sign in (-1,1):
  z=sign*(d/2-.085)
  for i in range(12):
   x0=-w/2+w*i/12;x1=-w/2+w*(i+1)/12
   b.quad([(x0,wall-.17,z),(x1,wall-.17,z),(x1,fy(x1,z)-.07,z),(x0,fy(x0,z)-.07,z)],'wall_warm')
  # Exposed hanging king post + 2 diagonal members
  b.beam((0,wall-.13,z+sign*.065),(0,ridge-.13,z+sign*.065),.18,.16,'wood_dark')
  for side in (-1,1):
   b.beam((side*(w/2-.1),wall-.15,z+sign*.10),(0,ridge-.15,z+sign*.10),.15,.17,'wood_warm')
 # Ridge capping small ornaments at both ends, rather than high upturned sci-fi fins.
 b.beam((0,ridge-.04,-hl-.12),(0,ridge-.04,hl+.12),.30,.24,'roof_ridge')
 for zz in (-hl-.12,hl+.12):b.box((0,ridge-.08,zz),(.48,.30,.42),'roof_charcoal')

def lattice(b,x,y,z,width,height,front=True,style=0):
 b.box((x,y,z),(width+.20,height+.21,.12),'wood_dark')
 b.box((x,y,z+(.073 if front else -.073)),(width-.06,height-.07,.09),'paper')
 # fine ink border and geometry lattice, not large 3D panes
 for i in range(1,4):
  xx=x-width/2+width*i/4
  b.box((xx,y,z+.136),(0.053,height-.10,.074),'wood_warm')
 for i in range(1,4):
  yy=y-height/2+height*i/4
  b.box((x,yy,z+.141),(width-.07,.053,.076),'wood_warm')
 if style%2:
  b.beam((x-width*.35,y-height*.30,z+.14),(x+width*.35,y+height*.30,z+.14),.027,.06,'wood_dark')

def build_house(b,kind,w,d,wall,wall_tex='wall_cream',marker=0):
 hall=kind in ('manor','hall'); tea=kind in ('tea','inn'); clinic=kind=='clinic'; store=kind=='store'; shrine=kind=='shrine'
 # Foundation and coping are flush with architectural supports, not separate levitating blocks.
 b.box((0,-.10,0),(w+.65,.54,d+.65),'stone_dark')
 b.box((0,.17,0),(w+.45,.16,d+.45),'stone')
 b.box((0,wall/2+.23,0),(w-.18,wall-.32,d-.18),wall_tex)
 # Soil/plaster wall remains consistent while having different painted tile variants.
 for z in (-d/2+.04,d/2-.04):
  b.box((0,.48,z),(w-.5,.14,.16),'wood_warm')
  b.box((0,wall-.10,z),(w+.08,.30,.27),'wood_dark')
 for x in (-w/2+.08,w/2-.08):
  b.box((x,.42,0),(.21,.23,d+.06),'wood_dark')
  b.box((x,wall-.12,0),(.25,.30,d+.09),'wood_dark')
  for z in (-d/2+.12,d/2-.12):
   b.box((x,wall/2+.07,z),(.28,wall-.13,.30),'wood_warm')
 # additional timber vertical bays / carved top panels, both front and back
 n_bay=max(3,int(w/2.4))
 for i in range(1,n_bay):
  x=-w/2+w*i/n_bay
  for z in (-d/2+.065,d/2+.065):
   b.box((x,wall*.55,z),(.13,wall-.50,.19),'wood')
 # front entrance is a visually inset timber door, with side frames and upper lintel
 z=d/2+.125
 b.box((0,1.25,z),(1.62,2.23,.17),'wood_dark')
 for sx in (-.40,.40):
  b.box((sx,1.22,z+.102),(.71,2.00,.06),'wood')
  b.box((sx,1.15,z+.150),(.05,1.70,.042),'wood_dark')
 b.box((0,2.39,z+.08),(1.92,.16,.19),'wood_warm')
 for sign in (-1,1):
  b.box((sign*.84,1.27,z+.14),(.18,2.31,.22),'wood_dark')
  b.box((sign*.125,1.12,z+.199),(.065,.14,.045),'metal_gold')
 # extra top transom, painted dark timber + tiled family panel
 b.box((0,wall-.65,z+.04),(2.25,.52,.16),'wood_shadow')
 for j in range(-3,4):b.box((j*.28,wall-.65,z+.15),(.045,.42,.05),'wood_light')
 # sills and carved side windows
 winw=min(1.45,max(1.05,w*.16));xoff=max(2.0,w*.31)
 for sign in (-1,1):
  lattice(b,sign*xoff,wall*.54,z+.04,winw,1.28,style=marker)
  b.box((sign*xoff,wall*.54-.78,z+.10),(winw+.3,.16,.33),'wood_dark')
 # side façade windows
 for sign in (-1,1):
  x=sign*(w/2+.08)
  b.box((x,wall*.59,0),(.14,1.18,1.58),'wood_dark')
  b.box((x+sign*.06,wall*.59,0),(.14,1.02,1.43),'paper_dim')
  for j in (-.37,.0,.37):b.box((x+sign*.15,wall*.59,j),(.08,1.0,.045),'wood_warm')
 # steps and covered veranda hall entrance support posts
 for j in range(3):b.box((0,.11-j*.105,d/2+.63+j*.28),(2.25+j*.27,.17,1.03),'stone')
 if tea or hall or shrine:
  for sx in (-w*.40,w*.40):
   pz=d/2+.43
   b.box((sx,wall*.48,pz),(.28,wall-.42,.32),'wood_dark')
   b.box((sx,wall-.19,pz),(.49,.28,.51),'wood_warm')
   # symbolic triangular corbel/bracket, supports roof overhang from porch column
   b.beam((sx,wall-.53,pz),(sx+( -.23 if sx>0 else .23),wall+.03,pz),.15,.20,'wood')
  b.box((0,wall-.32,d/2+.39),(w*.88,.23,.27),'wood_dark')
 # roof physically sits upon continuous wall upper framing and gable
 tile={'manor':'roof_blue','tea':'roof_smoke','inn':'roof_smoke','shrine':'roof_charcoal'}.get(kind,'roof_slate')
 roof(b,w,d,wall,1.70 if hall else (1.50 if tea else 1.26),style='hall' if hall or tea else 'rural',tile=tile)
 # rural ornamental elements coherent with each use (no borrowed signage)
 if tea or clinic or store:
  sc='sign_tea' if tea else ('sign_healer' if clinic else 'sign_inn')
  b.box((w*.40,2.37,z+.37),(.95,1.22,.09),sc)
  b.box((w*.40,3.1,z+.37),(1.12,.11,.12),'wood_dark')
 if shrine:
  b.box((0,2.45,z+.29),(1.50,.32,.13),'sign_shrine')
 # Lamps whose support brackets attach to the columns and roof soffit.
 if tea or hall or clinic or shrine:
  for sx in (-w*.40,w*.40):
   b.beam((sx,wall-.31,z),(sx,wall-1.02,z+.20),.065,.075,'wood_dark')
   b.box((sx,wall-1.31,z+.20),(.38,.47,.34),'lantern')
   b.box((sx,wall-1.04,z+.20),(.47,.09,.43),'wood_dark')
   b.box((sx,wall-1.59,z+.20),(.47,.09,.43),'wood_dark')
 # intentional restrained hand-painted embroidery on facades
 for sx in (-w/2+.66,w/2-.66):
  b.box((sx,wall-.45,z+.12),(.22,.10,.13),'wood_light')

def gateway(b,w=6.7,wall=3.6,d=2.2):
 # Mortise-like visible crossbeams and roof over actual timber columns.
 for sx in (-w/2+.42,w/2-.42):
  b.box((sx,wall*.48,0),(.49,wall,.52),'wood_dark')
  b.box((sx,wall*.05,0),(.67,.32,.67),'stone_dark')
  b.box((sx,wall-.25,0),(.76,.35,.73),'wood_warm')
 b.box((0,wall-.20,0),(w,.46,.72),'wood_dark')
 for i in range(-3,4):
  b.box((i*.62,wall-.45,0),(.075,.38,.34),'wood_light')
 roof(b,w,d,wall,1.06,'hall','roof_charcoal')
 # lintel plaque
 b.box((0,wall-.73,d/2+.10),(2.8,.48,.15),'wood')

def fence(b,w,d,gate=True):
 # Rectangular estate perimeter around center. Corner posts are grounded.
 for sx in (-1,1):
  x=sx*w/2
  b.box((x,1.00,0),(.20,.13,d),'wood_dark')
  for z in np.arange(-d/2,d/2+.01,2.3):
   b.box((x,.85,z),(.28,1.35,.29),'wood_warm')
 for sz in (-1,1):
  z=sz*d/2
  for side in (-1,1):
   lo,hi=((-w/2,-3.60) if side<0 else (3.60,w/2)) if gate and sz>0 else ((-w/2,0) if side<0 else (0,w/2))
   b.box(((lo+hi)/2,1.1,z),(hi-lo,.20,.17),'wood_dark')
   for x in np.arange(lo,hi,2.3): b.box((x,.84,z),(.28,1.26,.31),'wood_warm')

specs=json.load(open(ROOT/'data'/'HWA02_manifest.json'))['placements']
architectures=[]
for i,spec in enumerate(specs):
 name=spec['id'];x,z=spec['position_xz'];w,d=spec['dimensions_wd'];kind=spec['class']
 kind='inn' if name=='RIVERSIDE_INN' else 'clinic' if name=='HERBALIST' else kind
 wall=4.55 if name=='FAMILY_MAIN_HALL' else 3.35 if kind in ('tea','manor','inn') else 3.2 if kind in ('clinic','store') else 3.06
 b=group('ARCH_'+name);b.place(x,ground(x,z)+.35,z,spec['yaw_rad']);t={'plaster':'wall_cream','plaster_pale':'wall_sand','plaster_ochre':'wall_warm','plaster_cool':'wall_cool','plaster_speck':'wall_moss'}[spec['wall_texture']]
 build_house(b,kind,w,d,wall,t,marker=i)
 architectures.append({'id':name,'kind':kind,'wall_variant':t,'x':x,'z':z,'yaw':spec['yaw_rad'],'height':wall,'dimensions':[w,d],'roof_supported':True})
# New estate fence/pavilions are required since legacy manor is hidden along with old fencing.
b=group('ARCH_FAMILY_COURTYARD_FENCE');b.place(-48,ground(-48,-44)+.35,-44)
fence(b,45,44,True)
b=group('ARCH_FAMILY_COURTYARD_GATE');b.place(-48,ground(-48,-22)+.35,-22)
gateway(b,6.4,3.85,1.9)
# A canonical gate standalone asset and five house-type variants + shrine: no placeholder boxes.
kit_specs=[('HOUSE_RURAL','house',8,7,3.06,'wall_sand'),('HOUSE_FISHERMAN','house',7.2,6.4,2.90,'wall_moss'),('TEAHOUSE','tea',11,9,3.35,'wall_warm'),('HEALER_CLINIC','clinic',8,7,3.2,'wall_cool'),('STOREHOUSE','store',9,7,3.20,'wall_cream'),('MANOR_HALL','manor',16,10,4.55,'wall_cream'),('SHRINE','shrine',6,5,2.95,'wall_warm')]
for name,kind,w,d,h,t in kit_specs:
 b=B('KIT_'+name);build_house(b,kind,w,d,h,t)
 sc=trimesh.Scene();sc.add_geometry(b.mesh(atlas),geom_name=b.name,node_name=b.name);sc.export(str(KIT/(name+'.glb')))
b=B('KIT_COURTYARD_GATE');gateway(b);sc=trimesh.Scene();sc.add_geometry(b.mesh(atlas),geom_name=b.name,node_name=b.name);sc.export(str(KIT/'COURTYARD_GATE.glb'))
# Each placement is a separate named mesh, preserving replacement and collision granularity.
sc=trimesh.Scene();out=[]
for name,b in G.items():
 if b.faces:
  m=b.mesh(atlas);sc.add_geometry(m,geom_name=name,node_name=name);out.append({'name':name,'triangles':len(m.faces),'vertices':len(m.vertices)})
sc.export(str(DIR/'HWA02_Architecture_Sprint02.glb'))
summary={'generator':'EXO_Murim_Architecture_Sprint02','architecture_count':len(architectures),'groups':out,'triangles':sum(d['triangles'] for d in out),'kit_models':len(kit_specs)+1,'texture':'textures/EXO_Murim_Architecture_InkAtlas_1536.png','source':'100% newly generated mesh and texture, historically inspired not extracted','placements':architectures,'roof_policy':'closed gables, volumetric roof, eave beams and rafter braces joined to wall headers','family_geometry_static':True,'engine_tested':False}
(DIR/'manifest_sprint02.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps({'buildings':len(architectures),'tris':summary['triangles'],'parts':len(out),'kit_models':summary['kit_models']}))
