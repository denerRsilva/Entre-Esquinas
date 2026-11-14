extends "res://qa/BaseInterfaceNativa.gd"
func run():
	await start_game();g.session.enter_construction();g.tick(0)
	var quantity: int = g.session.state.objects.size();var cash: float = g.session.state.cash
	widget("nativo:comprar:counterH");check(g.session.building.type=="counterH" and not g.session.drawer,"Catálogo inicia posicionamento")
	g.session.hover={"x":20,"y":11};g.tick(0)
	check(g.session.preview_error()==null and await press("Confirmar posição"),"Posicionamento pela interface")
	check(g.session.state.objects.size()==quantity+1 and g.session.state.cash==cash-35 and g.session.drawer,"Compra e retorno automático do catálogo")
	var counter: Variant = null
	for object in g.session.state.objects:
		if object.type=="counterH":counter=object;break
	g.session.begin_build("counterH",counter.id);g.tick(0)
	check(await press("Girar ↻") and g.session.building.rot==1,"Rotação nativa")
	check(await press("Guardar e reembolsar") and g.session.state.objects.size()==quantity and g.session.state.cash==cash,"Remoção e reembolso")
	g.session.root_action("exitConstruction");g.session.set_zoom(2);g.session.enter_construction();g.session.drawer=false;g.session.camera.x=300;g.session.camera.y=300;g.session.update_camera();g.tick(0)
	var before: Dictionary = g.session.camera.duplicate(true)
	var point: Dictionary = g.session.CAMERA.screen_point(13*40+20,10*40+20,g.session.rect,g.session.viewport,g.session.camera)
	g.events.append({"kind":"pointer","phase":"down","x":point.x,"y":point.y});g.tick(0)
	g.events.append({"kind":"pointer","phase":"move","x":point.x-60,"y":point.y+30,"drag":true});g.tick(0)
	check(absf(g.session.camera.x-before.x-60/before.zoom)<1e-8 and absf(g.session.camera.y-before.y+30/before.zoom)<1e-8,"Arrasto do mapa respeita zoom")
	g.events.append({"kind":"pointer","phase":"up","x":point.x-60,"y":point.y+30});g.tick(0)
	check(g.session.build_pointer==null,"Fim do arrasto")
	var time: float = g.session.state.time;advance(1)
	check(g.session.state.time==time,"Construção pausa a simulação")
	check(g.session.SAVE.VALIDATOR.valid(g.session.state),"Construção preserva partida válida")
	await finish()
