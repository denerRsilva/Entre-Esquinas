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
		if not equivalent(actual,expected):
			check(false,test.operation+" "+JSON.stringify(test.params))
			FileAccess.open("/tmp/kitchen-actual.json",FileAccess.WRITE).store_string(JSON.stringify(actual))
			FileAccess.open("/tmp/kitchen-expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
			break
	print("CASOS: ",fixtures.cases.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
