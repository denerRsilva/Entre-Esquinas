extends "res://qa/CozinhaNativa.gd"
func run():
	var fixtures = load("res://qa/referencia-migracao/interacoes.json").data
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	rules.timed_orders_enabled=false # Historical instant notes; PlaytestDoZeroUI covers player progress.
	var count := 0
	var retired := 0
	for test in fixtures.cases:
		var state := patched(fixtures.base,test.input)
		# Successful instant washing is superseded by PiaTarefasUI.
		if patched(fixtures.base,test.expected.patch).message=="Prato limpo nas mãos.":retired+=1;continue
		# .57 removed the kitchen divider; this legacy blocked-cell snapshot is retired.
		if test.operation=="pointerDown" and state.get("singleRoom",false):
			var cell:Dictionary=test.params[0].world
			if int(floor(cell.x))==14 and int(floor(cell.y)) in [7,8,9]:retired+=1;continue
		if test.operation=="primaryObjectAction" and state.player.get("hand")!=null and str(state.player.hand.item).begins_with("pot_"):
			var target = preload("res://simulacao/nativa/Construcao.gd").find(state.objects,test.params[0])
			# Returning a full pot to an empty stove is covered by ApoioPanelasUI.
			if target!=null and target.type=="stove" and target.get("pan") in [null,""]:retired+=1;continue
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":"interacoes","args":[test.operation,state,test.params,test.context]},"",true,true)))
		actual.velocity=null if actual.clearInput else test.velocity
		actual.erase("clearInput")
		var expected: Dictionary = test.expected.duplicate(true)
		expected.state=patched(fixtures.base,expected.patch);expected.erase("patch")
		# Near legacy support interactions now fail atomically on equipped tables.
		if expected.state.message=="Panela apoiada." and state.player.get("hand")!=null and state.player.hand.item=="pot":
			expected.state.player.hand=state.player.hand.duplicate(true)
			for i in expected.state.objects.size():
				if expected.state.objects[i].type=="kitchen" and expected.state.objects[i].get("support")!=null:
					for original in state.objects:
						if original.id==expected.state.objects[i].id:expected.state.objects[i]=original.duplicate(true);break
			expected.state.message="Traga uma panela e libere o apoio."
			expected.effects=[{"bad":true,"kind":"tell","message":expected.state.message}]
		if expected.state.message=="Panela instalada.":
			for target in state.objects:
				if target.type=="stove" and target.get("pan")==null and not target.get("ingredients",[]).is_empty():
					expected.state.player.hand=state.player.hand.duplicate(true)
					for i in expected.state.objects.size():
						if expected.state.objects[i].id==target.id:expected.state.objects[i]=target.duplicate(true)
					expected.state.message="Traga uma panela para um fogão livre."
					expected.effects=[{"bad":true,"kind":"tell","message":expected.state.message}]
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
	print("CASOS: ",count," CONTRATOS SUBSTITUÍDOS: ",retired," FALHAS: ",failures)
	quit(1 if failures else 0)
