extends "res://qa/CozinhaNativa.gd"
func run():
	var fixtures = load("res://qa/referencia-migracao/simulacao.json").data
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	# Freeze idle walking only for old JS snapshots; PolimentoSalaoUI tests it enabled.
	rules.idle_walk_enabled=false
	rules.timed_orders_enabled=false
	var count := 0
	for test in fixtures.cases:
		var state := patched(fixtures.base,test.input)
		var draws: Array = []
		var actual: Variant = null
		while true:
			var args := [test.operation,state,test.params,draws,test.velocity] if test.system=="simulacao" else [test.operation,state,test.params,test.velocity!=null and test.velocity.get("moving",false)]
			actual=JSON.parse_string(rules.execute(JSON.stringify({"name":test.system,"args":args},"",true,true)))
			if actual==null or not actual.get("needsRandom",false):break
			draws.append([0.1,0.8,0.2,0.9,0.5][draws.size()%5])
		var expected := {"value":test.expected.value,"state":patched(fixtures.base,test.expected.patch)}
		if expected.state.message=="Restaurante fechado. O turno acompanha o relógio; reabra pela plaquinha enquanto estiver no horário.":expected.state.message="Restaurante fechado. O próximo turno abre automaticamente no horário marcado."
		if test.system=="simulacao":expected.input=test.expected.velocity
		count+=1
		if not equivalent(actual,expected) or draws.size()!=test.draws:
			check(false,test.system+" "+test.operation+" "+JSON.stringify(test.params)+" caso "+str(count))
			FileAccess.open("/tmp/simulation-actual.json",FileAccess.WRITE).store_string(JSON.stringify(actual))
			FileAccess.open("/tmp/simulation-expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
			break
	print("CASOS: ",count," FALHAS: ",failures)
	quit(1 if failures else 0)
