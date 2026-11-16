extends RefCounted
## Composes world details around the native TileMaps, furniture and characters.
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const INV = preload("res://simulacao/nativa/Inventario.gd")
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
const RECIPES = preload("res://simulacao/nativa/Receitas.gd")
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const PORTALS = {"restaurant":[{"x":7,"y":14,"name":"Sair para a cidade"}],"street":[{"x":12,"y":5,"name":"Entrar no restaurante"}],"stock":[{"x":21,"y":14,"name":"Voltar à cozinha"}]}
var commands: Array = []
var alpha := 1.0
var clean_view := true
var facing: Dictionary = {}
var velocity: Variant = null
var identities: Dictionary = {}
var service = SERVICE.new()
static func same(a: Variant,b: Variant) -> bool:
	if (a is String)!=(b is String):return false
	return a==b
func box(x: float,y: float,w: float,h: float,color: String) -> void:commands.append(["rect",FOOD.pixel(x),FOOD.pixel(y),FOOD.pixel(w),FOOD.pixel(h),color,alpha])
func text(value: String,x: float,y: float,size: int,color: String,align: String = "center") -> void:commands.append(["text",FOOD.pixel(x),FOOD.pixel(y),value,size,color,align])
func label(value: String,x: float,y: float,color: String = "#25473d") -> void:
	if clean_view:return
	var width := (value.to_utf16_buffer().size()/2)*10*0.60+12
	box(x-width/2,y-10,width,16,color);text(value,x,y+2,10,"#fff0ce")
func food(item: String,x: float,y: float,w: float,h: float) -> bool:
	if FOOD.food_key(item) not in FOOD.KEYS:return false
	commands.append(["food",item,x,y,w,h,1,1,0,0,alpha]);return true
func star(quality: int,x: float,y: float,size: float) -> void:
	if quality==0:return
	var points: Array = []
	for i in 10:
		var angle := -PI/2+i*PI/5
		var radius := size*(0.22 if i%2 else 0.5)
		points.append([x+size/2+cos(angle)*radius,y+size/2+sin(angle)*radius])
	commands.append(["poly",points,["","#c5c9cc","#ffd14c","#c286ff"][quality]])
func plate(x: float,y: float,recipe: Variant = null,dirty: bool = false,quality: int = 0,size: Vector2 = FOOD.DISH_SIZE) -> void:
	if not dirty and recipe!=null and food(recipe,x-size.x/2,y-size.y/2,size.x,size.y):star(quality,x+3,y-8,8);return
	empty_plate(x,y)
	if dirty:box(x-3,y,3,2,"#805332");box(x+2,y-2,2,2,"#9a6434")
func pot(x: float,y: float,filled: bool,active: bool,time: float) -> void:
	if active:box(x-8,y+3,16,4,"#f5a331");box(x-5,y+5,10,2,"#cb5428")
	commands.append(["img","taverna/moveis.png",710,802,180,140,FOOD.pixel(x-13),FOOD.pixel(y-12),26,20,alpha])
	if filled:box(x-5,y-7,10,3,"#d1963d")
	if active:
		for i in 3:box(x-5+i*5,y-9-fmod(time*7+i*6,18),2,4,"#f6ecd5aa")
func empty_plate(x: float,y: float) -> void:
	var crop := FOOD.CLEAN_PLATE_SOURCE
	var size := FOOD.CLEAN_PLATE_SIZE
	commands.append(["img","modular/prato-vazio.png",crop.position.x,crop.position.y,crop.size.x,crop.size.y,FOOD.pixel(x-size.x/2),FOOD.pixel(y-size.y/2),size.x,size.y,alpha])
func ingredient(item: String,x: float,y: float) -> void:
	var size := FOOD.INGREDIENT_SIZE
	food(item,x-size.x/2,y-size.y/2,size.x,size.y)
