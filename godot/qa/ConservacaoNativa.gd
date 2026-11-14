extends "res://qa/BaseNativa.gd"
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var tests: Array = []
	tests+=load("res://qa/referencia-migracao/conservacao.json").data
	tests+=load("res://qa/referencia-migracao/qualidade.json").data
	for test in tests:
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":test.name,"args":test.args},"",true,true)))
		if not equivalent(actual,test.expected):check(false,test.name+" "+JSON.stringify(test.args))
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
