extends RefCounted
const MAP = preload("res://simulacao/nativa/Mapa.gd")
const ACTORS = preload("res://simulacao/nativa/Conservacao.gd")
const SPEED = 3.3
const RADIUS = 0.20
const WALK_TIME = 0.18
const DIRS = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const PORTALS = {"restaurant":[{"x":7,"y":14,"to":"street","spawn":[12,6]}],"street":[{"x":12,"y":5,"to":"restaurant","spawn":[7,13]}],"stock":[{"x":21,"y":14,"to":"restaurant","spawn":[21,13]}]}
static func key(point: Dictionary) -> String:return str(int(point.x))+","+str(int(point.y))
static func distance(x: float, y: float) -> float:return sqrt(x*x+y*y)
static func position(actor: Dictionary) -> Dictionary:
	var motion = actor.get("motion")
	if motion!=null:
		var t := minf(1,motion.elapsed/motion.duration)
		return {"x":motion.fromX+(motion.toX-motion.fromX)*t,"y":motion.fromY+(motion.toY-motion.fromY)*t}
	var settled = actor.get("settled")
	if settled!=null and settled.room==actor.room and settled.x==actor.x and settled.y==actor.y:return {"x":settled.px,"y":settled.py}
	return {"x":actor.x,"y":actor.y}
static func walk_time(actor: Dictionary) -> float:
	if actor.id=="player":return 1/SPEED
	return 0.7 if actor.id=="worker2" and actor.get("goal")!=null and actor.goal.get("idleWalk",false) else 0.4
static func start(actor: Dictionary, target: Dictionary, ox: float = 0, oy: float = 0) -> bool:
	var p := position(actor)
	var x: float = target.x+ox
	var y: float = target.y+oy
	var d := distance(x-p.x,y-p.y)
	if d<1e-7:return false
	actor.motion={"fromX":p.x,"fromY":p.y,"toX":x,"toY":y,"x":target.x,"y":target.y,"elapsed":0,"duration":d*walk_time(actor)}
	return true
static func advance(actor: Dictionary, dt: float) -> float:
	var m = actor.get("motion")
	if m==null:return dt
	var used := minf(dt,m.duration-m.elapsed)
	m.elapsed+=used
	if m.elapsed>=m.duration-1e-8:
		actor.x=m.x;actor.y=m.y
		actor.settled={"room":actor.room,"x":actor.x,"y":actor.y,"px":m.toX,"py":m.toY}
		actor.motion=null
	return maxf(0,dt-used)
static func reserved(actor: Dictionary) -> Array:
	var result: Array = [{"x":actor.x,"y":actor.y}]
	var m = actor.get("motion")
	if actor.id=="player" and m==null:
		var p := position(actor)
		for y in range(int(floor(p.y+0.5-RADIUS)),int(floor(p.y+0.5+RADIUS))+1):
			for x in range(int(floor(p.x+0.5-RADIUS)),int(floor(p.x+0.5+RADIUS))+1):
				var dx := maxf(maxf(x-p.x-0.5,0),p.x-0.5-x)
				var dy := maxf(maxf(y-p.y-0.5,0),p.y-0.5-y)
				if dx*dx+dy*dy<RADIUS*RADIUS-1e-10:result.append({"x":x,"y":y})
	if m!=null:
		result.append({"x":m.x,"y":m.y})
		if m.x!=actor.x and m.y!=actor.y:result.append_array([{"x":m.x,"y":actor.y},{"x":actor.x,"y":m.y}])
	var unique: Array = []
	var seen := {}
	for p in result:
		if not seen.has(key(p)):seen[key(p)]=true;unique.append(p)
	return unique
static func blocked(s: Dictionary, room: String, x: int, y: int, actor: Dictionary = {}) -> bool:return MAP.blocked(s,room,Vector2i(x,y),actor)
static func access(s: Dictionary, object: Dictionary) -> Array:
	var r := MAP.rect(object)
	var result: Array = []
	for y in range(r.position.y-1,r.end.y+1):
		for x in range(r.position.x-1,r.end.x+1):
			if ((x==r.position.x-1 or x==r.end.x) and y>=r.position.y and y<r.end.y) or ((y==r.position.y-1 or y==r.end.y) and x>=r.position.x and x<r.end.x):
				if not blocked(s,object.room,x,y):result.append({"room":object.room,"x":x,"y":y})
	return result
