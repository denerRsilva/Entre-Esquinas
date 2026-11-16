extends "res://qa/BaseInterfaceNativa.gd"
const BAR = preload("res://interface/BarraAnimada.gd")
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var sim = g.session.simulation
	sim.service.random_source=func():return 0.5
	g.session.ADMIN.test_clock(s,660);g.tick(0)
	var home := Vector2i(s.player.x,s.player.y)
	check(not g.hud.comandas.visible,"Sem comandas antes de anotar pedidos")
	for i in 3:
		check(sim.spawn(s),"Cliente entra em mesa livre")
		var c: Dictionary = s.customers.back()
		var chair = g.session.BUILD.find(s.objects,c.seat)
		c.merge({"x":chair.x,"y":chair.y,"motion":null,"goal":null,"state":"waiting"},true)
		sim.service.begin(s,c,"service");g.tick(0)
		check(g.hud.comandas.cards.size()==i,"Cliente sem pedido anotado não gera papel")
		s.player.merge({"x":chair.x,"y":chair.y+1,"motion":null,"goal":null},true)
		check(sim.service.take_order(s,s.player,c),"Pedido é anotado")
		s.player.x=home.x;s.player.y=home.y
		c.experience.elapsed.food=c.experience.limits.food*[0.1,0.6,0.9][i]
	g.tick(0);await layout()
	var paper = g.hud.comandas
	var entries: Array = g.frame_data.ui.comandas
	check(entries.size()==3 and paper.visible and paper.cards.size()==3,"Três pedidos viram três comandas")
	var identities := {}
	var table_numbers := {}
	for object in s.objects:
		if object.type=="table":table_numbers[object.id]=table_numbers.size()+1
	for i in 3:
		var entry: Dictionary = entries[i]
		var card = paper.cards[str(entry.id)]
		identities[str(entry.id)]=card.get_instance_id()
		var chair = g.session.BUILD.find(s.objects,s.customers[i].seat)
		var table = g.session.BUILD.chair_table(chair,s.objects)
		var number: int = table_numbers[table.id]
		check(entry.table==number and card.table==str(number).pad_zeros(2),"Número identifica a mesa, sem usar ID do pedido")
		check(card.dish.texture==g.session.game_ui.controls.FOOD.texture(entry.recipe),"Imagem corresponde à receita real")
		check(card.bar.get_script()==BAR and is_equal_approx(card.bar.value,[0.9,0.4,0.1][i]),"Mesma barra animada acompanha paciência do cliente")
		check(card.tooltip_text.is_empty() and not card.accessibility_name.is_empty(),"Sem tooltip ou texto extra; descrição acessível preservada")
	var raw: Variant = g.session.SAVE.serialize(s)
	var restored: Variant = g.session.SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
	check(restored!=null,"Partida com comandas continua salvável")
	if restored!=null:check(equivalent(g.session.game_ui.comandas(restored),entries),"Save restaura números, receitas e progresso das comandas")
	for i in 60:
		s.customers[0].experience.elapsed.food+=0.01;g.tick(0)
	for entry in entries:
		check(paper.cards[str(entry.id)].get_instance_id()==identities[str(entry.id)],"Atualização de progresso reaproveita o papel existente")
	# Overflow stays reachable by horizontal touch scroll, within safe bounds.
	var many: Array = []
	for i in 12:many.append({"id":1000+i,"table":i+1,"recipe":"sopa","ratio":0.8})
	for extent in [Vector2(960,540),Vector2(1280,720),Vector2(1170,540),Vector2(540,960)]:
		var safe := Rect2(Vector2(24,12),extent-Vector2(48,24))
		paper.sync(many,safe);await layout()
		check(safe.encloses(paper.get_rect()),"Comandas ficam dentro da área segura em "+str(extent))
		check(paper.get_h_scroll_bar().max_value>paper.size.x,"Pedidos excedentes disponíveis na rolagem")
		paper.scroll_horizontal=9999;await layout()
		check(paper.scroll_horizontal>0,"Rolagem alcança os últimos pedidos")
	# Actual phone/PC screenshots use the same gameplay HUD, never a mockup.
	g.tick(0);await layout();paper.scroll_horizontal=0
	if "--capture" in OS.get_cmdline_user_args():
		root.mode=Window.MODE_WINDOWED
		for setting in [[Vector2i(1280,720),"pc"],[Vector2i(1170,540),"celular"]]:
			root.size=setting[0];await layout();g.tick(0);await layout();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/esquinas-comandas-"+setting[1]+".png")
	g.session.open_dialog("options");g.tick(0);check(not paper.visible,"Menus ocultam comandas")
	g.session.close_dialog();s.player.room="street";g.tick(0);check(not paper.visible,"Cidade não mostra pedidos do interior")
	s.player.room="restaurant";g.tick(0)
	var first: Dictionary = s.customers[0]
	var order: Dictionary = s.orders[0]
	order.state="ready";s.player.carry={"kind":"dish","order":order.id,"quality":0};g.tick(0)
	check(paper.cards.has(str(order.id)),"Pedido continua visível durante entrega")
	s.player.merge({"x":first.x,"y":first.y+1,"motion":null,"goal":null},true)
	check(sim.service.serve(s,s.player,first),"Prato entregue ao cliente")
	g.tick(0);check(not paper.cards.has(str(order.id)) and paper.cards.size()==2,"Servir remove só a comanda concluída")
	check(sim.service.abandon(s,s.customers[1]),"Cliente pode cancelar pedido")
	g.tick(0);check(paper.cards.size()==1,"Cancelamento remove comanda sem deixar papel órfão")
	var remaining_id: String = str(s.orders[2].id)
	check(paper.cards.has(remaining_id),"Comanda restante preserva identidade após remoções")
	s.orders[2].state="paid";g.tick(0)
	check(not paper.visible and paper.cards.is_empty(),"Sem pedidos ativos, tela fica livre de comandas")
	s.customers.clear();s.orders.clear();s.open=false
	g.session.enter_construction();g.tick(0)
	check(g.session.construction and not paper.visible,"Modo construção mantém tela sem comandas")
	await finish()
