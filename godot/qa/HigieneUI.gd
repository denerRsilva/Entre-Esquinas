extends "res://qa/BaseInterfaceNativa.gd"
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
const HYGIENE = preload("res://simulacao/nativa/Higiene.gd")
const SAVE = preload("res://simulacao/nativa/Salvamentos.gd")
const COOK = preload("res://simulacao/nativa/Cozinha.gd")
func object(s: Dictionary,type: String):
	for o in s.objects:
		if o.type==type:return o
	return null
func beside(s: Dictionary,o: Dictionary) -> void:
	var p = SIM.MOVE.closest(s,s.player,o)
	check(p!=null,"Jogador alcança alvo de limpeza")
	if p!=null:s.player.merge({"x":p.x,"y":p.y,"motion":null,"goal":null,"settled":null},true)
func reload(s: Dictionary) -> Variant:
	var raw: Variant = SAVE.serialize(s)
	return SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
func capture(s: Dictionary,name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	g.session.state=s;g.tick(0);await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/esquinas-higiene-"+name+".png")
func click_cell(x: int,y: int) -> void:
	var point: Dictionary = g.session.CAMERA.screen_point(x*40+20,y*40+25,g.session.rect,g.session.viewport,g.session.camera)
	g.events.append({"kind":"pointer","phase":"down","x":point.x,"y":point.y})
	g.events.append({"kind":"pointer","phase":"up","x":point.x,"y":point.y});g.tick(0)
	for i in 300:
		g.tick(0.05)
		if g.session.pending==null and g.session.state.player.get("motion")==null:break
	await layout()
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var sim := SIM.new();sim.service.random_source=func():return 0.5
	check(sim.spawn(s),"Cliente entra para testar refeição e sujeira")
	var c: Dictionary = s.customers[0]
	# Deterministically choose one of the visits which spills on the floor.
	for i in 100:
		var id := "clientH"+str(i)
		if posmod(hash(str(int(s.day))+":"+id+":"+str(c.recipe)),100)<35:c.id=id;break
	var chair = SIM.BUILD.find(s.objects,c.seat)
	var table = SIM.BUILD.chair_table(chair,s.objects)
	c.merge({"x":chair.x,"y":chair.y,"motion":null,"goal":null,"settled":null,"state":"waiting"},true)
	sim.service.begin(s,c,"service")
	var access = sim.service.customer_access(s,s.player,c)
	check(access!=null,"Cliente alcançável para servir")
	if access!=null:s.player.merge({"x":access.x,"y":access.y,"motion":null,"goal":null,"settled":null},true)
	check(sim.service.take_order(s,s.player,c),"Pedido anotado")
	# A previously cooked/plated serving: move one real plate from the station.
	object(s,"kitchen").plates-=1;s.meals.made[c.recipe]+=1
	s.player.hand={"item":"dish_"+c.recipe,"n":1}
	check(sim.service.interact(s,c.id) and c.state=="eating","Prato servido para refeição real")
	sim.service.clients_step(s,4.1)
	var seat := str(int(c.seat))
	check(c.state=="leave" and s.dirtyTables[seat]==1 and s.tableStains[seat]==1,"Fim da refeição deixa prato e mancha separados")
	check(s.floorDirt.size()==1,"Refeição selecionada deixa migalhas no chão")
	var key: String = s.floorDirt.keys()[0]
	var floor = HYGIENE.floor_point(key)
	check(floor!=null and not SIM.MOVE.blocked(s,"restaurant",floor.x,floor.y),"Sujeira surge em piso livre, fora dos móveis")
	var dirt_before := JSON.stringify([s.tableStains,s.floorDirt])
	sim.service.clients_step(s,0.1)
	check(JSON.stringify([s.tableStains,s.floorDirt])==dirt_before,"Mesma refeição não suja de novo a cada quadro")
	check(SAVE.VALIDATOR.valid(s),"Refeição e sujeira preservam conservação")
	var saved: Variant = reload(s)
	check(saved!=null and equivalent(saved.tableStains,s.tableStains) and equivalent(saved.floorDirt,s.floorDirt),"Save/load preserva manchas e migalhas")
	check(reload(PARTIDA.furnished(true,true))!=null,"Save antigo sem campos de sujeira continua aceito")
	await capture(s,"sujo")
	var kitchen := COOK.new();beside(s,table)
	check(not kitchen.wipe(s,table.id).ok and s.dirtyTables[seat]==1,"Pano não apaga os pratos ainda na mesa")
	check(kitchen.collect_dirty(s,table.id).ok and s.tableStains[seat]==1,"Recolher prato não remove a mancha")
	check(not kitchen.wipe(s,table.id).ok,"Mãos com louça não passam pano")
	var sink = object(s,"sink");beside(s,sink)
	check(kitchen.wash(s,sink.id).ok,"Jogador lava o prato recolhido")
	var station = object(s,"kitchen");beside(s,station)
	check(kitchen.physical(s,station.id,"installPlates").ok and s.player.hand==null,"Prato limpo devolvido sem perdas")
	advance(2.1) # Let the finished guest physically leave before construction.
	await capture(s,"manchas")
	check(not SIM.BUILD.remove(s,table.id).ok,"Mancha impede guardar mesa para apagar a sujeira")
	var cash: float = s.cash
	var blocked_build := SIM.BUILD.place(s,"plant",floor.x,floor.y)
	check(not blocked_build.ok and blocked_build.error=="Limpe o chão antes de posicionar o móvel." and s.cash==cash,"Construção não esconde sujeira sob móvel nem cobra por tentativa inválida")
	beside(s,table);g.session.selected=table.id;g.tick(0);await layout()
	var first: String = g.session.game_ui.first_context
	check(g.session.game_ui.controls.actions.has(first) and g.session.game_ui.controls.actions[first].kind=="wipe","Tecla de interação prioriza passar pano quando a louça já foi recolhida")
	g.events.append({"kind":"key","key":"e","down":true});g.tick(0)
	g.events.append({"kind":"key","key":"e","down":false});g.tick(0)
	check(not s.tableStains.has(seat),"Tecla E executa a limpeza da mesa")
	# Restore one mark to exercise the independent pointer path as well.
	s.tableStains[seat]=1;g.tick(0)
	await click_cell(table.x,table.y)
	check(not s.tableStains.has(seat) and s.dirtyTables[seat]==0,"Clique na mesa livre limpa a superfície")
	await click_cell(floor.x,floor.y)
	check(not s.floorDirt.has(key),"Clique na sujeira aproxima jogador e limpa o chão")
	check(SAVE.VALIDATOR.valid(s) and s.equipment.plate==12 and s.meals.eaten[c.recipe]==1,"Limpeza não cria ou apaga pratos e refeições")
	await capture(s,"limpo")
	# The default active waiter completes all three jobs, in the real movement loop.
	if saved!=null:
		var live: Dictionary = saved
		live.player.merge({"x":18,"y":11,"motion":null,"goal":null,"settled":null},true)
		live.workers[0].task="waiter"
		var worker_sim := SIM.new();worker_sim.service.random_source=func():return 0.5
		var worst := 0
		for i in 1000:
			var before := Time.get_ticks_usec();worker_sim.step(live,0.05);worst=maxi(worst,Time.get_ticks_usec()-before)
			if live.tableStains.is_empty() and live.floorDirt.is_empty() and object(live,"sink").get("dirtyPlates",0)==1:break
		check(live.tableStains.is_empty() and live.floorDirt.is_empty(),"Garçom recolhe louça, limpa mesa e limpa chão automaticamente")
		check(object(live,"sink").get("dirtyPlates",0)==1 and SAVE.VALIDATOR.valid(live),"Sujeira limpa com prato real ainda na pia")
		check(worst<100000,"Planejamento de limpeza não bloqueia quadros por 100ms")
		print("PIOR TICK HIGIENE (ms): ",worst/1000.0)
	# Stained surfaces still count as dirty after all physical plates are gone.
	var dirty_room: Dictionary = PARTIDA.furnished(true,true)
	dirty_room.workers[0].task="none";dirty_room.tableStains={}
	var marked := {}
	for o in dirty_room.objects:
		if o.type!="chair":continue
		var linked = SIM.BUILD.chair_table(o,dirty_room.objects)
		if linked!=null and not marked.has(linked.id):marked[linked.id]=true;dirty_room.tableStains[str(int(o.id))]=1
	check(sim.spawn(dirty_room) and dirty_room.customers[0].state=="leave","Mesas manchadas continuam causando rejeição até serem limpas")
	for invalid_data in [{"floorDirt":{"-1,0":1}},{"floorDirt":{"8,7":4}},{"floorDirt":{"08,7":1}},{"tableStains":{"99999":1}},{"tableStains":[]}]:
		var invalid: Dictionary = PARTIDA.furnished(true,true);invalid.merge(invalid_data,true)
		check(not SAVE.VALIDATOR.valid(invalid),"Save rejeita coordenadas, referência ou intensidade inválidas")
	var clear_state: Dictionary = dirty_room.duplicate(true)
	clear_state.floorDirt={"8,7":1};g.session.UI_COMMAND.execute(clear_state,"clear",[])
	check(not clear_state.has("tableStains") and not clear_state.has("floorDirt") and SAVE.VALIDATOR.valid(clear_state),"Limpar cenário de testes também remove referências de sujeira")
	await finish()
