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
	for test in load("res://qa/referencia-migracao/atendimento-fluxo.json").data:
		js("state="+JSON.stringify(test.input)+";globalThis.serviceDraws=0;globalThis.serviceRandom=()=>[.1,.8,.2,.9,.5][serviceDraws++%5]")
		js("for(let i=0;i<800;i++){R.step(state,.1,serviceRandom);"+("for(const c of [...state.customers]){if(c.state==='waiting'){Object.assign(state.player,{room:c.room,x:c.x-1,y:c.y,motion:null,goal:null,settled:null});R.interact(state,c.id);}else if(c.state==='ordered'){Object.assign(state.player,{room:c.room,x:c.x-1,y:c.y,motion:null,goal:null,settled:null});const prep=state.objects.find(o=>o.type==='kitchen');if(!state.player.hand&&R.objectCount(prep,'dish_sopa')){R.takeObject(state,prep,'dish_sopa',1,2);state.player.hand={item:'dish_sopa',n:1,quality:2};}R.interact(state,c.id);}}" if test.manual else "")+"}")
		var actual = JSON.parse_string(js("JSON.stringify(state)"))
		if not equivalent(actual,test.expected):
			FileAccess.open("/tmp/service-actual.json",FileAccess.WRITE).store_string(JSON.stringify(actual))
			FileAccess.open("/tmp/service-expected.json",FileAccess.WRITE).store_string(JSON.stringify(test.expected))
		check(equivalent(actual,test.expected),"Atendimento completo "+("manual" if test.manual else "garçom"))
		check(int(js("serviceDraws"))==test.draws,"Mesma sequência de sorteios")
		check(js("R.valid(state)&&R.foodConserved(state)&&R.equipmentConserved(state)&&R.mealsConserved(state)&&!!R.migrateSave(state)")=="true","Conservação e save após pagamento")
	var actions = load("res://qa/referencia-migracao/atendimento-acoes.json").data
	for test in actions:
		js("globalThis.serviceRequest="+JSON.stringify([test.operation,test.input,test.params,[],false]))
		var actual = JSON.parse_string(js("(()=>{let out;for(;;){out=JSON.parse(NativeRule(JSON.stringify({name:'atendimento',args:serviceRequest})));if(!out.needsRandom)return JSON.stringify(out);serviceRequest[3].push(.1);}})()"))
		if not equivalent(actual,test.expected):check(false,"Ação "+test.operation+" "+JSON.stringify(test.params))
		if int(js("serviceRequest[3].length"))!=test.draws:check(false,"Sorteios de "+test.operation)
	print("AÇÕES: ",actions.size())
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
