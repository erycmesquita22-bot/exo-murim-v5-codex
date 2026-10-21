extends RefCounted
## Versioned, additive physical planning. Never changes C3 region IDs, graph or ownership.
const CATALOG="res://genesis/v4/profiles.json"
const Planner=preload("res://genesis/world_planner.gd")
static var cached:Dictionary={}
static func catalog()->Dictionary:
 if cached.is_empty():
  var raw:Variant=JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
  if raw is Dictionary:cached=raw
 return cached
static func profile(spec:Dictionary)->Dictionary:
 var entries:Dictionary=catalog().get("biomes",{})
 if not entries.has(str(spec.get("biome",""))):return {}
 var result:Dictionary=entries[str(spec.biome)].duplicate(true)
 var number:int=Planner.derive(spec.region_seed,"WG4/profile")
 result["form"]=result.forms[number%result.forms.size()]
 result["yaw"]=float(number%628319)/100000.0
 result["ridge_offset"]=float(number%51)-25.0
 result["ridge_width"]=38.0+float(number%33)
 result["relief"]=float(result.relief)*(0.86+float(number%29)/100.0)
 result["tree_budget"]=int(result.trees)
 result["site_family_shift"]=number%4
 return result
static func decorate(source:Dictionary,world_id:String,core:RefCounted=null)->Dictionary:
 # Normalize through the existing JourneySave JSON representation before geometry.
 var atlas:Dictionary=freeze(source)
 atlas["worldgen_v4"]={"schema":1,"generator":4,"catalog_sha256":FileAccess.get_sha256(CATALOG),"handoff_ratio":0.76,"landmark_templates":catalog().get("landmarks",[]).duplicate(true)}
 for row in atlas.regions:
  var p:Dictionary=profile(row)
  # Preserved authored Jade anchor from the homologated LAB2 seed.
  if str(atlas.seed)=="101" and int(row.id)==15:p["site_family_shift"]=0
  row["worldgen_v4"]={"schema":1,"profile":p,"authorial":[]}
  if core!=null and core.services.has_service("content.library"):
   var context:Dictionary={"world_id":world_id,"seed":int(str(atlas.seed)),"region_id":int(row.id),"biome":str(row.biome),"settlement_type":str(row.get("settlement_scale","none")),"flags":[],"tags":[],"player_tier":1}
   var proposal:Variant=core.services.invoke("content.library","preview",["world",context,["biome_identity","region_theme","landmark_theme"]])
   if proposal is Dictionary and proposal.get("status")=="PROPOSAL_ONLY":
    row.worldgen_v4.authorial=proposal.get("proposals",[]).duplicate(true)
    # Accept only geometric vocabulary backed by existing host builders.
    for choice in row.worldgen_v4.authorial:
     if str(choice.get("domain",""))=="region_theme":
      var theme:String=str(choice.get("variables",{}).get("theme",""))
      if theme=="martial":row.worldgen_v4.profile.site_family_shift=int(p.site_family_shift)%2
      elif theme in ["pilgrimage","shrine"]:row.worldgen_v4.profile.site_family_shift=2
      elif theme in ["outlaw","pass"]:row.worldgen_v4.profile.site_family_shift=3
     elif str(choice.get("domain",""))=="landmark_theme":
      var feature:String=str(choice.get("variables",{}).get("feature",""))
      row.worldgen_v4.profile["landmark_preference"]={"shrine":2,"road_marker":0}.get(feature,-1)
  if str(atlas.seed)=="101" and int(row.id)==15:row.worldgen_v4.profile.site_family_shift=0
 return freeze(atlas)
static func freeze(value:Dictionary)->Dictionary:
 return JSON.parse_string(JSON.stringify(value))
static func valid_atlas(atlas:Dictionary)->bool:
 if not atlas.get("worldgen_v4") is Dictionary:return false
 var meta:Dictionary=atlas.worldgen_v4
 if meta.get("schema")!=1 or meta.get("generator")!=4 or str(meta.get("catalog_sha256","")).length()!=64:return false
 if not (meta.get("handoff_ratio") is int or meta.get("handoff_ratio") is float):return false
 if not meta.get("landmark_templates") is Array or meta.landmark_templates.size()!=4:return false
 if not is_finite(float(meta.handoff_ratio)):return false
 var template_ids:Array=[]
 for template in meta.landmark_templates:
  if not template is Dictionary:return false
  if template.get("id") not in ["waystone","lookout","trail_shrine","rest_stop"] or template.id in template_ids:return false
  if not template.get("title") is String or not template.get("description") is String:return false
  template_ids.append(template.id)
 if float(meta.get("handoff_ratio",0.0))<0.7 or float(meta.handoff_ratio)>1.0:return false
 if not atlas.get("regions") is Array or atlas.regions.size()!=88:return false
 for row in atlas.regions:
  if not row.get("worldgen_v4") is Dictionary:return false
  if row.worldgen_v4.get("schema")!=1 or not row.worldgen_v4.get("authorial") is Array:return false
  var p:Variant=row.worldgen_v4.get("profile")
  if not p is Dictionary or not p.get("form") is String:return false
  for key in ["relief","yaw","ridge_offset","ridge_width","tree_budget","cluster_cut","blend_m"]:
   if not (p.get(key) is int or p.get(key) is float) or not is_finite(float(p[key])):return false
  if float(p.tree_budget)!=floor(float(p.tree_budget)):return false
  for key in ["site_family_shift","landmark_preference"]:
   var choice:Variant=p.get(key,-1 if key=="landmark_preference" else null)
   if not (choice is int or choice is float) or not is_finite(float(choice)):return false
   if float(choice)!=floor(float(choice)) or float(choice)>3.0 or float(choice)<(-1.0 if key=="landmark_preference" else 0.0):return false
  if float(p.relief)<0.0 or float(p.relief)>75.0 or int(p.tree_budget)<0 or int(p.tree_budget)>200:return false
  if float(p.ridge_width)<30.0 or float(p.ridge_width)>90.0 or float(p.blend_m)<48.0 or float(p.blend_m)>100.0:return false
 return true
