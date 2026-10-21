extends RefCounted
## Copies the actual canonical Resident rig texture. No demo assets or repainting.
static func capture(region: Node3D, residents: Array) -> Dictionary:
	var images: Array[Image] = []
	var sources: Array = []
	for actor in residents:
		if not is_instance_valid(actor) or not is_instance_valid(actor.rig): continue
		var texture: Texture2D = actor.rig.skin.albedo_texture
		if texture == null: continue
		var image: Image = texture.get_image()
		if image == null or image.is_empty(): continue
		if image.is_compressed() and image.decompress() != OK: continue
		if image.get_size() != Vector2i(256,256): continue
		image.convert(Image.FORMAT_RGBA8)
		images.append(image)
		var digest := HashingContext.new()
		digest.start(HashingContext.HASH_SHA256); digest.update(image.get_data())
		sources.append({"npc_id": str(actor.identity.id), "rgba_sha256": digest.finish().hex_encode()})
		if images.size() == 64: break
	if images.is_empty():
		if region.has_meta("exo_crowd_npc_atlas"):region.remove_meta("exo_crowd_npc_atlas")
		return {"ok":false,"reason":"canonical_npc_textures_missing"}
	var atlas := Image.create(2048,2048,false,Image.FORMAT_RGBA8)
	for i in range(64):
		atlas.blit_rect(images[i % images.size()],Rect2i(0,0,256,256),Vector2i((i%8)*256,(i/8)*256))
	region.set_meta("exo_crowd_npc_atlas",ImageTexture.create_from_image(atlas))
	var receipt := {"ok":true,"owner":"Resident.rig.skin.albedo_texture","tile_size":256,"slots":64,"sources":sources,"outer_layers":false,"slim":false}
	region.set_meta("exo_crowd_npc_skin_receipt",receipt)
	return receipt
