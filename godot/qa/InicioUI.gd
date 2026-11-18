extends "res://qa/FluxoCompletoNativoUI.gd"
const MARKET = preload("res://simulacao/nativa/Mercado.gd")
func snapshot(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720);g.tick(0);await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/inicio-"+name+".png")
	if name in ["receitas","mercador"]:
		root.size=Vector2i(960,432);g.tick(0);await layout();await RenderingServer.frame_post_draw
		check(g.hud.usable_rect().encloses(g.hud.slots.modal[0].get_global_rect()),"Menu dentro da tela larga compacta: "+name)
		root.get_texture().get_image().save_png("/tmp/inicio-"+name+"-telefone.png")
		root.size=Vector2i(1280,720);g.tick(0);await layout()
func prepare(id: String) -> void:
	for ingredient in g.session.INTERACT.KITCHEN.RECIPES.RECIPES.data[id].foods:
		await take(ingredient)
		if ingredient!="arroz":await click_object("prep");advance(2.1)
		await click_object("stove")
	await click_object("stove");advance(g.session.INTERACT.KITCHEN.RECIPES.RECIPES.data[id].time+0.1)
	await click_object("stove");await click_object("kitchen");advance(2.1)
	check(held()=="pot","Empratamento devolve panela vazia: "+id)
	await click_object("stove");await click_object("kitchen")
	check(held().begins_with("dish_") and g.session.state.meals.made[id]==1,"Receita nova é feita e há prato pronto nas mãos: "+id)
