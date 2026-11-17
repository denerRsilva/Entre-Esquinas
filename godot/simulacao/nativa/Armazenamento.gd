extends RefCounted
const INV = preload("res://simulacao/nativa/Inventario.gd")
const CATALOG = preload("res://simulacao/nativa/catalogo.json")

const READY_DISH_CAPACITY = 4
const CLEAN_PLATE_CAPACITY = 20
const PLATES_PER_STACK = 10
const SUPPORT_SURFACES = ["worktable","counterH","counterV","counterCorner"]
static func plating_surface(object: Dictionary) -> bool:
	var data: Dictionary = CATALOG.data.get(object.get("baseType",object.get("type")),{})
	return data.get("w")==CATALOG.data.prep.w and data.get("h")==CATALOG.data.prep.h
static func is_pot(item: String) -> bool:
	return item=="pot" or INV.ITEMS.data.get(item,{}).get("servings",0)>0
static func is_support_surface(object: Dictionary) -> bool:return object.get("type") in SUPPORT_SURFACES or CATALOG.data.get(object.get("type"),{}).has("counterPart")
static func surface_empty(object: Dictionary, ignore_support: bool = false) -> bool:
	if not is_support_surface(object) or object.get("tableKit","")!="":return false
	if not ignore_support and object.get("support")!=null:return false
	if object.get("pan")!=null or object.get("plates",0)!=0 or object.get("utensil",false)!=false:return false
	var dishes = object.get("dishes",{})
	if not dishes is Dictionary:return false
	for amount in dishes.values():
		if amount!=0:return false
	var ingredients = object.get("ingredients",[])
	if not ingredients is Array or not ingredients.is_empty():return false
	var inventory = object.get("inventory",[])
	if not inventory is Array:return false
	for item in inventory:
		if item!=null:return false
	return true

static func location(object: Dictionary) -> String:
	if object.type=="shelf":return "storage" if object.y>10 else "kitchen"
	return "storage" if object.type=="cold" else "kitchen"

static func accepts(object: Dictionary, item: String) -> bool:
	if not INV.ITEMS.data.has(item):return false
	if is_support_surface(object):return is_pot(item)
	match object.type:
		"potRack":return item=="pot"
		"stove":return item in ["pot","cookingPot"] or item.begins_with("pot_")
		"kitchen":return plating_surface(object) and (item in ["plate","spoon"] or item.begins_with("dish_"))
		"sink","bin":return false
		"fridge","cold":return item!="cookingPot"
	var food: Dictionary = INV.ITEMS.data.get(INV.ITEMS.data[item].get("raw",item),{})
	return food.get("kind")=="dry" and object.type=="shelf"

static func slots(object: Dictionary) -> Array:
	if object.type=="sink":
		var result: Array = []
		if object.get("dirtyPlates",0)>0:result.append({"item":"dirtyPlate","n":object.dirtyPlates})
		if object.get("cleanPlates",0)>0:result.append({"item":"plate","n":object.cleanPlates})
		return result
	if object.type=="stove":
		var result: Array = [{"item":object.pan,"n":1}] if object.get("pan") else []
		result.append_array(object.get("ingredients",[]))
		return result
	if object.type=="kitchen":
		var result: Array = [object.get("support"),{"item":"plate","n":object.plates} if object.get("plates",0) else null,{"item":"spoon","n":1} if object.get("utensil",false) else null]
		for item in object.get("dishes",{}):
			var amount = object.dishes[item]
			result.append({"item":item,"n":amount} if amount else null)
		return result
	return [object.support] if is_support_surface(object) and object.get("support")!=null else object.get("inventory",[])

static func count(object: Dictionary, item: String) -> int:
	return INV.count(slots(object),item)

static func ready_count(object: Dictionary) -> int:
	var total := 0
	for amount in object.get("dishes",{}).values():total+=int(amount)
	return total

static func space(object: Dictionary, item: String, quality: int = 0) -> int:
	if object.type=="kitchen" and not plating_surface(object):return 0
	if is_support_surface(object):return 1 if is_pot(item) and surface_empty(object) else 0
	match object.type:
		"potRack":return maxi(0,3-count(object,"pot")) if item=="pot" else 0
		"stove":return 1 if not object.get("pan") and object.get("ingredients",[]).is_empty() and (item in ["pot","cookingPot"] or item.begins_with("pot_")) else 0
		"kitchen":
			if item=="plate":return maxi(0,CLEAN_PLATE_CAPACITY-int(object.plates))
			if item=="spoon":return 0 if object.utensil else 1
			return maxi(0,READY_DISH_CAPACITY-ready_count(object)) if item.begins_with("dish_") and INV.ITEMS.data.has(item) else 0
	return INV.space(object.get("inventory",[]),item,quality) if accepts(object,item) else 0