static func held(s: Dictionary,a: Dictionary) -> Variant:
	if a.get("hand")!=null:return a.hand
	var carry = a.get("carry")
	if carry==null:return null
	if carry.kind=="dish":
		for order in s.orders:
			if order.id==carry.order:return {"item":"dish_"+order.recipe,"n":1,"quality":carry.get("quality",0)}
	elif carry.kind=="food":return {"item":carry.food,"n":carry.n,"quality":carry.get("quality",0)}
	elif carry.kind=="dirtyPlates":return {"item":"dirtyPlate","n":carry.n}
	return null
func draw_held(s: Dictionary,p: Variant,x: float,y: float) -> void:
	if p==null:return
	var item: String = p.item
	var portions: float = INV.ITEMS.data.get(item,{}).get("servings",0)
	if item in ["pot","cookingPot"] or portions>0:pot(x,y,portions>0,false,s.time);return
	if item.begins_with("dish_"):plate(x,y,INV.ITEMS.data[item].recipe,false,p.get("quality",0));return
	if item=="plate":
		for i in mini(int(p.n),INV.HAND_PLATE_CAPACITY):empty_plate(x,y-i*3)
		return
	if item=="dirtyPlate":
		for i in mini(int(p.n),INV.HAND_PLATE_CAPACITY):plate(x,y-i*3,null,true)
		return
	if item=="spoon":box(x-1,y-3,3,16,"#527576");box(x-4,y-9,9,8,"#d6e5d9");box(x-2,y-8,5,5,"#90aaa3");return
	ingredient(item,x,y);star(p.get("quality",0),x+4,y-13,9)
func direction(a: Dictionary) -> String:
	var token: Variant = identities.get(a.id,a.id)
	var result: String = facing.get(token,"down")
	var input = velocity if a.id=="player" else null
	var dx := 0.0;var dy := 0.0
	if input!=null:
		dx=input.get("moveX",input.dx) if input.get("moving",false) else input.dx
		dy=input.get("moveY",input.dy) if input.get("moving",false) else input.dy
	elif a.get("motion")!=null:dx=a.motion.toX-a.motion.fromX;dy=a.motion.toY-a.motion.fromY
	else:return result
	if absf(dy)>1e-7:result="up" if dy<0 else "down"
	elif absf(dx)>1e-7:result="left" if dx<0 else "right"
	facing[token]=result
	return result
func actor(s: Dictionary,a: Dictionary,selected: Variant,construction: bool) -> void:
	var pose := MOVE.position(a)
	var x: float = pose.x*40+20;var bottom: float = pose.y*40+38
	box(x-12,bottom-3,24,5,"#4c3e3540")
	var digits := ""
	for ch in str(a.id):
		if ch>="0" and ch<="9":digits+=ch
	var number := int(digits) if not digits.is_empty() else 0
	var skin: int = 8 if a.id=="player" else 9 if a.id=="worker2" else 10 if a.id=="worker1" else 12+number%3 if a.id.begins_with("client") else 11 if a.id in ["lia","nina"] else 10+number%2
	var dir := direction(a)
	# Seated customers face their table, not their last walking direction.
	if a.get("state","") in ["waiting","ordered","eating"] and a.get("motion")==null:
		var chair = BUILD.find(s.objects,a.get("seat"))
		if chair!=null and a.room==chair.room and a.x==chair.x and a.y==chair.y and BUILD.seat_table(chair,s.objects)!=null:
			dir=["up","right","down","left"][posmod(int(chair.rot),4)]
			facing[identities.get(a.id,a.id)]=dir
	var moving: bool = a.get("motion")!=null or (a.id=="player" and velocity!=null and velocity.get("moving",false))
	commands.append(["cook",x,bottom,dir,moving] if a.id=="player" else ["npc",a.id,skin,x,bottom,dir,moving])
	if a.get("noteJob")!=null:
		var job: Dictionary = a.noteJob
		commands.append(["progress","note:"+str(a.id),x-22,bottom-78,44,8,1-job.left/job.total,"blue"])
	draw_held(s,held(s,a),x+(-12 if dir=="left" else 12 if dir=="right" else 8),bottom-(32 if dir=="up" else 22))
	if construction:return
	if a.id=="player":label("Você",x,bottom+12,"#77603a")
	elif a.id.begins_with("worker"):label("Logística" if a.id=="worker1" else "Garçom",x,bottom+11)
	elif a.get("recipe")!=null and a.get("order")!=null and a.state in ["ordered","eating"]:
		if not clean_view:box(x-17,bottom-82,34,28,"#25473df2")
		food(a.recipe,x-15,bottom-82,30,26)
	elif same(selected,a.id):label({"lia":"Lia","beto":"Beto","nina":"Nina"}.get(a.id,"Cliente"),x,bottom+11)
	if a.wait>=5:label("Aguardando passagem",x,bottom-68,"#78503a")
	if a.get("experience")!=null:
		var indicator = service.indicator(s,a)
		if indicator!=null:
			if not clean_view:box(x+18,bottom-82,28,25,"#25473df2");text(indicator.emoji,x+32,bottom-62,20,"#fff3d5")
			if indicator.phase!=null:commands.append(["progress","patience:"+str(a.id)+":"+str(indicator.phase),x-22,bottom-94,44,8,indicator.ratio,"patience"])
