extends Control
var kind:="weapon"
var ref:="sword"
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var metal:=Color("b7bec7")
	var gold:=Color("ad9463")
	var ink:=Color("443d33")
	if kind=="manual":
		draw_style_box(scroll_box(),Rect2(-15,-12,30,24))
		for y in [-7,-2,3,8]:draw_line(Vector2(-8,y),Vector2(8-(y%3),y),ink,1)
		for x in [-17,17]:draw_line(Vector2(x,-14),Vector2(x,14),gold,4)
	elif kind=="consumable":
		draw_circle(Vector2(0,3),12,Color("688e7d"))
		draw_rect(Rect2(-4,-14,8,10),metal)
		draw_line(Vector2(-6,-15),Vector2(6,-15),gold,3)
	elif kind=="material":
		draw_colored_polygon(PackedVector2Array([Vector2(-17,5),Vector2(-8,-10),Vector2(12,-12),Vector2(19,4),Vector2(6,12)]),metal)
		draw_line(Vector2(-8,-10),Vector2(0,7),gold,1)
	elif ref in ["bow","crossbow"]:
		draw_polyline(PackedVector2Array([Vector2(-8,-17),Vector2(6,-9),Vector2(9,0),Vector2(6,9),Vector2(-8,17)]),gold,3,true)
		draw_line(Vector2(-8,-17),Vector2(-8,17),metal,1,true)
		draw_line(Vector2(-15,0),Vector2(17,0),metal,2,true)
	elif ref in ["arcane_staff","wand","quarterstaff"]:
		draw_line(Vector2(-10,16),Vector2(9,-12),gold,4,true)
		draw_circle(Vector2(10,-13),5,metal)
	else:
		draw_line(Vector2(-10,15),Vector2(11,-15),metal,5,true)
		draw_line(Vector2(-13,1),Vector2(2,11),gold,3,true)
		draw_line(Vector2(-12,18),Vector2(-6,11),ink,4,true)
func scroll_box() -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=Color("b9a77e")
	box.border_color=Color("80704d")
	box.set_border_width_all(1)
	return box
