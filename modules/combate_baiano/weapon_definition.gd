extends Resource
@export var weapon_id := "murim_training_sword"
@export var blade_scene := "res://modules/combate_baiano/assets/Training_Sword_Blade.glb"
@export var damage_01 := 20
@export var damage_02 := 28
@export var damage_03 := 32
@export var query_radius := .13
@export var base_local := Vector3(0,-.13,0)
@export var tip_local := Vector3(0,-1.28,0)
@export var active_start := .22
@export var active_end := .60

func damage_for_clip(clip: String) -> int:
	if clip == "Sword_Attack_04": return 26
	if clip == "Sword_Attack_05": return 38
	return damage_03 if clip == "Sword_Attack_03" else (damage_02 if clip == "Sword_Attack_02" else damage_01)
