extends RefCounted
const CATALOG = preload("res://simulacao/nativa/catalogo.json")
const NAV = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i(1,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(-1,-1)]

static func rect(object: Dictionary) -> Rect2i:
	var data: Dictionary = CATALOG.data[object.get("baseType",object.type)]
	return Rect2i(object.x,object.y,data.h if int(object.rot)%2 else data.w,data.w if int(object.rot)%2 else data.h)

static func wall(room: String, x: int, y: int, state: Dictionary = {}) -> bool:
	if room=="restaurant" and state.get("singleRoom",false):
		return x<=4 or x>=23 or y<=6 or y>=15 or (x==14 and y<10)
	if room=="restaurant" and state.get("compact",false) and (x<=4 or y<=2):return true
	if x<1 or y<1 or x>=23 or y>=15:return true
	if room=="restaurant":return (x==14 and y!=7) or (x>=15 and y==10 and x!=18)
	if room=="street":return y<5 or (x<4 and y<11) or (x>19 and y<11)
	return false

static func fixed(room: String, x: int, y: int, state: Dictionary = {}) -> bool:
	if state.get("singleRoom",false):return false
	return room=="restaurant" and (((x==16 or x==17) and y==11) or (x>=20 and x<=22 and y==11))

static func blocked(state: Dictionary, room: String, point: Vector2i, actor: Dictionary = {}) -> bool:
	if wall(room,point.x,point.y,state) or fixed(room,point.x,point.y,state):return true
	for object in state.objects:
		if object.room==room and rect(object).has_point(point) and not (object.type=="chair" and actor.get("seat")==object.id):return true
	return false

static func route(state: Dictionary, room: String, start: Vector2i, target: Vector2i, actor: Dictionary = {}, avoid: Array = []) -> Variant:
	if blocked(state,room,target,actor):return null
	var sequence := 0
	var queue: Array = [{"point":start,"cost":0.0,"sequence":sequence}]
	var costs := {start:0.0}
	var previous := {start:null}
	while not queue.is_empty():
		queue.sort_custom(func(a,b):
			var first: float = a.cost+distance(a.point,target)
			var second: float = b.cost+distance(b.point,target)
			return a.sequence<b.sequence if first==second else first<second)
		var current: Dictionary = queue.pop_front()
		var point: Vector2i = current.point
		if current.cost>costs[point]:continue
		if point==target:
			var path: Array = []
			while previous[point]!=null:
				path.push_front({"x":point.x,"y":point.y})
				point=previous[point]
			return path
		for direction in NAV:
			var next: Vector2i = point+direction
			if next in avoid or blocked(state,room,next,actor):continue
			if direction.x and direction.y:
				var horizontal := point+Vector2i(direction.x,0)
				var vertical := point+Vector2i(0,direction.y)
				if horizontal in avoid or vertical in avoid or blocked(state,room,horizontal,actor) or blocked(state,room,vertical,actor):continue
			var cost: float = current.cost+distance(direction,Vector2i.ZERO)
			if cost>=costs.get(next,INF):continue
			costs[next]=cost
			previous[next]=point
			sequence+=1
			queue.append({"point":next,"cost":cost,"sequence":sequence})
	return null

## Geometry snapshots used by the native rules and migration regression tests.
static func obstacle_tables() -> Dictionary:
	var result := {}
	for compact in [false,true]:
		for single_room in [false,true]:
			var state := {"compact":compact,"singleRoom":single_room}
			var rooms := {}
			for room in ["restaurant","street","stock"]:
				var grid: Array = []
				for y in 16:
					for x in 24:
						grid.append((1 if wall(room,x,y,state) else 0)|(2 if fixed(room,x,y,state) else 0))
				rooms[room]=grid
			result[str(int(compact))+str(int(single_room))]=rooms
	return result

static func distance(a: Vector2i, b: Vector2i) -> float:
	var dx := float(a.x-b.x)
	var dy := float(a.y-b.y)
	return sqrt(dx*dx+dy*dy)
