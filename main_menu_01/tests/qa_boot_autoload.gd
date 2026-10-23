extends SceneTree

func _initialize() -> void:
    call_deferred("_qa_run")

func _qa_run() -> void:
    var startup: PackedScene = load("res://main_menu_01/main_menu.tscn")
    var menu_scene: Control = startup.instantiate()
    root.add_child(menu_scene)
    current_scene = menu_scene
    await process_frame
    await process_frame
    var issues: Array = []
    var menu: Node = current_scene
    if menu == null or menu.name != "EXOMurimMainMenu":
        issues.append("no_menu")
    else:
        if menu.buttons.size()!=5:issues.append("buttons")
        for i in range(5):
            if menu.buttons[i].texture_normal==null or menu.buttons[i].texture_hover==null:issues.append("sprite_missing_%d"%i)
        menu._show_settings()
        if not menu.modal.visible:issues.append("settings_missing")
        menu._close_panel()
        if menu.modal.visible:issues.append("settings_not_closed")
        menu._show_load()
        if not menu.modal.visible:issues.append("load_missing")
        menu._close_panel()
        if menu.modal.visible:issues.append("load_not_closed")
        menu._begin_game("new")
        if not menu.loading_panel.visible:issues.append("real_loading_screen_missing")
        for i in range(360):
            if current_scene != menu and current_scene != null:break
            await process_frame
        var game: Node = current_scene
        if game == null or game.name == "EXOMurimMainMenu":issues.append("new_scene_missing")
        else:
            if str(game.journey.data.phase)!="hero":issues.append("not_new_journey")
            if not paused:issues.append("creation_not_paused")
            if not game.ui.flow_screen.visible:issues.append("creator_not_visible")
            if game.ui.menu.visible:issues.append("pause_menu_overlap")
            if game.ui.modal.visible:issues.append("dialogue_overlap")
        print("EXO_MENU_BOOT_QA ",JSON.stringify({"issues":issues,"phase":str(game.journey.data.phase) if game!=null and game!=menu else "missing","scene":str(game.name) if game!=null else "missing","paused":paused}))
    quit(0 if issues.is_empty() else 1)
