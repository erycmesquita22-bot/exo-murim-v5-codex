extends RefCounted
## EXO Character Refit 01 is the only authored garment creator.
## Compatibility API retained for gameplay, prologue, NPCs, UI and skin importer.
const Catalog=preload("res://catalog.gd")
const Anatomy=preload("res://anatomy.gd")
const Arsenal=preload("res://arsenal.gd")
const ExoIdentity=preload("res://exo_identity.gd")
const Skin3D=preload("res://exo_skin3d/appearance_adapter.gd")
const NewGarments=preload("res://exo_character_refit01/geometry.gd")
const ROBES=NewGarments.PALETTES
const HAIRS=NewGarments.HAIR
const SKINS=["efd5be","dbb399","c79670","a77853","7b503d","4e352c"]

# Prologue/other legacy scripts call Wardrobe.piece for stage-specific props.
static func piece(parent:Node3D,pos:Vector3,size:Vector3,color:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new()
	var box:=BoxMesh.new();box.size=size;node.mesh=box
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.88
	node.material_override=mat;parent.add_child(node);node.position=pos
	return node

static func apply(rig:Node3D,profile:Dictionary)->void:
	if rig==null or not is_instance_valid(rig):return
	var chosen:Dictionary=profile.duplicate(true)
	# NPC appearances do not always specify clothing: deterministic visual variation
	# derived from identity, never from the frame or the saved gameplay schema.
	var stable:String=str(chosen.get("id",chosen.get("uid",chosen.get("name","npc"))))
	if not chosen.has("robe"):
		chosen["robe"]=posmod(stable.hash(),ROBES.size())
	if not chosen.has("haircut"):
		chosen["haircut"]=posmod((stable+"/haircut").hash(),4)
	if not chosen.has("hair"):
		chosen["hair"]=posmod((stable+"/hair").hash(),HAIRS.size())
	if not chosen.has("outfit"):
		chosen["outfit"]=posmod((stable+"/outfit").hash(),4)
	var race:Dictionary=Catalog.RACES[clampi(int(chosen.get("race",0)),0,Catalog.RACES.size()-1)]
	rig.set_meta("surface","metal" if race.body=="mechanical" else "body")
	rig.set_meta("voice",int(chosen.get("voice",0)))
	var imported:String=str(chosen.get("skin_file",""))
	var image:Image=ExoIdentity.paint(chosen)
	var imported_ok:bool=false
	if imported.begins_with("user://exo_skins/") and FileAccess.file_exists(imported):
		var supplied:=Image.new()
		if supplied.load(imported)==OK and supplied.get_width()==64 and supplied.get_height()==64:
			image=supplied
			imported_ok=true
	chosen["_refit_imported_skin"]=imported_ok
	rig.skin.albedo_texture=ImageTexture.create_from_image(image)
	rig.skin.albedo_color=Color.WHITE
	if not rig.has_meta("exo_base_scale"):rig.set_meta("exo_base_scale",rig.scale)
	var base_scale:Vector3=rig.get_meta("exo_base_scale")
	var body_scale:Vector3=ExoIdentity.BODY_SCALE[clampi(int(chosen.get("body",0)),0,6)]
	rig.scale=Vector3(base_scale.x*body_scale.x,base_scale.y*body_scale.y,base_scale.z*body_scale.z)
	rig.set_meta("robe_color",Color(ROBES[posmod(int(chosen.get("robe",0)),ROBES.size())]))
	rig.set_meta("skin_color",Color(SKINS[posmod(int(chosen.get("skin",0)),SKINS.size())]))
	# Remove R2 visual overlays before replacing garments; preserve R2 save selection data.
	preload("res://exo_humanoids03_r2/scripts/murim_wardrobe.gd").clear(rig)
	NewGarments.apply(rig,chosen)
	Anatomy.apply(rig,int(chosen.get("race",0)))
	Arsenal.equip(rig,str(chosen.get("weapon","sword")))
	Skin3D.apply(rig,chosen)

static func animate_cloth(rig:Node3D,time:float,moving:bool)->void:
	NewGarments.animate_cloth(rig,time,moving)
