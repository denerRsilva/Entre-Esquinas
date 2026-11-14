extends "res://qa/BaseNativa.gd"
func run():
	var tests = load("res://qa/referencia-migracao/cenas.json").data
	for test in tests:
		var actual = preload("res://simulacao/nativa/Cena.gd").new().draw(test.state.duplicate(true),test.ui)
		check(equivalent(actual,test.expected),"Composição visual nativa")
	print("CENAS: ",tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