static func table_plate_position(table: Dictionary,chair: Dictionary) -> Vector2:
	var rect := MOVE.MAP.rect(table)
	var origin := Vector2(rect.position)*40
	var size := Vector2(rect.size)*40
	# Match Mesa.tscn's projected tabletop, including its rotated footprint.
	var left := origin.x+size.x*0.025
	var right := origin.x+size.x*0.975
	var back := origin.y-size.y*0.45
	var front := origin.y+size.y*0.25
	var x := clampf(chair.x*40+20,left+9,right-9)
	var y := lerpf(back,front,clampf((chair.y*40+20-origin.y)/size.y,0,1))
	match posmod(int(chair.rot),4):
		0:y=front-6
		2:y=back+6
		1:x=left+9
		3:x=right-9
	return Vector2(x,y)

func object(s: Dictionary,o: Dictionary,selected: bool,preview: bool = false) -> void:
	var r := MOVE.MAP.rect(o)
	var x: float = r.position.x*40;var y: float = r.position.y*40;var w: float = r.size.x*40;var h: float = r.size.y*40
	alpha=0.65 if preview else 1.0
	box(x+5,y+h-7,w-7,8,"#624a343f");commands.append(["furniture",o.get("baseType",o.type) if str(o.get("baseType","")).begins_with("counter") else o.type,x,y,w,h,o.rot,preview])
	if o.type=="kitchen" and not str(o.get("baseType","")).begins_with("counter"):
		commands[-1].append({"plates":int(o.get("plates",0))})
	if str(o.get("baseType","")).begins_with("counter"):
		var kit_command: Array = ["furniture",o.tableKit,x,y,w,h,o.rot,preview]
		if o.tableKit=="platingKit":kit_command.append({"plates":int(o.get("plates",0))})
		commands.append(kit_command)
	if str(o.get("baseType",o.type)).begins_with("counter"):
		var neighbors := 0
		for i in 4:
			var point: Vector2i = Vector2i(o.x,o.y)+BUILD.DIRS[i]
			for other in s.objects:
				if other.room==o.room and str(other.get("baseType",other.type)).begins_with("counter") and MOVE.MAP.rect(other).has_point(point):neighbors|=1<<i
		# The kit is a separate draw command; find the base command explicitly.
		for index in range(commands.size()-1,-1,-1):
			if commands[index][0]=="furniture" and str(commands[index][1]).begins_with("counter"):
				commands[index].append(neighbors);break
	if o.type=="chair" and preview:
		var dir: Vector2i = MOVE.DIRS[int(o.rot)]
		box(x+19+dir.x*10,y+20+dir.y*10,3,3,"#f8deb0");text(["↑","→","↓","←"][int(o.rot)],x+20,y+24,16,"#fff2ce")
	if o.type=="stove" and o.get("pan")!=null:pot(x+w*0.3,y-9,o.pan.begins_with("pot_"),o.pan=="cookingPot" or o.get("readyBatch")!=null,s.time)
	if o.get("readyBatch")!=null:
		var stage: String = RECIPES.heat(s,o).stage
		if stage in ["over","danger","burned"]:
			box(x+10,y-15,12,7,"#514d40")
			for i in 3:box(x+10+i*4,y-22-fmod(s.time*8+i*6,18),5,7,"#383a36aa" if stage=="burned" else "#71695c99")
	if o.type=="potRack":
		for i in 3:
			if o.get("inventory",[]).size()>i and o.inventory[i]!=null and o.inventory[i].item=="pot":pot(x+w/2,y-20+i*23,false,false,s.time)
	if o.type=="sink":
		for i in int(o.get("dirtyPlates",0)):
			var pile := int(i/5)
			plate(x+w/2-24+(pile%2)*25,y+h-40+int(pile/2)*14-(i%5)*2,null,true)
	var cooking = s.get("cooking") if o.has("id") and s.get("cooking")!=null and s.cooking.stove==o.id else null
	if o.type=="stove" and (not o.get("ingredients",[]).is_empty() or cooking!=null or o.get("readyBatch")!=null):
		var index := 0
		for p in o.get("ingredients",[]):ingredient(p.item,x+14+index*24,y-6);index+=1
		var recipe = RECIPES.recognized(o)
		if recipe==null:recipe=cooking.recipe if cooking!=null else o.readyBatch.recipe if o.get("readyBatch")!=null else null
		if recipe!=null:food(recipe,x+w/2-14,y-50,28,24)
	if STORE.is_support_surface(o) and o.get("support")!=null:
		var center := Vector2(0,-44*h/40)
		if o.type in ["counterH","counterV","counterCorner"]:
			center=preload("res://moveis/Bancada.gd").centro_kit({"counterH":0,"counterV":1,"counterCorner":2}[o.type],int(o.rot))
		if BUILD.CATALOG.data[o.type].has("counterPart"):
			var part: String = BUILD.CATALOG.data[o.type].counterPart
			var thick: bool = BUILD.CATALOG.data[o.type].counterFamily=="wide"
			center=preload("res://moveis/BancadaPiskel.gd").apoio(thick,part in ["Top","Vertical","Base"],int(o.rot)%2==1)
		pot(x+w/2+center.x,y+h+center.y,INV.ITEMS.data[o.support.item].get("servings",0)>0,false,s.time)
	if o.type=="kitchen":
		if o.get("support")!=null:pot(x+minf(50,w*0.625),y-7,INV.ITEMS.data.get(o.support.item,{}).get("servings",0)>0,false,s.time)
		var index := 0
		var counter_type: String = o.get("baseType","")
		var counter := counter_type.begins_with("counter")
		var layout = preload("res://moveis/LayoutEmpratamento.gd")
		var geometry: Dictionary = layout.frame(Vector2(w/80,h/40))
		var kit_center := preload("res://moveis/Bancada.gd").centro_kit({"counterH":0,"counterV":1,"counterCorner":2}[counter_type],int(o.rot)) if counter else Vector2(0,-44*h/40)
		var anchor := Vector2(x+w/2,y+h)+kit_center
		for dish in o.get("dishes",{}):
			for q in 4:
				for j in STORE.quality_count(o,dish,q):
					# Old snapshots can exceed four; loaded games migrate overflow.
					var position: Vector2 = anchor+layout.ready(index%STORE.READY_DISH_CAPACITY,geometry)
					plate(position.x,position.y,INV.ITEMS.data[dish].recipe,false,q)
					index+=1
	if o.type=="table":
		for ch in s.objects:
			if ch.type!="chair":continue
			var linked = BUILD.chair_table(ch,s.objects)
			if linked==null or linked.id!=o.id:continue
			var place := table_plate_position(o,ch)
			for customer in s.customers:
				if customer.seat==ch.id and customer.state=="eating":
					var order = service.find(s.orders,customer.order)
					plate(place.x,place.y,customer.recipe,false,order.get("quality",0) if order!=null else 0);break
			if s.dirtyTables.get(str(int(ch.id)),0)>0:plate(place.x,place.y,null,true)
	if selected:commands.append(["line",FOOD.pixel(x+1),FOOD.pixel(y+1),w-2,h-2,"#fff0be",2])
	alpha=1
