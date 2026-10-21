extends "res://enemy.gd"
var damage_total:=0
func step(delta: float) -> void:
	root_timer=maxf(0,root_timer-delta)
	slow=maxf(0,slow-delta)
	velocity=forced_velocity
	forced_velocity=forced_velocity.move_toward(Vector3.ZERO,delta*12)
	if not is_on_floor():
		velocity.y=-5
	move_and_slide()
	rig.pose(world.elapsed,false,false,true)
	if position.distance_to(home)>5:
		position=home
func hurt(amount: int,impulse: Vector3,slow_seconds: float=0.0,context: Dictionary={}) -> bool:
	damage_total+=amount
	hp=maxi(1,hp-amount)
	if hp<=1:
		hp=max_hp
	slow=maxf(slow,slow_seconds)
	apply_control(impulse,0)
	world.hits+=1
	world.target=self
	world.message("Alvo: −%d • total %d" % [amount,damage_total])
	world.audio_fx.impact("cloth",context)
	return true

func _ready() -> void:
	rig.hide()
	# Padded training post: contact material is cloth, rather than an invisible wooden humanoid.
	preload("res://wardrobe.gd").piece(self,Vector3(0,.7,0),Vector3(.17,1.4,.17),Color("594533"))
	preload("res://wardrobe.gd").piece(self,Vector3(0,1.15,0),Vector3(.7,1.1,.55),Color("6e5346"))
	for y in [.75,1.35]:preload("res://wardrobe.gd").piece(self,Vector3(0,y,0),Vector3(.73,.055,.58),Color("b59a6c"))
	preload("res://wardrobe.gd").piece(self,Vector3(0,.1,0),Vector3(1,.12,.7),Color("45382d"))
