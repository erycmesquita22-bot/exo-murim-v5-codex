extends RefCounted
# One shared road graph per loaded region; shortest paths never cut across blocks.
var points: Array[Vector2]=[]
var edges: Dictionary={}
var streets: Array=[]
var data: RefCounted
func node(p: Vector2) -> int:
	for i in range(points.size()):
		if points[i].distance_to(p)<.02:return i
	points.append(p);edges[points.size()-1]={};return points.size()-1
func build(region_data: RefCounted) -> void:
	data=region_data;streets=data.settlement_roads
	for s in streets:node(s.a);node(s.b)
	for a in streets:
		for b in streets:
			var cross: Variant=Geometry2D.segment_intersects_segment(a.a,a.b,b.a,b.b)
			if cross is Vector2:node(cross)
	for lot in data.lots:node(lot.street_point)
	for s in streets:
		var chain: Array=[]
		for i in range(points.size()):
			if points[i].distance_to(Geometry2D.get_closest_point_to_segment(points[i],s.a,s.b))<.03:chain.append(i)
		chain.sort_custom(func(a,b):return points[a].distance_to(s.a)<points[b].distance_to(s.a))
		for k in range(1,chain.size()):
			var a: int=chain[k-1];var b: int=chain[k];var d: float=points[a].distance_to(points[b])
			edges[a][b]=d;edges[b][a]=d
func route(a: Vector3,b: Vector3) -> Array:
	var ai: int=-1;var bi: int=-1;var da:=INF;var db:=INF
	for i in range(points.size()):
		var x: float=points[i].distance_to(Vector2(a.x,a.z));var y: float=points[i].distance_to(Vector2(b.x,b.z))
		if x<da:ai=i;da=x
		if y<db:bi=i;db=y
	if ai<0 or bi<0:return []
	var dist: Dictionary={ai:0.0};var prev: Dictionary={};var open: Array=[ai]
	while not open.is_empty():
		open.sort_custom(func(x,y):return dist[x]<dist[y]);var current: int=open.pop_front()
		if current==bi:break
		for next in edges[current]:
			var score: float=float(dist[current])+float(edges[current][next])
			if score<float(dist.get(next,INF)):
				dist[next]=score;prev[next]=current
				if next not in open:open.append(next)
	if not dist.has(bi):return []
	var ids: Array=[bi]
	while ids[0]!=ai:ids.push_front(prev[ids[0]])
	var result: Array=[]
	for i in ids:
		var p: Vector2=points[i];result.append(Vector3(p.x,data.height_at(p)+.05,p.y))
	return result
