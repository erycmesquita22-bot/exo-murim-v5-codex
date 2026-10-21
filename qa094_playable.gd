extends SceneTree
# Headless smoke test: launch the actual game scene and inspect world and its sites.
var failed:=false
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var scene: PackedScene=load("res://main.tscn")
	if scene==null:push_error("Cena principal indisponível");quit(1);return
	var game: Node3D=scene.instantiate()
	root.add_child(game)
	if game.get_node_or_null("TerrainCollider09_4")==null:push_error("Colisão do novo terreno ausente");failed=true
	if game.get_node_or_null("PersistentTerrain09_4")==null:push_error("Malha do novo terreno ausente");failed=true
	if game.exploration_sites.size()!=3:push_error("Marcos procedurais indisponíveis");failed=true
	var previous: Dictionary=game.journey.data.world.duplicate(true)
	game.journey.data.world=preload("res://procedural/world_state.gd").create(12345,"world_test_094")
	game.rebuild_region()
	var a: Dictionary=game.get_meta("landscape_plan")
	game.rebuild_region()
	var b: Dictionary=game.get_meta("landscape_plan")
	if a!=b:push_error("Recriação do terreno mudou a vila com mesma seed");failed=true
	if game.exploration_sites.size()!=3:push_error("Recriação duplicou/perdeu marcos");failed=true
	game.journey.data.world=previous
	print("QA094 playable ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
