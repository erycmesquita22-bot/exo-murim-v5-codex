extends SceneTree
# Run after copying the module into the REAL EXO R13 project:
# godot --headless --path /path/to/exo_project --script res://exo_skill_forge/tests/qa_native.gd
const Catalog = preload("res://exo_skill_forge/runtime/catalog.gd")
const Planner = preload("res://exo_skill_forge/runtime/planner.gd")
const Validator = preload("res://exo_skill_forge/runtime/validator.gd")
const Presentation = preload("res://exo_skill_forge/runtime/presentation_router.gd")
var passed: int = 0
var failed: int = 0

func check(condition: bool, name: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL:", name)

func _initialize() -> void:
	var catalog = Catalog.new()
	check(catalog.initialize(), "R13 catalog loads")
	if not catalog.loaded:
		printerr(catalog.issues)
		quit(1)
		return
	var summary: Dictionary = catalog.summary()
	check(int(summary["legacy"]) == 16, "16 original skills")
	check(int(summary["authorial_candidates"]) == 168, "168 authorial candidates, including 140 R2")
	check(int(summary["total"]) == 184, "184 total in R2")
	check(catalog.query({"power_family": "sangue", "inspiration_origin": "manhwa"}).size() == 5, "R2 blood/manhwa filter")
	check(catalog.query({"power_family": "armas"}).size() == 20, "R2 weapon group")
	check(catalog.query({"inspiration_origin": "cinema"}).size() == 35, "R2 cinema group")
	check(catalog.query({"rarity_tier": 5, "power_family": "celestial"}).size() == 4, "R2 celestial high tier")
	check(int(summary["styles"]) == 12, "12 martial styles")
	check(int(summary["schools"]) == 9, "9 schools")
	check(catalog.get_skill("corte_inicial")["executor"] == "legacy", "legacy preserved")
	check(catalog.get_skill("exo.sf.fio_do_bambu")["executor"] == "generic", "new template")
	check(catalog.query({"weapon_pose": "fists"}).size() > 0, "fist filtering")
	check(catalog.query({"school": "exo_martial.school.seita_bambu"}).size() > 0, "school filtering")
	var candidate: Dictionary = catalog.get_skill("exo.sf.fio_do_bambu")
	var plan: Dictionary = Planner.compose(candidate, {"type": "npc", "weapon_pose": "blade", "level": 20})
	check(bool(plan.get("ok", false)), "npc simulation planning")
	check(float(plan["cost"]["stamina"]) > 0, "stamina present")
	check(plan["unbound_media"].size() >= 3, "media pending marked")
	check(not Planner.compose(candidate, {"type": "npc", "weapon_pose": "staff"}).get("ok", true), "invalid pose denied")
	check(not Planner.compose(candidate, {"type": "npc", "level": 0}).get("ok", true), "insufficient level denied")
	var result: Dictionary = Presentation.dispatch(plan, "impact", null, {})
	check(bool(result.get("ok", false)) and int(result["dispatched"]) == 0, "pending media not played")
	var broken: Dictionary = candidate.duplicate(true)
	broken["balance"]["qi"] = -1
	check(not Validator.verify(broken, catalog.refs["styles"], catalog.refs["schools"], catalog.refs["poses"], catalog.refs["templates"]).is_empty(), "negative Qi denied")
	print("EXO SKILL FORGE NATIVE QA PASS=", passed, " FAIL=", failed)
	quit(1 if failed > 0 else 0)
