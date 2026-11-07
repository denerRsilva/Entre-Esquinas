extends SceneTree
## Native mouse input: catches HUD overlays that JS-only tests cannot detect.
var g
var failures := 0
func _initialize(): call_deferred("run")
func js(code: String) -> String: return RestauranteVM.executar(code)
func check(ok: bool, message: String):
	print("OK  " if ok else "FALHOU  ",message)
	if not ok: failures += 1
func layout():
	for i in 8: await process_frame
func capture(name: String):
	if "--capturas" not in OS.get_cmdline_user_args(): return
	await layout()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/esquinas-ui-"+name+".png")
func click_at(point: Vector2):
	var motion := InputEventMouseMotion.new()
	motion.position=point;motion.global_position=point;root.push_input(motion)
	var mouse := InputEventMouseButton.new()
	mouse.position=point;mouse.global_position=point;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true
	root.push_input(mouse)
	mouse=mouse.duplicate();mouse.pressed=false;root.push_input(mouse)
	g.tick(0)
func button(text: String) -> bool:
	for b in g.hud.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and b.text==text and not b.disabled:
			var ancestor: Node = b.get_parent()
			while ancestor:
				if ancestor is ScrollContainer:
					ancestor.ensure_control_visible(b)
					await layout()
				ancestor=ancestor.get_parent()
			var point: Vector2 = b.get_global_rect().get_center()
			if not root.get_visible_rect().has_point(point): return false
			click_at(point)
			return true
	return false
func walk_to_selected():
	for i in 140:
		g.tick(.08)
		if js("!state.player.motion && !state.player.goal")=="true": break
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	await layout()
	check(await button("Começar mobiliado (teste)"),"Começar com clique nativo")
	await layout()
	check(not JSON.stringify(g.frame_data.ui.actions).contains("fullscreenBtn"),"Tela cheia fora da barra do jogo")
	click_at(Vector2(420,560))
	check(js("state.player.goal.x===10 && state.player.goal.y===12")=="true","Clique no chão mantém destino e rota do HTML")
	walk_to_selected()
	var x_before := float(js("R.position(state.player).x"))
	var key := InputEventKey.new()
	key.keycode=KEY_A;key.pressed=true;root.push_input(key)
	g.tick(.3)
	key=key.duplicate();key.pressed=false;root.push_input(key);g.tick(.3)
	check(float(js("R.position(state.player).x"))<x_before,"WASD movimenta o jogador continuamente")
	click_at(Vector2(680,150))
	check(js("state.objects.find(o=>o.id===selectedObject)?.type")=="stove","Clique no fogão atravessa HUD passiva")
	walk_to_selected()
	await layout()
	await capture("fogao")
	check(await button("Receitas"),"Abrir receitas pelo botão nativo do fogão")
	await layout()
	await capture("receitas")
	check(await button("Cozinhar"),"Iniciar receita por clique nativo")
	check(js("!!state.cooking")=="true","Fogão iniciou o cozimento")
	for i in 36: g.tick(.25)
	await layout()
	check(await button("Retirar panela"),"Retirar panela pronta pelo botão nativo")
	click_at(Vector2(680,272))
	check(js("state.objects.find(o=>o.id===selectedObject)?.type")=="prep","Clique na bancada seleciona móvel")
	walk_to_selected()
	await layout()
	await capture("bancada")
	check(await button("Empratar"),"Iniciar empratamento por clique nativo")
	for i in 12: g.tick(.25)
	await layout()
	check(js("R.readyCount(state.objects.find(o=>o.type==='prep'))")=="4","Bancada produziu quatro pratos")
	check(await button("Retirar prato"),"Retirar prato pelo controle nativo")
	check(js("R.readyCount(state.objects.find(o=>o.type==='prep'))")=="3","Prato transferido para mochila")
	check(js("R.valid(state)")=="true","Estado e recursos válidos após cozinha")
	await layout()
	check(await button("Opções"),"Abrir opções")
	await layout()
	check(g.frame_data.modal=="management" and JSON.stringify(g.frame_data.ui.modal).contains("fullscreenBtn"),"Tela cheia disponível em Opções → Câmera")
	await capture("camera")
	check(await button("Alternar tela cheia"),"Controle de tela cheia aceita clique nativo")
	if DisplayServer.get_name()!="headless":
		await layout()
		check(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN,"Janela entrou em tela cheia")
		check(await button("Alternar tela cheia"),"Retornar ao modo janela")
		await layout()
		check(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_WINDOWED,"Janela retornou ao modo normal")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame
	quit(1 if failures else 0)
