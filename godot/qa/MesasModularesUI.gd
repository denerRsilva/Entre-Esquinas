extends "res://qa/BaseInterfaceNativa.gd"
func run():
	await start_game()
	var state: Dictionary = g.session.state
	var build = g.session.BUILD
	var count: int = state.objects.size()
	var cash: float = state.cash
	g.session.enter_construction();g.tick(0)
	check(not g.session.catalog_ui.controls.actions.has("nativo:comprar:prep") and not g.session.catalog_ui.controls.actions.has("nativo:comprar:kitchen"),"Catálogo vende mesa e kits separados")
	for type in ["counterH","counterV","counterCorner"]:
		check(not g.session.catalog_ui.controls.actions.has("nativo:comprar:"+type),"Bancadas em refinamento não estão à venda: "+type)
	widget("nativo:comprar:worktable");g.session.hover={"x":20,"y":11};g.tick(0)
	check(await press("Confirmar posição"),"Compra da mesa vazia pela interface")
	var table: Dictionary = state.objects.back()
	var id: int = table.id
	check(table.type=="worktable" and state.cash==cash-55 and state.objects.size()==count+1,"Mesa vazia tem custo próprio e uma única ocupação")
	widget("nativo:comprar:cuttingKit");g.session.hover={"x":19,"y":10};g.tick(0)
	check(g.session.preview_error()!=null,"Kit não pode ser colocado no chão")
	var snapshot: Dictionary = state.duplicate(true)
	check(not build.place(state,"cuttingKit",19,10).ok and equivalent(snapshot,state),"Posição inválida não cobra nem altera estado")
	var poor: Dictionary = state.duplicate(true);poor.cash=0
	var poor_before: Dictionary = poor.duplicate(true)
	check(not build.place(poor,"cuttingKit",20,11).ok and equivalent(poor,poor_before),"Saldo insuficiente preserva mesa e dinheiro")
	g.session.hover={"x":21,"y":11};g.tick(0)
	check(g.session.preview_error()==null and await press("Confirmar posição"),"Kit encaixa na segunda célula da mesa")
	check(table.type=="prep" and table.tableKit=="cuttingKit" and table.id==id and state.objects.size()==count+1 and state.cash==cash-90,"Kit muda a função mantendo ID, base e ocupação")
	check(not build.place(state,"platingKit",20,11).ok,"Uma mesa aceita apenas um kit")
	var moved: Dictionary = build.place(state,"prep",20,10,0,id)
	check(moved.ok and moved.object.tableKit=="cuttingKit" and state.cash==cash-90,"Mover mesa transporta o kit sem cobrar novamente")
	var returned: Dictionary = build.place(state,"prep",20,11,0,id)
	check(returned.ok,"Mesa equipada volta ao ponto inicial")
	table=build.find(state.objects,id)
	var encoded: Variant = g.session.SAVE.serialize(state)
	var restored: Variant = g.session.SAVE.new().load_value(JSON.parse_string(encoded)) if encoded is String else null
	check(restored!=null and build.find(restored.objects,id).tableKit=="cuttingKit","Salvar e carregar preserva kit instalado")
	g.session.root_action("exitConstruction");g.tick(0)
	await take("frango")
	g.session.interact("physical",[id,"chop"])
	for i in 200:
		g.tick(0.05)
		if state.get("chopping")!=null:break
	check(state.get("chopping")!=null,"Mesa equipada inicia corte real após aproximação")
	var cutting_save: Variant = g.session.SAVE.serialize(state)
	var cutting_load: Variant = g.session.SAVE.new().load_value(JSON.parse_string(cutting_save)) if cutting_save is String else null
	check(cutting_load!=null and cutting_load.chopping.table==id,"Save restaura corte em andamento na mesa equipada")
	check(not build.remove_kit(state,id).ok,"Kit não sai durante o corte")
	advance(2.1)
	check(state.player.get("hand")!=null and state.player.hand.item=="frango_cut","Mesa nova devolve ingrediente cortado às mãos")
	g.session.enter_construction();g.session.begin_build("prep",id);g.tick(0)
	check(await press("Retirar kit") and table.type=="worktable" and state.cash==cash-55,"Retirar kit preserva mesa e reembolsa só ferramentas")
	widget("nativo:comprar:platingKit");g.session.hover={"x":20,"y":11};g.tick(0)
	check(await press("Confirmar posição") and table.type=="kitchen" and table.plates==0,"Mesma base pode virar estação de empratamento")
	check(g.session.SAVE.VALIDATOR.valid(state),"Estado e conservação válidos após troca de função")
	var old_kitchen: Variant = null
	for object in state.objects:
		if object.type=="kitchen" and object.id!=id:old_kitchen=object;break
	check(old_kitchen!=null and not build.remove_kit(state,old_kitchen.id).ok,"Mesa antiga mantém pratos e impede retirada indevida do kit")
	var loaded = g.session.SAVE.new().load_value(state)
	check(loaded!=null and build.find(loaded.objects,old_kitchen.id).plates==12,"Save anterior com mesa equipada e pratos continua válido")
	check(build.remove_kit(state,id).ok and build.remove(state,id).ok and state.cash==cash,"Desmontagem completa reembolsa os valores uma única vez")
	await finish()
