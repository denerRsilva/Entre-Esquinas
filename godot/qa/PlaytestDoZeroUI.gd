extends "res://qa/BaseInterfaceNativa.gd"
var stages: Array = []
func caption(b: BaseButton) -> String:return str(b.get_meta("action_label",b.tooltip_text if not b.tooltip_text.is_empty() else b.text))
func tap(point: Vector2) -> void:
	var move := InputEventMouseMotion.new();move.position=point;move.global_position=point;root.push_input(move,true)
	for down in [true,false]:
		var e := InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
	await process_frame;g.tick(0);await layout()
func choose(title: String,prefix: bool = false) -> bool:
	await layout()
	for b in g.hud.find_children("*","BaseButton",true,false):
		if not b.is_visible_in_tree() or b.disabled:continue
		if caption(b)!=title and b.text!=title and not (prefix and caption(b).begins_with(title)):continue
		var parent: Node = b.get_parent()
		while parent:
			if parent is ScrollContainer:parent.ensure_control_visible(b);await layout()
			parent=parent.get_parent()
		await tap(b.get_global_rect().get_center());return true
	return false
func world(point: Vector2) -> void:
	var screen: Dictionary = g.session.CAMERA.screen_point(point.x,point.y,g.session.rect,g.session.viewport,g.session.camera)
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(Vector2(screen.x,screen.y)),"Alvo de mouse dentro da janela")
	await tap(Vector2(screen.x,screen.y))
	for i in 400:
		g.tick(0.05)
		if g.session.pending==null and g.session.state.player.get("motion")==null and (g.session.state.player.get("goal")==null or g.session.MOVE.arrived(g.session.state.player)):break
	await layout()
func object(type: String) -> Dictionary:
	return g.session.state.objects.filter(func(o):return o.type==type)[0]
func use(type: String) -> void:
	var o := object(type);await world(Vector2(o.x*40+20,o.y*40+6))
func capture(name: String) -> void:
	stages.append(name)
	if not "--capture" in OS.get_cmdline_user_args():return
	await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/playtest-zero-"+name+".png")
func broth() -> void:
	await use("fridge");check(await choose("Retirar Batata •",true),"Retira batata com mouse real")
	await use("prep");advance(2.1);check(not g.hud.slots.context[0].visible,"Ações vazias não deixam painel invisível sobre o mapa");await use("stove");await use("stove");advance(5.1)
	await use("stove");await use("kitchen");advance(2.1)
	check(g.session.state.player.hand.item=="pot","Empratamento mantém panela na mão")
	await use("stove")
func clean_table(table: Dictionary) -> void:
	await world(Vector2(table.x*40+40,table.y*40+6))
	if g.session.INTERACT.KITCHEN.DISHES.count(g.session.state,table)>0:
		if not stages.has("limpeza"):await capture("limpeza")
		var actions: Array = g.hud.slots.context[1].find_children("*","Button",true,false).filter(func(n):return n.is_visible_in_tree())
		check(actions.any(func(n):return caption(n)=="Recolher pratos sujos da mesa" and not n.disabled),"Opção de recolher habilitada na mesa suja")
		if g.session.INTERACT.KITCHEN.HYGIENE.stained(g.session.state,table):check(actions.any(func(n):return caption(n)=="Limpar mesa" and n.disabled),"Pano aguarda retirar pratos, sem confundir com atendimento")
		check(await choose("Recolher pratos sujos da mesa"),"Mesa oferece recolher pratos")
		check(g.session.state.player.hand.item=="dirtyPlate","Recolhe louça real")
		await use("sink");advance(2.1);await use("sink");await use("kitchen")
	if g.session.INTERACT.KITCHEN.HYGIENE.can_wipe(g.session.state,table):
		await world(Vector2(table.x*40+40,table.y*40+6))
		check(await choose("Limpar mesa"),"Mesa oferece limpeza separada")
		check(not g.session.INTERACT.KITCHEN.HYGIENE.stained(g.session.state,table),"Limpeza remove manchas")
