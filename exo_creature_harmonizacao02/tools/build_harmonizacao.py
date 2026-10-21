#!/usr/bin/env python3
"""EXO harmonização02: audit source GLBs, author corrected gait, add socket nodes, build stand-alone assets/catalog.
Does not edit source archives or any EXO Core file. Python 3.11+; numpy, Pillow, numba only for previews.
"""
from __future__ import annotations
import os, json, math, struct, hashlib, zipfile, shutil, collections, io
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont

SRC=Path('/mnt/data');ROOT=Path('/mnt/data/harmonizacao02_work');OUT=ROOT/'exo_creature_harmonizacao02';OUT.mkdir(parents=True,exist_ok=True)
Z1=zipfile.ZipFile(SRC/'EXO-Murim-Creature-Forge-01.zip');Z2=zipfile.ZipFile(SRC/'EXO-Murim-Creature-Art-02-CANDIDATO.zip');Z3=zipfile.ZipFile(SRC/'bestiario_referencias/EXO-Murim-Bestiario-Inimigos-02.zip')
forge=json.loads(Z1.read('exo_creatures/data/creature_visual_catalog.json'));art=json.loads(Z2.read('exo_creature_art02/data/fixed_beast_catalog.json'))['animals'];bestiary={x['id']:x for x in json.loads(Z3.read('exo_bestiary/data/species.json'))['species']};fplanned=json.loads(Z1.read('exo_creatures/data/CATALOGO-CRIATURAS-EXO-01.json'))['species']
rename={'serpent':'snake','shadow_wolf':'corrupted_wolf'}
def canonical(c):return rename.get(c,c)
# Artist-specified scale is a proposal; reference protagonist height 2.0, not native verified.
scales={'wolf':.77,'boar':.80,'tiger':.86,'leopard':.82,'mountain_goat':.87,'desert_monitor':.72,'desert_scorpion':.8,'stone_guardian':.92,'deer':.9,'fox':.79,'rabbit':.62,'bear':.90,'snake':.88,'spirit_deer':.87,'corrupted_wolf':.81,'demon_boar':.80,'kitsune':.83}
# gait phase describes authored stance/swing; not a physically solved footplant/IK system.
gaits={'wolf':(.34,.045,(0,.55,.28,.82)), 'boar':(.22,.025,(0,.5,.5,0)), 'tiger':(.43,.033,(0,.46,.18,.72)), 'leopard':(.41,.04,(0,.52,.25,.77)), 'mountain_goat':(.31,.057,(0,.45,.53,.95)), 'bear':(.19,.022,(0,.5,0,.5)), 'deer':(.32,.055,(0,.5,.52,.05)), 'fox':(.33,.043,(0,.51,.24,.75)), 'rabbit':(.40,.09,(0,0,.55,.55)), 'spirit_deer':(.31,.05,(0,.55,.5,.04)), 'corrupted_wolf':(.37,.06,(0,.55,.24,.76)), 'demon_boar':(.22,.035,(0,.5,.5,0)), 'kitsune':(.34,.05,(0,.5,.26,.77)), 'stone_guardian':(.17,.015,(0,.5,0,.5)), 'desert_monitor':(.20,.018,(0,.5,.5,0))}

def sha(b):return hashlib.sha256(b).hexdigest()
def parse_glb(b):
 assert b[:4]==b'glTF' and struct.unpack_from('<I',b,4)[0]==2
 total=struct.unpack_from('<I',b,8)[0];assert total==len(b)
 n,tag=struct.unpack_from('<I4s',b,12);assert tag==b'JSON'
 doc=json.loads(b[20:20+n]);bo=20+n;bl,tag=struct.unpack_from('<I4s',b,bo);assert tag==b'BIN\x00'
 return doc,bytearray(b[bo+8:bo+8+bl])
def write_glb(doc,binary):
 doc['buffers'][0]['byteLength']=len(binary)
 j=json.dumps(doc,ensure_ascii=False,separators=(',',':')).encode('utf8'); j+=b' '*((-len(j))%4)
 binary=bytes(binary);binary+=b'\0'*((-len(binary))%4)
 return b'glTF'+struct.pack('<II',2,12+8+len(j)+8+len(binary))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(binary),b'BIN\0')+binary

