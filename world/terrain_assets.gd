extends RefCounted
# EXO 09.4.6 — reusable, tileable, CC0-equivalent (original project-generated) ground artwork.
# Shared materials are cached; textures repeat in WORLD SPACE on terrain and roads.
const TYPES=["grass_lush","grass_dry","earth","forest_soil","stone","gravel","moss_stone","trail"]
const ROOT="res://assets/terrain/"
static var cache: Dictionary={}

static func texture_for(kind: String) -> Texture2D:
	var id: String=kind if kind in TYPES else "grass_lush"
	return load(ROOT+id+".png") as Texture2D

static func material(kind: String) -> StandardMaterial3D:
	var id: String=kind if kind in TYPES else "grass_lush"
	if cache.has(id):return cache[id] as StandardMaterial3D
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color.WHITE
	mat.albedo_texture=texture_for(id)
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.roughness=1.0
	mat.metallic=0.0
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	cache[id]=mat
	return mat

static func material_for_box(kind: String,box_size: Vector3) -> StandardMaterial3D:
	# BoxMesh UVs default to 0..1: scale repeated textures by the size of the tile.
	var mat: StandardMaterial3D=material(kind).duplicate() as StandardMaterial3D
	mat.uv1_scale=Vector3(maxf(1.0,box_size.x/2.7),maxf(1.0,box_size.y/2.7),maxf(1.0,box_size.z/2.7))
	return mat

static func textured_block(w: Node3D,position: Vector3,size: Vector3,kind: String,solid: bool=false) -> MeshInstance3D:
	var mesh: MeshInstance3D=w.block(position,size,Color.WHITE,solid)
	mesh.material_override=material_for_box(kind,size)
	return mesh
