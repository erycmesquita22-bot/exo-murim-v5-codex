extends RefCounted
## EXO River Gate 02. Hydrology is READ ONLY. No new watercourses or save domain.
## Plans on the exact Genesis river contract and builds hollow, vaulted stone gates.
const VERSION := 2
const WATER_BANK_CLEARANCE := 11.8 # Genesis water is 5.4m wide; bank erosion extends to 9m.
const ABUTMENT_WIDTH := 1.8
const ROAD_BUFFER := 2.4
const MIN_CROSS_ANGLE := 0.28
const MAX_SPAN := 94.0
const Kit = preload("res://godot/modular_kit.gd")

static func _distance(p: Vector2,a: Vector2,b: Vector2) -> float:
 return p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))

static func _water_surface(river: Dictionary,hub: Vector2,p: Vector2) -> float:
 var way: Vector2=river.p-hub
 if way.length_squared()<.0001:return NAN
 return lerpf(float(river.hub_height),float(river.height),clampf((p-hub).dot(way)/way.length_squared(),0.0,1.0))

static func _fail(reason: String,opening: Dictionary) -> Dictionary:
 return {"ok":false,"reason":reason,"point":opening.point,"width":float(opening.width),"source":opening.source}

static func _ring_distance(a: float,b: float,around: float) -> float:
 return absf(fposmod(a-b+around*.5,around)-around*.5)

static func plan(opening: Dictionary,river: Dictionary,hub: Vector2,roads: Array,polygon_dist: Array,perimeter: float,height: Callable) -> Dictionary:
 var center: Vector2=opening.point
 var tangent: Vector2=opening.tangent.normalized()
 var full_width: float=float(opening.width)
 var direction: Vector2=(river.p-hub).normalized()
 var sine: float=absf(tangent.cross(direction))
 if sine<MIN_CROSS_ANGLE:return _fail("river_almost_parallel_to_wall",opening)
 if full_width>MAX_SPAN or full_width<12.0:return _fail("unsupported_river_span",opening)
 # A single straight arch cannot turn at a polygon corner. Keep this case BLOCKED.
 for k in range(1,polygon_dist.size()-1):
  if _ring_distance(float(opening.s),float(polygon_dist[k]),perimeter)<full_width*.5+1.75:
   return _fail("arch_crosses_perimeter_corner",opening)
 var water_level: float=_water_surface(river,hub,center)
 if not is_finite(water_level):return _fail("invalid_hydrology",opening)
 var half_width: float=full_width*.5
 var banks: Array=[]
 for sign_value in [-1.0,1.0]:
  var p: Vector2=center+tangent*sign_value*half_width
  if _distance(p,hub,river.p)<WATER_BANK_CLEARANCE-.5:
   return _fail("pier_in_river_buffer",opening)
  for road in roads:
   if _distance(p,road.a,road.b)<float(road.width)*.5+ROAD_BUFFER:
    return _fail("abutment_blocks_road",opening)
  var samples: Array=[]
  for d in [-1.0,0.0,1.0]:
   var h: float=float(height.call(p+tangent*d))
   if not is_finite(h):return _fail("nonfinite_bank",opening)
   samples.append(h)
  var bottom: float=minf(float(samples[0]),minf(float(samples[1]),float(samples[2])))
  var top: float=maxf(float(samples[0]),maxf(float(samples[1]),float(samples[2])))
  if top-bottom>2.4:return _fail("unstable_bank_slope",opening)
  if bottom<water_level+.75:return _fail("submerged_bank",opening)
  banks.append({"point":p,"ground":bottom,"high":top})
 # No vertical fill, abutment, or collision intersects the river below the clearance arch.
 # Monumental structures use parallel vaulted masonry ribs if dry islands are absent.
 var variant: String="small" if full_width<=27.0 else "medium" if full_width<=44.0 else "monumental"
 var deck_y: float=maxf(maxf(float(banks[0].high),float(banks[1].high))+7.8,water_level+9.3)
 # Shared road/river gates need pedestrian headroom over the original road.
 var clearances: Array=[]
 for road in roads:
  var closest: Vector2=Geometry2D.get_closest_point_to_segment(center,road.a,road.b)
  if closest.distance_to(center)>full_width:continue
  for step in range(int(ceil(full_width))+1):
   var x: float=lerpf(-half_width,half_width,float(step)/ceil(full_width))
   var sample: Vector2=center+tangent*x
   if _distance(sample,road.a,road.b)<float(road.width)*.5+ROAD_BUFFER:
    var ceiling: float=float(height.call(sample))+3.4
    clearances.append({"x":x,"height":ceiling})
    deck_y=maxf(deck_y,ceiling+2.0)
 var piers: Array=[]
 if variant=="monumental":
  for frac in [-.18,.18]:
   var p: Vector2=center+tangent*full_width*frac
   var h: float=float(height.call(p))
   # Permanent intermediate columns are permitted only on genuine dry islands.
   if is_finite(h) and h>=water_level+1.8 and _distance(p,hub,river.p)>WATER_BANK_CLEARANCE:
    var blocked:=false
    for road in roads:
     if _distance(p,road.a,road.b)<float(road.width)*.5+ROAD_BUFFER:blocked=true;break
    if not blocked:piers.append({"point":p,"ground":h})
 var span_ends: Array=[-half_width]
 for pier in piers:span_ends.append((pier.point-center).dot(tangent))
 span_ends.append(half_width);span_ends.sort()
 var arch_spans: Array=[]
 for k in range(span_ends.size()-1):
  arch_spans.append({"start":float(span_ends[k]),"end":float(span_ends[k+1])})
 return {"ok":true,"version":VERSION,"kind":"exo_river_gate","variant":variant,
  "source":opening.source,"point":center,"tangent":tangent,"flow":direction,
  "width":full_width,"road_clearances":clearances,"water_level":water_level,"deck_y":deck_y,"banks":banks,
  "piers":piers,"arch_spans":arch_spans,"clearance_above_water":3.6,"river_index":opening.get("river_index",-1)}

