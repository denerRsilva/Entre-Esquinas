extends SceneTree
var g
var failures := 0
func _initialize(): call_deferred("run")
func js(code: String) -> String: return RestauranteVM.executar(code)
func check(ok: bool, message: String):
	print("OK " if ok else "FALHOU ",message)
	if not ok: failures += 1
func advance(seconds: float):
	for i in int(seconds*20): g.tick(0.05)
func press(label: String) -> bool:
	for button in g.hud.find_children("*","Button",true,false):
		if button.is_visible_in_tree() and (button.text==label or button.tooltip_text==label) and not button.disabled:
			button.pressed.emit(); g.tick(0); return true
	return false
func run():
	g=load("res://mundo/Restaurante.tscn").instantiate(); root.add_child(g); g.set_process(false)
	await process_frame
	check(g.active,"Sessão Godot iniciou")
	check(press("Começar mobiliado (teste)"),"Cenário equipado")
	js("state.selectedSlot=state.inventory.findIndex(p=>p?.item==='legumes');const cutTable=state.objects.find(o=>o.type==='prep');queuePhysical(cutTable,'chop')")
	advance(12)
	check(js("R.inventoryCount(state,'legumes_cut')===1")=="true","Um clique aproxima, corta e guarda resultado")
	js("const stove=state.objects.find(o=>o.type==='stove');state.selectedSlot=state.inventory.findIndex(p=>p?.item==='legumes_cut');queuePhysical(stove,'add')")
	advance(5)
	js("state.selectedSlot=state.inventory.findIndex(p=>p?.item==='arroz');queuePhysical(stove,'add')")
	advance(1)
	check(press("Cozinhar"),"Ícone contextual inicia receita sem janela")
	advance(6.1)
	check(press("Retirar panela"),"Retirada direta")
	check(js("state.player.hand?.item==='pot_arrozLegumes_1'")=="true","Panela ocupa as mãos")
	js("const kitchen=state.objects.find(o=>o.type==='kitchen');queuePhysical(kitchen,'support')")
	advance(6)
	check(press("Empratar uma porção"),"Empratar sem talher exigido")
	advance(2.1)
	check(press("Pegar prato nas mãos"),"Prato visível e retirado individualmente")
	check(js("R.valid(state)&&state.player.hand?.item==='dish_arrozLegumes'")=="true","Conservação após ciclo nativo")
	check(js("Boolean(R.migrateSave(state))")=="true","Salvar/carregar conserva mãos e mesa")
	js("const st=state.objects.find(o=>o.type==='fridge');R.goObject(state,state.player,st)")
	advance(5)
	js("openObjectInventory(state.objects.find(o=>o.type==='fridge').id)")
	var before=js("state.time")
	advance(1)
	check(float(js("state.time"))>float(before),"Tempo avança no inventário de armazenamento")
	js("$('management').close();enterConstruction()")
	before=js("state.time");advance(1)
	check(js("state.time")==before,"Construção pausa simulação")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
