extends RefCounted
const Catalog=preload("res://catalog.gd")
var ui: CanvasLayer
var world: Node3D
func _init(owner_ui: CanvasLayer) -> void:ui=owner_ui;world=ui.world
func show_hero() -> void:
	world.journey.data.phase="hero"
	var selected: int=int(world.journey.data.hero)
	var hero: Dictionary=Catalog.HEROES[selected]
	var col: VBoxContainer=ui.begin_screen("hero")
	col.add_theme_constant_override("separation",10)
	ui.title(col,"GUERRA DO PANTEÃO",30)
	ui.label(col,"Escolha a memória que deseja reviver. Seu personagem será criado após o prólogo.",16).modulate=Color("a5bac0")
	var row:=HBoxContainer.new();col.add_child(row);row.add_theme_constant_override("separation",30)
	var left:=VBoxContainer.new();row.add_child(left);left.custom_minimum_size.x=520;left.add_theme_constant_override("separation",10)
	var grid:=GridContainer.new();left.add_child(grid);grid.columns=3
	grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8)
	for i in range(Catalog.HEROES.size()):
		var item: Button=ui.button(grid,Catalog.ELEMENTS[i],func():world.journey.data.hero=i;show_hero())
		item.custom_minimum_size=Vector2(165,40)
		item.modulate=Color("d5ba80") if i==selected else Color(Catalog.COLORS[i]).lightened(.3)
	ui.paragraph(left,hero.name,23,520).modulate=Color("d5ba80")
	ui.paragraph(left,"%s • %s • %s"%[Catalog.RACES[int(hero.race)].name,hero.class_name,Catalog.weapon(hero.weapon).name],16,520)
	var skills: Array=[]
	for id in hero.skills:skills.append(Catalog.skill(id).name)
	ui.paragraph(left,"Técnicas no auge\n"+"  /  ".join(skills),16,520)
	ui.paragraph(left,"Onze elementos em conflito. Reforços contínuos até a chegada do Deus Supremo.",15,520)
	ui.button(left,"ENTRAR NA GUERRA",func():ui.close_flow();world.flow.start_prologue())
	var right:=VBoxContainer.new();row.add_child(right)
	ui.make_preview(right,Catalog.hero_profile(selected),Vector2(450,390))
	ui.paragraph(right,"Arraste para girar • roda do mouse aproxima",12,440)
	ui.button(right,"CONFIGURAÇÕES",ui.show_start_settings)
	ui.paragraph(col,"WASD mover • Mouse orientar • F rolar • 1 / 2 / 3 técnicas • E avança após 10 s • Intervenção em 90 s",13,1000)
