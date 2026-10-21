extends SceneTree
const Seed=preload("res://procedural/world_state.gd")
const Loot=preload("res://procedural/loot_generator.gd")
const Save=preload("res://journey_save.gd")
const Items=preload("res://inventory.gd")
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func equivalent(a: Variant,b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))
func clean(path_value: String) -> void:
	for suffix in ["",".bak",".tmp",".pre092.json",".invalid.json"]:
		if FileAccess.file_exists(path_value+suffix):DirAccess.remove_absolute(path_value+suffix)
func run() -> void:
	var state:=Seed.create(123456,"world_test092")
	var original: Dictionary=state.duplicate(true)
	var a:=Loot.generate(state,"enemy/test","blade",2,"item_1")
	check(a==Loot.generate(state,"enemy/test","blade",2,"item_1"),"Mesma seed, versão e parâmetros reproduzem todo o item")
	for i in range(100):Seed.stream(state,"cosmetic/future",str(i)).next()
	check(a==Loot.generate(state,"enemy/test","blade",2,"item_1") and state==original,"Fluxo cosmético não altera o saque nem muta o mundo")
	var valid_batch:=true;var variety: Dictionary={};var rarities: Dictionary={};var examples: Dictionary={}
	var nodes_before: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var start:=Time.get_ticks_usec()
	for i in range(2000):
		var item:=Loot.generate(state,"sample/%d"%i,["blade","mage","boss"][i%3],1+i%3,"item_%d"%(i+1))
		valid_batch=valid_batch and Items.valid_item(item) and Items.valid_item(JSON.parse_string(JSON.stringify(item)))
		variety[JSON.stringify(item.stats)]=true;rarities[item.rarity]=true
		for key in item.stats:
			if not examples.has(key):examples[key]=item
	var elapsed_ms:=(Time.get_ticks_usec()-start)/1000.0
	var node_delta: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)-nodes_before
	check(valid_batch,"Lote de 2000 itens respeita catálogo, afixos, compatibilidade e limites")
	check(variety.size()>100 and rarities.size()==4,"Seeds/chaves produzem variedade mecânica e quatro raridades")
	check(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)==nodes_before,"Geração de dados não cria nós de cena")
	var different:=Loot.generate(Seed.create(123457,"world_test092"),"enemy/test","blade",2,"item_1")
	check(a.stats!=different.stats or a.ref!=different.ref or a.affixes!=different.affixes,"Outra seed altera uma combinação válida")
	var bad: Dictionary=a.duplicate(true);bad.stats.guard=999
	check(not Items.valid_item(bad),"Atributo fora dos limites é rejeitado")
	bad=a.duplicate(true);bad.generation.version=2
	check(not Items.valid_item(bad),"Versão de item desconhecida não é regenerada silenciosamente")
	bad=a.duplicate(true);bad.affixes.append("inexistente")
	check(not Items.valid_item(bad),"Afixo inexistente é rejeitado")
	var migrated_path:="user://qa092-legacy.json";clean(migrated_path)
	var old_text:=FileAccess.get_file_as_string("res://fixtures/save-091.json")
	FileAccess.open(migrated_path,FileAccess.WRITE).store_string(old_text)
	var migrated:=Save.new(migrated_path)
	check(migrated.load_progress() and Seed.valid(migrated.data.world),"Save real escrito pela 09.1 recebe extensão procedural")
	check(FileAccess.get_file_as_string(migrated_path+".pre092.json")==old_text and migrated.data.character.hands_free,"Cópia pré-migração preserva bytes e estado desarmado")
	var identity: Dictionary=migrated.data.world.duplicate(true)
	check(migrated.write(),"Save migrado grava sem perder o inventário antigo")
	var readback:=Save.new(migrated_path)
	check(readback.load_progress() and equivalent(readback.data.world,identity),"Identidade e seed migradas sobrevivem à nova instância")
	var broken_path:="user://qa092-invalid.json";clean(broken_path)
	FileAccess.open(broken_path,FileAccess.WRITE).store_string("meu save inválido")
	var broken:=Save.new(broken_path)
	check(not broken.load_progress() and not broken.write() and FileAccess.get_file_as_string(broken_path)=="meu save inválido","Arquivo inválido é informado e preservado contra autosave")
	w=load("res://main.gd").new();w.load_on_start=false;w.world_seed_override=789;w.save_path="user://qa092-live.json";w.settings_path="user://qa092-live.cfg";clean(w.save_path);root.add_child(w);await process_frame
	w.flow.phase="creator";check(w.flow.create_character({"name":"Mundo Procedural","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0}),"Novo personagem abre a aventura real")
	w.ui.resume();for actor in w.enemies:actor.enabled=false
	check(w.journey.data.world.seed==789,"Mundo registra seed definida e identificador persistente")
	var enemy: Node3D=w.enemies[0];enemy.position=Vector3(0,.03,-4);enemy.hp=1
	check(enemy.hurt(100,Vector3.ZERO),"Dano real derrota inimigo da estrada")
	await ticks(3)
	check(w.journey.data.defeated.has(enemy.uid) and w.journey.data.pending_loot.size()==1,"Derrota real materializa um saque uma única vez")
	var generated: Dictionary={}
	for item in w.journey.data.pending_loot[0].items:
		if item.has("generation"):generated=item.duplicate(true)
	check(not generated.is_empty() and Items.valid_item(generated),"Saque contém equipamento procedural completo, não somente referência")
	var after_death:=Save.new(w.save_path)
	check(after_death.load_progress() and after_death.data.pending_loot.size()==1 and equivalent(after_death.data.pending_loot[0].items.back(),generated),"Saque não recolhido preserva seus sorteios no disco")
	w.player.position=enemy.position;w.player.velocity=Vector3.ZERO;w.combat_timer=0;await ticks(3)
	var before_collect: Dictionary=w.journey.data.duplicate(true)
	while w.journey.data.items.size()<23:w.inventory.add("weapon","sword")
	var full_state: Dictionary=w.journey.data.duplicate(true)
	check(not w.inventory.collect(enemy.uid) and equivalent(w.journey.data,full_state),"Falha após primeira recompensa reverte itens, UIDs e todo o saque")
	w.journey.data=before_collect
	check(w.inventory.collect(enemy.uid),"Interação do mundo recolhe equipamento e recompensas fixas")
	check(w.inventory.find_item(generated.uid)==generated,"Inventário recebe exatamente a instância materializada")
	check(w.inventory.owns_weapon("bow") and w.journey.data.items.any(func(i):return i.kind=="manual" and i.ref=="golpe_circular"),"Arco e manual fixos da missão continuam disponíveis")
	var size: int=w.journey.data.items.size();w.enemy_defeated(enemy)
	check(not w.inventory.collect(enemy.uid) and w.journey.data.items.size()==size and w.journey.data.pending_loot.is_empty(),"Reabrir interação ou repetir derrota não duplica recompensa")
	w.player.position=Vector3(0,.03,28);w.combat_timer=0;await ticks(3)
	check(w.inventory.use(generated.uid),"Item procedural equipa pelo inventário existente")
	check(w.current_weapon().damage>w.Catalog.weapon(generated.ref).damage,"Qualidade do equipamento altera dano-base utilizado")
	var save_text:=JSON.stringify(generated)
	check(w.save_progress(),"Equipamento e seus atributos salvam na aventura")
	var reopened:=Save.new(w.save_path)
	check(reopened.load_progress() and equivalent(reopened.data.items.filter(func(i):return i.uid==generated.uid)[0],generated) and reopened.data.equipped==generated.uid,"Nova instância de save preserva exatamente propriedades e item equipado")
	check(reopened.data.world.id==w.journey.data.world.id and preload("res://procedural/world_state.gd").has_event(reopened.data.world,"loot/"+enemy.uid),"Identidade do mundo e recompensa recolhida persistem")
	var duplicate: Dictionary=generated.duplicate(true);duplicate.uid="item_%d"%int(w.journey.data.next_item);w.journey.data.next_item+=1;w.journey.data.items.append(duplicate)
	check(not w.journey.valid(w.journey.data),"Duas instâncias com a mesma identidade são rejeitadas")
	w.journey.data.items.erase(duplicate);w.journey.data.next_item-=1
	# Exercise actual modifiers using valid generator output, not injected fake stats.
	var effects_ok:=true
	var used_sources: Array=[]
	for stat in ["guard","move_pct","mana_regen","stamina_regen","agilidade","inteligencia","elemental_pct"]:
		var example: Dictionary={}
		for i in range(2000):
			var key:="qa/effect/%d"%i
			if key in used_sources:continue
			var candidate:=Loot.generate(w.journey.data.world,key,["blade","mage","boss"][i%3],3,"item_%d"%int(w.journey.data.next_item))
			if candidate.stats.has(stat):example=candidate;used_sources.append(key);break
		check(not example.is_empty(),"Gerador oferece amostra para "+stat)
		w.journey.data.next_item+=1;w.journey.data.items.append(example)
		w.combat_timer=0;check(w.equip_weapon(example.ref,example.uid),"Equipa amostra válida para "+stat)
		if stat in ["agilidade","inteligencia"]:
			effects_ok=effects_ok and w.attribute(stat)>int(w.journey.data.attributes[stat])
			if stat=="agilidade":
				w.combo_timeout=0;w.attack_time=-1;w.start_attack();effects_ok=effects_ok and w.attack_duration<float(w.current_weapon().duration);w.attack_time=-1
			else:effects_ok=effects_ok and w.techniques.scaled_damage(100,{"element":-1})>100
		elif stat=="guard":
			w.player.position=Vector3(0,.03,-5);w.health=100;w.invulnerability=0;w.techniques.shield=0;w.damage_player(12);effects_ok=effects_ok and w.health==100-maxi(1,12-int(example.stats.guard));w.player.position=Vector3(0,.03,28)
		elif stat=="elemental_pct":effects_ok=effects_ok and w.techniques.scaled_damage(100,{"element":example.affinity})>w.techniques.scaled_damage(100,{"element":-1})
		elif stat in ["mana_regen","stamina_regen"]:
			w.techniques.regen_delay=0;w.techniques.mana=10;w.techniques.stamina=10;w.techniques.tick(.5)
			effects_ok=effects_ok and (w.techniques.mana>14 if stat=="mana_regen" else w.techniques.stamina>19)
		else:
			w.player.velocity=Vector3.ZERO;Input.action_press("right");await ticks(20);Input.action_release("right")
			effects_ok=effects_ok and Vector2(w.player.velocity.x,w.player.velocity.z).length()>3.6
			w.player.position=Vector3(0,.03,28);w.player.velocity=Vector3.ZERO
	check(effects_ok,"Atributos, defesa, recuperação e afinidade modificam sistemas reais")
	w.combat_timer=0;check(w.martial.toggle() and w.equipment_stat("guard")==0 and w.current_weapon().id=="unarmed","Guardar arma não transfere seus bônus para mãos livres")
	print("PROCEDURAL_BENCH ",JSON.stringify({"count":2000,"elapsed_ms":elapsed_ms,"unique_stat_sets":variety.size(),"node_delta":node_delta}))
	print("PROCEDURAL092 ",passed," passaram / ",failed," falharam")
	w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);await create_timer(.2).timeout;w.queue_free();await process_frame;await process_frame;await create_timer(.35).timeout;w=null;quit(int(failed>0))
