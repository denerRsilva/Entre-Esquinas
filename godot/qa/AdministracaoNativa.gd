extends "res://qa/BaseNativa.gd"
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var tests = load("res://qa/referencia-migracao/administracao.json").data
	for test in tests:
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":"administracao","args":[test.operation,test.input,test.params]},"",true,true)))
		check(equivalent(actual,test.expected),test.operation)
	for test in load("res://qa/referencia-migracao/administracao-dias.json").data:
		var state: Dictionary = test.input.duplicate(true);var simulation = preload("res://simulacao/nativa/Simulacao.gd").new();simulation.service.random_source=func():return 0.5
		simulation.step(state,test.dt);check(equivalent(state,test.expected),"Dois dias completos")
	print("CASOS: ",tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
