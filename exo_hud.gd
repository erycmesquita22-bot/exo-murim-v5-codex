extends Control
const Slots=preload("res://data/slot_rules.gd")
# Presentation adapted from ExoHud, HudSettings and HudPresentation. No fabricated level or EXP.
const STYLES=["EXO Murim (oficial)","Tático","Orbes","Faixa RPG","Duelo","Manhwa","Barras verticais","Rúnico","Painel MMO","Essencial"]
const THEMES=["Eclipse","Aurora","Esmeralda","Rubi","Aço","Âmbar","Índigo"]
const ACCENTS=["78cbdd","e1bd77","7fd9ad","e78091","b2c7df","f3ae64","b299e7"]
const ANCHORS=["Superior esquerdo","Superior direito","Superior centro","Meio esquerdo","Meio direito","Centro","Inferior esquerdo","Inferior direito","Inferior centro"]
const COLORS=[Color("c44e5d"),Color("527fcc"),Color("439e86")]
var world: Node3D
var ui: Node
var origin:=Vector2.ZERO
var factor:=1.0
var font: Font
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=ThemeDB.fallback_font
func _process(_delta: float) -> void:
	visible=world.flow!=null and world.flow.phase in ["adventure","prologue"] and not get_tree().paused and int(world.graphics.hud.style)!=0
	if visible:queue_redraw()
func at(anchor: int,dimensions: Vector2) -> Vector2:
	var screen:=get_viewport_rect().size
	var xs: Array=[18.0,screen.x-dimensions.x-18,(screen.x-dimensions.x)*.5]
	var mapping: Array=[0,1,2,0,1,2,0,1,2]
	return Vector2(xs[mapping[anchor]],18 if anchor<3 else (screen.y-dimensions.y)*.5 if anchor<6 else screen.y-dimensions.y-18)
func text(value: String,point: Vector2,width: float=280,color: Color=Color("ece8db"),font_size: int=14) -> void:
	draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)
func panel(rect: Rect2,accent: Color,opacity: float=.85) -> void:
	draw_rect(rect,Color(.045,.065,.095,opacity))
	draw_rect(rect,Color(accent,.6),false,1)
	draw_line(rect.position,rect.position+Vector2(rect.size.x,0),accent,2)
func meter(point: Vector2,width: float,index: int,value: float,maximum: float,values: bool=true) -> void:
	var rect:=Rect2(point,Vector2(width,18))
	draw_rect(rect,Color("1a2637"))
	draw_rect(Rect2(point,Vector2(width*clampf(value/maximum,0,1),18)),COLORS[index])
	text(["Vida","Qi","Estamina"][index]+(" %.0f / %.0f"%[value,maximum] if values else ""),point+Vector2(5,14),width-8,Color.WHITE,12)
