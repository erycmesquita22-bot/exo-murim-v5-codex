extends RefCounted
const Catalog=preload("res://catalog.gd")
const COSMETIC_LABELS = {"head": "Cabeça", "torso": "Tronco", "right_arm": "Braço direito", "left_arm": "Braço esquerdo", "right_leg": "Perna direita", "left_leg": "Perna esquerda", "hair": "Cabelo", "collar": "Pescoço", "chest": "Peito", "shoulders": "Ombros", "wrists": "Punhos", "waist": "Cintura", "front_skirt": "Saia frontal", "back_skirt": "Saia traseira", "boots": "Pés", "back": "Costas", "sheath": "Bainha", "topknot": "Coque marcial", "headband": "Faixa de cabeça", "face_mask": "Máscara", "horns": "Chifres", "jade_collar": "Colar de jade", "martial_vest": "Colete marcial", "shoulder_cloth": "Manto de ombros", "wrist_wraps": "Faixas de punho", "jade_belt": "Cinto de jade", "front_robe": "Túnica frontal", "back_robe": "Túnica traseira", "travel_boots": "Botas de viagem", "short_cape": "Capa curta", "sword_sheath": "Bainha de espada", "iron_helm": "Elmo de ferro", "guard_cuirass": "Couraça de guarda", "iron_pauldron": "Ombreira de ferro", "iron_bracers": "Braçadeiras de ferro", "iron_boots": "Botas de ferro", "": "Nenhum"}

static func cosmetic_label(id: String) -> String:
	return str(COSMETIC_LABELS.get(id, id))

static func cosmetic_options(ids: Array) -> Array:
	var names: Array=[]
	for id in ids:names.append(cosmetic_label(str(id)))
	return names

var ui: CanvasLayer
var world: Node3D
func _init(owner_ui: CanvasLayer) -> void:ui=owner_ui;world=ui.world
func show_creator() -> void:
	var col: VBoxContainer=ui.begin_screen("creator")
	ui.title(col,"UM NOVO NOME NAS CRÔNICAS",29)
	col.add_theme_constant_override("separation",8)
	var tabs:=HBoxContainer.new();col.add_child(tabs)
	for i in range(3):
		var tab: Button=ui.button(tabs,["01  ORIGEM","02  APARÊNCIA","03  CONFIRMAR"][i],func():ui.creation_tab=i;show_creator())
		tab.custom_minimum_size.x=210;tab.modulate=Color("d5ba80") if i==ui.creation_tab else Color.WHITE
	var row:=HBoxContainer.new();col.add_child(row);row.add_theme_constant_override("separation",38)
	var left:=VBoxContainer.new();row.add_child(left);left.custom_minimum_size.x=525;left.add_theme_constant_override("separation",5)
	ui.race_description=null;ui.path_description=null
	if ui.creation_tab==0:origin(left)
	elif ui.creation_tab==1:
		var scroll := ScrollContainer.new()
		left.add_child(scroll)
		scroll.custom_minimum_size = Vector2(525,440)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var options := VBoxContainer.new()
		scroll.add_child(options)
		options.add_theme_constant_override("separation",6)
		appearance(options)
	else:summary(left)
	var right:=VBoxContainer.new();row.add_child(right);right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ui.make_preview(right,ui.profile,Vector2(450,370))
	ui.paragraph(right,"Arraste para girar • roda do mouse para aproximar",13,440)
	var pose_controls:=HBoxContainer.new();right.add_child(pose_controls)
	for pose_name in ["idle","walk","attack"]:
		var chosen: String=pose_name
		ui.button(pose_controls,{"idle":"Parado","walk":"Caminhar","attack":"Ataque"}[chosen],func():ui.preview_root.preview_pose=chosen)

	ui.creator_notice=ui.paragraph(col,"A ancestralidade fica vinculada a esta jornada. Outras armas e técnicas são descobertas no mundo.",14,1000)
	var actions:=HBoxContainer.new();col.add_child(actions)
	if ui.creation_tab>0:ui.button(actions,"ANTERIOR",func():ui.creation_tab-=1;show_creator()).custom_minimum_size.x=230
	if ui.creation_tab<2:ui.button(actions,"CONTINUAR",func():ui.creation_tab+=1;show_creator()).custom_minimum_size.x=300
	else:ui.button(actions,"DESPERTAR NA ALDEIA",confirm_character).custom_minimum_size.x=420
