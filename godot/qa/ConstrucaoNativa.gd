extends "res://qa/UIBase.gd"
func run():
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout()
	var fixtures = load("res://qa/referencia-migracao/construcao.json").data
	js("globalThis.buildingFixtures="+JSON.stringify(fixtures.bases))
	for test in fixtures.tests:
		js("globalThis.buildingState=JSON.parse(JSON.stringify(buildingFixtures["+JSON.stringify(test.base)+"]))")
		var before := js("JSON.stringify(buildingState)")
		var actual = JSON.parse_string(js("JSON.stringify(R["+JSON.stringify(test.name)+"](buildingState,..."+JSON.stringify(test.args)+"))"))
		if actual!=test.value:check(false,test.base+" "+test.name+" "+JSON.stringify(test.args))
		if test.after==null:
			if before!=js("JSON.stringify(buildingState)"):check(false,"Falha alterou estado")
		else:
			var after = JSON.parse_string(js("JSON.stringify({objects:buildingState.objects,cash:buildingState.cash,serial:buildingState.serial,ledger:buildingState.ledger,inv:buildingState.inv})"))
			if after!=test.after:check(false,"Resultado alterou dados inesperados")
	print("CASOS: ",fixtures.tests.size()," FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
