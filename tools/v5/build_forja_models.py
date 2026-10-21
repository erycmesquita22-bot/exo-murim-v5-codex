#!/usr/bin/env python3
"""Reprodutor dos modelos voxel EXO Forja 03. Apenas meshes originais novos.
Uso: python tools/build_assets_v3.py. GLB exportado com unidades metro/Y-up.
"""
import json, math, collections
from pathlib import Path
import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'models/forja_v3';OUT.mkdir(parents=True,exist_ok=True)
COLORS={
 'wood':(112,67,41,255), 'wood_light':(170,112,66,255),'wood_dark':(70,47,38,255),
 'stone':(119,122,120,255),'stone_light':(179,178,162,255),'stone_dark':(79,85,86,255),
 'roof':(59,76,82,255), 'roof_red':(153,66,55,255),'roof_jade':(51,111,91,255),
 'plaster':(214,201,168,255), 'plaster_dark':(179,164,127,255),
 'cloth':(169,56,45,255), 'cloth_gold':(220,154,65,255),'cloth_blue':(54,104,145,255),
 'grass':(77,119,56,255),'leaf':(54,100,54,255), 'leaf_light':(101,143,56,255),
 'soil':(89,60,43,255), 'water':(40,112,158,255),'iron':(58,62,65,255),
 'gold':(188,141,57,255), 'paper':(226,207,157,255), 'straw':(177,145,70,255)
}
manifest=[]
class Asset:
 def __init__(self,name,category,usage):
  self.name=name;self.category=category;self.usage=usage;self.groups=collections.defaultdict(list)
 def b(self,x,y,z,w,h,d,mat):
  assert w>0 and h>0 and d>0,(self.name,x,y,z,w,h,d)
  mesh=trimesh.creation.box((w,h,d));mesh.apply_translation([x,y+h/2,z]);self.groups[mat].append(mesh)
 def post(self,x,z,h,mat='wood',width=.22,y=0):self.b(x,y,z,width,h,width,mat)
 def slab(self,w,d,thick=.22,mat='stone',y=0):self.b(0,y,0,w,thick,d,mat)
 def stair(self,w,d,y,z,mat='stone'):
  for k in range(3):self.b(0,y+k*.16,z-k*.28,w,.16,d/3,mat)
 def roof(self,w,d,level,mat='roof',step=.42):
  # voxel stepped oriental roof with raised ridge and extended curved eaves
  count=4
  for i in range(count):
   z=(d/2+.22)-i*(d/2+.22)/count
   rw=w+(.55 if i==0 else .2)
   for sign in (-1,1):
    self.b(0,level+i*step/2,sign*z,rw,.18,max(.45,(d/2+.22)/count+.16),mat)
  self.b(0,level+count*step/2,0,w+.18,.3,.42,'wood_dark')
  for x in (-w/2,w/2):
   self.b(x,level+.15,0,.27,.36,d+.8,'wood_dark')
 def panel(self,w,h,d,mat='plaster',y=0,z=0): self.b(0,y,z,w,h,d,mat)
 def gateway(self,span,depth=1.1,h=4.4,stone=False):
  wall='stone' if stone else 'wood';detail='stone_dark' if stone else 'wood_dark'
  for s in (-1,1):
   px=s*(span/2-.46)
   self.b(px,0,0,.9,h,.9,wall)
   self.b(px,.15,0,1.1,.4,1.1,detail)
   self.b(px,h-.3,0,1.25,.32,1.1,detail)
  self.b(0,h-.2,0,span,.32,1.2,detail)
  self.roof(span+1.1,depth+1.0,h+.15,'roof_jade' if stone else 'roof_red',.43)
  self.b(0,h-.85,.68,span-2.4,.60,.08,'cloth')
 def hall(self,w,d=7,levels=1,roof='roof_jade',doors=True):
  base_h=2.95*levels
  self.b(0,0,0,w+.8,.5,d+.8,'stone')
  for yy in range(levels):
   y=.50+yy*2.95
   for xx in (-w/2+.35,w/2-.35):
    for zz in (-d/2+.35,d/2-.35):self.b(xx,y,zz,.38,2.9,.38,'wood_dark')
   self.b(0,y,-d/2,w-.1,2.6,.24,'plaster')
   # faca frontal com vazio funcional no vao da porta central
   self.b(-w/4-.55,y,d/2,w/2-1.15,2.6,.24,'plaster')
   self.b(w/4+.55,y,d/2,w/2-1.15,2.6,.24,'plaster')
   self.b(0,y+2.08,d/2,2.25,.52,.24,'wood_light')
   for side in (-1,1):self.b(side*w/2,y,0,.24,2.6,d-.3,'plaster')
   for xx in (-w/2+1,w/2-1):
    self.b(xx,y+.75,d/2+.15,.85,1.05,.10,'wood_dark')
    self.b(xx,y+.82,d/2+.20,.48,.84,.12,'paper')
   if yy<levels-1: self.b(0,y+2.6,0,w+.4,.35,d+.4,'wood')
  self.roof(w+1,d+1,.5+base_h,roof,.58)
  self.stair(3,1,.03,d/2+1,'stone_light')
 def export(self):
  sc=trimesh.Scene();total=0;parts=0
  for mat,meshes in self.groups.items():
   parts+=len(meshes);joined=trimesh.util.concatenate(meshes);joined.unmerge_vertices()
   joined.visual=trimesh.visual.TextureVisuals(material=PBRMaterial(name=mat,baseColorFactor=np.array(COLORS[mat],dtype=float)/255., metallicFactor=0., roughnessFactor=.9))
   sc.add_geometry(joined,geom_name=mat)
   total+=len(joined.faces)
  path=OUT/(self.name+'.glb');data=sc.export(file_type='glb',include_normals=True);path.write_bytes(data)
  minb,maxb=sc.bounds
  manifest.append({'id':self.name,'file':f'models/forja_v3/{self.name}.glb','category':self.category,'usage':self.usage,'collision':'none','bounds_m':[[round(float(v),4) for v in minb],[round(float(v),4) for v in maxb]],'mesh_parts':parts,'triangles':int(total),'materials':list(self.groups)})
  return self

