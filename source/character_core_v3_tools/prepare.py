import bpy,bmesh,math,json,os
from mathutils import Matrix,Vector
from pathlib import Path
R=Path(__file__).resolve().parents[1]; O=R/'original/EXO_Murim_PixelInk_Hero_V4_Illustrated'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(O/'model/EXO_Murim_Voxel_PixelInk_V4.glb'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:
 mat=Matrix.Rotation(-math.pi/2,4,'X')@o.matrix_world
 o.data.transform(mat);o.parent=None;o.matrix_world=Matrix.Identity(4)
original_image=bpy.data.images.load(str(O/'model/EXO_Murim_Skin_64UV_x16.png'),check_existing=True)
original_image.pack()
scene_fps=60
bpy.context.scene.render.fps=60
for m in bpy.data.materials:
 if m.use_nodes:
  for n in m.node_tree.nodes:
   if n.type=='TEX_IMAGE':
    n.image=original_image;n.interpolation='Closest'
# identical render scene for original and rig
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=False
scene.render.resolution_x=480;scene.render.resolution_y=600;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.65,.65,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
scene.view_settings.view_transform='Standard'
for name,loc,power,size in [('Key',(-3,-4,6),450,5),('Fill',(4,2,4),220,4)]:
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size
 o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,1.5))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('AuditCamera');cam=bpy.data.objects.new('AuditCamera',d);scene.collection.objects.link(cam);scene.camera=cam;d.type='ORTHO';d.ortho_scale=3.45
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False

def render(prefix):
 if os.environ.get('EXO_FAST_BUILD')=='1':return
 for az in [0,90,180,35]:
  t=math.radians(az);cam.location=(6*math.sin(t),-6*math.cos(t),3)
  cam.rotation_euler=(Vector((0,0,1.47))-cam.location).to_track_quat('-Z','Y').to_euler()
  scene.render.filepath=str(R/'captures'/f'{prefix}_{az:03d}.png');bpy.ops.render.render(write_still=True)

if not (R/'captures/original_000.png').exists(): render('original')
# Expected neutral appearance after the explicitly requested scabbard removal.
ob=bpy.data.objects['ACCESSORY_sword'];saved=ob.data;ob.data=saved.copy()
bm=bmesh.new();bm.from_mesh(ob.data);bm.faces.ensure_lookup_table()
bmesh.ops.delete(bm,geom=list(bm.faces)[:8],context='FACES');bm.to_mesh(ob.data);bm.free()
render('reference_no_scabbard')
ob.data=saved

# split the original surfaces by clipping; UVs interpolated by bmesh. Caps are internal joint surfaces only.
def clip_object(src,name,zmin,zmax):
 ob=src.copy();ob.data=src.data.copy();scene.collection.objects.link(ob);ob.name=name
 bm=bmesh.new();bm.from_mesh(ob.data)
 for z,normal in [(zmin,(0,0,1)),(zmax,(0,0,-1))]:
  if z is None:continue
  geom=list(bm.verts)+list(bm.edges)+list(bm.faces)
  bmesh.ops.bisect_plane(bm,geom=geom,dist=1e-7,plane_co=(0,0,z),plane_no=normal,clear_inner=True,clear_outer=False)
 bm.to_mesh(ob.data);bm.free()
 # Original has per-face disconnected vertices; merge for caps, retaining loop UV seams.
 bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
 edges=[e for e in bm.edges if e.is_boundary]
 if edges:
  fs=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[])
  uv=bm.loops.layers.uv.active
  for f in fs:
   for l in f.loops:
    if uv:l[uv].uv=(.40,.80) # shared dark atlas, internal cut surface
 bm.to_mesh(ob.data);bm.free();return ob
parts={}
for side in ['L','R']:
 src=bpy.data.objects['ARM_'+side]
 parts['upper_arm_'+side]=[clip_object(src,'ARM_'+side,1.70,None)]
 parts['forearm_'+side]=[clip_object(src,'ARM_'+side+'_forearm',None,1.70)]
 bpy.data.objects.remove(src,do_unlink=True);parts['hand_'+side]=[bpy.data.objects['HAND_'+side]]
 src=bpy.data.objects['LEG_'+side]
 parts['thigh_'+side]=[clip_object(src,'LEG_'+side,.69,None)]
 parts['shin_'+side]=[clip_object(src,'LEG_'+side+'_shin',.30,.69)]
 parts['foot_'+side]=[clip_object(src,'LEG_'+side+'_foot',None,.30)]
 bpy.data.objects.remove(src,do_unlink=True)
