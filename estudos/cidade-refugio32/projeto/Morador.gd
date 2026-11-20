extends Node2D
## Ambient patrol only: no service, combat, economy or campaign state.
var navigation
var waypoints: Array = []
var point:=0
var path:=PackedVector2Array()
var index:=0
var speed:=30.0
var pause:=4.0
var timer:=0.0
var elapsed:=0.0
var direction:=3
var walks:=0
var neighbors:Array=[]
var player_ref:Node2D
func clear_space(candidate:Vector2,margin:float=22.0)->bool:
	if not navigation.walkable(navigation.cell_at(candidate)):return false
	if player_ref!=null and candidate.distance_squared_to(player_ref.position)<margin*margin:return false
	for other in neighbors:
		if other!=self and candidate.distance_squared_to(other.position)<margin*margin:return false
	return true
func relax_spacing(delta:float):
	var away:=Vector2.ZERO
	for other in neighbors:
		if other==self:continue
		var difference:Vector2=position-other.position
		if difference.length_squared()>0.1 and difference.length_squared()<324:away+=difference.normalized()
	if player_ref!=null:
		var difference:=position-player_ref.position
		if difference.length_squared()>0.1 and difference.length_squared()<400:away+=difference.normalized()*1.5
	if away.length()>0:
		var next:=position+away.normalized()*26*delta
		if navigation.walkable(navigation.cell_at(next)):position=next

func configure(nav, route:Array, actor:Dictionary, delay:float):
	navigation=nav;waypoints=route;speed=actor.speed;pause=actor.pause
	point=int(actor.offset)%maxi(1,waypoints.size());timer=delay
	if not waypoints.is_empty():
		var p: Array = waypoints[point]
		position=nav.center(nav.nearest(Vector2i(p[0],p[1])))
func _process(delta):
	elapsed+=delta
	if navigation==null or waypoints.is_empty() or speed==0:return
	relax_spacing(delta)
	if timer>0:
		timer-=delta
		$Sprite.region_rect=Rect2(direction*32,0,32,64)
		return
	if index>=path.size():
		point=(point+1)%waypoints.size();var p: Array = waypoints[point]
		path=navigation.route(position,navigation.center(Vector2i(p[0],p[1])));index=1 if path.size()>1 else 0
		if path.size()<2:timer=pause;return
	var target:Vector2=path[index]
	var movement:=target-position
	var candidate:=position.move_toward(target,speed*delta)
	if not clear_space(candidate):
		# At a gathering point, wait beside the crowd instead of stacking sprites.
		if movement.length()<24:
			index+=1
			if index>=path.size():timer=pause;walks+=1
			return
		var perpendicular:=Vector2(-movement.y,movement.x).normalized()
		var stepped:=false
		for sign_value in [1.0,-1.0]:
			var aside:Vector2=position+perpendicular*sign_value*speed*delta
			if clear_space(aside,20):candidate=aside;stepped=true;break
		if not stepped:
			$Sprite.region_rect=Rect2(direction*32,0,32,64)
			return
	position=candidate
	if position.distance_to(target)<0.1:
		index+=1
		if index>=path.size():timer=pause+sin(elapsed)*0.8;walks+=1
	if movement.length()>0.1:direction=(0 if movement.x<0 else 2) if abs(movement.x)>abs(movement.y) else (1 if movement.y<0 else 3)
	$Sprite.region_rect=Rect2((direction*6+int(elapsed*6)%6)*32,64,32,64)
