extends SceneTree
# Run with Godot 4.6.2: --headless --path <root> --script res://convergence/tests/qa_c03_r8_native.gd
# This is a native SCRIPT/API smoke test, NOT F5 gameplay or enrollment proof.
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
const State=preload("res://exo_martial/r2/state_r2.gd")
const Module=preload("res://exo_martial/module.gd")
const Host=preload("res://convergence/martial_host_r8.gd")
const NarrativeOwner=preload("res://narrative/society/authorized_master_disciple.gd")
func _initialize() -> void:
 var ok:bool=true
 var cat:Dictionary=Catalog.valid_catalogs()
 if not bool(cat.get("ok",false)) or Catalog.schools().size()!=9 or Catalog.styles().size()!=12 or Catalog.techniques().size()!=16:
  push_error("R8 native: invalid official martial catalog");ok=false
 var state:Dictionary=State.fresh("101")
 if not State.valid(state):push_error("R8 native: fresh R2 domain invalid");ok=false
 if not Module.new().has_method("configure_host_integrations"):push_error("R8 native: Martial API missing");ok=false
 if not Host.new().has_method("trusted_social_proof"):push_error("R8 native: host adapter missing");ok=false
 print("C03_R8_NATIVE_SMOKE ","PASS" if ok else "FAIL"," (does not replace scene/gameplay QA)")
 quit(0 if ok else 1)
