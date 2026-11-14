extends RefCounted
const UI_COMMANDS = preload("res://simulacao/nativa/ComandosInterface.gd")
const FOOD_UI = preload("res://interface/ComidaInterface.gd")
const SCENE = preload("res://simulacao/nativa/Cena.gd")
const INTERACTIONS = preload("res://simulacao/nativa/Interacoes.gd")
const CAMERA = preload("res://simulacao/nativa/Camera.gd")
const LOGISTICS = preload("res://simulacao/nativa/Logistica.gd")
const SIMULATION = preload("res://simulacao/nativa/Simulacao.gd")
const KITCHEN = preload("res://simulacao/nativa/Cozinha.gd")
const SAVES = preload("res://simulacao/nativa/Salvamentos.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
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
		"uiCommand":
			value=UI_COMMANDS.execute(args[0],args[1],args[2])
			return JSON.stringify({"value":value,"state":args[0]},"",true,true)
		"foodIcon":value=FOOD_UI.icon(args[0],args[1])
		"heldItem":value=SCENE.held(args[0],args[1])
		"interacoes":
			var controller = INTERACTIONS.new()
			var state: Dictionary = args[1]
			var params: Array = args[2]
			var context: Dictionary = args[3]
			controller.pending=context.pending;controller.current=context.current
			controller.selected=context.selected;controller.building=context.building
			controller.kitchen.manual_moving=context.moving;controller.service.manual_moving=context.moving
			match args[0]:
				"approachCustomer":value=controller.approach(state,controller.service.find(state.customers,params[0]))
				"queueInteraction":value=controller.queue(state,params[0],params[1])
				"queuePhysical":value=controller.physical(state,BUILD.find(state.objects,params[0]),params[1])
				"primaryObjectAction":value=controller.primary(state,BUILD.find(state.objects,params[0]))
				"processInteraction":controller.process(state)
				"pointerDown":controller.pointer_down(state,params[0])
			return JSON.stringify({"value":value,"state":state,"pending":controller.pending,"current":controller.current,"selected":controller.selected,"clearInput":controller.clear_input,"effects":controller.effects},"",true,true)
		"camera":
			match args[0]:
				"update":value=CAMERA.update(args[1],args[2],args[3],args[4],args[5])
				"worldPointer":value=CAMERA.world_pointer(args[1],args[2],args[3],args[4])
				"screenPoint":value=CAMERA.screen_point(args[1],args[2],args[3],args[4],args[5])
				"door":value=CAMERA.door(args[1],args[2],args[3],args[4],args[5],args[6],args[7])
				"level":value=CAMERA.level(args[1])
				"drag":value=CAMERA.drag(args[1],args[2],args[3],args[4],args[5])
				"panKey":value=CAMERA.pan_key(args[1],args[2])
				"resize":value=CAMERA.resize(args[1],args[2],args[3],args[4])
		"logistica":
			var state: Dictionary = args[1]
			var params: Array = args[2]
			var kitchen = KITCHEN.new();kitchen.manual_moving=args[3]
			match args[0]:
				"changeLocation":value=LOGISTICS.change(state,params[0],params[1],params[2])
				"transfer":value=LOGISTICS.transfer(state,params[0],params[1],params[2],params[3])
				"storageObject":
					var target = LOGISTICS.storage(state,params[0],params[1],params[2],params[3])
					value=target.id if target!=null else null
				"locationChunk":value=LOGISTICS.chunk(state,params[0],params[1])
				"takeChunk":
					var portion: Dictionary = params[2]
					if portion.has("source"):portion.source=BUILD.find(state.objects,portion.source.id)
					LOGISTICS.take(state,params[0],params[1],portion,params[3])
				"utilityNear":value=LOGISTICS.utility_near(state,params[0],kitchen)
				"collectReceiving":value=LOGISTICS.collect(state,kitchen)
				"supplyAction":value=LOGISTICS.supply(state,params[0],params[1],params[2],kitchen)
			return JSON.stringify({"value":value,"state":state},"",true,true)
		"simulacao":
			var simulation = SIMULATION.new()
			var state: Dictionary = args[1]
			var params: Array = args[2]
			simulation.service.random_values=args[3]
			simulation.velocity=args[4]
			match args[0]:
				"step":simulation.step(state,params[0])
				"simulate":simulation.simulate(state,params[0])
				"spawn":value=simulation.spawn(state)
				"chooseRecipe":value=simulation.choose_recipe(state)
				"workerStep":simulation.worker(state,SERVICE.new().find(state.workers,params[0]))
			if simulation.service.needs_random:return JSON.stringify({"needsRandom":true})
			return JSON.stringify({"value":value,"state":state,"input":simulation.velocity},"",true,true)
		"cozinha":
			var op: String = args[0]
			var state: Dictionary = args[1]
			var params: Array = args[2]
			var kitchen = KITCHEN.new();kitchen.manual_moving=args[3]
			match op:
				"physicalAction":value=kitchen.physical(state,params[0],params[1])
				"handStorage":value=kitchen.storage(state,params[0],params[1],params[2])
				"recoverHand":value=kitchen.recover(state,params[0])
				"takePhysicalPan":value=kitchen.take_pan(state,kitchen.find(state,params[0]))
				"cookError":value=kitchen.cook_error(state,params[0],params[1])
				"startCook":value=kitchen.cook(state,params[0],params[1])
				"kitchenStep":kitchen.step(state,params[0])
				"choppingStep":kitchen.chop_step(state,params[0])
				"platingStep":kitchen.plate_step(state,params[0])
				"platingPlan":value=kitchen.plating_plan(state,params[0])
				"plateFood":value=kitchen.plate(state,params[0])
				"cancelPlating":value=kitchen.cancel_plate(state)
				"washPlates":value=kitchen.wash(state,params[0])
				"collectDirty":value=kitchen.collect_dirty(state,params[0])
				"discardFood":value=kitchen.discard(state,params[0],params[1])
				"consumeItem":value=kitchen.consume(state,params[0],params[1])
				"kitchenAction":value=kitchen.legacy(state,params[0],params[1],params[2])
				"objectNear":value=kitchen.near(state,params[0],params[1])
				"kitchenFeedback":value=kitchen.feedback(state,kitchen.find(state,params[0]),params[1])
			return JSON.stringify({"value":value,"state":state},"",true,true)
		"valid":value=SAVES.VALIDATOR.valid(args[0],args[1])
		"validExperience":value=SAVES.VALIDATOR.experience(args[0])
		"serializeSave":value=SAVES.serialize(args[0])
		"parseSave":return JSON.stringify(SAVES.new().parse_text(args[0],args[1]),"",true,true)
		"migrateSave":return JSON.stringify(SAVES.new().convert(args[0],args[1]),"",true,true)
		"administracao":
			var operation: String = args[0]
			var state: Dictionary = args[1]
			var params: Array = args[2]
			match operation:
				"validTimeReputation":value=ADMIN.valid_time_reputation(state)
				"syncService":ADMIN.sync(state)
				"servicePending":value=ADMIN.pending(state)
				"serviceOpenError":value=ADMIN.open_error(state)
				"setServiceHours":value=ADMIN.set_hours(state,params[0])
				"toggleOpen":value=ADMIN.toggle(state)
				"advanceClock":ADMIN.advance_clock(state,params[0])
				"finishPeriod":ADMIN.finish_period(state)
				"finishCalendarDay":value=ADMIN.finish_day(state)
				"advanceTestClock":value=ADMIN.test_clock(state,params[0])
				"purchase":value=ADMIN.purchase(state,params[0],params[1],params[2])
				"deliver":ADMIN.deliver(state)
				"buyTool":value=ADMIN.buy_tool(state,params[0])
				"receiveQuality":ADMIN.receive(state,params[0],params[1],params[2])
				"receivingCount":value=ADMIN.receiving_count(state,params[0],params[1])
				"applyVisitReputation":value=ADMIN.reputation(state,params[0],params[1],params[2],params[3])
			return JSON.stringify({"value":value,"state":state},"",true,true)
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
