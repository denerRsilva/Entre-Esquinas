extends "res://qa/BaseInterfaceNativa.gd"
const ATLAS = preload("res://arte/modular/bancadas-piskel.png")
const SCENES = preload("res://moveis/Catalogo.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var initial_cash: float = s.cash
	g.session.enter_construction();g.tick(0)
	check(await press("Bancadas") and g.session.catalog_ui.category=="bancadas","Abre seção Bancadas")
	var types := []
	for type in g.session.BUILD.CATALOG.data:
		if g.session.BUILD.CATALOG.data[type].has("counterPart"):types.append(type)
	check(types.size()==16,"Catálogo registra os dezesseis recortes editados")
	for type in types:
		check(g.session.catalog_ui.controls.actions.has("nativo:comprar:"+type),"Peça disponível na seção: "+type)
		widget("nativo:comprar:"+type);g.session.hover={"x":20,"y":11};g.tick(0)
		check(await press("Confirmar posição"),"Instala peça "+type)
		var object: Dictionary = s.objects.back()
		check(object.type==type and g.session.drawer and g.session.catalog_ui.category=="bancadas","Confirma compra e volta à mesma seção")
		var view = g.palco.pool[type][0]
		check(view.ATLAS==ATLAS and view.grossa==(g.session.BUILD.CATALOG.data[type].counterFamily=="wide"),"Mundo usa o PNG editado e a família correta")
		g.session.begin_build(type,object.id);g.tick(0)
		check(await press("Espelhar ↔"),"Espelha sem deitar a frente da bancada")
		g.session.hover={"x":20,"y":11};g.tick(0)
		check(await press("Confirmar posição") and object.rot==0,"Objeto de origem não é alterado antes da substituição")
		object=g.session.BUILD.find(s.objects,object.id)
		check(object.rot==1 and g.session.MOVE.MAP.rect(object).size==Vector2i.ONE,"Espelhamento mantém ocupação de uma célula")
		var saved = g.session.SAVE.serialize(s)
		var restored = g.session.SAVE.new().load_value(JSON.parse_string(saved)) if saved is String else null
		check(restored!=null and g.session.BUILD.find(restored.objects,object.id).type==type,"Salvar e carregar preserva a peça editada")
		check(STORE.put(s,object,"pot",1)==1,"Bancada vazia apoia panela")
		s.equipment.pot+=1
		check(g.session.SAVE.VALIDATOR.valid(s),"Panela apoiada conserva estado")
		check(not g.session.BUILD.remove(s,object.id).ok,"Guardar bancada ocupada não apaga a panela")
		check(STORE.take(s,object,"pot",1)==1,"Retira panela da bancada")
		s.equipment.pot-=1
		g.session.begin_build(type,object.id);g.tick(0)
		check(await press("Guardar e reembolsar") and s.cash==initial_cash,"Guarda a peça com reembolso integral")
	check(g.session.SAVE.VALIDATOR.valid(s),"Todos os tipos preservam estado e economia")
	if "--capture" in OS.get_cmdline_user_args():await capture_art()
	await finish()
func capture_art() -> void:
	var view := SubViewport.new();view.size=Vector2i(1600,1020);view.transparent_bg=false
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var background := ColorRect.new();background.color=Color("#34483e");background.size=Vector2(1600,1020);view.add_child(background)
	for family in 2:
		var prefix := "counterThin" if family==0 else "counterWide"
		var origin := Vector2(100,460+family*490)
		for item in [["Left",Vector2i(0,0)],["Middle",Vector2i(1,0)],["Right",Vector2i(2,0)],["Top",Vector2i(4,-2)],["Vertical",Vector2i(4,-1)],["CornerLeft",Vector2i(4,0)],["Middle",Vector2i(5,0)],["Right",Vector2i(6,0)]]:
			var node = SCENES.CENAS[prefix+item[0]].instantiate();view.add_child(node)
			node.position=origin+Vector2(item[1])*120;node.scale=Vector2.ONE*3;node.definir_origem(item[1]*40)
		for item in [["Left",Vector2i(8,0)],["Middle",Vector2i(9,0)],["CornerRight",Vector2i(10,0)],["Top",Vector2i(10,-2)],["Vertical",Vector2i(10,-1)]]:
			var node = SCENES.CENAS[prefix+item[0]].instantiate();view.add_child(node)
			node.position=origin+Vector2(item[1])*120;node.scale=Vector2.ONE*3;node.definir_origem(item[1]*40)
			if item[0] in ["Top","Vertical"]:node.configurar(1)
		for item in [["Top",Vector2i(12,-2)],["Vertical",Vector2i(12,-1)],["Base",Vector2i(12,0)]]:
			var node = SCENES.CENAS[prefix+item[0]].instantiate();view.add_child(node)
			node.position=origin+Vector2(item[1])*120;node.scale=Vector2.ONE*3;node.definir_origem(item[1]*40)
		var title := Label.new();title.text="Bancada fina" if family==0 else "Bancada grossa";title.position=Vector2(30,30+family*490);title.add_theme_font_size_override("font_size",25);view.add_child(title)
	await layout();await RenderingServer.frame_post_draw
	var shot := view.get_texture().get_image()
	var background_pixel := shot.get_pixel(0,0)
	for family in 2:
		var bottom := 460+family*490
		# External raster checks: no transparent gaps in the common front lip,
		# in either elbow, or where a vertical band meets its terminal base.
		for interval in [Vector2i(46,394),Vector2i(526,874),Vector2i(1006,1354)]:
			for x in range(interval.x,interval.y):check(shot.get_pixel(x,bottom-94)!=background_pixel,"Tampo contínuo, sem buraco entre peças")
		var center_x := 1508 if family==0 else 1526
		for y in range(bottom-437,bottom-94):check(shot.get_pixel(center_x,y)!=background_pixel,"Vertical e base sem faixa transparente")
	shot.save_png("/tmp/esquinas-bancadas-piskel-montadas.png")
	view.queue_free();await process_frame