func overlays(s: Dictionary,o: Dictionary,selected: bool,building: bool) -> void:
	var r := MOVE.MAP.rect(o)
	var x: float = r.position.x*40;var y: float = r.position.y*40;var w: float = r.size.x*40;var h: float = r.size.y*40
	if selected or building:label(BUILD.CATALOG.data[o.type].name,x+w/2,y+h+11)
	var job: Variant = null
	for pair in [["chopping","table"],["cooking","stove"],["plating","prep"]]:
		if s.get(pair[0])!=null and s[pair[0]].get(pair[1])==o.id:job=s[pair[0]];break
	if job!=null:
		label(("Cortando " if job.has("table") else "Cozinhando " if job.has("stove") else "Empratando ")+str(int(ceil(job.left)))+"s",x+w/2,y-30);commands.append(["progress","task:"+str(o.id)+":"+("cut" if job.has("table") else "cook" if job.has("stove") else "plate"),x,y-19,w,8,1-job.left/job.total,"blue"])
	elif o.type=="stove" and o.get("readyBatch")!=null:
		var heat := RECIPES.heat(s,o)
		label(heat.label,x+w/2,y-30)
		if heat.stage!="burned":commands.append(["progress","heat:"+str(o.id),x,y-19,w,8,heat.value,{"ready":"green","over":"yellow","danger":"red"}[heat.stage]])
	elif o.type=="kitchen" and STORE.ready_count(o)>0:label(str(STORE.ready_count(o))+" pratos prontos",x+w/2,y-20)
	if o.get("feedback")!=null and o.feedback.until>s.time:label("✓ "+o.feedback.label,x+w/2,y-47,"#3b6448")
