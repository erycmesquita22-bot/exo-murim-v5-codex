extends Control
## EXO-Murim HUD 01: official scalable presentation layer.
## Rendering only: no gameplay mechanics, inventories, XP or quest state are invented.
const Rewards = preload("res://regional_ecology/rewards.gd")
const BASE = Vector2(1280.0, 720.0)
const GOLD = Color("d9b87b")
const GOLD_LIGHT = Color("f3dbaa")
const JADE = Color("71b49e")
const PARCHMENT = Color("e8deca")
const DIM = Color("a9a59a")
const INK = Color("10151b")
const PANEL = Color("201c19")
const RED = Color("c64d47")
const BLUE = Color("367fba")
const STAMINA = Color("72b69a")

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
	display_font = ThemeDB.fallback_font

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
	draw_rect(Rect2(r.position+Vector2(0,3),r.size),Color(0,0,0,.26))
	draw_rect(r,_alpha(PANEL,opacity))
	draw_rect(r,GOLD.darkened(.48),false,1.0)
	for x in [0.0,r.size.x]:
		var direction: float=1.0 if x==0 else -1.0
		draw_line(r.position+Vector2(x,0),r.position+Vector2(x+direction*12,0),GOLD,2.0)
		draw_line(r.position+Vector2(x,r.size.y),r.position+Vector2(x+direction*12,r.size.y),GOLD,2.0)

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
	_frame(r,.94)
	draw_rect(r.grow(-5),tint.darkened(.82))
	draw_line(r.position+Vector2(5,5),r.position+Vector2(r.size.x-5,5),tint if selected else DIM.darkened(.5),2.0)
	_center(symbol,r.get_center()+Vector2(0,9),26,tint.lightened(.25) if selected else DIM)
	if not key_name.is_empty():
		draw_rect(Rect2(r.position+Vector2(4,4),Vector2(23,20)),Color("201b16"))
		_center(key_name,r.position+Vector2(15,20),13,PARCHMENT)

func _set_block_origin(p: Vector2) -> void:
	draw_set_transform(p, 0.0, Vector2(scale_ui, scale_ui))

func _reset_transform() -> void:
	draw_set_transform(Vector2.ZERO)

func layout_for(screen: Vector2) -> Dictionary:
	var fit: float=minf(screen.x/BASE.x,screen.y/BASE.y)
	var factor: float=clampf(fit*float(world.graphics.hud.scale),.25,minf(screen.x/1000.0,screen.y/590.0))
	var count: int=mini(6,world.techniques.DATA.size())
	var width: float=maxi(3,count)*84.0+154.0
	return {"scale":factor,"vitals":Rect2(Vector2(14,14)*factor,Vector2(348,146)*factor),
		"navigation":Rect2(Vector2(screen.x-254*factor,14*factor),Vector2(240,326)*factor),
		"techniques":Rect2(Vector2((screen.x-width*factor)*.5,screen.y-110*factor),Vector2(width,96)*factor)}

func _draw() -> void:
	if world == null or world.flow == null or world.graphics == null or world.journey == null:return
	var screen: Vector2=get_viewport_rect().size
	var layout: Dictionary=layout_for(screen)
	scale_ui=float(layout.scale)
	_draw_top_left(layout.vitals.position)
	_draw_top_right(layout.navigation.position)
	_draw_bottom(layout.techniques.position)
	_draw_combat_overlays(screen)

func _draw_top_left(origin: Vector2) -> void:
	_set_block_origin(origin)
	var hud: Dictionary=world.graphics.hud
	_frame(Rect2(0,0,348,146),float(hud.opacity))
	var profile: Dictionary=world.current_profile()
	var progress: Dictionary=world.journey.data.get("journey_dynamic",{}).get("progress",{})
	var level: int=maxi(1,int(progress.get("level",1)))
	if bool(hud.portrait):
		var skin: Texture2D=world.model.skin.albedo_texture if world.model!=null and world.model.skin!=null else null
		if skin!=null:
			var uv_scale: float=float(skin.get_width())/64.0
			draw_texture_rect_region(skin,Rect2(12,14,44,44),Rect2(Vector2(8,8)*uv_scale,Vector2(8,8)*uv_scale))
		_center(str(level),Vector2(34,76),16,GOLD_LIGHT)
	else:_center("QI",Vector2(34,43),20,JADE)
	_txt("Nv. %d  %s"%[level,str(profile.get("name","Andarilho"))],Vector2(68,24),18,GOLD_LIGHT,260)
	_meter(Rect2(68,34,266,24),world.health,world.max_health,RED,"Vida",bool(hud.values))
	_meter(Rect2(68,66,266,19),world.techniques.mana,100.0,BLUE,"Qi",bool(hud.values))
	_meter(Rect2(68,92,266,19),world.techniques.stamina,100.0,STAMINA,"Fôlego",bool(hud.values))
	var weapon: Dictionary=world.current_weapon()
	_txt(str(weapon.get("name","Mãos livres")),Vector2(12,131),14,PARCHMENT,210)
	var xp: int=maxi(0,int(progress.get("xp",0)))
	var start: int=Rewards.required_total(level)
	var finish: int=Rewards.required_total(level+1) if level<50 else start
	_txt("EXP %d / %d"%[maxi(0,xp-start),maxi(1,finish-start)] if level<50 else "EXP MÁX.",Vector2(210,131),11,DIM,125)
	var fraction: float=clampf(float(xp-start)/maxf(1.0,float(finish-start)),0,1) if level<50 else 1.0
	draw_rect(Rect2(1,141,346,4),Color("151812"))
	draw_rect(Rect2(1,141,346*fraction,4),GOLD)
	var effects: Array=[]
	if world.techniques.shield_time>0:effects.append("Proteção %.1fs"%world.techniques.shield_time)
	if world.techniques.regen_delay>0:effects.append("Qi em recuperação %.1fs"%world.techniques.regen_delay)
	for i in range(effects.size()):
		_frame(Rect2(0,156+i*27,246,24),.8)
		_txt(str(effects[i]),Vector2(10,173+i*27),13,JADE,228)
	_reset_transform()

