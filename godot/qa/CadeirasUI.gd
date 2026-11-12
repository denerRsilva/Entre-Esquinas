extends "res://qa/CozinhaUI.gd"
func disabled(label:String) -> bool:
	for b in g.hud.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and b.text==label:return b.disabled
	return false
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout();check(await button("Começar na taverna"),"Cenário mobiliado")
	check(js("R.seats(state).length===12&&state.objects.filter(o=>o.type==='table').every(t=>state.objects.filter(c=>c.type==='chair'&&R.seatTable(state,c)?.id===t.id).length===4)")=="true","Três mesas com quatro cadeiras válidas")
	await layout();check(await button("Gestão"),"Gestão")
	await layout();check(await button("Modo construção"),"Construção")
	js("globalThis.tableTest=state.objects.find(o=>o.type==='table');globalThis.chairTest=state.objects.find(o=>o.type==='chair'&&R.seatTable(state,o)?.id===tableTest.id);beginBuild('chair',chairTest.id);building.rot=1;hover={x:tableTest.x-1,y:tableTest.y};updatePreview()")
	g.tick(0);await layout()
	check(disabled("Confirmar posição"),"Prévia na ponta bloqueia confirmação")
	js("building.rot=0;hover={x:tableTest.x,y:tableTest.y-1};updatePreview()")
	g.tick(0);await layout()
	check(disabled("Confirmar posição"),"Cadeira virada para fora bloqueia confirmação")
	js("building.rot=chairTest.rot;hover={x:chairTest.x,y:chairTest.y};updatePreview()")
	g.tick(0);await layout()
	check(not disabled("Confirmar posição"),"Lado comprido com orientação correta permite confirmar")
	check(await button("Confirmar posição"),"Confirmar cadeira válida pelo mouse")
	check(js("R.valid(state)&&R.seats(state).length===12")=="true","Estado e assentos preservados")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
