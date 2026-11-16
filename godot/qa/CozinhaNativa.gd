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
	var retired := 0
	for test in fixtures.cases:
		var state := patched(fixtures.base,test.input)
		# Instant washing was replaced by per-plate tasks in PiaTarefasUI.
		if test.operation=="physicalAction" and test.params[1]=="wash" and test.expected.value.get("ok",false):retired+=1;continue
		# Historical snapshots allowed pots over tools and rejected full pots on
		# empty stoves. ApoioPanelasUI covers the replacement policy end-to-end.
		if test.operation=="physicalAction":
			var action: String = test.params[1]
			var target = preload("res://simulacao/nativa/Construcao.gd").find(state.objects,test.params[0])
			var old_success: bool = test.expected.value.get("ok",false)
			var retired_support: bool = action=="support" and target!=null and target.type=="kitchen" and old_success
			var full_stove: bool = action=="installPan" and state.player.get("hand")!=null and str(state.player.hand.item).begins_with("pot_")
			var occupied: bool = action in ["putDish","installPlates"] and target!=null and target.get("support")!=null and old_success
			if retired_support or full_stove or occupied:retired+=1;continue
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":"cozinha","args":[test.operation,state,test.params,false]},"",true,true)))
		var expected := {"value":test.expected.value,"state":patched(fixtures.base,test.expected.patch)}
		if expected.value is Dictionary and expected.value.get("error")=="Traga uma panela vazia para um fogão livre.":
			expected.value.error="Traga uma panela para um fogão livre."
			expected.value.message=expected.value.error;expected.state.message=expected.value.error
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
	print("CASOS: ",fixtures.cases.size()," CONTRATOS SUBSTITUÍDOS: ",retired," FALHAS: ",failures)
	quit(1 if failures else 0)
