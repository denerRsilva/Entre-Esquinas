extends "res://qa/BaseInterfaceNativa.gd"
func check_panel(label: String) -> void:
	await layout()
	var bounds := Rect2(Vector2.ZERO,g.hud.get_viewport_rect().size)
	var panel: Control = g.hud.slots.build[0]
	check(bounds.encloses(panel.get_global_rect()),label+": painel dentro da tela")
	for button in panel.find_children("*","Button",true,false):
		if button.is_visible_in_tree():
			check(bounds.encloses(button.get_global_rect()),label+": "+button.text+" dentro da tela")
func run():
	await start_game();g.session.enter_construction()
	g.session.begin_build("worktable");g.session.hover={"x":20,"y":11};g.tick(0)
	await check_panel("Comprar mesa")
	g.session.hover={"x":7,"y":14};g.tick(0)
	await check_panel("Mensagem de posição inválida")
	var table: Variant = null
	for object in g.session.state.objects:
		if object.type=="kitchen":table=object;break
	g.session.begin_build(table.type,table.id);g.tick(0)
	await check_panel("Mover com cinco ações")
	g.session.begin_build("cuttingKit");g.tick(0)
	await check_panel("Instalar kit")
	for viewport in [Vector2i(1280,720),Vector2i(2048,922),Vector2i(960,540)]:
		root.size=viewport;g.tick(0)
		g.session.begin_build(table.type,table.id);g.tick(0)
		await check_panel("Paisagem "+str(viewport))
	await finish()
