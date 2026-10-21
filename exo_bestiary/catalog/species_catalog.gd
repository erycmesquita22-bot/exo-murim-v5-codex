extends RefCounted
# Somente perfis; não instancia inimigos nem altera a ecologia.
const PATH_SPECIES := "res://exo_bestiary/data/species.json"
const PATH_HUMANS := "res://exo_bestiary/data/humanoids.json"
const PATH_SPECIAL := "res://exo_bestiary/data/elites_bosses.json"
const PATH_ATTACKS := "res://exo_bestiary/data/attacks.json"
var species: Dictionary = {}
var humans: Dictionary = {}
var elites: Dictionary = {}
var bosses: Dictionary = {}
var attacks: Dictionary = {}
var errors: Array[String] = []
func load_data() -> bool:
    errors.clear(); species.clear(); humans.clear(); elites.clear(); bosses.clear(); attacks.clear()
    var d: Variant = _load_json(PATH_SPECIES)
    var h: Variant = _load_json(PATH_HUMANS)
    var s: Variant = _load_json(PATH_SPECIAL)
    var a: Variant = _load_json(PATH_ATTACKS)
    if not (d is Dictionary and h is Dictionary and s is Dictionary and a is Dictionary):
        errors.append("invalid_json"); return false
    if d.get("schema") != 2 or h.get("schema") != 2 or s.get("schema") != 1 or a.get("schema") != 1:
        errors.append("schema_mismatch"); return false
    if not (d.get("species") is Array and h.get("profiles") is Array and s.get("elites") is Array and s.get("bosses") is Array and a.get("attacks") is Dictionary):
        errors.append("invalid_collections"); return false
    for attack_id in a.attacks:
        var at: Variant = a.attacks[attack_id]
        if not at is Dictionary or str(at.get("id", "")) != str(attack_id) or float(at.get("range", 0)) <= 0.0:
            errors.append("invalid_attack:" + str(attack_id)); return false
        attacks[attack_id] = at.duplicate(true)
    if not _index(d.species, species, "species"): return false
    if not _index(h.profiles, humans, "humanoid"): return false
    if not _index(s.elites, elites, "elite"): return false
    if not _index(s.bosses, bosses, "boss"): return false
    for id in elites:
        if not humans.has(elites[id].get("base")) and not species.has(elites[id].get("base")):
            errors.append("unknown_elite_base:" + id)
    for id in bosses:
        if not humans.has(bosses[id].get("base")) and not species.has(bosses[id].get("base")):
            errors.append("unknown_boss_base:" + id)
    return errors.is_empty() and species.size() >= 12 and humans.size() >= 8 and elites.size() >= 3 and bosses.size() >= 2
func _load_json(path: String) -> Variant:
    if not FileAccess.file_exists(path): return null
    return JSON.parse_string(FileAccess.get_file_as_string(path))
func _index(items: Array, target: Dictionary, kind: String) -> bool:
    for value in items:
        if not value is Dictionary:
            errors.append("non_object:" + kind); return false
        var id: String = str(value.get("id", ""))
        if id.is_empty() or not id.is_valid_identifier() or target.has(id):
            errors.append("bad_id:" + kind + ":" + id); return false
        if kind in ["species", "humanoid"]:
            var ids: Variant = value.get("attacks")
            if not ids is Array or ids.is_empty():
                errors.append("missing_attacks:" + id); return false
            for attack_id in ids:
                if not attacks.has(attack_id):
                    errors.append("undefined_attack:" + id + ":" + str(attack_id)); return false
        target[id] = value.duplicate(true)
    return true
func get_profile(id: String) -> Dictionary:
    if species.has(id):return species[id].duplicate(true)
    if humans.has(id):return humans[id].duplicate(true)
    var special: Dictionary = {}
    var category: String = ""
    if elites.has(id):special=elites[id].duplicate(true);category="elite"
    elif bosses.has(id):special=bosses[id].duplicate(true);category="boss"
    if special.is_empty():return {}
    var parent: Dictionary=get_profile(str(special.get("base","")))
    if parent.is_empty():return {}
    parent["base_id"]=str(special.base)
    parent.merge(special,true)
    parent["category"]=category
    return parent
func list_profiles(category: String = "") -> Array:
    var out: Array = []
    for table in [species, humans, elites, bosses]:
        var keys: Array = table.keys(); keys.sort()
        for id in keys:
            var p: Dictionary=get_profile(str(id))
            if category.is_empty() or str(p.get("category", "")) == category:out.append(p)
    return out
func get_attack(id: String) -> Dictionary:
    return attacks.get(id, {}).duplicate(true)
func summary() -> Dictionary:
    return {"species":species.size(),"humanoids":humans.size(),"elites":elites.size(),"bosses":bosses.size(),"attacks":attacks.size(),"errors":errors.duplicate()}
