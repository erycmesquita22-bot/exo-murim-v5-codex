extends RefCounted
## Forja/Monumental opcional: Dungeon Genesis decide FORMA e finalidade da sala.
## Sem kits da Forja, a dungeon continua gerando pisos, paredes e navegação.
## Nunca espalhar adereços aleatórios: selecionar somente peças contextuais.
const FIT:={
 "ruins":{"entrance":"stone_garden_lantern","shrine":"stone_garden_lantern"},
 "cavern":{},
 "temple":{"entrance":"lantern_01","shrine":"bronze_incense_burner"},
 "sect_hideout":{"training":"silk_vertical_banner"},
 "mine":{"treasure":"timber_handcart"},
 "tomb":{"shrine":"bronze_incense_burner"}
}
static func _official_ids() -> Dictionary:
 var ids: Dictionary={}
 for path in ["res://catalog.json","res://forja/catalog_v3.json"]:
  if not FileAccess.file_exists(path):continue
  var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
  if not parsed is Dictionary or not parsed.get("assets") is Array:continue
  for record in parsed.assets:
   if record is Dictionary and record.has("id") and record.has("file"):
    ids[str(record.id)]=str(record.file)
 return ids
static func decorate(root: Node3D,plan: Dictionary) -> Dictionary:
 if not ResourceLoader.exists("res://godot/modular_kit.gd"):
  return {"status":"SKIPPED","reason":"forja_kit_absent"}
 var known: Dictionary=_official_ids()
 if known.is_empty():return {"status":"SKIPPED","reason":"forja_catalog_absent"}
 var family: String=str(plan.request.family)
 var placements: Dictionary=FIT.get(family,{})
 if placements.is_empty():return {"status":"SKIPPED","reason":"no_contextual_assets"}
 var kit: Variant=load("res://godot/modular_kit.gd")
 kit.call("ensure")
 var placed:=0
 var skipped:=0
 for room in plan.rooms:
  var context: String=str(room.kind)
  if not placements.has(context):continue
  var asset_id: String=str(placements[context])
  if not known.has(asset_id) or not ResourceLoader.exists("res://"+str(known[asset_id])):
   skipped+=1
   continue
  # Nicho lateral, nunca no eixo central de deslocamento e sem colisão no decorador.
  var margin: float=maxf(3.0,float(room.width)*0.5-3.5)
  var position:=Vector3(float(room.cx)+margin,float(room.floor)*float(plan.get("render_metrics",{}).get("floor_height",12.0)),float(room.cz)+margin)
  kit.call("place",root,asset_id,position,0.0,"",false)
  placed+=1
 return {"status":"ADDED","placed":placed,"skipped":skipped,"collision":"disabled","author":"official_forja_catalog"}
