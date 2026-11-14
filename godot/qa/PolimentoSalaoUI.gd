extends "res://qa/BaseInterfaceNativa.gd"
const BANCADA = preload("res://moveis/Bancada.gd")
const MESA = preload("res://moveis/MesaTrabalho.gd")
const CENA = preload("res://simulacao/nativa/Cena.gd")
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var sim = g.session.SIM.new()
	sim.service.random_source=func():return 0.5
	var rolls := [0]
	sim.service.wander_random=func():rolls[0]+=1;return fmod(rolls[0]*0.618,1.0)
	var w: Dictionary = s.workers[0]

	sim.service.waiter(s,w)
	check(w.goal!=null and w.goal.get("idleWalk",false),"Garçom livre escolhe passeio")
	var visited := {}
	for i in 150:
		sim.step(s,0.1)
		visited[Vector2i(w.x,w.y)]=true
		check(w.room=="restaurant" and w.x<14 and w.y<14,"Passeio fica no salão, longe da saída")
	check(visited.size()>3,"Garçom continua andando após chegar ao destino")
	check(g.session.SAVE.VALIDATOR.valid(s),"Passeio preserva validade do salvamento")
	var saved = g.session.SAVE.serialize(s)
	check(saved is String and g.session.SAVE.new().load_value(JSON.parse_string(saved))!=null,"Save carrega durante o passeio")
	# Work always preempts the idle goal, including after the waiter returns
	# from a kitchen workstation. Keep the existing NPC speed.
	w.merge({"x":18,"y":11,"motion":null,"settled":null,"goal":null,"wait":0},true)
	sim.service.waiter(s,w)
	check(w.goal!=null and w.goal.x<14,"Garçom na cozinha recebe destino no salão")
	for i in 100:sim.step(s,0.1)
	check(w.x<14,"Garçom retorna da cozinha para passear")
	check(sim.spawn(s),"Cliente criado para testar prioridade")
	var customer: Dictionary = s.customers[0]
	var chair = g.session.BUILD.find(s.objects,customer.seat)
	customer.merge({"x":chair.x,"y":chair.y,"goal":null,"motion":null,"state":"waiting"},true)
	sim.service.begin(s,customer,"service")
	w.task="waiter";sim.service.waiter(s,w)
	check(w.goal!=null and not w.goal.get("idleWalk",false),"Cliente esperando interrompe passeio")
	for i in 150:
		sim.step(s,0.1)
		if customer.state=="ordered":break
	check(customer.state=="ordered","Garçom anota pedido após passear")
	sim.service.waiter(s,w)
	check(w.goal!=null and w.goal.get("idleWalk",false),"Passeio recomeça depois do atendimento")
	check(sim.MOVE.walk_time(w)>sim.MOVE.walk_time(customer),"Passeio é mais lento que atendimento")
	var kitchen: Variant = null
	for object in s.objects:
		if object.type=="kitchen":kitchen=object;break
	sim.service.STORE.put(s,kitchen,"dish_"+customer.recipe,1,0)
	sim.service.waiter(s,w)
	check(not w.goal.get("idleWalk",false),"Prato pronto interrompe o passeio")
	var delivered := false
	for i in 200:
		sim.step(s,0.1)
		if w.carry!=null:check(not w.goal.get("idleWalk",false),"Garçom com prato segue entrega")
		if customer.state=="eating":delivered=true;break
	check(delivered,"Entrega concluída depois de interromper o passeio")
	sim.service.waiter(s,w)
	check(w.goal!=null and w.goal.get("idleWalk",false),"Passeio recomeça depois de servir")
	# Four chair orientations, all seated phases, regardless of previous walk.
	var renderer = CENA.new()
	var table := {"id":900,"type":"table","room":"restaurant","x":8,"y":10,"rot":0}
	var seat := {"id":901,"type":"chair","room":"restaurant","x":8,"y":11,"rot":0}
	var visual_state: Dictionary = s.duplicate(true);visual_state.objects=[table,seat]
	for rot in 4:
		table.rot=rot%2;seat.rot=rot
		var p: Vector2i = [Vector2i(8,11),Vector2i(7,10),Vector2i(8,9),Vector2i(9,10)][rot]
		seat.x=p.x;seat.y=p.y
		customer.seat=seat.id;customer.x=p.x;customer.y=p.y;customer.motion=null;customer.settled=null
		for phase in ["waiting","ordered","eating"]:
			customer.state=phase;renderer.facing[customer.id]="left";renderer.commands=[]
			renderer.actor(visual_state,customer,null,false)
			for command in renderer.commands:
				if command[0]=="npc":check(command[5]==["up","right","down","left"][rot],"Cliente olha para a mesa: "+phase+str(rot))
	# Whole kits must fit on every rotated counter, including the L notch.
	check(MESA.CENTRO_KIT==Vector2(0,-44),"Kit centrado no tampo da mesa")
	for shape in 3:
		for rot in 4:
			var center := BANCADA.centro_kit(shape,rot)
			var cells := BANCADA.perfil(shape,rot)
			var local := Vector2i((center-Vector2(-20,-70))/2)
			for y in range(local.y-5,local.y+5):
				for x in range(local.x-6,local.x+6):check(cells[y*20+x]==1,"Kit inteiro sobre o tampo: "+str(shape)+"/"+str(rot))
	# Check actual world placement, rather than only the geometry helper.
	for shape in 3:
		for rot in 4:
			for kit in ["cuttingKit","platingKit"]:
				var packet: Dictionary = g.session.step(0,[])
				packet.scene=[["furniture",["counterH","counterV","counterCorner"][shape],400,400,40,40,rot,false,0],["furniture",kit,400,400,40,40,rot,false]]
				g.palco.paint(packet)
				var node = g.palco.pool[kit][0]
				var center: Vector2 = node.position+node.CENTRO_KIT*node.scale
				check(center.is_equal_approx(Vector2(420,440)+BANCADA.centro_kit(shape,rot)),"Kit centralizado na cena real: "+kit+str(shape)+str(rot))
	await finish()
