extends RefCounted
# Native planner v3. LAB2 JSON remains authoritative when imported; never silently reroll it.
const BIOMES = ["grassland","temperate_forest","bamboo_forest","dry_valley","wetland","rocky_highlands","alpine","mixed_woodland"]
const NICHES = [Vector3(.34,.43,.67),Vector3(.43,.68,.52),Vector3(.34,.76,.73),Vector3(.27,.24,.76),Vector3(.23,.85,.57),Vector3(.72,.45,.35),Vector3(.89,.46,.22),Vector3(.46,.55,.58)]
const QUOTAS = {"settlement":23,"ruins":12,"dungeon_approach":10,"wild":43}
static func derive(seed_value,domain: String,key=0) -> int:
	return (str(seed_value)+"|GENESIS3|"+domain+"|"+str(key)).sha256_text().substr(0,15).hex_to_int()
static func seed_mod(decimal_value,modulus: int) -> int:
	var result := 0
	for digit in str(decimal_value):result=(result*10+digit.to_int())%modulus
	return result
static func read_atlas(path: String) -> Dictionary:
	# Decimal seed strings prevent Godot JSON float64 rounding of LAB2 int63 values.
	var text := FileAccess.get_file_as_string(path)
	var rx := RegEx.new()
	rx.compile('("(?:seed|region_seed)"\\s*:\\s*)([0-9]+)')
	text=rx.sub(text,'$1"$2"',true)
	return JSON.parse_string(text)
static func roundtrip(doc: Dictionary) -> Dictionary:
	return read_text(JSON.stringify(doc,"",false,true))
static func read_text(text: String) -> Dictionary:
	var rx := RegEx.new();rx.compile('("(?:seed|region_seed)"\\s*:\\s*)([0-9]+)')
	return JSON.parse_string(rx.sub(text,'$1"$2"',true))
