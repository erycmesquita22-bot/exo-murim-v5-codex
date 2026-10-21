extends Node3D
## Original voxel Murim geometry built by actual Godot MeshInstance3D / StaticBody3D.
## Isolated preview; no host C3 dependency and no player/NPC spawns.
const Composer=preload("res://exo_city_forge/runtime/city_composer.gd")
const Legend=preload("res://exo_city_forge/preview/debug_legend.gd")
const Catalog=preload("res://exo_city_forge/runtime/city_registry.gd")
var seeds: Array=[101,816204,707,18026]
var seed_index: int=0
var blueprint_index: int=0
var profile_index: int=0
var blueprint_ids: Array=[]
var profile_ids: Array=[]
var palette: Dictionary={}
var show_landmark_gallery := false
func _ready() -> void:
 var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("93b5ce");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("ffffff");env.ambient_light_energy=0.7
 $WorldEnvironment.environment=env
 $Camera.look_at(Vector3.ZERO)
 var catalog: Dictionary=Catalog.catalog()
 for blueprint in catalog.blueprints:blueprint_ids.append(str(blueprint.id))
 for profile in catalog.profiles:profile_ids.append(str(profile.id))
 blueprint_index=maxi(0,blueprint_ids.find("orthogonal_market"))
 profile_index=maxi(0,profile_ids.find("rich_commercial_city"))
 _compose()
func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_1:blueprint_index=maxi(0,blueprint_ids.find("orthogonal_market"))
  KEY_2:blueprint_index=maxi(0,blueprint_ids.find("walled_crossroads"))
  KEY_3:blueprint_index=maxi(0,blueprint_ids.find("irregular_hillside"))
  KEY_4:blueprint_index=maxi(0,blueprint_ids.find("caravan_ring"))
  KEY_5:blueprint_index=maxi(0,blueprint_ids.find("waterless_terrace"))
  KEY_B:blueprint_index=(blueprint_index+1)%blueprint_ids.size()
  KEY_N:blueprint_index=posmod(blueprint_index-1,blueprint_ids.size())
  KEY_L:show_landmark_gallery=not show_landmark_gallery
  KEY_Q:_change_profile(-1)
  KEY_E:_change_profile(1)
  KEY_LEFT:seed_index=posmod(seed_index-1,seeds.size())
  KEY_RIGHT:seed_index=(seed_index+1)%seeds.size()
  _:return
 _compose()
func _change_profile(direction: int) -> void:
 var catalog: Dictionary=Catalog.catalog()
 var scale: String="city"
 for blueprint in catalog.blueprints:
  if str(blueprint.id)==str(blueprint_ids[blueprint_index]):
   scale="city" if "city" in blueprint.allowed_scales else str(blueprint.allowed_scales[0])
   break
 var eligible: Array=[]
 for profile in catalog.profiles:
  if scale in profile.get("allowed_scales",["village","town","city"]):eligible.append(str(profile.id))
 eligible.sort()
 if eligible.is_empty():return
 var current: String=str(profile_ids[profile_index])
 var idx: int=eligible.find(current)
 var next_id: String=str(eligible[posmod(idx+direction,eligible.size())]) if idx>=0 else str(eligible[0])
 profile_index=maxi(0,profile_ids.find(next_id))
func _material(hex_color: String) -> StandardMaterial3D:
 if palette.has(hex_color):return palette[hex_color]
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color(hex_color);mat.roughness=1.0
 palette[hex_color]=mat
 return mat
func _cube(parent: Node3D,at: Vector3,size: Vector3,color: String,solid: bool=true) -> Node3D:
 var root:=Node3D.new();parent.add_child(root);root.position=at
 var instance:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;instance.mesh=mesh;instance.material_override=_material(color);instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(instance)
 if solid:
  var body:=StaticBody3D.new();body.collision_layer=4;root.add_child(body)
  var shape:=CollisionShape3D.new();var collider:=BoxShape3D.new();collider.size=size;shape.shape=collider;body.add_child(shape)
 return root
