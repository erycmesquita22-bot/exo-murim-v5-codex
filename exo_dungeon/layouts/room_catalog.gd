extends RefCounted
## Catálogo lógico próprio. Aparência é definida por outro módulo, não pela seed de planta.
const FAMILIES := {
 "ruins": {"name":"Ruínas Murim", "enemy_tags":["bandit","guardian"],"palette":["#687078","#8d7965","#4a5557"],"trap_chance":0.16,"secret_chance":0.76,"reward_bonus":1},
 "cavern": {"name":"Cavernas naturais", "enemy_tags":["beast","cave"],"palette":["#53605b","#8a8767","#30413e"],"trap_chance":0.22,"secret_chance":0.58,"reward_bonus":0},
 "temple": {"name":"Templos antigos", "enemy_tags":["guardian","cultivator"],"palette":["#8b7961","#905d42","#4f5b47"],"trap_chance":0.11,"secret_chance":0.64,"reward_bonus":1},
 "sect_hideout": {"name":"Esconderijo de seita", "enemy_tags":["sect","bandit"],"palette":["#6d6663","#805248","#453937"],"trap_chance":0.24,"secret_chance":0.55,"reward_bonus":0},
 "mine": {"name":"Minas abandonadas", "enemy_tags":["bandit","cave"],"palette":["#696358","#8c734e","#3c403e"],"trap_chance":0.26,"secret_chance":0.53,"reward_bonus":1},
 "tomb": {"name":"Tumbas e catacumbas", "enemy_tags":["guardian","undead"],"palette":["#74747a","#8c7b6e","#484752"],"trap_chance":0.3,"secret_chance":0.70,"reward_bonus":1}
}
const ROOM_KINDS := ["common","combat","treasure","rest","puzzle","trap","shrine"]
static func profile(family: String) -> Dictionary:
 return FAMILIES.get(family,{}).duplicate(true)
static func is_supported(family: String) -> bool:
 return FAMILIES.has(family)
