import struct,json,hashlib,pathlib,io
import numpy as np
from PIL import Image,ImageChops,ImageDraw
R=pathlib.Path(__file__).resolve().parents[1]
def load(path):
 b=path.read_bytes();n=struct.unpack_from('<I',b,12)[0];d=json.loads(b[20:20+n]);data=b[28+n:]
 def accessor(index):
  a=d['accessors'][index];v=d['bufferViews'][a['bufferView']];ty={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']];components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
  return np.frombuffer(data,dtype=ty,count=a['count']*components,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],components)
 def img():
  v=d['bufferViews'][d['images'][0]['bufferView']];return Image.open(io.BytesIO(data[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']])).convert('RGBA')
 return d,accessor,img
old,oa,oi=load(R/'godot/assets/Original_V4.glb');new,na,ni=load(R/'godot/assets/EXO_Character_Core01.glb')
report={'triangles_original':sum(oa(p['indices']).size//3 for m in old['meshes'] for p in m['primitives']), 'triangles_final':sum(na(p['indices']).size//3 for m in new['meshes'] for p in m['primitives']),'materials':len(new['materials']),'mesh_count':len(new['meshes']),'bone_count':len(new['skins'][0]['joints']),'animations':[x['name'] for x in new['animations']],'embedded_texture_pixels_equal_original':np.array_equal(np.asarray(oi()),np.asarray(ni())),'external_texture_sha256':hashlib.sha256((R/'godot/assets/EXO_Murim_Skin_64UV_x16.png').read_bytes()).hexdigest(),'unchanged_surface_vertices_uv':{},'scabbard_node_present':any('scabbard' in n.get('name','').lower() for n in new['nodes'])}
for name in ['HEAD_skin','HEAD_hair_overlay','HAIR_ponytail','HAIR_side_locks','BODY_tunic','BODY_outer_layer','HAND_L','HAND_R','SASH_ribbons','FRONT_tabard']:
 o=next(m for m in old['meshes'] if m['name']==name)['primitives'][0]
 node=next(n for n in new['nodes'] if n.get('name')==name)
 n=new['meshes'][node['mesh']]['primitives'][0]
 op=oa(o['attributes']['POSITION']);op=np.column_stack([op[:,0],op[:,2],-op[:,1]])
 ov=np.column_stack([op,oa(o['attributes']['TEXCOORD_0'])]);nv=np.column_stack([na(n['attributes']['POSITION']),na(n['attributes']['TEXCOORD_0'])])
 # Blender flips texture V on import and glTF flips it back; compare with tolerance.
 report['unchanged_surface_vertices_uv'][name]=bool(all(np.any(np.max(np.abs(nv-v),axis=1)<1e-6) for v in ov))
report['uv_finite_and_range']=all(np.isfinite(na(p['attributes']['TEXCOORD_0'])).all() and na(p['attributes']['TEXCOORD_0']).min()>=-1e-6 and na(p['attributes']['TEXCOORD_0']).max()<=1.000001 for m in new['meshes'] for p in m['primitives'])
for key,v in report.items():print(key,v)
(R/'logs/final_asset_audit.json').write_text(json.dumps(report,indent=2))
comparisons={}
for a in ['000','035','090','180']:
 for prefix,left,right in [('blender','reference_no_scabbard','rig_neutral'),('godot','godot_reference','godot_final')]:
  x=Image.open(R/f'captures/{left}_{a}.png').convert('RGB');y=Image.open(R/f'captures/{right}_{a}.png').convert('RGB');ar=np.asarray(ImageChops.difference(x,y))
  comparisons[prefix+'_'+a]={'different_pixels':int((ar.max(axis=2)>0).sum()),'max_channel_difference':int(ar.max()),'mean_absolute_channel_difference':float(ar.mean())}
  board=Image.new('RGB',(x.width*2,x.height+40),'white');board.paste(x,(0,40));board.paste(y,(x.width,40));dr=ImageDraw.Draw(board);dr.text((10,10),'Original V4 - bainha removida',fill='black');dr.text((x.width+10,10),'Core 01 - rig / mesma camera e luz',fill='black');board.save(R/f'captures/compare_{prefix}_{a}.png')
(R/'logs/neutral_image_comparison.json').write_text(json.dumps(comparisons,indent=2));print(comparisons)
assert report['embedded_texture_pixels_equal_original']
assert all(report['unchanged_surface_vertices_uv'].values())
assert not report['scabbard_node_present']
