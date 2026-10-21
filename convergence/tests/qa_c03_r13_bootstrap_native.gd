extends SceneTree
# Godot 4.6.2 native HEADLESS bootstrap smoke; NOT a substitute for F5 gameplay.
# Run inside an isolated QA user:// namespace only. It does NOT create a campaign.
var checks: int = 0
var failures: Array[String] = []

func _check(ok: bool, context: String) -> void:
	checks += 1
	if not ok:
		failures.append(context)
		push_error("C03_R13_BOOT_FAIL " + context)

func _initialize() -> void:
	call_deferred("_execute")

func _execute() -> void:
	var cfg: String = str(ProjectSettings.get_setting("application/config/custom_user_dir_name", ""))
	_check(cfg == "EXO-Murim-Convergencia-03-ALFA-R13-QA", "R13 save isolation")
	var packed: PackedScene = load("res://convergence/game.tscn") as PackedScene
	_check(packed != null, "load main PackedScene")
	if packed == null:
		_complete()
		return
	var game: Node = packed.instantiate()
	_check(game != null and game.has_method("ensure_atlas"), "instantiate Convergence 03 host")
	if game == null:
		_complete()
		return
	root.add_child(game)
	await process_frame
	await process_frame
	_check(game.get("exo_core") != null, "Core initialized")
	var core: Variant = game.get("exo_core")
	if core != null:
		_check(bool(core.get("ready")), "Core boot is ready")
	_check(game.get("player") is CharacterBody3D, "real player body initialized")
	_check(game.get("flow") != null, "character creation flow initialized")
	_check(game.get("journey") != null, "single JourneySave present")
	_check(game.has_method("change_region"), "procedural travel entrypoint")
	# Deliberately do not create/save a campaign or claim F5 smoke validates travel.
	game.queue_free()
	await process_frame
	_complete()

func _complete() -> void:
	print("C03_R13_NATIVE_BOOT ", JSON.stringify({"checks":checks, "failed":failures,
		"godot":Engine.get_version_info().get("string",""),"class":"HEADLESS_BOOT_ONLY_NOT_GAMEPLAY"}))
	quit(0 if failures.is_empty() else 1)
