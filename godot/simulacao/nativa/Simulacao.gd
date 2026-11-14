extends RefCounted
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const KITCHEN = preload("res://simulacao/nativa/Cozinha.gd")
const LOGISTICS = preload("res://simulacao/nativa/Logistica.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
var service = SERVICE.new()
var kitchen = KITCHEN.new()
var velocity: Variant = null
func choose_recipe(s: Dictionary) -> Variant:
	var available: Array = []
	for id in SERVICE.RECIPES.data:
		if s.menu[id]:available.append(id)
	return available[int(s.serial)%available.size()] if not available.is_empty() else null
func spawn(s: Dictionary) -> bool:
	if s.clock.ending:return false
	if not true in s.menu.values():s.ledger.lost+=1;return false
	var seat: Variant = null
	for id in BUILD.seats(s):
		var candidate = BUILD.find(s.objects,id)
		var table = BUILD.seat_table(candidate,s.objects)
		var free := true
		for chair in s.objects:
			if chair.type!="chair":continue
			var linked = BUILD.chair_table(chair,s.objects)
			if linked==null or linked.id!=table.id:continue
			if s.dirtyTables.get(str(int(chair.id)),0)>0:free=false
			for c in s.customers:
				if c.seat==chair.id and not c.get("done",false):free=false
		if free:seat=candidate;break
	if seat==null:s.ledger.lost+=1;return false
	var id: int = s.serial;s.serial+=1
	var customer := {"id":"client"+str(id),"room":"restaurant","x":7,"y":13,"goal":null,"wait":0,"hold":0,"state":"walk","carry":null,"seat":seat.id,"recipe":choose_recipe(s),"order":null,"timer":0,"experience":service.experience()}
	for actor in MOVE.ACTORS.actors(s):
		if actor.room==customer.room and actor.x==customer.x and actor.y==customer.y:return false
	customer.goal={"room":"restaurant","x":seat.x,"y":seat.y};s.customers.append(customer)
	return true
func worker(s: Dictionary,w: Dictionary) -> void:
	var carry = w.get("carry")
	if (w.task in ["none","waiter"] and carry==null) or (carry!=null and carry.kind=="dish"):service.waiter(s,w)
	else:LOGISTICS.worker(s,w)
func simulate(s: Dictionary,dt: float) -> void:
	service.patience(s,dt);ADMIN.deliver(s);s.tick=fmod(s.tick+dt,0.18)
	MOVE.move(s,dt,velocity)
	service.manual_moving=velocity!=null and velocity.get("moving",false)
	kitchen.manual_moving=service.manual_moving
	for w in s.workers:worker(s,w)
	service.notes_step(s,dt)
	kitchen.step(s,dt);service.clients_step(s,dt)
	if s.open and not s.closing:
		s.arrival+=dt
		if s.arrival>=25:s.arrival=0;spawn(s)
	if s.closing and s.customers.is_empty() and s.get("cooking")==null and s.get("plating")==null and s.ready.is_empty():
		var carried := false
		for actor in MOVE.ACTORS.actors(s):
			if actor.get("carry")!=null and actor.carry.kind=="dish" and not service.canceled(s,actor):carried=true
		if not carried:ADMIN.finish_period(s)
func step(s: Dictionary,dt: Variant) -> void:
	if not ADMIN.numeric(dt) or dt<=0:return
	var remaining: float = dt
	while remaining>1e-9:
		var slice: float = remaining if s.clock.ending else minf(remaining,7-s.clock.remainder)
		s.time+=slice;ADMIN.advance_clock(s,slice);ADMIN.sync(s);simulate(s,slice);remaining=maxf(0,remaining-slice);ADMIN.finish_day(s)