static func _cutoff(plan: Dictionary,x: float,mid: float,radius: float,half_piece: float) -> float:
 var cutoff: float=float(plan.water_level)+3.6+3.15*sqrt(maxf(0.0,1.0-pow((x-mid)/radius,2.0)))
 for road in plan.get("road_clearances",[]):
  if absf(float(road.x)-x)<half_piece+1.0:cutoff=maxf(cutoff,float(road.height))
 return cutoff

static func _chunk(chunks: Array,pos: Vector3,size: Vector3) -> void:
 if size.x>.02 and size.y>.02 and size.z>.02:chunks.append({"at":pos,"size":size})

static func _batch(holder: Node3D,chunks: Array,material: Material,collision: bool=true) -> void:
 if chunks.is_empty():return
 var mesh:=BoxMesh.new();mesh.size=Vector3.ONE
 var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=mesh
 multi.instance_count=chunks.size()
 var node:=MultiMeshInstance3D.new();node.multimesh=multi;node.material_override=material
 node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;holder.add_child(node)
 var body: StaticBody3D
 if collision:
  body=StaticBody3D.new();body.collision_layer=4;body.name="RiverStoneColliders";holder.add_child(body)
 for i in range(chunks.size()):
  var part: Dictionary=chunks[i]
  multi.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(part.size),part.at))
  if collision:
   var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=part.size
   shape.shape=box;shape.position=part.at;body.add_child(shape)