def make(name,cat,usage):return Asset(name,cat,usage)

for mat in ['stone','wood','battlement']:
 a=make('city_wall_'+mat+'_2m','fortification',f'wall segment 2m, {mat}')
 if mat=='battlement':
  a.b(0,0,0,2,3.15,.52,'stone');a.b(0,3.1,0,2,.24,.72,'stone_dark')
  for x in (-.72,.0,.72):a.b(x,3.33,0,.38,.65,.58,'stone')
 else:
  a.b(0,0,0,2,3.0,.5,'stone' if mat=='stone' else 'wood')
  a.b(0,2.95,0,2.22,.35,.62,'stone_dark' if mat=='stone' else 'wood_dark')
  for x in (-.83,.83):a.post(x,0,3.25,'stone_light' if mat=='stone' else 'wood_dark',.18)
 a.export()
for mat in ['stone','wood']:
 a=make('wall_corner_'+mat,'fortification','corner infill for rectangular wall');m='stone' if mat=='stone' else 'wood'
 a.b(0,0,0,1.95,3,1.95,m);a.b(0,3,0,2.3,.34,2.3,'stone_dark' if mat=='stone' else 'wood_dark');a.export()
 a=make('gate_'+mat+'_6m','fortification',f'6m portal for {mat} walls with >4m clear opening')
 a.gateway(6.0,1.3,4.6,mat=='stone');a.export()
 a=make('watchtower_'+mat+'_4m','fortification','4m defensive watchtower with raised roof')
 m='stone' if mat=='stone' else 'wood'
 a.b(0,0,0,4,3.8,4,m)
 for x in (-1.6,1.6):
  for z in (-1.6,1.6):a.post(x,z,5.2,'wood_dark' if mat=='wood' else 'stone_dark',.4)
 a.b(0,3.85,0,4.7,.25,4.7,'wood_light')
 for x in (-1.65,1.65):a.b(x,4.3,0,.18,1,4,'wood_dark')
 a.roof(4.8,4.8,5.2,'roof_red' if mat=='wood' else 'roof_jade',.45);a.export()
for name,roof,cat in [('sect_hall_8m','roof_jade','civic'),('temple_hall_8m','roof_red','civic'),('guild_hall_8m','roof','civic')]:
 a=make(name,cat,'independent 8m hall with entry opening and roof');a.hall(8,7,1,roof)
 for x in (-3,3):a.b(x,0,4.3,.35,3,.35,'wood_dark')
 if name=='sect_hall_8m':
  for x in (-3.75,3.75):a.b(x,1.3,4.4,.28,1.5,.12,'cloth')
 if name=='temple_hall_8m':a.b(0,3.0,4.42,1.5,.55,.15,'gold')
 a.export()
for name in ('open_pavilion_6m','training_pavilion_6m'):
 a=make(name,'civic','open sided 6m pavilion')
 a.b(0,0,0,6,.35,6,'stone')
 for x in (-2.6,2.6):
  for z in (-2.6,2.6):a.post(x,z,3.4,'wood_dark',.35)
 a.roof(6,6,3.4,'roof_jade' if name=='open_pavilion_6m' else 'roof_red',.52)
 if name=='training_pavilion_6m':
  for x in (-1.55,1.55):a.b(x,0,0,.32,2,.32,'wood')
 a.export()

