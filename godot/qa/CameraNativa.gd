extends "res://qa/AtendimentoNativo.gd"
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var tests = load("res://qa/referencia-migracao/camera.json").data
	for test in tests:
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":"camera","args":test.args},"",true,true)))
		if not equivalent(actual,test.expected):
			check(false,JSON.stringify(test.args)+" esperado "+JSON.stringify(test.expected)+" recebido "+JSON.stringify(actual))
			break
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
