extends RefCounted
const CATALOG = preload("res://simulacao/nativa/catalogo.json")
const NAV = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i(1,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(-1,-1)]

static func rect(object: Dictionary) -> Rect2i:
	var data: Dictionary = CATALOG.data[object.get("baseType",object.type)]
	return Rect2i(object.x,object.y,data.h if int(object.rot)%2 else data.w,data.w if int(object.rot)%2 else data.h)

static func wall(room: String, x: int, y: int, state: Dictionary = {}) -> bool:
	if room=="restaurant" and state.get("singleRoom",false):
		return x<=4 or x>=23 or y<=6 or y>=15
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

# A binary heap preserves the old A* tie order without sorting the whole
# frontier on every visited cell. Blocked cells are indexed once per search.
static func precedes(a: Dictionary,b: Dictionary) -> bool:
	return a.sequence<b.sequence if a.priority==b.priority else a.priority<b.priority
static func heap_push(heap: Array, entry: Dictionary) -> void:
	heap.append(entry)
	var i := heap.size()-1
	while i>0:
		var parent := (i-1)/2
		if not precedes(entry,heap[parent]):break
		heap[i]=heap[parent];i=parent
	heap[i]=entry
static func heap_pop(heap: Array) -> Dictionary:
	var result: Dictionary = heap[0]
	var last: Dictionary = heap.pop_back()
	if heap.is_empty():return result
	var i := 0
	while i*2+1<heap.size():
		var child := i*2+1
		if child+1<heap.size() and precedes(heap[child+1],heap[child]):child+=1
		if not precedes(heap[child],last):break
		heap[i]=heap[child];i=child
	heap[i]=last
	return result

static var wall_grids: Dictionary = {}
static func route_obstacles(state: Dictionary,room: String,actor: Dictionary) -> Dictionary:
	var key := room+str(state.get("compact",false))+str(state.get("singleRoom",false))
	if not wall_grids.has(key):
		var walls := {}
		for y in 16:
			for x in 24:
				if wall(room,x,y,state) or fixed(room,x,y,state):walls[Vector2i(x,y)]=true
		wall_grids[key]=walls
	var obstacles: Dictionary = wall_grids[key].duplicate()
	for object in state.objects:
		if object.room!=room or (object.type=="chair" and actor.get("seat")==object.id):continue
		var bounds := rect(object)
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x):obstacles[Vector2i(x,y)]=true
	return obstacles

static func reachable(state: Dictionary,room: String,start: Vector2i,actor: Dictionary,avoid: Array = []) -> Dictionary:
	var obstacles := route_obstacles(state,room,actor)
	for cell in avoid:obstacles[cell]=true
	var found := {start:true}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index<queue.size():
		var point := queue[index];index+=1
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next: Vector2i = point+direction
			if next.x<1 or next.x>=23 or next.y<1 or next.y>=15 or obstacles.has(next) or found.has(next):continue
			found[next]=true;queue.append(next)
	return found

static func route(state: Dictionary, room: String, start: Vector2i, target: Vector2i, actor: Dictionary = {}, avoid: Array = []) -> Variant:
	var obstacles := route_obstacles(state,room,actor)
	if target.x<1 or target.x>=23 or target.y<1 or target.y>=15 or obstacles.has(target):return null
	for cell in avoid:obstacles[cell]=true
	var sequence := 0
	var queue: Array = [{"point":start,"cost":0.0,"priority":distance(start,target),"sequence":sequence}]
	var costs := {start:0.0}
	var previous := {start:null}
	while not queue.is_empty():
		var current := heap_pop(queue)
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
			if next.x<1 or next.x>=23 or next.y<1 or next.y>=15 or obstacles.has(next):continue
			if direction.x and direction.y:
				if obstacles.has(point+Vector2i(direction.x,0)) or obstacles.has(point+Vector2i(0,direction.y)):continue
			var cost: float = current.cost+distance(direction,Vector2i.ZERO)
			if cost>=costs.get(next,INF):continue
			costs[next]=cost;previous[next]=point;sequence+=1
			heap_push(queue,{"point":next,"cost":cost,"priority":cost+distance(next,target),"sequence":sequence})
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
