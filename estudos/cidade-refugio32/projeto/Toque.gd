extends Control
var finger:=-1
var vector:=Vector2.ZERO
var origin:=Vector2.ZERO
func _ready():
	mouse_filter=Control.MOUSE_FILTER_STOP
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and finger<0 and get_global_rect().has_point(event.position):
			finger=event.index;origin=event.position;vector=Vector2.ZERO;get_viewport().set_input_as_handled();queue_redraw()
		elif event.index==finger and not event.pressed:
			finger=-1;vector=Vector2.ZERO;get_viewport().set_input_as_handled();queue_redraw()
	elif event is InputEventScreenDrag and event.index==finger:
		vector=((event.position-origin)/52).limit_length();get_viewport().set_input_as_handled();queue_redraw()
func _draw():
	if finger<0:return
	var local:=origin-global_position
	draw_circle(local,60,Color(0.08,0.10,0.12,0.38))
	draw_arc(local,60,0,TAU,40,Color(0.9,0.82,0.66,0.6),2)
	draw_circle(local+vector*44,18,Color(0.92,0.85,0.71,0.7))