a=make('martial_training_yard_6m','civic','6m martial practice court, unobstructed center')
a.b(0,0,0,6,.16,6,'soil')
for x in (-2.7,2.7):
 for z in (-2.7,2.7):a.post(x,z,.55,'stone',.18)
a.export()
a=make('training_dummy','civic','wooden martial practice dummy')
a.post(0,0,1.9,'wood_dark',.27);a.post(0,0,.3,'stone',.6)
for x in (-.65,.65):a.b(x,1.35,.05,1.4,.18,.16,'wood')
a.export()
a=make('weapons_training_rack','civic','training rack with upright practice weapons')
for x in (-1,1):a.post(x,0,1.7,'wood_dark')
a.b(0,.45,0,2.4,.20,.4,'wood')
for x in (-.7,-.2,.3,.8):a.post(x,.05,1.82,'wood_light',.08)
a.export()
a=make('dojo_bell','civic','school gong assembly')
for x in (-1,1):a.post(x,0,2.5,'wood_dark')
a.b(0,2.35,0,2.35,.25,.35,'wood_dark')
a.b(0,.8,0,1.1,1.35,.18,'gold');a.export()
a=make('temple_altar','civic','incense altar with candles')
a.b(0,0,0,2.3,1.05,1.2,'stone_dark');a.b(0,1.05,0,2.5,.17,1.3,'stone_light')
for x in (-.6,0,.6):a.post(x,0,1.6,'gold',.06)
a.export()
a=make('temple_stela','civic','carved memorial stone pillar')
a.b(0,0,0,1.6,.45,1.05,'stone_dark');a.b(0,.45,0,1.22,2.3,.5,'stone_light');a.b(0,2.8,0,1.48,.3,.7,'roof_red');a.export()
a=make('clan_banner_pair','civic','two red lineage standards left and right of entrance')
for x in (-1.45,1.45):
 a.post(x,0,3.8,'wood_dark',.11);a.b(x,2.0,.04,.80,1.2,.09,'cloth');a.b(x,3.22,.05,.85,.18,.14,'gold')
a.export()
a=make('patrol_brazier','street','fire bowl on stone pedestal for guards')
a.b(0,0,0,.7,1.0,.7,'stone');a.b(0,.93,0,1.18,.26,1.18,'iron');a.b(0,1.18,0,.55,.38,.55,'cloth_gold');a.export()
a=make('hanging_wall_torch','street','compact bracket torch for walls')
a.b(0,0,0,.65,.16,.8,'wood_dark');a.post(0,.3,.85,'iron',.13);a.b(0,.82,.3,.28,.3,.28,'cloth_gold');a.export()

a=make('granary_6m','farm','raised granary warehouse with airy roof')
a.hall(6,5,1,'roof_red')
for x in (-2,2):a.b(x,0,3.6,1,1.4,.85,'straw')
a.export()
a=make('grain_silo','farm','granary round effect approximated voxel structure')
a.b(0,0,0,2.8,3.1,2.8,'wood')
for x in (-1.6,1.6):a.post(x,0,3.6,'wood_dark',.2)
a.roof(3.5,3.5,3.2,'roof_red',.3);a.export()
a=make('rice_field_4m','farm','irrigated stepped rice plot')
a.b(0,0,0,4,.2,4,'soil');a.b(0,.21,0,3.65,.07,3.65,'water')
for x in (-1.4,-.6,.2,1.0):
 for z in (-1.35,-.55,.25,1.05):a.b(x,.24,z,.14,.46,.12,'grass')
a.export()
a=make('vegetable_field_4m','farm','four vegetable crop rows')
a.b(0,0,0,4,.18,4,'soil')
for x in (-1.5,-.5,.5,1.5):
 a.b(x,.19,0,.56,.16,3.65,'straw')
 for z in (-1.45,-.65,.15,.95):a.b(x,.38,z,.36,.38,.36,'leaf_light')
a.export()
a=make('irrigation_channel_2m','farm','two meter canal trough')
for x in (-.95,.95):a.b(x,0,0,.22,.36,2,'stone')
a.b(0,0,0,1.72,.12,2,'water');a.export()
a=make('field_fence_2m','farm','low fence separating tilled plots')
for x in (-.87,.87):a.post(x,0,1.15,'wood_dark',.15)
for y in (.44,.87):a.b(0,y,0,2,.16,.13,'wood_light')
a.export()
a=make('farm_gate_4m','farm','farm entry and hanging gate')
for x in (-2,2):a.post(x,0,3.0,'wood_dark',.2)
a.b(0,2.7,0,4,.2,.28,'wood');a.export()
a=make('water_trough','farm','wood trough for livestock')
a.b(0,0,0,2.3,.55,1.15,'wood_dark');a.b(0,.56,0,1.85,.08,.8,'water');a.export()
a=make('hay_cart','farm','small hay cart with box and stylized wheels')
a.b(0,.5,0,2.2,.8,1.4,'wood')
a.b(0,1.28,0,2,.85,1.18,'straw')
for x in (-.92,.92):
 for z in (-.74,.74):a.b(x,0,z,.54,.74,.14,'wood_dark')
