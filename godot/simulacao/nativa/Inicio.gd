extends RefCounted
const P = preload("res://simulacao/nativa/Partida.gd")
const INV = preload("res://simulacao/nativa/Inventario.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const RECIPES = preload("res://simulacao/nativa/receitas.json")
const KITCHEN_LAYOUT = {"stove":Vector2i(15,8),"prep":Vector2i(17,8),"fridge":Vector2i(19,7),"sink":Vector2i(20,8),"bin":Vector2i(22,8),"kitchen":Vector2i(15,11),"potRack":Vector2i(19,11)}
static func apply(s: Dictionary) -> void:
	s.startKit={"version":1,"recipes":["caldoBatata","arrozCenoura"]}
	s.cash=200
	var table_ids: Array = s.objects.filter(func(o):return o.type=="table").map(func(o):return o.id)
	# In the single-room starter, keep the two lower tables from the reference.
	var removed_table = table_ids.front() if s.get("singleRoom",false) else table_ids.back()
	var table = s.objects.filter(func(o):return o.id==removed_table)[0]
	var erase_ids: Array = [table.id]
	for o in s.objects:
		if o.type=="chair":
			var linked = preload("res://simulacao/nativa/Construcao.gd").chair_table(o,s.objects)
			if linked!=null and linked.id==table.id:erase_ids.append(o.id)
	s.objects=s.objects.filter(func(o):return o.id not in erase_ids)
	for loc in s.inv:
		for raw in INV.RAWS:s.inv[loc][raw]=0
	for raw in INV.RAWS:s.purchased[raw]=0;s.used[raw]=0
	for id in RECIPES.data:
		s.menu[id]=id in s.startKit.recipes;s.prices[id]=RECIPES.data[id].price
		for kind in ["made","eaten","wasted"]:s.meals[kind][id]=0
	for o in s.objects:
		if s.get("singleRoom",false) and KITCHEN_LAYOUT.has(o.type):
			var position: Vector2i = KITCHEN_LAYOUT[o.type]
			o.x=position.x;o.y=position.y
		if o.type=="fridge":
			o.inventory.fill(null)
			for pair in [["arroz",12],["batata",8],["cenoura",8]]:INV.add(o.inventory,pair[0],pair[1]);s.purchased[pair[0]]=pair[1]
		elif o.type=="potRack":o.inventory.fill(null);o.inventory[0]={"item":"pot","n":1}
		elif o.type=="kitchen":o.plates=8
	s.equipment={"pot":2,"plate":8,"spoon":0};STORE.sync(s)
static func valid(s: Dictionary) -> bool:
	if not s.has("startKit"):return true
	var data = s.startKit
	if not data is Dictionary or data.get("version")!=1 or not data.get("recipes") is Array:return false
	if data.recipes not in [["caldoBatata","arrozCenoura"],["caldoBatata","arrozCenoura","canja"]]:return false
	for raw in INV.RAWS:
		if not s.purchased.has(raw) or not s.used.has(raw):return false
	for id in RECIPES.data:
		if id not in data.recipes and s.menu.get(id,false):return false
		for kind in ["made","eaten","wasted"]:
			if not s.meals[kind].has(id):return false
	return s.get("refuge") is Dictionary
