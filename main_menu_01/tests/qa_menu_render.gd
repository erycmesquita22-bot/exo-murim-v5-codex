extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var menu: Control = load("res://main_menu_01/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene = menu
    await process_frame
    await process_frame
    await process_frame
    var ok: bool = menu.buttons.size()==5 and menu.modal.visible == false and menu.wallpaper.texture != null
    var pixel: Image = root.get_texture().get_image()
    var result: Error = pixel.save_png("res://main_menu_01/tests/qa_menu_snapshot.png")
    menu._show_settings()
    await process_frame
    await process_frame
    var settings_capture: Error = root.get_texture().get_image().save_png("res://main_menu_01/tests/qa_settings_snapshot.png")
    menu._close_panel()
    print("EXO_MENU_RENDER ", JSON.stringify({"ok":ok,"screenshot_error":result,"settings_screenshot_error":settings_capture,"size":[pixel.get_width(),pixel.get_height()],"buttons":menu.buttons.size(),"scene":str(current_scene.name)}))
    quit(0 if ok and result==OK else 1)
