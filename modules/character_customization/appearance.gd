extends RefCounted
## Shared visual contract for V4-derived humanoids. Never edits the approved GLB.
const FACES := {
 "original":"",
 "river_watch":"res://modules/character_customization/faces/river_watch.png",
 "river_worker":"res://modules/character_customization/faces/river_worker.png",
 "jetty_keeper":"res://modules/character_customization/faces/jetty_keeper.png",
 "market_local":"res://modules/character_customization/faces/market_local.png",
 "tea_attendant":"res://modules/character_customization/faces/tea_attendant.png"
}
static func proportions(profile: Dictionary) -> Vector3:
 var body: Dictionary = profile.get("body_style",{})
 return Vector3(clampf(float(body.get("width",1.0)),.92,1.08),clampf(float(body.get("height",1.0)),.94,1.06),clampf(float(body.get("depth",1.0)),.93,1.07))
static func apply_to_visual(visual: Node3D, profile: Dictionary) -> void:
 var apparel: Dictionary = profile.get("apparel",{})
 var hair: Dictionary = profile.get("hair",{})
 var style := str(hair.get("style","low_tail"))
 var face_id := str(profile.get("face","original"))
 var npc_face_path := str(profile.get("face_path",""))
 visual.scale = proportions(profile)
 for mesh in visual.find_children("*","MeshInstance3D",true,false):
  var part := String(mesh.name)
  if part.begins_with("ACCESSORY_sword"):
   mesh.visible = not bool(profile.get("hide_embedded_sword",true))
   continue
  if part.begins_with("HAIR_ponytail"):
   mesh.visible = style in ["low_tail","high_tail","compact_tail","half_up","long_tail","silver_bun"]
   mesh.scale = Vector3.ONE * (0.43 if style=="silver_bun" else (0.52 if style=="compact_tail" else (1.13 if style=="long_tail" else (0.82 if style in ["low_tail","half_up"] else 1.04))))
  elif part.begins_with("HAIR_side_locks"):
   mesh.visible = style in ["low_tail","loose_short","high_tail","half_up","long_tail","swept"]
  if part.begins_with("HEAD_skin"):
   var texture_path := npc_face_path if npc_face_path.begins_with("res://modules/village_life/npc_faces/") else str(FACES.get(face_id,""))
   if texture_path == "":
    mesh.material_override = null
    continue
   var face_material: StandardMaterial3D = mesh.mesh.surface_get_material(0).duplicate()
   face_material.albedo_texture = load(texture_path)
   mesh.material_override = face_material
   continue
  var tone := ""
  if part.begins_with("HAIR") or part.begins_with("HEAD_hair"):
   tone = str(hair.get("color",""))
  elif part.begins_with("BODY_outer") or part.begins_with("SKIRT"):
   tone = str(apparel.get("outer",""))
  elif part.begins_with("BODY_tunic") or part.begins_with("ARM"):
   tone = str(apparel.get("tunic",""))
  elif part.begins_with("FRONT") or part.begins_with("SASH"):
   tone = str(apparel.get("sash",""))
  elif part.begins_with("LEG"):
   tone = str(apparel.get("trousers",""))
  if tone == "": continue
  var base: Material = mesh.mesh.surface_get_material(0)
  if base is StandardMaterial3D:
   var variant: StandardMaterial3D = base.duplicate()
   if (part.begins_with("HAIR") or part.begins_with("HEAD_hair")) and npc_face_path.begins_with("res://modules/village_life/npc_faces/"):
    variant.albedo_texture = load(npc_face_path)
    variant.albedo_color = Color.WHITE
   else: variant.albedo_color = Color(tone)
   mesh.material_override = variant