static func plan(world_seed) -> Dictionary:
	var rng := RandomNumberGenerator.new();rng.seed=derive(world_seed,"sites")
	var pts := PackedVector2Array()
	var rs: Array=[];var adj: Array=[]
	var noise := FastNoiseLite.new();noise.seed=derive(world_seed,"climate")%2147483647;noise.frequency=2.3
	for i in range(88):
		var p := Vector2((i%11+.5+rng.randf_range(-.35,.35))/11.0,(i/11+.5+rng.randf_range(-.35,.35))/8.0)
		pts.append(p);adj.append([])
		var ridge := .5+.17*sin(p.y*4.5+float(derive(world_seed,"ridge")%10000)/10000*TAU)
		var h := clampf(.36+.13*noise.get_noise_2d(p.x,p.y)+.49*exp(-pow((p.x-ridge)/.13,2)),0,1)
		var wet := clampf(.65+.29*noise.get_noise_2d(p.x+18,p.y+31)-.12*maxf(p.x-ridge,0),0,1)
		var temp := clampf(.93-.34*absf(p.y-.48)*2-.46*h+.12*noise.get_noise_2d(p.x-30,p.y),0,1)
		rs.append({"id":i,"center":[p.x,p.y],"elevation":h,"humidity":wet,"temperature":temp,"kind":"wild","region_seed":str(derive(world_seed,"region",i)),"entrances":[],"biome_weights":{}})
	var edges: Array=[];var seen: Dictionary={}
	var tri := Geometry2D.triangulate_delaunay(pts)
	for t in range(0,tri.size(),3):
		for e in [[tri[t],tri[t+1]],[tri[t],tri[t+2]],[tri[t+1],tri[t+2]]]:
			var a: int=mini(e[0],e[1]);var b: int=maxi(e[0],e[1]);var k := "%d:%d"%[a,b]
			if seen.has(k):continue
			seen[k]=true
			edges.append([pts[a].distance_to(pts[b])*(1+2.3*absf(rs[a].elevation-rs[b].elevation)+.26*absf(rs[a].humidity-rs[b].humidity)),a,b])
	edges.sort_custom(func(a,b): return a[0]<b[0] if a[0]!=b[0] else (a[1]*88+a[2])<(b[1]*88+b[2]))
	# Minimum spanning tree over actual Delaunay geographic neighbors.
	var parent: Array=range(88)
	for edge in edges:
		var a: int=edge[1];var b: int=edge[2]
		var ra := find_root(parent,a);var rb := find_root(parent,b)
		if ra!=rb:parent[rb]=ra;link(adj,a,b)
	# Repair any >4 exit tree node by reconnecting its two components, never rejecting the seed.
	for attempt in range(40):
		var over := -1
		for i in range(88):
			if adj[i].size()>4:over=i;break
		if over<0:break
		var repaired := false
		var neighbors: Array=adj[over].duplicate();neighbors.reverse()
		for neighbor in neighbors:
			adj[over].erase(neighbor);adj[neighbor].erase(over)
			var component := distances(adj,over)
			for edge in edges:
				var a: int=edge[1];var b: int=edge[2]
				if (component[a]<999)==(component[b]<999):continue
				if adj[a].size()>=4 or adj[b].size()>=4:continue
				link(adj,a,b);repaired=true;break
			if repaired:break
			link(adj,over,neighbor)
		if not repaired:break
	var links := 87
	for allow_triangles in [false,true]:
		for edge in edges:
			var a: int=edge[1];var b: int=edge[2]
			if b in adj[a] or adj[a].size()>=4 or adj[b].size()>=4:continue
			if not allow_triangles and distances(adj,a)[b]<3:continue
			link(adj,a,b);links+=1
			if links>=113:break
		if links>=113:break
	var costs: Array=[];var counts: Array=[]
	counts.resize(8);counts.fill(0)
	for r in rs:
		var d: Array=[]
		for n in NICHES:
			var dif: Vector3 = Vector3(r.elevation,r.humidity,r.temperature)-n
			d.append(dif.x*dif.x*1.6+dif.y*dif.y*1.9+dif.z*dif.z*1.5)
		if r.elevation>.56:d[4]+=1.5
		if r.elevation<.68:d[6]+=1.3
		if r.elevation<.55:d[5]+=.3
		if r.humidity<.5:d[2]+=.2
		var k: int=d.find(d.min());r.biome=k;counts[k]+=1;costs.append(d)
	for iteration in range(150):
		var over: int=counts.find(counts.max())
		var distinct := 0
		for c in counts:
			if c>0:distinct+=1
		if counts[over]<=32 and distinct>=6:break
		var best := INF;var ri := -1;var nk := -1
		for i in range(88):
			var old: int=rs[i].biome
			if counts[old]<=2:continue
			if counts[over]>32 and old!=over:continue
			for k in range(8):
				if k==old or counts[k]>=30 or (counts[over]<=32 and counts[k]>0):continue
				var delta: float=costs[i][k]-costs[i][old]
				if delta<best:best=delta;ri=i;nk=k
		if ri<0:break
		counts[rs[ri].biome]-=1;counts[nk]+=1;rs[ri].biome=nk
	for r in rs:r.biome=BIOMES[r.biome]
	var spawn := -1;var score := INF
	for i in range(88):
		if rs[i].biome in ["alpine","rocky_highlands"]:continue
		var s := absf(rs[i].elevation-.34)*1.4+.7*pts[i].distance_to(Vector2(.5,.5))
		if s<score:score=s;spawn=i
	var dist := distances(adj,spawn)
	var settlements: Array=[spawn];rs[spawn].kind="settlement"
	# Farthest-point services over graph distances, all 88 nodes are eligible for coverage.
	while settlements.size()<23:
		var nearest: Array=[];nearest.resize(88);nearest.fill(999)
		for s in settlements:
			var ds := distances(adj,s)
			for i in range(88):nearest[i]=mini(nearest[i],ds[i])
		var pick := -1;var best := -INF
		for i in range(88):
			if rs[i].kind!="wild":continue
			var sc: float=nearest[i]*10-absf(rs[i].elevation-.38)+float(derive(world_seed,"settlement",i)%1000)*.00001
			if sc>best:best=sc;pick=i
		settlements.append(pick);rs[pick].kind="settlement"
	settlements.remove_at(0)
	settlements.sort_custom(func(a,b):return adj[a].size()>adj[b].size() if adj[a].size()!=adj[b].size() else a<b)
	for rank in range(settlements.size()):rs[settlements[rank]].settlement_scale="city" if rank<4 else "town" if rank<11 else "village"
	rs[spawn].settlement_scale="village"
	for kind in ["ruins","dungeon_approach"]:
		var pool: Array=[]
		for i in range(88):
			if rs[i].kind=="wild" and dist[i]>=2:pool.append(i)
		pool.sort_custom(func(a,b):return rs[a].elevation+dist[a]*.025>rs[b].elevation+dist[b]*.025)
		for k in range(QUOTAS[kind]):rs[pool[k]].kind=kind
	var ports: Array=[]
	for a in range(88):
		adj[a].sort()
		for b in adj[a]:
			if b<a:continue
			var delta: Vector2=pts[b]-pts[a];var axis := 0 if absf(delta.x)>=absf(delta.y) else 1
			var pa := [0.0,0.0];var pb := [0.0,0.0]
			pa[axis]=254*signf(delta[axis]);pb[axis]=-pa[axis]
			pa[1-axis]=clampf(delta[1-axis]/absf(delta[axis])*128,-148,148);pb[1-axis]=-pa[1-axis]
			var id := "gate_%02d_%02d"%[a,b]
			ports.append({"id":id,"a":a,"b":b,"from_a":pa,"from_b":pb,"axis":axis,"height_m":6+25*minf(rs[a].elevation,rs[b].elevation),"width_m":8,"clear_radius_m":14,"boundary_palette":{"a":rs[a].biome,"b":rs[b].biome,"transition_width_m":48}})
			rs[a].entrances.append({"gate_id":id,"neighbor":b,"xz":pa});rs[b].entrances.append({"gate_id":id,"neighbor":a,"xz":pb})
	# Pack border reservations. Links keep opposite-facing sides, offsets belong to each local zone.
	for r in rs:
		var groups: Dictionary={}
		for e in r.entrances:
			var axis := 0 if absf(e.xz[0])>253 else 1;var side := str(axis)+str(signf(e.xz[axis]))
			if not groups.has(side):groups[side]=[]
			groups[side].append(e)
		for es in groups.values():
			if es.size()<2:continue
			var axis := 0 if absf(es[0].xz[0])>253 else 1
			es.sort_custom(func(a,b):return a.neighbor<b.neighbor)
			for k in range(es.size()):es[k].xz[1-axis]=(k-(es.size()-1)*.5)*64
	var hydro: Array=[];var rivers: Array=[]
	for i in range(88):
		var dest = null
		for j in adj[i]:
			if rs[j].elevation<rs[i].elevation and (dest==null or rs[j].elevation<rs[dest].elevation):dest=j
		hydro.append({"region":i,"to":dest,"flow":.2+.8*rs[i].humidity,"sink":dest==null})
	var ordered := range(88);ordered.sort_custom(func(a,b):return rs[a].elevation>rs[b].elevation)
	for i in ordered:
		if hydro[i].to!=null:hydro[hydro[i].to].flow+=hydro[i].flow
	for h in hydro:
		if h.to!=null and h.flow>2.3:rivers.append({"from":h.region,"to":h.to,"flow":h.flow})
	for r in rs:
		r.difficulty=mini(6,1+int(dist[r.id]/3));r.asset_palette=r.biome;r.biome_weights={r.biome:1.0}
		var foreign: Dictionary={}
		for e in r.entrances:
			var biome: String=rs[int(e.neighbor)].biome
			if biome!=r.biome:foreign[biome]=foreign.get(biome,0)+1
		if not foreign.is_empty():
			var options: Array=foreign.keys();options.sort()
			var secondary: String=options[0]
			for option in options:
				if foreign[option]>foreign[secondary]:secondary=option
			r.biome_weights={r.biome:.8,secondary:.2}
	return {"version":3,"algorithm":"EXO_GODOT_NATIVE_3","seed":str(world_seed),"region_count":88,"region_extent_m":512.0,"start_region":spawn,"regions":rs,"portals":ports,"hydrology_macro":hydro,"rivers_macro":rivers,"quotas":QUOTAS}
