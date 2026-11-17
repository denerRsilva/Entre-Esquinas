extends SceneTree
var g
var failures := 0
func _initialize():call_deferred("run")
func layout():
	for i in 8:await process_frame
func check(ok: bool,message: String):
	print("OK " if ok else "FALHOU ",message)
	if not ok:failures+=1
func press(title: String) -> bool:
	await layout()
	for control in g.hud.find_children("*","Button",true,false):
		if control.is_visible_in_tree() and not control.disabled and (control.text==title or control.tooltip_text==title):
			var parent = control.get_parent()
			while parent:
				if parent is ScrollContainer:parent.ensure_control_visible(control);await layout()
				parent=parent.get_parent()
			control.emit_signal("pressed");g.tick(0);await layout();return true
	return false
func run():
	root.size=Vector2i(960,700);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
	check(g.active and g.frame_data.modal=="welcome","Aplicação inicia sem avaliador de scripts")
	check(await press("Novo jogo") and g.session.state.objects.size()==22,"Partida mobiliada")
	check(await press("Gestão"),"Gestão nativa")
	for entry in [["Turnos","shifts"],["Equipe","team"],["Fechamento","finance"],["Clientes","customers"],["Calendário","calendar"],["Reputação","reputation"]]:check(await press(entry[0]) and g.session.tab==entry[1],"Aba "+entry[0])
	check(await press("Modo construção") and g.session.construction and g.session.drawer,"Construção e catálogo automático")
	check(await press("Voltar ao jogo") and not g.session.construction,"Sair da construção")
	check(await press("Livro de receitas") and g.frame_data.modal=="management","Livro nativo")
	check(await press("Voltar ao jogo"),"Fechar livro")
	check(await press("Opções"),"Opções nativas")
	for entry in [["Câmera","camera"],["Testes","test"],["Primeiros passos","guide"],["Salvar e carregar","save"]]:check(await press(entry[0]) and g.session.tab==entry[1],"Aba "+entry[0])
	var cash: float = g.session.state.cash
	check(await press("Salvar jogo"),"Salvar pelo controle Godot")
	g.session.state.cash=1;check(await press("Carregar jogo") and g.session.state.cash==cash,"Carregar pelo controle Godot")
	check(g.session.SAVE.VALIDATOR.valid(g.session.state),"Partida válida após interface completa")
	print("FALHAS: ",failures);g.queue_free();await process_frame;quit(1 if failures else 0)
