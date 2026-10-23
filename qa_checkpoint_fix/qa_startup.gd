extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var w: Variant=load("res://convergence/game.gd").new()
	w.load_on_start=false
	w.save_path="user://qa_ui_boot_fixture.json"
	w.world_seed_override=101
	root.add_child(w)
	await process_frame
	var hero_paused: bool=paused
	# Simulate an already-restored adventure without modifying normal startup.
	w.journey.data.character={"name":"QA Boot","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0,"weapon":"sword","element":6}
	w.journey.data.phase="adventure"
	w.flow.phase="adventure"
	w.ui.boot()
	var adventure_running: bool=not paused
	var menu_hidden: bool=not w.ui.menu.visible
	var flow_hidden: bool=not w.ui.flow_screen.visible
	print("EXO_STARTUP_QA ",JSON.stringify({"hero_paused":hero_paused,"adventure_running":adventure_running,"pause_menu_hidden":menu_hidden,"flow_screen_hidden":flow_hidden}))
	w.free()
	paused=false
	quit(0 if hero_paused and adventure_running and menu_hidden and flow_hidden else 1)