func _region_caption() -> String:
	if not preload("res://exo_dungeon/ui/map_draw.gd").snapshot(world).is_empty():return "Masmorra"
	if world.get("current_region") != null and int(world.get("current_region")) >= 0:
		var title: String = str(world.region_title(world.active_region.data.spec)) if is_instance_valid(world.active_region) else "Região"
		return "%s • %02d" % [title, int(world.current_region)]
	return "Terras Iniciais"

func _wrapped_text(value: String, at: Vector2, width: float, lines: int=3, px: int=14) -> void:
	var line: String=""
	var row: int=0
	for word in value.replace("\n"," ").split(" "):
		var candidate: String=line+(" " if not line.is_empty() else "")+word
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>width and not line.is_empty():
			_txt(line,at+Vector2(0,row*(px+5)),px,PARCHMENT,width)
			row+=1;line=word
			if row>=lines:return
		else:line=candidate
	if row<lines:_txt(line,at+Vector2(0,row*(px+5)),px,PARCHMENT,width)

func _draw_top_right(origin: Vector2) -> void:
	_set_block_origin(origin)
	_frame(Rect2(0,0,240,207),float(world.graphics.hud.opacity))
	_txt(_region_caption(),Vector2(12,23),15,GOLD_LIGHT,218)
	_draw_map(Vector2(120,112),70)
	var state: Dictionary=world.journey.data.get("convergence",{})
	var clock: float=float(state.get("clock",0.0))
	_txt("Dia %d  %02d:%02d"%[int(clock/(90.0*24.0))+1,posmod(int(clock/90.0),24),posmod(int(clock/1.5),60)],Vector2(12,194),12,DIM,160)
	_txt("TAB  Mapa",Vector2(160,194),12,GOLD_LIGHT,76)
	if not bool(world.graphics.hud.compact):
		_frame(Rect2(0,217,240,109),float(world.graphics.hud.opacity))
		_txt("SUA JORNADA",Vector2(12,239),13,GOLD,215)
		var journey_data: Dictionary=world.journey.data.get("journey_dynamic",{})
		var quests: Dictionary=journey_data.get("quests",{})
		var tracked: String=str(journey_data.get("tracked",""))
		var objective: String=str(world.objective())
		if quests.has(tracked):
			var q: Dictionary=quests[tracked]
			objective=str(q.get("title","Contrato"))+"  •  "+("Retorne ao contratante" if str(q.get("state",""))=="COMPLETED" else "%d / %d"%[int(q.get("progress",0)),int(q.get("goal",1))])
		_wrapped_text(objective,Vector2(12,263),215,3,14)
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
	for actor in world.enemies:
		if is_instance_valid(actor) and actor.hp>0 and actor.visible and actor.position.distance_to(world.player.position)<36.0:
			draw_circle(_map_project(Vector2(actor.position.x,actor.position.z)-center_world,center,radius,extent),2.5,RED)
	var hero := _map_project(Vector2(world.player.position.x, world.player.position.z) - center_world, center, radius, extent)
	draw_circle(hero, 6.0, Color("f8e0a1"))
	draw_circle(hero, 3.0, Color("49d1c0"))
	var facing: Vector2=Vector2(world.facing.x,world.facing.z).normalized()
	var side: Vector2=Vector2(-facing.y,facing.x)
	draw_colored_polygon(PackedVector2Array([hero+facing*10,hero-facing*2+side*4,hero-facing*2-side*4]),PARCHMENT)
	_center("N", center + Vector2(0, -radius + 14), 14, GOLD_LIGHT)

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
	var count: int=mini(6,world.techniques.DATA.size())
	var slots: int=maxi(3,count)
	for i in range(slots):
		var r: Rect2=Rect2(i*84.0,0,76,72)
		if i>=count:
			_icon(r,"·",DIM,false,str(i+1));_center("Sem técnica",Vector2(r.get_center().x,90),11,DIM)
			continue
		var skill: Dictionary=world.techniques.DATA[i]
		var cd: float=float(world.techniques.cooldowns[i]) if i<world.techniques.cooldowns.size() else 0.0
		var enough: bool=world.techniques.mana>=float(skill.get("mana",0)) and world.techniques.stamina>=float(skill.get("stamina",0))
		var tint: Color=BLUE if float(skill.get("mana",0))>0 else JADE
		_icon(r,_skill_symbol(str(skill.get("kind",""))),tint,cd<=0 and enough,str(i+1))
		if cd>0:
			draw_rect(r.grow(-4),Color(0,0,0,.7))
			var fraction: float=clampf(cd/maxf(.01,float(skill.get("cooldown",1))),0,1)
			draw_arc(r.get_center(),23,-PI*.5,-PI*.5+TAU*fraction,40,GOLD,2.0,true)
			_center("%.1f"%cd,r.get_center()+Vector2(0,6),17,Color.WHITE)
		elif not enough:
			draw_rect(r.grow(-4),Color(0,0,0,.5));_center("Sem Qi" if world.techniques.mana<float(skill.get("mana",0)) else "Fôlego",r.get_center()+Vector2(0,6),12,RED)
		var cost: float=float(skill.get("mana",0)) if float(skill.get("mana",0))>0 else float(skill.get("stamina",0))
		_txt(str(int(cost)),r.position+Vector2(51,64),12,tint,22)
		var title: String=str(skill.get("name","Técnica"))
		while font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>78 and title.length()>3:title=title.left(title.length()-2)+"…"
		_center(title,Vector2(r.get_center().x,90),12,PARCHMENT)
	var x: float=slots*84.0+8
	var dash: float=maxf(0.0,float(world.roll_cooldown))
	_icon(Rect2(x,0,64,72),"↗",JADE,dash<=0,"F")
	if dash>0:_center("%.1f"%dash,Vector2(x+32,65),13,GOLD_LIGHT)
	_center("Esquiva",Vector2(x+32,90),12,PARCHMENT)
	_icon(Rect2(x+72,0,64,72),"⚔",GOLD,true,"R")
	_center("Arma / mãos",Vector2(x+104,90),12,PARCHMENT)
	var supplies: int=0
	for entry in world.journey.data.get("items",[]):
		if str(entry.get("kind",""))=="consumable":supplies+=int(entry.get("qty",0))
	_frame(Rect2(0,-32,slots*84+144,24),.8)
	_txt("%d moedas  •  %d consumíveis  •  I Inventário  /  P Jornada"%[int(world.journey.data.get("coins",0)),supplies],Vector2(10,-15),12,PARCHMENT,slots*84+124)
	_reset_transform()

