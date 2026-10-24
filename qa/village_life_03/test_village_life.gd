extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var scene: PackedScene = load("res://modules/village_npcs/VillageNPCs_V11.tscn")
 var host = scene.instantiate()
 root.add_child(host)
 await process_frame
 host.title_flow.visible = false
 host.heart_menu.visible = false
 host.heart_menu.has_session = true
 paused = false
 host.enable_training_rival = false
 host._sync_regions(true)
 var result := {"residents":host.village_npcs.residents.size(),"households":0,"animals":0,"beasts":0,"skeletons":{},"cultivation_clip":false,"beast_damage":false,"beast_states":[],"fps":0.0,"dodge_avoids_hit":false,"household_census":false,"beast_clips":false,"master_defense":false,"face_variants":0,"hair_colors":0,"height_span":0.0,"motion_clips":false,"aura_runtime":false,"key_badges":false,"loaded_face_textures":0,"silver_hair_texture":false,"scheduled_work_plays":false,"qi_phases":[],"night_neon_gain":false,"tier_refraction_scales":false}
 var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/village_npcs/roster.json"))
 result.households = roster.households.size()
 result.household_census = roster.households.all(func(h): return h.count == h.residents.size()) and roster.households.reduce(func(total,h): return total+h.count,0)==29
 for animal in host.wildlife.creatures.values():
  if str(animal.spec.kind)=="animal":result.animals += 1
  else: result.beasts += 1
  var skeleton = animal.visual.find_children("*","Skeleton3D",true,false)[0]
  result.skeletons[str(animal.spec.rig)] = skeleton.get_bone_count()
 result.face_variants = roster.npcs.map(func(n): return n.face).reduce(func(a,b): a[b]=true;return a,{}).size()
 result.hair_colors = roster.npcs.map(func(n): return n.hair.color).reduce(func(a,b): a[b]=true;return a,{}).size()
 var heights: Array = roster.npcs.map(func(n): return float(n.body_style.height))
 result.height_span = heights.max()-heights.min()
 var loaded_faces := {}
 for npc in host.village_npcs.residents.values():
  for mesh in npc.visual.find_children("*","MeshInstance3D",true,false):
   if mesh.name.begins_with("HEAD_skin") and mesh.material_override is StandardMaterial3D:
    loaded_faces[mesh.material_override.albedo_texture.resource_path] = true
 result.loaded_face_textures = loaded_faces.size()
 var silver = host.village_npcs.residents["terrace_master_weak"]
 for mesh in silver.visual.find_children("*","MeshInstance3D",true,false):
  if mesh.name.begins_with("HEAD_hair") and mesh.material_override is StandardMaterial3D:
   result.silver_hair_texture = mesh.material_override.albedo_texture.resource_path == str(silver.record.face_path)
 var disciple = host.village_npcs.residents["family_main_hall_01"]
 result.motion_clips = disciple.animator.has_animation("village_life/Train_Form") and host.village_npcs.residents["farm_home_a_01"].animator.has_animation("village_life/Field_Work") and host.village_npcs.residents["tea_worker"].animator.has_animation("village_life/Serve_Tea") and host.village_npcs.residents["house_gate_01"].animator.has_animation("village_life/Guard_Survey")
 result.cultivation_clip = disciple.animator.has_animation("village_life/Cultivate")
 var farmer = host.village_npcs.residents["farm_home_a_01"]
 farmer.set_village_active(true)
 for minute in range(450,1050,30):
  farmer.clock_minutes = minute
  if farmer._idle_variation() == farmer.work_clip: break
 var field_target: Vector3 = farmer._destination()
 farmer.body.position = Vector3(field_target.x,host._terrain_height(field_target.x,field_target.z)+.55,field_target.z)
 farmer.state = "IDLE"
 farmer._physics_process(.016)
 result.scheduled_work_plays = farmer.animator.current_animation == farmer.work_clip
 var wolf = host.wildlife.creatures["ash_wolf_a"]
 host.actor.position = wolf.home+Vector3(0,.5,4.8)
 host.actor.velocity = Vector3.ZERO
 var initial_hp: int = host.health.hp
 print("BEFORE active=",wolf.active," wolf=",wolf.body.position," player=",host.actor.position," remote=",host._remote()," paused=",paused," can=",wolf.can_process())
 for i in 420: await physics_frame
 print("AFTER wolf=",wolf.body.position," player=",host.actor.position," hp=",host.health.hp," state=",wolf.state)
 result.beast_damage = host.health.hp < initial_hp
 host.dodge_invulnerable = true
 var dodged_hp: int = host.health.hp
 wolf._attack_area()
 result.dodge_avoids_hit = host.health.hp == dodged_hp
 result.beast_clips = wolf.animator.has_animation("Attack") and host.wildlife.creatures["moon_stag"].animator.has_animation("Attack_Headbutt") and host.wildlife.creatures["moon_stag"].animator.has_animation("Attack_Kick")
 result.beast_states = [wolf.state,wolf.combo_index]
 var master = host.village_npcs.residents["estate_master_weak"]
 host.actor.position = master.body.position+Vector3(0,0,2.5)
 master.set_village_active(true)
 host.health.hp = 120
 host.dodge_invulnerable = false
 var master_hp: int = master.hp
 master.take_hit(30,host.actor.position)
 result.master_defense = master_hp-master.hp <= 12 and host.health.hp == 102
 master.state = "CULTIVATE"
 master.body.position = master._destination()+Vector3(0,host._terrain_height(master._destination().x,master._destination().z)+.55,0)
 master._physics_process(.016)
 result.aura_runtime = master.qi_orbit.visible and master.qi_orbit.get_child_count() >= 7
 for sample in [0.2,2.6,7.3,9.6]:
  master.cultivation_time = sample
  master.state = "CULTIVATE"
  master._physics_process(.016)
  result.qi_phases.append(master.cultivation_stage)
 master.qi_orbit.update_fx(true,"circulate",.5,false,.016)
 var day_alpha: float = (master.qi_orbit.ground_ring.material_override as StandardMaterial3D).albedo_color.a
 master.qi_orbit.update_fx(true,"circulate",.5,true,.016)
 var night_alpha: float = (master.qi_orbit.ground_ring.material_override as StandardMaterial3D).albedo_color.a
 result.night_neon_gain = night_alpha > day_alpha and master.qi_orbit.night_light.light_energy > 0
 var tier_two: float = master.qi_orbit.distortion_power()
 master.qi_orbit.tier = 4
 var tier_four: float = master.qi_orbit.distortion_power()
 result.tier_refraction_scales = tier_four > tier_two and tier_two > 0
 master.qi_orbit.tier = 2
 result.key_badges = master.badge_background != null and master.plate.text.contains("Refinamento inicial") and host.village_npcs.residents["ji_wol"].badge_background != null
 result.fps = Performance.get_monitor(Performance.TIME_FPS)
 print("VILLAGE_LIFE_TEST ",JSON.stringify(result))
 var file := FileAccess.open("res://qa/village_life_03/test_result.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"\t"));file.close()
 host.queue_free()
 await process_frame
 call_deferred("quit",0 if result.residents==29 and result.animals==3 and result.beasts==3 and result.cultivation_clip and result.beast_damage and result.dodge_avoids_hit and result.household_census and result.beast_clips and result.master_defense and result.face_variants>=12 and result.hair_colors>=10 and result.height_span>=.25 and result.motion_clips and result.aura_runtime and result.key_badges and result.loaded_face_textures>=12 and result.silver_hair_texture and result.scheduled_work_plays and result.qi_phases==["gather","circulate","release","settle"] and result.night_neon_gain and result.tier_refraction_scales else 2)
