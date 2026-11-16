extends "res://qa/BaseInterfaceNativa.gd"
func held() -> String:
	return g.session.state.player.hand.item if g.session.state.player.get("hand")!=null else ""
func run():
	await start_game()
	await take("frango");check(held()=="frango","Retirada unitária da geladeira")
	await click_object("prep");advance(2.1);check(held()=="frango_cut","Corte fica nas mãos")
	await click_object("stove");check(g.session.state.player.hand==null,"Ingrediente entra na panela")
	await take("arroz");await click_object("stove");await click_object("stove")
	check(g.session.state.cooking!=null,"Cozimento começa por clique")
	advance(8.1);await click_object("stove");check(held()=="pot_frangoArroz_1","Retirada da panela pronta")
	await click_object("kitchen");advance(2.1)
	check(held()=="pot","Empratamento devolve panela vazia")
	await click_object("stove");await click_object("kitchen")
	check(held()=="dish_frangoArroz","Apoio, empratamento e prato nas mãos")
	g.session.ADMIN.test_clock(g.session.state,660)
	for recipe in g.session.state.menu:g.session.state.menu[recipe]=recipe=="frangoArroz"
	g.tick(0.05)
	for i in 200:
		g.tick(0.05)
		if g.session.pending==null:break
	check(g.session.state.open,"Restaurante abre automaticamente no horário")
	g.session.state.arrival=0 # Isolate the manually spawned guest from timed arrivals.
	await click_object("table") # Leave the arrival cell beside the service sign.
	# This kitchen workflow clicks the first table; chair randomness is covered
	# independently by AssentosClientesUI, so select that seat explicitly.
	var simulation = g.session.SIM.new();simulation.service.random_source=func():return 0.0
	check(simulation.spawn(g.session.state),"Cliente entra")
	# Finish this one service after closing arrivals. Other guests can now
	# share its table, and belong in the separate multi-seat scenarios.
	g.session.ADMIN.test_clock(g.session.state,900)
	advance(6)
	await click_object("table");check(g.session.state.orders.size()==1,"Mesa anota um pedido")
	await click_object("table");advance(4.1)
	check(g.session.state.ledger.sales==1 and g.session.state.ledger.revenue==20,"Entrega e pagamento únicos")
	await click_object("table");check(held()=="dirtyPlate","Louça recolhida")
	await click_object("sink");check(held()=="plate","Prato lavado")
	check(g.session.SAVE.VALIDATOR.valid(g.session.state),"Conservação e save válidos no fluxo completo")
	await finish()