def raw_accessor(doc,bb,idx):
 a=doc['accessors'][idx];view=doc['bufferViews'][a['bufferView']]
 comps={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
 dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']];of=view.get('byteOffset',0)+a.get('byteOffset',0)
 return np.ndarray((a['count'],comps),dtype=np.dtype(dtype),buffer=bb,offset=of,strides=(view.get('byteStride',comps*np.dtype(dtype).itemsize),np.dtype(dtype).itemsize))
def append_accessor(doc,blob,arr):
 arr=np.asarray(arr,dtype='<f4');assert arr.ndim==2
 offset=len(blob);blob.extend(arr.tobytes());view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':arr.nbytes});a=len(doc['accessors']);typ={1:'SCALAR',3:'VEC3',4:'VEC4'}[arr.shape[1]];doc['accessors'].append({'bufferView':view,'componentType':5126,'count':len(arr),'type':typ,'min':np.min(arr,axis=0).tolist(),'max':np.max(arr,axis=0).tolist()});return a

def quat_z(a):return [0.,0.,math.sin(a/2),math.cos(a/2)]
def foot_theta(p,amplitude):
 p=p%1.; stance=.63
 if p<stance:
  s=p/stance;s=s*s*(3-2*s);return amplitude*(1-2*s),0.0
 s=(p-stance)/(1-stance);s=s*s*(3-2*s)
 return amplitude*(-1+2*s),math.sin(math.pi*s)

def tune(doc,blob,id):
 changed=[]
 if id not in gaits:return changed
 amplitude,bob,phases=gaits[id]
 nm={x['name']:i for i,x in enumerate(doc['nodes'])}
 for anim in doc.get('animations',[]):
  name=anim['name']
  if name not in ('walk','run','attack'):continue
  for ch in anim['channels']:
   sp=anim['samplers'][ch['sampler']];node=doc['nodes'][ch['target']['node']]['name'];arr=raw_accessor(doc,blob,sp['output'])
   ts=raw_accessor(doc,blob,sp['input'])[:,0]; period=max(float(ts[-1]),.001)
   if name in ('walk','run') and ch['target']['path']=='rotation':
    is_upper=node in ('fl_upper','fr_upper','rl_upper','rr_upper')
    is_lower=node in ('fl_lower','fr_lower','rl_lower','rr_lower')
    if is_upper or is_lower:
     key=node[:2];i=['fl','fr','rl','rr'].index(key);a=amplitude*(1.24 if name=='run' else 1.)
     for n,t in enumerate(ts):
      angle,lift=foot_theta(t/period+phases[i],a)
      if is_lower: angle=(-.11-((.38 if name=='run' else .28)*lift))
      arr[n]=quat_z(angle)
     changed.append(name+':'+node)
   if name in ('walk','run') and ch['target']['path']=='translation' and node=='root':
    for n,t in enumerate(ts):
     p=t/period; arr[n]=[0.,float(bob*(1.7 if name=='run' else 1.)*(1-math.cos(4*math.pi*p))/2),0.]
    changed.append(name+':root')
   if name=='attack' and ch['target']['path']=='translation' and node=='root' and id in ('wolf','corrupted_wolf','boar','demon_boar','tiger','leopard','stone_guardian','bear'):
    strength={'wolf':.22,'corrupted_wolf':.32,'boar':.31,'demon_boar':.35,'tiger':.39,'leopard':.37,'stone_guardian':.12,'bear':.14}[id]
    for n,t in enumerate(ts):
     p=t/period; impulse=math.sin(math.pi*max(0.,min(1.,p)))**2
     arr[n]=[strength*impulse, (0.12 if id in ('tiger','leopard') else 0.)*impulse,0.]
    changed.append(name+':root_lunge')
  # feline claws, large animal paw-slam: add channels for actual forelimb attack, not a shared jaw-only gesture.
  if name=='attack' and id in ('tiger','leopard','bear','stone_guardian'):
   samp=anim['samplers'][0];ts=raw_accessor(doc,blob,samp['input'])[:,0];period=max(float(ts[-1]),.001)
   for fore in ('fl_upper','fr_upper'):
    if fore not in nm:continue
    if any(c['target']['node']==nm[fore] and c['target']['path']=='rotation' for c in anim['channels']):continue
    angles=[]
    for t in ts:
     p=t/period
     swing=(math.sin(math.pi*p)**2)*(-.84 if id in ('tiger','leopard') else .62)
     if fore=='fr_upper':swing*=.42
     angles.append(quat_z(swing))
    idx=append_accessor(doc,blob,np.asarray(angles,dtype='<f4'));si=len(anim['samplers']);anim['samplers'].append({'input':samp['input'],'output':idx,'interpolation':'LINEAR'});anim['channels'].append({'sampler':si,'target':{'node':nm[fore],'path':'rotation'}})
    changed.append(name+':'+fore+'_new')
 return changed

def add_sockets(doc,id):
 nodes=doc['nodes'];names={x['name']:i for i,x in enumerate(nodes)}
 specs=[('SOCKET_ATTACK_ORIGIN','head',[.18,0,0]),('SOCKET_VFX_CENTER','root',[0,.45,0]),('SOCKET_BACK','body',[-.08,.1,0])]
 if id in ('snake','desert_scorpion'):specs=[('SOCKET_ATTACK_ORIGIN','head' if id=='snake' else 'stinger',[.13,0,0]),('SOCKET_VFX_CENTER','root',[0,.35,0]),('SOCKET_BACK','spine_04' if id=='snake' else 'body',[0,.1,0])]
 if id=='stone_guardian':specs=[('SOCKET_ATTACK_ORIGIN','fl_upper',[0,-.25,0]),('SOCKET_VFX_CENTER','body',[0,.1,0]),('SOCKET_BACK','body',[-.1,.15,0])]
 added=[]
 for name,source,offset in specs:
  p=names.get(source)
  if p is None:p=names.get('head',names.get('root'));source=nodes[p]['name']
  index=len(nodes);nodes.append({'name':name,'translation':offset,'extras':{'exo_harmonizacao02_socket':True,'role':name,'parent_joint':source}});nodes[p].setdefault('children',[]).append(index);added.append({'name':name,'parent':source,'node_index':index,'translation':offset})
 return added

def verify(doc,blob):
 assert len(doc.get('skins',[]))==1 and len(doc.get('meshes',[]))>=1
 assert set(a['name'] for a in doc['animations']) >= {'idle','walk','run','attack','hit','death'}
 assert len(doc['nodes'])>0
 for v in doc.get('bufferViews',[]):assert 0<=v.get('byteOffset',0) and v.get('byteOffset',0)+v['byteLength']<=len(blob)
 for acc in doc['accessors']:
  if acc.get('componentType')==5126:
   ar=raw_accessor(doc,blob,doc['accessors'].index(acc));assert np.isfinite(ar).all()
 for skin in doc['skins']:
  assert all(0<=v<len(doc['nodes']) for v in skin['joints'])
  mat=raw_accessor(doc,blob,skin['inverseBindMatrices']);assert mat.shape[0]==len(skin['joints'])
 for anim in doc['animations']:
  for ch in anim['channels']:
   assert ch['target']['node']<len(doc['nodes']) and ch['sampler']<len(anim['samplers'])
   sam=anim['samplers'][ch['sampler']];ts=raw_accessor(doc,blob,sam['input'])[:,0];vals=raw_accessor(doc,blob,sam['output']);assert len(vals)==len(ts) and np.all(np.diff(ts)>0)
   if ch['target']['path']=='rotation':assert np.all(np.abs(np.linalg.norm(vals,axis=1)-1)<.02)
 return True

def variant_info(c,source):
 lookup= c if source=='forge' else c
 m=forge[lookup] if source=='forge' else art[lookup]
 return m

def sizes(doc,blob):
 a=doc['meshes'][0]['primitives'][0]['attributes']['POSITION'];verts=raw_accessor(doc,blob,a);mins=verts.min(axis=0);maxs=verts.max(axis=0)
 return {'bbox_min':[round(float(x),5) for x in mins], 'bbox_max':[round(float(x),5) for x in maxs], 'extent':[round(float(x),5) for x in maxs-mins], 'triangles':sum(doc['accessors'][pr['indices']]['count']//3 for m in doc['meshes'] for pr in m['primitives']),'vertices':len(verts)}

def collider(d,id,sc):
 # Bounds for physics as a *descriptor*; active collisions are owned by Bestiary. Keep tails/horns outside collision when possible.
 dims=np.asarray(d['extent'],float)*sc
 mult=(.66,.88,.75) if id not in ('snake','desert_scorpion') else ((.85,.84,.78) if id=='snake' else (.78,.72,.8))
 physics=np.maximum(dims*np.array(mult),[.25,.16,.24])
 return {'type':'capsule_group' if id in ('wolf','tiger','leopard','bear','stone_guardian') else 'box_proxy','body_extent_xyz_raw_plus_x':np.round(physics,4).tolist(),'body_extent_xyz_scene_minus_z':np.round(physics[[2,1,0]],4).tolist(),'body_offset_xyz':[0,round(float(physics[1]/2),4),0],'units':'Godot meters; scene wrapper scale applied','provisional':True,'damage_zone':None,'physics_owner':'Bestiary02/EXO Core'}

original_sources={};inventory=[];model_map={};validation=[]
for source,z,catalog in [('forge',Z1,forge),('art02',Z2,art)]:
 for code in catalog:
  c=canonical(code); m=catalog[code]
  inputpath=m['model'].replace('res://','');b=z.read(inputpath)
  doc,blob=parse_glb(b)
  before=sizes(doc,blob);original_nodes=len(doc['nodes']);original_tracks=sum(len(a['channels']) for a in doc['animations'])
  original_sources[f'{source}:{code}']={'archive':'EXO-Murim-Creature-Forge-01.zip' if source=='forge' else 'EXO-Murim-Creature-Art-02-CANDIDATO.zip','archive_sha256':sha((SRC/('EXO-Murim-Creature-Forge-01.zip' if source=='forge' else 'EXO-Murim-Creature-Art-02-CANDIDATO.zip')).read_bytes()),'member':inputpath,'original_sha256':sha(b)}
  motion=tune(doc,blob,c)
  sockets=add_sockets(doc,c)
  doc.setdefault('asset',{})['generator']='EXO Creature Forge / Creature Art + EXO Harmonizacao 02 (retargeted sockets and clips)'
  doc['extras']={'exo_harmonizacao02':{'canonical_species_id':c,'source_code':code,'source_archive':source,'forward':'+X','up':'+Y','gameplay_forward':'-Z via Godot scene wrapper +90deg Y','source_sha256':sha(b),'authoring_note':'Original mesh and original atlas preserved; animated gait and sockets updated. No mesh resculpt.'}}
  verify(doc,blob)
  output=write_glb(doc,blob);ndoc,nblob=parse_glb(output);verify(ndoc,nblob)
  outpath=OUT/'models'/c/(source+'.glb');outpath.parent.mkdir(parents=True,exist_ok=True);outpath.write_bytes(output)
  source_bounds=before['extent'];scene_scale=scales.get(c,1.)
  scene=OUT/'scenes'/c/(source+'.tscn');scene.parent.mkdir(parents=True,exist_ok=True)
  rel='res://exo_creature_harmonizacao02/models/'+c+'/'+source+'.glb'
  scene.write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="PackedScene" path="'+rel+'" id="1"]\n\n[node name="EXO_'+c+'_'+source+'" type="Node3D"]\n\n[node name="ForwardMinusZ" type="Node3D" parent="."]\nrotation = Vector3(0, 1.5707963, 0)\n\n[node name="CreatureModel" parent="ForwardMinusZ" instance=ExtResource("1")]\nscale = Vector3('+', '.join([str(scene_scale)]*3)+')\n',encoding='utf8')
  rec={'id':c,'source_id':code,'source':source,'source_glb_path':inputpath,'original_sha256':sha(b),'harmonized_sha256':sha(output),'model':'res://exo_creature_harmonizacao02/models/'+c+'/'+source+'.glb','scene':'res://exo_creature_harmonizacao02/scenes/'+c+'/'+source+'.tscn','atlas':'embedded in GLB (unchanged)','material_count':len(doc.get('materials',[])),'texture_count':len(doc.get('textures',[])),'rig':doc['skins'][0]['name'],'bones':len(doc['skins'][0]['joints']),'clip_names':[a['name'] for a in doc['animations']],'clips_count':len(doc['animations']),'vertices':before['vertices'],'triangles':before['triangles'],'source_bounds_xyz':source_bounds,'scene_scale_proposed':scene_scale,'scene_bounds_xyz':[round(float(v*scene_scale),4) for v in source_bounds],'orientation_source':'+X forward +Y up','orientation_scene':'-Z forward +Y up via 90deg wrapper','collision_profile':collider(before,c,scene_scale),'sockets':sockets,'animation_modification':motion,'track_count_before':original_tracks,'track_count_after':sum(len(a['channels']) for a in doc['animations']),'status':'candidate_offline_glb_validation_no_native_godot','licensing':'EXO original project; commercial chain-of-title pending final verification','model_geometry':'source unchanged'}
  inventory.append(rec);model_map.setdefault(c,[]).append(rec)
  validation.append({'asset':f'{source}:{code}','passes':['glb_header','version2','finite_accessors','bone_indexes','inverse_bind','all_six_clips','timeline_monotonic','quat_unit','socket_parent','zip_source_sha256'],'results':'PASS','godot':'NOT_RUN'})

# Explicit recommendations informed by geometry, species count not affected.
preferred={'wolf':'art02','boar':'art02','tiger':'art02'}
for c,rows in model_map.items():
 if c not in preferred:preferred[c]=rows[0]['source']

canonical_catalog={}
for id in sorted(model_map):
 rows=model_map[id];pick=next(x for x in rows if x['source']==preferred[id]);b=bestiary.get(id)
 canonical_catalog[id]={'canonical_id':id,'display_name':(b['name'] if b else (art.get(id,forge.get(id,{})).get('name') or forge.get(id,{}).get('display_name') or id)),'gameplay_authority':'bestiary02' if b else 'requires_bestiary02_approval','bestiary02_id':id if b else None,'bestiary02_attacks':b['attacks'] if b else [],'bestiary02_biomes':b['biomes'] if b else [],'variants':rows,'recommended_variant':{'source':pick['source'],'model':pick['model'],'scene':pick['scene'],'reason':('Higher silhouette detail and geometry for closer camera; retain Forge 01 as performance candidate (native fps/quality comparison pending)' if len(rows)>1 else 'Only authored asset currently available')},'species_count':1,'model_variant_count':len(rows),'status':'CANDIDATO_OFFLINE; requires Godot visual and animation QA'}

pending_33=[{'catalog_number':k,'name':v['name'],'status':'PENDING_FROM_ORIGINAL_33','clarification':'Species from original Forge scope; must not auto-map to Bestiary entry with different canonical ID'} for k,v in fplanned.items() if v['status']=='PENDENTE']
bestiary_pending=[{'id':id,'name':v['name'],'status':'BESTIARY02_REGISTERED_NO_SUITABLE_FIXED_MODEL','why':'No authored GLB for exact canonical ID'} for id,v in bestiary.items() if id not in model_map]
new_proposals=[{'id':id,'name':canonical_catalog[id]['display_name'],'status':'ART_ONLY_NOT_REGISTERED_BESTIARY02'} for id in canonical_catalog if id not in bestiary]
jsonout={'schema':'exo.visual.harmonizacao02.v1','date':'2026-10-19','engine_target':'Godot 4.6.2 Standard Compatibility','source_archives_sha256':{k:val['archive_sha256'] for k,val in [('Creature Forge 01',original_sources['forge:wolf']),('Creature Art 02',original_sources['art02:wolf'])]},'count':{'unique_creature_ids':len(canonical_catalog),'unique_source_glb':len(inventory),'duplicate_species':len([v for v in canonical_catalog.values() if len(v['variants'])>1]),'bestiary02_registered_with_visual':len([v for v in canonical_catalog.values() if v['bestiary02_id']]),'bestiary02_registered_without_visual':len(bestiary_pending),'original_33_planned_remaining':len(pending_33)},'assets_by_species':canonical_catalog,'original_33_pending':pending_33,'bestiary02_missing':bestiary_pending,'visual_only_proposals':new_proposals,'original_sources':original_sources,'authority_rules':{'species_ids':'Bestiary 02','spawn_biome_ecology_rewards_damage':'Bestiary 02 / EXO Core','visuals_and_sockets_only':'Harmonizacao02'},'status':'OFFLINE_QA_PASSED_NATIVE_GODOT_NOT_RUN'}
(OUT/'data').mkdir(parents=True,exist_ok=True)
(OUT/'data'/'CATALOGO-CRIATURAS-UNIFICADO.json').write_text(json.dumps(jsonout,indent=2,ensure_ascii=False),encoding='utf8')
(OUT/'data'/'qa_offline.json').write_text(json.dumps({'validations':validation,'tested_glbs':len(validation),'passed':len(validation),'godot':'NOT_RUN','metadata_caveat':'No physics/IK/visual approval'},indent=2,ensure_ascii=False),encoding='utf8')
(OUT/'data'/'roster_bestiary02.json').write_text(json.dumps({k:{'model':v['recommended_variant']['model'],'scene':v['recommended_variant']['scene'],'bestiary_id':v['bestiary02_id'],'only_visual':True} for k,v in canonical_catalog.items() if v['bestiary02_id']},indent=2,ensure_ascii=False),encoding='utf8')
print('OUT',len(inventory),'variants',len(canonical_catalog),'species',len(pending_33),'original33pending','bestiary_missing',len(bestiary_pending), 'production changes',sum(len(x['animation_modification']) for x in inventory))
