extends "res://qa/BaseNativa.gd"
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var fixtures = load("res://qa/referencia-migracao/construcao.json").data
	for test in fixtures.tests:
		var state: Dictionary = fixtures.bases[test.base].duplicate(true);var before: Dictionary = state.duplicate(true)
		var args: Array = [state];args.append_array(test.args)
		if test.name=="place":
			if args.size()<5:args.append(0)
			if args.size()<6:args.append(null)
		var raw = JSON.parse_string(rules.execute(JSON.stringify({"name":test.name,"args":args},"",true,true)))
		var actual = raw.value if test.name in ["place","remove"] else raw
		if test.name in ["place","remove"]:state=raw.state
		check(equivalent(actual,test.value),test.name)
		if test.after==null:check(equivalent(before,state),"Falha preserva estado")
		else:check(equivalent({"objects":state.objects,"cash":state.cash,"serial":state.serial,"ledger":state.ledger,"inv":state.inv},test.after),"Mudança preserva dados")
	print("CASOS: ",fixtures.tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
