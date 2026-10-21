extends RefCounted
const Catalog=preload("res://catalog.gd")
var menu: Control
var world: Node3D
func _init(owner_menu: Control) -> void:
 menu=owner_menu
 world=menu.world

func configuration(parent: Node) -> void:
 menu.text(parent,"EXO VISUAL 01 • CONFIGURAÇÕES AVANÇADAS",22).modulate=Color("d5ba80")
 menu.text(parent,"Renderizador atual: "+world.graphics.renderer_name()+" • Compatibility é o padrão; Forward+ requer reinicialização e testes.",13,800)
 var row:=HBoxContainer.new();parent.add_child(row);row.add_theme_constant_override("separation",25)
 var left:=VBoxContainer.new();row.add_child(left);left.custom_minimum_size.x=510;left.add_theme_constant_override("separation",7)
 menu.text(left,"PERFIS (atalhos; opções personalizáveis abaixo)",17)
 var preset_row:=GridContainer.new();preset_row.columns=3;left.add_child(preset_row)
 for i in range(5):
  var idx: int=i
  var button: Button=menu.button(preset_row,world.graphics.NAMES[idx]+(" • ATUAL" if world.graphics.level==idx else ""),func():world.graphics.select(idx);menu.open("config"),154)
  button.custom_minimum_size.y=36
 if world.graphics.level==5:menu.text(left,"Perfil atual: PERSONALIZADO",13)
 var spec=preload("res://exo_visual/spec.gd")
 for section in ["Tela","Iluminação","Ambiente","Efeitos","Texturas"]:
  menu.text(left,section.to_upper(),17).modulate=Color("d5ba80")
  for key in spec.OPTIONS:
   var option: Dictionary=spec.OPTIONS[key]
   if str(option.section)!=section:continue
   var current_key: String=str(key)
   var available: bool=world.graphics.option_available(current_key)
   var subrow:=HBoxContainer.new();left.add_child(subrow)
   var label_node:=Label.new();subrow.add_child(label_node)
   label_node.text=str(option.label)
   label_node.custom_minimum_size.x=275
   label_node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   var select_node:=OptionButton.new();subrow.add_child(select_node)
   select_node.custom_minimum_size.x=205
   for choice in option.choices:select_node.add_item(str(choice))
   select_node.select(world.graphics.get_option(current_key))
   select_node.disabled=not available
   select_node.tooltip_text="Requer Forward+; opção indisponível no Compatibility." if not available else str(option.label)
   select_node.item_selected.connect(func(value: int):world.graphics.set_option(current_key,value);menu.open("config"))
 menu.text(left,"Sombras pintadas essenciais e sinais de combate permanecem visíveis em qualquer perfil.",13,505)
 menu.text(left,"IDENTIDADE / MENU",17).modulate=Color("d5ba80")
 var themes:=OptionButton.new();left.add_child(themes)
 for value in ["EXO clássico","Anime japonês","Aventura","Fantasia rúnica"]:themes.add_item(value)
 themes.select(world.graphics.menu_style)
 themes.item_selected.connect(func(i: int):world.graphics.menu_style=i;world.graphics.save_settings();menu.shell.update_background())
 menu.button(left,"TREMOR DA CÂMERA: "+("SIM" if world.graphics.shake_enabled else "NÃO"),func():world.graphics.shake_enabled=not world.graphics.shake_enabled;world.graphics.save_settings();menu.open("config"))
 for key in ["ornaments","paper","preview_motion"]:
  var label_value: String={"ornaments":"ORNAMENTOS","paper":"PERGAMINHO","preview_motion":"RESPIRAÇÃO DO PERSONAGEM"}[key]
  menu.button(left,label_value+": "+("SIM" if world.graphics.get(key) else "NÃO"),func():world.graphics.set(key,not world.graphics.get(key));world.graphics.save_settings();menu.open("config"))
 var right:=VBoxContainer.new();row.add_child(right);right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var profile: Dictionary=world.journey.data.character if world.flow.phase=="adventure" else Catalog.hero_profile(int(world.journey.data.hero))
 world.ui.make_preview(right,profile,Vector2(350,385));menu.preview=world.ui.preview
 menu.text(right,"Arraste para girar • roda do mouse aproxima",12)

