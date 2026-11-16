extends "res://qa/BaseNativa.gd"
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	# Freeze idle walking only for old JS snapshots; PolimentoSalaoUI tests it enabled.
	rules.idle_walk_enabled=false
	rules.timed_orders_enabled=false
	for test in load("res://qa/referencia-migracao/atendimento-fluxo.json").data:
		var state: Dictionary = test.input.duplicate(true);var simulation = preload("res://simulacao/nativa/Simulacao.gd").new();var draws: Array = [0]
		simulation.service.idle_walk_enabled=false
		simulation.service.timed_orders_enabled=false
		simulation.service.random_source=func():var value: float = [0.1,0.8,0.2,0.9,0.5][draws[0]%5];draws[0]+=1;return value
		for i in 800:
			simulation.step(state,0.1)
			if test.manual:
				for customer in state.customers.duplicate():
					if customer.state not in ["waiting","ordered"]:continue
					state.player.merge({"room":customer.room,"x":customer.x-1,"y":customer.y,"motion":null,"goal":null,"settled":null},true)
					if customer.state=="ordered":
						var prep: Variant = null
						for o in state.objects:
							if o.type=="kitchen":prep=o;break
						if state.player.get("hand")==null and simulation.service.STORE.count(prep,"dish_sopa")>0:simulation.service.STORE.take(state,prep,"dish_sopa",1,2);state.player.hand={"item":"dish_sopa","n":1,"quality":2}
					simulation.service.interact(state,customer.id)
		# The old JS snapshot always reserved a whole table in fixed order.
		# Chair selection/dirty reactions now intentionally change paths,
		# profiles and reviews; retain the end-to-end service invariants.
		check(state.customers.all(func(c):return c.state=="leave") and state.ledger.sales>=1,"Atendimento manual/garçom conclui visitas e vendas")
		check(state.ledger.sales+state.ledger.lost==3 and state.experience.visits.size()==3,"Cada uma das três chegadas termina em venda ou abandono registrado")
		check(state.meals.eaten.sopa==state.ledger.sales and state.ledger.revenue==state.ledger.sales*state.prices.sopa,"Comida servida, vendas e receita permanecem consistentes")
		check(draws[0]>=test.draws+3,"Chegadas também sorteiam cadeiras, além de perfis e avaliações")
		check(preload("res://simulacao/nativa/Salvamentos.gd").VALIDATOR.valid(state),"Estado de atendimento válido")
	var actions = load("res://qa/referencia-migracao/atendimento-acoes.json").data
	for test in actions:
		var draws: Array = [];var actual: Variant = null
		while true:
			actual=JSON.parse_string(rules.execute(JSON.stringify({"name":"atendimento","args":[test.operation,test.input,test.params,draws,false]},"",true,true)))
			if not actual.get("needsRandom",false):break
			draws.append(0.1)
		check(equivalent(actual,test.expected),"Ação "+test.operation);check(draws.size()==test.draws,"Sorteios da ação")
	print("AÇÕES: ",actions.size()," FALHAS: ",failures);quit(1 if failures else 0)
