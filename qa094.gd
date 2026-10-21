extends SceneTree
const WorldSeed=preload("res://procedural/world_state.gd")
const Plan=preload("res://world/biome_plan.gd")
var errors: Array[String]=[]
func check(value: bool,description: String) -> void:
	if not value:errors.append(description)
func _initialize() -> void:
	var seen: Dictionary={}
	var layouts: Dictionary={}
	for n in range(400):
		var w: Dictionary=WorldSeed.create(n,"world_test_%d"%n)
		var a: Dictionary=Plan.create(w)
		var b: Dictionary=Plan.create(w.duplicate(true))
		check(WorldSeed.valid(w),"identidade de mundo inválida")
		check(a==b,"seed não determinística: "+str(n))
		check(Plan.safe_layout(a),"lotes inválidos: "+str(n))
		check(a.houses.size()==(2 if a.kind=="empobrecida" else 4 if a.kind=="comum" else 7 if a.kind=="prospera" else 5),"quantidade de lotes incorreta")
		seen[a.kind]=true
		layouts[JSON.stringify(a.houses)]=true
	check(seen.size()==4,"nem todos os quatro perfis aparecem nas 400 seeds testadas")
	check(layouts.size()>200,"vila não varia suficientemente entre seeds")
	var legacy: Dictionary=WorldSeed.create(6412,"world_legacy_test")
	check(Plan.safe_layout(Plan.create(legacy)),"seed legada sem layout")
	if errors.is_empty():print("QA094 PASS • 400 seeds, quatro perfis, lotes estáveis, mundo legado")
	else:
		for e in errors:push_error(e)
		print("QA094 FAIL • ",errors.size()," erros")
	quit(0 if errors.is_empty() else 1)
