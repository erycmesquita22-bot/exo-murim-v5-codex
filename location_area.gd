extends Area3D
var world: Node3D
var caption: String
func setup(w: Node3D,point: Vector3,text_value: String,size_value: Vector3=Vector3(3,3,2.5)) -> void:
	world=w
	caption=text_value
	position=point+Vector3(0,1,0)
	collision_layer=0
	collision_mask=2
	monitoring=true
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=size_value
	shape.shape=box
	add_child(shape)
	body_entered.connect(func(body):
		if body==world.player and is_instance_valid(world.ui):world.ui.set_location(caption))
	body_exited.connect(func(body):
		if body==world.player and is_instance_valid(world.ui):world.ui.set_location(""))
