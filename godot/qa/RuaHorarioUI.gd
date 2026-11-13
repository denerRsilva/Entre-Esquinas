extends "res://qa/CozinhaUI.gd"
func key(code:Key,pressed:bool):
	var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed;root.push_input(event);g.tick(0)
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	await layout()
	check(await button("Começar na taverna"),"Iniciar cenário para testar clientes")
	await layout()
	check(await button("Opções"),"Abrir Opções")
	await layout()
	check(await button("Testes"),"Abrir aba Testes")
	await layout()
	var clock:OptionButton
	for option in g.hud.find_children("*","OptionButton",true,false):
		if option.tooltip_text=="Horário de teste":clock=option;break
	check(clock!=null,"Seletor de horário existe na aba Testes")
	if clock:
		for i in clock.item_count:
			if clock.get_item_text(i)=="11:00":clock.select(i);clock.item_selected.emit(i);break
		g.tick(0);await layout()
	check(await button("Avançar horário"),"Avançar pelo botão nativo")
	check(js("R.clockText(state)")=="11:00","Relógio avançou exatamente para 11:00")
	check(js("state.time")=="0","Salto não simulou horas de espera")
	await capture("horario")
	check(await button("Voltar ao jogo"),"Retornar ao restaurante")
	# Isolate the exit interaction from the furnished kitchen spawn.
	js("Object.assign(state.player,{x:7,y:13,motion:null,goal:null,settled:null})")
	g.tick(0)
	key(KEY_S,true)
	for i in 20:g.tick(1.0/60.0)
	key(KEY_S,false);await layout()
	check(js("state.player.room")=="street","Sair pela porta com movimento livre")
	check(g.palco.get_node("Rua").visible and g.palco.get_node("Rua/Detalhes").is_visible_in_tree(),"Rua e fachada renderizadas")
	check(await button("Abrir restaurante"),"Opção de abrir disponível na rua")
	for i in 12:g.tick(.08)
	check(js("state.open")=="true" and js("state.player.room")=="street","Abrir serviço pelo lado de fora")
	await layout();await capture("rua")
	for i in 110:g.tick(.08)
	check(int(js("state.customers.length"))>0,"Clientes chegam com o restaurante aberto pela rua")
	check(js("R.valid(state)")=="true","Estado válido com clientes e jogador na rua")
	await layout()
	check(await button("Encerrar restaurante"),"Encerrar entrada pelo lado de fora")
	check(js("state.closing")=="true","Clientes presentes são preservados no fechamento")
	var portal=JSON.parse_string(js("JSON.stringify(screenPoint(500,220))"))
	click_at(Vector2(portal.x,portal.y))
	for i in 100:
		g.tick(.08)
		if js("state.player.room")=="restaurant":break
	check(js("state.player.room")=="restaurant","Entrar pela fachada com clique")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
