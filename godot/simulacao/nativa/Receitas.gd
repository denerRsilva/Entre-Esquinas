extends RefCounted
const RECIPES = preload("res://simulacao/nativa/receitas.json")
const ITEMS = preload("res://simulacao/nativa/itens.json")
static func available(s: Dictionary) -> Array:
	if s.get("startKit") is Dictionary:return s.startKit.recipes.duplicate()
	return RECIPES.data.keys().filter(func(id):return not RECIPES.data[id].get("early",false))
static func total_time(s: Dictionary,id: String) -> float:
	var total: float = RECIPES.data[id].time+2.0
	for item in RECIPES.data[id].foods:
		if item!="arroz":total+=RECIPES.data[id].foods[item]*preload("res://simulacao/nativa/Refugio.gd").cut_time(s)
	return total
static func batch_limit(s: Dictionary) -> int:
	return 2 if s.get("refuge") is Dictionary and s.refuge.get("balance") is Dictionary and s.refuge.level>=1 else 1
static func portions(s: Dictionary,object: Dictionary,id: String) -> int:
	var got := {}
	for portion in object.get("ingredients",[]):got[portion.item]=got.get(portion.item,0)+portion.n
	var needed := {}
	for food in RECIPES.data[id].foods:needed[food if food=="arroz" else food+"_cut"]=RECIPES.data[id].foods[food]
	if got.size()!=needed.size():return 0
	for factor in range(1,batch_limit(s)+1):
		var matches := true
		for item in needed:
			if got.get(item,0)!=needed[item]*factor:matches=false;break
		if matches:return factor
	return 0
static func recognized(object: Dictionary,s: Dictionary = {}) -> Variant:
	for id in RECIPES.data:
		if portions(s,object,id)>0:return id
	return null
static func batch_quality(state: Dictionary, object: Dictionary) -> int:
	var batch = object.get("readyBatch")
	if batch==null:return 0
	var elapsed := maxf(0,state.time-batch.doneAt)
	return maxi(0,int(ceil(float(batch.get("quality",0))*(1-maxf(0,elapsed-8)/12)-1e-8)))
static func heat(state: Dictionary, object: Dictionary) -> Dictionary:
	var batch = object.get("readyBatch")
	var elapsed := maxf(0,state.time-(state.time if batch==null else batch.get("doneAt",state.time)))+1e-8
	if elapsed>=25 or object.get("burned",false):return {"stage":"burned","label":"✕ Queimado — retirar e descartar","value":1}
	if elapsed>=20:return {"stage":"danger","label":"⚠ Perto de queimar","value":(elapsed-8)/17}
	if elapsed>=8:return {"stage":"over","label":"⚠ Passando do ponto","value":(elapsed-8)/17}
	return {"stage":"ready","label":"✓ No ponto — retirar","value":1-elapsed/8}
static func ingredient_plan(state: Dictionary, recipe: String) -> Dictionary:
	var weighted := 0.0
	var total := 0.0
	var cost := 0.0
	for food in RECIPES.data[recipe].foods:
		var left: float = RECIPES.data[recipe].foods[food]*4
		for portion in state.inventory:
			if portion==null or portion.item!=food:continue
			var amount := minf(left,portion.n)
			var quality := int(portion.get("quality",0))
			weighted+=amount*quality
			total+=amount
			cost+=amount*ITEMS.data[food].cost*[1,1.25,1.5,2][quality]
			left-=amount
			if left==0:break
	return {"quality":floor(weighted/maxf(total,1)+1e-8),"cost":cost}