func _draw_combat_overlays(screen: Vector2) -> void:
	var hint: String=str(world.interaction_hint())
	if not hint.is_empty():
		_set_block_origin(Vector2((screen.x-360*scale_ui)*.5,screen.y-(245 if world.techniques.busy() else 200)*scale_ui))
		_frame(Rect2(0,0,360,34),.88)
		_center(hint,Vector2(180,23),14,GOLD_LIGHT)
		_reset_transform()
	if bool(world.graphics.hud.target) and is_instance_valid(world.target) and world.target.hp>0:
		_set_block_origin(Vector2((screen.x-300*scale_ui)*.5,18*scale_ui))
		_frame(Rect2(0,0,300,57),.91)
		_txt(str(world.target.display_name),Vector2(12,21),16,GOLD_LIGHT,276)
		_meter(Rect2(12,32,276,18),world.target.hp,world.target.max_hp,RED,"Vida")
		_reset_transform()
	if bool(world.graphics.hud.notices) and world.feedback_time>0 and (not world.techniques.busy() or str(world.feedback)!=str(world.techniques.casting.get("name",""))):
		_set_block_origin(Vector2((screen.x-370*scale_ui)*.5,96*scale_ui))
		_frame(Rect2(0,0,370,51),.85)
		_wrapped_text(str(world.feedback),Vector2(12,21),346,2,14)
		_reset_transform()
	if world.techniques.busy():
		_set_block_origin(Vector2((screen.x-290*scale_ui)*.5,screen.y-200*scale_ui))
		_frame(Rect2(0,0,290,39),.9)
		_txt(str(world.techniques.casting.get("name","Técnica")),Vector2(12,23),14,GOLD_LIGHT,266)
		var cast: float=maxf(.01,float(world.techniques.casting.get("cast",.01)))
		draw_rect(Rect2(4,33,282*clampf(world.techniques.time/cast,0,1),3),JADE)
		_reset_transform()
