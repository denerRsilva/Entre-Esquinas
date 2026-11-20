extends CharacterBody2D
var navigation
var path:=PackedVector2Array()
var index:=0
var speed:=84.0
var direction:=3
var elapsed:=0.0
var locked:=false
var stick:=Vector2.ZERO
signal arrived
func go(point:Vector2):
	path=navigation.route(position,point);index=0
	if path.size()>1 and position.distance_to(path[0])<24:index=1
func _physics_process(delta):
	elapsed+=delta
	if navigation==null:return
	var move:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")+stick
	if Input.is_physical_key_pressed(KEY_A):move.x-=1
	if Input.is_physical_key_pressed(KEY_D):move.x+=1
	if Input.is_physical_key_pressed(KEY_W):move.y-=1
	if Input.is_physical_key_pressed(KEY_S):move.y+=1
	if move.length()>0.05:
		move=move.limit_length();path=PackedVector2Array()
	elif index<path.size():
		while index<path.size() and position.distance_to(path[index])<3:index+=1
		if index<path.size():move=(path[index]-position).normalized()
		else:arrived.emit()
	if locked:move=Vector2.ZERO
	velocity=move*speed
	if velocity.length()>0.1:
		direction=(0 if move.x<0 else 2) if abs(move.x)>abs(move.y) else (1 if move.y<0 else 3)
	move_and_slide()
	var walking:=velocity.length()>0.1
	$Sprite.region_rect=Rect2((direction*6+int(elapsed*7)%6)*32,64,32,64) if walking else Rect2(direction*32,0,32,64)
