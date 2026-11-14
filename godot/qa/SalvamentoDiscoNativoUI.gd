extends "res://qa/BaseInterfaceNativa.gd"
func run():
	await start_game();g.session.open_dialog("options");g.session.tab="save";g.session.generation+=1;g.tick(0)
	var cash: float = g.session.state.cash
	check(await press("Salvar restaurante") and g.values.has("entre-restaurante-12"),"Gravação pelo botão nativo")
	g.session.state.cash=1;check(await press("Carregar restaurante") and g.session.state.cash==cash,"Restauração pelo botão nativo")
	var previous: String = g.values["entre-restaurante-12"]
	var bad := FileAccess.open("user://invalid-import.json",FileAccess.WRITE);bad.store_string("{invalid");bad.close()
	g.import_save("user://invalid-import.json")
	check(g.session.state.cash==cash and g.values["entre-restaurante-12"]==previous,"Importação corrompida preserva partida e arquivo")
	var valid: String = g.session.SAVE.serialize(g.session.state)
	var incoming := FileAccess.open("user://valid-import.json",FileAccess.WRITE);incoming.store_string(valid);incoming.close();g.import_save("user://valid-import.json")
	check(g.values["entre-restaurante-12"]==valid and g.session.values["entre-restaurante-12"]==valid,"Importação válida disponível ao carregador")
	check(g.persist(g.values),"Gravação repetida gera backup")
	var corrupted := FileAccess.open(g.STORE,FileAccess.WRITE);corrupted.store_string("{invalid");corrupted.close()
	check(not g.read_values().is_empty(),"Recuperação do backup")
	check(g.persist(g.values),"Gravação após recuperação")
	check(g.session.SAVE.VALIDATOR.valid(g.session.state),"Partida válida após erros de I/O")
	await finish()
