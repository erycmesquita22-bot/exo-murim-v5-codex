extends Node3D
## Laboratório de inspeção. Controles: 1-6 famílias, R nova seed, Q/E muda piso, setas orbitam.
const Generator=preload("res://exo_dungeon/generator/dungeon_generator.gd")
const Instance=preload("res://exo_dungeon/runtime/dungeon_instance.gd")
var families: Array=["ruins","cavern","temple","sect_hideout","mine","tomb"]
var family_index:=0;var variation:=1;var floor_view:=0
var dungeon: Node3D;var camera: Camera3D;var status: Label
func _ready() -> void:
 var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("#1d242b");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("#d6d9e0");env.ambient_light_energy=0.65;world.environment=env;add_child(world)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-30,0);sun.light_energy=1.4;add_child(sun)
 camera=Camera3D.new();add_child(camera);camera.current=true;camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=140
 var hud:=CanvasLayer.new();add_child(hud);status=Label.new();status.position=Vector2(24,22);status.add_theme_font_size_override("font_size",20);hud.add_child(status)
 _refresh()
func _refresh() -> void:
 if is_instance_valid(dungeon):dungeon.queue_free()
 var plan: Dictionary=Generator.generate({"world_id":"QA_WORLD","world_seed":variation,"region_id":14,"location_id":"QA_DEMO","family":families[family_index],"floors":2,"rooms_per_floor":12,"difficulty":4})
 if not bool(plan.ok):status.text="FALHA: "+str(plan);return
 dungeon=Instance.new();add_child(dungeon)
 if not dungeon.materialize(plan):status.text="FALHA NA MATERIALIZAÇÃO";return
 _camera_at()
 status.text="EXO Dungeon Genesis 01 — LABORATÓRIO ORIGINAL (não é captura do jogo)\nFamília: %s  |  Seed: %d  |  Piso: %d  |  Salas: %d  |  Hash: %s\nTeclas 1-6: família  |  R: seed  |  Q/E: piso" % [families[family_index],variation,floor_view,plan.rooms.size(),str(plan.digest).substr(0,12)]
func _camera_at() -> void:
 var target:=Vector3(0,floor_view*9.0,0)
 camera.position=target+Vector3(90,105,90);camera.look_at(target)
func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 var redraw:=false
 if event.keycode>=KEY_1 and event.keycode<=KEY_6:family_index=event.keycode-KEY_1;redraw=true
 elif event.keycode==KEY_R:variation+=1;redraw=true
 elif event.keycode==KEY_Q:floor_view=maxi(0,floor_view-1);redraw=true
 elif event.keycode==KEY_E:floor_view=mini(1,floor_view+1);redraw=true
 if redraw:_refresh()
