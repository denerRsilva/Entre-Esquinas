extends SceneTree
var failures := 0
func check(ok: bool,label: String) -> void:
	print("OK " if ok else "FALHOU ",label)
	if not ok:failures+=1
func _initialize():
	var session = preload("res://simulacao/nativa/SessaoCompleta.gd").new()
	session.initialize({})
	check(session.step(0,[]).modal=="welcome","Boas-vindas nativas")
	session.root_action("furnished")
	check(session.state.objects.size()==22,"Taverna mobiliada")
	var packet: Dictionary = session.step(0.1,[])
	check(packet.modal=="" and packet.scene.size()>0 and packet.ui.has("hud"),"Cena e HUD nativos")
	session.open_dialog("options");session.tab="save";session.generation+=1;session.step(0,[])
	session.save_game();var old_cash: float = session.state.cash;session.state.cash=1;session.load_game()
	check(session.state.cash==old_cash,"Salvar e carregar nativamente")
	session.close_dialog();session.enter_construction();session.step(0,[])
	check(session.construction and session.drawer,"Catálogo automático")
	session.root_action("exitConstruction");session.key({"key":"d","down":true});var before: float = session.state.player.x
	for i in 10:session.step(0.05,[])
	check(session.MOVE.position(session.state.player).x>before,"Movimento por teclado nativo")
	session.key({"key":"d","down":false});check(session.SAVE.VALIDATOR.valid(session.state,0),"Estado final válido")
	print("FALHAS: ",failures);quit(1 if failures else 0)