func _line(parent: Node3D,a: Vector2,b: Vector2,width: float,color: String,raise: float=.12) -> void:
 var d: Vector2=b-a
 var node: Node3D=_cube(parent,Vector3((a.x+b.x)*.5,raise,(a.y+b.y)*.5),Vector3(width,.19,d.length()),color,false)
 node.rotation.y=-atan2(d.x,d.y)
func _sector_floor(parent: Node3D,sector: Dictionary,color: String) -> void:
 var pts:=PackedVector2Array()
 for p in sector.footprint:pts.append(Vector2(float(p[0]),float(p[1])))
 var tris:=Geometry2D.triangulate_polygon(pts)
 if tris.is_empty():return
 var surf:=SurfaceTool.new();surf.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in tris:
  var point: Vector2=pts[i]
  surf.set_normal(Vector3.UP);surf.add_vertex(Vector3(point.x,-.09,point.y))
 var mesh:=surf.commit();var visual:=MeshInstance3D.new();visual.mesh=mesh;visual.material_override=_material(color)
 visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(visual)
func _building(parent: Node3D,b: Dictionary) -> void:
 var root:=Node3D.new();parent.add_child(root);root.name=str(b.id).replace("/","_");root.position=Vector3(float(b.p[0]),0,float(b.p[1]));root.rotation.y=float(b.get("yaw",0.0))
 root.set_meta("building_id",str(b.id));root.set_meta("function",str(b.function));root.set_meta("interior_slot",bool(b.interior_slot));root.set_meta("entry_status","visual_only_not_host_verified")
 var w: float=float(b.size[0]);var d: float=float(b.size[1]);var h: float=float(b.height)
 var scheme: String=str(b.function)
 var archetype: String=str(b.get("archetype","generic"))
 var wall: String="e6c78f" if scheme in ["market","inn","herbalist"] else "d9b18b" if scheme in ["smithy","warehouse"] else "e0d8b8" if scheme in ["administration","shrine"] else "a9a2a0" if scheme=="martial_school" else "d8b698"
 var roof: String="2e6f68" if scheme in ["residence","martial_school","shrine"] else "a04b37" if scheme in ["market","inn"] else "4b5960" if scheme in ["warehouse","smithy"] else "456e81"
 if archetype in ["straw_hut","farmstead_hut","animal_shed"]:wall="c9b692";roof="8a7541"
 if archetype in ["clay_house","kiln_hut"]:wall="af825f";roof="995d3b"
 if archetype in ["stilt_house","timber_house","granary","watch_hut"]:wall="ad936c";roof="74623e"
 if archetype in ["dojo_hut","small_shrine","council_hall"]:roof="377f78"
 _cube(root,Vector3(0,.14,0),Vector3(w,.28,d),"8a7963")
 _cube(root,Vector3(-w*.5+.22,h*.5,0),Vector3(.44,h,d),wall)
 _cube(root,Vector3(w*.5-.22,h*.5,0),Vector3(.44,h,d),wall)
 _cube(root,Vector3(0,h*.5,-d*.5+.22),Vector3(w,h,.44),wall)
 # Two front jambs. The 2.4m gap is actually traversable with colliders.
 var jamb: float=maxf(.4,(w-2.4)*.5)
 _cube(root,Vector3(-(2.4+jamb)*.5,h*.5,d*.5-.22),Vector3(jamb,h,.44),wall)
 _cube(root,Vector3((2.4+jamb)*.5,h*.5,d*.5-.22),Vector3(jamb,h,.44),wall)
 _cube(root,Vector3(0,h+.30,0),Vector3(w+1,.6,d+1),roof)
 _cube(root,Vector3(0,h+.70,0),Vector3(w*.83,.35,d*.85),roof)
 for x in [-w*.5+.55,w*.5-.55]:
  _cube(root,Vector3(x,h*.58,d*.5+.04),Vector3(.38,.42,.13),"554332",false)
 if scheme=="smithy":_cube(root,Vector3(w*.3,h+1.55,-d*.2),Vector3(.85,2,.85),"646366")
 if scheme=="martial_school":_cube(root,Vector3(0,h+.94,d*.20),Vector3(w*.44,.42,.4),"a8ba59",false)
 if scheme=="inn":_cube(root,Vector3(-w*.48,h*.65,d*.4),Vector3(.45,1.9,.4),"b45b32",false)
 # R3 original geometry recipes; restricted to authored standalone preview.
 # Host R13 architecture sees only official function; these extra shapes are NOT automatically imported there.
 if archetype=="stilt_house":
  _cube(root,Vector3(0,-.24,0),Vector3(w+.5,.55,d+.5),"73573a")
  for xx in [-w*.35,w*.35]:
   for zz in [-d*.35,d*.35]:_cube(root,Vector3(xx,-.8,zz),Vector3(.4,1.5,.4),"6c5138")
 if archetype=="granary":
  _cube(root,Vector3(w*.12,h+.85,-d*.12),Vector3(w*.42,1.15,d*.38),"b68c4c")
 if archetype=="animal_shed":
  for zz in [-d*.33,d*.33]:_cube(root,Vector3(w*.30,.9,zz),Vector3(.15,1.8,.15),"6b4b35")
 if archetype=="watch_hut":
  _cube(root,Vector3(0,h+1.3,0),Vector3(w*.65,1.0,d*.65),"685b41",false)
 if archetype in ["road_stall","tea_stall"]:
  _cube(root,Vector3(0,h+.85,d*.34),Vector3(w*.82,.38,d*.40),"b8563b",false)
 if archetype in ["herb_hut","loom_house"]:
  for xx in [-w*.25,w*.25]:_cube(root,Vector3(xx,.7,d*.57),Vector3(.52,.58,.52),"6c8b4d",false)
 if archetype=="kiln_hut":
  _cube(root,Vector3(-w*.3,h+.8,-d*.25),Vector3(.95,1.6,.95),"724e41",true)
 if archetype=="small_shrine":
  _cube(root,Vector3(0,1.2,d*.57),Vector3(1.1,1.3,.4),"bc9e68",false)
 if archetype=="council_hall":
  _cube(root,Vector3(0,h+.75,0),Vector3(w*.62,.5,d*.75),"386b65",false)
 if archetype=="dojo_hut":
  for xx in [-w*.25,w*.25]:_cube(root,Vector3(xx,.9,d*.70),Vector3(.22,1.8,.22),"926c44",false)

