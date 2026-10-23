extends SceneTree
const OLD = preload("res://exo_settlement_forge/runtime/legacy_architecture_builder_qa.gd")
const NEW = preload("res://exo_settlement_forge/runtime/architecture_builder.gd")
func _initialize() -> void:call_deferred("run")
func measure(builder: Script,count: int) -> Dictionary:
	var holder := Node3D.new()
	root.add_child(holder)
	var begin := Time.get_ticks_usec()
	var made: Array=[]
	for i in range(count):
		var record: Dictionary={"accessible":true,"building_id":"house_%02d"%i,"function":"residence","dimensions":[10.0,5.8,10.0],"position":[float(i%8)*15,0,float(i/8)*15],"yaw":0.0}
		made.append(builder.build(holder,record))
	var elapsed := (Time.get_ticks_usec()-begin)/1000.0
	var nodes: int=0;var meshes:int=0;var bodies:int=0;var shape_count:int=0
	var pending: Array=[holder]
	while not pending.is_empty():
		var item: Node=pending.pop_back()
		nodes+=1
		if item is MeshInstance3D:meshes+=1
		if item is StaticBody3D:bodies+=1
		if item is CollisionShape3D:shape_count+=1
		for child in item.get_children():pending.append(child)
	var result := {"ms":elapsed,"nodes":nodes,"meshes":meshes,"bodies":bodies,"shapes":shape_count,"houses":count}
	holder.free()
	return result
func run() -> void:
	var baseline := measure(OLD,47)
	var candidate := measure(NEW,47)
	print("EXO_AC_AB ",JSON.stringify({"old":baseline,"new":candidate}))
	if candidate.meshes >= baseline.meshes or candidate.bodies >= baseline.bodies:quit(2)
	else:quit(0)
