extends Node
const Motion = preload("res://modules/village_life/npc_motion.gd")
const FX = preload("res://modules/village_life/cultivation_fx.gd")
const CATALOG_PATH := "res://modules/cultivation_path/ranks.json"
var catalog: Dictionary = {}
const DURATION := 9.0
var host
var save_path := "user://exo_cultivation_slot_1.json"
var rank := 0
var stage := 0
var cycles := 0
var fatigue := 0.0
var talked_ji := false
var talked_master := false
var cultivating := false
var elapsed := 0.0
var site_id := ""
var fx: Node3D
var panel: PanelContainer
var body: Label
var status: Label
var hint: Label
var message := ""
var message_time := 0.0
var log: Array[String] = []
var old_hp_max := 100
var old_qi_max := 100.0
func configure(world) -> void: host = world
func _ready() -> void:
 catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
 Motion.add_cultivation(host.player)
 for clip in ["Gather_Qi","Circulate_Qi","Release_Qi","Cultivate"]:
  Motion._apply_approved_pose(host.player.get_animation("village_life/"+clip),host.player.get_animation("Idle"))
 fx = FX.new(); fx.configure(1,Color("75d8e5")); host.actor.add_child(fx)
 fx.position.y = 1.23
 var canvas := CanvasLayer.new();canvas.layer = 12;canvas.name = "CultivationHUD";add_child(canvas)
 status = Label.new();status.position = Vector2(22,225);status.add_theme_font_size_override("font_size",18);status.add_theme_color_override("font_color",Color("e8c889"));canvas.add_child(status)
 hint = Label.new();hint.position = Vector2(22,255);hint.add_theme_font_size_override("font_size",16);hint.add_theme_color_override("font_color",Color("c1e6e8"));canvas.add_child(hint)
 panel = PanelContainer.new();panel.position = Vector2(24,290);panel.custom_minimum_size = Vector2(460,250)
 var style := StyleBoxFlat.new();style.bg_color = Color("122430ef");style.border_color = Color("be9a61");style.set_border_width_all(2);style.set_corner_radius_all(8);style.set_content_margin_all(18);panel.add_theme_stylebox_override("panel",style)
 body = Label.new();body.add_theme_font_size_override("font_size",17);body.add_theme_color_override("font_color",Color("f2e4c4"));panel.add_child(body);canvas.add_child(panel);panel.hide()
 old_hp_max = host.health.maximum;old_qi_max = host.skills.maximum_qi
 load_state();_refresh()
func use_slot(slot: int) -> void:
 save_path = "user://exo_cultivation_slot_%d.json" % clampi(slot,1,3)
 reset_state(false);load_state()
func reset_state(write := true) -> void:
 stop();rank=0;stage=0;cycles=0;fatigue=0;talked_ji=false;talked_master=false;log.clear()
 _apply_bonuses();_refresh()
 if write: save_state()
func save_state() -> void:
 var file := FileAccess.open(save_path,FileAccess.WRITE)
 if file == null: push_error("CULTIVATION_SAVE_FAILED "+str(FileAccess.get_open_error()));return
 file.store_string(JSON.stringify({"version":1,"rank":rank,"stage":stage,"cycles":cycles,"fatigue":fatigue,"talked_ji":talked_ji,"talked_master":talked_master},"\t"));file.close()
func load_state() -> void:
 if not FileAccess.file_exists(save_path): return
 var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
 if not data is Dictionary: return
 rank=clampi(int(data.get("rank",0)),0,2);stage=clampi(int(data.get("stage",0)),0,2)
 if rank == 0: stage=0
 cycles=maxi(0,int(data.get("cycles",0)));fatigue=clampf(float(data.get("fatigue",0)),0,100)
 talked_ji=bool(data.get("talked_ji",false));talked_master=bool(data.get("talked_master",false))
 _apply_bonuses();_refresh()
func on_talk(id: String) -> void:
 if id == "ji_wol" and not talked_ji: talked_ji=true;_notice("Ji Wol lhe falou sobre o treino no patio da seita.")
 if id in ["estate_master_weak","terrace_master_weak"] and talked_ji and not talked_master:
  talked_master=true;_notice("O mestre ensinou postura e respiracao. Procure um circulo de cultivo.")
 save_state();_refresh()
func _site() -> Dictionary:
 if host.village_npcs == null or not host.village_npcs.village_active: return {}
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/village_npcs/roster.json"))
 for spec in manifest.cultivation_sites:
  for marker in host.village_npcs.cultivation_sites:
   if marker.name == str(spec.id) and host.actor.global_position.distance_to(marker.global_position) <= float(spec.radius): return spec
 return {}
func toggle_cultivate() -> void:
 if cultivating: stop();_notice("Treino interrompido.");return
 var site := _site()
 if site.is_empty(): _notice("Cultivo apenas nos circulos de treino da vila.");return
 if host.health.dead or host.health.stun > 0 or not host.action_kind.is_empty() or not host.actor.is_on_floor(): _notice("Firme a postura antes de cultivar.");return
 if not talked_ji: _notice("Conheca Ji Wol para encontrar um caminho na vila.");return
 if not talked_master: _notice("Peca orientacao a um mestre antes de circular o Qi.");return
 if fatigue >= 80: _notice("Meridianos exaustos. Descanse antes de treinar.");return
 if host.armed: _notice("Guarde a espada antes de cultivar.");return
 cultivating=true;elapsed=0;site_id=str(site.id);host.travel_mode=false;host.travel_pending=false;host.neutral=true;host.actor.velocity=Vector3.ZERO;host.tree.active=false
 host.player.play("village_life/Gather_Qi");_notice("Respire, reuna e circule o Qi. [C] interrompe.")
