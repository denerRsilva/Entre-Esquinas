extends "res://qa/PlaytestDoZeroUI.gd"
const BAL = preload("res://simulacao/nativa/Equilibrio.gd")
func shot(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/equilibrio-"+name+".png")
func run():
	root.size=Vector2i(1280,720);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
	check(await choose("Novo jogo"),"Novo jogo pelo mouse")
	var s: Dictionary = g.session.state
	check(await choose("Gestão") and await choose("Cardápio"),"Abre preços reais")
	var prices: Array = g.hud.find_children("*","SpinBox",true,false).filter(func(v):return v.is_visible_in_tree())
	check(prices.size()==2 and prices[0].max_value==12,"Controle de preço usa a faixa do motor")
	await shot("cardapio");await choose("Voltar ao jogo")
	# A won fixture unlocks the real two-portion kitchen and first employee.
	s.day=3;s.clock.minute=1080
	for key in s.refuge.stats:s.refuge.stats[key]=90
	g.tick(0.1);g.session.refuge_action("skip");g.session.refuge_action("continue");g.tick(0)
	check(s.day==4 and g.session.INTERACT.KITCHEN.RECIPES.batch_limit(s)==2,"Primeira vitória aumenta capacidade da panela")
	check(g.session.REFUGE.HIRING.hire(s,4).ok,"Contrata primeiro garçom após crescimento")
	for i in 2:
		await use("fridge");check(await choose("Retirar Batata •",true),"Retira ingrediente real para lote")
		await use("prep");advance(1.7);await use("stove")
	await use("stove");check(s.cooking!=null and s.cooking.servings==2,"Duas batatas cortadas iniciam duas porções")
	advance(5.1);await use("stove");await use("kitchen");advance(2.1)
	var station := object("kitchen")
	check(s.meals.made.caldoBatata==2 and g.session.BUILD.STORE.count(station,"dish_caldoBatata")==2,"Lote produz duas refeições reais")
	await use("stove")
	check(g.session.SAVE.serialize(s)!=null,"Lote conserva ingredientes, panelas e pratos")
	s.clock.minute=660;s.clock.remainder=0;s.open=true;s.arrival=-100;s.period=0
	var w: Dictionary = s.workers[0]
	for i in 400:
		g.tick(0.05)
		if w.has("mealBreak"):break
	check(w.has("mealBreak"),"Garçom retira uma porção excedente em intervalo")
	if not w.has("mealBreak"):await finish();return
	check(g.session.BUILD.STORE.count(station,"dish_caldoBatata")==1,"Refeição não é criada gratuitamente")
	await shot("intervalo")
	var raw = g.session.SAVE.serialize(s);var copy = g.session.SAVE.new().load_value(JSON.parse_string(raw)) if raw!=null else null
	check(copy!=null and copy.workers[0].has("mealBreak"),"Save preserva refeição em andamento")
	var cash: float = s.cash;var food: float = s.refuge.stats.food
	advance(4.1)
	check(s.cash==cash+10 and s.meals.eaten.caldoBatata==1 and s.refuge.stats.food>food,"Cidade remunera refeição real da equipe e alimenta status")
	check(not w.has("mealBreak") and w.carry!=null and w.carry.kind=="dirtyPlates","Funcionário fica com louça suja real")
	var paid: float = s.cash;advance(5)
	check(s.cash==paid,"Mesmo funcionário não recebe duas refeições no turno")
	if copy!=null:
		var sim = g.session.SIM.new();sim.service.random_source=func():return 0.5
		for i in 100:sim.step(copy,0.05)
		check(copy.cash==cash+10 and copy.meals.eaten.caldoBatata==1,"Retomada da refeição paga apenas uma vez")
	check(g.session.SAVE.serialize(s)!=null,"Equipe preserva conservação após comer e recolher")
	s.open=false;s.closing=false;w.goal=null;w.motion=null
	await choose("Gestão");await choose("Cidade");await shot("cidade")
	var protected: Dictionary = s.duplicate(true)
	protected.refuge.balance.staff={};protected.workers[0].carry=null;protected.workers[0].goal=null
	protected.orders=[{"recipe":"caldoBatata","state":"ordered"}]
	var left: int = g.session.BUILD.STORE.count(protected.objects.filter(func(o):return o.type=="kitchen")[0],"dish_caldoBatata")
	check(not BAL.staff_step(protected,protected.workers[0],0.1),"Reserva do cliente impede refeição da equipe")
	check(g.session.BUILD.STORE.count(protected.objects.filter(func(o):return o.type=="kitchen")[0],"dish_caldoBatata")==left,"Não retira porção reservada")
	await choose("Voltar ao jogo");await choose("Livro de receitas");await shot("livro")
	root.size=Vector2i(960,432);g.tick(0);await layout();await shot("livro-telefone")
	check(g.hud.usable_rect().encloses(g.hud.slots.modal[0].get_global_rect()),"Livro cabe na janela compacta")
	for label in g.hud.find_children("*","Label",true,false):
		if label.is_visible_in_tree() and label.text=="Prato":
			var parent: Node = label.get_parent()
			while not parent is PanelContainer:parent=parent.get_parent()
			check(label.get_global_rect().end.y<=parent.get_global_rect().end.y-16,"Rodapé do livro tem espaço antes da moldura")
	await choose("Voltar ao jogo")
	# New independent campaign verifies the menu action, not the debug clock.
	g.queue_free();await process_frame
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout();await choose("Novo jogo");await choose("Começar novo jogo")
	s=g.session.state;await choose("Gestão");await choose("Cidade")
	check(await choose("Avançar até o próximo turno"),"Avança pelo menu real")
	check(s.clock.minute==660 and s.open and s.customers.is_empty(),"Avanço simula preparação e abre no horário sem gerar clientes antecipados")
	check(g.session.SAVE.serialize(s)!=null,"Avanço seguro mantém save válido")
	var chairs: Array = g.session.BUILD.seats(s)
	var seat = chairs[int(chairs.size()*0.5)]
	s.dirtyTables[str(int(seat))]=1;s.equipment.plate+=1
	g.session.simulation.service.random_source=func():return 0.5
	check(g.session.simulation.spawn(s),"Chegada controlada encontra lugar sujo")
	var rejected: Dictionary = s.customers[0]
	check(rejected.experience.get("arrivalIssue")=="dirtySeat" and rejected.reactionUntil>s.time,"Reação breve acompanha recusa aprovada por sujeira")
	g.tick(0);await shot("reacao")
	check(g.session.SAVE.serialize(s)!=null,"Reação preserva save, sujeira e louça")
	await finish()