func _draw() -> void:
	if world.flow==null:return
	var settings: Dictionary=world.graphics.hud
	var style: int=int(settings.style)
	var accent:=Color(ACCENTS[int(settings.theme)])
	var width: float=410 if style==3 else 205 if style==6 else 320 if style==8 else 285
	var height: float=145 if settings.compact else 220
	if not settings.compact:height+=22*maxi(0,world.techniques.DATA.size()-Slots.ACTIVE)
	if style in [2,6,7]:height+=20
	factor=clampf(float(settings.scale),.6,1.5)
	origin=at(int(settings.anchor),Vector2(width,height)*factor)
	draw_set_transform(origin,0,Vector2.ONE*factor)
	var values: Array=[world.health,world.techniques.mana,world.techniques.stamina]
	var maximum: Array=[world.max_health,100.0,100.0]
	var name_value: String=world.current_profile().get("name",world.journey.data.character.get("name","EXO"))
	if style not in [1,9]:panel(Rect2(0,0,width,height),accent,float(settings.opacity))
	text("[ SISTEMA ]  STATUS" if style==5 else "COMBATE" if style==4 else name_value,Vector2(12,22),width-24,accent,16)
	var y:=35.0
	if style==5:text(name_value,Vector2(12,43),width-24,Color("d8bd81"));y=53
	if style in [2,7]:
		for i in range(3):
			var center:=Vector2(width*(i+.5)/3,75)
			if style==2:
				draw_circle(center,27,Color("1a2637"))
				var fraction: float=clampf(values[i]/maximum[i],0,1)
				for row in range(54):
					var dy:=row-26.5
					var half:=sqrt(maxf(0,27*27-dy*dy))
					if row>=54*(1-fraction):draw_line(center+Vector2(-half,dy),center+Vector2(half,dy),COLORS[i],1)
				draw_arc(center,28,0,TAU,48,accent,1,true)
			else:
				var points:=PackedVector2Array([center+Vector2(0,-27),center+Vector2(27,0),center+Vector2(0,27),center+Vector2(-27,0)])
				draw_colored_polygon(points,COLORS[i].darkened(1-float(values[i])/maximum[i]))
				points.append(points[0]);draw_polyline(points,accent,1,true)
			text(["Vida","Qi","Estamina"][i],Vector2(center.x-32,116),75,COLORS[i],12)
			if settings.values:text("%.0f"%values[i],center+Vector2(-15,5),50,Color.WHITE,13)
		y=137
	elif style==6:
		for i in range(3):
			var x:=15+i*62
			draw_rect(Rect2(x,40,42,77),Color("1a2637"))
			var fill: float=77*clampf(values[i]/maximum[i],0,1)
			draw_rect(Rect2(x,117-fill,42,fill),COLORS[i])
			text(["V","Q","S"][i],Vector2(x+14,133),35,accent,12)
		y=153
	elif style==3:
		for i in range(3):meter(Vector2(12+i*130,42),122,i,values[i],maximum[i],settings.values)
		y=83
	elif style==9:
		for i in range(3):
			var point:=Vector2(12,36+i*19)
			draw_rect(Rect2(point,Vector2(width-24,5)),Color("1a2637"))
			draw_rect(Rect2(point,Vector2((width-24)*clampf(values[i]/maximum[i],0,1),5)),COLORS[i])
			if settings.values:text("%.0f / %.0f"%[values[i],maximum[i]],point+Vector2(0,17),width-24,Color("dde3e8"),10)
		y=105
	else:
		var x:=12.0
		if settings.portrait and style in [0,4,8]:
			var texture: Texture2D=world.model.skin.albedo_texture
			draw_texture_rect_region(texture,Rect2(12,40,48,48),Rect2(8,8,8,8))
			x=70
		for i in range(3):meter(Vector2(x,y+i*24),width-x-12,i,values[i],maximum[i],settings.values)
		y+=85
	if not settings.compact:
		for i in range(world.techniques.DATA.size()):
			var skill: Dictionary=world.techniques.DATA[i]
			var cd: float=world.techniques.cooldowns[i]
			text("[%d] %s%s"%[i+1,skill.name,"  %.1fs"%cd if cd>0 else ""],Vector2(12,y+i*22),width-24,Color("9eacc0") if cd>0 else Color("ece8db"),13)
	if world.flow.meditating:text("Cultivo • %.0f s"%world.journey.data.meditation,Vector2(12,height-12),width-24,accent,13)
	draw_set_transform(Vector2.ZERO)
	if settings.target and is_instance_valid(world.target) and world.target.hp>0:
		var p:=Vector2((get_viewport_rect().size.x-300)/2,get_viewport_rect().size.y-90)
		panel(Rect2(p,Vector2(300,55)),accent)
		text(world.target.display_name,p+Vector2(10,20),280,accent)
		meter(p+Vector2(10,28),280,0,world.target.hp,world.target.max_hp,true)
	if settings.notices and world.feedback_time>0:
		var p:=Vector2(get_viewport_rect().size.x-330,180)
		panel(Rect2(p,Vector2(310,78)),accent)
		text("SISTEMA AVISA",p+Vector2(10,20),290,accent,12)
		draw_multiline_string(font,p+Vector2(10,42),world.feedback,HORIZONTAL_ALIGNMENT_LEFT,290,13,2,Color("ece8db"))
	if world.techniques.busy():
		var data: Dictionary=world.techniques.casting
		var p:=Vector2((get_viewport_rect().size.x-280)/2,get_viewport_rect().size.y-145)
		panel(Rect2(p,Vector2(280,33)),accent)
		text("Preparando • "+str(data.get("name","")),p+Vector2(10,22),260,accent,13)
