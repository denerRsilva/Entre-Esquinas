extends RefCounted
## Selects, queues and completes one interaction after reaching the target.
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const KITCHEN = preload("res://simulacao/nativa/Cozinha.gd")
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const LOGISTICS = preload("res://simulacao/nativa/Logistica.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const INV = preload("res://simulacao/nativa/Inventario.gd")
const HYGIENE = preload("res://simulacao/nativa/Higiene.gd")
var kitchen = KITCHEN.new()
var service = SERVICE.new()
var pending: Variant = null
var current := true
var building := false
var selected: Variant = null
var clear_input := false
var effects: Array = []
func tell(s: Dictionary,message: String,bad: bool = false) -> Variant:
	s.message=message;effects.append({"kind":"tell","message":message,"bad":bad})
	return null
func go_object(s: Dictionary,o: Dictionary) -> bool:
	var point = MOVE.closest(s,s.player,o)
	if point==null:return false
	s.player.goal=point;clear_input=true;kitchen.manual_moving=false;service.manual_moving=false
	return true
func approach(s: Dictionary,c: Dictionary) -> bool:
	var a: Dictionary = s.player
	var options: Array = []
	for direction in MOVE.DIRS:
		var point := {"room":c.room,"x":c.x+direction.x,"y":c.y+direction.y}
		if not MOVE.blocked(s,point.room,point.x,point.y,a) and MOVE.MAP.route(s,point.room,Vector2i(a.x,a.y),Vector2i(point.x,point.y),a)!=null:options.append(point)
	# Insertion keeps the original N/E/S/W order for equal distances.
	for i in range(1,options.size()):
		var point: Dictionary = options[i]
		var j := i-1
		while j>=0 and absf(options[j].x-a.x)+absf(options[j].y-a.y)>absf(point.x-a.x)+absf(point.y-a.y):options[j+1]=options[j];j-=1
		options[j+1]=point
	if options.is_empty():return false
	MOVE.go(a,options[0]);clear_input=true;kitchen.manual_moving=false;service.manual_moving=false
	return true
func queue(s: Dictionary,kind: String,target: Variant) -> bool:
	var c = service.find(s.customers,target) if kind=="customer" else null
	var o = BUILD.find(s.objects,target) if kind!="customer" else null
	if c!=null and c.state not in ["waiting","ordered"]:return false
	if c==null and o==null:return false
	if not (approach(s,c) if c!=null else go_object(s,o)):
		tell(s,"Não há passagem até o alvo.",true);return true
	pending={"kind":kind,"target":target,"until":s.time+30}
	if c!=null:pending.phase=c.state
	current=true;process(s)
	return true
func physical(s: Dictionary,o: Dictionary,action: String) -> Variant:
	selected=o.id
	if not go_object(s,o):return tell(s,"Não há passagem.",true)
	pending={"kind":"physical","target":o.id,"action":action,"index":s.selectedSlot,"until":s.time+30};current=true;process(s)
	return true
func queue_floor(s: Dictionary,key: String) -> bool:
	if not HYGIENE.free_hands(s,s.player):return false
	var target = HYGIENE.target(s,s.player,key)
	if target==null:return false
	play_go(s,target.point);pending={"kind":"mop","target":key,"until":s.time+30}
	current=true;process(s);return true
func primary(s: Dictionary,o: Dictionary) -> Variant:
	if o.type in ["computer","receiving","fridge","cold","shelf","potRack"]:
		if not go_object(s,o):return false
		pending={"kind":"utility" if o.type in ["computer","receiving"] else "storage","target":o.id,"until":s.time+30};current=true;process(s);return true
	var p = s.player.get("hand")
	var item: String = p.item if p!=null else ""
	if KITCHEN.STORE.is_support_surface(o):
		if p!=null and KITCHEN.STORE.is_pot(item):return physical(s,o,"support")
		if p==null and o.get("support")!=null:return physical(s,o,"takePan")
		return false
	if o.type=="prep":return physical(s,o,"chop") if item in ["frango","legumes"] and s.get("chopping")==null and s.get("plating")==null else false
	if o.type=="stove":
		var pan = o.get("pan")
		var action: Variant = null
		if pan==null or pan=="":action="installPan" if KITCHEN.STORE.is_pot(item) else null
		elif pan.begins_with("pot_"):action="takePan" if p==null else null
		elif pan!="cookingPot":
			if p!=null and item in ["arroz","legumes_cut","frango_cut"]:action="add"
			elif p==null and kitchen.RECIPES.recognized(o)!=null:action="cook"
			elif p==null and o.get("ingredients",[]).is_empty():action="takePan"
		return physical(s,o,action) if action!=null else false
	if o.type=="kitchen":
		var action: Variant = null
		if item=="plate":action="installPlates"
		elif item.begins_with("dish_"):action="putDish"
		elif p!=null:action="plate" if INV.ITEMS.data.get(item,{}).get("servings",0)>0 else "support" if item=="pot" else null
		elif SERVICE.STORE.ready_count(o)>0:action="takeDish"
		elif o.get("support")!=null:action="plate" if o.support.item.begins_with("pot_") else "takePan"
		elif o.plates>0:action="takePlates"
		return physical(s,o,action) if action!=null else false
	if o.type=="sink" and (item=="dirtyPlate" or (p==null and o.get("dirtyPlates",0)>0)):return queue(s,"wash",o.id)
	if o.type in ["sink","bin"] and INV.ITEMS.data.get(item,{}).has("recipe"):return physical(s,o,"discardHand")
	var table = o if o.type=="table" else BUILD.chair_table(o,s.objects) if o.type=="chair" else null
	if table==null:return false
	# Hands already carrying a dirty pile keep collecting instead of trying
	# to serve another guest at the same table.
	if item=="dirtyPlate" and p.n<INV.HAND_PLATE_CAPACITY and kitchen.DISHES.count(s,table)>0:return queue(s,"clean",table.id)
	if item=="dirtyPlate":return false
	var chairs: Array = []
	for chair in s.objects:
		if chair.type!="chair":continue
		var linked = BUILD.chair_table(chair,s.objects)
		if linked!=null and linked.id==table.id:chairs.append(chair.id)
	var customers: Array = []
	for c in s.customers:
		if c.seat in chairs and c.state in ["waiting","ordered"]:customers.append(c)
	var target: Variant = null
	for c in customers:
		if c.state=="ordered" and (INV.count(s.inventory,"dish_"+c.recipe)>0 or item=="dish_"+c.recipe or (s.player.get("carry")!=null and s.player.carry.get("order")==c.order)):target=c;break
	if target==null:
		for c in customers:
			if c.state=="waiting":target=c;break
	if target==null and not customers.is_empty():target=customers[0]
	if target!=null:return queue(s,"customer",target.id)
	for id in chairs:
		if s.dirtyTables.get(str(int(id)),0)>0:return queue(s,"clean",table.id)
	if HYGIENE.can_wipe(s,table) and HYGIENE.free_hands(s,s.player):return queue(s,"wipe",table.id)
	return false
func process(s: Dictionary) -> void:
	var job = pending
	if job==null:return
	if job.kind in ["computer","receiving"]:
		if not current or s.time>job.until:pending=null;return
		var point := {"room":"restaurant","x":16 if job.kind=="computer" else 21,"y":12}
		if s.player.get("motion")!=null or not service.near(s.player,point):return
		pending=null
		if job.kind=="computer":effects.append({"kind":"dialog","mode":"computer"})
		else:tell(s,LOGISTICS.collect(s,kitchen))
		return
	if not current or building or s.time>job.until:pending=null;return
	if job.kind=="mop":
		if not s.get("floorDirt",{}).has(job.target) or not HYGIENE.free_hands(s,s.player):pending=null;return
		if HYGIENE.mop(s,s.player,job.target):pending=null
		return
	if job.kind=="serviceSign":
		if s.player.get("motion")!=null or not service.near(s.player,job.get("door",{"room":"restaurant","x":7,"y":14})):return
		pending=null
		if s.open!=job.wasOpen or s.period!=job.period or s.closing or s.clock.ending:return
		ADMIN.toggle(s);tell(s,s.message,not s.open and not s.closing);return
	var c = service.find(s.customers,job.target) if job.kind=="customer" else null
	var o = BUILD.find(s.objects,job.target) if job.kind!="customer" else null
	if (job.kind=="customer" and (c==null or c.state!=job.get("phase"))) or (job.kind!="customer" and o==null):pending=null;return
	if s.player.get("motion")!=null:return
	if not (service.near(s.player,c) if c!=null else kitchen.near(s,o)):return
	pending=null
	if c!=null:
		var ok: bool = service.interact(s,c.id);tell(s,s.message,not ok)
	elif job.kind=="physical":
		var result: Dictionary = kitchen.physical(s,o.id,job.action);tell(s,result.message,not result.ok)
	elif job.kind=="utility":
		if o.type=="computer":effects.append({"kind":"dialog","mode":"computer"})
		else:tell(s,LOGISTICS.collect(s,kitchen))
	elif job.kind=="storage":effects.append({"kind":"inventory","id":o.id})
	else:
		var result: Dictionary = kitchen.wash(s,o.id) if job.kind=="wash" else kitchen.wipe(s,o.id) if job.kind=="wipe" else kitchen.collect_dirty(s,o.id)
		tell(s,result.message,not result.ok)
func play_go(s: Dictionary,point: Dictionary) -> void:
	MOVE.go(s.player,point);clear_input=true;kitchen.manual_moving=false;service.manual_moving=false
func refresh() -> void:effects.append({"kind":"refresh"})
func pointer_down(s: Dictionary,pointer: Dictionary) -> void:
	var x := int(floor(pointer.world.x))
	var y := int(floor(pointer.world.y))
	var room: String = s.player.room
	if pointer.construction:
		if pointer.get("building")==null:
			for o in s.objects:
				if o.room==room and MOVE.MAP.rect(o).has_point(Vector2i(x,y)):
					effects.append({"kind":"beginBuild","type":o.type,"moving":o.id});return
		effects.append({"kind":"capture","x":pointer.clientX,"y":pointer.clientY,"pointerId":pointer.get("pointerId")})
		if pointer.get("building")!=null:effects.append({"kind":"preview","x":x,"y":y})
		return
	selected=null
	for portal in MOVE.PORTALS[room]:
		if portal.x==x and portal.y==y:
			selected="portal:"+room+":"+str(x)+":"+str(y)
			play_go(s,{"room":portal.to,"x":portal.spawn[0],"y":portal.spawn[1]});refresh();return
	for c in s.customers:
		if c.room==room and c.x==x and c.y==y and c.state in ["waiting","ordered"]:
			selected=c.id;queue(s,"customer",c.id);refresh();return
	for o in s.objects:
		if o.room!=room or not MOVE.MAP.rect(o).has_point(Vector2i(x,y)):continue
		selected=o.id
		if primary(s,o):refresh();return
		if not go_object(s,o):tell(s,"Móvel sem acesso.",true)
		refresh();return
	for person in MOVE.ACTORS.actors(s):
		if person.id!=s.player.id and person.room==room and person.x==x and person.y==y:
			selected=person.id;approach(s,person);refresh();return
	var dirt_key := str(x)+","+str(y)
	if room=="restaurant" and s.get("floorDirt",{}).has(dirt_key) and HYGIENE.free_hands(s,s.player):
		selected="floor:"+dirt_key
		if queue_floor(s,dirt_key):refresh();return
	if not s.singleRoom and room=="restaurant" and ((x>=16 and x<=17 and y>=10 and y<=11) or (x>=20 and x<=22 and y==11)):
		var computer: bool = x<=17
		selected="computer" if computer else "receiving"
		play_go(s,{"room":room,"x":16 if computer else 21,"y":12})
		pending={"kind":selected,"until":s.time+30};current=true;process(s);refresh();return
	if x<0 or x>=24 or y<0 or y>=16:return
	if MOVE.MAP.route(s,room,Vector2i(s.player.x,s.player.y),Vector2i(x,y),s.player)==null:tell(s,"Passagem bloqueada. Toque em uma célula livre.",true);return
	play_go(s,{"room":room,"x":x,"y":y,"offsetX":pointer.world.x-x-0.5,"offsetY":pointer.world.y-y-0.5});refresh()
