extends RefCounted
## Native frame coordinator. The legacy bridge remains only until its rules,
## menu callbacks and painter have been migrated independently.
var evaluate: Callable
var input_router: RefCounted

func _init(executor: Callable):
	evaluate = executor
	input_router = preload("res://simulacao/nativa/Entrada.gd").new(executor)

func read(expression: String) -> Variant:
	return JSON.parse_string(evaluate.call("JSON.stringify("+expression+")"))

func step(dt: float, events: Array) -> Dictionary:
	for event in events:
		if event is Dictionary:input_router.dispatch(event)
	evaluate.call("Host.clock+="+str(dt*1000.0)+";frame(Host.clock);")
	var state = read("({singleRoom:state.singleRoom===true,compact:state.compact===true,room:state.player.room,camera:[camera.x,camera.y,camera.zoom],modal:$('welcome').open?'welcome':$('management').open?'management':'',construction:constructionMode,container:dialogMode==='container',door:[parseFloat($('openBtn').style.left)||0,parseFloat($('openBtn').style.top)||0],notice:$('notice').style.opacity==='1'})")
	if not state is Dictionary:
		return {}
	var scene = read("(()=>{const painter=new Painter();RestaurantArt.draw(painter,R,state,{selectedObject,building,hover,previewError,constructionMode});return painter.commands;})()")
	if not scene is Array:
		return {}
	evaluate.call("Host.widgets.clear()")
	var ui := {}
	if state.modal != "":
		ui.modal = section(state.modal)
	elif state.construction:
		ui.catalog = section("constructionControls")
		ui.drawer = section("constructionDrawer")
		ui.build = section("buildBar")
	else:
		for id in ["hud","dock","actions","context","ordersHud","kitchenStatus","openBtn"]:
			ui[id] = section(id)
		ui.notice = section("notice") if state.notice else null
	var writes = read("Host.writes")
	var sounds = read("Host.sound")
	if not writes is Dictionary or not sounds is Array:
		return {}
	evaluate.call("Host.writes={};Host.sound=[]")
	return {"singleRoom":state.singleRoom,"compact":state.compact,"room":state.room,
		"camera":state.camera,"scene":scene,"ui":ui,"modal":state.modal,
		"liveInventory":state.modal=="management" and state.container,
		"construction":state.construction,"door":state.door,"writes":writes,"sounds":sounds}

func section(id: String) -> Variant:
	return read("section("+JSON.stringify(id)+")")
