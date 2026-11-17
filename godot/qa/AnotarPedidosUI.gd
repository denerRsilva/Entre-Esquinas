extends "res://qa/BaseInterfaceNativa.gd"
func click_world(point: Vector2,wait: float = 10) -> void:
	var screen: Dictionary = g.session.CAMERA.screen_point(point.x,point.y,g.session.rect,g.session.viewport,g.session.camera)
	g.events.append({"kind":"pointer","phase":"down","x":screen.x,"y":screen.y});g.events.append({"kind":"pointer","phase":"up","x":screen.x,"y":screen.y});g.tick(0);advance(wait);await layout()
func visitor(initial: Dictionary,index: int) -> Dictionary:
	g.session.load_state(initial.duplicate(true));g.session.close_dialog()
	var s: Dictionary = g.session.state
	s.player.x=12;s.player.y=10
	g.session.ADMIN.test_clock(s,660);g.tick(0.01);s.arrival=0
	var sim = g.session.SIM.new();sim.service.random_source=func():return (index+0.01)/8.0
	check(sim.spawn(s),"Cliente chega para cadeira "+str(index))
	g.session.ADMIN.test_clock(s,900);advance(8)
	return s.customers[0]
func snapshot() -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/anotar-pedido-corrigido.png")
func run():
	root.size=Vector2i(1280,720);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout();await press("Novo jogo")
	var initial: Dictionary = g.session.state.duplicate(true)
	g.session.ADMIN.test_clock(g.session.state,660);g.tick(0.01);g.session.state.arrival=0
	var arriving = g.session.SIM.new();arriving.service.random_source=func():return 0.0
	check(arriving.spawn(g.session.state),"Cliente em chegada para testar clique antecipado")
	var guest: Dictionary = g.session.state.customers[0]
	await click_world(Vector2(guest.x*40+20,guest.y*40-12))
	check(guest.state=="ordered" and g.session.state.orders.size()==1,"Um clique durante a chegada aguarda sentar e anota sem segundo clique")
	var seats := {}
	for index in 8:
		var c: Dictionary = await visitor(initial,index)
		var s: Dictionary = g.session.state
		seats[c.seat]=true
		check(c.state=="waiting","Cliente terminou de sentar")
		await click_world(Vector2(c.x*40+20,c.y*40-12))
		check(c.state=="ordered" and s.orders.size()==1 and s.orders[0].customer==c.id,"Rosto seleciona e anota o cliente correto na cadeira "+str(index))
		check(g.session.SAVE.serialize(s)!=null,"Pedido anotado pode ser salvo")
		if index==0:await snapshot()
		await click_world(Vector2(c.x*40+20,c.y*40+4),1)
		check(s.orders.size()==1,"Clique repetido não duplica o pedido")
	check(seats.size()==8,"Exercita todas as cadeiras das duas mesas")
	for zoom in [0.7,1.5,2.0]:
		root.size=Vector2i(960,432);await layout();g.session.set_zoom(zoom)
		var c: Dictionary = await visitor(initial,1)
		g.session.state.player.x=11;g.session.state.player.y=7;g.session.state.player.goal=null;g.session.state.player.motion=null;g.session.state.player.erase("settled");g.tick(0)
		var target: Dictionary = g.session.CAMERA.screen_point(c.x*40+20,c.y*40-12,g.session.rect,g.session.viewport,g.session.camera)
		check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(Vector2(target.x,target.y)),"Rosto está visível antes do toque no zoom "+str(zoom))
		await click_world(Vector2(c.x*40+20,c.y*40-12))
		check(c.state=="ordered","Seleção acompanha câmera e tela compacta no zoom "+str(zoom))
	root.size=Vector2i(1280,720);await layout();g.session.set_zoom(1)
	g.session.load_state(initial.duplicate(true));g.session.state.player.x=12;g.session.state.player.y=10
	var s: Dictionary = g.session.state
	g.session.ADMIN.test_clock(s,660);g.tick(0.01);s.arrival=0
	var sim = g.session.SIM.new();sim.service.random_source=func():return 0.0
	for i in 3:check(sim.spawn(s),"Chegada de morador "+str(i));advance(6)
	g.session.ADMIN.test_clock(s,900)
	for c in s.customers:
		await click_world(Vector2(c.x*40+20,c.y*40-12))
		check(c.state=="ordered" and s.orders.any(func(o):return o.customer==c.id),"Clientes próximos recebem suas próprias comandas")
	check(s.orders.size()==3 and g.session.SAVE.serialize(s)!=null,"Três pedidos distintos persistem sem funcionário")
	# Legacy table-click and floor navigation remain available.
	var c: Dictionary = await visitor(initial,0)
	await click_world(Vector2(c.x*40+20,c.y*40+20))
	check(c.state=="ordered","Clique na célula do assento permanece válido")
	var control = g.session.INTERACT.new()
	check(control.visible_customer(g.session.state,{"x":18.0,"y":11.0})==null,"Cozinha vazia não seleciona cliente distante")
	g.session.enter_construction();g.tick(0)
	check(not g.session.construction,"Serviço pendente continua impedindo construção")
	await finish()
