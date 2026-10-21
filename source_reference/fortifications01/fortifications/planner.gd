extends RefCounted
## EXO Fortificações 01 — pure geometry planning, without mutating Genesis.
## Adapter: plan_region(region_data); explicit result statuses ready/partial/skipped/invalid.
const VERSION := 1
const MAX_SECTION_M := 2.8

static func _cross(a: Vector2,b: Vector2) -> float:
	return a.x*b.y-a.y*b.x
static func _nearest(p: Vector2,a: Vector2,b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))
static func _perimeter(poly: Array) -> Array:
	var d: Array=[0.0]
	for i in range(poly.size()): d.append(float(d.back())+poly[i].distance_to(poly[(i+1)%poly.size()]))
	return d
static func _ring_point(poly: Array,dist: Array,s: float) -> Vector2:
	var circumference: float=dist.back()
	var q: float=fposmod(s,circumference)
	for i in range(poly.size()):
		if q<=float(dist[i+1])+0.000001:
			return (poly[i] as Vector2).lerp(poly[(i+1)%poly.size()],clampf((q-float(dist[i]))/maxf(0.00001,float(dist[i+1])-float(dist[i])),0,1))
	return poly[0]
static func _arc_dist(a: float,b: float,around: float) -> float:
	return absf(fposmod(a-b+around*.5,around)-around*.5)
