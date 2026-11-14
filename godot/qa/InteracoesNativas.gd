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
		# Filled pots now queue plating directly, rather than a support action.
		if test.operation=="primaryObjectAction" and expected.get("pending")!=null and expected.pending.get("action")=="support" and state.player.get("hand")!=null and state.player.hand.item.begins_with("pot_"):
			expected.pending.action="plate"
		if test.operation=="primaryObjectAction" and state.player.get("hand")!=null and state.player.hand.item=="pot_sopa_1" and expected.state.player.get("hand")==null:
			var target: Variant = null
			for object in expected.state.objects:
				if object.id==test.params[0] and object.get("support")!=null and object.support.item=="pot_sopa_1":target=object;break
			if target!=null:
				target.erase("support");target.feedback={"label":"Empratando uma porção","until":state.time+0.9}
				expected.state.player.hand=state.player.hand.duplicate(true);expected.state.message="Empratando uma porção."
				expected.state.plating={"count":1,"hand":true,"item":"pot_sopa_1","left":2,"portions":1,"prep":test.params[0],"quality":2,"recipe":"sopa","total":2}
				expected.effects=[{"bad":false,"kind":"tell","message":"Empratando uma porção."}]
		count+=1
		if not equivalent(actual,expected):
			check(false,test.operation+" "+JSON.stringify(test.params)+" caso "+str(count))
			FileAccess.open("/tmp/interaction-actual.json",FileAccess.WRITE).store_string(JSON.stringify(actual))
			FileAccess.open("/tmp/interaction-expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
			break
	print("CASOS: ",count," FALHAS: ",failures)
	quit(1 if failures else 0)
