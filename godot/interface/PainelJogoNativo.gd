extends RefCounted
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const CALENDAR = preload("res://simulacao/nativa/Calendario.gd")
const KITCHEN = preload("res://simulacao/nativa/Cozinha.gd")
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const SCENE = preload("res://simulacao/nativa/Cena.gd")
const ICONS = preload("res://simulacao/nativa/icones-controle.json")
var controls = preload("res://interface/InventariosNativos.gd").new()
var kitchen = KITCHEN.new()
var service = SERVICE.new()
var first_context := ""
func node(tag: String,children: Array,id: String = "",cls: String = "") -> Dictionary:return {"tag":tag,"id":id,"cls":cls,"children":children}
func plain(value: String) -> Dictionary:return controls.text(value)
func icon(kind: String) -> Array:return [["svg",'<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="'+ICONS.data[kind]+'"/></svg>']]
func button(title: String,kind: String,action: Dictionary) -> Dictionary:
	var path := "nativo:jogo:"+str(action.kind)+":"+str(action.get("id",action.get("room","")))+":"+str(action.get("command",action.get("x","")))
	if first_context.is_empty():first_context=path
	return controls.button(title,path,action,false,"objectAction",controls.item_art(action.recipe) if action.has("recipe") else icon(kind))
func anchor(s: Dictionary,o: Dictionary) -> Dictionary:
	var lift := 0
	for c in s.customers:
		if SCENE.same(c.id,o.get("id")) or SCENE.same(c.seat,o.get("id")):lift=40
		if o.get("type")=="table":
			for chair in s.objects:
				if chair.id!=c.seat:continue
				var dir: Vector2i = KITCHEN.MOVE.DIRS[int(chair.rot)]
				if KITCHEN.MOVE.MAP.rect(o).has_point(Vector2i(chair.x+dir.x,chair.y+dir.y)):lift=40
	return {"x":o.x,"y":o.y,"w":KITCHEN.MOVE.MAP.rect(o).size.x if o.has("type") else 1,"lift":lift}
func row(s: Dictionary,rows: Dictionary,o: Dictionary) -> Dictionary:
	var key: String = str(o.get("id",o.get("name",str(o.x)+":"+str(o.y))))
	if not rows.has(key):
		rows[key]=node("div",[],"","objectActions");rows[key].anchor=anchor(s,o)
	return rows[key]
func add_physical(target: Dictionary,o: Dictionary,kind: String,title: String,command: String) -> void:
	target.children.append(button(title,kind,{"kind":"physical","id":o.id,"command":command}))
