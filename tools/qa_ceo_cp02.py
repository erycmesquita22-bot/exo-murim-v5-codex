#!/usr/bin/env python3
"""CP02 offline regression/audit: these checks DO NOT run Godot or gameplay."""
from pathlib import Path
import json
import re
import sys
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[1]
out = []
def check(name, success, info=""):
    out.append({"id":name,"status":"PASS" if success else "FAIL","detail":info})

game = (ROOT/"convergence/game.gd").read_text()
functional = (ROOT/"convergence4/tests/qa_functional.gd").read_text()
reopen = (ROOT/"convergence4/tests/qa_reopen.gd").read_text()
s0 = game.index("func save_progress() -> bool:")
s1 = game.index("func _restore_r10_energy",s0)
save = game[s0:s1]
check("p0_snapshot_precedes_prep",save.index("var previous: Dictionary=journey.data.duplicate(true)") <
      save.index("activation_v4.prepare_save()") < save.index("exo_core.prepare_save()"))
check("p0_save_failure_rolls_back",save.count("journey.data=previous")==2 and
      "if ok and exo_core!=null and exo_core.ready:" in save)
check("p0_replay_save_no_side_effects","(flow.replaying or flow.lab_mode)" in save and
      save.index("return super.save_progress()") < save.index("activation_v4.prepare_save()"))
check("p0_failed_auth_rollback", ('journey.data=before_data' + chr(10) + chr(9)*3 + 'return {"ok":false,"code":"interior_forge_authorization"}') in game)
check("p1_entry_world_transform","player.global_position=hall.to_global(" in game and
      "player.position=hall.global_position+" not in game)
check("p1_fall_world_transform","player.global_position=institutional_root.to_global(" in game and
      "institutional_root.position+Vector3(" not in game)
check("p1_interior_autosave", ("autosave_time+=delta"+chr(10)+chr(9)*2+"if autosave_time>20.0:") in game and ("save_progress()"+chr(10)+chr(9)*2+"return") in game)
check("p1_restore_last_position","player.global_position=saved" in game and
      "clear_capsule(get_world_3d().direct_space_state,saved)" in game)
check("qa_forced_save_rollback","failed_save_prep_rollback" in functional and "interior_forced_save_failure" in functional)
check("qa_reopen_uses_exit_marker","remote_exit_rejected_after_reload" in reopen and
      "return_marker_after_reload" in reopen and "exit_proximity_after_reload" in reopen)
check("p2_exit_hint_near_marker",'return "E • Sair do interior" if _near_institutional_exit() else ""' in game)

script_refs = re.compile(r'(?:preload|load)\(\s*"res://([^"]+)"\s*\)')
broken=[]
total=0
for f in ROOT.rglob("*.gd"):
    if f.relative_to(ROOT).parts[:2]==("exo_core","module_template"):
        continue
    for rel in script_refs.findall(f.read_text(errors="replace")):
        total+=1
        if not (ROOT/rel).is_file():broken.append([str(f.relative_to(ROOT)),rel])
check("p0_direct_script_paths",not broken,f"checked={total};broken={broken[:15]}")

scene_total=0
scene_broken=[]
for ext in ("*.tscn","*.tres"):
    for f in ROOT.rglob(ext):
        if f.relative_to(ROOT).parts[:2]==("exo_core","module_template"):
            continue
        for rel in re.findall(r'path="res://([^"]+)"',f.read_text(errors="replace")):
            scene_total+=1
            if not (ROOT/rel).is_file():scene_broken.append([str(f.relative_to(ROOT)),rel])
check("p0_scene_resource_paths",not scene_broken,f"checked={scene_total};broken={scene_broken[:15]}")

json_good=0
json_bad=[]
for f in ROOT.rglob("*.json"):
    try:
        json.loads(f.read_text(encoding="utf-8-sig"));json_good+=1
    except Exception as e: json_bad.append([str(f.relative_to(ROOT)),str(e)])
check("p0_json_parses",not json_bad,f"ok={json_good};bad={json_bad[:10]}")

# A separate embedded Godot template has its own res:// project root.
check("p0_single_main_godot", (ROOT/"project.godot").is_file()
      and (ROOT/"exo_core/module_template/project.godot").is_file())
check("p1_no_second_save_owner","JourneySave.new(" not in save
      and "var ok: bool=super.save_progress()" in save)

evidence = {"source":"EXO-MURIM-V4-CEO-CP01-INTEGRAL","kind":"offline_static_source_validation",
  "executed_in":"Python, current container","godot_native":"NOT_RUN",
  "windows_android":"NOT_RUN","visual":"NOT_RUN",
  "results":out}
target=ROOT/"tools/qa_ceo_cp02_result.json"
target.write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+"\n")
for v in out: print(v["status"],v["id"],v["detail"])
print("RESULT",sum(x["status"]=="PASS" for x in out),"/",len(out),"static checks")
sys.exit(0 if all(x["status"]=="PASS" for x in out) else 1)
