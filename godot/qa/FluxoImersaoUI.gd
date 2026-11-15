extends "res://qa/BaseInterfaceNativa.gd"
func run():
	await start_game()
	var s: Dictionary = g.session.state
	await take("frango");await click_object("prep");advance(2.1)
	await click_object("stove");await take("arroz");await click_object("stove");await click_object("stove");advance(8.1);await click_object("stove")
	check(s.player.hand.item=="pot_frangoArroz_1","Panela pronta nas mãos")
	await click_object("kitchen")
	var table: Variant = null
	for object in s.objects:
		if object.type=="kitchen":table=object;break
	check(s.plating!=null and s.plating.get("hand",false),"Um clique começa empratamento nas mãos")
	check(table.get("support")==null and s.player.hand.item=="pot_frangoArroz_1","Panela não é apoiada na superfície")
	var saved: Variant = g.session.SAVE.serialize(s)
	var loaded: Variant = g.session.SAVE.new().load_value(JSON.parse_string(saved)) if saved is String else null
	check(loaded!=null and loaded.plating.get("hand",false),"Save restaura empratamento das mãos")
	if loaded!=null:
		var invalid: Dictionary = loaded.duplicate(true);invalid.plating.portions=0
		check(not g.session.SAVE.VALIDATOR.valid(invalid),"Save rejeita porções inválidas no empratamento das mãos")
		var resumed_kitchen = g.session.SIM.KITCHEN.new()
		resumed_kitchen.plate_step(loaded,2.1)
		check(loaded.plating==null and loaded.player.hand.item=="pot" and g.session.SAVE.VALIDATOR.valid(loaded),"Empratamento salvo conclui com conservação")
	advance(2.1)
	check(s.plating==null and s.player.hand.item=="pot" and table.get("support")==null,"Final devolve panela vazia diretamente às mãos")
	check(g.session.BUILD.STORE.count(table,"dish_frangoArroz")==1 and table.plates==11,"Prato pronto e prato limpo consumido uma vez")
	advance(2.1);check(g.session.BUILD.STORE.count(table,"dish_frangoArroz")==1,"Não duplica pratos depois de terminar")
	check(g.session.SAVE.VALIDATOR.valid(s),"Conservação após empratar")
	# Simulate an older four-portion batch: all contents become dishes and the
	# pot returns empty, provided the surface has plates and pickup capacity.
	# Clear the existing pickup place before plating a four-portion legacy pot.
	g.session.BUILD.STORE.take(s,table,"dish_frangoArroz",1)
	s.recovery.append({"item":"dish_frangoArroz","n":1})
	s.player.hand={"item":"pot_frangoArroz_4","n":1,"quality":2};s.meals.made.frangoArroz+=4
	var kitchen = g.session.SIM.KITCHEN.new()
	check(kitchen.plate(s,table.id).ok,"Lote antigo com quatro porções aceito")
	kitchen.cancel_plate(s)
	check(s.player.hand.item=="pot_frangoArroz_4" and table.plates==11,"Cancelamento preserva comida e pratos")
	table.plates=2;s.equipment.plate-=9
	check(not kitchen.plate(s,table.id).ok and s.player.hand.item=="pot_frangoArroz_4","Falta de pratos preserva panela")
	table.plates=11;s.equipment.plate+=9
	check(kitchen.plate(s,table.id).ok,"Lote pronto para empratar")
	kitchen.plate_step(s,2.1)
	check(s.player.hand.item=="pot" and g.session.BUILD.STORE.count(table,"dish_frangoArroz")==4,"Lote inteiro vira pratos sem perder comida")
	check(g.session.SAVE.VALIDATOR.valid(s),"Conservação também com lote antigo")
	# Move time across opening without touching a sign or walking to the door.
	g.session.ADMIN.test_clock(s,650);g.tick(0)
	check(not s.open and g.session.step(0,[]).ui.get("openBtn")==null,"Sem HUD na porta antes de abrir")
	advance(7.1)
	check(s.open and s.clock.minute==660,"Abertura automática às 11:00")
	check(g.session.step(0,[]).ui.get("openBtn")==null,"Sem HUD na porta durante serviço")
	# Seat a customer and watch the waiter take the order over time.
	s.player.hand=null;s.equipment.pot-=1
	var sim = g.session.SIM.new();sim.service.random_source=func():return 0.5
	check(sim.spawn(s),"Cliente entra após abertura automática")
	var c: Dictionary = s.customers[0]
	var chair = g.session.BUILD.find(s.objects,c.seat)
	c.merge({"x":chair.x,"y":chair.y,"motion":null,"goal":null,"state":"waiting"},true);sim.service.begin(s,c,"service")
	var w: Dictionary = s.workers[0];w.task="waiter"
	for i in 200:
		sim.step(s,0.05)
		if w.has("noteJob"):break
	check(w.has("noteJob") and c.state=="waiting" and s.orders.is_empty(),"Garçom inicia anotação antes de criar pedido")
	var packet: Dictionary = g.session.step(0,[])
	var bar := false
	for command in packet.scene:
		if command[0]=="progress" and str(command[1]).begins_with("note:"):bar=true
	check(bar,"Anotação mostra barra no mundo")
	saved=g.session.SAVE.serialize(s);loaded=g.session.SAVE.new().load_value(JSON.parse_string(saved)) if saved is String else null
	check(loaded!=null and loaded.workers[0].has("noteJob"),"Save durante anotação")
	for i in 10:sim.step(s,0.05)
	check(c.state=="waiting" and s.orders.is_empty(),"Pedido aguarda conclusão da barra")
	for i in 20:sim.step(s,0.05)
	check(c.state=="ordered" and s.orders.size()==1 and not w.has("noteJob"),"Pedido anotado exatamente uma vez")
	check(g.session.SAVE.VALIDATOR.valid(s),"Estado final válido")
	# Closing remains tied to hours, then dinner opens without intervention.
	g.session.ADMIN.test_clock(s,900);check(s.closing,"Horário final suspende entradas")
	if loaded!=null:
		var resumed = g.session.SIM.new();resumed.service.random_source=func():return 0.5
		for i in 30:resumed.step(loaded,0.05)
		check(loaded.orders.size()==1 and not loaded.workers[0].has("noteJob"),"Anotação salva conclui uma única vez")
	# Cancel an in-progress note if its customer leaves: no orphan order.
	var canceled_state: Dictionary = s.duplicate(true)
	canceled_state.customers[0].state="waiting";canceled_state.customers[0].order=null
	canceled_state.workers[0].noteJob={"customer":c.id,"left":1,"total":1.2}
	canceled_state.customers[0].state="leave"
	var canceled_sim = g.session.SIM.new();canceled_sim.service.notes_step(canceled_state,2)
	check(not canceled_state.workers[0].has("noteJob") and canceled_state.orders.size()==s.orders.size(),"Saída do cliente cancela anotação sem criar outro pedido")
	var scheduled = g.session.get_script().new();scheduled.initialize({});scheduled.root_action("furnished")
	scheduled.state.serviceHours=[{"start":670,"end":680},{"start":690,"end":700}]
	scheduled.ADMIN.test_clock(scheduled.state,650)
	scheduled.step(7.1,[]);check(not scheduled.state.open,"Horário personalizado não abre antes da hora")
	scheduled.step(7,[]);check(scheduled.state.open,"Almoço abre no horário personalizado")
	scheduled.step(7,[]);check(not scheduled.state.open,"Almoço fecha ao final do horário sem clientes")
	scheduled.step(7,[]);check(scheduled.state.open and scheduled.state.period==1,"Jantar também abre sozinho")
	await finish()
