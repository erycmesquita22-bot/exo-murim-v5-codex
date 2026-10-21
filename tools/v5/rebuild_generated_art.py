from pathlib import Path
import hashlib,json,random,math,wave,struct
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
def scene(p,boxes,creature=False):
 lines=['[gd_scene load_steps=200 format=3]']; nodes=[]
 for i,(at,size,col) in enumerate(boxes):
  c=tuple(int(col[j:j+2],16)/255 for j in [0,2,4]);lines+=['',f'[sub_resource type="StandardMaterial3D" id="Mat{i}"]',f'albedo_color = Color({c[0]}, {c[1]}, {c[2]}, 1)','roughness = 0.95',f'[sub_resource type="BoxMesh" id="Mesh{i}"]',f'material = SubResource("Mat{i}")',f'size = Vector3({size[0]}, {size[1]}, {size[2]})'];nodes+=['',f'[node name="Part{i}" type="MeshInstance3D" parent="Body"]',f'position = Vector3({at[0]}, {at[1]}, {at[2]})',f'mesh = SubResource("Mesh{i}")']
 if creature:
  animations=[]
  for name in ['idle','walk','run','attack','hit','death','die']:
   duration=.8 if name in ['idle','walk','run'] else .5
   lines+=['',f'[sub_resource type="Animation" id="Anim_{name}"]',f'resource_name = "{name}"',f'length = {duration}']
   if name in ['idle','walk','run']:lines+=['loop_mode = 1']
   amplitude=.018 if name=='idle' else .08 if name in ['walk','run'] else .16
   # Genuine keyed geometric animation; no imported rig/animation is used.
   path='Body:rotation' if name in ['death','die'] else 'Body:position'
   values='Vector3(0,0,0), Vector3(0,0,1.4), Vector3(0,0,1.57)' if name in ['death','die'] else f'Vector3(0,0,0), Vector3(0,{amplitude},0), Vector3(0,0,0)'
   lines += ['tracks/0/type = "value"',f'tracks/0/path = NodePath("{path}")','tracks/0/interp = 1',f'tracks/0/keys = {{"times": PackedFloat32Array(0, {duration/2}, {duration}), "transitions": PackedFloat32Array(1,1,1), "update": 0, "values": [{values}]}}']
   animations.append(f'"{name}": SubResource("Anim_{name}")')
  lines+=['','[sub_resource type="AnimationLibrary" id="Lib"]','_data = {'+', '.join(animations)+'}']
 lines+=['','[node name="OriginalV5Model" type="Node3D"]','metadata/provenance = "EXO V5 code-generated replacement; clean_assets.py"','','[node name="Body" type="Node3D" parent="."]']+nodes
 if creature:lines+=['','[node name="AnimationPlayer" type="AnimationPlayer" parent="."]','libraries = {&"": SubResource("Lib")}']
 # Godot load_steps is a hint; set exact number for readability.
 lines[0]=f'[gd_scene load_steps={sum(x.startswith("[sub_resource") for x in lines)+1} format=3]'
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text('\n'.join(lines)+'\n')

records=json.loads(Path(__file__).with_name('generated_art_specs.json').read_text())
for record in records:
 p=ROOT/record['path'];p.parent.mkdir(parents=True,exist_ok=True)
 rel=record['source_id'];kind=record['kind']
 if kind=='new_code_generated_texture':
  sz=tuple(record['size']);digest=hashlib.sha256(rel.encode()).digest();rng=random.Random(int.from_bytes(digest[:8],'big'))
  kind=rel.lower();color=(73,111,68) if any(s in kind for s in ['grass','foliage','vegetation','leaf','moss']) else (119,97,69) if any(s in kind for s in ['dirt','earth','soil','wood']) else (112,123,123)
  im=Image.new('RGBA',sz,(*color,255));d=ImageDraw.Draw(im)
  # Original abstract voxel pattern, tileable block noise.
  for y in range(0,sz[1],8):
   for x in range(0,sz[0],8):
    k=rng.randrange(-14,15);d.rectangle((x,y,x+7,y+7),fill=tuple(max(0,min(255,c+k)) for c in color)+(255,))
  if 'identity' in kind or 'skin' in kind:
   im=Image.new('RGBA',sz,(184,139,105,255));d=ImageDraw.Draw(im);w,h=sz
   d.rectangle((w//4,h//3,3*w//4,h-1),fill=(44+digest[0]%50,65+digest[1]%65,75+digest[2]%60,255))
   d.rectangle((w//8,h//8,w//2,h//4),fill=(49,38,29,255))
  im.save(p)
 elif kind=='new_code_generated_voxel_scene':scene(p,record['boxes'],record['creature'])
 elif kind=='new_synthesized_feedback':
  digest=hashlib.sha256(rel.encode()).digest();rate=22050;n=int(rate*.14);freq=170+int.from_bytes(digest[:2],'big')%850
  with wave.open(str(p),'wb') as wav:
   wav.setparams((1,2,rate,n,'NONE','not compressed'));wav.writeframes(b''.join(struct.pack('<h',int(7000*math.sin(2*math.pi*freq*i/rate)*(1-i/n)**2)) for i in range(n)))
print('Regenerated',len(records),'code-generated files; no source art read.')
