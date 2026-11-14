extends "res://qa/BaseInterfaceNativa.gd"
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var sim = g.session.SIM.new()
	sim.service.wander_random=func():return 0.5
	var w: Dictionary = s.workers[0]
	sim.service.waiter(s,w)
	var start := Vector2i(w.x,w.y)
	var until: float = w.goal.idleUntil
	check(until-s.time>=3 and until-s.time<=7,"Pausa tem duração humana de 3 a 7 segundos")
	for i in 20:sim.step(s,0.1)
	check(Vector2i(w.x,w.y)==start and w.get("motion")==null,"Garçom permanece parado durante a pausa")
	check(w.goal.idleUntil==until,"Pausa não é sorteada novamente a cada quadro")
	check(g.session.SAVE.new().load_value(JSON.parse_string(g.session.SAVE.serialize(s)))!=null,"Salvar e carregar durante pausa")
	while s.time<until+0.1:sim.step(s,0.1)
	check(w.goal!=null and not w.goal.has("idleUntil"),"Passeio recomeça ao terminar a pausa")
	var target := Vector2i(w.goal.x,w.goal.y)
	var distance := absi(target.x-start.x)+absi(target.y-start.y)
	check(distance>=2 and distance<=4,"Passeio escolhe destino próximo")
	check(sim.MOVE.walk_time(w)==0.7,"Passos ociosos são mais lentos")
	for i in 100:
		sim.step(s,0.1)
		if w.goal!=null and w.goal.has("idleUntil"):break
	check(Vector2i(w.x,w.y)==target and w.goal.has("idleUntil"),"Chegar ao destino inicia outra pausa")
	var pause_save: Variant = g.session.SAVE.new().load_value(JSON.parse_string(g.session.SAVE.serialize(s)))
	check(pause_save!=null and pause_save.workers[0].goal.idleUntil==w.goal.idleUntil,"Save preserva tempo restante da pausa")
	# A new order interrupts even a fresh pause, without waiting for its timer.
	sim.service.random_source=func():return 0.5
	check(sim.spawn(s),"Cliente para interromper pausa")
	var c: Dictionary = s.customers[0]
	var chair = g.session.BUILD.find(s.objects,c.seat)
	c.merge({"x":chair.x,"y":chair.y,"motion":null,"goal":null,"state":"waiting"},true)
	sim.service.begin(s,c,"service");w.task="waiter"
	sim.service.waiter(s,w)
	check(w.goal!=null and not w.goal.get("idleWalk",false) and sim.MOVE.walk_time(w)==0.4,"Atendimento interrompe pausa e restaura velocidade")
	# Interrupting a slow step preserves position and accelerates its remainder.
	w.merge({"x":12,"y":10,"goal":null,"motion":null,"settled":null},true)
	sim.MOVE.go(w,{"x":11,"y":10,"idleWalk":true})
	sim.MOVE.start(w,{"x":11,"y":10});sim.MOVE.advance(w,0.2)
	var before: Dictionary = sim.MOVE.position(w)
	var remaining: float = w.motion.duration-w.motion.elapsed
	sim.MOVE.go(w,{"x":10,"y":10})
	var after: Dictionary = sim.MOVE.position(w)
	check(is_equal_approx(before.x,after.x) and is_equal_approx(before.y,after.y),"Interromper passeio não causa salto de posição")
	check(w.motion.duration-w.motion.elapsed<remaining,"Tarefa acelera o passo já em andamento")
	check(g.session.SAVE.VALIDATOR.valid(s),"Mudança de ritmo mantém save válido")
	await finish()
