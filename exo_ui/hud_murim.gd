extends Control
## EXO-Murim HUD 01: official scalable presentation layer.
## Rendering only: no gameplay mechanics, inventories, XP or quest state are invented.
const Rewards = preload("res://regional_ecology/rewards.gd")
const BASE = Vector2(1600.0, 900.0)
const GOLD = Color("d9b87b")
const GOLD_LIGHT = Color("f3dbaa")
const JADE = Color("71b49e")
const PARCHMENT = Color("e8deca")
const DIM = Color("a9a59a")
const INK = Color("10151b")
const PANEL = Color("111418")
const RED = Color("c64d47")
const BLUE = Color("367fba")
const STAMINA = Color("a39b45")

var world: Node3D
var ui: Node
var font: Font
var display_font: Font
var elapsed := 0.0
var scale_ui := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = ThemeDB.fallback_font
	display_font = load("res://assets/manuscrito.otf")

func _process(delta: float) -> void:
	elapsed += delta
	if world == null or world.flow == null or world.graphics == null:
		visible = false
		return
	visible = world.flow.phase in ["adventure", "prologue"] and not get_tree().paused and int(world.graphics.hud.style) == 0
	if visible:
		queue_redraw()

func _txt(label: String, at: Vector2, px: int = 15, color: Color = PARCHMENT, max_width: float = -1.0, use_display: bool = false) -> void:
	var chosen: Font = display_font if use_display else font
	draw_string(chosen, at, label, HORIZONTAL_ALIGNMENT_LEFT, max_width, px, color)

func _center(label: String, at: Vector2, px: int = 15, color: Color = PARCHMENT) -> void:
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	_txt(label, at - Vector2(width * 0.5, 0), px, color)

func _alpha(color: Color, opacity: float) -> Color:
	var result := color
	result.a = opacity
	return result

func _frame(r: Rect2, opacity: float = 0.87) -> void:
	var c := PANEL
	c.a = opacity
	draw_rect(r, c)
	draw_rect(r.grow(-3), _alpha(Color("29251f"), opacity * 0.92), false, 1.0)
	draw_rect(r, GOLD.darkened(0.32), false, 2.0)
	draw_rect(r.grow(-6), _alpha(Color("a58355"), opacity * .8), false, 1.0)
	# The four slanted metal fittings are independent of bitmap atlases.
	for sx in [0, 1]:
		for sy in [0, 1]:
			var p := r.position + Vector2(float(sx) * r.size.x, float(sy) * r.size.y)
			var dx := -1.0 if sx == 1 else 1.0
			var dy := -1.0 if sy == 1 else 1.0
			draw_line(p + Vector2(dx * 3.0, dy * 15.0), p + Vector2(dx * 15.0, dy * 3.0), GOLD_LIGHT, 2.0, true)
			draw_circle(p + Vector2(dx * 9.0, dy * 9.0), 2.0, JADE)
			draw_arc(p + Vector2(dx * 18.0, dy * 18.0), 8.0, .0, TAU, 20, _alpha(GOLD, opacity * .68), 1.2)
			draw_line(p + Vector2(dx * 15, dy * 2), p + Vector2(dx * 35, dy * 2), GOLD.darkened(.25), 1.0)
			draw_line(p + Vector2(dx * 2, dy * 15), p + Vector2(dx * 2, dy * 30), GOLD.darkened(.25), 1.0)

func _plaque(r: Rect2, text_value: String, size_value: int = 17) -> void:
	_frame(r, .93)
	_txt(text_value, r.position + Vector2(16, r.size.y * .65), size_value, GOLD_LIGHT, r.size.x - 20, true)

func _meter(r: Rect2, current: float, maximum: float, fill: Color, label: String, show_value: bool = true) -> void:
	var fraction := clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	_txt(label, r.position + Vector2(0, 14), 14, GOLD_LIGHT)
	var inner := Rect2(r.position + Vector2(64, 0), Vector2(r.size.x - 64, r.size.y))
	draw_rect(inner, Color("090e15"))
	draw_rect(inner.grow(-2), Color("202a2c"))
	if fraction > 0.001:
		var fill_r := Rect2(inner.position + Vector2(3, 3), Vector2((inner.size.x - 6) * fraction, inner.size.y - 6))
		draw_rect(fill_r, fill)
		draw_line(fill_r.position + Vector2(0, 1), fill_r.position + Vector2(fill_r.size.x, 1), fill.lightened(.36), 1.0)
	draw_rect(inner, GOLD.darkened(.31), false, 1.5)
	if show_value:
		var content := "%d / %d" % [int(ceilf(current)), int(ceilf(maximum))]
		var sz := font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		_txt(content, inner.position + Vector2(inner.size.x - sz - 6, 14), 13, Color.WHITE)