func _landmark(parent: Node3D,id: String,position: Vector2) -> void:
 var n:=Node3D.new();parent.add_child(n);n.name=id;n.position=Vector3(position.x,0,position.y);n.set_meta("landmark_id",id)
 match id:
  "bell_tower":
   _cube(n,Vector3(0,2,0),Vector3(3,4,3),"bbae84");_cube(n,Vector3(0,4.6,0),Vector3(5,1,5),"2d6e70");_cube(n,Vector3(0,5.25,0),Vector3(2,.7,2),"bd913f")
  "stone_gate":
   _cube(n,Vector3(-2,2,0),Vector3(1.2,4,1.3),"8c8d88");_cube(n,Vector3(2,2,0),Vector3(1.2,4,1.3),"8c8d88");_cube(n,Vector3(0,4.4,0),Vector3(5.5,.9,1.8),"8c8d88")
  "jade_fountain":
   _cube(n,Vector3(0,.5,0),Vector3(5,1,5),"879a91");_cube(n,Vector3(0,1.1,0),Vector3(4,.22,4),"4f9eb4",false);_cube(n,Vector3(0,2,0),Vector3(1,2,1),"74b8a1")
  "martial_stela":
   _cube(n,Vector3(0,.6,0),Vector3(3,1,2),"777f82");_cube(n,Vector3(0,2.5,0),Vector3(1.5,3,1),"596267")
  "market_pavilion":
   for x in [-2,2]:
    for z in [-2,2]:_cube(n,Vector3(x,1.8,z),Vector3(.5,3.6,.5),"99694b")
   _cube(n,Vector3(0,3.9,0),Vector3(5.5,.6,5.5),"a34b34")
  "lantern_arch":
   for x in [-2.5,2.5]:_cube(n,Vector3(x,2.1,0),Vector3(.5,4.2,.5),"815c41")
   _cube(n,Vector3(0,4.35,0),Vector3(6,.5,.65),"8a4e31")
   for x in [-2.0,0.0,2.0]:_cube(n,Vector3(x,3.6,0),Vector3(.6,1.0,.6),"c08e37",false)
  "clan_memorial":
   _cube(n,Vector3(0,.3,0),Vector3(5,.6,4),"74766d")
   _cube(n,Vector3(0,2.0,0),Vector3(3.2,3.1,.7),"9e9684")
  "roadside_torii":
   for x in [-2.2,2.2]:_cube(n,Vector3(x,2.4,0),Vector3(.6,4.8,.6),"a34b36")
   _cube(n,Vector3(0,4.55,0),Vector3(6.2,.7,.8),"713a29")
  "tea_stage":
   _cube(n,Vector3(0,.45,0),Vector3(6,.9,5),"8c7055")
   for x in [-2.4,2.4]:_cube(n,Vector3(x,2.6,-1.8),Vector3(.3,3.5,.3),"89633f")
   _cube(n,Vector3(0,4.1,-1.8),Vector3(5.5,.5,1.5),"2b7467")
  "clan_banner":
   _cube(n,Vector3(0,3,0),Vector3(.35,6,.35),"604a36");_cube(n,Vector3(.9,4.8,0),Vector3(1.8,2.6,.15),"b24f3d",false)
  "rural_well":
   for x in [-1.1,1.1]:
    for z in [-1.1,1.1]:_cube(n,Vector3(x,.55,z),Vector3(.7,1.1,.7),"918375")
   _cube(n,Vector3(0,.35,0),Vector3(2.4,.12,2.4),"4993a2",false)
  "bamboo_lookout":
   for x in [-1.3,1.3]:
    for z in [-1.3,1.3]:_cube(n,Vector3(x,2.6,z),Vector3(.4,5.2,.4),"a5905e")
   _cube(n,Vector3(0,5.1,0),Vector3(4,.35,4),"866a40")
  "village_ancestral_tree":
   _cube(n,Vector3(0,2.5,0),Vector3(1.4,5,1.4),"74603e")
   for x in [-1.4,1.4]:_cube(n,Vector3(x,5.0,0),Vector3(3,3.2,4.2),"4b7d44",false)
  "grain_silo":
   _cube(n,Vector3(0,2,0),Vector3(3.3,4,3.3),"b69a68")
   _cube(n,Vector3(0,4.4,0),Vector3(4.4,1,4.4),"a17e4b")
  "wooden_bridge":
   _cube(n,Vector3(0,1,0),Vector3(6,.45,3),"8c7549")
   for x in [-2.8,2.8]:
    for z in [-1.3,1.3]:_cube(n,Vector3(x,1.65,z),Vector3(.28,1.3,.28),"87623d")
  "village_bell":
   for x in [-1.7,1.7]:_cube(n,Vector3(x,2.25,0),Vector3(.4,4.5,.4),"9e7b4b")
   _cube(n,Vector3(0,4.4,0),Vector3(4.0,.45,.65),"765a3b")
   _cube(n,Vector3(0,2.6,0),Vector3(1.3,1.6,1.2),"ac8b42",false)