# separate original scabbard 8 triangles from original grip/guard/pommel 32 triangles using original polygon ordering
sword=bpy.data.objects['ACCESSORY_sword']
def face_subset(src,name,keep):
 ob=src.copy();ob.data=src.data.copy();scene.collection.objects.link(ob);ob.name=name
 bm=bmesh.new();bm.from_mesh(ob.data);bm.faces.ensure_lookup_table()
 bmesh.ops.delete(bm,geom=[f for i,f in enumerate(bm.faces) if i not in keep],context='FACES')
 bm.to_mesh(ob.data);bm.free();return ob
sheath=face_subset(sword,'ACCESSORY_scabbard',set(range(8)))
grip=face_subset(sword,'ACCESSORY_sword',set(range(8,40)))
bpy.data.objects.remove(sword,do_unlink=True);grip.name='ACCESSORY_sword'
# paper robe panels follow corresponding thighs, preserving exact original vertex/UV data
skirt=bpy.data.objects['SKIRT_paper']
for side,sg in [('L',-1),('R',1)]:
 keep={p.index for p in skirt.data.polygons if sum(skirt.data.vertices[i].co.x for i in p.vertices)*sg>0}
 parts['thigh_'+side].append(face_subset(skirt,'SKIRT_paper_'+side,keep))
bpy.data.objects.remove(skirt,do_unlink=True)
parts['spine']=[bpy.data.objects[x] for x in ['BODY_tunic','BODY_outer_layer']]
parts['pelvis']=[bpy.data.objects[x] for x in ['FRONT_tabard','SASH_ribbons']]
parts['head']=[bpy.data.objects[x] for x in ['HEAD_skin','HEAD_hair_overlay','HAIR_ponytail','HAIR_side_locks']]
bpy.data.objects.remove(sheath,do_unlink=True)
parts['socket_waist']=[];parts['weapon']=[grip]
# Original identifiers retained on proximal segments.
for side in ['L','R']:
 parts['upper_arm_'+side][0].name='ARM_'+side
 parts['thigh_'+side][0].name='LEG_'+side
# skeleton rest contract, Z up in Blender; exported Y up by glTF
bones={
 'root':(None,(0,0,0),(0,0,.2)),
 'pelvis':('root',(0,0,1.32),(0,0,1.5)),
 'spine':('pelvis',(0,0,1.5),(0,0,2.10)),
 'neck':('spine',(0,0,2.10),(0,0,2.185)),
 'head':('neck',(0,0,2.185),(0,0,2.70)),
 'socket_waist':('pelvis',(-.30,-.31,1.60),(-.30,-.31,1.70)),
 'socket_back':('spine',(0,.25,1.9),(0,.25,2.0)),
 'socket_head':('head',(0,0,2.80),(0,0,2.90))}
for side,sg in [('L',-1),('R',1)]:
 x=sg*.515;lx=sg*.192
 bones.update({
 'clavicle_'+side:('spine',(sg*.28,0,2.10),(x,0,2.10)),
 'upper_arm_'+side:('clavicle_'+side,(x,0,2.10),(x,0,1.70)),
 'forearm_'+side:('upper_arm_'+side,(x,0,1.70),(x,-.004,1.30)),
 'hand_'+side:('forearm_'+side,(x,-.004,1.30),(x,-.004,1.15)),
 'socket_hand_'+side:('hand_'+side,(x,-.004,1.245),(x,-.10,1.245)),
 'thigh_'+side:('pelvis',(lx,0,1.255),(lx,0,.69)),
 'shin_'+side:('thigh_'+side,(lx,0,.69),(lx,0,.30)),
 'foot_'+side:('shin_'+side,(lx,0,.30),(lx,-.16,.20))})
