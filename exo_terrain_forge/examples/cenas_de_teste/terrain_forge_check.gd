extends Node
func _ready() -> void:
 var Adapter=load("res://exo_terrain_forge/worldgen/terrain_texture_adapter.gd")
 var m: Dictionary=Adapter.read_manifest()
 assert(str(m.get("schema",""))=="exo.terrain.texture_forge.v1")
 assert(m.get("materials",[]).size()==36)
 for item in m.materials:
  assert(ResourceLoader.exists(item.path),"Resource missing: "+str(item.path))
  assert(load(item.path)!=null)
 for atlas in m.runtime_atlases.values():
  assert(ResourceLoader.exists(atlas.path))
 print("EXO TERRAIN FORGE: 36 assets + 5 atlases; asset import PASS")
 get_tree().quit()
