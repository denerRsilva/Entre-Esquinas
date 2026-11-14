extends RefCounted
const MAP = preload("res://simulacao/nativa/Mapa.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const NUM = preload("res://simulacao/nativa/Conservacao.gd")
const CATALOG = preload("res://simulacao/nativa/catalogo.json")
const DIRS = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const TABLE_KITS = {"cuttingKit":"prep","platingKit":"kitchen"}
static func is_worktable(object: Dictionary) -> bool:return object.get("type") in ["worktable","prep","kitchen","counterH","counterV","counterCorner"]
static func installed_kit(object: Dictionary) -> String:
	# Old saves already contain equipped tables; their IDs and contents stay intact.
	return "cuttingKit" if object.type=="prep" else "platingKit" if object.type=="kitchen" else ""
static func table_at(state: Dictionary, x: int, y: int) -> Variant:
	for object in state.objects:
		if is_worktable(object) and object.room=="restaurant" and MAP.rect(object).has_point(Vector2i(x,y)):return object
	return null
static func kit_error(state: Dictionary, type: String, x: int, y: int) -> Variant:
	var error = edit_error(state)
	if error!=null:return error
	var table = table_at(state,x,y)
	if table==null:return "Posicione o kit sobre uma mesa de trabalho vazia."
	if not installed_kit(table).is_empty():return "Retire o kit atual antes de instalar outro."
	if busy(state,table.id):return "Conclua o preparo antes de trocar o kit."
	if state.cash<CATALOG.data[type].price:return "Dinheiro insuficiente."
	return null
static func install_kit(state: Dictionary, type: String, x: int, y: int) -> Dictionary:
	var error = kit_error(state,type,x,y)
	if error!=null:return fail(error)
	var table: Dictionary = table_at(state,x,y)
	table.baseType=table.get("baseType",table.type)
	table.type=TABLE_KITS[type]
	table.tableKit=type
	if table.type=="kitchen":table.merge({"plates":0,"utensil":false,"dishes":{},"dishQuality":{}})
	state.cash-=CATALOG.data[type].price
	state.ledger.investment+=CATALOG.data[type].price
	return {"ok":true,"object":table}
static func remove_kit(state: Dictionary, id: Variant) -> Dictionary:
	var error = edit_error(state)
	if error!=null:return fail(error)
	var table = find(state.objects,id)
	if table==null or not is_worktable(table) or installed_kit(table).is_empty():return fail("Esta mesa não possui kit instalado.")
	if busy(state,id):return fail("Conclua o preparo antes de retirar o kit.")
	for slot in STORE.slots(table):
		if slot!=null:return fail("Retire a comida, a panela e os utensílios antes de retirar o kit.")
	var price: float = CATALOG.data[installed_kit(table)].price
	for key in ["tableKit","plates","utensil","dishes","dishQuality","support","feedback"]:table.erase(key)
	table.type=table.get("baseType","worktable")
	table.erase("baseType")
	state.cash+=price;state.ledger.investment-=price
	return {"ok":true,"object":table}
static func find(objects: Array, id: Variant) -> Variant:
	for object in objects:
		if object.id==id:return object
	return null
static func dirty(state: Dictionary, id: Variant) -> bool:return state.dirtyTables.get(str(int(id)),0)!=0
static func edit_error(state: Dictionary) -> Variant:
	if state.open or not state.customers.is_empty():return "Feche o serviço e conclua os clientes antes de reorganizar."
	for order in state.orders:
		if order.state not in ["paid","lost"]:return "Feche o serviço e conclua os clientes antes de reorganizar."
	return null
static func long_side(chair: Dictionary, table: Dictionary) -> bool:
	var r := MAP.rect(table)
	if r.size==Vector2i(2,1):return chair.x>=r.position.x and chair.x<r.end.x and ((chair.y==r.position.y-1 and chair.rot==2) or (chair.y==r.end.y and chair.rot==0))
	if r.size==Vector2i(1,2):return chair.y>=r.position.y and chair.y<r.end.y and ((chair.x==r.position.x-1 and chair.rot==1) or (chair.x==r.end.x and chair.rot==3))
	return true
static func chair_table(chair: Variant, objects: Array) -> Variant:
	if chair==null:return null
	var dir: Vector2i = DIRS[int(chair.rot)%4]
	for table in objects:
		if table.room==chair.room and table.type=="table" and MAP.rect(table).has_point(Vector2i(chair.x+dir.x,chair.y+dir.y)):return table
	return null
static func seat_table(chair: Variant, objects: Array) -> Variant:
	var table = chair_table(chair,objects)
	return table if table!=null and long_side(chair,table) else null
static func touching(chair: Dictionary, objects: Array) -> Array:
	var result: Array = []
	for table in objects:
		if table.type!="table" or table.room!=chair.room:continue
		for dir in DIRS:
			if MAP.rect(table).has_point(Vector2i(chair.x+dir.x,chair.y+dir.y)):result.append(table);break
	return result
static func geometry(object: Dictionary) -> Array:return [object.id,object.type,object.room,object.x,object.y,object.rot]
static func chair_error(state: Dictionary, chair: Dictionary, objects: Array) -> Variant:
	var tables := touching(chair,objects)
	if tables.is_empty():return null
	var on_end := false
	for table in tables:
		var r := MAP.rect(table)
		if (r.size==Vector2i(2,1) and (chair.x==r.position.x-1 or chair.x==r.end.x)) or (r.size==Vector2i(1,2) and (chair.y==r.position.y-1 or chair.y==r.end.y)):on_end=true
	if not on_end and seat_table(chair,objects)!=null:return null
	var old = find(state.objects,chair.id)
	if old!=null and old.type=="chair" and geometry(old)==geometry(chair):
		var old_tables := touching(chair,state.objects)
		if old_tables.size()==tables.size():
			var same := true
			for i in tables.size():
				if geometry(old_tables[i])!=geometry(tables[i]):same=false
			if same:return null
	return "Posicione a cadeira no lado comprido da mesa, virada para ela. As pontas não aceitam cadeiras."
static func layout_error(state: Dictionary, objects: Array) -> Variant:
	var occupied := {}
	for object in objects:
		if not CATALOG.data.has(object.type) or object.room!=CATALOG.data[object.type].room:return "Objeto fora do setor permitido."
		if TABLE_KITS.has(object.type):return "Os kits precisam ser instalados sobre uma mesa de trabalho."
		var r := MAP.rect(object)
		for y in range(r.position.y,r.end.y):
			for x in range(r.position.x,r.end.x):
				if MAP.wall(object.room,x,y,state) or MAP.fixed(object.room,x,y,state):return "Parede, porta ou infraestrutura reservada."
				for door in MOVE.PORTALS[object.room]:
					if absf(door.x-x)+absf(door.y-y)<=1:return "Parede, porta ou infraestrutura reservada."
				var area: String = CATALOG.data[object.get("baseType",object.type)].area
				if object.room=="restaurant" and ((area=="hall" and x>=14) or (area=="kitchen" and (x<=14 or (not state.get("singleRoom",false) and y>=10))) or (area=="storage" and (x<=14 or (not state.get("singleRoom",false) and y<=10))) or (area=="dryStorage" and x<=14)):return "Mesas e cadeiras: salão. Fogão e geladeira de cozinha: cozinha. Prateleira: cozinha ou estoque. Geladeira de estoque: estoque."
				var key: String = object.room+":"+str(x)+","+str(y)
				if occupied.has(key):return "Esta célula já está ocupada."
				occupied[key]=true
				for actor in NUM.actors(state):
					if actor.room!=object.room:continue
					for cell in MOVE.reserved(actor):
						if cell.x==x and cell.y==y:return "Há uma pessoa nesta posição."
	for chair in objects:
		if chair.type=="chair":
			var error = chair_error(state,chair,objects)
			if error!=null:return error
	var solid := PackedByteArray();solid.resize(24*16)
	var reached := PackedByteArray();reached.resize(24*16)
	for y in 16:
		for x in 24:solid[y*24+x]=1 if MAP.wall("restaurant",x,y,state) or MAP.fixed("restaurant",x,y,state) or occupied.has("restaurant:"+str(x)+","+str(y)) else 0
	var queue: Array = [13*24+7]
	reached[queue[0]]=1
	var head := 0
	while head<queue.size():
		var cell: int = queue[head];head+=1
		var x := cell%24
		var y := int(cell/24)
		for dir in DIRS:
			var nx: int = x+dir.x
			var ny: int = y+dir.y
			if nx<0 or ny<0 or nx>=24 or ny>=16:continue
			var next: int = ny*24+nx
			if solid[next] or reached[next]:continue
			reached[next]=1;queue.append(next)
	if solid[13*24+7]:reached[13*24+7]=0
	for door in MOVE.PORTALS.restaurant:
		if not reached[int(door.y)*24+int(door.x)]:return "A disposição bloqueia uma porta."
	var candidate_state := state.duplicate()
	candidate_state.objects=objects
	for object in objects:
		if object.room!="restaurant":continue
		var accessible := false
		for point in MOVE.access(candidate_state,object):
			if reached[int(point.y)*24+int(point.x)]:accessible=true;break
		if not accessible:return "Deixe uma passagem até cada móvel."
	return null
static func fail(message: String) -> Dictionary:return {"ok":false,"error":message}
static func busy(state: Dictionary, id: Variant) -> bool:
	return (state.get("chopping")!=null and state.chopping.get("table")==id) or (state.get("cooking")!=null and state.cooking.get("stove")==id) or (state.get("plating")!=null and state.plating.get("prep")==id)
static func dirty_table(state: Dictionary, object: Dictionary) -> bool:
	if object.type!="table":return false
	for chair in state.objects:
		if chair.type=="chair":
			var table = chair_table(chair,state.objects)
			if table!=null and table.id==object.id and dirty(state,chair.id):return true
	return false
static func place(state: Dictionary, type: Variant, x: Variant, y: Variant, rotation: Variant = 0, moving: Variant = null) -> Dictionary:
	var error = edit_error(state)
	if error!=null:return fail(error)
	if not CATALOG.data.has(type):return fail("Objeto desconhecido.")
	var data: Dictionary = CATALOG.data[type]
	if state.get("singleRoom",false) and type=="cold":return fail("Esta planta não possui estoque separado.")
	if type in ["computer","receiving"]:
		for object in state.objects:
			if object.type==type and object.id!=moving:return fail("Este equipamento já está instalado.")
	if not NUM.integer(x) or not NUM.integer(y) or not NUM.integer(rotation):return fail("Posição inválida.")
	if TABLE_KITS.has(type):
		if moving!=null:return fail("Mova a mesa para transportar o kit instalado.")
		return install_kit(state,type,int(x),int(y))
	var old = find(state.objects,moving) if moving!=null and moving!=0 else null
	if moving!=null and moving!=0 and (old==null or old.type!=type):return fail("Objeto não encontrado.")
	if old!=null:
		if busy(state,old.id):return fail("Conclua o preparo antes de mover.")
		if dirty(state,old.id) or dirty_table(state,old):return fail("Recolha os pratos sujos antes de mover.")
	var object: Dictionary = old.duplicate(true) if old!=null else {}
	object.merge({"id":old.id if old!=null else state.serial,"type":type,"x":x,"y":y,"rot":posmod(int(rotation),4),"room":data.room},true)
	match type:
		"stove":
			object.ingredients=old.get("ingredients",[]) if old!=null else []
			object.pan=old.get("pan") if old!=null else null
			if old!=null and old.get("readyBatch")!=null:object.readyBatch=old.readyBatch.duplicate(true);object.burned=old.get("burned",false)
		"kitchen":
			object.merge({"plates":old.get("plates",0) if old!=null else 0,"utensil":old.get("utensil",false) if old!=null else false,"dishes":old.get("dishes",{}) if old!=null else {},"dishQuality":old.get("dishQuality",{}) if old!=null else {}},true)
		"shelf","cold","fridge","potRack":
			if old!=null:object.inventory=old.inventory
			else:
				object.inventory=[]
				object.inventory.resize(3 if type=="potRack" else 10)
	var objects: Array = []
	for candidate in state.objects:
		if candidate.id!=moving:objects.append(candidate)
	objects.append(object)
	error=layout_error(state,objects)
	if error!=null:return fail(error)
	if old==null and state.cash<data.price:return fail("Dinheiro insuficiente.")
	if old==null:state.cash-=data.price;state.ledger.investment+=data.price;state.serial+=1
	state.objects=objects
	STORE.sync(state)
	return {"ok":true,"object":object}
static func remove(state: Dictionary, id: Variant) -> Dictionary:
	var error = edit_error(state)
	if error!=null:return fail(error)
	var object = find(state.objects,id)
	if object==null:return fail("Objeto não encontrado.")
	if object.type=="receiving":
		for amount in state.inv.receiving.values():
			if amount>0:return fail("Recolha as entregas antes de guardar o recebimento.")
		for delivery in state.deliveries:
			if delivery.pending>0:return fail("Recolha as entregas antes de guardar o recebimento.")
	if dirty_table(state,object):return fail("Recolha os pratos sujos antes de guardar a mesa.")
	if busy(state,id) or dirty(state,object.id):return fail("Retire os itens instalados e a comida antes de guardar.")
	for slot in STORE.slots(object):
		if slot!=null:return fail("Retire os itens instalados e a comida antes de guardar.")
	var objects: Array = []
	for candidate in state.objects:
		if candidate.id!=id:objects.append(candidate)
	state.objects=objects
	state.dirtyTables.erase(str(int(id)))
	var refund: float = CATALOG.data[object.get("baseType",object.type)].price
	if object.has("baseType"):refund+=CATALOG.data[installed_kit(object)].price
	state.cash+=refund
	state.ledger.investment-=refund
	return {"ok":true}
static func seats(state: Dictionary) -> Array:
	var result: Array = []
	for chair in state.objects:
		if chair.type!="chair" or seat_table(chair,state.objects)==null:continue
		if MAP.route(state,"restaurant",Vector2i(7,13),Vector2i(chair.x,chair.y),{"seat":chair.id})!=null:result.append(chair.id)
	return result
static func kit(state: Dictionary) -> Array:
	var result: Array = []
	if seats(state).is_empty():result.append("mesa com cadeira voltada para ela e caminho livre")
	for pair in [["stove","fogão"],["fridge","geladeira na cozinha"],["kitchen","mesa de preparo"]]:
		var found := false
		for object in state.objects:
			if object.type==pair[0]:found=true;break
		if not found:result.append(pair[1])
	return result
