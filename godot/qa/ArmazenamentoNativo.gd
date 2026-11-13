extends "res://qa/UIBase.gd"
func run():
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout()
	var tests = load("res://qa/referencia-migracao/armazenamento.json").data
	tests+=load("res://qa/referencia-migracao/receitas-nativas.json").data
	for test in tests:
		var request := JSON.stringify({"name":test.name,"args":test.args})
		var actual = JSON.parse_string(js("NativeRule("+JSON.stringify(request)+")"))
		# Godot JSON writes fewer final decimal digits than JavaScript.
		# Only the visual heat progress permits a 1e-12 serialization tolerance.
		if test.name=="heatState" and actual is Dictionary and actual.has("value"):
			if absf(float(actual.value)-float(test.expected.value))<=1e-12:actual.value=test.expected.value
		if actual!=test.expected:
			check(false,test.name+" "+JSON.stringify(test.args))
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
