extends RefCounted
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const KITCHEN_STATE = preload("res://simulacao/nativa/EstadoCozinha.gd")
const MIGRATION = preload("res://simulacao/nativa/MigracaoSave.gd")
const QUALITY = preload("res://simulacao/nativa/Qualidade.gd")
const CONSERVATION = preload("res://simulacao/nativa/Conservacao.gd")
const RECIPES = preload("res://simulacao/nativa/Receitas.gd")
const STORAGE = preload("res://simulacao/nativa/Armazenamento.gd")
const CALENDAR = preload("res://simulacao/nativa/Calendario.gd")
const MAP = preload("res://simulacao/nativa/Mapa.gd")
const INVENTORY = preload("res://simulacao/nativa/Inventario.gd")

func execute(json: String) -> String:
	var request = JSON.parse_string(json)
	if not request is Dictionary:return "null"
	var args: Array = request.get("args",[])
	var value: Variant = null
	match request.get("name",""):
		"satisfactionFor":value=SERVICE.new().satisfaction(args[0])
		"waitRatio":
			args[0].phase=args[1]
			value=SERVICE.new().ratio(args[0])
		"finishWait":
			SERVICE.new().finish(args[0])
			return JSON.stringify(args[0],"",true,true)
		"mealCost":
			value=0
			for food in SERVICE.RECIPES.data[args[0]].foods:value+=SERVICE.RECIPES.data[args[0]].foods[food]*SERVICE.INV.ITEMS.data[food].cost
		"atendimento":
			var operation: String = args[0]
			var state: Dictionary = args[1]
			var params: Array = args[2]
			var service = SERVICE.new()
			service.random_values=args[3]
			service.manual_moving=args[4] if args.size()>4 else false
			var actor = service.find(MOVE.ACTORS.actors(state),params[0]) if not params.is_empty() and operation in ["takeOrder","serve","pickupDish","canceledCarry","returnCanceledDish","customerAccess","readyPoint","waiterStep","removeHandDish"] else null
			var customer = service.find(state.customers,params[1]) if params.size()>1 and operation in ["takeOrder","serve","customerAccess","removeHandDish"] else null
			match operation:
				"newExperience":value=service.experience()
				"refreshCustomerVisual":service.visual(state,service.find(state.customers,params[0]))
				"customerIndicator":value=service.indicator(state,service.find(state.customers,params[0]))
				"beginWait":service.begin(state,service.find(state.customers,params[0]),params[1])
				"finalizeVisit":value=service.finalize(state,service.find(state.customers,params[0]),params[1])
				"abandonCustomer":value=service.abandon(state,service.find(state.customers,params[0]))
				"expiredCustomer":value=service.expired(state,service.find(state.customers,params[0]))
				"patienceStep":service.patience(state,params[0])
				"takeOrder":value=service.take_order(state,actor,customer)
				"serve":value=service.serve(state,actor,customer)
				"pickupDish":value=service.pickup(state,actor)
				"canceledCarry":value=service.canceled(state,actor)
				"returnCanceledDish":value=service.return_canceled(state,actor)
				"customerAccess":value=service.customer_access(state,actor,customer)
				"readyPoint":value=service.ready_point(state,actor)
				"interact":value=service.interact(state,params[0])
				"waiterStep":service.waiter(state,actor)
				"removeHandDish":service.hand_dish(state,actor,customer,params[2])
				"clientsStep":service.clients_step(state,params[0])
			if service.needs_random:return JSON.stringify({"needsRandom":true})
			return JSON.stringify({"value":value,"state":state},"",true,true)
		"editError":value=BUILD.edit_error(args[0])
		"layoutError":value=BUILD.layout_error(args[0],args[1])
		"longSideSeat":value=BUILD.long_side(args[0],args[1])
		"chairLayoutError":value=BUILD.chair_error(args[0],args[1],args[2])
		"chairTable","seatTable":
			var table = BUILD.chair_table(args[1],args[2]) if request.name=="chairTable" else BUILD.seat_table(args[1],args[2])
			value=table.id if table!=null else null
		"seats":value=BUILD.seats(args[0])
		"kit":value=BUILD.kit(args[0])
		"place","remove":
			var state: Dictionary = args[0]
			value=BUILD.place(state,args[1],args[2],args[3],args[4],args[5]) if request.name=="place" else BUILD.remove(state,args[1])
			return JSON.stringify({"value":value,"state":state},"",true,true)
		"position":value=MOVE.position(args[0])
		"reserved":value=MOVE.reserved(args[0])
		"actorWalkTime":value=MOVE.walk_time(args[0])
		"arrived":value=MOVE.arrived(args[0]) if args[0].get("goal")!=null else null
		"goalInRoom":value=MOVE.goal_in_room(args[0])
		"accessPoints":
			args[0].objects=args[2]
			value=MOVE.access(args[0],args[1])
		"closestAccess":value=MOVE.closest(args[0],args[1],args[2])
		"occupants":value=MOVE.occupants(args[0],args[1]).keys()
		"isMoving":value=args[0].get("motion")!=null or (args[1]!=null and args[1].get("moving",false))
		"startMotion","advanceMotion","go":
			match request.name:
				"startMotion":value=MOVE.start(args[0],args[1],args[2],args[3])
				"advanceMotion":value=MOVE.advance(args[0],args[1])
				"go":MOVE.go(args[0],args[1])
			return JSON.stringify({"value":value,"actor":args[0]},"",true,true)
		"setPlayerInput":
			value=args[3]
			if (args[1] is int or args[1] is float) and (args[2] is int or args[2] is float):value=MOVE.input(args[0].player,args[3],args[1],args[2])
			return JSON.stringify({"actor":args[0].player,"input":value},"",true,true)
		"goObject":
			var point = MOVE.closest(args[0],args[1],args[2])
			if point!=null:args[1].goal=point
			return JSON.stringify({"value":point!=null,"actor":args[1]},"",true,true)
		"moveActors","pushAside":
			var state: Dictionary = args[0]
			var locked := {}
			var seen := {}
			if request.name=="moveActors":MOVE.move(state,args[1],args[2])
			else:
				var actor: Variant = null
				var requester: Variant = null
				for candidate in MOVE.ACTORS.actors(state):
					if candidate.id==args[1]:actor=candidate
					if candidate.id==args[2]:requester=candidate
				for cell in args[3]:locked[cell]=true
				for id in args[4]:seen[id]=true
				value=MOVE.push(state,actor,requester,locked,seen)
			return JSON.stringify({"value":value,"player":state.player,"workers":state.workers,"residents":state.residents,"customers":state.customers,"flowWaits":state.flowWaits,"input":args[2] if request.name=="moveActors" else null,"locked":locked.keys(),"seen":seen.keys()},"",true,true)
		"validKitchen":value=KITCHEN_STATE.valid(args[0])
		"validPhysicalKitchen":value=KITCHEN_STATE.physical(args[0])
		"recoverItems","migrateKitchen","migrateCleaning","migratePhysicalKitchen","migrateHands":
			var state: Dictionary = args[0]
			match request.name:
				"recoverItems":value=MIGRATION.recover(state)
				"migrateKitchen":MIGRATION.kitchen(state)
				"migrateCleaning":MIGRATION.cleaning(state)
				"migratePhysicalKitchen":MIGRATION.physical(state,args[1])
				"migrateHands":value=MIGRATION.hands(state)
			return JSON.stringify({"value":value,"state":state},"",true,true)
		"validQuality":value=QUALITY.valid(args[0])
		"foodConserved":value=CONSERVATION.food(args[0])
		"equipmentConserved":value=CONSERVATION.equipment(args[0])
		"mealsConserved":value=CONSERVATION.meals(args[0])
		"recognizedRecipe":value=RECIPES.recognized(args[0])
		"batchQuality":value=RECIPES.batch_quality(args[0],args[1])
		"heatState":value=RECIPES.heat(args[0],args[1])
		"ingredientPlan":value=RECIPES.ingredient_plan(args[0],args[1])
		"objectLocation":value=STORAGE.location(args[0])
		"accepts":value=STORAGE.accepts(args[0],args[1])
		"stationSlots":value=STORAGE.slots(args[0])
		"objectCount":value=STORAGE.count(args[0],args[1])
		"readyCount":value=STORAGE.ready_count(args[0])
		"objectSpace":value=STORAGE.space(args[0],args[1],args[2])
		"objectQualityCount":value=STORAGE.quality_count(args[0],args[1],args[2])
		"firstDishQuality":value=STORAGE.first_quality(args[0],args[1])
		"capacity":value=STORAGE.capacity(args[0],args[1],args[2])
		"amount":value=STORAGE.amount(args[0],args[1],args[2])
		"syncContainers":
			STORAGE.sync(args[0])
			return JSON.stringify({"value":null,"inv":args[0].inv},"",true,true)
		"putObject","takeObject":
			var object: Dictionary = args[1]
			for candidate in args[0].objects:
				if candidate.get("id")==object.get("id"):
					object=candidate
					break
			value=STORAGE.put(args[0],object,args[2],args[3],args[4]) if request.name=="putObject" else STORAGE.take(args[0],object,args[2],args[3],args[4])
			return JSON.stringify({"value":value,"object":object,"inv":args[0].inv},"",true,true)
		"newServiceHours":value=CALENDAR.hours()
		"validServiceHours":value=CALENDAR.valid_hours(args[0])
		"serviceHours":value=args[0].get("serviceHours",CALENDAR.hours())
		"serviceTimeText":value=CALENDAR.time_text(args[0])
		"newClock":value={"minute":360,"remainder":0,"ending":false}
		"calendarDate":value=CALENDAR.date(args[0])
		"clockText":value=CALENDAR.time_text(args[0].clock.minute)
		"clampReputation":value=clampf(args[0],0,100)
		"newReputation":value={"initial":0,"score":0,"history":[],"processed":[]}
		"reputationLevel":value=CALENDAR.reputation_level(args[0])
		"route":
			var avoid: Array = []
			for cell in args[5]:
				var parts = str(cell).split(",")
				avoid.append(Vector2i(int(parts[0]),int(parts[1])))
			var state: Dictionary = args[0]
			state.objects=args[6]
			value=MAP.route(state,args[1],Vector2i(args[2].x,args[2].y),Vector2i(args[3].x,args[3].y),args[4] if args[4]!=null else {},avoid)
		"wall":value=MAP.wall(args[0],args[1],args[2],args[3] if args[3]!=null else {})
		"fixed":value=MAP.fixed(args[0],args[1],args[2],args[3] if args[3]!=null else {})
		"rect":
			var rect = MAP.rect(args[0])
			value={"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y}
		"cells":
			var rect = MAP.rect(args[0])
			value=[]
			for y in range(rect.position.y,rect.end.y):
				for x in range(rect.position.x,rect.end.x):value.append({"x":x,"y":y})
		"hit":value=MAP.rect(args[0]).has_point(Vector2i(args[1],args[2]))
		"near":value=args[0].room==args[1].room and absf(args[0].x-args[1].x)+absf(args[0].y-args[1].y)<=args[2]
		"itemLimit":value=INVENTORY.limit(args[0])
		"inventoryCount":value=INVENTORY.count(args[0].inventory,args[1])
		"inventorySpace":value=INVENTORY.space(args[0].inventory,args[1],args[2])
		"addInventory":
			var quantity: Variant = args[2]
			value=false
			if quantity is float and is_finite(quantity) and quantity==floor(quantity):value=INVENTORY.add(args[0].inventory,args[1],int(quantity),args[3],args[4])
			return JSON.stringify({"value":value,"inventory":args[0].inventory},"",true,true)
		"removeInventory":
			value=false
			if args[1] is float and args[1]==floor(args[1]) and args[2] is float and args[2]==floor(args[2]):value=INVENTORY.remove(args[0].inventory,int(args[1]),int(args[2]))
			return JSON.stringify({"value":value,"inventory":args[0].inventory},"",true,true)
	return JSON.stringify(value,"",true,true)
