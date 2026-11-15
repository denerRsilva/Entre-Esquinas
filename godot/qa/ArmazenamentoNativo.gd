extends "res://qa/BaseNativa.gd"
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var tests: Array = []
	tests+=load("res://qa/referencia-migracao/armazenamento.json").data
	tests+=load("res://qa/referencia-migracao/receitas-nativas.json").data
	for test in tests:
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":test.name,"args":test.args},"",true,true)))
		var expected: Variant = test.expected
		if test.name=="objectSpace" and test.args[0].type=="kitchen" and test.args[1]=="plate":
			expected=maxi(0,20-int(test.args[0].plates))
		if not equivalent(actual,expected):check(false,test.name+" "+JSON.stringify(test.args))
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
