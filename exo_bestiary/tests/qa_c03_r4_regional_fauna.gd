extends SceneTree
# Nativo para Godot 4.6.2 Compatibility. NÃO é evidência até ser executado.
const Atlas=preload("res://genesis/world_planner.gd")
const Data=preload("res://genesis/region_data.gd")
const Territory=preload("res://regional_ecology/territories.gd")
const Species=preload("res://exo_bestiary/catalog/species_catalog.gd")
const Inventory=preload("res://inventory.gd")
const Fauna=preload("res://exo_bestiary/integration/regional_fauna_actor.gd")
var passed:=0
var failed:=0
func check(ok: bool,n: String) -> void:
    if ok:passed+=1
    else:failed+=1;push_error("R4_FAIL "+n)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var catalog=Species.new()
    check(catalog.load_data(),"catalog_load")
    check(catalog.summary().species>=16,"catalog_16")
    var atlas: Dictionary=preload("res://genesis/v4/world_plan.gd").decorate(Atlas.read_atlas("res://genesis/atlas_seed_101.json"),"fauna-qa")
    var kinds:=0
    var total_sites:=0
    for rid in range(88):
        var data=Data.new(atlas,rid)
        var old: Array=Territory.build(data,"101")
        var a: Array=Territory.build_fauna(data,"101",catalog.list_profiles(),old)
        var b: Array=Territory.build_fauna(data,"101",catalog.list_profiles(),old)
        var stable: bool=a.size()==b.size()
        if stable:
            for index in range(a.size()):
                if str(a[index].id)!=str(b[index].id) or str(a[index].species)!=str(b[index].species) or a[index].p!=b[index].p:
                    stable=false;break
        check(stable,"seed_determinism_r"+str(rid))
        check(a.size()<=(8 if str(data.spec.kind)=="wild" else 4 if str(data.spec.kind)=="settlement" else 3),"site_budget_r"+str(rid))
        for site in a:
            check(str(site.id).begins_with("eco/r"),"stable_id")
            check(not catalog.get_profile(str(site.species)).is_empty(),"species_profile")
            check(data.road_distance(site.p)>=11.0 and data.river_distance(site.p)>=18.0,"terrain_exclusions")
            check(data.pad_distance(site.p)>=18.0,"lot_exclusion")
            if str(site.species) in ["wolf","corrupted_wolf"]:check(int(site.group_size)>=3,"minimum_wolf_pack")
            total_sites+=1
        if not a.is_empty():kinds+=1
    check(total_sites>0 and kinds>0,"fauna_sites_present")
    var p: Dictionary=catalog.get_profile("wolf")
    var actor=Fauna.new()
    get_root().add_child(actor)
    check(actor.has_method("setup_regional") and actor.has_method("hurt") and actor.has_method("revive_after_failed_commit"),"host_actor_contract")
    check(Inventory.valid_item({"uid":"item_7","kind":"material","ref":"hide","qty":1}),"hide_valid")
    check(Inventory.valid_item({"uid":"item_8","kind":"material","ref":"fang","qty":1}),"fang_valid")
    check(not Inventory.valid_item({"uid":"item_9","kind":"material","ref":"unknown","qty":1}),"no_arbitrary_material")
    actor.queue_free()
    print("C03_R4_NATIVE_FAUNA ",JSON.stringify({"pass":passed,"fail":failed,"sites":total_sites}))
    quit(0 if failed==0 else 1)
