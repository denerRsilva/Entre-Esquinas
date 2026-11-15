extends RefCounted
const INV = preload("res://simulacao/nativa/Inventario.gd")
const STORAGE = preload("res://simulacao/nativa/Armazenamento.gd")
const RECIPES = preload("res://simulacao/nativa/receitas.json")

static func recover(state: Dictionary) -> Dictionary:
	var count := 0
	for portion in state.get("recovery",[]):
		var quality := int(portion.get("quality",0))
		var amount := mini(int(portion.n),INV.space(state.inventory,portion.item,quality))
		if amount:
			INV.add(state.inventory,portion.item,amount,quality,portion.get("burned",false))
			portion.n-=amount
			count+=amount
	state.recovery=state.recovery.filter(func(p):return p.n>0)
	var message := str(count)+" itens preservados recolhidos." if count else "Libere espaço na mochila."
	state.message=message
	return {"ok":count!=0,"error":null if count else message,"message":message}

static func kitchen(state: Dictionary) -> void:
	if state.get("recovery")==null:state.recovery=[]
	if not state.get("plating"):state.plating=null
	for object in state.objects:
		if object.type not in ["stove","kitchen"] or not object.has("inventory") or object.inventory==null:continue
		var items: Array = []
		for portion in object.inventory:
			if portion!=null:items.append(portion.duplicate(true))
		object.erase("inventory")
		if object.type=="stove":
			var selected: Variant = null
			for kind in ["cookingPot","full","pot"]:
				for portion in items:
					if (kind=="full" and str(portion.item).begins_with("pot_")) or portion.item==kind:
						selected=portion
						break
				if selected!=null:break
			object.pan=selected.item if selected!=null else null
			if selected!=null:selected.n-=1
		else:
			object.plates=0
			object.utensil=false
			object.dishes={}
			for portion in items:
				if portion.item=="plate":
					var amount := mini(int(portion.n),99)
					object.plates=amount
					portion.n-=amount
				if portion.item=="spoon" and not object.utensil:object.utensil=true;portion.n-=1
				if str(portion.item).begins_with("dish_"):
					var amount := mini(int(portion.n),12-STORAGE.ready_count(object))
					object.dishes[portion.item]=amount
					portion.n-=amount
		for portion in items:
			if portion.n>0:state.recovery.append(portion)
	if not state.recovery.is_empty():recover(state)
	if state.get("cooking"):
		state.cooking.erase("slot")
		state.cooking.total=RECIPES.data.get(state.cooking.recipe,{}).get("time")
	STORAGE.sync(state)
	state.version=12

static func cleaning(state: Dictionary) -> void:
	for object in state.objects:
		if object.type not in ["sink","bin"] or not object.has("inventory") or object.inventory==null:continue
		for portion in object.inventory:
			if portion!=null:state.recovery.append(portion.duplicate(true))
		object.erase("inventory")
	if not state.recovery.is_empty():recover(state)
	STORAGE.sync(state)
	state.version=12

static func physical(state: Dictionary, source_version: int) -> void:
	if source_version<10:
		for object in state.objects:
			if object.type=="prep":object.type="kitchen"
		if state.get("plating"):state.plating=null
		state.chopping=null
	for object in state.objects:
		if object.type=="stove" and object.get("ingredients")==null:object.ingredients=[]
	state.version=12

static func hands(state: Dictionary) -> bool:
	var preserved: Array = []
	for portion in state.inventory:
		if portion!=null:preserved.append(portion)
	preserved.append_array(state.recovery)
	var carry = state.player.get("carry")
	if carry!=null and carry.kind=="food":
		preserved.append({"item":carry.food,"n":carry.n,"quality":carry.get("quality",0)})
		state.player.carry=null
	elif carry!=null and carry.kind=="dish":
		var order: Variant = null
		for candidate in state.orders:
			if candidate.id==carry.order:order=candidate;break
		if order==null:return false
		state.player.hand={"item":"dish_"+order.recipe,"n":1,"quality":carry.get("quality",0)}
		state.player.carry=null
		if order.state=="ready":order.state="ordered"
	state.inventory=[]
	state.selectedSlot=0
	state.recovery=[]
	for portion in preserved:
		var left := int(portion.n)
		var quality := int(portion.get("quality",0))
		for object in state.objects:
			if not object.has("inventory") or not STORAGE.accepts(object,portion.item):continue
			var amount := mini(left,STORAGE.space(object,portion.item,quality))
			if amount:
				var added: bool
				if object.type=="potRack":added=STORAGE.put(state,object,portion.item,amount,quality)==amount
				else:added=INV.add(object.inventory,portion.item,amount,quality,portion.get("burned",false))
				if added:left-=amount
			if left==0:break
		if left:
			var remainder: Dictionary = portion.duplicate(true)
			remainder.n=left
			state.recovery.append(remainder)
	STORAGE.sync(state)
	return true

# Preserve every plate from older saves whose stations could hold 99 units.
static func plate_capacity(state: Dictionary) -> void:
	for object in state.objects:
		if object.type!="kitchen":continue
		var count = object.get("plates")
		if not (count is int or count is float) or not is_finite(count) or count!=floor(count) or count<=STORAGE.CLEAN_PLATE_CAPACITY or count>99:continue
		var excess := int(count)-STORAGE.CLEAN_PLATE_CAPACITY
		object.plates=STORAGE.CLEAN_PLATE_CAPACITY
		for receiver in state.objects:
			if not receiver.has("inventory") or not STORAGE.accepts(receiver,"plate"):continue
			var amount := mini(excess,INV.space(receiver.inventory,"plate"))
			if amount>0 and INV.add(receiver.inventory,"plate",amount):excess-=amount
			if excess==0:break
		if excess>0:state.recovery.append({"item":"plate","n":excess})

# Older stations held twelve served dishes. Keep four on the tabletop and
# preserve the remainder, with its quality, in storage or item recovery.
static func ready_capacity(state: Dictionary) -> bool:
	var num = preload("res://simulacao/nativa/Conservacao.gd")
	var quality = preload("res://simulacao/nativa/Qualidade.gd")
	for object in state.objects:
		if object.type!="kitchen":continue
		if not object.get("dishes") is Dictionary or not object.get("dishQuality",{}) is Dictionary:return false
		for item in object.dishes:
			if not str(item).begins_with("dish_") or not INV.ITEMS.data.has(item) or not num.integer(object.dishes[item]) or object.dishes[item]<0:return false
		for item in object.get("dishQuality",{}):
			var counts = object.dishQuality[item]
			if not object.dishes.has(item) or not quality.counts_valid(counts) or counts[1]+counts[2]+counts[3]>object.dishes[item]:return false
		if STORAGE.ready_count(object)>12:return false
		var free := STORAGE.READY_DISH_CAPACITY
		for item in object.dishes.keys():
			for tier in 4:
				var count := STORAGE.quality_count(object,item,tier)
				var kept := mini(free,count)
				free-=kept
				var excess := count-kept
				if excess==0:continue
				STORAGE.take(state,object,item,excess,tier)
				for receiver in state.objects:
					if not receiver.has("inventory") or not STORAGE.accepts(receiver,item):continue
					var amount := mini(excess,INV.space(receiver.inventory,item,tier))
					if amount>0 and INV.add(receiver.inventory,item,amount,tier):excess-=amount
					if excess==0:break
				while excess>0:
					var amount := mini(excess,INV.limit(item))
					state.recovery.append({"item":item,"n":amount,"quality":tier})
					excess-=amount
	return true
