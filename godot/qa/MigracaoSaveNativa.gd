extends "res://qa/BaseNativa.gd"
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var phases = load("res://qa/referencia-migracao/migracao-fases.json").data;phases+=load("res://qa/referencia-migracao/estado-cozinha.json").data
	for test in phases:
		var expected: Variant = test.expected
		if test.name=="validKitchen":
			for object in test.args[0].objects:
				if object.type=="kitchen" and (object.get("plates",0) is int or object.get("plates",0) is float) and (object.plates>20 or preload("res://simulacao/nativa/Armazenamento.gd").ready_count(object)>4):expected=false
		check(equivalent(JSON.parse_string(rules.execute(JSON.stringify({"name":test.name,"args":test.args},"",true,true))),expected),test.name)
	var tests = load("res://qa/referencia-migracao/migracao-saves.json").data
	for test in tests:
		var before: Dictionary = test.input.duplicate(true) if test.input is Dictionary else {};var draws: Array = [];var actual: Variant = null
		while true:
			var result = preload("res://simulacao/nativa/Salvamentos.gd").new().convert(test.input,draws)
			if not result.get("needsRandom",false):actual=result.value;break
			draws.append(0.5)
		if test.has("draws"):check(draws.size()==test.draws,"Sorteios preservados")
		check(equivalent(actual,test.expected),test.label)
		if test.input is Dictionary:check(equivalent(test.input,before),"Entrada preservada")
	print("CASOS: ",tests.size()+phases.size()," FALHAS: ",failures);quit(1 if failures else 0)