func _compose() -> void:
 for child in $Generated.get_children():child.free()
 var blueprint_catalog: Dictionary={}
 for candidate in Catalog.catalog().blueprints:
  if str(candidate.id)==str(blueprint_ids[blueprint_index]):blueprint_catalog=candidate;break
 var scales: Array=blueprint_catalog.get("allowed_scales",["city"])
 var scale: String="city" if "city" in scales else str(scales[0])
 var eligible_profiles: Array=[]
 for item in Catalog.catalog().profiles:
  if scale in item.get("allowed_scales",["village","town","city"]):eligible_profiles.append(str(item.id))
 if eligible_profiles.is_empty():return
 var selected_profile: String=str(profile_ids[profile_index])
 if selected_profile not in eligible_profiles:
  profile_index=maxi(0,profile_ids.find(str(eligible_profiles[0])))
 var request: Dictionary={"region_id":26,"region_seed":str(seeds[seed_index]),"kind":"settlement","settlement_scale":scale,"profile_id":profile_ids[profile_index],"blueprint_id":blueprint_ids[blueprint_index],"half_extent":256.0,"gates":[[0,-230],[230,0]],"rivers":[],"monument_reservations":[],"mode":"authored_modular","families":3 if profile_ids[profile_index]=="poor_martial_city" else 1}
 var plan: Dictionary=Composer.compose(request)
 $Overlay/Legend.text=Legend.text(plan,str(seeds[seed_index]))
 if str(plan.get("status",""))!="ready":return
 _cube($Generated,Vector3(0,-.42,0),Vector3(510,.5,510),"69865a",true)
 for street in plan.streets:
  _line($Generated,Vector2(float(street.a[0]),float(street.a[1])),Vector2(float(street.b[0]),float(street.b[1])),float(street.width),"b59a70")
 var colors: Dictionary={"residential":"7c9b64","commercial":"d9aa64","martial":"a1a66c","institutional":"92a0a1","noble":"c3b096","plaza":"cdbda0","artisan":"a9a17a","mixed":"b6ae77"}
 for sector in plan.sectors:
  var b: Dictionary=sector.bounds
  _sector_floor($Generated,sector,str(colors.get(str(sector.category),"92ab6f")))
  for street in sector.internal_streets:
   var c: Array=sector.center
   _line($Generated,Vector2(float(c[0])+float(street.a[0]),float(c[1])+float(street.a[1])),Vector2(float(c[0])+float(street.b[0]),float(c[1])+float(street.b[1])),float(street.width),"b9a88a",.08)
 for b in plan.buildings:
  var gate: Array=b.get("door",[])
  var anchor: Array=b.get("street_point",[])
  if gate.size()==2 and anchor.size()==2:
   _line($Generated,Vector2(float(gate[0]),float(gate[1])),Vector2(float(anchor[0]),float(anchor[1])),1.8,"b9a88a",.16)
  _building($Generated,b)
 # Gallery outside the city shows original landmarks without incorrectly placing them in roads.
 # CityPlan landmarks remain [] until the host approves actual real placement slots.
 if show_landmark_gallery:
  var lands: Array=Catalog.catalog().landmarks
  for i in range(lands.size()):
   var x: float=186.0+float(i%5)*15.0
   var z: float=-173.0+float(i/5)*15.0
   _landmark($Generated,str(lands[i].id),Vector2(x,z))
 if bool(plan.wall):
  # Segment the wall at the authored, preview-only street termini.
  # These gates are NOT WorldGenesis host gates; host remains authoritative.
  var rural_wall: bool=scale=="village"
  var wall_h: float=2.7 if rural_wall else 4.1 if scale=="town" else 5.6
  var wall_material: String="927548" if rural_wall else "887f73"
  var e: float=float(plan.get("blueprint_half_extent",100.0))+4.0
  var entrances: Array=blueprint_catalog.get("gates",[])
  var piece: float=5.5
  var count: int=int(ceil((e*2.0)/piece))
  for side in ["west","east","north","south"]:
   for idx in range(count):
    var v: float=-e+(float(idx)+.5)*(e*2.0/float(count))
    var span: float=e*2.0/float(count)
    var opening: bool=false
    for entrance in entrances:
     if not entrance is Array or entrance.size()!=2:continue
     var ex: float=float(entrance[0])
     var ez: float=float(entrance[1])
     var projected_side: String="east" if absf(ex)>=absf(ez) and ex>0 else "west" if absf(ex)>=absf(ez) else "south" if ez>0 else "north"
     var gate_axis: float=ez if projected_side in ["east","west"] else ex
     if projected_side==side and absf(v-gate_axis)<5.5:opening=true
    if opening:continue
    var pos: Vector3=Vector3(e if side=="east" else -e,wall_h*.5,v) if side in ["east","west"] else Vector3(v,wall_h*.5,e if side=="south" else -e)
    var dims: Vector3=Vector3(1.7,wall_h,span) if side in ["east","west"] else Vector3(span,wall_h,1.7)
    _cube($Generated,pos,dims,wall_material)
  for entrance in entrances:
   if not entrance is Array or entrance.size()!=2:continue
   var near: Vector2=Vector2(float(entrance[0]),float(entrance[1]))
   var end: Vector2=near
   if absf(near.x)>=absf(near.y):end.x=e*signf(near.x)
   else:end.y=e*signf(near.y)
   _line($Generated,near,end,3.3,"b29b76",.13)
