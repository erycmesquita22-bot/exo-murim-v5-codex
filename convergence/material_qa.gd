extends SceneTree
func _initialize():call_deferred("run")
func run():
	var kit=preload("res://godot/modular_kit.gd")
	var parent:=Node3D.new();root.add_child(parent)
	var part: Node3D=kit.place(parent,"silk_vertical_banner",Vector3.ZERO,0,"gray_jade",false)
	var colors: Dictionary={}
	for mesh in part.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var m: Material=mesh.get_active_material(i)
			if m is StandardMaterial3D:colors[m.albedo_color.to_html()]=true
	var ok: bool=colors.size()>=3
	print("MATERIAL012 ",ok," distinct banner colors=",colors.keys())
	var initial_cache: int=kit.cached.size()
	parent.free();await process_frame
	for i in range(8):
		var holder:=Node3D.new();root.add_child(holder)
		kit.place(holder,"silk_vertical_banner",Vector3.ZERO,0,"gray_jade",false);holder.free();await process_frame
	ok=ok and kit.cached.size()==initial_cache
	print("MATERIAL_CACHE_REVISIT ",ok," size=",kit.cached.size()," initial=",initial_cache)
	quit(int(not ok))
