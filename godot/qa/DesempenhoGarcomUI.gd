extends "res://qa/BaseNativa.gd"
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
const CENA = preload("res://simulacao/nativa/Cena.gd")
func measure(blocked: bool) -> Dictionary:
	var s: Dictionary = PARTIDA.furnished(true,true)
	var sim = SIM.new()
	sim.service.random_source=func():return 0.5
	sim.service.wander_random=func():return 0.5
	var w: Dictionary = s.workers[0];w.task="waiter"
	sim.spawn(s)
	var c: Dictionary = s.customers[0]
	var chair = sim.BUILD.find(s.objects,c.seat)
	c.x=chair.x;c.y=chair.y;c.goal=null;c.state="waiting";sim.service.begin(s,c,"service")
	if blocked:
		for y in range(7,15):PARTIDA.add_object(s,"counterH",14,y) # Full barrier after the .57 divider removal.
		w.x=18;w.y=11
	var begin := Time.get_ticks_usec()
	for i in 30:sim.service.customer_access(s,w,c)
	var planning := (Time.get_ticks_usec()-begin)/30000.0
	var times := []
	begin=Time.get_ticks_usec()
	for i in 300:
		var tick := Time.get_ticks_usec();sim.step(s,0.05);times.append((Time.get_ticks_usec()-tick)/1000.0)
	times.sort()
	check(s.orders.size()==(0 if blocked else 1),"Atendimento respeita disponibilidade de passagem")
	check(times.back()<100,"Busca de tarefas não bloqueia por centenas de milissegundos")
	return {"blocked":blocked,"planning_ms":planning,"median_tick_ms":times[150],"p95_tick_ms":times[285],"worst_tick_ms":times.back()}
func run():
	print("PERFIL ",JSON.stringify(measure(false)))
	print("PERFIL ",JSON.stringify(measure(true)))
	var s: Dictionary = PARTIDA.furnished(true,true)
	var table := {"id":900,"type":"table","room":"restaurant","x":8,"y":10,"rot":0}
	var top := {"id":901,"type":"chair","room":"restaurant","x":8,"y":9,"rot":2}
	var bottom := {"id":902,"type":"chair","room":"restaurant","x":8,"y":11,"rot":0}
	s.objects=[table,top,bottom];s.customers=[{"id":"clientA","seat":901,"state":"eating","recipe":"sopa","order":null},{"id":"clientB","seat":902,"state":"eating","recipe":"frangoArroz","order":null}]
	var renderer = CENA.new();renderer.object(s,table,false)
	var positions := {}
	for command in renderer.commands:
		if command[0]=="food":positions[command[1]]=Vector2(command[2]+10,command[3]+7)
	check(positions.has("sopa") and positions.has("frangoArroz"),"Ambos os pratos são desenhados")
	check(positions.sopa.y<400 and positions.frangoArroz.y>400,"Prato servido fica do lado do cliente que recebeu")
	check(positions.sopa.x==340 and positions.frangoArroz.x==340,"Prato alinhado à cadeira")
	s.customers=[];s.dirtyTables={"901":1};renderer.commands=[];renderer.object(s,table,false)
	var dirty_correct := false
	for command in renderer.commands:
		if command[0]=="img" and command[1]=="modular/prato-vazio.png":dirty_correct=command[6]+command[8]/2==340 and command[7]+command[9]/2==388
	check(dirty_correct,"Louça suja permanece no lugar do cliente")
	var vertical := {"id":903,"type":"table","room":"restaurant","x":8,"y":10,"rot":1}
	var left := {"x":7,"y":10,"rot":1};var right := {"x":9,"y":10,"rot":3}
	check(CENA.table_plate_position(vertical,left).x<CENA.table_plate_position(vertical,right).x,"Mesa girada também respeita o lado da cadeira")
	# Moving/rotating furniture must affect searches immediately, without
	# stale cached occupancy; only immutable wall layouts are cached.
	var map = SIM.MOVE.MAP
	var fresh: Dictionary = PARTIDA.fresh(true,true)
	check(map.route(fresh,"restaurant",Vector2i(18,11),Vector2i(19,11))!=null,"Célula inicialmente acessível")
	PARTIDA.add_object(fresh,"counterH",19,11)
	check(map.route(fresh,"restaurant",Vector2i(18,11),Vector2i(19,11))==null,"Objeto novo bloqueia imediatamente")
	fresh.objects[0].x=20
	check(map.route(fresh,"restaurant",Vector2i(18,11),Vector2i(19,11))!=null,"Mover objeto libera passagem imediatamente")
	print("FALHAS: ",failures);call_deferred("quit",1 if failures else 0)