func context(s: Dictionary,model: Dictionary) -> Dictionary:
	first_context=""
	var rows: Dictionary = {}
	var a: Dictionary = s.player
	var selected = model.selectedObject
	if model.constructionMode or model.get("modal",false) or a.get("motion")!=null or kitchen.manual_moving or selected==null:return node("div",[],"context")
	for p in SCENE.PORTALS[a.room]:
		if SCENE.same(selected,"portal:"+a.room+":"+str(int(p.x))+":"+str(int(p.y))) and service.near(a,{"room":a.room,"x":p.x,"y":p.y}):
			var portal: Dictionary = KITCHEN.MOVE.PORTALS[a.room][0]
			row(s,rows,p).children.append(button(p.name,"door",{"kind":"portal","room":portal.to,"x":portal.spawn[0],"y":portal.spawn[1]}))
	for type in ["computer","receiving"]:
		var x := 16 if type=="computer" else 21
		if not (type=="computer" and s.get("refuge") is Dictionary) and SCENE.same(selected,type) and service.near(a,{"room":"restaurant","x":x,"y":12}):row(s,rows,{"x":x,"y":11}).children.append(button("Usar computador" if type=="computer" else "Recolher ingredientes","computer" if type=="computer" else "box",{"kind":type}))
	for o in s.objects:
		if o.type=="computer" and s.get("refuge") is Dictionary:continue
		if not SCENE.same(o.id,selected) or not kitchen.near(s,o):continue
		var target := row(s,rows,o)
		if o.type in ["computer","receiving"]:target.children.append(button("Usar computador" if o.type=="computer" else "Recolher ingredientes","computer" if o.type=="computer" else "box",{"kind":o.type}))
		if o.has("inventory") and o.type not in ["stove","prep","sink","bin"]:target.children.append(button("Abrir "+KITCHEN.BUILD.CATALOG.data[o.type].name,"bag",{"kind":"inventory","id":o.id}))
		var hand = a.get("hand")
		if KITCHEN.STORE.is_support_surface(o):
			if hand==null and o.get("support")!=null:add_physical(target,o,"take","Retirar panela apoiada","takePan")
			elif hand!=null and KITCHEN.STORE.is_pot(hand.item) and KITCHEN.STORE.surface_empty(o):add_physical(target,o,"pot","Apoiar panela","support")
			continue
		if o.type in ["stove","prep","kitchen"]:
			if o.type=="prep":
				if s.get("chopping")!=null and s.chopping.table==o.id:add_physical(target,o,"bin","Cancelar corte","cancelCut")
			elif o.type=="stove":
				if o.get("pan")==null and hand!=null and KITCHEN.STORE.is_pot(hand.item) and KITCHEN.STORE.space(o,hand.item)>0:add_physical(target,o,"pot","Colocar panela no fogão","installPan")
				elif o.get("pan")=="pot":
					if not o.get("ingredients",[]).is_empty():add_physical(target,o,"take","Retirar último ingrediente","removeIngredient")
					if KITCHEN.RECIPES.recognized(o)!=null:add_physical(target,o,"flame","Cozinhar","cook")
			else:
				if hand!=null and hand.item=="plate":add_physical(target,o,"box","Instalar prato das mãos","installPlates")
				elif hand!=null and KITCHEN.INV.ITEMS.data.get(hand.item,{}).get("servings",0)>0:add_physical(target,o,"serve","Empratar","plate")
				elif hand!=null and hand.item.begins_with("dish_") and o.get("support")==null:add_physical(target,o,"pot","Apoiar prato","putDish")
				if o.get("support")!=null:add_physical(target,o,"take","Retirar panela apoiada","takePan")
				if o.utensil:add_physical(target,o,"take","Retirar talher preservado","takeUtensil")
				if o.plates>0:add_physical(target,o,"take","Retirar pratos limpos","takePlates")
				if o.get("support")!=null and o.support.item.begins_with("pot_"):add_physical(target,o,"serve","Empratar uma porção","plate")
				if KITCHEN.STORE.ready_count(o)>0:add_physical(target,o,"serve","Pegar prato nas mãos","takeDish")
				if s.get("plating")!=null and s.plating.prep==o.id:add_physical(target,o,"bin","Cancelar empratamento","cancelPlate")
			continue
		if o.type=="sink":
			var washing = s.get("washing")
			if washing!=null and washing.sink==o.id:add_physical(target,o,"bin","Cancelar lavagem de pratos","cancelWash")
			elif (hand!=null and hand.item=="dirtyPlate") or (hand==null and o.get("dirtyPlates",0)>0 and o.get("cleanPlates",0)<KITCHEN.INV.CLEAN_SINK_CAPACITY):target.children.append(button("Lavar pratos","wash",{"kind":"wash","id":o.id}))
			if o.get("cleanPlates",0)>0 and (hand==null or (hand.item=="plate" and hand.n<KITCHEN.INV.HAND_PLATE_CAPACITY)):add_physical(target,o,"take","Retirar pratos limpos da pia","takeClean")
		if o.type in ["sink","bin"] and hand!=null and KITCHEN.INV.ITEMS.data.get(hand.item,{}).has("recipe"):add_physical(target,o,"bin","Descartar comida das mãos","discardHand")
		if o.type=="table" and not KITCHEN.HYGIENE.can_wipe(s,o):target.children.append(button("Recolher pratos sujos da mesa","wash",{"kind":"clean","id":o.id}))
		if o.type=="table" and KITCHEN.HYGIENE.can_wipe(s,o) and KITCHEN.HYGIENE.free_hands(s,a):target.children.append(button("Limpar mesa","wash",{"kind":"wipe","id":o.id}))
	for c in s.customers:
		if not service.near(a,c):continue
		var chair = service.find(s.objects,c.seat)
		var selected_object = service.find(s.objects,selected)
		var table: Variant = null
		if chair!=null:
			var dir: Vector2i = KITCHEN.MOVE.DIRS[int(chair.rot)]
			for o in s.objects:
				if o.type=="table" and KITCHEN.MOVE.MAP.rect(o).has_point(Vector2i(chair.x+dir.x,chair.y+dir.y)):table=o;break
		if not SCENE.same(selected,c.id) and not SCENE.same(selected,c.seat) and (table==null or not SCENE.same(selected,table.id)):continue
		var target := row(s,rows,selected_object if selected_object!=null else chair if chair!=null else c)
		if c.state=="waiting":target.children.append(button("Anotar pedido","note",{"kind":"customer","id":c.id}))
		if c.state=="ordered":
			target.children.append(button("Servir "+SERVICE.RECIPES.data[c.recipe].name,"serve",{"kind":"customer","id":c.id,"recipe":c.recipe}))
			var order = service.find(s.orders,c.order)
			if model.get("cleanView",false) and order!=null and order.state=="ordered":
				target.children.append(button("Pedido prioritário" if s.priority==order.id else "Priorizar pedido","note",{"kind":"priority","id":order.id}))
	return node("div",rows.values(),"context")
