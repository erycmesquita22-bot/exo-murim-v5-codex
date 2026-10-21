extends SceneTree
# Run from an isolated COPY of the audited Core project:
# godot --headless --path <core-copy> --script res://exo_items/tests/qa_native.gd
const Generator = preload("res://exo_items/generation/item_generator.gd")
const Affixes = preload("res://exo_items/generation/affix_generator.gd")
const Catalog = preload("res://exo_items/catalog/item_catalog.gd")
const Power = preload("res://exo_items/balance/power_budget.gd")
const Validator = preload("res://exo_items/balance/stat_validator.gd")
const Ser = preload("res://exo_items/persistence/item_serialization.gd")
const LegacyInventory = preload("res://inventory.gd")
const LootAdapter = preload("res://exo_items/integration/loot_adapter.gd")
const WorldSeed = preload("res://procedural/world_state.gd")
const Appearance = preload("res://exo_items/visuals/appearance_descriptors.gd")
var failures: Array = []
var checked: Dictionary = {"legacy":0,"vertical_ABC":0,"determinism":0,"affix":0,"budget":0,"serialization":0,"transaction_guards":0,"adversarial":0,"visual_adapter":0,"fit_regression":0}
func _initialize() -> void:
 call_deferred("_run")
func _check(ok: bool, context: String) -> void:
 if not ok and failures.size() < 60: failures.append(context)
