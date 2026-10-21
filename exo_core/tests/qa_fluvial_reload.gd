extends "res://validation_r3/support.gd"
const Save=preload("res://journey_save.gd")
func _initialize():call_deferred("run_reload")
func normalized(value):return JSON.parse_string(JSON.stringify(value))
func run_reload():
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://exo_core/evidence/fluvial_integrated/reload_expected.json"))
 await boot("user://exo_fluvial_integrated_v3.json",true)
 w.set_physics_process(false)
 check(w.current_region==int(expected.region),"same_real_city_new_process")
 check(w.exo_core.architecture_status().status=="ready","river_wall_rebuilt_new_process")
 check(w.active_region.data.digest()==expected.digest,"terrain_and_identity_deterministic")
 check(normalized(w.journey.data.items)==expected.items,"inventory_exact")
 check(normalized(w.journey.data.character)==expected.character,"appearance_exact")
 check(normalized(w.journey.data.narrative)==expected.narrative,"narrative_exact")
 check(normalized(w.journey_manager.state().progress)==expected.progress,"no_extra_xp_on_reload")
 check(normalized(w.residents.map(func(actor):return actor.identity.id))==expected.npc_ids,"same_existing_npcs")
 for old_version in [4,5]:
  var legacy: Dictionary=w.journey.data.duplicate(true);legacy.convergence.regional_version=old_version
  var path: String="user://fluvial_regional_legacy_%d.json"%old_version
  FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(legacy))
  var old=Save.new(path)
  check(old.load_progress(),"accept_legacy_regional_"+str(old_version))
  check(normalized(old.data.items)==expected.items and normalized(old.data.character)==expected.character,"legacy_player_data_preserved_"+str(old_version))
 check(int(w.extension().regional_version)==6 and w.journey.data.version==4,"regional_v6_root_save_v4")
 await finish("fluvial_reload")
