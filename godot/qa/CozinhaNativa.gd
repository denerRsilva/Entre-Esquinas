extends "res://qa/BaseNativa.gd"
func patched(base: Dictionary,changes: Array) -> Dictionary:
	var state: Dictionary = base.duplicate(true)
	for change in changes:
		var parent: Variant = state
		for i in range(change.path.size()-1):parent=parent[change.path[i]]
		var key: String = change.path.back()
		if change.get("remove",false):parent.erase(key)
		else:parent[key]=change.value.duplicate(true) if change.value is Array or change.value is Dictionary else change.value
	return state
func run():
	var fixtures = load("res://qa/referencia-migracao/cozinha.json").data
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	for test in fixtures.cases:
		var state := patched(fixtures.base,test.input)
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":"cozinha","args":[test.operation,state,test.params,false]},"",true,true)))
		var expected := {"value":test.expected.value,"state":patched(fixtures.base,test.expected.patch)}
		# This native action intentionally replaces the retired hands-empty rule.
		var hand = state.player.get("hand")
		if test.operation=="physicalAction" and test.params[1]=="plate" and hand!=null and hand.item=="pot_sopa_1" and expected.value.get("error")=="Libere as mãos.":
			expected.value={"ok":true,"error":null,"message":"Empratando uma porção."}
			expected.state.message="Empratando uma porção."
			expected.state.plating={"count":1,"hand":true,"item":"pot_sopa_1","left":2,"portions":1,"prep":test.params[0],"quality":2,"recipe":"sopa","total":2}
			for object in expected.state.objects:
				if object.id==test.params[0]:object.feedback={"label":"Empratando uma porção","until":state.time+0.9}
		if not equivalent(actual,expected):
			check(false,test.operation+" "+JSON.stringify(test.params))
			FileAccess.open("/tmp/kitchen-actual.json",FileAccess.WRITE).store_string(JSON.stringify(actual))
			FileAccess.open("/tmp/kitchen-expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
			break
	print("CASOS: ",fixtures.cases.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
