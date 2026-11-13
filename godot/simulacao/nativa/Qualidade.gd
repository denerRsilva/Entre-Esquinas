extends RefCounted
const CONSERVATION = preload("res://simulacao/nativa/Conservacao.gd")
const ITEMS = preload("res://simulacao/nativa/itens.json")
const RECIPES = preload("res://simulacao/nativa/receitas.json")

static func quality_valid(record: Dictionary) -> bool:
	if not record.has("quality"):return true
	var quality = record.quality
	return CONSERVATION.integer(quality) and quality>=0 and quality<=3

static func counts_valid(value: Variant) -> bool:
	if not value is Array or value.size()!=4:return false
	for amount in value:
		if not CONSERVATION.integer(amount) or amount<0:return false
	return true

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func valid(state: Dictionary) -> bool:
	for container in CONSERVATION.locations(state):
		for portion in container:
			if portion==null:continue
			if not quality_valid(portion):return false
			if portion.has("burned") and (not portion.burned is bool or not str(portion.item).begins_with("pot_")):return false
	for actor in CONSERVATION.actors(state):
		var carry = actor.get("carry")
		if carry!=null and not quality_valid(carry):return false
	for delivery in state.deliveries:
		if not quality_valid(delivery):return false
	for food in state.get("receivingQuality",{}):
		var counts = state.receivingQuality[food]
		if food not in ["arroz","legumes","frango"] or not counts_valid(counts):return false
		if counts[1]+counts[2]+counts[3]>state.inv.receiving[food]:return false
	for object in state.objects:
		for item in object.get("dishQuality",{}):
			var counts = object.dishQuality[item]
			if not ITEMS.data.has(item) or not counts_valid(counts):return false
			var stored = object.get("dishes",{}).get(item)
			if stored!=null and counts[1]+counts[2]+counts[3]>stored:return false
		var batch = object.get("readyBatch")
		if batch!=null:
			if not numeric(batch.get("doneAt")) or batch.doneAt>state.time or not quality_valid(batch) or not RECIPES.data.has(batch.get("recipe")):return false
	var cooking = state.get("cooking")
	return cooking==null or quality_valid(cooking)