func origin(parent: Node) -> void:
	ui.name_field=LineEdit.new();parent.add_child(ui.name_field)
	ui.name_field.text=ui.profile.name;ui.name_field.placeholder_text="Nome do personagem";ui.name_field.max_length=24
	ui.name_field.custom_minimum_size=Vector2(520,36)
	ui.name_field.text_changed.connect(func(value: String):ui.profile.name=value)
	ui.selector(parent,"Ancestralidade",world.flow.RACES,ui.profile.race,func(i: int):ui.profile.race=i;update_profile())
	ui.race_description=ui.paragraph(parent,Catalog.RACES[int(ui.profile.race)].description,15,520)
	ui.selector(parent,"Caminho",world.flow.PATHS,ui.profile.path,func(i: int):ui.profile.path=i;ui.profile.weapon=["sword","arcane_staff","gauntlets"][i];show_creator())
	ui.path_description=ui.paragraph(parent,path_description(),15,520)
	var ids: Array=["sword","spear","bow","arcane_staff","gauntlets"]
	var names: Array=[]
	for id in ids:names.append(Catalog.weapon(id).name)
	ui.selector(parent,"Arma inicial",names,maxi(0,ids.find(ui.profile.get("weapon","sword"))),func(i: int):ui.profile.weapon=ids[i];update_profile())
	ui.selector(parent,"Afinidade",Catalog.ELEMENTS,int(ui.profile.get("element",6)),func(i: int):ui.profile.element=i;update_profile())
