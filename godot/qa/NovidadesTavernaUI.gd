extends "res://qa/BaseInterfaceNativa.gd"
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var build = g.session.BUILD
	g.session.enter_construction();widget("nativo:comprar:cuttingKit")
	var packet: Dictionary = g.session.step(0,[])
	var outlines := 0
	for command in packet.scene:
		if command[0]=="line" and command[5]=="#9fffc4":outlines+=1
	check(outlines==0,"Mesas equipadas não são destacadas como vazias")
	g.session.stop_build();g.session.drawer=true
	widget("nativo:comprar:counterH");g.session.hover={"x":20,"y":11};g.tick(0)
	check(await press("Confirmar posição"),"Compra de bancada com a nova arte")
	var counter: Dictionary = s.objects.back();var id: int = counter.id
	widget("nativo:comprar:cuttingKit");packet=g.session.step(0,[]);outlines=0
	for command in packet.scene:
		if command[0]=="line" and command[5]=="#9fffc4":outlines+=1
	check(outlines==1,"Bancada vazia destacada antes de apontar o mouse")
	g.session.hover={"x":20,"y":11};g.tick(0)
	check(await press("Confirmar posição") and counter.baseType=="counterH" and counter.type=="prep","Kit transforma bancada em corte")
	check(g.session.MOVE.MAP.rect(counter).size==Vector2i.ONE,"Kit preserva tamanho da bancada")
	var encoded: Variant = g.session.SAVE.serialize(s)
	var loaded: Variant = g.session.SAVE.new().load_value(JSON.parse_string(encoded)) if encoded is String else null
	check(loaded!=null and build.find(loaded.objects,id).baseType=="counterH","Save preserva bancada equipada")
	check(build.remove_kit(s,id).ok and counter.type=="counterH","Retirar kit devolve a bancada original")
	check(build.place(s,"platingKit",20,11).ok and counter.type=="kitchen","Bancada também aceita empratamento")
	check(build.place(s,"counterH",21,11).ok,"Peças vizinhas mantêm passagem")
	packet=g.session.step(0,[])
	var east_join := false;var west_join := false
	for command in packet.scene:
		if command[0]=="furniture" and command[1]=="counterH" and command.size()>8:
			if command[2]==800:east_join=bool(command[8]&2)
			if command[2]==840:west_join=bool(command[8]&8)
	check(east_join and west_join,"Conexões removem as bordas internas dos dois módulos")
	g.session.root_action("exitConstruction")
	g.session.save_game();var cash: float = s.cash
	g.session.choose_slot(2);g.session.root_action("furnished");g.session.state.cash=123;g.session.save_game()
	g.session.choose_slot(1)
	check(g.session.state.cash==cash,"Três espaços mantêm partidas independentes")
	var day: int = g.session.state.day
	g.session.sleep_day()
	check(g.session.state.day==day+1 and JSON.parse_string(g.session.values[g.session.slot_key(1)]).day==day+1,"Dormir inicia novo dia e salva automaticamente")
	g.session.choose_slot(2);check(g.session.state.cash==123,"Dormir não sobrescreve outra partida")
	g.session.choose_slot(4);check(g.session.active_slot==2,"Apenas três espaços são aceitos")
	await take("frango");await click_object("prep")
	packet=g.session.step(0.3,[])
	check(packet.sounds.has(180),"Corte produz sinal sonoro")
	check(g.session.state.chopping!=null,"Animação do corte acompanha tarefa real")
	advance(2.1);await click_object("stove")
	await take("arroz");await click_object("stove");await click_object("stove")
	packet=g.session.step(2.1,[])
	check(packet.sounds.has(105),"Cozimento produz sinal sonoro próprio")
	advance(8.1)
	var stove: Variant = null
	for object in g.session.state.objects:
		if object.type=="stove":stove=object;break
	check(stove!=null and stove.get("readyBatch")!=null,"Alimento pronto mantém estado para brilho e alerta")
	packet=g.session.step(0,[])
	var sparkle := false
	for command in packet.scene:
		if command[0]=="text" and command[3]=="✦":sparkle=true
	check(sparkle,"Prato no ponto ganha sinal visual animado")
	advance(20)
	packet=g.session.step(0,[])
	var warning := false
	for command in packet.scene:
		if command[0]=="text" and command[3]=="!":warning=true
	check(warning,"Risco de queimar mostra alerta visual")
	var long_game: Dictionary = g.session.PARTIDA.furnished(true,true)
	for i in 5100:long_game.orders.append({"id":1000+i,"customer":"old"+str(i),"recipe":"sopa","state":"paid","price":12,"age":0})
	long_game.serial=7000
	var long_save: Variant = g.session.SAVE.serialize(long_game)
	check(long_save is String and JSON.parse_string(long_save).orders.size()==200,"Campanha com mais de 5000 pedidos continua salvando")
	long_game.orders.push_front({"id":8000,"customer":"cancelado","recipe":"sopa","state":"lost","price":12,"age":0})
	long_game.workers[0].carry={"kind":"dish","order":8000,"quality":0}
	long_game.equipment.plate+=1;long_game.meals.made.sopa+=1;long_game.serial=9000
	var carried_save: Variant = g.session.SAVE.serialize(long_game)
	var carried_load: Variant = g.session.SAVE.new().load_value(JSON.parse_string(carried_save)) if carried_save is String else null
	check(carried_load!=null and g.session.INTERACT.SERVICE.new().find(carried_load.orders,8000)!=null,"Arquivamento preserva pedidos antigos ainda carregados")
	await finish()