func _run() -> void:
 var world: Dictionary = WorldSeed.create(9371, "world_items_qa")
 var profiles: Array = Catalog.profiles.weapon.keys()
 profiles.sort()
 var families: Array = ["weapon", "armor", "accessory", "material", "special"]
 var rarity_ids: Array = ["common", "uncommon", "rare", "epic", "legendary", "ancestral"]
 var seen: Dictionary = {}
 for i in range(10000):
  var source: String = "eco/r1/m%d/g%d" % [i, i % 31]
  var a: Dictionary = Generator.compatible_reward(world, source, ["blade","mage","boss"][i%3], i%3+1, "item_%d" % (i+1))
  _check(not a.is_empty() and LegacyInventory.valid_item(a), "legacy_validation_%d" % i)
  if not a.is_empty():
   _check(not seen.has(a.instance_id), "legacy_duplicate_instance_%d" % i)
   seen[a.instance_id] = true
   _check(JSON.stringify(a,"",true) == JSON.stringify(Generator.compatible_reward(world, source,["blade","mage","boss"][i%3],i%3+1,"item_%d" % (i+1)),"",true), "legacy_reroll_%d" % i)
  checked.legacy += 1
 # Five vertical requirements are tracked separately; only the pure generator is
 # executable here. Live inventory/save scenarios remain for integration QA.
 for case in range(3):
  var found: bool = false
  for attempt in range(300):
   var vertical: Dictionary = Generator.compatible_reward(world, "qa/vertical_%d_%d" % [case,attempt], "blade", 1 if case == 0 else 3, "item_%d" % (20000+case*300+attempt), "sword")
   if vertical.is_empty() or not LegacyInventory.valid_item(vertical): continue
   if (case == 0 and vertical.rarity == "Comum") or (case == 1 and vertical.affixes.size() == 2) or (case == 2 and vertical.rarity == "Rara"):
    _check(LegacyInventory.valid_item(JSON.parse_string(JSON.stringify(vertical))), "legacy_json_vertical_%d" % case)
    found = true
    break
  _check(found, "missing_vertical_case_%d" % case)
  checked.vertical_ABC += 1
 for i in range(10000):
  var family: String = families[i%families.size()]
  var bases: Array = Catalog.profiles[family].keys()
  bases.sort()
  var base_id: String = str(bases[int(i / families.size()) % bases.size()])
  var source: String = "qa/procedural/%d" % i
  var rarity: String = str(rarity_ids[i % rarity_ids.size()])
  var a: Dictionary = Generator.preview(91371, source, family, base_id, i%100+1, i%4, rarity)
  var b: Dictionary = Generator.preview(91371, source, family, base_id, i%100+1, i%4, rarity)
  _check(not a.is_empty() and Validator.valid_descriptor(a), "preview_validation_%d" % i)
  _check(JSON.stringify(a,"",true) == JSON.stringify(b,"",true), "preview_determinism_%d" % i)
  checked.determinism += 1
  if not a.is_empty():
   var chosen: Array = []
   for id in a.affixes:
    var def: Dictionary = Catalog.affix(id)
    _check(Affixes.compatible(def, family, base_id, Catalog.base(family,base_id).tags, chosen), "affix_%d_%s" % [i,id])
    chosen.append(id)
   checked.affix += 1
   _check(Power.within(a.stats, Catalog.rarity(a.rarity_id), int(a.level), int(a.quality),Catalog.material(a.material_id)), "power_%d" % i)
   checked.budget += 1
   if i < 5000:
    _check(Ser.roundtrip(a), "roundtrip_%d" % i)
    checked.serialization += 1
 var save: Dictionary = {"world":world,"items":[],"pending_loot":[],"next_item":123}
 var candidate: Dictionary = LootAdapter.prepare(save,"eco/r2/m1/g1","blade",1)
 _check(bool(candidate.get("ok",false)), "preflight_initial")
 if bool(candidate.get("ok",false)):
  _check(not bool(candidate.get("committed",true)), "preflight_must_not_commit")
  save.world.events["loot/eco/r2/m1/g1"]={"status":"pending"}
  _check(not bool(LootAdapter.prepare(save,"eco/r2/m1/g1","blade",1).get("ok",true)), "repeated_loot")
  save.world.events.erase("loot/eco/r2/m1/g1")
  for i in range(24): save.items.append({"uid":"item_%d" % i,"kind":"material","ref":"iron","qty":1})
  _check(not bool(LootAdapter.prepare(save,"eco/r2/m1/g1","blade",1).get("ok",true)), "full_inventory")
 checked.transaction_guards=3
 # Edge cases: cross-drop duplicate UID, duplicate physical instance and invalid sequence.
 var clean: Dictionary = {"world":world.duplicate(true),"items":[],"pending_loot":[],"next_item":741}
 var prepared: Dictionary = LootAdapter.prepare(clean,"qa/cross_uid","blade",1)
 _check(bool(prepared.get("ok",false)),"cross_uid_initial")
 if bool(prepared.get("ok",false)):
  clean.pending_loot.append({"source":"other_drop","items":[prepared.item.duplicate(true)]})
  _check(not bool(LootAdapter.prepare(clean,"qa/cross_uid","blade",1).get("ok",true)),"cross_drop_uid_block")
  clean.pending_loot.clear()
  var same_instance: Dictionary=prepared.item.duplicate(true)
  same_instance.uid="item_99998"
  clean.pending_loot.append({"source":"other_drop","items":[same_instance]})
  _check(not bool(LootAdapter.prepare(clean,"qa/cross_uid","blade",1).get("ok",true)),"cross_drop_instance_block")
  clean.pending_loot.clear()
  clean.next_item=741.5
  _check(not bool(LootAdapter.prepare(clean,"qa/cross_uid","blade",1).get("ok",true)),"fractional_uid_block")
  clean.next_item=741
  _check(bool(LootAdapter.prepare(clean,"qa/cross_uid","blade",1).get("ok",false)),"integer_uid_allowed")
 checked.adversarial=5
 var over: Dictionary={"damage_pct":0.35,"move_pct":0.08,"guard":4.0,"mana_regen":2.0,"stamina_regen":4.0,"elemental_pct":0.18,"agilidade":2.0,"inteligencia":2.0}
 var r: Dictionary=Catalog.rarity("common")
 var mat: Dictionary=Catalog.material("iron")
 var fitted: Dictionary=Power.fit(over,r,1,0,mat)
 _check(not fitted.is_empty() and Power.within(fitted,r,1,0,mat),"overspend_reduction")
 _check(Power.cost(fitted)<=Power.budget(r,1,0,mat)+0.0001,"fit_final_budget")
 checked.fit_regression=2
 var legacy_visual: Dictionary=Appearance.describe({"kind":"weapon","ref":"sword","rarity":"Rara"})
 _check(str(legacy_visual.get("existing_base",""))=="sword","legacy_appearance_mesh")
 _check(str(legacy_visual.get("rarity_color",""))=="#3D9FFF","legacy_appearance_rarity")
 checked.visual_adapter=2
 _check(Generator.preview(1,"bad","weapon","does_not_exist",1).is_empty(), "unknown_reference")
 _check(Generator.preview(1,"bad","armor","head_wrap",1,0,"ancestral","iron").size()>0, "planned_armor_preview")
 _check(not Validator.valid_descriptor({"schema":2,"mode":"preview_only","id":"exo2/bad","source":"x","family":"weapon","base_id":"sword","rarity_id":"common","material_id":"iron","stats":{"damage_pct":9999}}), "reject_overpowered")
 var result: Dictionary = {"module":"exo_items","status":"PASS" if failures.is_empty() else "FAIL","checks":checked,"failure_count":failures.size(),"failures":failures,"native":true}
 print(JSON.stringify(result,"  ",true))
 quit(0 if failures.is_empty() else 2)
