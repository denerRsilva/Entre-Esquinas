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
	var tests = load("res://qa/referencia-migracao/movimento.json").data
	for test in tests:
		js("state="+JSON.stringify(test.input))
		for command in test.commands:
			if command.kind=="input":js("R.setPlayerInput(state,"+str(command.x)+","+str(command.y)+")")
			elif command.kind=="go":js("R.go(R.allActors(state).find(a=>a.id==="+JSON.stringify(command.id)+"),"+JSON.stringify(command.target)+")")
			else:js("R.moveActors(state,"+str(command.dt)+")")
		var actual = JSON.parse_string(js("JSON.stringify({player:state.player,workers:state.workers,residents:state.residents,customers:state.customers,flowWaits:state.flowWaits})"))
		check(equivalent(actual,test.expected),test.label)
		check(equivalent(JSON.parse_string(js("JSON.stringify(R.playerVelocity(state.player))")),test.velocity),"Entrada transitória preservada")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
