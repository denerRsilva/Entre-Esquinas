extends "res://qa/CozinhaNativa.gd"
func run():
	var fixtures = load("res://qa/referencia-migracao/interacoes.json").data
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var count := 0
	for test in fixtures.cases:
		var state := patched(fixtures.base,test.input)
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":"interacoes","args":[test.operation,state,test.params,test.context]},"",true,true)))
		actual.velocity=null if actual.clearInput else test.velocity
		actual.erase("clearInput")
		var expected: Dictionary = test.expected.duplicate(true)
		expected.state=patched(fixtures.base,expected.patch);expected.erase("patch")
		count+=1
		if not equivalent(actual,expected):
			check(false,test.operation+" "+JSON.stringify(test.params)+" caso "+str(count))
			FileAccess.open("/tmp/interaction-actual.json",FileAccess.WRITE).store_string(JSON.stringify(actual))
			FileAccess.open("/tmp/interaction-expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
			break
	print("CASOS: ",count," FALHAS: ",failures)
	quit(1 if failures else 0)
