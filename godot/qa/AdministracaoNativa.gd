extends "res://qa/UIBase.gd"
func equivalent(a: Variant,b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):return absf(float(a)-float(b))<=1e-8
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not equivalent(a[key],b[key]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in a.size():
			if not equivalent(a[i],b[i]):return false
		return true
	return a==b
func run():
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout()
	var tests = load("res://qa/referencia-migracao/administracao.json").data
	for test in tests:
		var request := JSON.stringify({"name":"administracao","args":[test.operation,test.input,test.params]})
		var actual = JSON.parse_string(js("NativeRule("+JSON.stringify(request)+")"))
		if actual!=test.expected:check(false,test.operation+" "+JSON.stringify(test.params))
	js("state=R.fresh();state.ledger.revenue=100;R.advanceTestClock(state,1560);state.ledger.revenue=50;R.advanceTestClock(state,1560)")
	check(js("state.reports.length===2&&state.reports[0].revenue===100&&state.reports[1].revenue===50&&state.lastReport===state.reports[1]&&state.cash===1476")=="true","Dois fechamentos preservam relatórios e descontam duas despesas")
	for test in load("res://qa/referencia-migracao/administracao-dias.json").data:
		js("state="+JSON.stringify(test.input)+";R.step(state,"+str(test.dt)+",()=>.5)")
		var actual = JSON.parse_string(js("JSON.stringify(state)"))
		check(equivalent(actual,test.expected),"Avanço completo de dois dias equivale ao motor anterior")
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
