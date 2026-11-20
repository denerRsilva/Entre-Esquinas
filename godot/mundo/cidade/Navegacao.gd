extends RefCounted
## One static grid and a bounded shared path cache, reused by every inhabitant.
var grid:=AStarGrid2D.new()
var cache: Dictionary = {}
var data: Dictionary
var solids: Dictionary = {}
func _init(layout: Dictionary,authored_rects:Array=[]):
	data=layout
	grid.region=Rect2i(0,0,int(data.world[0]),int(data.world[1]))
	grid.cell_size=Vector2(32,32);grid.offset=Vector2(16,16)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	var rectangles:Array=authored_rects
	if rectangles.is_empty():
		for o in data.objects:
			if o.has("solid"):rectangles.append(o.solid)
	for r in rectangles:
		for y in range(int(floor(r[1]/32.0)),int(ceil((r[1]+r[3])/32.0))):
			for x in range(int(floor(r[0]/32.0)),int(ceil((r[0]+r[2])/32.0))):
				var cell:=Vector2i(x,y)
				if grid.region.has_point(cell):solids[cell]=true;grid.set_point_solid(cell)
	# The player cannot leave the authored world, even through the edge of a forest.
	for x in int(data.world[0]):
		for y in [0,int(data.world[1])-1]:grid.set_point_solid(Vector2i(x,y));solids[Vector2i(x,y)]=true
	for y in int(data.world[1]):
		for x in [0,int(data.world[0])-1]:grid.set_point_solid(Vector2i(x,y));solids[Vector2i(x,y)]=true
func cell_at(pos: Vector2)->Vector2i:return Vector2i(floor(pos.x/32),floor(pos.y/32))
func center(cell: Vector2i)->Vector2:return Vector2(cell)*32+Vector2(16,16)
func walkable(cell:Vector2i)->bool:return grid.region.has_point(cell) and not grid.is_point_solid(cell)
func nearest(cell:Vector2i)->Vector2i:
	if walkable(cell):return cell
	for radius in range(1,7):
		var candidates: Array[Vector2i]=[]
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				if maxi(abs(x),abs(y))!=radius:continue
				var p:=cell+Vector2i(x,y)
				if walkable(p):candidates.append(p)
		if not candidates.is_empty():
			candidates.sort_custom(func(a,b):return a.distance_squared_to(cell)<b.distance_squared_to(cell))
			return candidates[0]
	return Vector2i(-1,-1)
func route(from:Vector2,to:Vector2)->PackedVector2Array:
	var a:=nearest(cell_at(from));var b:=nearest(cell_at(to))
	if not walkable(a) or not walkable(b):return PackedVector2Array()
	var key:=Vector4i(a.x,a.y,b.x,b.y)
	if cache.has(key):return cache[key]
	var result:=grid.get_point_path(a,b)
	if cache.size()>=128:cache.erase(cache.keys()[0])
	cache[key]=result
	return result
func connected(start:Vector2i)->Dictionary:
	var found:Dictionary={start:true};var todo:Array[Vector2i]=[start];var i:=0
	while i<todo.size():
		var cell:=todo[i];i+=1
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next:Vector2i=cell+d
			if walkable(next) and not found.has(next):found[next]=true;todo.append(next)
	return found