static func _hit(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> Dictionary:
	var r: Vector2=b-a
	var s: Vector2=d-c
	var den: float=_cross(r,s)
	if absf(den)<0.00000001:return {}
	var qp: Vector2=c-a
	var t: float=_cross(qp,s)/den
	var u: float=_cross(qp,r)/den
	if t < -0.0000001 or t>1.0000001 or u < -0.0000001 or u>1.0000001:return {}
	return {"t":clampf(t,0,1),"u":clampf(u,0,1)}
static func _empty(status: String,scale: String,reason: String) -> Dictionary:
	return {"version":VERSION,"status":status,"scale":scale,"errors":[reason],"segments":[],"openings":[],"towers":[],"polygon":[],"skipped":{}}
static func _centered_poly(center: Vector2,side: Vector2,forward: Vector2,limits: Array,ch: float) -> Array:
	var lx: float=limits[0];var hx: float=limits[1];var ly: float=limits[2];var hy: float=limits[3]
	var xy: Array=[Vector2(lx+ch,ly),Vector2(hx-ch,ly),Vector2(hx,ly+ch),Vector2(hx,hy-ch),Vector2(hx-ch,hy),Vector2(lx+ch,hy),Vector2(lx,hy-ch),Vector2(lx,ly+ch)]
	var poly: Array=[]
	for t in xy:poly.append(center+side*t.x+forward*t.y)
	return poly
static func _routes(contract: Dictionary) -> Array:
	var lines: Array=[]
	for r in contract.get("streets",[]):lines.append({"a":r.a,"b":r.b,"width":float(r.get("width",5)),"tag":str(r.get("kind","street"))})
	for g in contract.get("gates",[]):lines.append({"a":Vector2.ZERO,"b":g.p,"width":float(g.get("width",7)),"tag":"world_portal"})
	return lines
static func _waters(contract: Dictionary) -> Array:
	var lines: Array=[]
	for r in contract.get("rivers",[]):lines.append({"a":contract.get("river_hub",Vector2(72,72)),"b":r.p})
	return lines
static func _gap(s: float,opening: Array,around: float) -> bool:
	for o in opening:
		if _arc_dist(s,float(o.s),around)<float(o.width)*.5+0.00000001:return true
	return false

static func plan_region(data: RefCounted) -> Dictionary:
	if data.settlement_plan.get("status","invalid")!="ready":return _empty("skipped","","genesis_settlement_not_ready")
	var contract: Dictionary={"ready":true,"region_id":int(data.spec.id),"scale":str(data.spec.settlement_scale),"lots":data.lots,"streets":data.settlement_plan.streets,"fixtures":data.settlement_plan.fixtures,"gates":data.gates,"rivers":data.rivers,"river_hub":data.river_hub,"half_extent":data.half}
	return plan_contract(contract,Callable(data,"height_at"))

static func plan_contract(c: Dictionary,height: Callable) -> Dictionary:
	var scale: String=str(c.get("scale",""))
	if not bool(c.get("ready",false)) or not (scale in ["city","town","village"]):return _empty("invalid",scale,"not_ready_or_scale")
	var lots: Array=c.get("lots",[])
	var streets: Array=c.get("streets",[])
	if lots.is_empty() or streets.is_empty() or not height.is_valid():return _empty("invalid",scale,"missing_input")
	var forward: Vector2=(streets[0].b-streets[0].a).normalized()
	var side := Vector2(-forward.y,forward.x)
	var center := Vector2.ZERO
	var lx := INF;var hx := -INF;var ly := INF;var hy := -INF
	var ch := 1.8
	var selected: Dictionary={}
	if scale=="city":
		for lot in lots:
			var radius: float=float(lot.get("halfsize",5.5))+15.5
			var x: float=(lot.p as Vector2).dot(side)
			var y: float=(lot.p as Vector2).dot(forward)
			lx=minf(lx,x-radius);hx=maxf(hx,x+radius)
			ly=minf(ly,y-radius);hy=maxf(hy,y+radius)
		for f in c.get("fixtures",[]):
			var pt: Vector2=f.p
			var radius: float=float(f.get("halfsize",2.5))+12.0
			lx=minf(lx,pt.dot(side)-radius);hx=maxf(hx,pt.dot(side)+radius)
			ly=minf(ly,pt.dot(forward)-radius);hy=maxf(hy,pt.dot(forward)+radius)
		lx=minf(lx,-13.0);hx=maxf(hx,13.0);ly=minf(ly,-13.0);hy=maxf(hy,13.0)
		ch=minf(14.,minf((hx-lx)*.09,(hy-ly)*.09))
	else:
		var ordered: Array=lots.duplicate()
		ordered.sort_custom(func(a,b):
			var ar: int=0 if str(a.get("function","")) in ["inn","martial_school","farmstead","administration"] else 1
			var br: int=0 if str(b.get("function","")) in ["inn","martial_school","farmstead","administration"] else 1
			return ar < br if ar != br else str(a.id) < str(b.id))
		for lot in ordered:
			var r: float=float(lot.get("halfsize",5.5))+3.4
			if float(lot.get("frontage",0))<r+4.0:continue
			var conflict := false
			for other in lots:
				if other.id!=lot.id and (lot.p as Vector2).distance_to(other.p)<r+float(other.get("halfsize",5.5))+2.0:conflict=true;break
			if conflict:continue
			for water in _waters(c):
				if _nearest(lot.p,water.a,water.b)<r+11.0:conflict=true;break
			if not conflict:selected=lot;break
		if selected.is_empty():return _empty("skipped",scale,"no_safe_courtyard")
		center=selected.p
		forward=(selected.street_point-selected.p).normalized()
		side=Vector2(-forward.y,forward.x)
		var r: float=float(selected.get("halfsize",5.5))+3.4
		lx=-r;hx=r;ly=-r;hy=r
	var poly: Array=_centered_poly(center,side,forward,[lx,hx,ly,hy],ch)
	var half: float=float(c.get("half_extent",256))
	for pt in poly:
		if absf(pt.x)>half-18 or absf(pt.y)>half-18:return _empty("skipped",scale,"perimeter_outside_region")
	var dist: Array=_perimeter(poly)
	var around: float=dist.back()
	if around<30:return _empty("invalid",scale,"degenerate_perimeter")
	var roads: Array=_routes(c) if scale=="city" else [{"a":selected.door,"b":selected.street_point,"width":4.0,"tag":"courtyard_entry"}]
	var waters: Array=_waters(c) if scale=="city" else []
	var openings: Array=[]
	for typ in ["gate","river"]:
		var lines: Array=roads if typ=="gate" else waters
		for path in lines:
			var a: Vector2=path.a;var b: Vector2=path.b
			var width: float=float(path.get("width",12.0))
			for i in range(poly.size()):
				var c1: Vector2=poly[i];var d1: Vector2=poly[(i+1)%poly.size()]
				var h: Dictionary=_hit(a,b,c1,d1)
				if h.is_empty():continue
				var angle: float=absf(_cross((d1-c1).normalized(),(b-a).normalized()))
				var requested: float=maxf(5.5 if typ=="gate" and scale!="city" else 9.0,width+5.0)
				var open_width: float=minf(70.0,requested/maxf(.22,angle))
				var s: float=fposmod(float(dist[i])+(d1-c1).length()*float(h.u),around)
				var duplicate := false
				for old in openings:
					if old.type==typ and _arc_dist(s,float(old.s),around)<1.5:duplicate=true;break
				if not duplicate:openings.append({"s":s,"width":open_width,"type":typ,"source":str(path.get("tag","river")),"point":_ring_point(poly,dist,s),"tangent":(d1-c1).normalized()})
	if scale!="city":
		var has_gate:=false
		for opening in openings:
			if opening.type=="gate":has_gate=true;break
		if not has_gate:return _empty("invalid",scale,"courtyard_no_entrance")
	var boundaries: Array=[0.0,around]
	for k in range(1,dist.size()-1):boundaries.append(float(dist[k]))
	for op in openings:
		for sign_value in [-1.0,1.0]:boundaries.append(fposmod(float(op.s)+sign_value*float(op.width)*.5,around))
	boundaries.sort()
	var segments: Array=[]
	var skipped: Dictionary={"river":0,"road":0,"steep":0,"near_road":0}
	for k in range(boundaries.size()-1):
		var lo: float=boundaries[k];var hi: float=boundaries[k+1]
		if hi-lo<.000001:continue
		var s: float=(lo+hi)*.5
		if _gap(s,openings,around):
			var river_gap:=false
			for op in openings:
				if op.type=="river" and _arc_dist(s,float(op.s),around)<float(op.width)*.5:river_gap=true;break
			skipped["river" if river_gap else "road"]+=1
			continue
		var count: int=maxi(1,int(ceil((hi-lo)/MAX_SECTION_M)))
		for j in range(count):
			var s0: float=lerpf(lo,hi,float(j)/float(count))
			var s1: float=lerpf(lo,hi,float(j+1)/float(count))
			var a: Vector2=_ring_point(poly,dist,s0)
			var b: Vector2=_ring_point(poly,dist,s1)
			var mid: Vector2=a.lerp(b,.5)
			var reject:=false
			if scale=="city":
				for road in roads:
					if _nearest(mid,road.a,road.b)<float(road.width)*.5+2.5:skipped.near_road+=1;reject=true;break
			if reject:continue
			for water in waters:
				if _nearest(mid,water.a,water.b)<11.0:skipped.river+=1;reject=true;break
			if reject:continue
			var ground: Array=[];var vmin:=INF;var vmax:=-INF
			for frac in [0.0,.25,.5,.75,1.0]:
				var hval: float=float(height.call(a.lerp(b,frac)))
				if not is_finite(hval):reject=true;break
				vmin=minf(vmin,hval);vmax=maxf(vmax,hval);ground.append(hval)
			if reject or vmax-vmin>2.4:skipped.steep+=1;continue
			segments.append({"a":a,"b":b,"base":vmin-.65,"top":vmax+(6.2 if scale=="city" else 2.8),"heights":ground})
	var towers: Array=[]
	if scale=="city":
		for s in dist.slice(0,-1):
			if _gap(float(s),openings,around):continue
			var keep:=true
			for op in openings:
				if _arc_dist(float(s),float(op.s),around)<float(op.width)*.5+5.5:keep=false;break
			var p: Vector2=_ring_point(poly,dist,float(s))
			if keep:
				for path in waters:
					if _nearest(p,path.a,path.b)<14.:keep=false;break
			if keep:
				for road in roads:
					if _nearest(p,road.a,road.b)<float(road.width)*.5+5.:keep=false;break
			if keep:towers.append({"p":p,"height":float(height.call(p))})
	var result_status: String="ready" if segments.size()>0 and int(skipped.steep)==0 and int(skipped.near_road)==0 else "partial" if segments.size()>0 else "invalid"
	return {"version":VERSION,"status":result_status,"region_id":int(c.get("region_id",-1)),"scale":scale,"kind":"city_wall" if scale=="city" else "courtyard_wall", "polygon":poly,"perimeter_m":around,"segments":segments,"openings":openings,"towers":towers,"skipped":skipped,"errors":[] if segments.size()>0 else ["no_valid_wall_segments"],"selected_lot":str(selected.get("id",""))}