func appearance(parent: Node) -> void:
	ui.title(parent,"SEU ESTILO NO MURIM",22)
	var categories:=HBoxContainer.new();parent.add_child(categories)
	for i in range(4):
		ui.button(categories,["Traços","Vestuário","Acessórios","Armaduras"][i],func():ui.appearance_tab=i;show_creator())
	var cosmetic: Dictionary=preload("res://exo_skin3d/profile_codec.gd").normalized(ui.profile)
	var codec=preload("res://exo_skin3d/profile_codec.gd")
	if ui.appearance_tab==0:
		ui.selector(parent,"Corpo",["Original","Pequeno","Alto","Robusto","Esbelto","Baixo e forte","Grande"],int(ui.profile.get("body",0)),func(i: int):set_option("body",i))
		ui.selector(parent,"Pele",["Porcelana","Claro","Mel","Bronze","Castanho","Ébano"],int(ui.profile.get("skin",0)),func(i: int):set_option("skin",i))
		ui.selector(parent,"Músculos",["Desligados","Suaves","Marcados"],int(ui.profile.get("muscles",0)),func(i: int):set_option("muscles",i))
		ui.selector(parent,"Cabelo",["Preto","Castanho","Ruivo","Louro","Branco","Azul"],int(ui.profile.get("hair",0)),func(i: int):set_option("hair",i))
		ui.selector(parent,"Corte",["Curto","Espigado","Franja","Raspado"],int(ui.profile.get("haircut",0)),func(i: int):set_option("haircut",i))
		ui.selector(parent,"Olhos",["Firme","Sereno","Intenso","Amplo"],int(ui.profile.get("eyes",0)),func(i: int):set_option("eyes",i))
		ui.selector(parent,"Íris",["Cinza","Castanho","Azul","Verde","Âmbar","Violeta"],int(ui.profile.get("eye_color",0)),func(i: int):set_option("eye_color",i))
		ui.selector(parent,"Rosto",["Limpo","Cicatriz","Barba"],int(ui.profile.get("mark",0)),func(i: int):set_option("mark",i))
		ui.selector(parent,"Voz",["Masculina","Feminina","Sem voz"],int(ui.profile.get("voice",0)),func(i: int):set_option("voice",i))
	elif ui.appearance_tab==1:
		ui.paragraph(parent,"Estilos prontos • personalize cada detalhe depois",14,470)
		var presets:=HBoxContainer.new();parent.add_child(presets)
		for i in range(4):
			ui.button(presets,["Discípulo","Andarilho","Guarda","Erudito"][i],func():apply_style(i))
		ui.selector(parent,"Roupa",["Grafite","Azul","Verde","Vermelho","Branco","Violeta"],int(ui.profile.get("robe",0)),func(i: int):set_option("robe",i))
		ui.selector(parent,"Traje",["Kimono","Treino","Faixas","Túnica"],int(ui.profile.get("outfit",0)),func(i: int):set_option("outfit",i))
		ui.selector(parent,"Arranjo",["Coque marcial","Longo","Faixa de treino"],int(ui.profile.get("style",0)),func(i: int):set_option("style",i))
	elif ui.appearance_tab==2:
		for part in preload("res://exo_skin3d/profile_codec.gd").LAYERS:
			var part_id: String=part
			ui.selector(parent,"Camada · "+cosmetic_label(part_id),["Oculta","Visível"],1 if cosmetic.layers[part_id] else 0,func(i: int):
				ui.profile.skin3d=preload("res://exo_skin3d/profile_codec.gd").normalized(ui.profile)
				ui.profile.skin3d.layers[part_id]=(i==1)
				update_profile())
		ui.paragraph(parent,"Camadas 3D seguem cabeça, braços, cotovelos, pernas e joelhos. A skin PNG não é sobrescrita.",13,470)

		ui.title(parent,"ACESSÓRIOS 3D · VISUAIS",18)
		for slot in codec.SLOTS:
			var slot_id: String=slot
			var options: Array=[""]
			options.append_array(codec.ACCESSORY_OPTIONS.get(slot_id,[]))
			var current: String=str(cosmetic.accessories.get(slot_id,""))
			ui.selector(parent,"Acessório · "+cosmetic_label(slot_id),cosmetic_options(options),maxi(0,options.find(current)),func(i: int):
				ui.profile.skin3d=preload("res://exo_skin3d/profile_codec.gd").normalized(ui.profile)
				if i==0:ui.profile.skin3d.accessories.erase(slot_id)
				else:ui.profile.skin3d.accessories[slot_id]=options[i]
				update_profile())
	else:
		ui.title(parent,"ARMADURAS 3D · COSMÉTICAS",18)
		for slot in codec.ARMOR_OPTIONS:
			var armor_slot: String=slot
			var armor_options: Array=[""]
			armor_options.append_array(codec.ARMOR_OPTIONS[armor_slot])
			var chosen: String=str(cosmetic.equipment.get(armor_slot,""))
			ui.selector(parent,"Armadura · "+cosmetic_label(armor_slot),cosmetic_options(armor_options),maxi(0,armor_options.find(chosen)),func(i: int):
				ui.profile.skin3d=preload("res://exo_skin3d/profile_codec.gd").normalized(ui.profile)
				if i==0:ui.profile.skin3d.equipment.erase(armor_slot)
				else:ui.profile.skin3d.equipment[armor_slot]=armor_options[i]
				update_profile())
		ui.paragraph(parent,"Somente aparência: nenhuma armadura cosmética altera defesa, efeitos ou atributos.",13,470)
	ui.button(parent,"IMPORTAR SKIN MINECRAFT 64×64",func():open_skin_picker())
	ui.selector(parent,"Braços Minecraft",["Clássico · 4 px","Slim · 3 px"],1 if cosmetic.model=="slim" else 0,func(i: int):ui.profile.skin3d=preload("res://exo_skin3d/profile_codec.gd").normalized(ui.profile);ui.profile.skin3d.model="slim" if i==1 else "classic";update_profile())
	if not str(ui.profile.get("skin_file","")).is_empty():
		ui.button(parent,"USAR APARÊNCIA EXO",func():ui.profile.erase("skin_file");update_profile();show_creator())
	ui.button(parent,"SORTEAR APARÊNCIA",func():randomize_appearance())

