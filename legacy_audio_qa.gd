extends SceneTree
const Registry=preload("res://audio/skill_registry.gd")
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func ticks(n: int) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://qa092-audio.json";w.settings_path="user://qa092-audio.cfg";root.add_child(w);await process_frame
	w.flow.phase="creator";w.flow.create_character({"name":"Legado EXO","race":0,"path":0,"robe":0,"hair":0,"skin":0,"style":0});w.ui.resume()
	for actor in w.enemies:actor.enabled=false
	w.audio_fx.groups.master=.75;w.audio_fx.groups.magic=.7
	var audit_ok: bool=Registry.catalog.skills.size()==w.Catalog.SKILLS.size()
	for s in w.Catalog.SKILLS:
		var entry: Dictionary=Registry.catalog.skills.get(s.id,{})
		audit_ok=audit_ok and not entry.get("original",{}).is_empty()
		for phase in ["prepare","cast","movement","impact","finish"]:audit_ok=audit_ok and entry.get("phases",{}).has(phase)
	check(audit_ok,"Catálogo audita IDs reais e as cinco fases das dezesseis técnicas")
	var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/exo_legacy/ORIGEM.json"))
	var hashes_ok:=true
	for f in provenance.files:
		hashes_ok=hashes_ok and FileAccess.get_sha256("res://"+f.local_file)==f.result_sha256 and f.license.begins_with("CC0-1.0")
	check(hashes_ok,"Assinaturas CC0 de saída/pouso têm os hashes originais do EXO Visual")
	w.player.position=w.village_anchor("camp",Vector3(0,.03,32));w.player.velocity=Vector3.ZERO;w.set_facing(Vector3.FORWARD);await ticks(25)
	w.techniques.configure(["corte_inicial","bola_de_gelo","salto_impetuoso"]);w.techniques.reset();w.techniques.mana=100;w.techniques.stamina=100
	w.audio_fx.history.clear();w.audio_fx.recent.clear()
	check(w.techniques.cast(2),"Salto Impetuoso inicia pelo controlador real")
	var airborne_sound:=false;var early_impact:=false
	for i in range(90):
		await ticks(1)
		if not w.player.is_on_floor():
			airborne_sound=airborne_sound or "exo_salto_cast" in w.audio_fx.history
			early_impact=early_impact or "exo_salto_impact" in w.audio_fx.history
	check(airborne_sound and not early_impact,"Som de execução acompanha o voo; impacto aguarda chão")
	check(w.techniques.landings==1 and w.audio_fx.history.count("exo_salto_cast")==1 and w.audio_fx.history.count("exo_salto_impact")==1,"Um salto real emite uma saída e um pouso")
	check("punch" not in w.audio_fx.history and "leap" not in w.audio_fx.history and "chronicle_koto" not in w.audio_fx.history,"Assinatura não acumula soco genérico, deslocamento ou narrativa")
	check(w.audio_fx.cache.has("exo_legacy/salto_cast") and w.audio_fx.cache.has("exo_legacy/salto_impact"),"Dois Ogg originais carregados pela engine")
	check(not Registry.integrated("bola_de_gelo") and w.audio_fx.skill_event(w.Catalog.skill("bola_de_gelo"))=="gelo","Demais sons aprovados preservam sua seleção")
	print("LEGACY_AUDIO092 %d passaram / %d falharam"%[passed,failed])
	w.simulation_enabled=false;w.audio_fx.shutdown();OS.delay_msec(120);await create_timer(.2).timeout;w.queue_free();await process_frame;await process_frame;await create_timer(.3).timeout;w=null;quit(int(failed>0))