a.export()
a=make('village_stone_path_2m','street','stone path tile, no implied route creation')
a.b(0,0,0,2,.11,2,'soil')
for x in (-.52,.43):
 for z in (-.6,.48):a.b(x,.12,z,.73,.10,.73,'stone')
a.export()
a=make('village_wood_path_2m','street','wood plank footpath tile')
for z in (-.75,-.25,.25,.75):a.b(0,0,z,2,.16,.42,'wood_light')
for x in (-.85,.85):a.b(x,-.14,0,.14,.15,2,'wood_dark')
a.export()
a=make('street_signpost','street','oriental village directional post with 2 signboards')
a.post(0,0,3.0,'wood_dark',.26)
a.b(.35,2.25,0,1.55,.32,.15,'wood_light');a.b(-.4,1.63,0,1.38,.32,.15,'wood_light');a.export()
a=make('village_notice_board','street','notice board for contract system')
for x in (-1.15,1.15):a.post(x,0,2.8,'wood_dark')
a.b(0,1.05,0,2.6,1.65,.19,'wood');a.b(0,1.25,.11,2.25,1.14,.05,'paper')
a.roof(2.7,1.1,2.82,'roof',.25);a.export()
a=make('street_lamp_post','street','lantern with wooden post')
a.post(0,0,3.1,'wood_dark',.2);a.b(.38,2.96,0,.95,.2,.16,'wood')
a.b(.78,2.1,0,.58,.66,.52,'paper');a.b(.78,2.81,0,.68,.21,.65,'roof_red');a.export()
a=make('stone_lion_statue','street','voxel guardian lion stylization')
a.b(0,0,0,1.2,.4,1.2,'stone_dark');a.b(0,.38,0,.8,1.25,.8,'stone_light')
a.b(0,1.55,.3,.9,.78,.78,'stone');a.b(-.3,1.82,.7,.11,.13,.09,'stone_dark');a.b(.3,1.82,.7,.11,.13,.09,'stone_dark');a.export()
a=make('wood_footbridge_4m','street','short footbridge for shallow stream')
a.b(0,.6,0,4,.28,2.3,'wood')
for x in (-1.85,1.85):
 for z in (-.95,.95):a.post(x,z,1.65,'wood_dark',.13)
for z in (-1.05,1.05):a.b(0,1.55,z,4,.15,.13,'wood_dark')
a.export()
a=make('stone_footbridge_4m','street','stone creek footbridge')
a.b(0,.6,0,4.1,.3,2.3,'stone');a.b(0,.0,-.9,4.1,.6,.4,'stone_dark')
a.b(0,0,.9,4.1,.6,.4,'stone_dark')
for z in (-1.12,1.12):a.b(0,1.05,z,4,.55,.22,'stone')
a.export()

for name,usage in [('herbalist_garden_box','medicine plants'),('tea_garden_bush','tea bushes')]:
 a=make(name,'nature_detail',usage);a.b(0,0,0,2,.42,1.2,'wood_dark')
 for x in (-.62,0,.62):
  if name=='tea_garden_bush':
   a.b(x,.43,0,.58,.28,.42,'leaf_light')
   a.b(x,.72,0,.30,.18,.26,'leaf')
  else:
   a.b(x,.43,0,.35,.7,.32,'leaf')
   a.post(x,0,.22,'wood_light',.06,y=.98)
 a.export()

# source catalog is preserved except additive v3 entries/version.
catalog_path=ROOT/'forja/catalog_v3.json';doc=json.loads(catalog_path.read_text())
doc['assets']=[item for item in doc['assets'] if not str(item['file']).startswith('models/forja_v3/')]
assert len(doc['assets'])==121 and not any(x['id'] in {v['id'] for v in manifest} for x in doc['assets'])
for item in manifest:
 doc['assets'].append({'id':item['id'],'family':item['category'],'file':item['file'],
 'bounds':item['bounds_m'],'triangles':item['triangles'],'materials':item['materials'],
 'collision':item['collision'],'sockets':[],'description':item['usage'],
 'origin':'Forja 03 original voxel mesh; centered; Y up; meter units'})
doc['version']='3.0'
catalog_path.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n')
(ROOT/'docs/v5/forja-generated-catalog.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('GENERATED',len(manifest),'TOTAL CATALOG',len(doc['assets']),'TRIANGLES',sum(v['triangles'] for v in manifest),'BYTES',sum((OUT/(v['id']+'.glb')).stat().st_size for v in manifest))
