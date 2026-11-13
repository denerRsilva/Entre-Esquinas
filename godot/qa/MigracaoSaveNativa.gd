extends "res://qa/UIBase.gd"
func run():
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout()
	var phases = load("res://qa/referencia-migracao/migracao-fases.json").data
	phases+=load("res://qa/referencia-migracao/estado-cozinha.json").data
	for test in phases:
		var request := JSON.stringify({"name":test.name,"args":test.args})
		var actual = JSON.parse_string(js("NativeRule("+JSON.stringify(request)+")"))
		check(actual==test.expected,"Fase nativa "+test.name)
	var tests = load("res://qa/referencia-migracao/migracao-saves.json").data
	for test in tests:
		js("globalThis.migrationInput="+JSON.stringify(test.input))
		var before := js("JSON.stringify(migrationInput)")
		var actual = JSON.parse_string(js("JSON.stringify(R.migrateSave(migrationInput))"))
		check(actual==test.expected,test.label)
		check(js("JSON.stringify(migrationInput)")==before,"Entrada preservada")
	print("CASOS: ",tests.size()+phases.size()," FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
