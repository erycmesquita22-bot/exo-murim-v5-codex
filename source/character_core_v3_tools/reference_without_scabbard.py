"""Removes only the first eight scabbard triangles; preserves all original binary data."""
import json,struct,pathlib
R=pathlib.Path(__file__).resolve().parents[1]
p=R/'original/EXO_Murim_PixelInk_Hero_V4_Illustrated/model/EXO_Murim_Voxel_PixelInk_V4.glb'
b=p.read_bytes();n=struct.unpack_from('<I',b,12)[0];d=json.loads(b[20:20+n]);tail=b[20+n:]
a=d['accessors'][d['meshes'][15]['primitives'][0]['indices']]
assert a['componentType']==5125 and a['count']==120
# Vertex indices for the first eight triangles exclusively belong to the scabbard.
a['byteOffset']=a.get('byteOffset',0)+24*4;a['count']-=24
a.pop('min',None);a.pop('max',None)
j=json.dumps(d,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
out=struct.pack('<III',0x46546c67,2,20+len(j)+len(tail))+struct.pack('<II',len(j),0x4e4f534a)+j+tail
(R/'godot/assets/Reference_No_Scabbard.glb').write_bytes(out)
print('Reference_No_Scabbard.glb: original GLB with only 8 scabbard triangles removed')
