extends RefCounted
const BAL = preload("res://simulacao/nativa/Equilibrio.gd")
const REFUGE = preload("res://simulacao/nativa/Refugio.gd")
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const KITCHEN = preload("res://simulacao/nativa/Cozinha.gd")
const LOGISTICS = preload("res://simulacao/nativa/Logistica.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
var service = SERVICE.new()
var kitchen = KITCHEN.new()
var velocity: Variant = null
func choose_recipe(s: Dictionary,person: Variant = null,profile: String = "normal") -> Variant:
	var available: Array = []
	for id in preload("res://simulacao/nativa/Receitas.gd").available(s):
		if s.menu.get(id,false):available.append(id)
	if BAL.active(s) and person!=null:
		available=available.filter(func(id):return BAL.affordable(s,id,profile))
		if BAL.favorite(int(person.id)) in available:return BAL.favorite(int(person.id))
	return available[int(s.serial)%available.size()] if not available.is_empty() else null
func spawn(s: Dictionary) -> bool:
	if s.clock.ending or REFUGE.blocked(s) or REFUGE.dinner_blocked(s):return false
	var person = REFUGE.next_resident(s)
	if REFUGE.active(s) and person==null:return false
	if not true in s.menu.values():s.ledger.lost+=1;return false
	# Do not create overlapping arrivals or consume their random decisions
	# while another person is still crossing the entrance.
	for actor in MOVE.ACTORS.actors(s):
		if actor.get("room")!="restaurant" or not actor.has("x") or not actor.has("y"):continue
		for cell in MOVE.reserved(actor):
			if cell.x==7 and cell.y==13:return false
	var choice := choose_seat(s)
	if choice.is_empty():s.ledger.lost+=1;return false
	var seat: Dictionary = choice.seat
	var id: int = s.serial;s.serial+=1
	var customer := {"id":"client"+str(id),"room":"restaurant","x":7,"y":13,"goal":null,"wait":0,"hold":0,"state":"walk","carry":null,"seat":seat.id,"recipe":choose_recipe(s),"order":null,"timer":0,"experience":service.experience()}
	if person!=null:
		REFUGE.bind_visit(s,customer,person)
		if BAL.active(s):
			var selected_recipe = choose_recipe(s,person,customer.experience.profile)
			if selected_recipe!=null:customer.recipe=selected_recipe
			else:
				s.customers.append(customer);service.reject_dirty(s,customer,"price");return true
	s.customers.append(customer)
	if choice.get("reject",false):
		service.reject_dirty(s,customer,choice.reason);return true
	if choice.get("unhappy",false):
		# Reuse saved experience data: 20% of service patience remains and
		# the poor first impression also lowers the final service score.
		customer.experience.arrivalIssue="dirtySeat"
		customer.experience.elapsed.service=customer.experience.limits.service*0.8
	customer.goal={"room":"restaurant","x":seat.x,"y":seat.y}
	return true

func choose_seat(s: Dictionary) -> Dictionary:
	var reserved := {}
	for c in s.customers:
		if not c.get("done",false) and c.get("state","walk")!="leave":reserved[c.seat]=true
	var occupied := {}
	for actor in MOVE.ACTORS.actors(s):
		if actor.get("room")!="restaurant" or not actor.has("x") or not actor.has("y"):continue
		for cell in MOVE.reserved(actor):occupied[MOVE.key(cell)]=true
	var free: Array = []
	var tables := {}
	var reachable: Array = []
	for id in BUILD.seats(s):
		var chair = BUILD.find(s.objects,id)
		var table = BUILD.seat_table(chair,s.objects)
		tables[table.id]=false;reachable.append(chair)
		if not reserved.has(id) and not occupied.has(MOVE.key(chair)):free.append({"seat":chair,"table":table.id})
	if reachable.is_empty():return {}
	# A plate makes its table dirty, but only its own chair unavailable.
	# The explicit exception is a completely dirty dining room: every new
	# arrival turns around, even when some other places at those tables are clear.
	for chair in s.objects:
		if chair.type!="chair" or not BUILD.dirty(s,chair.id):continue
		var table = BUILD.chair_table(chair,s.objects)
		if table!=null and tables.has(table.id):tables[table.id]=true
	if not false in tables.values():return {"seat":reachable[0],"reject":true,"reason":"dirtyDiningRoom"}
	if free.is_empty():return {}
	var selected: Dictionary = free[int(service.draw()*free.size())]
	if not BUILD.dirty(s,selected.seat.id):return selected
	var alternatives: Array = []
	for candidate in free:
		if candidate.table==selected.table and not BUILD.dirty(s,candidate.seat.id):alternatives.append(candidate)
	if alternatives.is_empty() or service.draw()>=0.5:
		return {"seat":selected.seat,"reject":true,"reason":"dirtySeat"}
	var replacement: Dictionary = alternatives[int(service.draw()*alternatives.size())].duplicate()
	replacement.unhappy=true
	return replacement
func worker(s: Dictionary,w: Dictionary) -> void:
	var carry = w.get("carry")
	if (w.task in ["none","waiter"] and carry==null) or (carry!=null and carry.kind in ["dish","dirtyPlates"]):service.waiter(s,w)
	else:LOGISTICS.worker(s,w)
func simulate(s: Dictionary,dt: float) -> void:
	service.patience(s,dt);ADMIN.deliver(s);s.tick=fmod(s.tick+dt,0.18)
	MOVE.move(s,dt,velocity)
	service.manual_moving=velocity!=null and velocity.get("moving",false)
	kitchen.manual_moving=service.manual_moving
	for w in s.workers:
		if not service.pending_service(s) or w.has("mealBreak"):
			if BAL.staff_step(s,w,dt):continue
		worker(s,w)
	service.notes_step(s,dt)
	kitchen.step(s,dt);service.clients_step(s,dt)
	if s.open and not s.closing:
		s.arrival+=dt
		if s.arrival>=BAL.interval(s):s.arrival=0;spawn(s)
	if s.closing and s.customers.is_empty() and s.get("cooking")==null and s.get("plating")==null and s.ready.is_empty():
		var carried := false
		for actor in MOVE.ACTORS.actors(s):
			if actor.get("carry")!=null and actor.carry.kind=="dish" and not service.canceled(s,actor):carried=true
		if not carried and not s.workers.any(func(w):return w.has("mealBreak")):ADMIN.finish_period(s)
func step(s: Dictionary,dt: Variant) -> void:
	if not ADMIN.numeric(dt) or dt<=0:return
	if REFUGE.blocked(s):REFUGE.battle_step(s,dt);return
	if REFUGE.due(s) and not ADMIN.pending(s):REFUGE.begin_attack(s);return
	var remaining: float = dt
	while remaining>1e-9:
		var slice: float = remaining if s.clock.ending else minf(remaining,7-s.clock.remainder)
		s.time+=slice;ADMIN.advance_clock(s,slice);ADMIN.sync(s);simulate(s,slice);remaining=maxf(0,remaining-slice);ADMIN.finish_day(s)
		if REFUGE.due(s) and not ADMIN.pending(s):REFUGE.begin_attack(s);return