static func closest(s: Dictionary, actor: Dictionary, object: Dictionary) -> Variant:
	var points := access(s,object)
	if actor.room!=object.room:return points[0] if not points.is_empty() else null
	var best: Variant = null
	var length := 2147483647
	for p in points:
		var path = MAP.route(s,actor.room,Vector2i(actor.x,actor.y),Vector2i(p.x,p.y),actor)
		if path!=null and path.size()<length:best=p;length=path.size()
	return best
static func go(actor: Dictionary, target: Dictionary) -> void:
	var previous_speed := walk_time(actor)
	actor.goal={"room":(target.get("room") if target.get("room") else actor.room),"x":target.x,"y":target.y}
	if target.get("idleWalk",false):actor.goal.idleWalk=true
	if target.has("idleUntil"):actor.goal.idleUntil=target.idleUntil
	# A task can interrupt a slow stroll between cells. Preserve progress
	# while immediately restoring the normal service pace.
	if actor.get("motion")!=null:
		var ratio := walk_time(actor)/previous_speed
		actor.motion.duration*=ratio;actor.motion.elapsed*=ratio
	if target.get("offsetX") is float and target.get("offsetY") is float:
		actor.goal.offsetX=clampf(target.offsetX,-0.25,0.25);actor.goal.offsetY=clampf(target.offsetY,-0.25,0.25)
static func arrived(actor: Dictionary) -> bool:
	var goal = actor.get("goal")
	if goal==null or actor.get("motion")!=null or actor.room!=goal.room or actor.x!=goal.x or actor.y!=goal.y:return false
	var p := position(actor)
	return distance(p.x-goal.x-goal.get("offsetX",0),p.y-goal.y-goal.get("offsetY",0))<1e-6
static func occupants(s: Dictionary, actor: Dictionary) -> Dictionary:
	var result := {}
	for other in ACTORS.actors(s):
		if other.id!=actor.id and other.room==actor.room:
			for p in reserved(other):result[key(p)]=true
	return result
static func goal_in_room(actor: Dictionary) -> Variant:
	var goal = actor.get("goal")
	if goal==null:return null
	if goal.room==actor.room:return goal
	for p in PORTALS[actor.room]:
		if p.to==goal.room:return p
	return PORTALS[actor.room][0]
static func input(actor: Dictionary, old: Variant, dx: float, dy: float) -> Variant:
	if not is_finite(dx) or not is_finite(dy):return old
	var length := distance(dx,dy)
	if length==0:return null
	var p := position(actor)
	actor.x=floor(p.x+0.5);actor.y=floor(p.y+0.5)
	actor.settled={"room":actor.room,"x":actor.x,"y":actor.y,"px":p.x,"py":p.y}
	actor.motion=null;actor.goal=null
	return {"dx":dx/length,"dy":dy/length,"moving":old.get("moving",false) if old!=null else false}
static func collision(s: Dictionary, actor: Dictionary, occupied: Dictionary, x: float, y: float) -> bool:
	var cx := x+0.5
	var cy := y+0.5
	for iy in range(int(floor(cy-RADIUS)),int(floor(cy+RADIUS))+1):
		for ix in range(int(floor(cx-RADIUS)),int(floor(cx+RADIUS))+1):
			if not blocked(s,actor.room,ix,iy,actor) and not occupied.has(str(ix)+","+str(iy)):continue
			var ox := maxf(maxf(ix-cx,0),cx-ix-1)
			var oy := maxf(maxf(iy-cy,0),cy-iy-1)
			if ox*ox+oy*oy<RADIUS*RADIUS-1e-10:return true
	return false
