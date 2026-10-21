extends RefCounted
static var materials:Dictionary={}
static func material(surface:String,focus:String="")->Material:
 var cache_key:String=surface+"/"+focus
 if materials.has(cache_key):return materials[cache_key]
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://exo_terrain_forge/worldgen/terrain_texture_manifest.json"))
 var wanted:String="stone_plaza_warm" if surface=="stone" else "dirt_clean"
 if surface=="stone":wanted=str({"fish":"stone_plaza_b","ferry":"stone_plaza_b","ore":"stone_path_c","sect":"stone_plaza_a","ritual":"stone_plaza_c","craft":"stone_path_a","guard":"stone_path_b"}.get(focus,wanted))
 else:wanted=str({"grain":"dirt_compacted","wood":"dirt_forest_litter","herbs":"dirt_warm_path","caravan":"dirt_trampled","fish":"dirt_riverbank"}.get(focus,wanted))
 var path:String=""
 for row in manifest.materials:
  if str(row.id)==wanted:path=str(row.get("optimized_path",row.path));break
 if not ResourceLoader.exists(path):
  for row in manifest.materials:
   if str(row.group)==surface:path=str(row.path);break
 var mat:=StandardMaterial3D.new();mat.albedo_texture=load(path);mat.roughness=1.0;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 materials[cache_key]=mat;return mat
# Liang-Barsky on the center line, inset by half the road width.
# Clipping the centerline preserves its direction and keeps the FULL strip inside.
static func _clip_segment(a:Vector2,b:Vector2,limit:float)->Dictionary:
 if not a.is_finite() or not b.is_finite() or not is_finite(limit) or limit<=0.0:return {"ok":false}
 var d:Vector2=b-a
 if not d.is_finite() or not is_finite(d.length_squared()) or d.length_squared()<0.01:return {"ok":false}
 var t0:float=0.0;var t1:float=1.0
 for constraint in [[-d.x,a.x+limit],[d.x,limit-a.x],[-d.y,a.y+limit],[d.y,limit-a.y]]:
  var q:float=constraint[0];var r:float=constraint[1]
  if absf(q)<0.000001:
   if r<0.0:return {"ok":false}
   continue
  var t:float=r/q
  if q<0.0:t0=maxf(t0,t)
  else:t1=minf(t1,t)
  if t0>t1:return {"ok":false}
 var start:Vector2=a+d*t0;var finish:Vector2=a+d*t1
 if not start.is_finite() or not finish.is_finite() or start.distance_squared_to(finish)<0.01:return {"ok":false}
 return {"ok":true,"a":start,"b":finish}

static func safe_strip(road:Dictionary,half:float)->Dictionary:
 var width:float=float(road.get("width",NAN))
 if not is_finite(width) or width<0.25 or not is_finite(half) or half<=0.5:return {"ok":false}
 if width>=2.0*(half-0.25) or not road.get("a") is Vector2 or not road.get("b") is Vector2:return {"ok":false}
 var clipped:Dictionary=_clip_segment(road.a,road.b,half-0.25-width*0.5)
 if not clipped.ok:return clipped
 var direction:Vector2=(clipped.b-clipped.a).normalized()
 clipped.side=Vector2(-direction.y,direction.x)*width*0.5
 clipped.clipped=clipped.a.distance_squared_to(road.a)>0.0001 or clipped.b.distance_squared_to(road.b)>0.0001
 return clipped

static func build(region:Node3D):
 var count:int=0;var clipped_count:int=0;var rejected_count:int=0
 var host:Node3D=region.get_meta("world_v4",null)
 var themes:Array=[];var focus:String=""
 if is_instance_valid(host):
  var context:Dictionary={"world_id":str(host.journey.data.world.id),"seed":int(host.journey.data.world.seed),"region_id":int(region.data.spec.id),"biome":str(region.data.spec.biome),"settlement_type":str(region.data.spec.settlement_scale),"player_tier":int(host.journey_manager.state().progress.level),"flags":[],"tags":[]}
  themes=host.activation_v4.consume("city_forge","city_theme/"+str(region.data.spec.id),["settlement_theme"],context)
  if not themes.is_empty():focus=str(themes[0].variables.get("service_focus",""))
 for road in region.data.settlement_roads:
  var strip:Dictionary=safe_strip(road,float(region.data.half))
  if not strip.ok:rejected_count+=1;continue
  var start:Vector2=strip.a;var finish:Vector2=strip.b;var side:Vector2=strip.side
  var n:int=maxi(1,int(ceil(start.distance_to(finish)/4.0)))
  if n>4096:rejected_count+=1;continue
  var vertices:PackedVector3Array=[]
  var valid:bool=true
  for k in range(n):
   var a:Vector2=start.lerp(finish,float(k)/n);var b:Vector2=start.lerp(finish,float(k+1)/n)
   for point in [a-side,a+side,b-side,a+side,b+side,b-side]:
    var h:float=region.data.height_at(point)+.045
    if not is_finite(h):valid=false;break
    vertices.append(Vector3(point.x,h,point.y))
   if not valid:break
  if not valid:rejected_count+=1;continue
  if strip.clipped:clipped_count+=1
  var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for vertex in vertices:
   st.set_normal(Vector3.UP);st.set_uv(Vector2(vertex.x,vertex.z)/4.0);st.add_vertex(vertex)
  var mesh:=MeshInstance3D.new();mesh.name="TerrainR3Pavement_%03d"%count;mesh.mesh=st.commit();mesh.material_override=material(str(road.get("surface","stone")),focus);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;region.add_child(mesh);count+=1
 if count>0 and not themes.is_empty():region.set_meta("library_material_consumed",themes[0].duplicate(true))
 region.set_meta("terrain_r3_pavements",{"roads":count,"clipped":clipped_count,"rejected":rejected_count,"source":"Terrain Forge R3","sector_surfaces":true})