func kitchen_status(s: Dictionary) -> Dictionary:
	var jobs: Array = []
	for pair in [["chopping","table","Cortando ingrediente"],["cooking","stove","Cozinhando "],["plating","prep","Empratando"],["washing","sink","Lavando prato"]]:
		var job = s.get(pair[0])
		if job==null:continue
		var entry: Dictionary = job.duplicate(true)
		entry.label=pair[2]+(SERVICE.RECIPES.data[job.recipe].name if pair[0]=="cooking" else "" if kitchen.near(s,service.find(s.objects,job[pair[1]])) else " • pausado: aproxime-se");jobs.append(entry)
	for o in s.objects:
		if o.get("readyBatch")!=null and str(o.get("pan","")).begins_with("pot_"):
			var heat := KITCHEN.RECIPES.heat(s,o)
			jobs.append({"label":heat.label+" • "+SERVICE.RECIPES.data[o.readyBatch.recipe].name,"total":1,"left":1-heat.value,"heat":heat.stage})
	var children: Array = []
	for job in jobs:
		var parts: Array = [plain(job.label+("" if job.has("heat") else " • "+str(int(ceil(job.left)))+"s"))]
		if job.get("heat")!="burned":parts.append({"tag":"progress","max":job.total,"value":job.total-job.left,"label":job.label,"color":{"ready":"green","over":"yellow","danger":"red"}.get(job.get("heat",""),"blue")})
		children.append(node("label",parts,"","heat-"+job.heat if job.has("heat") else ""))
	return node("div",children,"kitchenStatus")
func comandas(s: Dictionary) -> Array:
	if s.player.room!="restaurant":return []
	# Number actual dining tables, never order IDs or chair IDs. Saves retain
	# object order, so multiple guests at the same table share its number.
	var tables := {}
	for object in s.objects:
		if object.type=="table":tables[object.id]=tables.size()+1
	var result: Array = []
	for order in s.orders:
		if order.state not in ["ordered","cooking","ready"]:continue
		var customer = service.find(s.customers,order.customer)
		if customer==null or customer.state!="ordered":continue
		var chair = service.find(s.objects,customer.seat)
		var table = KITCHEN.BUILD.chair_table(chair,s.objects)
		if table==null or not tables.has(table.id):continue
		result.append({"id":order.id,"table":tables[table.id],"recipe":order.recipe,"ratio":float(service.ratio(customer.experience))})
	return result

func render(s: Dictionary,model: Dictionary,input: Variant) -> Dictionary:
	controls.actions.clear()
	kitchen.manual_moving=input!=null and input.get("moving",false)
	var period := "Almoço" if s.period==0 else "Jantar"
	var hours: Dictionary = ADMIN.hours(s)[int(s.period)]
	var status := "Encerrando o dia" if s.clock.ending else "Concluindo" if s.closing else "Aberto" if s.open else "Encerrado" if s.clock.minute>=hours.end else "Preparação" if s.clock.minute<hours.start else "Fechado"
	var date := CALENDAR.date(int(s.day))
	var summary: String = period+" • "+status+"  ★ "+str(int(s.reputation.score))+"/100 • "+CALENDAR.reputation_level(s.reputation.score)+"    "+CALENDAR.time_text(s.clock.minute)+" • "+date.weekday+" "+str(date.day)+" • "+date.season+" • Ano "+str(date.year)+"  $%.2f"%s.cash
	if model.get("cleanView",false):
		return {"hud":node("div",[plain(summary)],"hud"),"openBtn":null,"ordersHud":null,"comandas":comandas(s),"kitchenStatus":null,"context":context(s,model)}
	var orders: Array = []
	for c in s.customers:
		if c.state!="waiting":continue
		var indicator = service.indicator(s,c)
		var waiting_parts: Array = [plain((indicator.emoji+" " if indicator!=null else "")+"Mesa aguardando pedido"+(" • "+str(int(ceil(indicator.remaining)))+"s de paciência" if indicator!=null else ""))]
		if indicator!=null and indicator.phase!=null:waiting_parts.append({"tag":"progress","max":1,"value":indicator.ratio,"color":"patience","label":"Paciência"})
		orders.append(node("div",waiting_parts,"","orderCard"))
	for order in s.orders:
		if order.state in ["paid","lost"]:continue
		var customer = service.find(s.customers,order.get("customer"))
		var indicator = service.indicator(s,customer) if customer!=null else null
		var extra: String = " • "+indicator.emoji+(" "+str(int(ceil(indicator.remaining)))+"s de paciência" if indicator.phase!=null else " "+indicator.label) if indicator!=null else ""
		var content: Array = [node("b",[plain("#"+str(int(order.id))+" • "),{"tag":"canvas","art":controls.item_art(order.recipe),"label":SERVICE.RECIPES.data[order.recipe].name}]),plain({"ordered":"A preparar","cooking":"No fogão","ready":"A caminho da mesa","eating":"Cliente comendo"}.get(order.state,order.state)+extra+" • espera "+str(int(floor(order.age)))+"s")]
		if indicator!=null and indicator.phase!=null:content.append({"tag":"progress","max":1,"value":indicator.ratio,"color":"patience","label":"Paciência"})
		if order.state=="ordered":content.append(controls.button("Prioritário" if s.priority==order.id else "Priorizar","nativo:jogo:prioridade:"+str(int(order.id)),{"kind":"priority","id":order.id}))
		orders.append(node("div",content,"","orderCard"))
	return {"hud":node("div",[plain(summary)],"hud"),"openBtn":null,"ordersHud":node("div",orders,"ordersHud"),"kitchenStatus":kitchen_status(s),"context":context(s,model)}
