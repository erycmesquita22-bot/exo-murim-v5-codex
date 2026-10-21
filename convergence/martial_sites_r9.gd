extends RefCounted
# R9 physical teaching furnishings: voxel mats inside an existing authorised
# training courtyard. Not another monumental generator or a fake QA marker.
const Occupancy=preload("res://convergence/martial_occupancy_r9.gd")
static func install(root:Node3D,plan:Dictionary,seed:String) -> int:
 if not bool(ProjectSettings.get_setting("exo_murim/r9/martial_training_enabled",true)):return 0
 if str(plan.get("kind","")) not in ["martial_medium","martial_grand"]:return 0
 var school:String=Occupancy.school_for_site(seed,str(plan.get("id","")),str(plan.get("school_id","")))
 if school!="exo_martial.school.mosteiro_jade":return 0
 var courtyard:Marker3D
 for marker in root.find_children("*","Marker3D",true,false):
  if marker.is_in_group("exo_monument_gameplay_station") and str(marker.get_meta("station_kind",""))=="training_courtyard":
   courtyard=marker;break
 if not is_instance_valid(courtyard):return 0
 var hub:=Node3D.new();hub.name="EXO_R9_JadeMeditationCircle";root.add_child(hub)
 hub.position=courtyard.position+Vector3(2.8,0.0,-1.8)
 var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_color=Color("#788a75")
 for step in range(8):
  var theta:float=TAU*float(step)/8.0
  var slab:=MeshInstance3D.new();slab.name="VoxelCircleStep_%02d"%step
  var mesh:=BoxMesh.new();mesh.size=Vector3(.75,.12,.75)
  slab.mesh=mesh;slab.material_override=floor_mat
  slab.position=Vector3(cos(theta)*1.35,0.08,sin(theta)*1.35)
  hub.add_child(slab)
  var solid:=StaticBody3D.new();solid.collision_layer=4;slab.add_child(solid)
  var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=mesh.size;shape.shape=box;solid.add_child(shape)
 var physical:=Marker3D.new();physical.name="MeditationCircle";hub.add_child(physical)
 physical.position=Vector3(0,.22,0)
 physical.set_meta("station_id",str(plan.id)+":r9_meditation_circle")
 physical.set_meta("station_kind","meditation_circle")
 physical.set_meta("capacity",1)
 physical.add_to_group("exo_monument_gameplay_station")
 return 1
