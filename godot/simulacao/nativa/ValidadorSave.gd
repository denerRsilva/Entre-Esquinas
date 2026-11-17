extends RefCounted
const N = preload("res://simulacao/nativa/Conservacao.gd")
const Q = preload("res://simulacao/nativa/Qualidade.gd")
const K = preload("res://simulacao/nativa/EstadoCozinha.gd")
const A = preload("res://simulacao/nativa/Administracao.gd")
const M = preload("res://simulacao/nativa/Movimento.gd")
const S = preload("res://simulacao/nativa/Armazenamento.gd")
const ITEMS = preload("res://simulacao/nativa/itens.json")
const RECIPES = preload("res://simulacao/nativa/receitas.json")
const CATALOG = preload("res://simulacao/nativa/catalogo.json")
const CLIENTS = preload("res://simulacao/nativa/clientes.json")
const HYGIENE = preload("res://simulacao/nativa/Higiene.gd")
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
static func has_keys(d: Variant,keys: Array) -> bool:
	if not d is Dictionary:return false
	for key in keys:
		if not d.has(key):return false
	return true
static func score(v: Variant) -> bool:
	if v==null:return true
	if not has_keys(v,["score","classification","quality"]) or not number(v.score) or v.score<0 or v.score>100:return false
	if v.classification not in ["verySatisfied","satisfied","neutral","unsatisfied"]:return false
	return v.quality==null or (number(v.quality) and v.quality>=0 and v.quality<=3)
static func experience_data(p: Variant) -> bool:
	if not has_keys(p,["profile","limits","elapsed","results","satisfaction"]) or not CLIENTS.data.profiles.has(p.profile):return false
	if p.has("arrivalIssue") and p.arrivalIssue not in ["dirtySeat","dirtyDiningRoom"]:return false
	for phase in ["service","food"]:
		if not has_keys(p.limits,[phase]) or not has_keys(p.elapsed,[phase]) or not has_keys(p.results,[phase]):return false
		if not number(p.limits[phase]) or p.limits[phase]<=0 or not number(p.elapsed[phase]) or p.elapsed[phase]<0 or p.elapsed[phase]>p.limits[phase]:return false
		if p.results[phase]!=null and (not number(p.results[phase]) or p.results[phase]<0 or p.results[phase]>1):return false
	return score(p.satisfaction)
static func experience(s: Dictionary) -> bool:
	var history = s.get("experience")
	if not has_keys(history,["visits","events"]) or not history.visits is Array or not history.events is Array:return false
	var visits := {};var events := {};var customers := {}
	for v in history.visits:
		if not experience_data(v) or not has_keys(v,["id","outcome","time","day","period"]):return false
		if not v.id is String or visits.has(v.id) or v.outcome not in ["completed","abandoned"] or not number(v.time) or v.time>s.time or not N.integer(v.day) or v.day<1 or (not number(v.period) or (v.period!=0 and v.period!=1)):return false
		visits[v.id]=v
	for e in history.events:
		if not has_keys(e,["outcome","type","visitId","time"]):return false
		if (e.outcome=="abandoned" and e.type=="praise") or not visits.has(e.visitId) or events.has(e.visitId) or e.type not in ["praise","complaint"] or not number(e.time) or e.time>s.time or visits[e.visitId].outcome!=e.outcome:return false
		events[e.visitId]=true
	for c in s.customers:
		var p = c.get("experience")
		if not experience_data(p) or customers.has(c.id) or not has_keys(p,["phase","visual","abandoned","reviewResolved","legacy","indicatorUntil"]):return false
		customers[c.id]=true
		if p.phase not in [null,"service","food"] or p.visual not in [null,"patient","impatient","stressed","leaving","happy"]:return false
		if not p.abandoned is bool or not p.reviewResolved is bool or not p.legacy is bool:return false
		if p.indicatorUntil!=null and (not number(p.indicatorUntil) or p.indicatorUntil<0):return false
		var expected: Variant = "service" if c.state=="waiting" else "food" if c.state=="ordered" else null
		if p.phase!=expected or (p.abandoned and c.state!="leave"):return false
		if p.phase!=null and p.elapsed[p.phase]>=p.limits[p.phase]:return false
		if not p.reviewResolved and visits.has(c.id):return false
		if not p.legacy and ((c.state=="ordered" and p.results.service==null) or (c.state=="eating" and p.satisfaction==null)):return false
	return true
