extends SceneTree
## Godot 4.6.2 Compatibility actual GDScript QA (NOT_RUN until an executable is available).
## godot --headless --path <standalone-project> --script res://exo_city_forge/qa/qa_run.gd
const Composer=preload("res://exo_city_forge/runtime/city_composer.gd")
const Registry=preload("res://exo_city_forge/runtime/city_registry.gd")
var failures: Array=[]
var passes: int=0
func _check(ok: bool,name: String) -> void:
 if ok:passes+=1
 else:failures.append(name)
func _initialize() -> void:
 var catalog: Dictionary=Registry.catalog()
 _check(catalog.blueprints.size()==14,"r4_14_blueprints")
 _check(catalog.districts.size()==60,"r4_60_districts")
 _check(catalog.profiles.size()==13,"r4_13_urban_profiles")
 _check(catalog.landmarks.size()==16,"r4_16_landmarks")
 var distinct: Dictionary={}
 for d in catalog.districts:
  var geometry: String=JSON.stringify(d.buildings)+JSON.stringify(d.internal_streets)
  _check(not distinct.has(geometry),"distinct_district:"+str(d.id))
  distinct[geometry]=true
 var tested: int=0
 for blueprint in catalog.blueprints:
  var scale: String="city" if "city" in blueprint.allowed_scales else str(blueprint.allowed_scales[0])
  for profile in catalog.profiles:
   if scale not in profile.get("allowed_scales",["village","town","city"]):continue
   for seed in range(40):
    var request: Dictionary={"region_id":seed%88,"region_seed":str(seed*41+2026),"kind":"settlement","settlement_scale":scale,"profile_id":str(profile.id),"blueprint_id":str(blueprint.id),"half_extent":256.0,"gates":[[0,-230]],"rivers":[],"monument_reservations":[],"mode":"authored_modular"}
    var result: Dictionary=Composer.compose(request)
    _check(str(result.get("status",""))=="ready","ready:"+str(blueprint.id)+":"+str(profile.id)+":"+str(seed))
    if str(result.get("status",""))!="ready":continue
    var repeated: Dictionary=Composer.compose(request)
    _check(JSON.stringify(result)==JSON.stringify(repeated),"stable:"+str(blueprint.id)+":"+str(seed))
    var buildings: int=result.get("buildings",[]).size()
    if scale=="village":_check(buildings>=4 and buildings<=10,"village_4_10_lots")
    if scale=="town":_check(buildings>=12 and buildings<=26,"town_12_26_lots")
    tested+=1
 var req: Dictionary={"region_id":26,"region_seed":"816204","kind":"settlement","settlement_scale":"village","profile_id":"rural_farming_village","blueprint_id":"aldeia_pomar_cruz","half_extent":256.0,"gates":[[0,-230]],"rivers":[],"monument_reservations":[],"mode":"authored_modular"}
 _check(str(Composer.compose(req).get("status",""))=="ready","village_smoke")
 req["half_extent"]=20.0
 _check(str(Composer.compose(req).get("status",""))=="invalid","reject_small_region")
 req["half_extent"]=256.0
 req["monument_reservations"]=[{"min_x":-40,"max_x":-20,"min_z":-40,"max_z":-20}]
 _check(str(Composer.compose(req).get("status",""))=="invalid","reject_r7_reservation")
 req["monument_reservations"]=[]
 req["blocked_r7_contract"]=true
 _check(str(Composer.compose(req).get("status",""))=="invalid","fail_closed_r7")
 # Adversarial inputs must explicitly fail closed rather than silently build a city.
 var bad: Dictionary={"region_id":26,"region_seed":"-1042","kind":"settlement","settlement_scale":"city","profile_id":"poor_martial_city","blueprint_id":"orthogonal_market","half_extent":256.0,"gates":[[0,-230]],"rivers":[],"monument_reservations":[],"mode":"authored_modular"}
 _check(str(Composer.compose(bad).get("status",""))=="ready","negative_seed_is_valid")
 bad["settlement_scale"]="moon"
 _check(str(Composer.compose(bad).get("status",""))=="invalid","unknown_scale_rejected")
 bad["settlement_scale"]="city"
 bad["kind"]="ruins"
 _check(str(Composer.compose(bad).get("status",""))=="invalid","non_settlement_rejected")
 bad["kind"]="settlement"
 bad["gates"]=[[INF,0]]
 _check(str(Composer.compose(bad).get("status",""))=="invalid","nonfinite_gate_rejected")
 bad["gates"]=[[0,-230]]
 bad["half_extent"]=INF
 _check(str(Composer.compose(bad).get("status",""))=="invalid","nonfinite_extent_rejected")
 bad["half_extent"]=256.0
 bad["monument_reservations"]=[{"min_x":5.0,"max_x":-5.0,"min_z":-3.0,"max_z":3.0}]
 _check(str(Composer.compose(bad).get("status",""))=="invalid","inverted_r7_rejected")
 bad["monument_reservations"]=[]
 bad["profile_id"]="missing_profile"
 _check(str(Composer.compose(bad).get("status",""))=="invalid","unknown_profile_rejected")
 var report: Dictionary={"suite":"city_forge_r4_native","status":"PASS" if failures.is_empty() else "FAIL","passes":passes,"failures":failures,"sampled_compositions":tested,"native_engine":Engine.get_version_info()}
 print(JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
