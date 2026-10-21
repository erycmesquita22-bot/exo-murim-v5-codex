extends Control
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var gold:=Color("a38e60")
	var cyan:=Color("aeb9c4")
	for p in [Vector2(8,8),Vector2(size.x-8,8),Vector2(8,size.y-8),Vector2(size.x-8,size.y-8)]:
		var direction:=Vector2(1 if p.x<size.x/2 else -1,1 if p.y<size.y/2 else -1)
		draw_line(p,p+Vector2(direction.x*29,0),gold,2)
		draw_line(p,p+Vector2(0,direction.y*29),gold,2)
		draw_circle(p+direction*6,2,cyan)
	for x in [size.x*.3,size.x*.7]:
		var p:=Vector2(x,8)
		draw_polyline(PackedVector2Array([p+Vector2(-8,0),p+Vector2(0,5),p+Vector2(8,0)]),gold,1)
