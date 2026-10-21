extends RefCounted
## Test-only canonical Wardrobe texture; never installed into a production region.
class TestResident:
	extends Node3D
	var rig:Node3D
	var identity:Dictionary={"id":"npc/r13/texture_test"}
static func install(parent:Node3D):
	var actor:=TestResident.new();parent.add_child(actor)
	actor.rig=preload("res://rig.gd").new();actor.add_child(actor.rig)
	preload("res://wardrobe.gd").apply(actor.rig,{"race":0,"skin":0,"hair":0,"robe":1,"weapon":"sword"})
	preload("res://exo_crowd_illusion/visuals/shared_npc_skins.gd").capture(parent,[actor])
	actor.free()
