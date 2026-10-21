#!/usr/bin/env python3
"""EXO-Murim CEO checkpoint: structural source QA (NOT Godot runtime QA)."""
from __future__ import annotations
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = []

def check(label, condition, detail=""):
    RESULTS.append({"id": label, "status": "PASS" if condition else "FAIL", "detail": detail})
    return condition

game = (ROOT / "convergence/game.gd").read_text(encoding="utf-8-sig")
builder = (ROOT / "exo_interior_forge/runtime/interior_builder.gd").read_text(encoding="utf-8-sig")
functional = (ROOT / "convergence4/tests/qa_functional.gd").read_text(encoding="utf-8-sig")
walker = ROOT / "qa/walker.gd"
check("p0_player_save_single_owner", "super.save_progress()" in game and "exo_core.prepare_save()" in game)
check("p0_death_force_recovery_not_normal_interact",
      '_exit_institutional_interior(true)' in game
      and "func _exit_institutional_interior(force_recovery: bool = false)" in game
      and 'not force_recovery and not _near_institutional_exit()' in game)
check("p1_only_exit_at_door",
      '"InteriorExit"' in game and '"InteriorReturn"' in game
      and 'absf(delta.y) <= 2.2' in game
      and 'Vector2(delta.x, delta.z).length() <= 2.2' in game)
check("p1_save_interior_position",
      "_record_institutional_save_position()" in game
      and 'visit["interior_position"]' in game
      and "clear_capsule(get_world_3d().direct_space_state,saved)" in game)
check("p2_hud_exit_hint_proximity",
      'return "E • Sair do interior" if _near_institutional_exit() else ""' in game)
check("p2_visual_backdrop_nonphysical",
      'IsolatedDarkBackdrop' in builder
      and 'mats["dark"], false)' in builder)
check("p2_authorial_prefabs_untouched",
      len(list((ROOT / "exo_interior_forge").rglob("*.json"))) >= 52)
check("qa_door_actor_present", walker.is_file() and "extends CharacterBody3D" in walker.read_text())
check("qa_door_failure_covered",
      "interior_exit_rejects_remote_E" in functional
      and "interior_exit_authorized_at_door" in functional)
# Nested exo_core/module_template/ is an independent example Godot project
# with its own res:// root; do not incorrectly report its valid template preload.
refs = re.compile(r'(?:preload|load)\(\s*"res://([^"]+)"\s*\)')
missing = []
checks = 0
for source in ROOT.rglob("*.gd"):
    if source.relative_to(ROOT).parts[:2] == ("exo_core", "module_template"):
        continue
    for rel in refs.findall(source.read_text(errors="replace")):
        checks += 1
        if not (ROOT / rel).is_file():
            missing.append([str(source.relative_to(ROOT)), rel])
check("p0_static_preloads_resolve", not missing, f"checked={checks};missing={missing}")
# Store source QA evidence outside the project's live scenes and imports.
payload = {
    "kind": "source_static_only",
    "engine_import": "NOT_RUN",
    "godot_native": "NOT_RUN",
    "android": "NOT_RUN",
    "scenario": "C02 + restricted interior exit, save point, QA door walker and backdrop",
    "results": RESULTS
}
outfile = ROOT / "tools/qa_ceo_p0p1p2_result.json"
outfile.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
for item in RESULTS:
    print(item["status"], item["id"], item["detail"])
print(f"RESULT: {sum(x['status']=='PASS' for x in RESULTS)}/{len(RESULTS)} static checks passed")
sys.exit(0 if all(x["status"] == "PASS" for x in RESULTS) else 1)
