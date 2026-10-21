extends RefCounted
# Park-Miller v1: explicitly pinned integer algorithm; independent of Godot/global RNG state.
const MODULUS=2147483647
var state: int
func _init(seed_value: int) -> void:state=posmod(seed_value,MODULUS-1)+1
func next() -> int:
	state=(state*48271)%MODULUS
	return state
func below(count: int) -> int:return next()%maxi(1,count)
func unit() -> float:return float(next()-1)/float(MODULUS-1)
func between(low: float,high: float) -> float:return lerpf(low,high,unit())
static func hash_value(text_value: String) -> int:return text_value.sha256_text().substr(0,8).hex_to_int()%(MODULUS-1)