static func quality_count(object: Dictionary, item: String, quality: int) -> int:
	if object.type=="kitchen":
		var counts: Array = object.get("dishQuality",{}).get(item,[0,0,0,0])
		if quality:return int(counts[quality])
		return count(object,item)-int(counts[1]+counts[2]+counts[3])
	var total := 0
	for slot in (slots(object) if is_support_surface(object) else object.get("inventory",[])):
		if slot!=null and slot.item==item and slot.get("quality",0)==quality:total+=int(slot.n)
	return total

static func first_quality(object: Dictionary, item: String) -> int:
	for quality in 4:
		if quality_count(object,item,quality)>0:return quality
	return 0

static func sync(state: Dictionary) -> void:
	for loc in ["storage","kitchen"]:
		for food in INV.RAWS:
			var total := 0
			for object in state.objects:
				if object.has("inventory") and location(object)==loc:total+=count(object,food)
			if total>0 or state.inv[loc].has(food):state.inv[loc][food]=total

static func put(state: Dictionary, object: Dictionary, item: String, quantity: Variant, quality: int = 0) -> int:
	if not (quantity is int or quantity is float) or not is_finite(quantity) or quantity!=floor(quantity) or quantity<1 or not INV.ITEMS.data.has(item):return 0
	var amount := mini(int(quantity),space(object,item,quality))
	if amount==0:return 0
	match object.type:
		"potRack":
			var left := amount
			for index in object.inventory.size():
				if left and object.inventory[index]==null:
					object.inventory[index]={"item":"pot","n":1}
					if quality:object.inventory[index].quality=quality
					left-=1
		"stove":object.pan=item
		"kitchen":
			if item=="plate":object.plates+=amount
			elif item=="spoon":object.utensil=true
			else:
				object.dishes[item]=object.dishes.get(item,0)+amount
				if quality:
					if not object.has("dishQuality"):object.dishQuality={}
					if not object.dishQuality.has(item):object.dishQuality[item]=[0,0,0,0]
					object.dishQuality[item][quality]+=amount
		_:
			if is_support_surface(object):object.support={"item":item,"n":1,"quality":quality}
			else:INV.add(object.inventory,item,amount,quality)
	sync(state)
	return amount

static func take(state: Dictionary, object: Dictionary, item: String, quantity: float, quality: Variant = null) -> float:
	var available := count(object,item) if quality==null else quality_count(object,item,quality)
	var total := minf(quantity,available)
	if total==0:return 0
	match object.type:
		"stove":object.pan=null
		"kitchen":
			if item=="plate":object.plates-=total
			elif item=="spoon":object.utensil=false
			else:
				var common := quality_count(object,item,0)
				object.dishes[item]=object.dishes[item]-total if object.dishes.has(item) else null
				var left := total
				for q in 4:
					if left==0:break
					if quality!=null and q!=quality:continue
					var available_quality: float = common if q==0 else object.get("dishQuality",{}).get(item,[0,0,0,0])[q]
					var taken := minf(left,available_quality)
					if q:object.dishQuality[item][q]-=taken
					left-=taken
		_:
			if is_support_surface(object):
				object.erase("support");sync(state);return total
			var left := total
			for index in mini(10,object.inventory.size()):
				if left==0:break
				var slot = object.inventory[index]
				if slot!=null and slot.item==item and (quality==null or slot.get("quality",0)==quality):
					var amount := minf(left,slot.n)
					if amount==floor(amount):INV.remove(object.inventory,index,int(amount))
					left-=amount
	sync(state)
	return total

static func capacity(state: Dictionary, loc: String, food: String) -> int:
	if loc=="receiving":return 60
	var total := 0
	for object in state.objects:
		if object.has("inventory") and location(object)==loc and accepts(object,food):total+=990
	return total

static func amount(state: Dictionary, loc: String, food: String) -> int:
	var total := 0
	if loc=="receiving":
		for value in state.inv.receiving.values():total+=int(value)
	else:
		for object in state.objects:
			if object.has("inventory") and location(object)==loc and accepts(object,food):
				for slot in object.inventory:
					if slot!=null:total+=int(slot.n)
	return total