func audio_options(parent: Node) -> void:
 menu.text(parent,"PAISAGEM SONORA",23)
 menu.text(parent,"Golpes em camadas, movimentos marciais e vozes. Movimento e impacto são eventos distintos; as vozes têm intervalo próprio.",16,680)
 for key in ["master","combat","magic","voice","ambience","narrative","ui"]:
  menu.text(parent,{"master":"GERAL","combat":"GOLPES E IMPACTOS","magic":"TÉCNICAS E PRESENÇAS","ui":"INTERFACE","ambience":"AMBIENTE / PASSOS","narrative":"CRÔNICAS / NARRATIVA","voice":"VOZES DE COMBATE"}[key],16)
  var slider:=HSlider.new()
  parent.add_child(slider)
  slider.min_value=0
  slider.max_value=100
  slider.step=5
  slider.value=world.audio_fx.groups[key]*100
  slider.custom_minimum_size=Vector2(650,25)
  slider.value_changed.connect(func(value: float):world.audio_fx.select_volume(key,value/100.0))
 var samples: Dictionary={"punch":"SOCO NO AR • DESLOCAMENTO","fist_hit":"SOCO NO CORPO","strong_hit":"SOCO FORTE","critical_hit":"GOLPE CRÍTICO","fatal_hit":"GOLPE FATAL","swing":"KATANA NO AR","blade_hit":"ESPADA • CONTATO","wood_hit":"SOCO EM MADEIRA","hurt_male":"VOZ • DANO MASCULINO","hurt_female":"VOZ • DANO FEMININO","attack_male":"VOZ • ESFORÇO NO ATAQUE","gelo":"GELO • ESTALO","fogo":"FOGO • SOPRO","vento":"VENTO • AR","qi":"QI • LIBERAÇÃO","summon":"INVOCAÇÃO","boss_entry":"CHEFE • ENTRADA","boss_phase":"CHEFE • FASE","boss_prepare":"CHEFE • PREPARAÇÃO","boss_release":"CHEFE • LIBERAÇÃO","quest_complete":"MISSÃO • CONCLUSÃO","chronicle_koto":"CRÔNICA • KOTO"}
 for event in samples:
  menu.button(parent,"OUVIR • "+samples[event],func():world.audio_fx.play_event(event,"voice" if event in ["hurt_male","hurt_female","attack_male"] else "ambience" if event=="chronicle_koto" else "magic" if event in ["gelo","fogo","vento"] else "combat"))

func hud_options(parent: Node) -> void:
 var hud_class=preload("res://exo_hud.gd")
 menu.text(parent,"HUD / APRESENTAÇÃO EXO",23)
 for spec in [["style","ESTILO",hud_class.STYLES],["theme","PALETA",hud_class.THEMES],["anchor","POSIÇÃO",hud_class.ANCHORS]]:
  menu.text(parent,spec[1],16)
  var options:=OptionButton.new()
  parent.add_child(options)
  for value in spec[2]:options.add_item(value)
  options.select(int(world.graphics.hud[spec[0]]))
  options.item_selected.connect(func(i: int):world.graphics.hud[spec[0]]=i;world.graphics.save_settings())
 for spec in [["scale","ESCALA",.6,1.5,.05],["opacity","OPACIDADE",.2,1.0,.05]]:
  menu.text(parent,spec[1],16)
  var slider:=HSlider.new()
  parent.add_child(slider)
  slider.min_value=spec[2]
  slider.max_value=spec[3]
  slider.step=spec[4]
  slider.value=world.graphics.hud[spec[0]]
  slider.custom_minimum_size=Vector2(650,22)
  slider.value_changed.connect(func(value: float):world.graphics.hud[spec[0]]=value;world.graphics.save_settings())
 for key in ["portrait","values","compact","target","notices"]:
  var names: Dictionary={"portrait":"RETRATO","values":"VALORES NUMÉRICOS","compact":"COMPACTO","target":"ALVO","notices":"AVISOS DO SISTEMA"}
  menu.button(parent,names[key]+": "+("SIM" if world.graphics.hud[key] else "NÃO"),func():world.graphics.hud[key]=not world.graphics.hud[key];world.graphics.save_settings();menu.open("hud"))

func controls(parent: Node) -> void:
 menu.text(parent,"CONTROLES",23)
 menu.text(parent,"WASD • mover\nMouse • orientar\nClique • atacar\nR • guardar/retomar arma e mãos livres\nF • rolar\n1 / 2 / 3 • técnicas\nE • interagir e recolher\nP • Central do Aventureiro\nI • inventário\nTab • mapa\nEsc • pausa",19,680)

func help_page(parent: Node) -> void:
 menu.text(parent,"PRIMEIROS PASSOS",23)
 menu.text(parent,"Procure a representante da Guilda na praça e pressione E para aceitar seu primeiro contrato. Recolha os pacotes deixados pelos inimigos. Os manuais são lidos no inventário; conhecimentos descobertos aparecem em Personagem > Técnicas.",18,680)
 menu.text(parent,"Maestria da técnica cresce com resultados válidos. Atacar o vazio não concede maestria. Graus de domínio melhoram potência, custo e recarga conforme cada técnica. Meditação e descoberta permanecem requisitos separados.",18,680)
