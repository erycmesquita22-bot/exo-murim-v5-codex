extends RefCounted
## Convergencia 03 Alfa R5 — adaptador somente visual.
## O actor Bestiary/RegionalEcology continua dono de colisao, IA, dano e saves.
## Nao gera novos atores nem substitui a autoridade de spawn existente.

static func attach_visual(holder: Node3D, descriptor: Dictionary) -> Dictionary:
    if holder == null or not is_instance_valid(holder):
        return {}
    var scene_path: String = str(descriptor.get("scene", ""))
    if not scene_path.begins_with("res://exo_creature_harmonizacao02/scenes/"):
        return {}
    if not scene_path.ends_with(".tscn") or not ResourceLoader.exists(scene_path):
        return {}
    var scene: PackedScene = load(scene_path) as PackedScene
    if scene == null:
        return {}
    var instance: Node = scene.instantiate()
    if not instance is Node3D:
        if instance != null:
            instance.queue_free()
        return {}
    # P0 stand-ins are generic silhouettes, not the species-specific authored
    # visual. Keep Bestiary's original procedural anatomy/leg animation rather
    # than hiding it behind an identical brown quadruped for every species.
    var candidates:Array=[instance]
    candidates.append_array(instance.find_children("*","Node3D",true,false))
    for candidate in candidates:
        if str(candidate.get_meta("provenance","")).contains("code-generated replacement"):
            instance.free()
            return {}
    # Somente ocultar a geometria voxel depois de termos uma cena valida.
    # O holder continua rotacionado pela locomocao e conserva os pivots originais.
    var old_nodes: Array[Node3D] = []
    for child in holder.get_children():
        if child is Node3D:
            old_nodes.append(child)
    var previous_scale: Vector3 = holder.scale
    holder.add_child(instance)
    instance.name = "HarmonizedVisualR5"
    for old in old_nodes:
        old.visible = false
    # As cenas .tscn harmonizadas ja contem escala/orientacao por especie.
    # Evita multiplicar novamente por species.stats.size do voxel procedural.
    holder.scale = Vector3.ONE
    var player: AnimationPlayer = find_animation_player(instance)
    return {"root": instance, "player": player, "voxel_nodes": old_nodes, "previous_scale": previous_scale, "species_id": str(descriptor.get("species_id", ""))}

static func find_animation_player(root: Node) -> AnimationPlayer:
    if root == null:
        return null
    var pending: Array[Node] = [root]
    while not pending.is_empty():
        var node: Node = pending.pop_back()
        if node is AnimationPlayer:
            return node
        for child in node.get_children():
            pending.append(child)
    return null

static func clip_for(player: AnimationPlayer, action: String) -> String:
    if player == null or not is_instance_valid(player):
        return ""
    var wanted: String = action.to_lower()
    for clip in player.get_animation_list():
        var name: String = str(clip)
        if name.to_lower() == wanted or name.get_file().to_lower() == wanted:
            return name
    # Algumas importacoes guardam os clips em bibliotecas com prefixos variados.
    for clip in player.get_animation_list():
        var name: String = str(clip)
        if name.to_lower().ends_with("/" + wanted):
            return name
    return ""

static func play_action(binding: Dictionary, action: String) -> bool:
    var player: AnimationPlayer = binding.get("player", null)
    if player == null or not is_instance_valid(player):
        return false
    var clip: String = clip_for(player, action)
    if clip.is_empty() and action == "run":
        clip = clip_for(player, "walk")
    if clip.is_empty():
        return false
    if str(player.current_animation) != clip or not player.is_playing():
        player.play(clip, 0.12)
    return true

static func detach_visual(holder: Node3D, binding: Dictionary) -> void:
    if binding.is_empty() or holder == null or not is_instance_valid(holder):
        return
    var model: Node3D = binding.get("root", null)
    if model != null and is_instance_valid(model):
        holder.remove_child(model)
        model.queue_free()
    holder.scale = binding.get("previous_scale", Vector3.ONE)
    for old in binding.get("voxel_nodes", []):
        if old != null and is_instance_valid(old):
            old.visible = true
