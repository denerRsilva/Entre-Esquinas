extends "res://qa/BaseInterfaceNativa.gd"
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
const DISHES = preload("res://simulacao/nativa/Louca.gd")
const SAVE = preload("res://simulacao/nativa/Salvamentos.gd")
const COOK = preload("res://simulacao/nativa/Cozinha.gd")
const SCENE = preload("res://simulacao/nativa/Cena.gd")
func object(s: Dictionary,type: String):
	for o in s.objects:
		if o.type==type:return o
	return null
func add_dirty(s: Dictionary,table: Dictionary,n: int) -> void:
	var chairs: Array = []
	for chair in s.objects:
		if chair.type!="chair":continue
		var linked = SIM.BUILD.chair_table(chair,s.objects)
		if linked!=null and linked.id==table.id:chairs.append(chair)
	for i in n:
		var key := str(int(chairs[i%chairs.size()].id))
		s.dirtyTables[key]=s.dirtyTables.get(key,0)+1
	s.equipment.plate+=n
func beside(s: Dictionary,a: Dictionary,o: Dictionary) -> void:
	var p = SIM.MOVE.closest(s,a,o)
	check(p!=null,"Móvel tem acesso")
	if p!=null:a.merge({"x":p.x,"y":p.y,"motion":null,"goal":null,"settled":null},true)
func reload(s: Dictionary) -> Variant:
	var raw: Variant = SAVE.serialize(s)
	return SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
