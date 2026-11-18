extends RefCounted
## Shared refuge rules; pure state functions keep economics and UI in agreement.
const RECIPES = preload("res://simulacao/nativa/receitas.json")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
static func active(s: Dictionary) -> bool:return s.get("refuge") is Dictionary and s.refuge.get("balance") is Dictionary
static func initialize(s: Dictionary) -> void:
	if not s.get("refuge") is Dictionary or s.refuge.has("balance"):return
	s.refuge.balance={"version":1,"lateMinute":0,"lastRest":16,"staff":{}}
	# Existing orders keep their quote; only future menu prices enter the fair range.
	for id in s.prices:
		if RECIPES.data.has(id):s.prices[id]=clampf(s.prices[id],bounds(id).x,bounds(id).y)
static func bounds(id: String) -> Vector2:
	var base: float = RECIPES.data[id].price
	return Vector2(ceilf(base*0.8*4)/4,floorf(base*1.2*4)/4)
static func favorite(id: int) -> String:return ["caldoBatata","arrozCenoura","caldoBatata","canja","arrozCenoura","canja"][clampi(id-1,0,5)]
static func affordable(s: Dictionary,id: String,profile: String) -> bool:
	return s.prices[id]<=RECIPES.data[id].price*{"impatient":1.0,"normal":1.1,"patient":1.2}.get(profile,1.1)+0.00001
static func price_penalty(s: Dictionary,id: String) -> float:return clampf((s.prices[id]/RECIPES.data[id].price-1)*40,-8,8)
static func change(s: Dictionary,key: String,value: float) -> void:s.refuge.stats[key]=clampf(s.refuge.stats[key]+value,0,100)
static func meal(s: Dictionary,recipe: String,score: float) -> void:
	var population: int = s.refuge.residents.size()
	change(s,"food",RECIPES.data.get(recipe,{}).get("nutrition",5)*2.0/population)
	change(s,"morale",clampf((score-60)/10,-4,4)/population)
static func departure(s: Dictionary) -> void:
	if active(s) and s.period==1:s.refuge.balance.lateMinute=maxi(s.refuge.balance.lateMinute,int(s.clock.minute))
static func recovery(s: Dictionary) -> int:
	if not active(s):return 16 if s.refuge.stats.food>=40 else 8
	var minute: int = s.refuge.balance.lateMinute
	var rested := 16 if minute<=1320 else 12 if minute<=1380 else 8
	return mini(rested,8) if s.refuge.stats.food<40 else rested
static func interval(s: Dictionary) -> float:
	if not active(s):return 25
	var count: int = s.refuge.residents.size()-s.workers.size()
	var seconds: float = (s.serviceHours[int(s.period)].end-s.serviceHours[int(s.period)].start)*0.7
	return clampf(seconds*0.6/maxi(1,count-1),28,50)
static func staff_key(s: Dictionary,w: Dictionary) -> String:return str(int(s.period))+":"+str(w.id)
static func staff_step(s: Dictionary,w: Dictionary,dt: float) -> bool:
	if not active(s) or not w.has("refugeResident"):return false
	var job = w.get("mealBreak")
	if job!=null:
		if w.get("motion")!=null:return true
		w.goal=null;job.left=maxf(0,job.left-dt)
		if job.left>0:return true
		var recipe: String = job.dish.item.trim_prefix("dish_")
		meal(s,recipe,85);departure(s);s.meals.eaten[recipe]+=1
		var price: float = RECIPES.data[recipe].price
		s.cash+=price;s.ledger.revenue+=price;s.ledger.sales+=1;s.ledger["teamRevenue"]=s.ledger.get("teamRevenue",0)+price
		s.refuge.balance.staff[staff_key(s,w)]={"recipe":recipe,"price":price}
		w.erase("mealBreak");w.carry={"kind":"dirtyPlates","n":1}
		return true
	if (not s.open and not s.closing) or w.task!="waiter" or w.get("carry")!=null or w.has("noteJob") or s.refuge.balance.staff.has(staff_key(s,w)):return false
	# Service has priority. Only take a surplus portion, never a customer's plate.
	if s.customers.any(func(c):return c.state in ["walk","waiting"]):return false
	for station in s.objects:
		if station.type!="kitchen":continue
		for dish in station.get("dishes",{}):
			var recipe: String = dish.trim_prefix("dish_")
			if not s.menu.get(recipe,false):continue
			var reserved: int = s.orders.filter(func(o):return o.recipe==recipe and o.state=="ordered").size()
			if STORE.count(station,dish)<=reserved:continue
			var goal = w.get("goal")
			if w.get("motion")!=null and goal!=null and MOVE.access(s,station).any(func(p):return p.room==goal.room and p.x==goal.x and p.y==goal.y):return true
			var point = MOVE.closest(s,w,station)
			if point==null:continue
			MOVE.go(w,point)
			if MOVE.arrived(w) and w.get("motion")==null:
				var quality := STORE.first_quality(station,dish)
				STORE.take(s,station,dish,1,quality);w.goal=null
				w.mealBreak={"dish":{"item":dish,"n":1,"quality":quality},"left":4.0,"day":s.day,"period":s.period}
			return true
	return false
static func numeric(v: Variant) -> bool:return (v is float or v is int) and is_finite(v)
static func valid(s: Dictionary) -> bool:
	if not s.get("refuge") is Dictionary:return not s.workers.any(func(w):return w.has("mealBreak"))
	if not s.refuge.has("balance"):return not s.workers.any(func(w):return w.has("mealBreak"))
	var b = s.refuge.balance
	if not b is Dictionary or b.get("version")!=1 or not b.get("staff") is Dictionary or b.staff.size()>4:return false
	if not numeric(b.get("lateMinute")) or b.lateMinute<0 or b.lateMinute>1560 or b.lateMinute!=floor(b.lateMinute) or not numeric(b.get("lastRest")) or (b.lastRest!=8 and b.lastRest!=12 and b.lastRest!=16):return false
	for key in b.staff:
		if key not in ["0:worker1","0:worker2","1:worker1","1:worker2"]:return false
		var row = b.staff[key]
		if not row is Dictionary or not RECIPES.data.has(row.get("recipe")) or row.get("price")!=RECIPES.data[row.recipe].price:return false
	for w in s.workers:
		var j = w.get("mealBreak")
		if j==null:continue
		if (not s.open and not s.closing) or s.refuge.phase!="day" or not w.has("refugeResident") or not j is Dictionary or not j.get("dish") is Dictionary or j.get("day")!=s.day or j.get("period")!=s.period or not numeric(j.get("left")) or j.left<0 or j.left>4:return false
		if w.get("carry")!=null or w.has("noteJob") or b.staff.has(staff_key(s,w)):return false
		if j.dish.get("n")!=1 or not str(j.dish.get("item","")).begins_with("dish_") or not RECIPES.data.has(str(j.dish.item).trim_prefix("dish_")):return false
	for c in s.customers:
		for key in ["pricePenalty","preference"]:
			if c.experience.has(key) and (not numeric(c.experience[key]) or c.experience[key]<(-8 if key=="pricePenalty" else 0) or c.experience[key]>(8 if key=="pricePenalty" else 4)):return false
	return true