static func valid(value: Variant,slots: int = 0) -> bool:
	if not value is Dictionary:return false
	var s: Dictionary = value
	for key in ["objects","inventory","workers","residents","customers","orders","deliveries","ready","reports","recovery"]:
		if not s.get(key) is Array:return false
	for key in ["player","inv","equipment","meals","purchased","used","prices","menu","ledger","friends","tools","dirtyTables","clock","reputation"]:
		if not s.get(key) is Dictionary:return false
	if s.get("singleRoom",false) and not s.get("compact",false):return false
	if s.has("waiterDefaultApplied") and not s.waiterDefaultApplied is bool:return false
	for key in ["compact","singleRoom"]:
		if s.has(key) and not s[key] is bool:return false
	if s.get("version")!=12 or not number(s.get("cash")) or not N.integer(s.get("day")) or s.day<1 or (not number(s.get("period")) or (s.period!=0 and s.period!=1)) or not number(s.get("time")):return false
	var hiring = preload("res://simulacao/nativa/Contratacao.gd")
	if not hiring.valid(s):return false
	var expected_workers: int = s.refuge.hiring.hires.size() if hiring.active(s) else 1 if s.get("singleRoom",false) else 2
	if s.objects.size()>180 or s.orders.size()>5000 or s.customers.size()>50 or s.workers.size()!=expected_workers:return false
	if s.residents.size()!=3 or not N.integer(s.get("serial")) or s.serial<1 or not s.get("open") is bool or not s.get("closing") is bool or not number(s.get("tick")) or not number(s.get("arrival")):return false
	if not s.tools.get("pot") is bool or not s.tools.get("spoon") is bool:return false
	for v in s.ledger.values():
		if not number(v):return false
	for id in ["lia","beto","nina"]:
		if not N.integer(s.friends.get(id)) or s.friends[id]<0:return false
	for key in ["pot","plate","spoon"]:
		if not N.integer(s.equipment.get(key)) or s.equipment[key]<0:return false
	for name in ["made","eaten","wasted"]:
		if not has_keys(s.meals.get(name),["arrozLegumes","sopa","frangoArroz"]):return false
	for loc in ["receiving","storage","kitchen"]:
		if not has_keys(s.inv.get(loc),["arroz","legumes","frango"]):return false
		for food in K.INV.RAWS:
			if not N.integer(s.inv[loc].get(food,0)) or s.inv[loc].get(food,0)<0:return false
	var ids := {};var occupied := {}
	for o in s.objects:
		if not has_keys(o,["id","type","room","x","y","rot"]) or not CATALOG.data.has(o.type):return false
		if o.type in ["cuttingKit","platingKit"]:return false
		if o.has("tableKit") and (o.type not in ["prep","kitchen"] or o.tableKit!={"prep":"cuttingKit","kitchen":"platingKit"}[o.type]):return false
		if o.type=="worktable":
			for key in ["plates","utensil","dishes","dishQuality","inventory"]:
				if o.has(key):return false
		if not N.integer(o.id) or ids.has(o.id) or not N.integer(o.x) or not N.integer(o.y) or not N.integer(o.rot) or o.rot<0 or o.rot>3 or o.room!=CATALOG.data[o.type].room:return false
		if o.has("baseType") and (o.baseType not in ["worktable","counterH","counterV","counterCorner"] or o.type not in ["prep","kitchen"] or not o.has("tableKit")):return false
		ids[o.id]=o
		var rect := M.MAP.rect(o)
		for y in range(rect.position.y,rect.end.y):
			for x in range(rect.position.x,rect.end.x):
				if M.MAP.wall(o.room,x,y,s) or M.MAP.fixed(o.room,x,y,s):return false
				var key: String = o.room+":"+str(x)+","+str(y)
				if occupied.has(key):return false
				occupied[key]=true
		if o.type in ["shelf","cold","fridge","potRack"]:
			if not o.get("inventory") is Array or o.inventory.size()!=(3 if o.type=="potRack" else 10):return false
			for p in o.inventory:
				if p!=null and (not K.stack(p) or not S.accepts(o,p.item) or (o.type=="potRack" and p.n!=1)):return false
	if s.inventory.size()!=slots or not N.integer(s.get("selectedSlot")) or s.selectedSlot<0 or s.selectedSlot>=maxi(1,slots):return false
	for p in s.inventory:
		if p!=null and not K.stack(p):return false
	for p in s.recovery:
		if not K.stack(p):return false
	for o in s.objects:
		if o.type=="stove" and not o.get("ingredients",[]) is Array:return false
		for p in o.get("ingredients",[]):
			if not K.stack(p):return false
		if o.get("support")!=null and not K.stack(o.support):return false
	var order_ids := {}
	for o in s.orders:
		if not has_keys(o,["id","recipe","customer","state","price","age"]) or not N.integer(o.id) or order_ids.has(o.id) or not RECIPES.data.has(o.recipe) or o.state not in ["ordered","cooking","ready","eating","paid","lost"]:return false
		if not number(o.price) or o.price<1 or not number(o.age) or o.age<0:return false
		order_ids[o.id]=o
	var ready_ids := {}
	for id in s.ready:
		if ready_ids.has(id) or not order_ids.has(id) or order_ids[id].state!="ready":return false
		ready_ids[id]=true
	for c in s.customers:
		if not has_keys(c,["id","recipe","state","seat","order"]) or not RECIPES.data.has(c.recipe) or c.state not in ["walk","waiting","ordered","eating","leave"] or not ids.has(c.seat) or ids[c.seat].type!="chair":return false
		if c.order!=null and (not order_ids.has(c.order) or order_ids[c.order].customer!=c.id):return false
	var reservations := {};var persons := {}
	for a in N.actors(s):
		if not has_keys(a,["id","room","x","y","wait","hold"]) or not M.PORTALS.has(a.room) or not N.integer(a.x) or not N.integer(a.y) or a.x<1 or a.x>=23 or a.y<1 or a.y>=15:return false
		if M.blocked(s,a.room,a.x,a.y,a) or not number(a.hold) or not number(a.wait):return false
		if s.workers.has(a) and a.get("task") not in ["none","logistics","waiter"]:return false
		if a.has("noteJob"):
			var note = a.noteJob
			if (not s.workers.has(a) and a!=s.player) or not has_keys(note,["customer","left","total"]) or not note.customer is String or not number(note.left) or not number(note.total) or note.total!=1.2 or note.left<0 or note.left>note.total:return false
			if a==s.player and not s.customers.any(func(c):return c.id==note.customer and c.state=="waiting"):return false
		var goal = a.get("goal")
		if goal!=null:
			if goal is Dictionary and goal.has("idleWalk") and not goal.idleWalk is bool:return false
			if goal is Dictionary and goal.has("idleUntil") and (not number(goal.idleUntil) or goal.idleUntil<0):return false
			if not has_keys(goal,["room","x","y"]) or not M.PORTALS.has(goal.room) or not N.integer(goal.x) or not N.integer(goal.y) or goal.x<1 or goal.x>=23 or goal.y<1 or goal.y>=15:return false
			for key in ["offsetX","offsetY"]:
				if goal.has(key) and (not number(goal[key]) or absf(goal[key])>0.25):return false
		var motion = a.get("motion")
		if motion!=null:
			if not motion is Dictionary:return false
			for key in ["fromX","fromY","toX","toY","duration","elapsed","x","y"]:
				if not number(motion.get(key)):return false
			if motion.duration<=0 or motion.duration>M.walk_time(a)*3 or motion.elapsed<0 or motion.elapsed>=motion.duration or not N.integer(motion.x) or not N.integer(motion.y):return false
			if absf(motion.x-a.x)>1 or absf(motion.y-a.y)>1 or absf(motion.toX-motion.x)>0.25 or absf(motion.toY-motion.y)>0.25 or M.blocked(s,a.room,motion.x,motion.y,a):return false
		var settled = a.get("settled")
		if settled!=null:
			if not settled is Dictionary:return false
			for key in ["x","y","px","py"]:
				if not number(settled.get(key)):return false
		var carry = a.get("carry")
		if carry!=null:
			if not carry is Dictionary or carry.get("kind") not in ["food","dish","dirtyPlates"]:return false
			if carry.kind=="dirtyPlates" and (not s.workers.has(a) or not N.integer(carry.get("n")) or carry.n<1 or carry.n>K.INV.HAND_PLATE_CAPACITY):return false
			if carry.kind=="dish" and (not order_ids.has(carry.get("order")) or order_ids[carry.order].state not in ["ready","lost"]):return false
			if carry.kind=="food" and (carry.get("food") not in K.INV.RAWS or not N.integer(carry.get("n")) or carry.n<1):return false
		var key: String = a.room+":"+M.key(a)
		if persons.has(key):return false
		persons[key]=true
		for p in M.reserved(a):
			key=a.room+":"+M.key(p)
			if reservations.has(key) and reservations[key]!=a.id:return false
			reservations[key]=a.id
	if s.player.get("hand")!=null and not K.stack(s.player.hand,true):return false
	for d in s.deliveries:
		if not has_keys(d,["food","total","pending","received","eta"]) or d.food not in K.INV.RAWS or not N.integer(d.total) or d.total<1:return false
		if not number(d.pending) or not number(d.received) or d.pending<0 or d.received<0 or d.total!=d.pending+d.received or not number(d.eta):return false
	for food in K.INV.RAWS:
		if not N.integer(s.purchased.get(food,0)) or not N.integer(s.used.get(food,0)) or s.purchased.get(food,0)<0 or s.used.get(food,0)<0:return false
	for recipe in RECIPES.data:
		if RECIPES.data[recipe].get("early",false) and not s.has("startKit") and not s.menu.has(recipe) and not s.prices.has(recipe):continue
		if not number(s.prices.get(recipe)) or s.prices[recipe]<1 or s.prices[recipe]>100 or not s.menu.get(recipe) is bool:return false
	for loc in ["storage","kitchen"]:
		for food in K.INV.RAWS:
			var count := 0
			for o in s.objects:
				if o.has("inventory") and S.location(o)==loc:count+=S.count(o,food)
			if s.inv[loc].get(food,0)!=count:return false
	for loc in s.inv:
		for food in K.INV.RAWS:
			if S.amount(s,loc,food)>S.capacity(s,loc,food):return false
	var cooking = s.get("cooking")
	if cooking!=null:
		if not cooking is Dictionary or not RECIPES.data.has(cooking.get("recipe")) or not ids.has(cooking.get("stove")) or ids[cooking.stove].type!="stove" or ids[cooking.stove].get("pan")!="cookingPot" or not number(cooking.get("left")) or cooking.left<0:return false
	return preload("res://simulacao/nativa/Inicio.gd").valid(s) and preload("res://simulacao/nativa/Mercado.gd").valid(s) and preload("res://simulacao/nativa/Refugio.gd").valid(s) and HYGIENE.valid(s) and K.valid(s) and Q.valid(s) and experience(s) and A.valid_time_reputation(s) and N.food(s) and N.equipment(s) and N.meals(s)