static func axis(s: Dictionary, actor: Dictionary, occupied: Dictionary, p: Dictionary, dx: float, dy: float) -> void:
	if dx==0 and dy==0:return
	var amount := 1.0
	if collision(s,actor,occupied,p.x+dx,p.y+dy):
		var low := 0.0
		var high := 1.0
		for i in 14:
			var middle := (low+high)/2
			if collision(s,actor,occupied,p.x+dx*middle,p.y+dy*middle):high=middle
			else:low=middle
		amount=low
	p.x+=dx*amount;p.y+=dy*amount
static func free_player(s: Dictionary, actor: Dictionary, velocity: Dictionary, dt: float) -> void:
	var p := position(actor)
	var before := p.duplicate()
	var occupied := occupants(s,actor)
	var length := SPEED*dt
	var count := maxi(1,int(ceil(length/0.08)))
	for i in count:
		axis(s,actor,occupied,p,velocity.dx*length/count,0)
		axis(s,actor,occupied,p,0,velocity.dy*length/count)
	actor.x=floor(p.x+0.5);actor.y=floor(p.y+0.5)
	actor.settled={"room":actor.room,"x":actor.x,"y":actor.y,"px":p.x,"py":p.y}
	actor.motion=null;actor.goal=null;actor.wait=0
	velocity.moveX=p.x-before.x;velocity.moveY=p.y-before.y
	velocity.moving=distance(velocity.moveX,velocity.moveY)>1e-7
	if actor.room not in ["restaurant","street"]:return
	for portal in PORTALS[actor.room]:
		if absf(p.x-portal.x)>=0.35 or absf(p.y-portal.y)>=0.35:continue
		if actor.room=="restaurant" and not (velocity.dy>0 and p.y>=portal.y-0.2):continue
		if actor.room=="street" and not (velocity.dy<0 and p.y<=portal.y+0.2):continue
		var x: int = portal.spawn[0]
		var y: int = portal.spawn[1]
		var occupied_dest := false
		for other in ACTORS.actors(s):
			if other.id!=actor.id and other.room==portal.to:
				for cell in reserved(other):
					if cell.x==x and cell.y==y:occupied_dest=true
		if not blocked(s,portal.to,x,y,actor) and not occupied_dest:
			actor.room=portal.to;actor.x=x;actor.y=y;actor.settled=null
		return
static func push(s: Dictionary, actor: Dictionary, requester: Dictionary, locked: Dictionary, seen: Dictionary) -> bool:
	if actor.get("motion")!=null or actor.id=="player" or seen.has(actor.id) or seen.size()>8:return false
	seen[actor.id]=true
	var options: Array = []
	for dir in DIRS:
		var p := {"x":actor.x+dir.x,"y":actor.y+dir.y}
		if not blocked(s,actor.room,p.x,p.y,actor) and not locked.has(actor.room+":"+key(p)) and not (requester.room==actor.room and requester.x==p.x and requester.y==p.y):options.append(p)
	# Stable sorting preserves the previous cardinal preference on equal scores.
	for i in options.size():options[i].order=i;options[i].score=escape_score(s,actor,requester,options[i])
	options.sort_custom(func(a,b):return a.order<b.order if a.score==b.score else a.score>b.score)
	for p in options:
		var other: Variant = null
		for candidate in ACTORS.actors(s):
			if candidate.id!=actor.id and candidate.room==actor.room:
				for cell in reserved(candidate):
					if cell.x==p.x and cell.y==p.y:other=candidate;break
				if other!=null:break
		if other!=null and not push(s,other,actor,locked,seen):continue
		locked[actor.room+":"+key(actor)]=true
		start(actor,p);actor.hold=s.time+1.2
		return true
	return false
static func escape_score(s: Dictionary, actor: Dictionary, requester: Dictionary, point: Dictionary) -> float:
	var score := 0.0
	for dir in DIRS:
		if not blocked(s,actor.room,point.x+dir.x,point.y+dir.y):score+=10
	return score+absf(point.x-requester.x)+absf(point.y-requester.y)
static func hall_limits(leaving_kitchen: bool = false) -> Array:
	var result: Array = []
	for y in range(1,15):
		for x in range(1,23):
			if (x>=14 and not leaving_kitchen) or y==14:result.append(Vector2i(x,y))
	return result

