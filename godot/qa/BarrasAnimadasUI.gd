extends "res://qa/BaseInterfaceNativa.gd"
const BAR = preload("res://interface/BarraAnimada.gd")
const ART = preload("res://interface/ArteBarras.gd")
const DETAILS = preload("res://mundo/Tracos.gd")
func run():
	await start_game()
	var bar = BAR.new()
	bar.max_value=1;bar.value=0.83;g.hud.add_child(bar);bar.set_process(false)
	check(is_equal_approx(bar.value,0.83) and is_equal_approx(bar.displayed,0.83),"Progresso fracionário preservado ao criar barra")
	bar.value=0.2;bar._process(0.05);bar.set_process(false)
	check(bar.displayed>bar.value and bar.displayed<0.83,"Preenchimento diminui suavemente sem alterar valor real")
	bar._process(1);bar.set_process(false)
	check(is_equal_approx(bar.displayed,0.2),"Animação alcança o valor real")
	bar.value=1;bar._process(0.05);bar.set_process(false)
	check(bar.displayed>0.2 and bar.displayed<1,"Preenchimento também cresce suavemente")
	check(ART.color_for("patience",0.8)=="green" and ART.color_for("patience",0.5)=="yellow" and ART.color_for("patience",0.25)=="red","Paciência usa três cores nas faixas corretas")
	var details = DETAILS.new();g.add_child(details)
	details.set_commands([["progress","old",0,0,44,8,0.9,"blue"]])
	details.set_commands([["progress","old",0,0,44,8,0.1,"blue"]]);details._process(0.05)
	check(details.progress_values.old>0.1 and details.progress_values.old<0.9,"Barras no mundo interpolam por identidade")
	details.set_commands([["progress","new",0,0,44,8,0.2,"patience"]])
	check(details.progress_values.size()==1 and is_equal_approx(details.progress_values.new,0.2),"Nova tarefa não herda valor e cache descarta tarefas antigas")
	details.set_commands([])
	check(details.progress_values.is_empty() and not details.is_processing(),"Sem barras, desenho não mantém animação ativa")
	bar.queue_free();details.queue_free()
	var s: Dictionary = g.session.state
	g.session.ADMIN.test_clock(s,660);g.tick(0)
	var sim = g.session.simulation
	sim.service.random_source=func():return 0.5
	check(sim.spawn(s),"Cliente entra para teste de paciência")
	var c: Dictionary = s.customers[0]
	c.state="waiting";sim.service.begin(s,c,"service")
	var packet: Dictionary = g.session.step(0,[])
	var patient_bar := false
	for op in packet.scene:
		if op[0]=="progress" and str(op[1]).begins_with("patience:"):patient_bar=true
	check(patient_bar,"Cliente aguardando mostra paciência no cenário")
	g.hud.sync(packet);await layout()
	check(g.hud.order_bars.size()==1 and g.hud.order_bars[0].value>0,"Cliente tem barra correspondente no painel de pedidos")
	var id: int = g.hud.order_bars[0].get_instance_id()
	for child in packet.ui.ordersHud.children[0].children:
		if child.tag=="progress":child.value=0.91
	g.hud.sync(packet)
	check(g.hud.order_bars[0].get_instance_id()==id and is_equal_approx(g.hud.order_bars[0].value,0.91),"Painel reaproveita controle e atualiza frações de paciência")
	# Screenshot gallery uses actual Controls and the same renderer as the world.
	if "--capture" in OS.get_cmdline_user_args():
		var chair = g.session.BUILD.find(s.objects,c.seat)
		c.merge({"x":chair.x,"y":chair.y,"motion":null,"goal":null},true)
		g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-hud-jogo.png")
		g.get_node("Mapa").hide();g.hud.hide()
		var backdrop := ColorRect.new();backdrop.color=Color("26382f");backdrop.size=Vector2(960,700);root.add_child(backdrop)
		var rows := VBoxContainer.new();rows.position=Vector2(70,35);rows.size.x=800;rows.add_theme_constant_override("separation",12);backdrop.add_child(rows)
		for entry in [["Tarefa iniciando",0.15,"blue"],["Cozinhando",0.65,"blue"],["Anotando pedido",0.85,"blue"],["Cliente paciente",0.85,"patience"],["Cliente impaciente",0.45,"patience"],["Paciência acabando",0.15,"patience"],["Ponto ideal",1.0,"green"],["Risco de queimar",0.7,"red"],["Vazia",0.0,"blue"]]:
			var text := Label.new();text.text=entry[0];rows.add_child(text)
			var sample=BAR.new();sample.max_value=1;sample.value=entry[1];sample.kind=entry[2];sample.custom_minimum_size.y=24;rows.add_child(sample)
		await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-barras.png")
		backdrop.queue_free()
	await finish()
