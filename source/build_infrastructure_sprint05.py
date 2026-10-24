#!/usr/bin/env python3
"""Sprint 05 — original authored Haneul physical infrastructure.
Input: EXACT V08 world layout. Creates complete replacement of current painted
terrain visual (geometry unchanged), bridge, landing zones, thresholds and data.
No external textures, borrowed models or game character modifications.
"""
from pathlib import Path
import json, random, math, hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import trimesh
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'infrastructure_sprint05';(OUT/'previews').mkdir(parents=True,exist_ok=True);(OUT/'data').mkdir(exist_ok=True)
materials={
 'timber':'#71513C','wood_light':'#A47C51','wood_dark':'#302C2B','wood_rim':'#4C3B34',
 'bridge_plank':'#A58B69','plank_shadow':'#706452','stone':'#A8A295','stone_shadow':'#746F66',
 'flagstone':'#C2B8A2','rope':'#BE9C67','ink':'#252831','earth':'#9F896D',
 'bamboo':'#5C7551','moss':'#62745B','clay':'#C2A77B','paper':'#E4D9C6'}
N=1024;S=256;A=Image.new('RGB',(N,N));D=ImageDraw.Draw(A);rand=random.Random(5151)
for i,(name,c) in enumerate(materials.items()):
 x=(i%4)*S;y=(i//4)*S;base=tuple(bytes.fromhex(c[1:]));D.rectangle((x,y,x+255,y+255),fill=base)
 for j in range(1700):
  xx=x+rand.randrange(4,252);yy=y+rand.randrange(4,252); v=rand.randint(-18,13)
  D.point((xx,yy),fill=tuple(max(0,min(255,z+v)) for z in base))
 if name in ('bridge_plank','timber','wood_light','wood_dark','wood_rim'):
  for j in range(12):
   yy=y+9+j*21+rand.randint(-5,5);col=tuple(max(0,z-20) for z in base)
   D.arc((x+5,yy-2,x+250,yy+10),180,350,fill=col,width=1)
 if name in ('stone','stone_shadow','flagstone'):
  for j in range(22):
   xx=x+rand.randint(12,237);yy=y+rand.randint(12,237)
   D.arc((xx-9,yy-4,xx+15,yy+11),30,240,fill=tuple(max(0,z-28) for z in base),width=1)
 D.rectangle((x+2,y+2,x+253,y+253),outline='#2D2C2B',width=3)
tex=OUT/'EXO_Haneul_Infrastructure_PaintedAtlas_1024.png';A.save(tex)
M={n:i for i,n in enumerate(materials)}
def uvs(name):
 i=M[name];x=(i%4)*S;y=(i//4)*S;pad=7
 return [((x+pad)/N,1-(y+S-pad)/N),((x+S-pad)/N,1-(y+S-pad)/N),((x+S-pad)/N,1-(y+pad)/N),((x+pad)/N,1-(y+pad)/N)]
class Mesh:
 def __init__(self,name):self.name=name;self.v=[];self.f=[];self.uv=[]
 def quad(self,pts,col):
  k=len(self.v);self.v.extend(pts);self.f.extend(((k,k+1,k+2),(k,k+2,k+3)));self.uv.extend(uvs(col))
 def cube(self,center,size,color):
  x,y,z=center;w,h,d=[a/2 for a in size]
  b=[(x-w,y-h,z-d),(x+w,y-h,z-d),(x+w,y-h,z+d),(x-w,y-h,z+d)]
  t=[(x-w,y+h,z-d),(x+w,y+h,z-d),(x+w,y+h,z+d),(x-w,y+h,z+d)]
  for pts in ([b[0],b[1],t[1],t[0]],[b[1],b[2],t[2],t[1]], [b[2],b[3],t[3],t[2]],[b[3],b[0],t[0],t[3]], [t[0],t[1],t[2],t[3]],[b[3],b[2],b[1],b[0]]):self.quad(pts,color)
 def deck_segment(self,xa,xb,z,top_a,top_b,width=.0,thickness=.22,col='bridge_plank'):
  w=width or 3.1;q=[(xa,top_a,z-w/2),(xa,top_a,z+w/2),(xb,top_b,z+w/2),(xb,top_b,z-w/2)]
  bottom=[(x,y-thickness,zz) for x,y,zz in q]
  self.quad(q,col);self.quad(bottom[::-1],'wood_dark')
  for i in range(4):self.quad([q[i],bottom[i],bottom[(i+1)%4],q[(i+1)%4]],'wood_rim')
 def export(self):
  if not self.f:return None
  mesh=trimesh.Trimesh(vertices=np.asarray(self.v),faces=np.asarray(self.f),process=False)
  mesh.visual=trimesh.visual.texture.TextureVisuals(uv=np.asarray(self.uv),material=trimesh.visual.material.PBRMaterial(name='EXO_S05_Ink',baseColorTexture=A,roughnessFactor=1,metallicFactor=0,doubleSided=True))
  return mesh

def ground(x,z):
 center=66+8*math.sin((z+20)/41)+z*.045
 base=.2+.17*math.sin(x*.072+z*.013)+.17*math.cos(z*.093-x*.024)
 west=max(0,(-x-57)/55)**1.8*11.5
 nw=max(0,(-z-65)/45)*max(0,(-x-55)/65)*6
 water=-2.25*max(0,1-abs(x-center)/12)**1.35
 return base+west+nw+water
# Bridge crosses the river at z=35. Real river width there is x~68..83;
# two bank ramps connect mesh to the terrain and the elevated deck crosses water.
river_z=35.0
west_x,east_x=57,94
start_y,end_y=ground(west_x,river_z)+.13,ground(east_x,river_z)+.13
def h(x):
 if x<63:return start_y+(1.48-start_y)*(x-57)/6
 if x<=88:return 1.48
 return 1.48+(end_y-1.48)*(x-88)/6
bridge=Mesh('INFRA_WALK_PedestrianBridge')
rails=Mesh('INFRA_COLLIDE_BridgeRailings')
structure=Mesh('INFRA_DECOR_BridgeBracing')
for i in range(37):
 x=west_x+i
 bridge.deck_segment(x,x+1,river_z,h(x),h(x+1),width=3.1,col='bridge_plank' if i%4 else 'wood_light')
 for zz in (river_z-1.57,river_z+1.57):
  structure.cube((x+.48,(h(x)+h(x+1))/2-.19,zz),(.92,.24,.28),'wood_dark')
for x in range(62,89,4):
 for z in (river_z-1.77,river_z+1.77):
  top=h(x)+1.22
  structure.cube((x,(top-2.6)/2,z),(.32,top+2.6,.34),'timber')
  rails.cube((x,h(x)+.74,z),(.27,1.35,.30),'wood_rim')
for a,b in zip(range(63,88,4),range(67,92,4)):
 a=max(a,63);b=min(b,88)
 for z in (river_z-1.77,river_z+1.77):
  rails.cube(((a+b)/2,h((a+b)/2)+1.16,z),(b-a+.27,.19,.24),'timber')
  rails.cube(((a+b)/2,h((a+b)/2)+.52,z),(b-a+.27,.12,.20),'wood_light')
# solid landing shoulders, flush with terrain, plus ferry mooring posts.
land=Mesh('INFRA_WALK_Landings')
for x in (56.5,94.5):
 top=ground(x,river_z)+.095
 land.cube((x,top-.06,river_z),(2.5,.12,4.3),'flagstone')
# Ferry landing (not a teleport / not a travel system) at preexisting dock z=-9.
for x in (47,88):
 zz=-9.0;top=ground(x,zz)+.20
 land.cube((x,top-.12,zz),(3.6,.24,3.5),'bridge_plank')
 for dz in (-1.35,1.35):
  structure.cube((x,top+.32,zz+dz),(.18,.75,.19),'wood_dark')
# threshold steps outside all fifteen entries; never modify or penetrate doorway.
arch=json.loads((ROOT/'data/HWA02_manifest.json').read_text())['placements']
thresholds=Mesh('INFRA_WALK_Thresholds')
entries=[]
for item in arch:
 x,z=item['position_xz'];w,d=item['dimensions_wd'];yaw=item['yaw_rad'];fx,fz=math.sin(yaw),math.cos(yaw)
 door=(x+fx*(d/2+.98),z+fz*(d/2+.98))
 for ix in range(3):
  distance=d/2+1.58+ix*.60
  xx=x+fx*distance;zz=z+fz*distance
  # original architecture has stone steps at entrance; ground-level approach begins
  # just beyond its farthest threshold, avoiding overlap with front steps.
  yy=ground(xx,zz)+.07
  wid=1.58+ix*.12
  # rotating a flat stone quadrilateral around Y to follow the door orientation
  side=(math.cos(yaw),-math.sin(yaw))
  dx=side[0]*wid*.5;dz=side[1]*wid*.5
  ddx=fx*.28;ddz=fz*.28
  thresholds.quad([(xx-dx-ddx,yy,zz-dz-ddz),(xx+dx-ddx,yy,zz+dz-ddz), (xx+dx+ddx,yy,zz+dz+ddz),(xx-dx+ddx,yy,zz-dz+ddz)],'flagstone' if ix!=1 else 'stone')
 entries.append({'id':item['id'],'door_center':[round(door[0],3),round(ground(*door),3),round(door[1],3)],'outward_normal':[round(fx,5),0,round(fz,5)],'trigger_radius_m':1.35,'status':'reserved_no_interior_scene'})
# bank protection: sparse rocks on riverbanks, no fake colliders overlapping walking ramp.
banks=Mesh('INFRA_DECOR_BankProtection')
for x in [57,59,61,88,90,92]:
 for dz in [-3.2,3.2]:
  zz=river_z+dz
  yy=ground(x,zz)
  banks.cube((x,yy+.08,zz),(1.25,.16,.53),'stone_shadow' if x%2 else 'stone')
# symbolic structural bridge signs at both ends, visually legible but noninteractable.
for x in (55.5,95.5):
 yy=ground(x,river_z)
 structure.cube((x,yy+1.15,river_z-2.6),(.20,2.3,.23),'timber')
 structure.cube((x,yy+2.05,river_z-2.6),(.98,.43,.17),'paper')
structure.cube((57.0,ground(57,35)+.04,river_z),(1.6,.08,3.8),'stone')
mods=[bridge,rails,structure,land,thresholds,banks];scene=trimesh.Scene();stats={}
for obj in mods:
 g=obj.export();scene.add_geometry(g,geom_name=obj.name,node_name=obj.name);stats[obj.name]=len(g.faces)
glb=OUT/'HWA02_Infraestrutura_S05.glb';scene.export(str(glb))
# Paint the bridge-approach trails into a NEW full terrain skin. This avoids
# floating 'road strips' and deliberately preserves original terrain vertex positions.
base=Image.open(ROOT/'terrain_sprint04/EXO_Haneul_Ground_Polished_S04_2048.png').convert('RGB')
w,h0=base.size; msk=Image.new('L',(w,h0),0);d=ImageDraw.Draw(msk)
def xy(x,z):return (round((x+118)/236*(w-1)),round((z+112)/224*(h0-1)))
roads=[[(39,38),(45,40),(52,36),(57,35)],[(94,35),(99,34),(108,25)],[(39,-13),(44,-9),(47,-9)],[(89,-9),(98,-6)]]
for pts in roads:
 points=[xy(*p) for p in pts]
 d.line(points,fill=220,width=20,joint='curve')
 for p in points:d.ellipse((p[0]-10,p[1]-10,p[0]+10,p[1]+10),fill=220)
msk=msk.filter(ImageFilter.GaussianBlur(11))
mask=np.asarray(msk,dtype=np.float32)[:,:,None]/255
old=np.asarray(base,dtype=np.float32)
# muted ochre, not neon or visual tile strips
new=np.uint8(np.clip(old*(1-mask*.73)+np.asarray([150.,126.,98.])[None,None,:]*(mask*.73),0,255))
paint=Image.fromarray(new,'RGB');src_paint=OUT/'EXO_Haneul_Ground_S05_BridgeApproaches_2048.png';paint.save(src_paint,optimize=True)
# Keep original mesh/UVs byte-for-byte identical; only replace UV texture.
base_scene=trimesh.load(ROOT/'terrain_sprint04/HWA02_Terrain_Murim_Polished_S04.glb',force='scene',process=False)
G=base_scene.geometry['Terrain_InkGround'].copy()
G.visual=trimesh.visual.texture.TextureVisuals(uv=G.visual.uv.copy(),material=trimesh.visual.material.PBRMaterial(name='EXO_Haneul_S05_Ground',baseColorTexture=paint,roughnessFactor=1,metallicFactor=0,doubleSided=True))
newscene=trimesh.Scene();newscene.add_geometry(G,geom_name='Terrain_S05_InkGround',node_name='Terrain_S05_InkGround')
newscene.export(str(OUT/'HWA02_Terrain_S05.glb'))
manifest={'sprint':'05','bridge':{'name':'Ponte do Vau Pequeno','z':35,'west_x':57,'east_x':94,'width_m':3.1,'end_heights_y':[round(start_y,3),round(end_y,3)],'max_deck_y':1.48,'crossing_real_geometry':True,'bridge_end_reserved_region':True},'terrain_modified':'diffuse texture only; identical vertices and triangle indices','buildings_moved':False,'interiors_functional':False,'npc_ai_implemented':False,'traversal_purpose':'pedestrian bridge; ferry docks remain separate transport point','entrance_anchors':entries,'geometry_faces':stats,'provenance':'original generated model and handpainted texture, no third-party assets','godot_qa':'not run when generated'}
(OUT/'data/manifest_sprint05.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('generated',glb,'size',glb.stat().st_size,'triangles',stats,'entrances',len(entries))