func snapshot(s: Dictionary,name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	g.session.state=s;g.tick(0);await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/esquinas-louca-"+name+".png")
func run():
	await start_game(true)
	check(g.session.state.workers[0].task=="waiter","Garçom vem ativo na partida mobiliada")
	check(PARTIDA.fresh(true,true).workers[0].task=="waiter","Partida vazia também habilita o garçom")
	var old: Dictionary = PARTIDA.furnished(true,true)
	old.erase("waiterDefaultApplied");old.workers[0].task="none"
	g.session.load_state(old)
	check(old.workers[0].task=="waiter" and old.waiterDefaultApplied,"Partida antiga ganha padrão ativo ao entrar")
	g.session.UI_COMMAND.execute(old,"task",["worker2","none"])
	var paused: Variant = reload(old)
	check(paused!=null,"Escolha de pausar pode ser salva")
	if paused!=null:
		g.session.load_state(paused)
		check(g.session.state.workers[0].task=="none","Reabrir partida respeita pausa escolhida e salva")
	g.session.state=PARTIDA.furnished(true,true);g.session.state.workers[0].task="none";g.tick(0)
	var s: Dictionary = g.session.state
	var tables: Array = s.objects.filter(func(o):return o.type=="table")
	add_dirty(s,tables[0],4);add_dirty(s,tables[1],3)
	# Actual click-to-walk collection fills one hand across multiple tables.
	await click_object("table")
	check(s.player.hand!=null and s.player.hand.item=="dirtyPlate" and s.player.hand.n==4,"Um clique recolhe os quatro pratos disponíveis")
	beside(s,s.player,tables[1])
	var kitchen := COOK.new()
	check(kitchen.collect_dirty(s,tables[1].id).ok and s.player.hand.n==5,"Outra mesa completa pilha até cinco")
	check(DISHES.count(s,tables[1])==2 and not kitchen.collect_dirty(s,tables[1].id).ok,"Sexto prato fica na mesa")
	check(SAVE.VALIDATOR.valid(s) and reload(s)!=null,"Pilha de cinco preservada no save/load")
	await snapshot(s,"jogador")
	var renderer := SCENE.new();renderer.draw_held(s,s.player.hand,100,100)
	var plates: Array = renderer.commands.filter(func(op):return op[0]=="img" and op[1]=="modular/prato-vazio.png")
	check(plates.size()==5 and plates[0][9]==plates[4][9] and plates[4][7]<plates[0][7],"Cinco pratos são desenhados empilhados sem mudar tamanho")
	var sink = object(s,"sink");beside(s,s.player,sink)
	check(kitchen.wash(s,sink.id).ok and s.player.hand.item=="plate" and s.player.hand.n==5,"Lavagem conserva a pilha inteira")
	var station = object(s,"kitchen")
	s.equipment.plate+=19-int(station.plates);station.plates=19
	beside(s,s.player,station)
	check(kitchen.physical(s,station.id,"installPlates").ok and station.plates==20 and s.player.hand.n==4,"Mesa quase cheia recebe só um e devolve os outros quatro nas mãos")
	var fridge = object(s,"fridge");beside(s,s.player,fridge)
	check(kitchen.storage(s,fridge.id,"put",0).ok and s.player.hand==null and SIM.BUILD.STORE.count(fridge,"plate")==4,"Guardar pilha não descarta os pratos restantes")
	check(SAVE.VALIDATOR.valid(s),"Coleta, lavagem, instalação e armazenamento conservam todos os pratos")
	var invalid: Dictionary = s.duplicate(true)
	invalid.player.hand={"item":"dirtyPlate","n":6};invalid.equipment.plate+=6
	check(not SAVE.VALIDATOR.valid(invalid),"Save rejeita seis pratos nas mãos")
	var bad_worker: Dictionary = PARTIDA.furnished(true,true)
	bad_worker.workers[0].carry={"kind":"dirtyPlates","n":6};bad_worker.equipment.plate+=6
	check(not SAVE.VALIDATOR.valid(bad_worker),"Save também rejeita seis pratos carregados por NPC")
	var bad_sink: Dictionary = PARTIDA.furnished(true,true)
	object(bad_sink,"sink").dirtyPlates=21;bad_sink.equipment.plate+=21
	check(not SAVE.VALIDATOR.valid(bad_sink),"Save rejeita pia acima da capacidade")
	# Real worker path: collect across tables, cap at five, and unload at sink.
	var live: Dictionary = PARTIDA.furnished(true,true)
	var sim := SIM.new();sim.service.random_source=func():return 0.5
	var worker: Dictionary = live.workers[0]
	var dirty_tables: Array = live.objects.filter(func(o):return o.type=="table")
	add_dirty(live,dirty_tables[0],4);add_dirty(live,dirty_tables[2],3)
	var max_held := 0;var saw_carry := false;var restored_carry := false;var captured := false
	var worst_tick := 0
	for i in 1000:
		var before := Time.get_ticks_usec();sim.step(live,0.05);worst_tick=maxi(worst_tick,Time.get_ticks_usec()-before)
		var count := DISHES.held(worker);max_held=maxi(max_held,count)
		if count==5 and not captured:
			captured=true;await snapshot(live,"garcom")
		if count and not saw_carry:
			saw_carry=true
			var copy: Variant = reload(live)
			restored_carry=copy!=null and DISHES.held(copy.workers[0])==count
		check(count<=5,"NPC nunca carrega mais de cinco pratos")
		if object(live,"sink").get("dirtyPlates",0)==7 and worker.get("carry")==null:break
	check(saw_carry and max_held==5 and restored_carry,"NPC empilha até cinco e pode ser salvo durante o transporte")
	check(object(live,"sink").get("dirtyPlates",0)==7 and DISHES.count(live,dirty_tables[0])==0 and DISHES.count(live,dirty_tables[2])==0,"NPC leva sete pratos em duas viagens sem lavar automaticamente")
	check(SAVE.VALIDATOR.valid(live) and reload(live)!=null,"Louça entregue na pia persiste sem perda ou duplicação")
	await snapshot(live,"pia")
	check(worst_tick<100000,"Limpeza não bloqueia um quadro por 100ms")
	var waiting_sink = object(live,"sink");beside(live,live.player,waiting_sink)
	check(kitchen.wash(live,waiting_sink.id).ok and live.player.hand.n==5 and waiting_sink.dirtyPlates==2,"Jogador lava até cinco pratos deixados pelo NPC")
	check(not kitchen.wash(live,waiting_sink.id).ok and waiting_sink.dirtyPlates==2,"Mãos ocupadas não apagam os pratos restantes na pia")
	check(not SIM.BUILD.remove(live,waiting_sink.id).ok,"Pia com pratos não pode ser reembolsada e apagar conteúdo")
	# No usable sink: keep dirty plates where they are, with bounded planning.
	var blocked: Dictionary = PARTIDA.furnished(true,true)
	blocked.objects=blocked.objects.filter(func(o):return o.type!="sink")
	add_dirty(blocked,object(blocked,"table"),5)
	for i in 100:sim.step(blocked,0.05)
	check(DISHES.count(blocked,object(blocked,"table"))==5 and blocked.workers[0].get("carry")==null,"Sem pia, funcionário não recolhe louça sem destino")
	blocked.equipment.plate+=3;DISHES.set_held(blocked.workers[0],3)
	for i in 20:sim.step(blocked,0.05)
	check(DISHES.held(blocked.workers[0])==3 and SAVE.VALIDATOR.valid(blocked),"Pia removida durante transporte não apaga a pilha")
	# New service interrupts cleanup before collection; hands in transit must
	# first unload, even if the operator pauses the worker during transport.
	var urgent: Dictionary = PARTIDA.furnished(true,true)
	var urgent_sim := SIM.new();urgent_sim.service.random_source=func():return 0.5
	add_dirty(urgent,object(urgent,"table"),4)
	check(urgent_sim.spawn(urgent),"Cliente para testar prioridade")
	var c: Dictionary = urgent.customers[0]
	var chair = SIM.BUILD.find(urgent.objects,c.seat)
	c.merge({"x":chair.x,"y":chair.y,"motion":null,"goal":null,"state":"waiting"},true);urgent_sim.service.begin(urgent,c,"service")
	for i in 500:
		urgent_sim.step(urgent,0.05)
		if c.state=="ordered":break
	check(c.state=="ordered" and DISHES.count(urgent,object(urgent,"table"))==4,"Anotar pedido tem prioridade sobre limpar")
	var paused_delivery: Dictionary = PARTIDA.furnished(true,true)
	paused_delivery.equipment.plate+=5;DISHES.set_held(paused_delivery.workers[0],5);paused_delivery.workers[0].task="none"
	for i in 500:
		sim.step(paused_delivery,0.05)
		if DISHES.held(paused_delivery.workers[0])==0:break
	check(object(paused_delivery,"sink").get("dirtyPlates",0)==5 and paused_delivery.workers[0].task=="none","Pausar no transporte termina a entrega sem perder a pilha")
	print("PILHA MÁXIMA NPC: ",max_held," • PIOR TICK (ms): ",worst_tick/1000.0)
	await finish()