bones['weapon']=('pelvis',(-.30,-.31,1.60),(-.30,-.31,1.70))
ad=bpy.data.armatures.new('EXO_Humanoid_Core01');rig=bpy.data.objects.new('EXO_Rig',ad);scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,(parent,h,t) in bones.items():
 b=ad.edit_bones.new(name);b.head=h;b.tail=t
 if parent:b.parent=ad.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for bn,obs in parts.items():
 for ob in obs:
  vg=ob.vertex_groups.new(name=bn);vg.add(list(range(len(ob.data.vertices))),1,'REPLACE')
  md=ob.modifiers.new('Rigid_piece_skin','ARMATURE');md.object=rig;ob.parent=rig
# Preserve every piece identifier and record replacements
(R/'docs/bone_contract.json').write_text(json.dumps({'bones':bones,'parts':{k:[o.name for o in v] for k,v in parts.items()},'units':'meters','blender_up':'Z','godot_up':'Y'},indent=2))
# original animations, sampled authored poses; no external motion data
for p in rig.pose.bones:p.rotation_mode='QUATERNION'
weapon=rig.pose.bones['weapon']
def animate(name,duration,loop,posefn):
 action=bpy.data.actions.new(name);rig.animation_data_create();rig.animation_data.action=action
 frames=round(duration*60)
 previous_quats={}
 global transport_frames
 transport_frames={}
 max_authored_step=0.0
 for f in range(frames+1):
  scene.frame_set(f+1)
  t=f/60;u=t/duration
  for p in rig.pose.bones:p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0)
  global held
  held=None
  posefn(t,u)
  bpy.context.view_layer.update()
  waist_target=P['pelvis'].matrix @ ad.bones['pelvis'].matrix_local.inverted() @ ad.bones['weapon'].matrix_local
  if held:
   side_x=-.515 if held=='L' else .515
   rest_grip=ad.bones['weapon'].matrix_local.copy();rest_grip.translation=Vector((side_x,-.08,1.245))
   target=P['hand_'+held].matrix @ ad.bones['hand_'+held].matrix_local.inverted() @ rest_grip
  else:target=waist_target
  P['weapon'].matrix=target
  bpy.context.view_layer.update()
  for p in rig.pose.bones:
   transport_frames[p.name]=p.matrix.to_3x3().copy()
   if p.name in previous_quats:
    if p.rotation_quaternion.dot(previous_quats[p.name])<0:p.rotation_quaternion.negate()
    step=p.rotation_quaternion.rotation_difference(previous_quats[p.name]).angle
    if step>.6:print('ROTATION_JUMP',name,f,p.name,round(step,4))
    max_authored_step=max(max_authored_step,step)
   previous_quats[p.name]=p.rotation_quaternion.copy()
   p.keyframe_insert('rotation_quaternion',frame=f+1,group=p.name);p.keyframe_insert('location',frame=f+1,group=p.name)
 for fc in action.fcurves:
  for kp in fc.keyframe_points:kp.interpolation='LINEAR'
 track=rig.animation_data.nla_tracks.new();track.name=name;strip=track.strips.new(name,1,action)
 track.mute=True
 action['loop']=loop
 action['max_authored_rotation_step']=max_authored_step
 print('AUTHORED_STEP',name,max_authored_step)
 return action
P=rig.pose.bones
def rot(n,x=0,y=0,z=0):P[n].rotation_quaternion=Euler(tuple(math.radians(v) for v in (x,y,z))).to_quaternion()
exec(compile((R/'source/motion_authoring.py').read_text(),str(R/'source/motion_authoring.py'),'exec'),globals())
rig.animation_data.action=None
for tr in rig.animation_data.nla_tracks:tr.mute=True
for p in P:p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0)
scene.frame_set(1);bpy.context.view_layer.update()
render('rig_neutral')
# save editable with packed original image, and export original named actions
# The original external PNG is already packed, preserving image bytes.

bpy.ops.wm.save_as_mainfile(filepath=str(R/'EXO_Character_Core01.blend'))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in scene.objects:
 if o.type=='MESH':o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'godot/assets/EXO_Character_Core01.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_force_sampling=True,export_skins=True,export_all_influences=False,export_yup=True)
print('CORE01_BUILD_COMPLETE')
