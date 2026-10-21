extends SceneTree
const Catalog=preload("res://exo_bestiary/catalog/species_catalog.gd")
const Variants=preload("res://exo_bestiary/catalog/variant_generator.gd")
const AI=preload("res://exo_bestiary/ai/behavior_controller.gd")
var failure:=0
func _initialize() -> void:
    var c=Catalog.new()
    if not c.load_data():print("EXO_BESTIARY_MASSIVE_FAIL load_data");quit(2);return
    var profiles: Array=c.list_profiles()
    var iterations:=25000
    for i in range(iterations):
        var p: Dictionary=profiles[i%profiles.size()]
        var uid: String="r%02d/t%02d/m%02d/g%04d"%[i%88,i%4,i%7,i%40]
        var v: Dictionary=Variants.variant_for(p,i%97,uid)
        if v.is_empty() or v!=Variants.variant_for(p,i%97,uid):failure+=1
        var controller=AI.new();controller.configure(p)
        var state: Dictionary=controller.step({"hp_ratio":float(i%100)/100.0,"target_visible":i%3!=0,"predator_visible":i%11==0,"intruding":i%2==0,"outside_territory":i%29==0,"territory_exists":i%33!=0,"distance":float(i%12),"attack_ready":i%2==0,"line_of_sight":i%5!=0,"allies":i%4},.08)
        if state.get("state","")=="" or state.get("intent","")=="":failure+=1
    print("EXO_BESTIARY_02_MASSIVE ",JSON.stringify({"cases":iterations,"failures":failure,"status":"PASS" if failure==0 else "FAIL"}))
    quit(0 if failure==0 else 1)