func _icon(r: Rect2, symbol: String, tint: Color, selected: bool = false, key_name: String = "") -> void:
	_frame(r, .96 if selected else .89)
	draw_rect(r.grow(-9), tint.darkened(.72))
	draw_circle(r.get_center(), minf(r.size.x, r.size.y) * .28, Color(tint, .26))
	_center(symbol, r.get_center() + Vector2(0, 9), 25, tint.lightened(.4))
	if key_name != "":
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(23, 20)), Color("1b1a1a"))
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(23, 20)), GOLD.darkened(.23), false, 1)
		_center(key_name, r.position + Vector2(13, 17), 13, PARCHMENT)

func _set_block_origin(p: Vector2) -> void:
	draw_set_transform(p, 0.0, Vector2(scale_ui, scale_ui))

func _reset_transform() -> void:
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if world == null or world.flow == null or world.graphics == null or world.journey == null:
		return
	var screen := get_viewport_rect().size
	scale_ui = minf(screen.x / BASE.x, screen.y / BASE.y) * float(world.graphics.hud.scale)
	scale_ui = clampf(scale_ui, .40, 1.65)
	_draw_top_left(Vector2(16, 14) * scale_ui)
	_draw_top_right(Vector2(screen.x - 320 * scale_ui - 16 * scale_ui, 14 * scale_ui))
	_draw_bottom(Vector2((screen.x - 1600 * scale_ui) * .5, screen.y - 135 * scale_ui - 15 * scale_ui))
	_draw_combat_overlays(screen)

func _draw_top_left(origin: Vector2) -> void:
	_set_block_origin(origin)
	var hud: Dictionary = world.graphics.hud
	_frame(Rect2(0, 0, 515, 158), float(hud.opacity))
	var profile: Dictionary = world.current_profile()
	var player_name := str(profile.get("name", "Andarilho"))
	# Live Minecraft skin head UV (portrait can be toggled independently).
	if bool(hud.portrait):
		_frame(Rect2(9, 10, 123, 135), .98)
		var skin: Texture2D = world.model.skin.albedo_texture if world.model != null and world.model.skin != null else null
		if skin != null:
			draw_texture_rect_region(skin, Rect2(18, 19, 105, 102), Rect2(8, 8, 8, 8))
		_center("EXO", Vector2(70, 137), 13, JADE)
	else:
		_frame(Rect2(9, 10, 123, 135), .98)
		_center("EXO", Vector2(70, 87), 27, GOLD)
	var progress: Dictionary = world.journey.data.get("journey_dynamic", {}).get("progress", {})
	var level: int = maxi(1, int(progress.get("level", 1)))
	_txt("Nv. %d   %s" % [level, player_name], Vector2(148, 25), 21, GOLD_LIGHT, 354, true)
	_meter(Rect2(148, 38, 354, 19), float(world.health), float(world.max_health), RED, "Vida", bool(hud.values))
	_meter(Rect2(148, 64, 354, 19), float(world.techniques.mana), 100.0, BLUE, "Qi", bool(hud.values))
	_meter(Rect2(148, 90, 354, 19), float(world.techniques.stamina), 100.0, STAMINA, "Stamina", bool(hud.values))
	var total_xp: int = maxi(0, int(progress.get("xp", 0)))
	var xp_start: int = Rewards.required_total(level)
	var xp_next: int = Rewards.required_total(level + 1) if level < 50 else xp_start
	var span: int = maxi(1, xp_next - xp_start)
	var frac: float = clampf(float(total_xp - xp_start) / float(span), 0.0, 1.0) if level < 50 else 1.0
	_txt("EXP", Vector2(148, 137), 13, GOLD_LIGHT)
	draw_rect(Rect2(193, 127, 215, 10), Color("0c1113"))
	draw_rect(Rect2(195, 129, 211 * frac, 6), JADE)
	_txt("%d / %d" % [maxi(0, total_xp - xp_start), span] if level < 50 else "MAX", Vector2(415, 137), 12, PARCHMENT)
	# Only actual timed effects. Empty slots do not invent active buffs.
	var effects: Array = []
	if float(world.techniques.shield_time) > 0:
		effects.append(["◈", "Escudo", float(world.techniques.shield_time), JADE])
	if float(world.techniques.regen_delay) > 0:
		effects.append(["✦", "Recarga", float(world.techniques.regen_delay), BLUE])
	if world.techniques.busy():
		effects.append(["✶", "Técnica", maxf(0.0, float(world.techniques.casting.get("cast", .0)) - world.techniques.time), RED])
	for i in range(mini(effects.size(), 4)):
		var effect: Array = effects[i]
		var x := 533.0 + 53.0 * i
		_icon(Rect2(x, 0, 47, 47), str(effect[0]), effect[3])
		_center("%.1fs" % float(effect[2]), Vector2(x + 23, 64), 12, GOLD_LIGHT)
	_reset_transform()

