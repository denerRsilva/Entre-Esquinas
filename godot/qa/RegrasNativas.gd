extends "res://qa/UIBase.gd"
func run():
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout()
	var tests = load("res://qa/referencia-migracao/regras-nativas.json").data
	tests+=load("res://qa/referencia-migracao/rotas-nativas.json").data
	for test in tests:
		var request := JSON.stringify({"name":test.name,"args":test.args})
		var actual = JSON.parse_string(js("NativeRule("+JSON.stringify(request)+")"))
		if actual!=test.expected:
			check(false,test.name+" "+JSON.stringify(test.args))
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
