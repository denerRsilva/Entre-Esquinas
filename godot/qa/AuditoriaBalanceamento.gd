extends "res://qa/BaseNativa.gd"
## Analytical projections, NOT a physical or human playthrough. Deliberately
## outside the regression suite: balance problems must not become contracts.
const P = preload("res://simulacao/nativa/Partida.gd")
const REF = preload("res://simulacao/nativa/Refugio.gd")
const START = preload("res://simulacao/nativa/Inicio.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const HIRE = preload("res://simulacao/nativa/Contratacao.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
const CMD = preload("res://simulacao/nativa/ComandosInterface.gd")
const RECIPES = preload("res://simulacao/nativa/receitas.json")
const ITEMS = preload("res://simulacao/nativa/itens.json")
func fresh() -> Dictionary:
	var s := P.furnished(true,true);REF.start(s);START.apply(s);return s
func cost(id: String) -> float:
	var value := 0.0
	for raw in RECIPES.data[id].foods:value+=ITEMS.data[raw].cost*RECIPES.data[id].foods[raw]
	return value
func project(recipe: String,lunch_only: bool,hire: bool,price: float) -> Dictionary:
	var s := fresh();var rows := [];var margin := 0.0;var meals := 0
	for day in 60:
		if s.refuge.phase=="gameover":break
		var hired := false
		if hire and HIRE.unlocked(s) and not HIRE.occupied(s):
			var result := HIRE.hire(s,4);check(result.ok,"Projeção consegue contratar no crescimento");hired=result.ok
			if hired:margin-=HIRE.HIRE_COST
		var served := 0
		for period in 2:
			s.period=period
			if period==1 and REF.attack_day(s):continue
			if not recipe.is_empty() and not (period==1 and lunch_only):
				for person in s.refuge.residents:
					var employed := HIRE.employed(s,person.id)
					# Assume every eligible resident is served at 85% satisfaction.
					# No navigation, inventory, dirt, wastage or time simulation here.
					REF.completed(s,{"refugeResident":person.id,"recipe":recipe,"experience":{"satisfaction":{"score":85}}},"completed")
					served+=1;meals+=1;margin+=(float(RECIPES.data[recipe].price) if employed else price)-cost(recipe)
			REF.end_shift(s,period)
		var row := {"day":s.day,"population":s.refuge.residents.size(),"workers":s.workers.size(),"meals":served,"stats":REF.collective(s),"hired":hired}
		if REF.attack_day(s):
			s.clock.minute=1080;REF.begin_attack(s);REF.battle_step(s,8)
			row.attack=s.refuge.battle.duplicate(true)
			if s.refuge.phase!="gameover":REF.continue_day(s)
		else:s.clock={"minute":1560,"remainder":0,"ending":true}
		margin-=12;row.cumulative_margin=margin;rows.append(row)
		if s.refuge.phase!="gameover":check(ADMIN.finish_day(s),"Projeção encerra dia sem pendências")
		for value in s.refuge.stats.values():check(is_finite(value) and value>=0 and value<=100,"Status coletivo limitado")
	return {"recipe":recipe,"lunch_only":lunch_only,"hire":hire,"price":price,"days":rows,"meals":meals,"replacement_margin_less_daily_expenses_and_hire":margin,"ending":s.refuge.phase}
func price_probe(price: float) -> Dictionary:
	var s := fresh();s.menu.arrozCenoura=false
	var response := CMD.execute(s,"price",["caldoBatata",price])
	if not response.ok:return {"requested_price":price,"accepted":false,"menu_price":s.prices.caldoBatata}
	var sim := SIM.new();sim.service.random_source=func():return 0.5
	check(sim.spawn(s),"Preço permite chegada")
	var c: Dictionary = s.customers[0]
	if c.state=="leave":return {"requested_price":price,"accepted":true,"customer_ordered":false,"reason":c.experience.get("arrivalIssue")}
	c.state="waiting";c.goal=null
	s.player.x=c.x+1;s.player.y=c.y;sim.service.begin(s,c,"service")
	c.experience.elapsed.service=2
	check(sim.service.take_order(s,s.player,c),"Preço permite anotar pedido")
	c.experience.elapsed.food=10;sim.service.finish(c);c.experience.servedQuality=0
	return {"price":s.orders[0].price,"profile":c.experience.profile,"limits":c.experience.limits,"recipe":c.recipe,"satisfaction_with_equal_waits":sim.service.satisfaction(c.experience)}
func run():
	var data := {"method":"Formula projections with perfect service at 85% satisfaction, not physical playthroughs. Margins assume ingredients replaced at catalog cost; no spoilage, wages or extra purchases. Staff meals included at reference price, assuming a real surplus portion is prepared.","price_probe":[price_probe(8),price_probe(10),price_probe(12),price_probe(100)],"recipes":[],"policies":[]}
	for id in ["caldoBatata","arrozCenoura","canja"]:
		data.recipes.append({"recipe":id,"price":RECIPES.data[id].price,"ingredients":cost(id),"margin":RECIPES.data[id].price-cost(id),"nutrition":RECIPES.data[id].nutrition})
	for policy in [["",false,false,10],["caldoBatata",true,false,10],["caldoBatata",false,false,10],["arrozCenoura",false,false,14],["arrozCenoura",false,true,14]]:
		data.policies.append(project(policy[0],policy[1],policy[2],policy[3]))
	FileAccess.open("/tmp/auditoria-balanceamento.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	print("PROJEÇÕES /tmp/auditoria-balanceamento.json; FALHAS: ",failures);quit(1 if failures else 0)
