extends "res://qa/UIBase.gd"
func advance(seconds:float):
	for i in int(seconds*20):g.tick(.05)
func click_object(type:String):
	var point=JSON.parse_string(js("(()=>{const o=state.objects.find(o=>o.type==='"+type+"');return JSON.stringify(screenPoint(o.x*40+20,o.y*40+20))})()"))
	click_at(Vector2(point.x,point.y));advance(6);await layout()
func take_storage(label:String) -> bool:
	for b in g.hud.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and b.tooltip_text==label and not b.disabled:
			click_at(b.get_global_rect().get_center());await layout();return true
	return false
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout();check(await button("Começar mobiliado (teste)"),"Começar mobiliado")
	check(not g.hud.slots.has("hotbar") and not g.frame_data.ui.has("hotbar"),"Barra e espaço de inventário removidos")
	check(js("state.inventory.length===0&&!state.player.hand&&state.equipment.pot===4")=="true","Mãos vazias; uma panela no fogão e três na estante")
	check(js("['arroz','legumes','frango'].every(f=>R.objectCount(state.objects.find(o=>o.type==='fridge'),f)===30)")=="true","Ingredientes começam na geladeira")
	await click_object("fridge")
	check(g.frame_data.modal=="management","Um clique aproxima e abre geladeira")
	var before=float(js("state.time"));advance(1)
	check(float(js("state.time"))>before,"Tempo continua no inventário da geladeira")
	await layout();check(await take_storage("Retirar Frango • espaço 3"),"Retirar frango pelo inventário real")
	check(js("state.player.hand?.item==='frango'&&state.player.hand.n===1")=="true","Uma unidade de frango nas mãos")
	await click_object("prep")
	check(js("state.player.hand?.item==='frango_cut'")=="true","Um clique na mesa corta frango")
	await click_object("stove")
	check(js("!state.player.hand&&state.objects.find(o=>o.type==='stove').ingredients[0].item==='frango_cut'")=="true","Adicionar frango cortado da mão à panela")
	await click_object("fridge");await layout()
	check(await take_storage("Retirar Arroz • espaço 1"),"Retirar arroz da geladeira")
	await click_object("stove")
	check(js("R.recognizedRecipe(state.objects.find(o=>o.type==='stove'))==='frangoArroz'")=="true","Receita reconhecida")
	check(await button("Cozinhar"),"Cozinhar pelo mouse");advance(8.1);await layout()
	check(await button("Retirar panela"),"Retirar panela nas mãos")
	await click_object("kitchen")
	check(js("!state.player.hand&&state.objects.find(o=>o.type==='kitchen').support?.item==='pot_frangoArroz_1'")=="true","Panela apoiada na mesa de cozinha")
	check(await button("Empratar uma porção"),"Empratar com pratos iniciais");advance(2.1);await layout()
	check(await button("Pegar prato nas mãos"),"Pegar prato pronto")
	check(js("state.player.hand?.item==='dish_frangoArroz'&&R.valid(state)&&Boolean(R.migrateSave(state))")=="true","Mãos, itens e save válidos")
	js("enterConstruction()");g.tick(0);before=float(js("state.time"));advance(1)
	check(float(js("state.time"))==before,"Construção continua pausando")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