func _region_caption() -> String:
	if not preload("res://exo_dungeon/ui/map_draw.gd").snapshot(world).is_empty():return "Masmorra"
	if world.get("current_region") != null and int(world.get("current_region")) >= 0:
		var title: String = str(world.region_title(world.active_region.data.spec)) if is_instance_valid(world.active_region) else "Região"
		return "%s • %02d" % [title, int(world.current_region)]
	return "Terras Iniciais"

func _draw_top_right(origin: Vector2) -> void:
	_set_block_origin(origin)
	_plaque(Rect2(0, 0, 320, 39), _region_caption(), 17)
	var clock := ""
	if world.get("current_region") != null and int(world.get("current_region")) >= 0:
		var state: Dictionary = world.journey.data.get("convergence", {})
		var n: float = float(state.get("clock", 0.0))
		var day: int = int(n / (90.0 * 24.0)) + 1
		var hr: int = posmod(int(n / 90.0), 24)
		clock = "Dia %d   %02d:%02d" % [day, hr, posmod(int(n / 1.5), 60)]
	else:
		clock = "TAB  •  Mapa regional"
	_txt(clock, Vector2(14, 65), 13, GOLD_LIGHT)
	_draw_map(Vector2(168, 159), 106)
	# Actual contracts first; fall back to the existing tracked world objective.
	if bool(world.graphics.hud.compact):
		_reset_transform()
		return
	_frame(Rect2(0, 277, 320, 220), .91)
	_txt("CRÔNICAS  /  CONTRATOS", Vector2(17, 304), 19, GOLD_LIGHT, 297, true)
	draw_line(Vector2(15, 317), Vector2(304, 317), GOLD.darkened(.32), 1.5)
	var journey_data: Dictionary = world.journey.data.get("journey_dynamic", {})
	var quests: Dictionary = journey_data.get("quests", {})
	if not quests.is_empty():
		var ids: Array = quests.keys()
		ids.sort()
		var tracked: String = str(journey_data.get("tracked", ""))
		if tracked in ids:
			ids.erase(tracked)
			ids.push_front(tracked)
		for i in range(mini(3, ids.size())):
			var quest: Dictionary = quests[ids[i]]
			var y: float = 342 + i * 48.0
			var title: String = str(quest.get("title", "Contrato"))
			if title.length() > 32: title = title.substr(0, 31) + "…"
			_txt(("◆  " if i == 0 else "◇  ") + title, Vector2(17, y), 14, GOLD_LIGHT if i == 0 else PARCHMENT, 292)
			var progress_text: String = "Concluído • retornar" if str(quest.get("state", "")) == "COMPLETED" else "%d / %d" % [int(quest.get("progress", 0)), int(quest.get("goal", 1))]
			_txt("       " + progress_text, Vector2(17, y + 19), 12, DIM, 288)
	else:
		var objective: String = str(world.objective())
		var words := objective.replace("\r", "").replace("\n", " ").split(" ")
		var output: Array[String] = []
		var line := ""
		for word in words:
			if (line + " " + word).length() > 33:
				output.append(line)
				line = str(word)
			else:
				line += (" " if not line.is_empty() else "") + word
		if not line.is_empty(): output.append(line)
		for i in range(mini(output.size(), 6)):
			_txt(("◆  " if i == 0 else "    ") + output[i], Vector2(17, 344 + i * 21), 14, PARCHMENT, 296)
	_txt("P  •  crônicas    |    TAB  •  mapa", Vector2(17, 479), 11, DIM)
	_reset_transform()

func _map_project(position: Vector2, center: Vector2, radius: float, world_extent: float) -> Vector2:
	var offset := position / maxf(1.0, world_extent) * (radius * .87)
	if offset.length() > radius * .88:
		offset = offset.normalized() * radius * .88
	return center + offset

