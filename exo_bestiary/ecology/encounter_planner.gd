extends RefCounted
const Habitat = preload("res://exo_bestiary/ecology/ecosystem_rules.gd")
const Variants = preload("res://exo_bestiary/catalog/variant_generator.gd")
# Retorna proposta para Regional Ecology. Não instancia, não altera save.
static func suggest(catalog, region: Dictionary, candidates: Array, seed: int, max_new: int = 2) -> Array:
    var valid: Array=[]
    var all: Array=catalog.list_profiles()
    for p in all:
        if str(p.get("category", "")) in ["elite","boss","humanoid"]:continue
        if p.get("stats",{}).is_empty():continue
        if Habitat.habitat_matches(p,region): valid.append(p)
    valid.sort_custom(func(a,b):return str(a.id)<str(b.id))
    var out: Array=[]
    for i in range(mini(candidates.size(),maxi(0,max_new))):
        var point: Variant=candidates[i]
        if not point is Dictionary or not bool(point.get("surface_valid",false)) or bool(point.get("visible",true)) or bool(point.get("protected",true)):
            continue
        if valid.is_empty(): break
        var index: int=posmod(Variants.stable_hash("%d/%d/%s"%[seed,i,str(region.get("id",0))]),valid.size())
        out.append({"profile":valid[index].id,"position":point.get("position",Vector3.ZERO),"approval_required":"regional_ecology"})
    return out