func apply_style(index: int) -> void:
	var presets: Array=[
		{"robe":1,"outfit":0,"style":0,"haircut":0,"skin3d":{"accessories":{"waist":"jade_belt","hair":"topknot"}}},
		{"robe":2,"outfit":3,"style":2,"haircut":2,"skin3d":{"accessories":{"head":"headband","back":"short_cape","boots":"travel_boots"}}},
		{"robe":0,"outfit":1,"style":2,"haircut":3,"skin3d":{"equipment":{"chest":"guard_cuirass","wrists":"iron_bracers","boots":"iron_boots"}}},
		{"robe":4,"outfit":3,"style":1,"haircut":0,"skin3d":{"accessories":{"collar":"jade_collar","shoulders":"shoulder_cloth"}}}]
	ui.profile.erase("skin_file")
	for key in presets[index]:ui.profile[key]=presets[index][key].duplicate(true) if presets[index][key] is Dictionary else presets[index][key]
	ui.profile.skin3d=preload("res://exo_skin3d/profile_codec.gd").normalized(ui.profile)
	update_profile()
	show_creator()

func set_option(key: String, value: int) -> void:
	ui.profile[key] = value
	update_profile()

func randomize_appearance() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	ui.profile.erase("skin_file")
	for key in ["robe", "hair", "skin", "style", "body", "outfit", "haircut", "eyes", "eye_color", "muscles", "mark"]:
		ui.profile[key] = rng.randi_range(0, {"robe":5, "hair":5, "skin":5, "style":2, "body":6, "outfit":3, "haircut":3, "eyes":3, "eye_color":5, "muscles":2, "mark":2}[key])
	update_profile()
	show_creator()

func open_skin_picker() -> void:
	var dialog:=FileDialog.new()
	dialog.access=FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.png","Minecraft PNG (64x64)")
	ui.add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var target: String=preload("res://exo_skin3d/skin_importer.gd").import_file(path)
		if not target.is_empty():
			ui.profile.skin_file=target
			update_profile()
			show_creator()
		else:
			ui.creator_notice.text="A skin precisa ser PNG Minecraft 64×64 válido."
		dialog.queue_free())
	dialog.canceled.connect(func():dialog.queue_free())
	dialog.popup_centered_ratio(.6)

func summary(parent: Node) -> void:
	ui.title(parent,str(ui.profile.name),27)
	ui.paragraph(parent,"%s • %s\nAfinidade: %s\nArma inicial: %s"%[Catalog.RACES[int(ui.profile.race)].name,world.flow.PATHS[int(ui.profile.path)],Catalog.ELEMENTS[int(ui.profile.get("element",6))],Catalog.weapon(ui.profile.get("weapon","sword")).name],20,520)
	ui.paragraph(parent,path_description(),16,520)
	ui.paragraph(parent,"Seed do mundo (opcional, 0–2147483646)",14,520)
	var seed_field:=LineEdit.new();parent.add_child(seed_field);seed_field.text=ui.procedural_seed;seed_field.placeholder_text="Automática";seed_field.max_length=10
	seed_field.text_changed.connect(func(value: String):ui.procedural_seed=value.strip_edges())
	ui.paragraph(parent,"Você desperta na aldeia com sua primeira arma. A Guilda, os viajantes e os manuais encontrados serão os primeiros passos do seu cultivo.",18,520)
func path_description() -> String:return ["Combatente • +10% de dano nos ataques básicos.","Arcanista • +10% de dano de técnicas; geada dura +1 s.","Guardião • +20 de vida máxima."][int(ui.profile.path)]
func update_profile() -> void:
	if is_instance_valid(ui.preview):preload("res://wardrobe.gd").apply(ui.preview,ui.profile)
	if is_instance_valid(ui.race_description):ui.race_description.text=Catalog.RACES[int(ui.profile.race)].description
	if is_instance_valid(ui.path_description):ui.path_description.text=path_description()
func confirm_character() -> void:
	ui.profile.name=ui.profile.name.strip_edges()
	if ui.profile.name.is_empty():ui.creator_notice.text="Dê um nome ao seu personagem para começar.";return
	var chosen:=-1
	if not ui.procedural_seed.is_empty():
		if not ui.procedural_seed.is_valid_int() or int(ui.procedural_seed)<0 or int(ui.procedural_seed)>=2147483647:ui.creator_notice.text="Use uma seed inteira de 0 a 2147483646.";return
		chosen=int(ui.procedural_seed)
	if not world.flow.create_character(ui.profile,chosen):ui.creator_notice.text="Não foi possível confirmar o personagem."
