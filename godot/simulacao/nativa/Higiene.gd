extends RefCounted
## Surface stains are separate from physical dishes. No plate is created or
## destroyed by wiping, and visit-based variation does not reroll after loads.
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")

static func free_hands(s: Dictionary,a: Dictionary) -> bool:
	return a.get("hand")==null and a.get("carry")==null and (a.id!="player" or (s.get("chopping")==null and s.get("plating")==null))

static func floor_point(key: String) -> Variant:
	var parts := key.split(",")
	if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():return null
	var x := int(parts[0]);var y := int(parts[1])
	if key!=str(x)+","+str(y):return null
	return {"room":"restaurant","x":x,"y":y}

static func after_meal(s: Dictionary,c: Dictionary) -> void:
	var chair = BUILD.find(s.objects,c.seat)
	if chair==null or BUILD.chair_table(chair,s.objects)==null:return
	if not s.has("tableStains"):s.tableStains={}
	var seat := str(int(c.seat))
	s.tableStains[seat]=mini(3,int(s.tableStains.get(seat,0))+1)
	var seed: int = hash(str(int(s.day))+":"+str(c.id)+":"+str(c.recipe))
	# About one third of meals leave crumbs/spills on a nearby free floor cell.
	if posmod(seed,100)>=35:return
	var cells: Array = []
	for dir in MOVE.DIRS:
		var p: Vector2i = Vector2i(chair.x,chair.y)+dir
		if p in [Vector2i(7,13),Vector2i(7,14)] or MOVE.blocked(s,chair.room,p.x,p.y):continue
		cells.append(p)
	if cells.is_empty():return
	var point: Vector2i = cells[posmod(seed,cells.size())]
	var key := str(point.x)+","+str(point.y)
	if not s.has("floorDirt"):s.floorDirt={}
	s.floorDirt[key]=mini(3,int(s.floorDirt.get(key,0))+1)

static func seats(s: Dictionary,table: Dictionary) -> Array:
	var result: Array = []
	for chair in s.objects:
		if chair.type!="chair":continue
		var linked = BUILD.chair_table(chair,s.objects)
		if linked!=null and linked.id==table.id:result.append(chair.id)
	return result

static func stained(s: Dictionary,table: Dictionary) -> bool:
	for id in seats(s,table):
		if s.get("tableStains",{}).get(str(int(id)),0)>0:return true
	return false

static func can_wipe(s: Dictionary,table: Dictionary) -> bool:
	if not stained(s,table):return false
	var ids := seats(s,table)
	for id in ids:
		if s.dirtyTables.get(str(int(id)),0)>0:return false
	for c in s.customers:
		if c.seat in ids and c.state in ["walk","waiting","ordered","eating"]:return false
	return true

static func near_object(s: Dictionary,a: Dictionary,o: Dictionary) -> bool:
	if a.room!=o.room or a.get("motion")!=null:return false
	for point in MOVE.access(s,o):
		if point.x==a.x and point.y==a.y:return true
	return false

static func wipe(s: Dictionary,a: Dictionary,table: Dictionary) -> bool:
	if table.type!="table" or not free_hands(s,a) or not near_object(s,a,table) or not can_wipe(s,table):return false
	for id in seats(s,table):s.tableStains.erase(str(int(id)))
	return true

static func mop(s: Dictionary,a: Dictionary,key: String) -> bool:
	var point = floor_point(key)
	if point==null or not s.get("floorDirt",{}).has(key) or a.room!=point.room or a.get("motion")!=null or not free_hands(s,a):return false
	if absi(int(a.x)-point.x)+absi(int(a.y)-point.y)>1:return false
	s.floorDirt.erase(key)
	return true

static func target(s: Dictionary,a: Dictionary,only_floor: String = "") -> Variant:
	var candidates: Array = []
	if only_floor.is_empty():
		for table in s.objects:
			if table.room!=a.room or table.type!="table" or not can_wipe(s,table):continue
			for point in MOVE.access(s,table):candidates.append({"kind":"wipe","object":table,"point":point})
	if a.room=="restaurant":
		for key in s.get("floorDirt",{}):
			if not only_floor.is_empty() and key!=only_floor:continue
			var p = floor_point(key)
			if p==null:continue
			for dir in [Vector2i.ZERO,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				var point := {"room":"restaurant","x":p.x+dir.x,"y":p.y+dir.y}
				if not MOVE.blocked(s,a.room,point.x,point.y,a):candidates.append({"kind":"mop","key":key,"point":point})
	if candidates.is_empty():return null
	var reachable := MOVE.MAP.reachable(s,a.room,Vector2i(a.x,a.y),a)
	var distance := INF
	var best: Variant = null
	for candidate in candidates:
		var point: Dictionary = candidate.point
		var d := absf(point.x-a.x)+absf(point.y-a.y)
		if d<distance and reachable.has(Vector2i(point.x,point.y)):
			distance=d;best=candidate
	return best

static func valid(s: Dictionary) -> bool:
	for field in ["tableStains","floorDirt"]:
		var entries = s.get(field,{})
		if not entries is Dictionary or entries.size()>384:return false
		for key in entries:
			if not key is String or not BUILD.NUM.integer(entries[key]) or entries[key]<1 or entries[key]>3:return false
			if field=="floorDirt":
				var p = floor_point(key)
				if p==null or Vector2i(p.x,p.y) in [Vector2i(7,13),Vector2i(7,14)] or MOVE.MAP.wall("restaurant",p.x,p.y,s) or MOVE.MAP.fixed("restaurant",p.x,p.y,s):return false
			else:
				if not key.is_valid_int() or key!=str(int(key)):return false
				var chair = BUILD.find(s.objects,int(key))
				if chair==null or chair.type!="chair" or BUILD.chair_table(chair,s.objects)==null:return false
	return true
