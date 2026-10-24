extends Node
var maximum := 120
var hp := 120
var stamina := 100.0
var stun := 0.0
var freeze := 0.0
var dead := false
var blocking := false
var block_time := 10.0
var hurt_count := 0
var block_count := 0
var evade_count := 0
var parry_count := 0
func tick(delta: float) -> void:
	stun = maxf(0,stun-delta)
	freeze = maxf(0,freeze-delta)
	if blocking: block_time += delta
	else:
		block_time = 10.0
		stamina = minf(100,stamina+delta*22)
func set_guard(value: bool) -> void:
	if value and not blocking: block_time = 0
	blocking = value and not dead
func reset() -> void:
	hp = maximum
	stamina = 100
	stun = 0
	freeze = 0
	dead = false
	blocking = false
	block_time = 10
