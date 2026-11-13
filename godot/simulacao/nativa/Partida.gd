extends RefCounted
## Native initial state. JSON contains configuration, never executable code.
const INVENTORY = preload("res://simulacao/nativa/Inventario.gd")
const MAP = preload("res://simulacao/nativa/Mapa.gd")
const BASE = preload("res://simulacao/nativa/partida-base.json")
const CATALOG = preload("res://simulacao/nativa/catalogo.json")

static func fresh(compact: bool = false, single_room: bool = false) -> Dictionary:
	var state: Dictionary = BASE.data.duplicate(true)
	state.compact = compact
	state.singleRoom = single_room
	if single_room:
		state.workers = [state.workers[1]]
		state.workers[0].x = 12
		state.workers[0].y = 10
	return state

static func furnished(compact: bool = false, single_room: bool = false) -> Dictionary:
	var state := fresh(compact, single_room)
	var tables: Array = [[9,8],[6,11],[11,12]] if single_room else [[6,5],[6,10],[11,10]] if compact else [[4,5],[4,10],[10,10]]
	for p in tables:
		add_object(state,"table",p[0],p[1])
		add_object(state,"chair",p[0],p[1]-1,2)
		add_object(state,"chair",p[0]+1,p[1]-1,2)
		add_object(state,"chair",p[0],p[1]+1)
		add_object(state,"chair",p[0]+1,p[1]+1)
	var kitchen: Array = [["stove",16,8],["prep",18,13],["fridge",15,7],["kitchen",15,13],["sink",18,8],["potRack",20,8],["bin",22,8]] if single_room else [["stove",20,4 if compact else 3],["prep",20,8],["fridge",15,3 if compact else 2],["kitchen",15,8],["sink",21,6],["potRack",17,3 if compact else 2],["bin",22,8],["shelf",16,13],["cold",21,13]]
	for p in kitchen:
		add_object(state,p[0],p[1],p[2])
	for object in state.objects:
		match object.type:
			"fridge":
				for food in ["arroz","legumes","frango"]:
					INVENTORY.add(object.inventory,food,30)
					state.purchased[food] = 30
					state.inv.kitchen[food] = 30
			"stove": object.pan = "pot"
			"potRack":
				for i in 3: object.inventory[i] = {"item":"pot","n":1}
			"kitchen": object.plates = 12
	state.equipment = {"pot":4,"plate":12,"spoon":0}
	state.tools = {"pot":true,"spoon":false}
	state.player.x = 18
	state.player.y = 11 if single_room else 6
	state.message = "Taverna pronta: ingredientes na geladeira, panela no fogão e pratos na mesa de cozinha."
	if not single_room or compact:
		assert(not MAP.blocked(state,"restaurant",Vector2i(state.player.x,state.player.y)))
		assert(MAP.route(state,"restaurant",Vector2i(7,13),Vector2i(7,14))!=null)
	return state

static func add_object(state: Dictionary, type: String, x: int, y: int, rotation: int = 0) -> void:
	var object := {"id":state.serial,"type":type,"x":x,"y":y,"rot":rotation,"room":CATALOG.data[type].room}
	match type:
		"stove": object.merge({"ingredients":[],"pan":null})
		"kitchen": object.merge({"plates":0,"utensil":false,"dishes":{},"dishQuality":{}})
		"shelf","cold","fridge","potRack":
			object.inventory = []
			object.inventory.resize(3 if type=="potRack" else 10)
	state.objects.append(object)
	state.serial += 1

static func templates() -> Dictionary:
	var result := {}
	for compact in [false,true]:
		for single_room in [false,true]:
			result[str(int(compact))+str(int(single_room))] = {"empty":fresh(compact,single_room),"furnished":furnished(compact,single_room)}
	return result