func run():
	root.size=Vector2i(1280,720);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
	check(await choose("Novo jogo"),"Novo jogo pelo botão real")
	check(g.session.REFUGE.active(g.session.state),"Clique nativo inicia a campanha de verdade")
	if not g.session.REFUGE.active(g.session.state):await finish();return
	g.session.rng=func():return 0.5
	var s: Dictionary = g.session.state
	check(s.cash==200 and s.workers.is_empty(),"Playtest começa do zero com 200 e sem garçom")
	await capture("inicio")
	check(await choose("Gestão") and await choose("Cardápio"),"Cardápio pelo mouse")
	var toggles: Array = g.hud.find_children("*","CheckButton",true,false).filter(func(n):return n.is_visible_in_tree())
	check(toggles.size()==2,"Cardápio apresenta duas ofertas iniciais")
	if toggles.size()==2:await tap(toggles[1].get_global_rect().get_center())
	check(s.menu.caldoBatata and not s.menu.arrozCenoura,"Escolhe servir caldo no almoço")
	await choose("Voltar ao jogo")
	await broth()
	for visit in 3:
		var c: Variant = null
		for i in 1600:
			for candidate in s.customers:
				if candidate.state=="waiting":c=candidate;break
			if c!=null or s.ledger.sales+s.ledger.lost>=3:break
			g.tick(0.1)
		if c==null:
			check(s.ledger.sales+s.ledger.lost==3,"Todas as três chegadas tiveram resultado")
			break
		check(c!=null,"Chegada natural de cliente "+str(visit+1))
		await world(Vector2(c.x*40+20,c.y*40-12))
		check(s.player.has("noteJob") and c.state=="waiting" and s.orders.filter(func(o):return o.customer==c.id).is_empty(),"Um clique inicia a anotação sem adiantar a comanda")
		check(not g.hud.slots.context[0].visible,"Cliente não abre ícones contextuais")
		check(g.frame_data.scene.any(func(op):return op[0]=="progress" and op[1]=="note:player"),"Barra real da anotação aparece")
		if visit==0:
			g.tick(0.3);var remaining: float = s.player.noteJob.left
			await capture("anotando")
			var raw: String = g.session.SAVE.serialize(s);var loaded = g.session.SAVE.new().load_value(JSON.parse_string(raw))
			check(loaded!=null and is_equal_approx(loaded.player.noteJob.left,remaining),"Save preserva progresso parcial da anotação")
			var invalid: Dictionary = loaded.duplicate(true);invalid.player.noteJob.customer="cliente-inexistente"
			check(g.session.SAVE.serialize(invalid)==null,"Save rejeita anotação sem cliente correspondente")
			var resumed = g.session.SIM.new();resumed.service.notes_step(loaded,2);resumed.service.notes_step(loaded,2)
			check(loaded.orders.size()==1 and not loaded.player.has("noteJob"),"Anotação carregada conclui uma única vez")
			var canceled = g.session.SAVE.new().load_value(JSON.parse_string(raw))
			g.session.MOVE.go(canceled.player,{"room":"restaurant","x":18,"y":11});resumed.step(canceled,0.1)
			check(not canceled.player.has("noteJob") and canceled.orders.is_empty(),"Mover cancela anotação sem criar pedido")
			await world(Vector2(c.x*40+20,c.y*40-12))
			check(is_equal_approx(s.player.noteJob.left,remaining-0.05),"Clique repetido não reinicia a barra")
		advance(1.3)
		check(c.state=="ordered" and not s.player.has("noteJob"),"Pedido anotado ao completar a barra")
		check(not g.frame_data.scene.any(func(op):return op[0]=="food" and op[1]==c.recipe and op[2]==c.x*40+5 and op[3]==c.y*40-44),"Não duplica o pedido com comida flutuante sobre o cliente")
		check(not g.hud.slots.context[0].visible,"Pedido pronto não mostra ícones de servir ou prioridade")
		if visit==0:await capture("pedido")
		if visit>0:await broth()
		await use("kitchen");check(s.player.hand.item=="dish_caldoBatata","Prato pedido vai à mão")
		await world(Vector2(c.x*40+20,c.y*40-12))
		check(c.state=="eating","Clique único entrega o prato ao cliente correto")
		if visit==0:await capture("servido")
		var count_before: int = s.orders.size()
		await world(Vector2(c.x*40+20,c.y*40-12))
		check(s.orders.size()==count_before and g.session.pending==null,"Clique em cliente comendo não atende outra pessoa nem abre opções")
		advance(4.2)
		check(s.orders.filter(func(o):return o.customer==c.id and o.state=="paid").size()==1,"Serve e recebe pagamento sem ícone intermediário")
		var chair = g.session.BUILD.find(s.objects,c.seat);var table = g.session.BUILD.chair_table(chair,s.objects)
		print("PAGO ",visit+1," tempo=",s.time," arrival=",s.arrival," dirty=",s.dirtyTables," clientes=",s.customers.map(func(v):return [v.id,v.state,v.x,v.y]))
		await clean_table(table)
		print("ATENDIDO ",visit+1," tempo=",s.time," clientes=",s.customers.map(func(v):return [v.id,v.state,v.x,v.y])," perdidos=",s.ledger.lost)
	check(s.ledger.sales==3 and s.ledger.lost==0 and s.experience.visits.size()==3,"Cadência permite servir e limpar as três chegadas sem perdas")
	check(s.experience.visits.filter(func(v):return v.outcome=="abandoned").all(func(v):return v.get("arrivalIssue")=="dirtySeat"),"A saída é causada pela regra aprovada de sujeira, não por falha de anotação")
	for table in s.objects:
		if table.type=="table" and g.session.INTERACT.KITCHEN.HYGIENE.can_wipe(s,table):await clean_table(table)
	while s.clock.minute<900:g.tick(0.1)
	await capture("almoco")
	check(s.equipment.plate==8 and s.equipment.pot==2 and g.session.SAVE.serialize(s)!=null,"Ciclo conserva pratos, panelas, ingredientes e refeições")
	var portal: Dictionary = g.session.MOVE.PORTALS.restaurant[0]
	await world(Vector2(portal.x*40+20,portal.y*40+20))
	check(s.player.room=="street","Sai pela porta usando o mapa")
	var seller: Dictionary = s.residents.filter(func(v):return v.id=="beto")[0]
	await world(Vector2(seller.x*40+20,seller.y*40+6))
	check(g.session.modal=="market","Visita o mercador pela janela real")
	var before: float = s.cash
	check(await choose("Comprar 5 Batata · $10") and s.cash==before-10 and s.market.stock.batata==7,"Compra reposição pelo mouse com dinheiro ganho no almoço")
	await capture("mercador");await choose("Voltar ao jogo")
	check(await choose("Opções") and await choose("Salvar e carregar") and await choose("Salvar jogo"),"Salva progresso pelo mouse")
	var cash: float = s.cash
	check(await choose("Carregar jogo") and g.session.state.cash==cash and g.session.state.ledger.sales==3,"Carrega o almoço sem perder pagamentos")
	await choose("Voltar ao jogo")
	print("ETAPAS PLAYTEST: ",stages)
	await finish()
