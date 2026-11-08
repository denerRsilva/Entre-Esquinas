extends "res://qa/CozinhaUI.gd"
func select_stove():
	var point=JSON.parse_string(js("(()=>{const o=state.objects.find(o=>o.type==='stove');return JSON.stringify(screenPoint(o.x*40+20,o.y*40+20))})()"))
	click_at(Vector2(point.x,point.y));await layout()
func finish():
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout();check(await button("Começar mobiliado (teste)"),"Iniciar mobiliado")
	await layout();check(await button("Gestão"),"Abrir gestão")
	await layout();check(await button("Modo construção"),"Entrar na construção")
	var before=js("JSON.stringify([state.cash,state.objects])")
	await select_stove()
	check(js("building?.type==='stove'")=="true","Selecionar fogão para mover")
	var controls=g.hud.slots.build[1].find_children("*","Button",true,false)
	var horizontal:bool=controls.size()==4
	var y:float=controls[0].get_global_rect().position.y
	for b in controls:
		if absf(b.get_global_rect().position.y-y)>1.0:horizontal=false
		if not root.get_visible_rect().encloses(b.get_global_rect()):horizontal=false
	check(horizontal,"Quatro botões em uma linha horizontal, dentro da tela")
	check(g.hud.slots.build[1].find_children("*","Label",true,false).is_empty(),"Painel mostra somente os textos das opções")
	# A prévia não tem ID de objeto; o fogão real tem ID e continua no cenário.
	var point=JSON.parse_string(js("JSON.stringify(screenPoint(18*40+20,3*40+20))"))
	click_at(Vector2(point.x,point.y));await layout()
	check(g.active,"Prévia do fogão não interrompe simulação")
	if not g.active:await finish();return
	check(await button("Girar ↻"),"Girar fogão com prévia ativa")
	check(js("building.rot===1")=="true","Rotação aplicada")
	check(await button("Cancelar"),"Cancelar pelo mouse responde")
	check(js("!building&&constructionMode")=="true","Cancelar sai da colocação e mantém construção")
	check(js("JSON.stringify([state.cash,state.objects])")==before,"Cancelar preserva fogão, panela e caixa")
	await select_stove()
	var target=JSON.parse_string(js("(()=>{for(let y=1;y<9;y++)for(let x=15;x<23;x++)if(!previewError({...building,room:'restaurant',x,y}))return JSON.stringify({x,y});return 'null'})()"))
	check(target is Dictionary,"Há posição válida para mover")
	if target is Dictionary:
		point=JSON.parse_string(js("JSON.stringify(screenPoint("+str(target.x*40+20)+","+str(target.y*40+20)+"))"))
		click_at(Vector2(point.x,point.y));await layout()
		check(await button("Confirmar posição"),"Confirmar fogão responde")
		check(js("!building&&R.valid(state)")=="true","Confirmação mantém estado válido")
	await select_stove()
	check(await button("Guardar e reembolsar"),"Botão de guardar responde")
	check(js("Boolean(building)&&state.objects.some(o=>o.type==='stove'&&o.pan==='pot')")=="true","Panela instalada impede guardar sem perder fogão")
	await layout()
	check(await button("Cancelar"),"Cancelar funciona após tentativa recusada")
	await layout();check(await button("Construção"),"Catálogo continua funcionando")
	await layout();check(await button("Voltar ao jogo"),"Sair da construção")
	check(g.active and js("R.valid(state)")=="true","Jogo continua ativo")
	await finish()
