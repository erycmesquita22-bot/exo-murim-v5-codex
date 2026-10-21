extends Node
const SkillRegistry=preload("res://audio/skill_registry.gd")
# Curated EXO files. A bounded polyphonic pool replaces the prototype's single voice.
var BANK: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://audio/events.json"))
var voices: Array[AudioStreamPlayer]=[]
var cache: Dictionary={}
var recent: Dictionary={}
var index:=0
var played:=0
var groups:={"master":.75,"combat":.8,"magic":.7,"ui":.35,"ambience":.35,"voice":.55,"narrative":.55,"music":.3}
var history: Array[String]=[]
var variants: Dictionary={}
var actor_cooldowns: Dictionary={}
var step_distance:=0.0
var last_step:=Vector3.ZERO
var path:="user://exo-audio.cfg"
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var config:=ConfigFile.new()
	if config.load(path)==OK:
		for key in groups:
			var value: Variant=config.get_value("volume",key,groups[key])
			if value is float or value is int:groups[key]=clampf(float(value),0,1)
	for key in BANK:
		for name_value in BANK[key]:
			var asset: String="res://assets/"+name_value+".wav"
			if ResourceLoader.exists(asset):cache[name_value]=load(asset)
	var bus:=AudioServer.get_bus_index("EXO")
	if bus<0:
		AudioServer.add_bus()
		bus=AudioServer.bus_count-1
		AudioServer.set_bus_name(bus,"EXO")
		var limiter:=AudioEffectLimiter.new()
		limiter.ceiling_db=-1.0
		AudioServer.add_bus_effect(bus,limiter)
	for i in range(20):
		var voice:=AudioStreamPlayer.new()
		voice.bus="EXO"
		add_child(voice)
		voices.append(voice)
func play_event(event: String,group: String="combat",strength: float=1.0) -> void:
	if not BANK.has(event) or voices.is_empty():return
	group=event_group(event,group)
	if groups.master<=0 or float(groups.get(group,.8))<=0:return
	var now:=Time.get_ticks_msec()
	if now-int(recent.get(event,-1000))<45:return
	recent[event]=now
	var names: Array=BANK[event]
	if names.is_empty():return
	var variant: int=int(variants.get(event,0))
	var name_value: String=names[variant%names.size()]
	variants[event]=variant+1
	if not cache.has(name_value):return
	var voice: AudioStreamPlayer
	for candidate in voices.slice(0,18):
		if not candidate.playing:voice=candidate;break
	if group=="narrative":voice=voices[19]
	elif group=="music":voice=voices[18]
	elif voice==null:voice=voices[index%18]
	index+=1
	voice.stream=cache[name_value]
	voice.pitch_scale=1.0
	voice.set_meta("group",group)
	voice.set_meta("strength",strength)
	voice.volume_db=linear_to_db(maxf(.0001,groups.master*groups.get(group,.8)*strength))
	voice.play()
	played+=1
	history.append(event)
	if history.size()>64:history.pop_front()
func select_volume(group: String,value: float) -> void:
	if not groups.has(group):return
	groups[group]=clampf(value,0,1)
	var file:=ConfigFile.new()
	for key in groups:file.set_value("volume",key,groups[key])
	file.save(path)
	for voice in voices:
		if voice.playing:
			if groups.master==0 or (group==voice.get_meta("group","") and value==0):voice.stop();continue
			voice.volume_db=linear_to_db(maxf(.0001,groups.master*groups.get(voice.get_meta("group","combat"),.8)*float(voice.get_meta("strength",1))))

func skill(data: Dictionary,prepare: bool=false) -> void:
	if SkillRegistry.play(self,str(data.get("id","")),"prepare" if prepare else "cast"):return
	var kind: String=data.get("kind","")
	# Martial movements retain a martial sound even if their catalog has an element tag.
	if prepare:
		if float(data.get("mana",0))>0:play_event("skill_windup","magic",.22)
		return
	var event:=skill_event(data)
	play_event(event,"combat" if kind in ["cut","area","dash","leap"] else "magic",.65)

func skill_event(data: Dictionary) -> String:
	if SkillRegistry.integrated(str(data.get("id",""))):return str(SkillRegistry.catalog.skills[data.id].phases.cast.event)
	var kind: String=data.get("kind","")
	if kind in ["cut","area"]:return "swing"
	if kind in ["dash","leap"]:return "punch"
	if int(data.get("element",11))==6:return "gelo"
	if int(data.get("element",11))==5:return "fogo"
	if int(data.get("element",11))==0:return "vento"
	if int(data.get("element",11))==1:return "terra"
	if kind=="summon":return "summon"
	return "qi"

func actor_voice(actor: Node3D,attacking: bool=false) -> void:
	var choice: int=int(actor.get_meta("voice",0))
	if choice==2 or (attacking and choice==1):return
	var event: String="attack_male" if attacking else "hurt_female" if choice==1 else "hurt_male"
	var key: String=str(actor.get_instance_id())+("attack" if attacking else "hurt")
	var now:=Time.get_ticks_msec()
	if now-int(actor_cooldowns.get(key,-2000))<(1300 if attacking else 850):return
	actor_cooldowns[key]=now
	var owner_world: Node=get_parent()
	var distance: float=actor.global_position.distance_to(owner_world.player.global_position)
	if distance>22:return
	play_event(event,"voice",(.5 if attacking else .62)*clampf(1.0-distance/25.0,.12,1))

func _exit_tree() -> void:
	shutdown()
func shutdown() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream=null
	cache.clear()
	voices.clear()

func impact_event(material: String,context: Dictionary={}) -> String:
	# Contact material takes precedence over critical/fatal flavour. Wood never bleeds.
	if material=="wood":return "wood_hit"
	if material=="metal":return "metal_hit"
	if material in ["stone","ground"]:return "landing"
	if context.get("fatal",false):return "fatal_hit"
	if context.get("critical",false):return "critical_hit"
	if context.get("magic",false):
		return "gelo" if int(context.get("element",11))==6 else "fogo" if int(context.get("element",11))==5 else "qi_hit"
	if context.get("family","") in ["blade","draw","heavy","thrust","dual","reverse","reap","pole"]:return "blade_hit"
	if context.get("heavy",false):return "strong_hit"
	return "fist_hit" if context.get("family","")=="fists" else "body_hit"

func impact(material: String,context: Dictionary={}) -> void:
	play_event(impact_event(material,context),"combat",.75)

func steps(position_value: Vector3,grounded: bool,moving: bool) -> void:
	var distance:=position_value.distance_to(last_step)
	last_step=position_value
	if not grounded or not moving or distance>1.5:step_distance=0;return
	step_distance+=distance
	if step_distance>=1.45:step_distance=0;play_event("step","ambience",.45)

func technique_context(data: Dictionary) -> Dictionary:
	var martial: bool=data.get("kind","") in ["cut","area","dash","leap"] and float(data.get("mana",0))<=0
	return {"magic":data.get("magic",not martial and data.get("id","")!="weapon"),"family":data.get("family","blade" if data.get("kind","")=="cut" else "fists" if martial else ""),"element":data.get("element",11)}

func event_group(event: String,fallback: String="combat") -> String:
	if event=="chronicle_koto":return "narrative"
	if event.begins_with("ambience_"):return "music"
	if event=="quest_complete":return "ui"
	if event.begins_with("boss_") or event in ["qi","magia","summon","skill_windup","fogo","gelo","vento","terra"]:return "magic"
	return fallback
