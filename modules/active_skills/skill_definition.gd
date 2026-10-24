extends Resource
## Stable data contract. Duplicate a .tres and keep IDs unique to add a skill.
@export var skill_id: StringName
@export var display_name: String
@export_enum("Punho", "Qi", "Espada") var school: String = "Punho"
@export_enum("fist", "projectile", "blade") var delivery: String = "fist"
@export_multiline var description: String
@export var animation: StringName
@export var damage := 24
@export var qi_cost := 8.0
@export var cooldown := 2.0
@export_range(0,1) var active_start := .30
@export_range(0,1) var active_end := .56
@export var query_radius := .16
@export var lunge_distance := .42
@export var projectile_speed := 12.0
@export var projectile_range := 14.0
@export var effect_color := Color(.7,.9,1)
func damage_for_clip(_clip: String) -> int: return damage
func is_valid_definition() -> bool:
	return not str(skill_id).is_empty() and not str(animation).is_empty() and damage > 0 and qi_cost >= 0 and cooldown > 0 and active_start >= 0 and active_end <= 1 and active_end > active_start and query_radius > 0 and projectile_speed > 0 and projectile_range > 0