func run():
	root.size=Vector2i(1280,720);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout();await press("Novo jogo")
	var s: Dictionary = g.session.state
	check(s.cash==200 and s.workers.is_empty(),"Início com 200 e sem funcionário")
	check(s.objects.filter(func(o):return o.type=="table").size()==2 and s.objects.filter(func(o):return o.type=="chair").size()==8,"Duas mesas e oito cadeiras")
	check(s.equipment.pot==2 and s.equipment.plate==8 and s.inv.kitchen.arroz==12 and s.inv.kitchen.batata==8 and s.inv.kitchen.cenoura==8,"Utensílios e ingredientes do kit aprovado")
	check(g.session.SAVE.serialize(s)!=null,"Início conserva recursos e pode ser salvo")
	check(g.session.simulation.choose_recipe(s) in ["caldoBatata","arrozCenoura"],"Clientes só escolhem as duas receitas iniciais")
	for id in ["batata","cenoura","caldoBatata","arrozCenoura","canja"]:check(g.session.renderer.FOOD.texture(id).get_size()==Vector2(32,32),"Nova arte nativa de 32px: "+id)
	await snapshot("salao")
	await press("Livro de receitas");var book := JSON.stringify(g.frame_data.ui.modal)
	check(book.contains("Caldo de batata") and book.contains("Arroz com cenoura") and not book.contains('"text":"Canja"') and book.contains("recipeRating"),"Livro mostra pratos iniciais com nutrição e tempo visuais")
	var indicators := get_nodes_in_group("recipeRatings")
	check(indicators.map(func(v):return v.count)==[4,5,6,5],"Controles reais desenham todas as coxas e relógios, não apenas o primeiro ícone")
	await snapshot("receitas");await press("Voltar ao jogo")
	await press("Gestão");check(await press("Cardápio"),"Cardápio administrado sem computador");await press("Voltar ao jogo")
	await prepare("caldoBatata");await click_object("kitchen")
	await prepare("arrozCenoura");await click_object("kitchen")
	check(s.meals.made.caldoBatata==1 and s.meals.made.arrozCenoura==1 and g.session.SAVE.serialize(s)!=null,"As duas refeições ficam prontas e conservam ingredientes, pratos e panelas")
	await snapshot("pratos")
	# Feed an actual resident with one of the new dishes.
	for id in s.menu:s.menu[id]=id=="caldoBatata"
	g.session.ADMIN.test_clock(s,660);g.tick(0.05);s.arrival=0;await click_object("table")
	var sim = g.session.SIM.new();sim.service.random_source=func():return 0.0
	check(sim.spawn(s),"Morador chega e pede receita inicial")
	g.session.ADMIN.test_clock(s,900);advance(6);await click_object("table");advance(1.3)
	await click_object("kitchen");await click_object("table");advance(4.1)
	check(s.ledger.sales==1 and s.meals.eaten.caldoBatata==1,"Prato novo é servido, consumido e pago")
	# Reach the city, click the merchant, and purchase through real controls.
	g.session.MOVE.go(s.player,{"room":"street","x":17,"y":8});advance(20)
	var point: Dictionary = g.session.CAMERA.screen_point(18*40+20,8*40+20,g.session.rect,g.session.viewport,g.session.camera)
	g.events.append({"kind":"pointer","phase":"down","x":point.x,"y":point.y});g.events.append({"kind":"pointer","phase":"up","x":point.x,"y":point.y});g.tick(0);advance(5)
	check(g.session.modal=="market","Clique no mercador abre comércio após aproximação")
	var cash: float = s.cash;var count: float = s.inv.kitchen.batata
	check(await press("Comprar 5 Batata · $10"),"Compra pelo botão Godot")
	check(s.cash==cash-10 and s.market.stock.batata==7 and s.inv.kitchen.batata==count+5,"Compra cobra uma vez, reduz estoque e entrega na geladeira")
	await snapshot("mercador")
	var encoded: String = g.session.SAVE.serialize(s);var loaded = g.session.SAVE.new().load_value(JSON.parse_string(encoded))
	check(loaded!=null and loaded.market.stock.batata==7,"Salvar e carregar não repõe estoque comprado")
	var frozen := JSON.stringify(s)
	check(not MARKET.buy(s,"batata",8).ok and JSON.stringify(s)==frozen,"Recusa falta de estoque sem cobrar")
	s.cash=0;frozen=JSON.stringify(s);check(not MARKET.buy(s,"batata",1).ok and JSON.stringify(s)==frozen,"Recusa falta de dinheiro sem consumir estoque")
	s.cash=cash-10
	var full: Dictionary = s.duplicate(true)
	for o in full.objects:
		if o.type=="fridge":o.inventory.fill({"item":"arroz","n":99})
	frozen=JSON.stringify(full);check(not MARKET.buy(full,"batata",1).ok and JSON.stringify(full)==frozen,"Geladeira cheia não cobra nem perde compra")
	g.session.close_dialog();s.player.room="restaurant";s.player.x=18;s.player.y=11;s.player.goal=null;s.player.motion=null;s.player.erase("settled")
	s.customers=[];s.orders=[];s.ready=[] # The served guest has already paid.
	s.clock={"minute":1560,"remainder":0,"ending":true}
	check(g.session.ADMIN.finish_day(s) and s.day==2 and s.market.stock.batata==12,"Amanhecer repõe limite diário sem acumular sobras")
	var newer: Dictionary = g.session.SAVE.new().load_value(JSON.parse_string(g.session.SAVE.serialize(s)))
	check(newer!=null,"Dia seguinte continua salvável")
	# First traveling trader, recipe unlock and repeated-action protection.
	var trip: Dictionary = newer.duplicate(true);trip.day=4;MARKET.restock(trip);trip.player.room="street";trip.player.x=16;trip.player.y=12;trip.player.goal=null;trip.player.motion=null;trip.player.erase("settled")
	var money: float = trip.cash
	check(MARKET.visiting(trip) and MARKET.learn(trip) and trip.cash==money-30 and "canja" in trip.startKit.recipes,"Viajante do quarto dia ensina canja por custo único")
	money=trip.cash;check(not MARKET.learn(trip) and trip.cash==money,"Não paga novamente por receita conhecida")
	check(MARKET.buy(trip,"frango",5,true).ok and trip.market.travelStock==1,"Viajante tem estoque próprio limitado")
	check(g.session.SAVE.serialize(trip)!=null,"Receita aprendida, estoque de viagem e pagamento persistem")
	var small: Dictionary = trip.duplicate(true);small.refuge.stats.food=20
	var rich: Dictionary = small.duplicate(true)
	var guest := {"refugeResident":1,"recipe":"caldoBatata","experience":{"satisfaction":{"score":50}}}
	g.session.REFUGE.completed(small,guest,"completed");guest.recipe="arrozCenoura";g.session.REFUGE.completed(rich,guest,"completed")
	check(is_equal_approx(small.refuge.stats.food-20,4*2.0/small.refuge.residents.size()) and rich.refuge.stats.food>small.refuge.stats.food,"Nutrição visual corresponde à contribuição alimentar real")
	trip.player.room="restaurant";trip.player.x=18;trip.player.y=11;g.session.load_state(trip);g.tick(0)
	await prepare("canja")
	check(g.session.SAVE.serialize(trip)!=null and trip.meals.made.canja==1,"Canja desbloqueada também funciona na cozinha e no save")
	for corruption in ["food","meal","stock","recipe"]:
		var bad: Dictionary = trip.duplicate(true)
		match corruption:
			"food":bad.purchased.batata+=1
			"meal":bad.meals.made.canja+=1
			"stock":bad.market.stock.batata=13
			"recipe":bad.startKit.recipes.append("frangoArroz")
		check(g.session.SAVE.serialize(bad)==null,"Recusa corrupção no novo início: "+corruption)
	var legacy: Dictionary = g.session.PARTIDA.furnished(true,true);g.session.REFUGE.start(legacy)
	var imported = g.session.SAVE.new().load_value(legacy)
	check(imported!=null and imported.cash==1500 and imported.objects.size()==22 and imported.equipment.pot==4 and imported.market.stock.has("legumes") and not imported.has("startKit"),"Save anterior ganha mercador sem resetar dinheiro, móveis, pratos, panelas ou receitas")
	await finish()
