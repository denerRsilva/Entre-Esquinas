extends RefCounted
const INV = preload("res://simulacao/nativa/Inventario.gd")
const STORAGE = preload("res://simulacao/nativa/Armazenamento.gd")
const NUM = preload("res://simulacao/nativa/Conservacao.gd")
const RECIPES = preload("res://simulacao/nativa/receitas.json")

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func truthy(value: Variant) -> bool:
	if value is Dictionary or value is Array:return true
	if value==null:return false
	if value is bool:return value
	if value is String:return not value.is_empty()
	if value is int or value is float:return value!=0 and not is_nan(value)
	return true

static func stack(value: Variant, hand: bool = false) -> bool:
	if not value is Dictionary or not INV.ITEMS.data.has(value.get("item")):return false
	var count = value.get("n")
	if not NUM.integer(count) or count<1 or count>INV.limit(value.item):return false
	if hand:
		var quality = value.get("quality",0)
		return count<=(INV.HAND_PLATE_CAPACITY if value.item in ["plate","dirtyPlate"] else 1) and NUM.integer(quality) and quality>=0 and quality<=3
	return true

static func physical(state: Dictionary) -> bool:
	var hand = state.player.get("hand")
	if truthy(hand) and (not stack(hand,true) or hand.item=="cookingPot"):return false
	if truthy(hand) and truthy(state.player.get("carry")):return false
	var washing = state.get("washing")
	if washing!=null:
		if not washing is Dictionary or not NUM.integer(washing.get("sink")) or not numeric(washing.get("left")) or not numeric(washing.get("total")):return false
		if washing.total!=INV.DISH_WASH_TIME or washing.left<0 or washing.left>washing.total:return false
		if not NUM.integer(washing.get("plate")) or washing.plate<0 or washing.plate>=INV.CLEAN_SINK_CAPACITY:return false
		if hand!=null or state.player.get("carry")!=null or state.get("chopping")!=null or state.get("plating")!=null:return false
		var found := false
		for object in state.objects:
			if object.id==washing.sink and object.type=="sink":
				found=true
				if object.get("dirtyPlates",0)<=0 or object.get("cleanPlates",0)>=INV.CLEAN_SINK_CAPACITY or washing.plate>object.get("cleanPlates",0):return false
		if not found:return false
	for object in state.objects:
		if object.type=="stove":
			var ingredients = object.get("ingredients")
			if not ingredients is Array:return false
			for portion in ingredients:
				if not stack(portion,true) or portion.item not in ["arroz","legumes_cut","frango_cut"]:return false
			if not ingredients.is_empty() and object.get("pan")!="pot":return false
		var support = object.get("support")
		if truthy(support):
			if object.type!="kitchen" and not STORAGE.is_support_surface(object):return false
			if not stack(support,true):return false
			if STORAGE.is_support_surface(object) and not STORAGE.surface_empty(object,true):return false
			if support.item!="pot" and not INV.ITEMS.data[support.item].get("servings",0):return false
	var job = state.get("chopping")
	if truthy(job):
		if not job is Dictionary:return false
		var found := false
		for object in state.objects:
			if object.id==job.get("table") and object.type=="prep":found=true
		if not found or job.get("item") not in ["frango","legumes"]:return false
		var portion: Variant = null
		if truthy(job.get("hand")):portion=hand
		else:
			var index = job.get("index")
			if NUM.integer(index) and index>=0 and index<state.inventory.size():portion=state.inventory[int(index)]
		if not portion is Dictionary or portion.get("item")!=job.item:return false
		if not numeric(job.get("left")) or job.left<0 or not numeric(job.get("total")) or job.left>job.total or job.total!=preload("res://simulacao/nativa/Refugio.gd").cut_time(state):return false
	var plating = state.get("plating")
	if truthy(plating):
		if not plating is Dictionary:return false
		if plating.has("hand") and not plating.hand is bool:return false
		if plating.get("hand",false):
			var data: Dictionary = INV.ITEMS.data.get(plating.get("item"),{})
			if data.get("servings",0)<1 or plating.get("recipe")!=data.get("recipe") or plating.get("portions")!=data.get("servings"):return false
			if not NUM.integer(plating.get("quality")) or plating.quality<0 or plating.quality>3 or hand==null or plating.quality!=hand.get("quality",0) or hand.get("burned",false):return false
		var found := false
		for object in state.objects:
			var support = hand if plating.get("hand",false) else object.get("support")
			if object.id==plating.get("prep") and object.type=="kitchen" and support is Dictionary and support.get("item")==plating.get("item"):found=true
		if not found or not RECIPES.data.has(plating.get("recipe")) or not numeric(plating.get("count")) or plating.count!=(INV.ITEMS.data.get(plating.get("item"),{}).get("servings",0) if plating.get("hand",false) else 1):return false
		if not numeric(plating.get("left")) or plating.left<0 or not numeric(plating.get("total")) or plating.left>plating.total or plating.total!=2:return false
	return true

static func valid(state: Dictionary) -> bool:
	var recovery = state.get("recovery")
	if not recovery is Array:return false
	for portion in recovery:
		if not stack(portion) or portion.item=="cookingPot":return false
	for object in state.objects:
		if object.type in ["sink","bin"] and object.has("inventory"):return false
		if object.type=="sink" and (not NUM.integer(object.get("dirtyPlates",0)) or object.get("dirtyPlates",0)<0 or object.get("dirtyPlates",0)>INV.DIRTY_SINK_CAPACITY):return false
		if object.type=="sink" and (not NUM.integer(object.get("cleanPlates",0)) or object.get("cleanPlates",0)<0 or object.get("cleanPlates",0)>INV.CLEAN_SINK_CAPACITY):return false
		if object.type=="stove":
			if object.has("inventory") or not object.has("pan"):return false
			var pan = object.pan
			if pan!=null and pan not in ["pot","cookingPot"] and (not pan is String or not pan.begins_with("pot_") or not INV.ITEMS.data.has(pan)):return false
		if object.type=="kitchen":
			if not STORAGE.plating_surface(object):return false
			if object.has("inventory") or not NUM.integer(object.get("plates")) or object.plates<0 or object.plates>STORAGE.CLEAN_PLATE_CAPACITY:return false
			if not object.get("utensil") is bool or not object.get("dishes") is Dictionary:return false
			for item in object.dishes:
				var count = object.dishes[item]
				if not str(item).begins_with("dish_") or not INV.ITEMS.data.has(item) or not NUM.integer(count) or count<0:return false
			if STORAGE.ready_count(object)>STORAGE.READY_DISH_CAPACITY:return false
	var cooking = state.get("cooking")
	if truthy(cooking):
		if not cooking is Dictionary or not numeric(cooking.get("total")) or cooking.total<=0:return false
		if numeric(cooking.get("left")) and cooking.left>cooking.total:return false
	return physical(state)
