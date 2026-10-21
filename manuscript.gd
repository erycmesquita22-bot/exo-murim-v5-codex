extends Control
var clock:=0.0
var dark:=false
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	clock+=delta
	if dark:queue_redraw()
func _draw() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=6404
	if dark:
		draw_rect(Rect2(Vector2.ZERO,size),Color("08090c"))
		for i in range(34):
			var x:=fposmod(rng.randf()*size.x+sin(clock*.13+i)*22,size.x)
			var y:=fposmod(rng.randf()*size.y-clock*(3+i%4),size.y)
			draw_circle(Vector2(x,y),rng.randf_range(.5,1.6),Color(.72,.73,.78,.08))
		for side in [-1,1]:
			var x:=size.x*(.08 if side<0 else .92)
			draw_line(Vector2(x,size.y*.16),Vector2(x,size.y*.84),Color(.45,.46,.5,.1),1)
	else:
		for i in range(280):
			var point:=Vector2(rng.randf()*size.x,rng.randf()*size.y)
			draw_line(point,point+Vector2(rng.randf_range(2,30),rng.randf_range(-1,1)),Color(.65,.59,.45,.035),1)
