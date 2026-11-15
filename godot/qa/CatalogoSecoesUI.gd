extends "res://qa/BaseInterfaceNativa.gd"
func run():
	await start_game()
	var s: Dictionary = g.session.state
	g.session.enter_construction();g.tick(0)
	for category in g.session.catalog_ui.SECTIONS:
		if category!=g.session.catalog_ui.category:check(await press(g.session.catalog_ui.SECTIONS[category]),"Muda seção pelo botão: "+category)
		check(g.session.catalog_ui.category==category,"Categoria atual correta")
		var count := 0
		for path in g.session.catalog_ui.controls.actions:
			if not path.begins_with("nativo:comprar:"):continue
			var type: String = path.trim_prefix("nativo:comprar:");count+=1
			check(g.session.catalog_ui.category_of(type)==category,"Seção mostra somente itens correspondentes")
		check(count>0,"Seção tem itens compráveis: "+category)
		for grid in g.hud.find_children("ConstructionGrid","GridContainer",true,false):check(grid.columns==2,"Seção mantém duas colunas")
	check(await press("Decorações"),"Volta a Decorações")
	for type in ["plant","flowers"]:
		widget("nativo:comprar:"+type);g.session.hover={"x":20,"y":11};g.tick(0)
		check(await press("Confirmar posição"),"Compra decoração: "+type)
		var object: Dictionary = s.objects.back()
		check(object.type==type and g.session.catalog_ui.category=="decoracoes","Compra volta à seção de decoração")
		check(g.session.SAVE.serialize(s) is String,"Decoração pode ser salva")
		g.session.begin_build(type,object.id);g.tick(0);check(await press("Guardar e reembolsar"),"Recolhe decoração")
	for viewport in [Vector2i(960,540),Vector2i(2048,922),Vector2i(1280,720)]:
		root.size=viewport;g.tick(0);await layout()
		var bounds := Rect2(Vector2.ZERO,Vector2(viewport))
		for button in g.hud.find_children("*","Button",true,false):
			if button.text in g.session.catalog_ui.SECTIONS.values() and button.is_visible_in_tree():check(bounds.encloses(button.get_global_rect()),"Botão de seção dentro da tela: "+button.text)
	if "--capture" in OS.get_cmdline_user_args():
		root.size=Vector2i(1920,1080);g.tick(0);await layout();await press("Bancadas");await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-catalogo-secoes.png")
	check(g.session.SAVE.VALIDATOR.valid(s),"Navegação e compras preservam estado")
	await finish()
