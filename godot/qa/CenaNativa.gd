extends "res://qa/BaseNativa.gd"
func run():
	var tests = load("res://qa/referencia-migracao/cenas.json").data
	for test in tests:
		var actual = preload("res://simulacao/nativa/Cena.gd").new().draw(test.state.duplicate(true),test.ui)
		# Neighbor mask is new native rendering metadata, absent in migration snapshots.
		for command in actual:
			if command[0]=="furniture" and str(command[1]).begins_with("counter") and command.size()==9:command.pop_back()
		check(equivalent(actual,test.expected),"Composição visual nativa")
	print("CENAS: ",tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
