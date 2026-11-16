extends RefCounted
## Shared collection rules: players and workers move real plates, never copies.
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const INV = preload("res://simulacao/nativa/Inventario.gd")
const SINK_CAPACITY := INV.DIRTY_SINK_CAPACITY

static func held(actor: Dictionary) -> int:
	var p = actor.get("hand") if actor.id=="player" else actor.get("carry")
	if p==null:return 0
	return int(p.n) if (p.get("item")=="dirtyPlate" if actor.id=="player" else p.get("kind")=="dirtyPlates") else 0

static func set_held(actor: Dictionary, count: int) -> void:
	if actor.id=="player":actor.hand={"item":"dirtyPlate","n":count} if count else null
	else:actor.carry={"kind":"dirtyPlates","n":count} if count else null

static func count(s: Dictionary, table: Dictionary) -> int:
	var total := 0
	for chair in s.objects:
		if chair.type!="chair":continue
		var linked = BUILD.chair_table(chair,s.objects)
		if linked!=null and linked.id==table.id:total+=int(s.dirtyTables.get(str(int(chair.id)),0))
	return total

static func near(s: Dictionary,actor: Dictionary,object: Dictionary) -> bool:
	if actor.room!=object.room or actor.get("motion")!=null:return false
	for p in MOVE.access(s,object):
		if p.x==actor.x and p.y==actor.y:return true
	return false

static func collect(s: Dictionary,actor: Dictionary,table: Dictionary,max_total: int = INV.HAND_PLATE_CAPACITY) -> int:
	if table.type!="table" or not near(s,actor,table):return 0
	var current := held(actor)
	if actor.id=="player":
		if actor.get("carry")!=null or (actor.get("hand")!=null and current==0) or s.get("chopping")!=null or s.get("plating")!=null or s.get("washing")!=null:return 0
	elif actor.get("carry")!=null and current==0:return 0
	var remaining := mini(INV.HAND_PLATE_CAPACITY,max_total)-current
	var taken := 0
	for chair in s.objects:
		if remaining<=0:break
		if chair.type!="chair":continue
		var linked = BUILD.chair_table(chair,s.objects)
		var key := str(int(chair.id))
		if linked==null or linked.id!=table.id:continue
		var amount := mini(remaining,int(s.dirtyTables.get(key,0)))
		if amount>0:s.dirtyTables[key]-=amount;remaining-=amount;taken+=amount
	if taken:set_held(actor,current+taken)
	return taken

static func sink_space(sink: Dictionary) -> int:return maxi(0,SINK_CAPACITY-int(sink.get("dirtyPlates",0)))

static func deposit(s: Dictionary,actor: Dictionary,sink: Dictionary) -> int:
	if sink.type!="sink" or not near(s,actor,sink):return 0
	var amount := mini(held(actor),sink_space(sink))
	if amount:
		sink.dirtyPlates=int(sink.get("dirtyPlates",0))+amount
		set_held(actor,held(actor)-amount)
	return amount

static func target(s: Dictionary,actor: Dictionary,kind: String) -> Variant:
	var candidates: Array = []
	for object in s.objects:
		if object.room!=actor.room or object.type!=kind:continue
		if (kind=="table" and count(s,object)>0) or (kind=="sink" and sink_space(object)>0):candidates.append(object)
	if candidates.is_empty():return null
	# One flood fill for every candidate, rather than A* for each edge per frame.
	var reachable := MOVE.MAP.reachable(s,actor.room,Vector2i(actor.x,actor.y),actor)
	var best: Variant = null
	var distance := INF
	for object in candidates:
		for point in MOVE.access(s,object):
			var d := absf(point.x-actor.x)+absf(point.y-actor.y)
			if d<distance and reachable.has(Vector2i(point.x,point.y)):
				distance=d;best={"object":object,"point":point}
	return best