static func move(s: Dictionary, dt: float, velocity: Variant) -> void:
	var locked := {}
	for actor in ACTORS.actors(s):
		if actor.id==s.player.id and velocity!=null:free_player(s,actor,velocity,dt);continue
		var goal = actor.get("goal")
		if actor.id==s.player.id and actor.get("motion")==null and goal!=null and (goal.room!=actor.room or goal.x!=actor.x or goal.y!=actor.y):start(actor,{"x":actor.x,"y":actor.y})
		var budget := dt
		if actor.get("motion")!=null:
			var before: String = actor.room+":"+key(actor)
			budget=advance(actor,budget)
			if actor.motion==null:locked[before]=true
			if actor.motion!=null or budget<1e-8:continue
		if goal==null or actor.hold>s.time:continue
		var g = goal_in_room(actor)
		if g==null:continue
		if actor.x==g.x and actor.y==g.y:
			if goal.room!=actor.room:
				for dest in PORTALS[actor.room]:
					if dest.x!=g.x or dest.y!=g.y:continue
					var occupied_dest := false
					for other in ACTORS.actors(s):
						if other.id!=actor.id and other.room==dest.to:
							for p in reserved(other):
								if p.x==dest.spawn[0] and p.y==dest.spawn[1]:occupied_dest=true
					if not occupied_dest:
						locked[actor.room+":"+key(actor)]=true
						actor.room=dest.to;actor.x=dest.spawn[0];actor.y=dest.spawn[1];actor.settled=null
					break
			else:
				actor.wait=0
				if start(actor,g,goal.get("offsetX",0),goal.get("offsetY",0)):advance(actor,budget)
			continue
		var avoid := occupants(s,actor)
		for cell in locked:
			if str(cell).begins_with(actor.room+":"):avoid[str(cell).split(":")[1]]=true
		var unavailable := avoid.duplicate()
		avoid.erase(key(g))
		var strolling: bool = goal.get("idleWalk",false)
		var avoid_points: Array = hall_limits(actor.x>=14) if strolling else []
		for cell in avoid:
			var parts = str(cell).split(",")
			avoid_points.append(Vector2i(int(parts[0]),int(parts[1])))
		var path = MAP.route(s,actor.room,Vector2i(actor.x,actor.y),Vector2i(g.x,g.y),actor,avoid_points)
		if path!=null and not path.is_empty() and unavailable.has(key(path[0])):path=null
		if (path==null or path.is_empty()) and not strolling:
			var fallback = MAP.route(s,actor.room,Vector2i(actor.x,actor.y),Vector2i(g.x,g.y),actor)
			if fallback!=null and not fallback.is_empty():
				var n: Dictionary = fallback[0]
				if not unavailable.has(key(n)) and (n.x==actor.x or n.y==actor.y or (not unavailable.has(key({"x":n.x,"y":actor.y})) and not unavailable.has(key({"x":actor.x,"y":n.y})))):path=fallback
		if path==null or path.is_empty():
			actor.wait+=dt/WALK_TIME
			if not strolling:s.flowWaits+=1
			var static_path = MAP.route(s,actor.room,Vector2i(actor.x,actor.y),Vector2i(g.x,g.y),actor)
			if not strolling and actor.wait>=5 and static_path!=null and not static_path.is_empty():
				var n: Dictionary = static_path[0]
				var other: Variant = null
				for candidate in ACTORS.actors(s):
					if candidate.id!=actor.id and candidate.room==actor.room:
						for p in reserved(candidate):
							if p.x==n.x and p.y==n.y:other=candidate;break
						if other!=null:break
				if other!=null and other.state not in ["waiting","ordered","eating"]:push(s,other,actor,locked,{})
			continue
		var n: Dictionary = path[0]
		var final: bool = goal.room==actor.room and n.x==g.x and n.y==g.y
		locked[actor.room+":"+key(actor)]=true
		start(actor,n,goal.get("offsetX",0) if final else 0,goal.get("offsetY",0) if final else 0)
		advance(actor,budget);actor.wait=0