static func find_root(parent: Array,value: int) -> int:
	while parent[value]!=value:value=parent[value]
	return value
static func link(adj: Array,a: int,b: int) -> void:
	adj[a].append(b);adj[b].append(a)
static func distances(adj: Array,start: int) -> Array:
	var d: Array=[];d.resize(adj.size());d.fill(999);d[start]=0
	var q: Array=[start];var cursor := 0
	while cursor<q.size():
		var i: int=q[cursor];cursor+=1
		for j in adj[i]:
			if d[j]==999:d[j]=d[i]+1;q.append(j)
	return d
static func validate(w: Dictionary) -> Array:
	var errors: Array=[];var rs: Array=w.regions;var adj: Array=[];var counts: Dictionary={};var bc: Dictionary={};var sc: Dictionary={}
	if rs.size()!=88:errors.append("count");return errors
	for i in range(88):
		adj.append([]);var r: Dictionary=rs[i]
		if r.id!=i:errors.append("id")
		counts[r.kind]=counts.get(r.kind,0)+1;bc[r.biome]=bc.get(r.biome,0)+1
		if r.kind=="settlement":sc[r.settlement_scale]=sc.get(r.settlement_scale,0)+1
		for key in ["elevation","humidity","temperature"]:
			if not is_finite(r[key]) or r[key]<0 or r[key]>1:errors.append("climate")
		if not str(r.region_seed).is_valid_int() or str(r.region_seed).begins_with("-"):errors.append("seed")
		for a in range(r.entrances.size()):
			for b in range(a):
				var ea: Array=r.entrances[a].xz;var eb: Array=r.entrances[b].xz
				if Vector2(ea[0],ea[1]).distance_to(Vector2(eb[0],eb[1]))<24:errors.append("overlapping_gates")
	if counts!=QUOTAS:errors.append("quotas")
	if sc!={"city":4,"town":7,"village":12}:errors.append("settlement_scales")
	if bc.size()<6 or bc.values().max()>35:errors.append("biomes")
	var ids: Dictionary={}
	for p in w.portals:
		if ids.has(p.id):errors.append("duplicate_gate")
		ids[p.id]=true;link(adj,int(p.a),int(p.b))
		for rid in [int(p.a),int(p.b)]:
			var es: Array=rs[rid].entrances.filter(func(e):return e.gate_id==p.id)
			if es.size()!=1:errors.append("bilateral_gate");continue
			var target: Array=p.from_a if rid==int(p.a) else p.from_b
			if es[0].xz!=target:errors.append("gate_position")
		if absf(p.from_a[int(p.axis)]+p.from_b[int(p.axis)])>.001:errors.append("opposite_facing")
		if p.boundary_palette.a!=rs[int(p.a)].biome or p.boundary_palette.b!=rs[int(p.b)].biome:errors.append("palette")
	var d := distances(adj,int(w.start_region))
	if d.max()==999:errors.append("connected")
	if w.portals.size()<107:errors.append("loops")
	for a in adj:
		if a.size()>4:errors.append("degree")
	var start: Dictionary=rs[int(w.start_region)]
	if start.kind!="settlement" or start.biome in ["alpine","rocky_highlands"]:errors.append("spawn")
	var nearest: Array=[];nearest.resize(88);nearest.fill(999)
	for r in rs:
		if r.kind=="dungeon_approach" and d[int(r.id)]<2:errors.append("dungeon_spawn")
		if r.kind=="settlement":
			var ds := distances(adj,int(r.id))
			for i in range(88):nearest[i]=mini(nearest[i],ds[i])
	if nearest.max()>4:errors.append("service_coverage")
	for h in w.hydrology_macro:
		if h.to!=null and rs[int(h.to)].elevation>=rs[int(h.region)].elevation:errors.append("uphill_river")
	return errors
static func save_atlas(doc: Dictionary,path: String) -> Error:
	if not validate(doc).is_empty():return ERR_INVALID_DATA
	var temporary := path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(JSON.stringify(doc,"\t",false,true));file.flush();file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))