func draw(s: Dictionary,ui: Dictionary,input: Variant = null) -> Array:
	commands=[];alpha=1;clean_view=ui.get("cleanView",true);velocity=input;identities=ui.get("actorTokens",{})
	var room: String = s.player.room
	if room=="street":label("ENCERRANDO" if s.closing else "ABERTO" if s.open else "FECHADO",675,200,"#3b6448" if s.open else "#77503a")
	if room=="restaurant" and not s.singleRoom:
		var received := 0.0
		for value in s.inv.receiving.values():received+=value
		if not ui.constructionMode:label("Computador",680,409);label("Recebimento • "+str(int(received))+"/60",860,490)
		for i in mini(5,int(ceil(received/12))):box(804+i*21,444,18,22,"#d0a56d");box(810+i*21,444,4,22,"#e3c58c")
		if s.objects.is_empty() and not ui.constructionMode:label("Use Gestão → Modo construção para equipar seu restaurante",280,230)
	for p in PORTALS[room]:
		box(p.x*40+2,p.y*40+2,36,36,"#866139");box(p.x*40+4,p.y*40+4,32,5,"#d4b77a")
		if not ui.constructionMode:label(p.name,p.x*40+20,p.y*40+22)
	var items: Array = []
	for o in s.objects:
		if o.room==room:items.append({"depth":(o.y+MOVE.MAP.rect(o).size.y)*40,"object":o})
	var tokens: Array = []
	for a in MOVE.ACTORS.actors(s):
		tokens.append(identities.get(a.id,a.id))
		if a.room==room:items.append({"depth":(MOVE.position(a).y+1)*40,"actor":a})
	for token in facing.keys():
		if token not in tokens:facing.erase(token)
	preload("res://simulacao/nativa/Camadas.gd").sort(items)
	for item in items:
		if item.has("object"):object(s,item.object,same(ui.selectedObject,item.object.id))
		else:actor(s,item.actor,ui.selectedObject,ui.constructionMode)
	if not ui.constructionMode:
		for o in s.objects:
			if o.room==room:overlays(s,o,same(ui.selectedObject,o.id),ui.get("building")!=null)
	if ui.get("feedback",false) and not ui.constructionMode:
		feedback(s)
	if ui.get("building")!=null:
		if BUILD.TABLE_KITS.has(ui.building.type):
			for surface in s.objects:
				if surface.room!=room or not BUILD.is_worktable(surface) or not BUILD.installed_kit(surface).is_empty():continue
				if ui.building.type=="platingKit" and not STORE.plating_surface(surface):continue
				var area := MOVE.MAP.rect(surface)
				box(area.position.x*40,area.position.y*40,area.size.x*40,area.size.y*40,"#74d9ac44")
				commands.append(["line",area.position.x*40,area.position.y*40,area.size.x*40,area.size.y*40,"#9fffc4",2])
		for y in 16:
			for x in 24:
				if not MOVE.MAP.wall(room,x,y,s):commands.append(["line",x*40,y*40,40,40,"#33584766",1])
		if ui.get("hover")!=null:
			if BUILD.TABLE_KITS.has(ui.building.type):
				var table = BUILD.table_at(s,int(ui.hover.x),int(ui.hover.y))
				var target: Dictionary = table if table!=null else {"type":"worktable","x":int(ui.hover.x),"y":int(ui.hover.y),"rot":0}
				var footprint := MOVE.MAP.rect(target)
				var kit_error = BUILD.kit_error(s,ui.building.type,int(ui.hover.x),int(ui.hover.y))
				commands.append(["furniture",ui.building.type,footprint.position.x*40,footprint.position.y*40,footprint.size.x*40,footprint.size.y*40,target.rot,true])
				box(footprint.position.x*40,footprint.position.y*40,footprint.size.x*40,footprint.size.y*40,"#bb433b55" if kit_error!=null else "#55aa7055")
				return commands
			var o := {"type":ui.building.type,"room":BUILD.CATALOG.data[ui.building.type].room,"x":ui.hover.x,"y":ui.hover.y,"rot":ui.building.rot}
			var r := MOVE.MAP.rect(o);var objects: Array = []
			for existing in s.objects:
				if existing.id!=ui.building.get("moving"):objects.append(existing)
			var candidate: Dictionary = o.duplicate(true);candidate.id=ui.building.get("moving") if ui.building.get("moving") else s.serial;objects.append(candidate)
			var error: Variant = "Vá ao setor indicado para colocar este objeto." if o.room!=room else BUILD.layout_error(s,objects)
			object(s,o,true,true);box(r.position.x*40,r.position.y*40,r.size.x*40,r.size.y*40,"#bb433b55" if error!=null else "#55aa7055")
	return commands

