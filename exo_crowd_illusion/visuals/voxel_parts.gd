extends RefCounted
## Original voxel skin mesh. Standard vanilla 64x64 base UVs; classic limb width.
## Six reusable meshes, instanced by MultiMesh. Outer layer and slim are future adapter work.
static var _cache: Dictionary = {}

static func mesh_for(part: String) -> ArrayMesh:
	if _cache.has(part):
		return _cache[part]
	var sizes := {"head": Vector3(0.5,0.5,0.5), "body": Vector3(0.5,0.75,0.25),
		"arm_r": Vector3(0.25,0.75,0.25), "arm_l": Vector3(0.25,0.75,0.25),
		"leg_r": Vector3(0.25,0.75,0.25), "leg_l": Vector3(0.25,0.75,0.25)}
	var mappings := {"head": Vector2i(0,0), "body": Vector2i(16,16),
		"arm_r": Vector2i(40,16), "arm_l": Vector2i(32,48),
		"leg_r": Vector2i(0,16), "leg_l": Vector2i(16,48)}
	if not sizes.has(part):
		return ArrayMesh.new()
	var size: Vector3 = sizes[part]
	var uv_base: Vector2i = mappings[part]
	var px_w := 8 if part in ["head", "body"] else 4
	var px_h := 8 if part == "head" else 12
	var px_d := 8 if part == "head" else 4
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	var hd := size.z * 0.5
	# Face winding is deliberately two-sided: material uses cull_disabled.
	var faces: Array = [
		{"v":[Vector3(-hw,hh,-hd),Vector3(hw,hh,-hd),Vector3(hw,hh,hd),Vector3(-hw,hh,hd)],"uv":[px_d,0,px_w,px_d]}, # top
		{"v":[Vector3(-hw,-hh,hd),Vector3(hw,-hh,hd),Vector3(hw,-hh,-hd),Vector3(-hw,-hh,-hd)],"uv":[px_d+px_w,0,px_w,px_d]}, # bottom
		{"v":[Vector3(-hw,hh,-hd),Vector3(-hw,hh,hd),Vector3(-hw,-hh,hd),Vector3(-hw,-hh,-hd)],"uv":[0,px_d,px_d,px_h]}, # right
		{"v":[Vector3(-hw,hh,hd),Vector3(hw,hh,hd),Vector3(hw,-hh,hd),Vector3(-hw,-hh,hd)],"uv":[px_d,px_d,px_w,px_h]}, # front
		{"v":[Vector3(hw,hh,hd),Vector3(hw,hh,-hd),Vector3(hw,-hh,-hd),Vector3(hw,-hh,hd)],"uv":[px_d+px_w,px_d,px_d,px_h]}, # left
		{"v":[Vector3(hw,hh,-hd),Vector3(-hw,hh,-hd),Vector3(-hw,-hh,-hd),Vector3(hw,-hh,-hd)],"uv":[px_d*2+px_w,px_d,px_w,px_h]} # back
	]
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for face in faces:
		var offset := verts.size()
		var patch: Array = face["uv"]
		var vface: Array = face["v"]
		var face_normal: Vector3 = (vface[1] - vface[0]).cross(vface[2] - vface[0]).normalized()
		for v in vface:
			verts.append(v)
			normals.append(face_normal)
		for coord in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
			uvs.append(Vector2((float(uv_base.x) + float(patch[0]) + coord.x * float(patch[2])) / 64.0,
				(float(uv_base.y) + float(patch[1]) + coord.y * float(patch[3])) / 64.0))
		for idx in [0,1,2,0,2,3]:
			indices.append(offset + idx)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_cache[part] = mesh
	return mesh
