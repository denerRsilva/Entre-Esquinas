extends RefCounted
const STORAGE = preload("res://simulacao/nativa/Armazenamento.gd")
const ITEMS = preload("res://simulacao/nativa/itens.json")
const RECIPES = preload("res://simulacao/nativa/receitas.json")

static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value) and value==floor(value)

static func actors(state: Dictionary) -> Array:
	var result: Array = [state.player]
	result.append_array(state.workers)
	result.append_array(state.residents)
	for customer in state.customers:
		if not customer.get("done",false):result.append(customer)
	return result

static func locations(state: Dictionary) -> Array:
	var result: Array = [state.inventory,[state.player.hand] if state.player.get("hand") else [],state.get("recovery",[])]
	for object in state.objects:result.append(STORAGE.slots(object))
	return result

static func food(state: Dictionary) -> bool:
	var all_locations := locations(state)
	for raw in ["arroz","legumes","frango"]:
		var total: float = state.inv.receiving[raw]+state.used[raw]
		for delivery in state.deliveries:
			if delivery.food==raw:total+=delivery.pending
		for container in all_locations:
			for portion in container:
				if portion!=null and ITEMS.data.get(portion.item,{}).get("raw",portion.item)==raw:total+=portion.n
		for actor in actors(state):
			var carry = actor.get("carry")
			if carry!=null and carry.kind=="food" and carry.food==raw:total+=carry.n
		if total!=state.purchased[raw]:return false
	return true

static func equipment(state: Dictionary) -> bool:
	var sums := {"pot":0.0,"spoon":0.0,"plate":0.0}
	for container in locations(state):
		for portion in container:
			if portion==null:continue
			var item: String = portion.item
			if item in ["pot","cookingPot"] or item.begins_with("pot_"):sums.pot+=portion.n
			elif item=="spoon":sums.spoon+=portion.n
			elif item in ["plate","dirtyPlate"] or item.begins_with("dish_"):sums.plate+=portion.n
	for actor in actors(state):
		var carry = actor.get("carry")
		if carry!=null and carry.kind=="dish":sums.plate+=1
		elif carry!=null and carry.kind=="dirtyPlates":sums.plate+=carry.n
	for customer in state.customers:
		if customer.state=="eating":sums.plate+=1
	for id in state.dirtyTables:
		var amount = state.dirtyTables[id]
		if not integer(amount) or amount<0:return false
		var found := false
		if not str(id).is_valid_float():return false
		for object in state.objects:
			if object.id==str(id).to_float() and object.type=="chair":found=true;break
		if not found:return false
		sums.plate+=amount
	for item in sums:
		if not integer(state.equipment[item]) or state.equipment[item]<0 or sums[item]!=state.equipment[item]:return false
	return true

static func meals(state: Dictionary) -> bool:
	var all_locations := locations(state)
	for recipe in RECIPES.data:
		var total := 0.0
		for container in all_locations:
			for portion in container:
				if portion==null:continue
				var data: Dictionary = ITEMS.data.get(portion.item,{})
				if data.get("recipe")==recipe:total+=portion.n*data.get("servings",1)
		for actor in actors(state):
			var carry = actor.get("carry")
			if carry!=null and carry.kind=="dish":
				for order in state.orders:
					if order.id==carry.order:
						if order.recipe==recipe:total+=1
						break
		for customer in state.customers:
			if customer.state=="eating" and customer.recipe==recipe:total+=1
		for name in ["made","eaten","wasted"]:
			var amount = state.meals[name][recipe]
			if not integer(amount) or amount<0:return false
		if total+state.meals.eaten[recipe]+state.meals.wasted[recipe]!=state.meals.made[recipe]:return false
	var busy := 0.0
	for object in state.objects:
		for portion in STORAGE.slots(object):
			if portion!=null and portion.item=="cookingPot":busy+=portion.n
	if busy!=(1 if state.get("cooking") else 0):return false
	for portion in state.inventory:
		if portion!=null and portion.item=="cookingPot":return false
	return true
