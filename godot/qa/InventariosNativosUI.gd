extends "res://qa/MaosUI.gd"
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout();await button("Começar na taverna");await layout()
	await click_object("fridge")
	check(g.frame_data.liveInventory,"Inventário nativo não pausa o tempo")
	check(js("$('panel').children.length")=="0","Conteúdo do inventário não é construído no modelo HTML")
	var path := ""
	for key in g.session.inventory_ui.actions:
		if ":retirar:" in key and key.ends_with(":2"):path=key
	check(not path.is_empty(),"Botão de retirada registrado em GDScript")
	check(js("Host.widgets.has("+JSON.stringify(path)+")")=="false","Retirada não depende do registro DOM")
	check(await take_storage("Retirar Frango • espaço 3"),"Retirar pelo botão nativo")
	check(js("state.player.hand.item==='frango'")=="true","Ingrediente nas mãos")
	g.queue_command({"kind":"widget","path":path});g.tick(0);await layout()
	check(js("state.player.hand.n===1")=="true","Evento antigo após fechar o menu não duplica item")
	await click_object("fridge")
	check(not g.session.inventory_ui.actions.has(path),"Retirada desabilitada não possui ação ativa")
	g.queue_command({"kind":"widget","path":path});g.tick(0);await layout()
	check(js("state.player.hand.n===1")=="true","Evento de controle desabilitado é ignorado")
	check(await button("Guardar Frango"),"Guardar pelo botão nativo")
	check(js("!state.player.hand&&R.objectCount(state.objects.find(o=>o.type==='fridge'),'frango')===30")=="true","Quantidade original restaurada")
	check(js("R.valid(state)&&!!R.migrateSave(state)")=="true","Estado e salvamento preservados")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
