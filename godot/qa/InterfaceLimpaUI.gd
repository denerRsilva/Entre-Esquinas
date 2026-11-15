extends "res://qa/BaseInterfaceNativa.gd"
func clean(label: String) -> Dictionary:
	var packet: Dictionary = g.session.step(0,[])
	g.hud.sync(packet)
	check(not packet.ui.has("notice") and not packet.ui.has("hint"),label+": sem aviso flutuante")
	check(packet.ui.get("ordersHud")==null and packet.ui.get("kitchenStatus")==null,label+": sem painéis automáticos")
	check(not g.hud.slots.ordersHud[0].visible and not g.hud.slots.kitchenStatus[0].visible,label+": janelas de feedback invisíveis")
	for op in packet.scene:
		if op[0]=="rect":check(op[5]!="#25473df2",label+": sem molduras de feedback sobre clientes")
		if op[0]=="text":check(op[3] in ["✦","!"],label+": sem nomes, instruções ou confirmações no cenário")
	return packet
func run():
	await start_game()
	check(not g.hud.slots.has("notice") and not g.hud.slots.has("hint"),"HUD não cria janelas de notificação")
	clean("Início mobiliado")
	g.session.notify("Mensagem de teste de sucesso");g.tick(0);clean("Ação concluída")
	g.session.notify("Mensagem de teste de erro",true);g.tick(0);clean("Ação indisponível")
	await take("frango");await click_object("prep")
	var packet := clean("Corte em andamento")
	check(packet.scene.any(func(op):return op[0]=="progress" and str(op[1]).begins_with("task:")),"Corte mantém barra animada no objeto")
	advance(2.1)
	check(g.session.state.player.hand.item=="frango_cut","Corte termina e devolve ingrediente sem precisar de notificação")
	clean("Corte concluído")
	await click_object("stove")
	packet=clean("Interação com fogão")
	g.session.selected=null;g.tick(0)
	await click_object("fridge")
	check(g.frame_data.modal=="management" and g.hud.slots.modal[0].visible,"Inventário continua acessível por interação")
	g.session.close_dialog();g.tick(0)
	g.session.open_dialog("options");g.tick(0)
	check(g.hud.slots.modal[0].visible,"Opções continuam acessíveis")
	g.session.close_dialog();g.tick(0)
	g.session.enter_construction();g.session.begin_build("worktable");g.tick(0)
	check(g.hud.slots.build[0].visible,"Confirmação necessária da construção continua disponível")
	g.session.root_action("exitConstruction");g.tick(0)
	var s: Dictionary = g.session.state
	g.session.ADMIN.test_clock(s,660);g.tick(0)
	var sim = g.session.simulation
	sim.service.random_source=func():return 0.5
	check(sim.spawn(s),"Cliente entra para verificar interação sem painel de pedidos")
	var customer: Dictionary = s.customers[0]
	customer.state="waiting";customer.motion=null;customer.goal=null
	var chair = g.session.BUILD.find(s.objects,customer.seat)
	customer.x=chair.x;customer.y=chair.y
	s.player.x=chair.x;s.player.y=chair.y+1;s.player.motion=null;s.player.goal=null
	sim.service.begin(s,customer,"service");sim.service.take_order(s,s.player,customer)
	g.session.selected=customer.id;g.tick(0);await layout()
	check(await press("Priorizar pedido") and s.priority==customer.order,"Prioridade continua acessível ao interagir com cliente")
	packet=clean("Cliente com pedido")
	check(packet.scene.any(func(op):return op[0]=="food" and op[1]==customer.recipe),"Pedido continua identificado por ícone de comida")
	if "--capture" in OS.get_cmdline_user_args():
		root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1920,1080);await layout();g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-interface-limpa.png")
	await finish()