func _draw_map(center: Vector2, radius: float) -> void:
	draw_circle(center, radius + 7, Color("0b0d0e"))
	draw_circle(center, radius + 2, GOLD.darkened(.45))
	draw_circle(center, radius - 4, Color("304a3d"))
	draw_arc(center, radius + 5, 0, TAU, 96, GOLD_LIGHT, 2.0, true)
	var dungeon_map:Dictionary=preload("res://exo_dungeon/ui/map_draw.gd").snapshot(world)
	if not dungeon_map.is_empty():
		preload("res://exo_dungeon/ui/map_draw.gd").draw_map(self,dungeon_map,center,radius-4)
		return
	# World coordinates drive all map markers: no decorative fantasy locations.
	var regional: bool = world.get("current_region") != null and int(world.get("current_region")) >= 0 and is_instance_valid(world.active_region)
	var extent: float = 256.0 if regional else 110.0
	var center_world := Vector2.ZERO if regional else Vector2(0, 0)
	for ring in [.32, .62]:
		draw_arc(center, radius * ring, 0, TAU, 48, Color(JADE, .15), 1.0)
	for cardinal in [0, 1, 2, 3]:
		var angle := float(cardinal) * PI / 2.0
		var a := center + Vector2(cos(angle), sin(angle)) * 12.0
		var b := center + Vector2(cos(angle), sin(angle)) * (radius - 8.0)
		draw_line(a, b, Color(JADE, .19), 1)
	if regional:
		var data: RefCounted = world.active_region.data
		for road in data.settlement_roads:
			var a: Vector2 = _map_project(road.a, center, radius, extent)
			var b: Vector2 = _map_project(road.b, center, radius, extent)
			draw_line(a, b, Color("c8a875"), 2)
		for gate in data.gates:
			draw_circle(_map_project(gate.p, center, radius, extent), 4, GOLD_LIGHT)
		for lot in data.lots:
			var marker := _map_project(lot.p, center, radius, extent)
			draw_rect(Rect2(marker - Vector2(2, 2), Vector2(4, 4)), Color("b7ad88"))
		for resident in world.residents:
			if is_instance_valid(resident) and resident.rig.visible:
				draw_circle(_map_project(Vector2(resident.position.x, resident.position.z), center, radius, extent), 2, Color("dac680"))
	else:
		draw_line(_map_project(Vector2(-75, 24), center, radius, extent), _map_project(Vector2(55, 24), center, radius, extent), Color("c8a875"), 3)
		draw_line(_map_project(Vector2(0, -92), center, radius, extent), _map_project(Vector2(0, 90), center, radius, extent), Color("c8a875"), 3)
		var plan: Dictionary = world.get_meta("landscape_plan", {})
		for house in plan.get("houses", []):
			var marker := _map_project(Vector2(float(house.x), float(house.z)), center, radius, extent)
			draw_rect(Rect2(marker - Vector2(2, 2), Vector2(5, 5)), Color("c6b28b"))
	var hero := _map_project(Vector2(world.player.position.x, world.player.position.z) - center_world, center, radius, extent)
	draw_circle(hero, 6.0, Color("f8e0a1"))
	draw_circle(hero, 3.0, Color("49d1c0"))
	_center("N", center + Vector2(0, -radius - 14), 16, GOLD_LIGHT)
	_txt("TAB", center + Vector2(radius - 10, radius - 6), 11, GOLD_LIGHT)

func _weapon_symbol(weapon: Dictionary) -> String:
	var wid := str(weapon.get("id", ""))
	if "bow" in wid or "besta" in wid: return "⌁"
	if "spear" in wid or "lance" in wid: return "↟"
	if "wand" in wid or "staff" in wid: return "✦"
	return "⚔"

func _skill_symbol(kind: String) -> String:
	match kind:
		"cut": return "⚔"
		"projectile": return "✦"
		"leap": return "↟"
		"dash": return "➶"
		"shield": return "◈"
		"heal": return "+"
		"summon": return "♜"
		"channel": return "◎"
		"area": return "✹"
		_: return "✧"

