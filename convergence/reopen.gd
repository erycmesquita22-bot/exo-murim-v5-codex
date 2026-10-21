extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
func _initialize():call_deferred("run")
func run():
 w=Game.new();w.load_on_start=true;w.save_path="user://convergence_qa.json";root.add_child(w)
 for i in range(800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 var state: Dictionary=w.extension()
 var ok: bool=w.current_region==int(state.current) and w.current_region>=0 and not w.residents.is_empty() and w.journey.valid(w.journey.data)
 var identity_ok:=true
 for actor in w.residents:
  if w.journey.data.living_world.npcs[actor.identity.id]!=actor.identity:identity_ok=false
 var report={"pass":ok and identity_ok,"current_region":w.current_region,"physical_npcs":w.residents.size(),"identity_match":identity_ok,"engine":Engine.get_version_info()}
 FileAccess.open("res://convergence/reopen_result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("REOPEN_RESULT ",JSON.stringify(report));w.set_paused(false);w.audio_fx.shutdown();w.free();quit(0 if ok and identity_ok else 1)