func feedback(s: Dictionary) -> void:
	for a in ([] if clean_view else MOVE.ACTORS.actors(s)):
		if a.room!=s.player.room or a.get("carry")==null or a.carry.kind!="dish":continue
		var pos := MOVE.position(a)
		box(pos.x*40+9,pos.y*40-48,23,17,"#25473de0")
		plate(pos.x*40+20,pos.y*40-40)
		text("→",pos.x*40+36,pos.y*40-36,13,"#a8efb0")
	var job = s.get("chopping")
	if job!=null:
		var table = BUILD.find(s.objects,job.table)
		if table!=null and table.room==s.player.room:
			var area := MOVE.MAP.rect(table)
			var x: float = area.position.x*40+area.size.x*20
			var y: float = area.position.y*40
			ingredient(job.item,x,y-6)
			var lift: float = 5 if int(s.time*7)%2 else 0
			box(x+10,y-17-lift,3,13,"#e6e0c8")
			box(x+10,y-22-lift,3,6,"#6b422d")
	for stove in s.objects:
		if stove.room!=s.player.room or stove.type!="stove":continue
		var x: float = stove.x*40+30
		var y: float = stove.y*40-30
		if stove.get("readyBatch")!=null:
			var stage: String = RECIPES.heat(s,stove).stage
			if stage=="ready":
				var pulse: float = sin(s.time*5)*3
				text("✦",x,y+pulse,18,"#ffe4a0")
			elif stage in ["over","danger","burned"]:
				text("!",x,y-absf(sin(s.time*6))*4,20,"#ffb369" if stage=="over" else "#ff7059")