func _draw_bottom(origin: Vector2) -> void:
	_set_block_origin(origin)
	var settings: Dictionary = world.graphics.hud
	var weapon: Dictionary = world.current_weapon()
	_frame(Rect2(5, 10, 305, 106), float(settings.opacity))
	_txt("ARMA / ESTILO", Vector2(20, 30), 14, GOLD_LIGHT, 278, true)
	_icon(Rect2(24, 40, 60, 61), _weapon_symbol(weapon), GOLD)
	_txt(str(weapon.get("name", "Arma")), Vector2(94, 67), 16, PARCHMENT, 190)
	_txt("R  •  embainhar / mãos livres", Vector2(94, 93), 11, DIM, 196)
	_frame(Rect2(328, 0, 897, 124), float(settings.opacity))
	# Exactly the active loadout: do not display abilities that are not equipped.
	var skill_count: int = mini(6, world.techniques.DATA.size())
	for i in range(6):
		var r := Rect2(341 + i * 103, 14, 92, 78)
		if i < skill_count:
			var skill: Dictionary = world.techniques.DATA[i]
			var cd: float = float(world.techniques.cooldowns[i]) if i < world.techniques.cooldowns.size() else 0.0
			var icon_tint := Color("d86b55") if i % 3 == 0 else Color("6faaca") if i % 3 == 1 else Color("d2b16e")
			_icon(r, _skill_symbol(str(skill.get("kind", ""))), icon_tint, cd <= 0.0, str(i + 1))
			if cd > 0:
				draw_rect(r.grow(-5), _alpha(Color("050509"), .73))
				_center("%.1fs" % cd, r.get_center() + Vector2(0, 7), 18, Color.WHITE)
			var short_name := str(skill.get("name", "Técnica"))
			if short_name.length() > 12: short_name = short_name.substr(0, 11) + "…"
			_center(short_name, Vector2(r.get_center().x, 111), 11, PARCHMENT)
		else:
			_frame(r, .50)
			_center("+", r.get_center() + Vector2(0, 8), 18, DIM)
			_center("Slot livre", Vector2(r.get_center().x, 111), 11, DIM)
	_icon(Rect2(970, 22, 68, 69), "↗", JADE, true, "F")
	_center("Esquiva", Vector2(1004, 111), 12, PARCHMENT)
	_icon(Rect2(1048, 22, 68, 69), "⚔", GOLD, true, "R")
	_center("Arma / mãos", Vector2(1082, 111), 12, PARCHMENT)
	_icon(Rect2(1125, 22, 83, 69), "…", GOLD, false, "E")
	_center("Interagir", Vector2(1166, 111), 12, PARCHMENT)
	# Real inventory consumables, not fictitious R/F/C shortcuts.
	_frame(Rect2(1240, 10, 192, 106), float(settings.opacity))
	_txt("CONSUMÍVEIS", Vector2(1253, 30), 13, GOLD_LIGHT, 175, true)
	var consumables: Array = []
	for entry in world.journey.data.get("items", []):
		if str(entry.get("kind", "")) == "consumable":consumables.append(entry)
	for i in range(mini(consumables.size(), 2)):
		var entry: Dictionary = consumables[i]
		_icon(Rect2(1254 + 75 * i, 43, 64, 58), "✚", JADE, false)
		_txt(str(entry.get("qty", 0)), Vector2(1296 + 75 * i, 99), 13, Color.WHITE)
	_txt("I  •  usar no inventário", Vector2(1253, 115), 11, DIM)
	_frame(Rect2(1444, 34, 148, 76), float(settings.opacity))
	_txt("◈  MOEDAS", Vector2(1454, 58), 14, GOLD_LIGHT)
	_txt("%d" % int(world.journey.data.get("coins", 0)), Vector2(1454, 90), 22, PARCHMENT)
	_reset_transform()

func _draw_combat_overlays(screen: Vector2) -> void:
	if bool(world.graphics.hud.target) and is_instance_valid(world.target) and world.target.hp > 0:
		var target_width := 285.0 * scale_ui
		_set_block_origin(Vector2((screen.x - target_width) * .5, screen.y - 244 * scale_ui))
		_frame(Rect2(0, 0, 285, 53), .90)
		_txt(str(world.target.display_name), Vector2(12, 20), 15, GOLD_LIGHT, 263)
		_meter(Rect2(10, 28, 265, 17), float(world.target.hp), float(world.target.max_hp), RED, "Vida")
		_reset_transform()
	if bool(world.graphics.hud.notices) and float(world.feedback_time) > 0:
		_set_block_origin(Vector2((screen.x - 400 * scale_ui) * .5, 180 * scale_ui))
		_frame(Rect2(0, 0, 400, 62), .90)
		_txt("SISTEMA AVISA", Vector2(13, 22), 16, GOLD_LIGHT, 377, true)
		_txt(str(world.feedback).replace("\n", " "), Vector2(13, 46), 13, PARCHMENT, 376)
		_reset_transform()
	if world.techniques.busy():
		_set_block_origin(Vector2((screen.x - 300 * scale_ui) * .5, screen.y - 208 * scale_ui))
		_frame(Rect2(0, 0, 300, 37), .88)
		_txt("Canalizando  •  " + str(world.techniques.casting.get("name", "Técnica")), Vector2(13, 26), 15, GOLD_LIGHT, 274)
		_reset_transform()
