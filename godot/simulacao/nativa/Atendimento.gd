extends RefCounted
const REFUGE = preload("res://simulacao/nativa/Refugio.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const INV = preload("res://simulacao/nativa/Inventario.gd")
const RECIPES = preload("res://simulacao/nativa/receitas.json")
const CONFIG = preload("res://simulacao/nativa/clientes.json")
const DISHES = preload("res://simulacao/nativa/Louca.gd")
const HYGIENE = preload("res://simulacao/nativa/Higiene.gd")
static var wander_rng := RandomNumberGenerator.new()
var timed_orders_enabled := true
var idle_walk_enabled := true
var wander_random: Callable = func():return wander_rng.randf()
var random_source: Callable
var random_values: Array = []
var manual_moving := false
var random_index := 0
var needs_random := false
func draw() -> float:
	if random_source.is_valid():return clampf(random_source.call(),0,1-2.220446049250313e-16)
	if random_index>=random_values.size():needs_random=true;return 0
	var value: float = random_values[random_index]
	random_index+=1
	return clampf(value,0,1-2.220446049250313e-16)
func find(list: Array, id: Variant) -> Variant:
	for value in list:
		if value.id is String and id is String:
			if value.id==id:return value
		elif (value.id is int or value.id is float) and (id is int or id is float):
			if value.id==id:return value
	return null
func near(actor: Dictionary, target: Dictionary) -> bool:return actor.room==target.room and absf(actor.x-target.x)+absf(actor.y-target.y)<=1
func ratio(experience: Dictionary) -> Variant:
	var phase = experience.get("phase")
	return maxf(0,1-experience.elapsed[phase]/experience.limits[phase]) if phase!=null else null
func visual(s: Dictionary, c: Dictionary) -> void:
	var p: Dictionary = c.experience
	if p.phase!=null:
		var remaining: float = ratio(p)
		p.visual="patient" if remaining>CONFIG.data.thresholds.patient else "impatient" if remaining>CONFIG.data.thresholds.stressed else "stressed"
	elif p.abandoned:p.visual="leaving" if p.indicatorUntil==null or s.time<p.indicatorUntil else null
	else:p.visual="happy" if p.satisfaction!=null and p.satisfaction.classification in ["verySatisfied","satisfied"] and s.time<p.indicatorUntil else null
func begin(s: Dictionary,c: Dictionary,phase: String) -> void:c.experience.phase=phase;visual(s,c)
func finish(c: Dictionary) -> void:
	if c.experience.phase!=null:c.experience.results[c.experience.phase]=ratio(c.experience)
	c.experience.phase=null
func satisfaction(p: Dictionary) -> Dictionary:
	var weights: Dictionary = CONFIG.data.satisfaction.weights
	var score: float = (p.results.get("service") if p.results.get("service")!=null else 0)*weights.service+(p.results.get("food") if p.results.get("food")!=null else 0)*weights.food
	var denominator: float = weights.service+weights.food
	if p.has("servedQuality"):score+=[0.7,0.8,0.9,1][int(p.servedQuality)]*weights.quality;denominator+=weights.quality
	score=100*score/denominator
	var classification: String = CONFIG.data.satisfaction.classes[-1].id
	for item in CONFIG.data.satisfaction.classes:
		if score>=item.min:classification=item.id;break
	return {"score":score,"classification":classification,"quality":p.get("servedQuality")}
func reputation(s: Dictionary,visit: Dictionary,event: Variant) -> bool:
	return ADMIN.reputation(s,visit,event,true,true)
func finalize(s: Dictionary,c: Dictionary,outcome: String) -> bool:
	var p: Dictionary = c.experience
	if p.reviewResolved:return false
	p.reviewResolved=true
	var rule: Dictionary = CONFIG.data.reviews["abandoned" if outcome=="abandoned" else p.satisfaction.classification]
	var event: Variant = null
	if draw()<rule.probability:
		event={"visitId":c.id,"day":s.day,"period":s.period,"time":s.time,"type":rule.type,"outcome":outcome}
		s.experience.events.append(event)
	var visit := {"id":c.id,"day":s.day,"period":s.period,"time":s.time,"outcome":outcome,"profile":p.profile,"limits":p.limits.duplicate(),"elapsed":p.elapsed.duplicate(),"results":p.results.duplicate(),"satisfaction":p.satisfaction.duplicate() if p.satisfaction!=null else null}
	if p.has("arrivalIssue"):visit.arrivalIssue=p.arrivalIssue
	s.experience.visits.append(visit);reputation(s,visit,event)
	REFUGE.completed(s,c,outcome)
	return true
func reject_dirty(s: Dictionary,c: Dictionary,reason: String) -> bool:
	var p: Dictionary = c.experience
	if p.reviewResolved:return false
	p.arrivalIssue=reason;p.abandoned=true;p.phase=null
	p.satisfaction={"score":0,"classification":"unsatisfied","quality":null}
	p.indicatorUntil=null
	c.state="leave";MOVE.go(c,{"room":"restaurant","x":7,"y":14})
	s.ledger.lost+=1;visual(s,c);finalize(s,c,"abandoned")
	return true
func abandon(s: Dictionary,c: Dictionary) -> bool:
	var p: Dictionary = c.experience
	if p.abandoned or p.phase==null:return false
	finish(c);p.abandoned=true;p.satisfaction={"score":0,"classification":"unsatisfied","quality":null}
	p.indicatorUntil=null if CONFIG.data.indicators.abandonSeconds==null else s.time+CONFIG.data.indicators.abandonSeconds
	var order = find(s.orders,c.order)
	if order!=null:
		order.state="lost";s.ready=s.ready.filter(func(id):return id!=order.id)
		if s.priority==order.id:s.priority=null
	c.state="leave";MOVE.go(c,{"room":"restaurant","x":7,"y":14});s.ledger.lost+=1
	visual(s,c);finalize(s,c,"abandoned");s.message="Cliente desistiu por demora. Pedido cancelado, sem venda."
	return true
func expired(s: Dictionary,c: Dictionary) -> bool:
	var p: Dictionary = c.experience
	if p.abandoned:return true
	if p.phase!=null and p.elapsed[p.phase]>=p.limits[p.phase]:abandon(s,c);return true
	return false
func canceled(s: Dictionary,a: Dictionary) -> bool:
	var carry = a.get("carry")
	if carry==null or carry.kind!="dish":return false
	var order = find(s.orders,carry.order)
	return order!=null and order.state=="lost"
func object_near(s: Dictionary,a: Dictionary,o: Dictionary) -> bool:
	if a.get("motion")!=null or a.room!=o.room or (a.id==s.player.id and manual_moving):return false
	for p in MOVE.access(s,o):
		if p.x==a.x and p.y==a.y:return true
	return false
func return_canceled(s: Dictionary,a: Dictionary) -> bool:
	if a.get("motion")!=null or not canceled(s,a):return false
	var item: String = "dish_"+find(s.orders,a.carry.order).recipe
	for o in s.objects:
		if o.type=="kitchen" and STORE.space(o,item)>0 and object_near(s,a,o):
			STORE.put(s,o,item,1,a.carry.get("quality",0));a.carry=null;s.message="Pedido cancelado: prato devolvido à mesa de preparo.";return true
	return false
func take_order(s: Dictionary,a: Dictionary,c: Variant) -> bool:
	if a.get("motion")!=null or c==null or c.state!="waiting" or not near(a,c) or expired(s,c):return false
	finish(c)
	var order := {"id":s.serial,"customer":c.id,"recipe":c.recipe,"state":"ordered","age":0,"price":s.prices[c.recipe]}
	s.serial+=1;s.orders.append(order);c.order=order.id;c.state="ordered";begin(s,c,"food")
	s.message="Pedido anotado: "+RECIPES.data[c.recipe].name
	return true
func customer_access(s: Dictionary,a: Dictionary,c: Dictionary) -> Variant:
	var best: Variant = null
	var length := 2147483647
	for dir in MOVE.DIRS:
		var p := {"room":c.room,"x":c.x+dir.x,"y":c.y+dir.y}
		if MOVE.blocked(s,p.room,p.x,p.y,a):continue
		var path = MOVE.MAP.route(s,a.room,Vector2i(a.x,a.y),Vector2i(p.x,p.y),a)
		if path!=null and path.size()<length:best=p;length=path.size()
	return best
func ready_point(s: Dictionary,a: Dictionary) -> Variant:
	for o in s.objects:
		if o.type!="kitchen":continue
		var ordered := false
		for order in s.orders:
			if order.state=="ordered" and STORE.count(o,"dish_"+order.recipe)>0:ordered=true;break
		if ordered:
			var p = MOVE.closest(s,a,o)
			if p!=null:return p
	return null
func pickup(s: Dictionary,a: Dictionary) -> bool:
	if canceled(s,a):return return_canceled(s,a)
	if a.get("carry")!=null or a.get("motion")!=null:return false
	for prep in s.objects:
		if prep.type!="kitchen" or not object_near(s,a,prep):continue
		for order in s.orders:
			var item: String = "dish_"+order.recipe
			if order.state!="ordered" or STORE.count(prep,item)<=0:continue
			var quality := STORE.first_quality(prep,item)
			STORE.take(s,prep,item,1,quality);order.state="ready";a.carry={"kind":"dish","order":order.id,"quality":quality};return true
	return false
func serve(s: Dictionary,a: Dictionary,c: Variant) -> bool:
	if a.get("motion")!=null or c==null or c.state!="ordered" or expired(s,c) or not near(a,c):return false
	var order = find(s.orders,c.order)
	if order==null or order.state!="ready" or a.get("carry")==null or a.carry.get("order")!=order.id:return false
	finish(c);c.experience.servedQuality=a.carry.get("quality",0);order.quality=c.experience.servedQuality
	c.experience.satisfaction=null if c.experience.legacy else satisfaction(c.experience)
	c.experience.indicatorUntil=s.time+CONFIG.data.indicators.happySeconds;visual(s,c)
	order.state="eating";c.state="eating";c.timer=4;a.carry=null;s.message="Prato servido. O cliente paga depois de comer."
	return true
func hand_dish(s: Dictionary,a: Dictionary,c: Dictionary,p: Dictionary) -> void:
	find(s.orders,c.order).state="ready";a.carry={"kind":"dish","order":c.order,"quality":p.get("quality",0)}
func interact(s: Dictionary,id: Variant) -> bool:
	var a: Dictionary = s.player
	if a.get("motion")!=null:s.message="Aguarde o personagem se aproximar.";return false
	var c = find(s.customers,id)
	if c==null or not near(a,c):s.message="Aproxime-se da mesa.";return false
	if expired(s,c):return false
	if c.state=="waiting":return take_order(s,a,c)
	if c.state=="ordered":
		for actor in MOVE.ACTORS.actors(s):
			var delivery = actor.get("carry")
			if actor.id!=a.id and delivery!=null and delivery.kind=="dish" and delivery.order==c.order:
				s.message="Este pedido já está sendo levado à mesa.";return false
		var hand = a.get("hand")
		if hand!=null and hand.item=="dish_"+c.recipe:
			if a.get("carry")!=null:return false
			a.hand=null;hand_dish(s,a,c,hand);return serve(s,a,c)
		if canceled(s,a) and find(s.orders,a.carry.order).recipe==c.recipe:
			a.carry.order=c.order;find(s.orders,c.order).state="ready";return serve(s,a,c)
		if a.get("carry")!=null:
			if a.carry.kind=="dish" and a.carry.order==c.order:return serve(s,a,c)
			s.message="Entregue primeiro o prato que está na sua mão.";return false
		var item: String = "dish_"+c.recipe
		for index in s.inventory.size():
			var p = s.inventory[index]
			if p!=null and p.item==item:
				var quality: int = p.get("quality",0)
				INV.remove(s.inventory,index,1);find(s.orders,c.order).state="ready";a.carry={"kind":"dish","order":c.order,"quality":quality};return serve(s,a,c)
	s.message="Emprate a receita pedida e traga o prato pronto."
	return false
func idle_pause(s: Dictionary,w: Dictionary) -> void:
	MOVE.go(w,{"room":w.room,"x":w.x,"y":w.y,"idleWalk":true,"idleUntil":s.time+3+4*wander_random.call()})
	w.wait=0

func wander(s: Dictionary,w: Dictionary) -> void:
	if not idle_walk_enabled or w.id!="worker2" or w.room!="restaurant":w.goal=null;return
	var goal = w.get("goal")
	var returning: bool = w.x>=14
	if goal!=null and goal.get("idleWalk",false):
		if goal.has("idleUntil"):
			if s.time<goal.idleUntil:return
		elif not MOVE.arrived(w) and w.wait<5 and not MOVE.blocked(s,w.room,goal.x,goal.y,w):return
		else:
			if w.get("motion")!=null:return
			idle_pause(s,w);return
	elif not returning:
		if w.get("motion")!=null:w.goal=null;return
		idle_pause(s,w);return
	var occupied := MOVE.occupants(s,w)
	var avoid := MOVE.hall_limits(returning)
	for cell in occupied:
		var parts: PackedStringArray = cell.split(",")
		avoid.append(Vector2i(int(parts[0]),int(parts[1])))
	var candidates: Array[Vector2i] = []
	for y in range(1,14):
		for x in range(1,14):
			var distance: int = absi(x-int(w.x))+absi(y-int(w.y))
			if distance==0 or (not returning and (distance<2 or distance>4)) or MOVE.blocked(s,w.room,x,y,w) or occupied.has(str(x)+","+str(y)):continue
			candidates.append(Vector2i(x,y))
	if not candidates.is_empty():
		var reachable := MOVE.MAP.reachable(s,w.room,Vector2i(w.x,w.y),w,avoid)
		var start := mini(candidates.size()-1,int(wander_random.call()*candidates.size()))
		for i in candidates.size():
			var point: Vector2i = candidates[(start+i)%candidates.size()]
			if not reachable.has(point):continue
			var path = MOVE.MAP.route(s,w.room,Vector2i(w.x,w.y),point,w,avoid)
			if path==null or path.is_empty() or (not returning and path.size()>5):continue
			MOVE.go(w,{"room":"restaurant","x":point.x,"y":point.y,"idleWalk":true});w.wait=0;return
	idle_pause(s,w)

func note_order(s: Dictionary,w: Dictionary,c: Dictionary) -> void:
	if not timed_orders_enabled:take_order(s,w,c);return
	if w.get("motion")!=null:return
	w.goal=null
	if not w.has("noteJob"):w.noteJob={"customer":c.id,"left":1.2,"total":1.2}

func notes_step(s: Dictionary,dt: float) -> void:
	for w in s.workers:
		var job = w.get("noteJob")
		if job==null:continue
		var c = find(s.customers,job.customer)
		if w.task!="waiter" or w.get("carry")!=null or w.get("motion")!=null or c==null or c.state!="waiting" or not near(w,c):w.erase("noteJob");continue
		job.left=maxf(0,job.left-dt)
		if job.left<=1e-8:take_order(s,w,c);w.erase("noteJob")

func pending_service(s: Dictionary) -> bool:
	for c in s.customers:
		if c.state=="waiting":return true
	for order in s.orders:
		if order.state!="ordered":continue
		for object in s.objects:
			if object.type=="kitchen" and STORE.count(object,"dish_"+order.recipe)>0:return true
	return false

func cleanup(s: Dictionary,w: Dictionary) -> bool:
	var held := DISHES.held(w)
	if held==0:
		var dirty := false
		for amount in s.dirtyTables.values():
			if amount>0:dirty=true;break
		if not dirty:return clean_surfaces(s,w)
	if w.get("motion")!=null:return true
	var sink = DISHES.target(s,w,"sink")
	if sink==null:
		if held:w.goal=null
		return true if held>0 else clean_surfaces(s,w)
	var capacity := mini(INV.HAND_PLATE_CAPACITY,DISHES.sink_space(sink.object))
	if w.task=="waiter" and held<capacity and (held==0 or not pending_service(s)):
		var table = DISHES.target(s,w,"table")
		if table!=null:
			MOVE.go(w,table.point)
			if MOVE.arrived(w):DISHES.collect(s,w,table.object,capacity)
			return true
	if held:
		MOVE.go(w,sink.point)
		if MOVE.arrived(w):DISHES.deposit(s,w,sink.object)
		return true
	return false

func clean_surfaces(s: Dictionary,w: Dictionary) -> bool:
	if w.task!="waiter" or not HYGIENE.free_hands(s,w):return false
	if s.get("tableStains",{}).is_empty() and s.get("floorDirt",{}).is_empty():return false
	if w.get("motion")!=null:return true
	var target = HYGIENE.target(s,w)
	if target==null:return false
	MOVE.go(w,target.point)
	if MOVE.arrived(w):
		if target.kind=="wipe":HYGIENE.wipe(s,w,target.object)
		else:HYGIENE.mop(s,w,target.key)
	return true

func waiter(s: Dictionary,w: Dictionary) -> void:
	var carry = w.get("carry")
	if w.get("noteJob")!=null:
		var c = find(s.customers,w.noteJob.customer)
		if w.task=="waiter" and carry==null and c!=null and c.state=="waiting" and near(w,c):w.goal=null;return
		w.erase("noteJob")
	if carry!=null and carry.kind=="dirtyPlates":cleanup(s,w);return
	if w.task=="none" and carry==null:wander(s,w);return
	if carry!=null and carry.kind=="dish":
		if canceled(s,w):
			var item: String = "dish_"+find(s.orders,carry.order).recipe
			for prep in s.objects:
				if prep.type=="kitchen" and STORE.space(prep,item)>0:
					var p = MOVE.closest(s,w,prep)
					if p!=null:w.goal=p
					return_canceled(s,w);return
			w.goal=null;return
		var c: Variant = null
		for candidate in s.customers:
			if candidate.order==carry.order:c=candidate;break
		if c==null:w.goal=null;return
		var p = customer_access(s,w,c)
		if p==null:w.goal=null;return
		MOVE.go(w,p)
		if near(w,c):serve(s,w,c)
		return
	if carry!=null:return
	var ready = ready_point(s,w)
	if ready!=null:
		MOVE.go(w,ready)
		if MOVE.arrived(w):pickup(s,w)
		return
	var waiting: Array = []
	for c in s.customers:
		if c.state=="waiting":waiting.append(c)
	# Insertion sorting keeps equal-priority clients in their original order.
	for i in range(1,waiting.size()):
		var current = waiting[i]
		var priority: float = current.experience.limits.service-current.experience.elapsed.service
		var j := i
		while j>0 and waiting[j-1].experience.limits.service-waiting[j-1].experience.elapsed.service>priority:waiting[j]=waiting[j-1];j-=1
		waiting[j]=current
	for c in waiting:
		var p = customer_access(s,w,c)
		if p==null:continue
		MOVE.go(w,p)
		if near(w,c):note_order(s,w,c)
		return
	if not cleanup(s,w):wander(s,w)
func clients_step(s: Dictionary,dt: float) -> void:
	for order in s.orders:
		if order.state not in ["paid","lost"]:order.age+=dt
	for c in s.customers:
		if c.state=="walk" and MOVE.arrived(c):c.state="waiting";c.goal=null;begin(s,c,"service")
		if c.state=="eating":
			c.timer-=dt
			if c.timer<=0:
				HYGIENE.after_meal(s,c)
				var order = find(s.orders,c.order)
				order.state="paid";finalize(s,c,"completed");s.meals.eaten[order.recipe]+=1
				var seat: String = str(int(c.seat))
				s.dirtyTables[seat]=s.dirtyTables.get(seat,0)+1
				s.cash+=order.price;s.ledger.revenue+=order.price;s.ledger.sales+=1
				c.state="leave";MOVE.go(c,{"room":"restaurant","x":7,"y":14});s.message="Pagamento recebido: $"+str("%.2f"%order.price)
		if c.state=="leave" and MOVE.arrived(c):c.done=true
	s.customers=s.customers.filter(func(c):return not c.get("done",false))
func experience() -> Dictionary:
	var total := 0.0
	var entries: Array = []
	for id in CONFIG.data.profiles:
		var profile: Dictionary = CONFIG.data.profiles[id]
		if profile.weight>0:entries.append(id);total+=profile.weight
	var roll := draw()*total
	var selected: String = entries[-1]
	for id in entries:
		roll-=CONFIG.data.profiles[id].weight
		if roll<0:selected=id;break
	var profile: Dictionary = CONFIG.data.profiles[selected]
	return {"profile":selected,"limits":{"service":profile.service[0]+draw()*(profile.service[1]-profile.service[0]),"food":profile.food[0]+draw()*(profile.food[1]-profile.food[0])},"elapsed":{"service":0,"food":0},"phase":null,"visual":null,"results":{"service":null,"food":null},"satisfaction":null,"abandoned":false,"reviewResolved":false,"legacy":false,"indicatorUntil":null}
func indicator(s: Dictionary,c: Dictionary) -> Variant:
	var p = c.get("experience")
	if p==null:return null
	visual(s,c)
	if p.visual==null:return null
	return {"emoji":CONFIG.data.indicators.emoji[p.visual],"label":{"patient":"Paciente","impatient":"Perdendo a paciência","stressed":"Estressado","leaving":"Indo embora","happy":"Feliz"}[p.visual],"phase":p.phase,"remaining":maxf(0,p.limits[p.phase]-p.elapsed[p.phase]) if p.phase!=null else null,"ratio":ratio(p)}
func patience(s: Dictionary,dt: float) -> void:
	for c in s.customers:
		var p: Dictionary = c.experience
		if p.phase!=null:p.elapsed[p.phase]=minf(p.limits[p.phase],p.elapsed[p.phase]+dt);expired(s,c)
		visual(s,c)