func stop() -> void:
 if not cultivating: return
 cultivating=false;site_id="";host.player.stop();host.neutral=false;host.tree.active=true;fx.update_fx(false,"off",0,false,0)
func _process(delta: float) -> void:
 if host.title_flow != null and host.title_flow.visible: panel.hide();hint.text="";status.text="";return
 message_time=maxf(0,message_time-delta)
 if not cultivating: fatigue=maxf(0,fatigue-delta*1.5)
 var here := _site()
 status.text="CULTIVO  %s%s   |   Fadiga %d%%   [J] Jornada" % [str(catalog.realms[rank].name),(" · "+["Inicial","Intermediario","Avancado"][stage]) if rank>0 else "",int(fatigue)]
 hint.text=message if message_time>0 else ("[C] Cultivar  ·  %s" % str(here.id) if not here.is_empty() else "")
 if panel.visible: _refresh()
func _physics_process(delta: float) -> void:
 if not cultivating: return
 var site := _site()
 if site.is_empty() or str(site.id) != site_id or host.health.dead or host.health.stun > 0 or not host.action_kind.is_empty(): stop();_notice("A concentracao foi quebrada.");return
 host.neutral=true;host.actor.velocity.x=0;host.actor.velocity.z=0
 elapsed += delta
 var phase := fmod(elapsed,9.0)
 var anim := "Gather_Qi" if phase<2.0 else ("Circulate_Qi" if phase<7.0 else "Cultivate")
 if host.player.current_animation != "village_life/"+anim: host.player.play("village_life/"+anim,.35)
 fx.update_fx(rank>0,"gather" if phase<2.0 else ("circulate" if phase<7.0 else "form"),phase/9.0,false,delta)
 if elapsed >= DURATION:
  elapsed=0;cycles+=1;fatigue=minf(100,fatigue+29)
  if rank>0: host.skills.qi=minf(host.skills.maximum_qi,host.skills.qi+8)
  save_state();_notice("Ciclo %d concluido. Respire e recupere antes do proximo." % cycles)
  stop();_refresh()
func breakthrough() -> bool:
 if cultivating: _notice("Conclua o ciclo antes do avancar.");return false
 if _site().is_empty(): _notice("Avance dentro de um circulo de cultivo.");return false
 var required := _required()
 if required < 0: _notice("Este reino depende de uma etapa futura da jornada.");return false
 if cycles < required or not talked_master: _notice("Faltam ciclos de treino e orientacao do mestre.");return false
 if fatigue > 65: _notice("Descanse para estabilizar os meridianos.");return false
 if rank==0: rank=1;stage=0
 elif stage<2: stage+=1
 else: rank+=1;stage=0
 _apply_bonuses();host.skills.qi=minf(host.skills.maximum_qi,host.skills.qi+25);save_state();_notice("Avanco: %s %s!" % [str(catalog.realms[rank].name),["Inicial","Intermediario","Avancado"][stage]])
 _refresh();return true
func _required() -> int:
 if rank==0:return 2
 if rank==1:return [5,9,14][stage]
 if rank==2:return [20,27,-1][stage]
 return -1
func _apply_bonuses() -> void:
 var steps := 0 if rank==0 else (stage+1 if rank==1 else 3+stage+1)
 host.health.maximum=old_hp_max+steps*5
 host.health.hp=mini(host.health.hp,host.health.maximum)
 host.skills.maximum_qi=0.0 if rank==0 else old_qi_max+steps*8
 host.skills.qi=minf(host.skills.qi,host.skills.maximum_qi)
func _notice(s: String) -> void: message=s;message_time=5.0;log.append(s)
func toggle_panel() -> void: panel.visible=not panel.visible;_refresh()
func _refresh() -> void:
 if body==null:return
 var task := "Fale com Ji Wol [T]" if not talked_ji else ("Peca orientacao a um mestre [T]" if not talked_master else ("Complete %d ciclos e avance [X] no circulo" % _required() if _required()>0 else "Aguarde o proximo capitulo da jornada"))
 var lines := "JORNADA · O PRECO DO RIO\nUm nome desconhecido  /  Raizes do Vale\nObjetivo: %s\n\nReino: %s  |  Ciclos: %d  |  Fadiga: %d%%\n" % [task,str(catalog.realms[rank].name),cycles,int(fatigue)]
 lines += "[C] Cultivar   [X] Avancar   [J] Fechar\n\nESCALA MARCIAL\n"
 for i in catalog.realms.size():
  var realm: Dictionary=catalog.realms[i]
  lines += "%s %s%s\n" % ["◆" if i==rank else "·",str(realm.name),"  (horizonte)" if not realm.playable else ""]
 body.text=lines
