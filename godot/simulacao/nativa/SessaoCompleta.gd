extends RefCounted
## Native application state and input controller; no script evaluator or DOM.
const REFUGE = preload("res://simulacao/nativa/Refugio.gd")
const MARKET = preload("res://simulacao/nativa/Mercado.gd")
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const CAMERA = preload("res://simulacao/nativa/Camera.gd")
const INTERACT = preload("res://simulacao/nativa/Interacoes.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const SAVE = preload("res://simulacao/nativa/Salvamentos.gd")
const UI_COMMAND = preload("res://simulacao/nativa/ComandosInterface.gd")
const FOOD_UI = preload("res://interface/ComidaInterface.gd")
var simulation = SIM.new()
var rng: Callable = randf
var state: Dictionary = PARTIDA.fresh(true,true)
const SAVE_KEY := "entre-partida-unica"
const CHECKPOINT_KEY := "entre-refugio-preparo-unico"
var checkpoint_cache := {"day":0,"raw":""}
var kitchen_sound_stamp := ""
var values: Dictionary = {}
var writes: Dictionary = {}
var sounds: Array = []
var camera := {"x":0.0,"y":0.0,"zoom":1.0,"mode":null}
var viewport := {"width":960.0,"height":640.0}
var rect := {"left":0.0,"top":60.0,"width":960.0,"height":640.0}
var camera_level := 1.0
var responsive_view := false
var modal := "welcome"
var mode := "general"
var tab := "guide"
var dialog_object: Variant = null
var generation := 0
var construction := false
var drawer := false
var building: Variant = null
var hover: Variant = null
var build_pointer: Variant = null
var selected: Variant = null
var pending: Variant = null
var velocity: Variant = null
var keyboard: Dictionary = {}
var hidden := false
var tutorial := false
var clock := 0.0
var notice_until := 0.0
var menu_notice := ""
var played_heat: Dictionary = {}
var renderer = preload("res://simulacao/nativa/Cena.gd").new()
var game_ui = preload("res://interface/PainelJogoNativo.gd").new()
var admin_ui = preload("res://interface/AdministracaoUI.gd").new()
var inventory_ui = preload("res://interface/InventariosNativos.gd").new()
var tools_ui = preload("res://interface/UtensiliosNativos.gd").new()
var catalog_ui = preload("res://interface/ComprasConstrucaoNativas.gd").new()
var recipe_ui = preload("res://interface/LivroReceitasNativo.gd").new()
var food_ui = FOOD_UI.new()
var root_actions: Dictionary = {}
func initialize(saved: Dictionary) -> void:
	values=saved.duplicate(true)
	migrate_single_save()
	var level: float = str(values.get("entre-camera-zoom","1")).to_float()
	if level>=0.7 and level<=2:camera_level=level
	update_camera()
func migrate_single_save() -> void:
	if values.has(SAVE_KEY):return
	# Import the previously active valid game; retain all historical keys.
	var preferred := clampi(str(values.get("entre-slot-ativo","1")).to_int(),1,3)
	var sources: Array = []
	for slot in [preferred,1,2,3]:
		var source := "entre-partida-"+str(slot)
		if not sources.has(source):sources.append(source)
	for version in ["12","11","10","09","07","06","05","04"]:sources.append("entre-restaurante-"+version)
	var fallback := ""
	for source in sources:
		var raw := str(values.get(source,""))
		if raw.is_empty():continue
		if fallback.is_empty():fallback=raw
		if parse_save(raw)==null:continue
		values[SAVE_KEY]=raw;writes[SAVE_KEY]=raw
		var slot := int(source.trim_prefix("entre-partida-")) if source.begins_with("entre-partida-") else 1
		var backup := str(values.get("entre-refugio-preparo-"+str(slot),""))
		values[CHECKPOINT_KEY]=backup;writes[CHECKPOINT_KEY]=backup
		return
	# Keep a corrupt game's presence visible rather than silently replacing it.
	if not fallback.is_empty():values[SAVE_KEY]=fallback;writes[SAVE_KEY]=fallback
func has_saved_game() -> bool:return not str(values.get(SAVE_KEY,"")).is_empty()
func archive_save() -> void:
	if not has_saved_game():return
	for pair in [[SAVE_KEY,"entre-partida-anterior"],[CHECKPOINT_KEY,"entre-refugio-preparo-anterior"]]:
		var raw := str(values.get(pair[0],""))
		values[pair[1]]=raw;writes[pair[1]]=raw
func release_keyboard() -> void:keyboard.clear();velocity=null
func focus(value: bool) -> void:hidden=not value;release_keyboard()
func resize_view(width: float,height: float) -> void:
	responsive_view=true;build_pointer=null
	viewport={"width":maxf(1,width),"height":maxf(1,height)}
	rect={"left":0.0,"top":0.0,"width":viewport.width,"height":viewport.height}
	update_camera()
func update_camera() -> void:camera=CAMERA.update(state,camera,viewport,camera_level,construction,responsive_view)
func set_zoom(value: float) -> void:
	camera_level=CAMERA.level(value);values["entre-camera-zoom"]=str(camera_level);writes["entre-camera-zoom"]=str(camera_level);update_camera()
func notify(message: String,bad: bool = false) -> void:
	state.message=message;notice_until=clock+6
	if modal in ["management","market","welcome","confirmNew"]:menu_notice=message
func reset_view() -> void:
	PARTIDA.waiter_defaults(state)
	renderer.facing.clear();played_heat.clear();pending=null;velocity=null;keyboard.clear();generation+=1
func open_dialog(next: String) -> void:
	if next in ["cooking","plating","inventory"]:return
	if next=="build":enter_construction();return
	if construction:return
	pending=null;release_keyboard()
	var kitchen = INTERACT.KITCHEN.new()
	if next=="computer" and REFUGE.active(state):return
	if next in ["merchant","traveler"]:
		if MARKET.near(state,next=="traveler"):mode=next;modal="market";menu_notice="";state.player.goal=null
		return
	if next=="computer" and not INTERACT.LOGISTICS.utility_near(state,"computer",kitchen):notify("Aproxime-se do computador.",true);return
	mode=next;tab="container" if next=="container" else "supplier" if next=="computer" else "camera" if next=="options" else "recipes" if next=="recipes" else "city" if next=="general" and REFUGE.active(state) else "shifts"
	modal="management";menu_notice="";generation+=1
func close_dialog() -> void:modal="";release_keyboard()
func open_inventory(id: Variant) -> void:
	var object = BUILD.find(state.objects,id)
	var kitchen = INTERACT.KITCHEN.new();kitchen.manual_moving=velocity!=null and velocity.get("moving",false)
	if object==null or not object.has("inventory") or not kitchen.near(state,object):notify("Aproxime-se do objeto.",true);return
	dialog_object=id;open_dialog("container")
func enter_construction() -> void:
	if state.open or state.closing or not state.customers.is_empty():notify("Conclua o serviço antes de construir.",true);return
	if state.player.room!="restaurant":notify("Entre no restaurante para construir.",true);return
	pending=null;release_keyboard();selected=null;construction=true;modal="";drawer=true;mode="build";tab="catalog";generation+=1;update_camera()
func stop_build(reopen: bool = true) -> void:
	release_keyboard();building=null;hover=null
	if reopen and construction:drawer=true;generation+=1
func begin_build(type: String,moving: Variant = null) -> void:
	if not construction:return
	pending=null;release_keyboard()
	if state.open or not state.customers.is_empty():notify("Conclua o serviço antes de montar.",true);return
	modal="";drawer=false
	var object = BUILD.find(state.objects,moving) if moving!=null else null
	building={"type":type,"rot":object.rot if object!=null else 0,"moving":moving};hover=null;state.player.goal=null
func preview_error() -> Variant:
	if building==null or hover==null:return null
	if BUILD.TABLE_KITS.has(building.type):return BUILD.kit_error(state,building.type,int(hover.x),int(hover.y))
	var candidate := {"type":building.type,"room":BUILD.CATALOG.data[building.type].room,"x":hover.x,"y":hover.y,"rot":building.rot,"id":building.moving if building.moving!=null else state.serial}
	if candidate.room!=state.player.room:return "Vá ao setor indicado para colocar este objeto."
	var objects: Array = []
	for object in state.objects:
		if not renderer.same(object.id,building.moving):objects.append(object)
	objects.append(candidate)
	return BUILD.layout_error(state,objects)
func interact(operation: String,args: Array = []) -> Variant:
	var controller = INTERACT.new();controller.pending=pending;controller.selected=selected;controller.building=building!=null
	controller.kitchen.manual_moving=velocity!=null and velocity.get("moving",false);controller.service.manual_moving=controller.kitchen.manual_moving
	var result: Variant = null
	match operation:
		"pointer":controller.pointer_down(state,args[0])
		"process":controller.process(state)
		"physical":result=controller.physical(state,BUILD.find(state.objects,args[0]),args[1])
	pending=controller.pending;selected=controller.selected
	if controller.clear_input:velocity=null
	for effect in controller.effects:
		match effect.kind:
			"tell":notify(effect.message,effect.bad)
			"dialog":open_dialog(effect.mode)
			"inventory":open_inventory(effect.id)
			"beginBuild":begin_build(effect.type,effect.moving)
			"capture":build_pointer={"x":effect.x,"y":effect.y}
			"preview":building.locked=true;hover={"x":effect.x,"y":effect.y}
	return result
func keyboard_move() -> void:
	var dx := int(keyboard.get("arrowright",false) or keyboard.get("d",false))-int(keyboard.get("arrowleft",false) or keyboard.get("a",false))
	var dy := int(keyboard.get("arrowdown",false) or keyboard.get("s",false))-int(keyboard.get("arrowup",false) or keyboard.get("w",false))
	if dx!=0 or dy!=0:pending=null
	velocity=MOVE.input(state.player,velocity,dx,dy)
func pointer(event: Dictionary) -> void:
	if not modal.is_empty():return
	var point := {"clientX":float(event.get("x",0)),"clientY":float(event.get("y",0))}
	if not is_finite(point.clientX) or not is_finite(point.clientY):return
	match event.phase:
		"down":
			pending=null;release_keyboard()
			interact("pointer",[{"world":CAMERA.world_pointer(point,rect,viewport,camera),"clientX":point.clientX,"clientY":point.clientY,"pointerId":1,"construction":construction,"building":building}])
		"up","cancel":build_pointer=null
		"move":
			if not construction:return
			if build_pointer!=null and event.get("drag",false):
				camera=CAMERA.drag(camera,point,build_pointer,rect,viewport);build_pointer={"x":point.clientX,"y":point.clientY};update_camera()
				if building!=null:building.locked=false
			if building!=null and not building.get("locked",false):
				var world := CAMERA.world_pointer(point,rect,viewport,camera);hover={"x":floor(world.x),"y":floor(world.y)}
func key(event: Dictionary) -> void:
	var name: String = event.key;var down: bool = event.down
	if name=="escape" and down and modal=="confirmNew":modal="welcome";return
	if name=="escape" and down and modal in ["management","market"]:close_dialog();return
	if not modal.is_empty():return
	var movement: bool = name in ["arrowup","arrowdown","arrowleft","arrowright","w","a","s","d"]
	if construction:
		if not down:return
		if name=="escape":
			if building!=null:stop_build()
			elif drawer:drawer=false
			else:root_action("exitConstruction")
		elif movement:camera=CAMERA.pan_key(camera,name);update_camera()
		elif name=="r" and building!=null:building.rot=(int(building.rot)+1)%4
		return
	if name=="escape" and down:stop_build();return
	if name=="e" and down:
		if game_ui.controls.actions.has(game_ui.first_context):world_action(game_ui.controls.actions[game_ui.first_context])
		else:
			var customer = INTERACT.SERVICE.new().find(state.customers,selected)
			if customer!=null:world_action({"kind":"customer","id":customer.id})
		return
	if movement:
		if down:keyboard[name]=true
		else:keyboard.erase(name)
		keyboard_move()
func world_action(action: Dictionary) -> void:
	if not modal.is_empty() or construction:return
	var result: Variant = null
	match action.kind:
		"priority":UI_COMMAND.execute(state,"priority",[action.id])
		"portal":velocity=null;MOVE.go(state.player,{"room":action.room,"x":action.x,"y":action.y})
		"computer":open_dialog("computer")
		"receiving":notify(INTERACT.LOGISTICS.collect(state,INTERACT.KITCHEN.new()))
		"inventory":open_inventory(action.id)
		"physical":interact("physical",[action.id,action.command])
		"customer":INTERACT.SERVICE.new().interact(state,action.id);notify(state.message)
		"wash":result=INTERACT.KITCHEN.new().wash(state,action.id)
		"clean":result=INTERACT.KITCHEN.new().collect_dirty(state,action.id)
		"wipe":result=INTERACT.KITCHEN.new().wipe(state,action.id)
	if result!=null:notify(result.message,not result.ok)
func parse_save(raw: String) -> Variant:
	var draws: Array = []
	while true:
		var result: Dictionary = SAVE.new().parse_text(raw,draws)
		if result.get("needsRandom",false):draws.append(rng.call());continue
		return result.get("value")
	return null
func load_state(next: Dictionary) -> void:
	state=next;state.cookActive=false;building=null;selected=null;reset_view();update_camera()
func save_game() -> void:
	var raw = SAVE.serialize(state)
	if raw==null:notify("Não foi possível salvar: Estado inválido",true);return
	values[SAVE_KEY]=raw;writes[SAVE_KEY]=raw
	notify("Jogo salvo.")
func load_game() -> bool:
	var next = parse_save(str(values.get(SAVE_KEY,"")))
	if next==null:
		notify("Não foi possível carregar: salvamento ausente ou inválido. Estado atual preservado.",true);return false
	load_state(next);notify("Jogo carregado.");return true
func admin_action(action: Dictionary,value: Variant) -> void:
	if modal!="management" or mode!=action.mode or tab!=action.tab:return
	var k: String = action.key;var result: Variant = null
	match action.kind:
		"quantity":admin_ui.form.quantities[k]=value
		"quality":admin_ui.form.qualities[k]=int(value)
		"hours":admin_ui.form.hours[action.index][action.field]=int(value)
		"time":admin_ui.form.time=int(value)
		"close":close_dialog()
		"tab":
			if k=="build":open_dialog("build")
			else:tab=k;generation+=1;menu_notice=""
		"zoom":set_zoom(1 if k=="reset" else camera_level+(-0.1 if k=="out" else 0.1));generation+=1;menu_notice=""
		"applyHours":result=ADMIN.set_hours(state,admin_ui.form.hours);generation+=int(result.ok)
		"advance":result=ADMIN.test_clock(state,admin_ui.form.time);generation+=1
		"searchStaff":admin_ui.form.searchStaff=true
		"hire":
			result=preload("res://simulacao/nativa/Contratacao.gd").hire(state,int(k))
			if result.ok:generation+=1
		"menu","price","task":result=UI_COMMAND.execute(state,action.kind,[k,value])
		"clear":result=UI_COMMAND.execute(state,"clear",[]);building=null;hover=null;selected=null;dialog_object=null;reset_view()
		"purchase":
			var count: Variant = admin_ui.form.quantities[k];var quality := int(admin_ui.form.qualities[k])
			var ok := ADMIN.purchase(state,k,count,quality)
			if ok:generation+=1
			notify(admin_ui.number(count)+" "+INTERACT.SERVICE.INV.ITEMS.data[k].name+" encomendados por "+admin_ui.money(count*INTERACT.SERVICE.INV.ITEMS.data[k].cost*[1,1.25,1.5,2][quality])+". A entrega avança ao voltar ao jogo." if ok else "Informe de 1 a 100 unidades e confira o saldo.",not ok)
		"save":save_game()
		"load":load_game()
	if result!=null and result.get("message")!=null:notify(result.message,not result.ok)
func checkpoint_key() -> String:return CHECKPOINT_KEY
func checkpoint(force: bool = false) -> void:
	if not REFUGE.active(state) or REFUGE.blocked(state):return
	if not force and state.day!=state.refuge.nextHorde:return
	var previous_raw: String = str(values.get(checkpoint_key(),""))
	if not force and checkpoint_cache.day==state.day and checkpoint_cache.raw==previous_raw:return
	var old = parse_save(previous_raw) if not previous_raw.is_empty() else null
	if not force and old is Dictionary and old.get("day")==state.day:
		checkpoint_cache={"day":state.day,"raw":previous_raw};return
	var raw = SAVE.serialize(state)
	if raw==null:return
	values[checkpoint_key()]=raw;writes[checkpoint_key()]=raw
	checkpoint_cache={"day":state.day,"raw":raw}
func refuge_action(action: String) -> void:
	if not REFUGE.active(state):return
	match action:
		"skip":
			if REFUGE.active(state) and state.refuge.phase=="battle":REFUGE.battle_step(state,REFUGE.BATTLE_SECONDS)
		"continue":
			if REFUGE.continue_day(state):ADMIN.finish_day(state);save_game();checkpoint();generation+=1
		"retry":
			if not REFUGE.active(state) or state.refuge.phase!="gameover":return
			var previous = parse_save(str(values.get(checkpoint_key(),"")))
			if previous!=null and REFUGE.active(previous) and not REFUGE.blocked(previous):load_state(previous);close_dialog();save_game()
			else:
				var saved = parse_save(str(values.get(SAVE_KEY,"")))
				if saved!=null and not REFUGE.blocked(saved):load_state(saved);close_dialog()
				else:load_state(PARTIDA.fresh(true,true));modal="welcome"
func sleep_day() -> void:
	if ADMIN.pending(state) or state.open or state.closing:notify("Conclua o serviço e os preparos antes de dormir.",true);return
	state.clock={"minute":1560,"remainder":0,"ending":true}
	if ADMIN.finish_day(state):save_game();checkpoint();generation+=1
func start_refuge() -> void:
	archive_save()
	values[CHECKPOINT_KEY]="";writes[CHECKPOINT_KEY]="";checkpoint_cache={"day":0,"raw":""};menu_notice=""
	state=PARTIDA.furnished(true,true);REFUGE.start(state);preload("res://simulacao/nativa/Inicio.gd").apply(state);MARKET.initialize(state);building=null;hover=null;selected=null;construction=false;drawer=false;reset_view();modal="";set_zoom(camera_level);save_game();checkpoint(true)
func root_action(kind: String) -> void:
	if kind.begins_with("marketBuy:") and modal=="market":
		var parts := kind.split(":")
		if parts.size()==3:
			var result := MARKET.buy(state,parts[1],int(parts[2]),mode=="traveler");notify(result.message,not result.ok)
		return
	if kind=="learnCanja" and modal=="market":
		if MARKET.learn(state):notify("Canja aprendida. Disponível no livro e no cardápio.")
		return
	if kind=="sleep":sleep_day();return
	if kind=="manualSave":save_game();return
	if kind=="manualLoad":load_game();return
	match kind:
		"newGame","refuge":
			if has_saved_game():modal="confirmNew";menu_notice="";release_keyboard()
			else:start_refuge()
		"confirmNew":
			if modal=="confirmNew":start_refuge()
		"loadStart":
			if load_game():close_dialog()
		"closeMarket":close_dialog()
		"welcome":modal="welcome";menu_notice="";release_keyboard()
		"furnished":state=PARTIDA.furnished(true,true);building=null;hover=null;selected=null;reset_view();modal="";set_zoom(camera_level)
		"empty":close_dialog()
		"tutorial":tutorial=not tutorial
		"management":open_dialog("general")
		"options":open_dialog("options")
		"recipes":open_dialog("recipes")
		"zoomOut":set_zoom(camera_level-0.1)
		"zoomIn":set_zoom(camera_level+0.1)
		"toggleCatalog":drawer=not drawer
		"exitConstruction":stop_build(false);construction=false;build_pointer=null;update_camera()
		"rotate":if building!=null:building.rot=(int(building.rot)+1)%4
		"cancelBuild":stop_build()
		"confirm":
			if building==null or hover==null:return
			var result := BUILD.place(state,building.type,hover.x,hover.y,building.rot,building.moving)
			if not result.ok:notify(result.error,true);return
			stop_build();notify("Objeto instalado. As rotas foram atualizadas.")
		"store":
			if building==null or building.moving==null:return
			var result := BUILD.remove(state,building.moving)
			if not result.ok:notify(result.error,true);return
			stop_build();notify("Objeto guardado e valor devolvido.")
		"removeTableKit":
			if building==null or building.moving==null:return
			var result := BUILD.remove_kit(state,building.moving)
			if not result.ok:notify(result.error,true);return
			stop_build();notify("Kit retirado e valor devolvido. A mesa ficou vazia.")
func widget(event: Dictionary) -> void:
	var path: String = event.get("path","")
	if root_actions.has(path):root_action(root_actions[path]);return
	if admin_ui.controls.actions.has(path):admin_action(admin_ui.controls.actions[path],event.get("value"));return
	if game_ui.controls.actions.has(path):world_action(game_ui.controls.actions[path]);return
	if inventory_ui.actions.has(path) and modal=="management" and mode=="container":
		var action: Dictionary = inventory_ui.actions[path];var kitchen = INTERACT.KITCHEN.new()
		var result: Dictionary = kitchen.recover(state,action.index) if action.kind=="recover" else kitchen.storage(state,action.id,action.kind,action.get("index",0))
		if result.ok and action.kind!="put":close_dialog()
		notify(result.message,not result.ok);return
	if tools_ui.controls.actions.has(path) and modal=="management" and mode=="computer" and tab=="tools":
		var ok := ADMIN.buy_tool(state,tools_ui.controls.actions[path].item);generation+=1;notify("Item nas mãos." if ok else "Confira o saldo e libere as mãos.",not ok);return
	if catalog_ui.controls.actions.has(path) and construction and drawer:
		var action: Dictionary = catalog_ui.controls.actions[path]
		if action.has("category"):
			catalog_ui.category=action.category;generation+=1
		else:begin_build(action.type)
func button(title: String,action: String,disabled: bool = false,id: String = "",art: Array = []) -> Dictionary:
	var path := "nativo:sessao:"+action
	if not disabled:root_actions[path]=action
	return {"tag":"button","text":title,"label":title,"path":path,"disabled":disabled,"id":id,"art":art}
func node(tag: String,children: Array,id: String = "",cls: String = "") -> Dictionary:return {"tag":tag,"children":children,"id":id,"cls":cls}
func text(value: String) -> Dictionary:return {"tag":"text","text":value}
func label(value: String) -> Dictionary:return node("p",[text(value)])
func ui() -> Dictionary:
	root_actions.clear();game_ui.controls.actions.clear();admin_ui.controls.actions.clear();inventory_ui.actions.clear();tools_ui.controls.actions.clear();catalog_ui.controls.actions.clear()
	if modal=="confirmNew":
		return {"modal":node("dialog",[node("h1",[text("Começar um novo jogo?")]),label("O progresso salvo será substituído."),button("Começar novo jogo","confirmNew"),button("Voltar","welcome")],"confirmNew")}
	if modal=="welcome":
		var items: Array = [node("h1",[text("Entre Esquinas")]),button("Novo jogo","newGame"),button("Carregar jogo","loadStart",not has_saved_game())]
		if not menu_notice.is_empty():items.append(label(menu_notice))
		return {"modal":node("dialog",items,"welcome")}
	if modal=="market":
		var traveler: bool = mode=="traveler"
		var items: Array = [node("h1",[text("Nina · Caravana" if traveler else "Beto · Mercador")]),label("Disponível: $%.2f"%state.cash),label("Entrega incluída na geladeira. Estoque limitado; reposição ao amanhecer."),button("Voltar ao jogo","closeMarket")]
		if traveler and state.has("startKit") and "canja" not in state.startKit.recipes:items.append(button("Aprender canja · $30","learnCanja",state.cash<MARKET.RECIPE_COST))
		var stock: Dictionary = {"frango":state.market.travelStock} if traveler else state.market.stock
		var cards: Array = []
		for food in stock:
			var card: Array = [node("b",[text(INTERACT.INV.ITEMS.data[food].name)]),FOOD_UI.icon(food),label("Estoque: "+str(int(stock[food])))]
			for amount in [1,5]:card.append(button("Comprar "+str(amount)+" "+INTERACT.INV.ITEMS.data[food].name+" · $"+str(int(amount*INTERACT.INV.ITEMS.data[food].cost)),"marketBuy:"+food+":"+str(amount),not MARKET.error(state,food,amount,traveler).is_empty()))
			var reason := MARKET.error(state,food,1,traveler)
			if not reason.is_empty():card.append(label(reason))
			cards.append(node("div",card,"","inventoryPane"))
		items.append(node("div",cards,"","splitInventories"))
		if not menu_notice.is_empty():items.append(label(menu_notice))
		return {"modal":node("dialog",items,"market")}
	if modal=="management":
		var panel: Variant = null
		if mode=="container":panel=inventory_ui.render(state,dialog_object)
		elif mode=="recipes":panel=recipe_ui.render(state)
		elif mode=="computer" and tab=="tools":panel=tools_ui.render(state)
		if mode=="options" and tab=="save":
			var raw := str(values.get(SAVE_KEY,""))
			var saved: Variant = JSON.parse_string(raw) if not raw.is_empty() else null
			var day: Variant = saved.get("day") if saved is Dictionary else null
			var valid_day: bool = (day is int or day is float) and is_finite(day) and day>=1 and day==floor(day)
			var title := "Jogo salvo • Dia "+str(int(day)) if valid_day else "Nenhum jogo salvo" if raw.is_empty() else "Salvamento inválido"
			panel=node("div",[label(title),button("Dormir e salvar","sleep",ADMIN.pending(state) or state.open or state.closing),button("Salvar jogo","manualSave"),button("Carregar jogo","manualLoad",not has_saved_game())],"panel")
		return {"modal":admin_ui.render(state,{"mode":mode,"tab":tab,"object":dialog_object,"camera":camera_level,"generation":generation,"notice":menu_notice},panel)}
	if construction:
		var result := {"catalog":node("div",[button("Construção","toggleCatalog")],"constructionControls")}
		if drawer:result.drawer=node("div",[node("div",[node("b",[text("Modo construção")]),button("Voltar ao jogo","exitConstruction")],"","constructionHead"),label("Jogo pausado • arraste o cenário para explorar"),label("Disponível: $%.2f"%state.cash),catalog_ui.render(state)],"constructionDrawer")
		if building!=null:
			var error = preview_error()
			var is_kit: bool = BUILD.TABLE_KITS.has(building.type)
			var hint := "Toque sobre uma mesa de trabalho vazia." if is_kit else "Toque em uma célula do setor indicado." if hover==null else "Posição válida. Arraste o mapa para explorar. A seta da cadeira aponta para a mesa."
			var mirror: bool = BUILD.CATALOG.data[building.type].has("counterPart")
			var actions: Array = [] if is_kit else [button("Espelhar ↔" if mirror else "Girar ↻","rotate")]
			actions.append(button("Confirmar posição","confirm",hover==null or error!=null))
			if building.moving!=null:
				var table = BUILD.find(state.objects,building.moving)
				if table!=null and not BUILD.installed_kit(table).is_empty():actions.append(button("Retirar kit","removeTableKit"))
				actions.append(button("Guardar e reembolsar","store"))
			actions.append(button("Cancelar","cancelBuild"))
			result.build=node("div",[node("b",[text(("Mover: " if building.moving!=null else "Instalar: ")+BUILD.CATALOG.data[building.type].name)]),label(error if error!=null else hint),node("div",actions,"","buildActions")],"buildBar")
		return result
	var door := CAMERA.door(state,camera,viewport,rect,false,false,false)
	var result: Dictionary = game_ui.render(state,{"selectedObject":selected,"constructionMode":false,"modal":false,"building":building,"doorHidden":door.hidden,"cleanView":true},velocity)
	result.dock=node("div",[button("Gestão","management",false,"menuBtn",game_ui.icon("note")),button("Opções","options",false,"optionsBtn",game_ui.icon("options")),button("Livro de receitas","recipes")],"dock")
	result.actions=node("div",[button("−","zoomOut",camera_level<=0.7),button("+","zoomIn",camera_level>=2)],"actions")
	return result
func step(dt: float,events: Array) -> Dictionary:
	var previous_phase: String = state.refuge.phase if REFUGE.active(state) else ""
	for event in events:
		if event.get("kind")=="refuge":refuge_action(str(event.get("action","")));continue
		if REFUGE.blocked(state):continue
		match event.get("kind",""):
			"widget":widget(event)
			"pointer":pointer(event)
			"key":key(event)
			"blur":release_keyboard()
	clock+=dt
	checkpoint()
	if not hidden and (modal.is_empty() or (modal=="management" and mode=="container")) and not construction:
		var old_day: int = state.day
		var old_message: String = state.message;var remaining := maxf(0,dt)
		while remaining>1e-9:
			var slice := minf(0.08,remaining)
			if modal.is_empty():keyboard_move()
			simulation.velocity=velocity;simulation.service.random_source=rng
			simulation.step(state,slice);ADMIN.auto_open(state);velocity=simulation.velocity
			if REFUGE.blocked(state):pending=null;release_keyboard()
			elif pending!=null:interact("process")
			remaining=maxf(0,remaining-slice)
		if state.day!=old_day:save_game();checkpoint()
		if state.message!=old_message:notice_until=clock+4.5
		var chop = state.get("chopping")
		var cook = state.get("cooking")
		var audio_stamp := "cut:"+str(int(state.time*4)) if chop!=null else "cook:"+str(int(state.time/2)) if cook!=null else ""
		if not audio_stamp.is_empty() and audio_stamp!=kitchen_sound_stamp:sounds.append(180 if chop!=null else 105)
		kitchen_sound_stamp=audio_stamp
		for object in state.objects:
			if object.get("readyBatch")==null:continue
			var tone: String = str(object.readyBatch.doneAt)+":"+str(object.get("heatStage"))
			if played_heat.get(object.id)==tone:continue
			played_heat[object.id]=tone;sounds.append(660 if object.get("heatStage")=="ready" else 440 if object.get("heatStage")=="over" else 220)
	if REFUGE.active(state) and previous_phase!=state.refuge.phase:
		if state.refuge.phase=="battle":sounds.append(330)
		elif state.refuge.phase in ["aftermath","gameover"]:sounds.append(660 if state.refuge.battle.result in ["calm","held"] else 220)
	update_camera()
	var scene := renderer.draw(state,{"selectedObject":selected,"constructionMode":construction,"building":building,"hover":hover,"feedback":true,"cleanView":true},velocity)
	var door := CAMERA.door(state,camera,viewport,rect,construction,not modal.is_empty(),modal=="welcome")
	var packet := {"singleRoom":state.singleRoom,"compact":state.compact,"room":state.player.room,"camera":[camera.x,camera.y,camera.zoom],"scene":scene,"ui":ui(),"modal":modal,"liveInventory":modal=="management" and mode=="container","refuge":REFUGE.view(state) if REFUGE.blocked(state) and modal!="welcome" else null,"construction":construction,"door":[door.left,door.top],"writes":writes.duplicate(true),"sounds":sounds.duplicate()}
	writes.clear();sounds.clear()
	return packet
