extends "res://qa/BaseNativa.gd"
const P = preload("res://simulacao/nativa/Partida.gd")
const REF = preload("res://simulacao/nativa/Refugio.gd")
const START = preload("res://simulacao/nativa/Inicio.gd")
const BAL = preload("res://simulacao/nativa/Equilibrio.gd")
const CMD = preload("res://simulacao/nativa/ComandosInterface.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const SAVE = preload("res://simulacao/nativa/Salvamentos.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
func fresh() -> Dictionary:
	var s := P.furnished(true,true);REF.start(s);START.apply(s);preload("res://simulacao/nativa/Mercado.gd").initialize(s);return s
func run():
	var s := fresh()
	check(SAVE.serialize(s)!=null,"Campanha balanceada começa salvável")
	for pair in [["caldoBatata",65],["arrozCenoura",73],["canja",81]]:
		var city := fresh()
		for period in 2:
			for person in city.refuge.residents:BAL.meal(city,pair[0],85)
			REF.end_shift(city,period)
		check(is_equal_approx(city.refuge.stats.food,pair[1]),"Manutenção/recuperação diária: "+pair[0])
		check(is_equal_approx(city.refuge.stats.morale,66),"Moral recupera um ponto com atendimento bom")
	var skipped := fresh()
	for person in skipped.refuge.residents:BAL.meal(skipped,"caldoBatata",85)
	REF.end_shift(skipped,0);REF.end_shift(skipped,1)
	check(is_equal_approx(skipped.refuge.stats.food,57),"Pular jantar cria déficit alimentar")
	var horde := fresh();horde.day=3
	var before := REF.collective(horde);REF.end_shift(horde,1)
	check(REF.collective(horde)==before,"Jantar cancelado por horda não tem penalidade")
	check(not CMD.execute(s,"price",["caldoBatata",100]).ok and s.prices.caldoBatata==10,"Preço 100 rejeitado sem alterar cardápio")
	check(CMD.execute(s,"price",["caldoBatata",12]).ok and not BAL.affordable(s,"caldoBatata","normal") and BAL.affordable(s,"caldoBatata","patient"),"Orçamentos limitam preço alto")
	var discount := fresh();CMD.execute(discount,"price",["caldoBatata",8])
	check(is_equal_approx(BAL.price_penalty(discount,"caldoBatata"),-8),"Desconto favorece satisfação em troca de margem")
	var sim := SIM.new();sim.service.random_source=func():return 0.5
	s.menu.arrozCenoura=false
	var spawned := sim.spawn(s)
	check(spawned and s.customers[0].experience.get("arrivalIssue")=="price","Cliente sem opção acessível recusa preço")
	check(SAVE.serialize(s)!=null,"Recusa por preço preserva save e conservação")
	for minute in [1320,1380,1440]:
		var rest := fresh();rest.refuge.balance.lateMinute=minute
		check(BAL.recovery(rest)==[16,12,8][[1320,1380,1440].find(minute)],"Descanso acompanha término real do jantar")
	var old := fresh();old.refuge.erase("balance");old.cash=177;old.prices.caldoBatata=100
	var loaded = SAVE.new().load_value(old)
	check(loaded!=null and BAL.active(loaded) and loaded.cash==177 and loaded.prices.caldoBatata==12,"Save anterior migra sem reset e normaliza só preços futuros")
	var corrupt := fresh();corrupt.refuge.balance.lastRest=99
	check(SAVE.serialize(corrupt)==null,"Rejeita recuperação corrompida")
	check(ADMIN.skip_error(fresh()).is_empty(),"Pode avançar preparação sem tarefas")
	var hot := fresh();hot.objects.filter(func(o):return o.type=="stove")[0].ingredients=[{"item":"batata_cut","n":1}]
	check(not ADMIN.skip_error(hot).is_empty(),"Não salta tempo com ingredientes no fogão")
	var quoted := fresh();quoted.menu.arrozCenoura=false
	var engine := SIM.new();engine.service.random_source=func():return 0.5
	engine.spawn(quoted)
	var c: Dictionary = quoted.customers[0];c.state="waiting";c.goal=null;quoted.player.x=c.x+1;quoted.player.y=c.y;engine.service.begin(quoted,c,"service")
	check(engine.service.take_order(quoted,quoted.player,c),"Anota preço atual")
	CMD.execute(quoted,"price",["caldoBatata",12]);check(quoted.orders[0].price==10,"Pedido mantém preço acordado")
	var good := engine.service.satisfaction(c.experience);c.experience.pricePenalty=8
	check(engine.service.satisfaction(c.experience).score<good.score,"Preço alto reduz satisfação no cálculo real")
	quoted.period=1;quoted.clock.minute=1390;engine.service.abandon(quoted,c)
	check(BAL.recovery(quoted)==8,"Saída tardia sem refeição também reduz descanso")
	var session = preload("res://simulacao/nativa/SessaoCompleta.gd").new()
	session.root_action("refuge");session.state.day=3;session.state.clock.minute=600;session.checkpoint(true)
	var preparation: String = session.values[session.CHECKPOINT_KEY]
	session.state.refuge.stats.food=0;session.state.clock.minute=1000;session.modal="management";session.mode="general";session.tab="city"
	session.admin_action({"kind":"nextShift","key":"","mode":"general","tab":"city"},null)
	check(session.state.refuge.phase=="battle" and session.values[session.CHECKPOINT_KEY]==preparation,"Avanço inicia horda sem sobrescrever a preparação recuperável")
	print("FALHAS: ",failures);quit(1 if failures else 0)