static func build(parent: Node3D,plan: Dictionary) -> Dictionary:
 if not bool(plan.get("ok",false)):return {"ok":false,"reason":plan.get("reason","invalid")}
 var holder:=Node3D.new();holder.name="EXO_RiverGate_%s"%str(plan.source).replace(":","_")
 parent.add_child(holder)
 holder.set_meta("exo_river_gate_version",VERSION)
 holder.set_meta("water_level",plan.water_level)
 holder.set_meta("opening_width_m",plan.width)
 holder.set_meta("river_source",plan.source)
 var p: Vector2=plan.point;var tangent: Vector2=plan.tangent
 holder.position=Vector3(p.x,0,p.y)
 holder.rotation.y=-atan2(tangent.y,tangent.x)
 var width: float=float(plan.width);var half_width:=width*.5
 var deck: float=float(plan.deck_y);var water: float=float(plan.water_level)
 var blocks: Array=[];var trims: Array=[]
 # The arch is hollow, with 2m voxel voussoirs. All stone over water sits >3.6m above it.
 var depth:=2.6 if plan.variant=="small" else 3.2 if plan.variant=="medium" else 4.0
 for arch in plan.arch_spans:
  var left: float=float(arch.start);var right: float=float(arch.end)
  var mid: float=(left+right)*.5;var radius: float=maxf(.1,(right-left)*.5)
  var count:=maxi(4,int(ceil((right-left)/1.9)))
  for i in range(count):
   var xa: float=lerpf(left,right,float(i)/count)
   var xb: float=lerpf(left,right,float(i+1)/count)
   var x: float=(xa+xb)*.5
   var cutoff: float=_cutoff(plan,x,mid,radius,(xb-xa)*.5)
   var vault_top: float=deck-1.15
   _chunk(blocks,Vector3(x,(cutoff+vault_top)*.5,0),Vector3(xb-xa,maxf(.12,vault_top-cutoff),depth))
   if i%3==0:_chunk(trims,Vector3(x,cutoff+.19,0),Vector3(xb-xa,.38,depth+.3))
 # Modular upper patrol path; multi-instanced segments, not stretched imported GLBs.
 var deck_sections:=maxi(1,int(ceil((width+2.0)/2.0)))
 for i in range(deck_sections):
  var xa: float=lerpf(-half_width-1.0,half_width+1.0,float(i)/deck_sections)
  var xb: float=lerpf(-half_width-1.0,half_width+1.0,float(i+1)/deck_sections)
  var xc: float=(xa+xb)*.5
  _chunk(blocks,Vector3(xc,deck-.57,0),Vector3(xb-xa,1.16,depth))
  for z in [-depth*.5+.25,depth*.5-.25]:
   _chunk(trims,Vector3(xc,deck+.45,z),Vector3(xb-xa,.9,.43))
   if i%2==0:_chunk(trims,Vector3(xc,deck+1.2,z),Vector3((xb-xa)*.62,.65,.55))
 for bank in plan.banks:
  var x: float=(bank.point-p).dot(tangent)
  var base: float=float(bank.ground)-.55
  _chunk(blocks,Vector3(x,(base+deck)*.5,0),Vector3(ABUTMENT_WIDTH,deck-base,depth+1.4))
  _chunk(trims,Vector3(x,deck+.65,0),Vector3(2.3,1.6,depth+1.8))
 # Optional piers only over real dry islands; NONE are synthesized inside wet channels.
 for pier in plan.piers:
  var x: float=(pier.point-p).dot(tangent)
  var base: float=float(pier.ground)-.6
  _chunk(blocks,Vector3(x,(base+deck)*.5,0),Vector3(1.55,deck-base,depth))
 # Monumental two-/three-rib vaulted detail runs parallel to the current, and is
 # explicitly used when transverse intermediate pylons cannot be founded.
 if plan.variant=="monumental":
  for z in [-depth*.5-.46,depth*.5+.46]:
   for arch in plan.arch_spans:
    var left: float=float(arch.start);var right: float=float(arch.end)
    var mid: float=(left+right)*.5;var radius: float=maxf(.1,(right-left)*.5)
    var count:=maxi(4,int(ceil((right-left)/2.0)))
    for i in range(count):
     var x: float=lerpf(left,right,(float(i)+.5)/count)
     var inner: float=_cutoff(plan,x,mid,radius,(right-left)/count*.5)
     _chunk(trims,Vector3(x,inner+.43,z),Vector3((right-left)/count,.86,.66))
 var stone:=StandardMaterial3D.new();stone.albedo_color=Color("77756e");stone.roughness=.94
 var trim:=StandardMaterial3D.new();trim.albedo_color=Color("a5a196");trim.roughness=.9
 _batch(holder,blocks,stone,true)
 _batch(holder,trims,trim,false)
 # Reuse native Forja 03 battlements at both wall-connection shoulders; never
 # stretch an imported arch model. Their collision is managed by the batch above.
 for sign_value in [-1.0,1.0]:
  var x: float=sign_value*(half_width-.6)
  var asset: Node3D=Kit.place(holder,"city_wall_battlement_2m",Vector3(x,deck+.03,0),0.0,"",false)
  asset.scale=Vector3(.72,.65,.9)
  asset.set_meta("river_gate_shoulders",true)
 # Existing Forja stone towers are optional, dry-bank-only modules.
 if plan.variant=="monumental":
  for bank in plan.banks:
   var x: float=(bank.point-p).dot(tangent)
   var tower: Node3D=Kit.place(holder,"watchtower_stone_4m",Vector3(x,float(bank.ground),0),0.0,"",false)
   tower.set_meta("river_gate_watchtower",true)
 return {"ok":true,"node":holder,"kind":plan.variant,"arches":plan.arch_spans.size(),"chunks":blocks.size(),"dry_piers":plan.piers.size()}
