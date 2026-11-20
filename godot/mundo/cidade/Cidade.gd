extends Node2D
const NAV=preload("res://mundo/cidade/Navegacao.gd")
signal service_requested(id:String)
var pending_point:Dictionary={}
var input_enabled:=true
var integrated:=true
var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://mundo/cidade/cidade.json"))
var navigation
var player
var camera:Camera2D
var ui
var night:=false
var capturing:=false
var roof_timer:=0.0
var zoom_value:=1.5
var target_marker:Polygon2D
func collider_rect(c:CollisionShape2D)->Array:
	var half:Vector2=c.shape.size/2.0
	var corners:PackedVector2Array=[]
	for point in [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)]:corners.append(c.global_transform*point)
	var r:=Rect2(corners[0],Vector2.ZERO)
	for point in corners:r=r.expand(point)
	return [r.position.x,r.position.y,r.size.x,r.size.y]
func authored_geometry()->Array:
	var rectangles:Array=[]
	for collider in find_children("*","CollisionShape2D",true,false):
		if collider.shape is RectangleShape2D:rectangles.append(collider_rect(collider))
	# The saved scene remains authoritative when an artist moves props in the editor.
	for object in $Objetos.get_children():
		if not object.has_meta("layout_index"):continue
		var index:int=object.get_meta("layout_index");var o:Dictionary=data.objects[index]
		var sprite=object.get_node_or_null("Sprite")
		if sprite:
			var rect:Rect2=sprite.get_rect();var origin:Vector2=sprite.global_transform*rect.position
			o.pos=[origin.x,origin.y]
			if o.has("role"):
				object.set_meta("visual_rect",Rect2(origin,rect.size))
				for point in data.points:
					if point.id==o.role:point.building=[origin.x,origin.y,rect.size.x,rect.size.y]
		var collider=object.get_node_or_null("BaseFisica/Solo_0000")
		if collider:o.solid=collider_rect(collider)
	for point in data.points:
		var marker=get_node_or_null("Destinos/"+point.id)
		if marker:point.cell=[int(floor(marker.position.x/32)),int(floor(marker.position.y/32))]
	for cell in $Piso32.get_used_cells():
		if cell.x<0 or cell.y<0 or cell.x>=data.world[0] or cell.y>=data.world[1]:continue
		var source:int=$Piso32.get_cell_source_id(cell)
		data.terrain[cell.y*int(data.world[0])+cell.x]="dirt" if source==20 else "paving" if source==22 else "asphalt" if source==23 else "grass"
	return rectangles
func _ready():
	navigation=NAV.new(data,authored_geometry())
	player=$Objetos/Jogador;player.navigation=navigation
	player.position=navigation.center(navigation.nearest(Vector2i(data.spawn[0],data.spawn[1])))
	camera=$Camera;camera.position=player.position+Vector2(0,-80);camera.zoom=Vector2.ONE*zoom_value
	ui=$HUD;ui.bind(self)
	var i:=0
	var occupied:Dictionary={navigation.cell_at(player.position):true}
	for npc in get_tree().get_nodes_in_group("resident"):
		var spec:Dictionary=data.people[i]
		var route: Array = data.routes[int(spec.route)].duplicate(true) if spec.route>=0 else []
		for cell in route:
			var adjusted:Vector2i=navigation.nearest(Vector2i(cell[0]+(i%3)-1,cell[1]))
			cell[0]=adjusted.x;cell[1]=adjusted.y
		npc.configure(navigation,route,spec,0.35+i*0.3)
		npc.neighbors=get_tree().get_nodes_in_group("resident");npc.player_ref=player
		if spec.route<0:npc.position=navigation.center(Vector2i(spec.cell[0],spec.cell[1]));npc.direction=2
		var initial:Vector2i=navigation.cell_at(npc.position)
		if occupied.has(initial):
			for offset in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.DOWN,Vector2i.UP,Vector2i(2,0)]:
				var candidate:Vector2i=initial+offset
				if navigation.walkable(candidate) and not occupied.has(candidate):npc.position=navigation.center(candidate);break
		occupied[navigation.cell_at(npc.position)]=true
		i+=1
	target_marker=Polygon2D.new();target_marker.polygon=PackedVector2Array([Vector2(-6,0),Vector2(0,-4),Vector2(6,0),Vector2(0,4)]);target_marker.color=Color(1,0.81,0.38,0.75);target_marker.z_index=100;target_marker.visible=false;add_child(target_marker)
func _process(delta):
	if navigation==null:return
	if not pending_point.is_empty() and player.position.distance_to(point_position(pending_point))<5:
		var id:String=pending_point.id;pending_point={};service_requested.emit(id)
	if player.position.distance_to(point_position(data.points[0]))<17 and player.velocity.y<0:service_requested.emit("taverna")
	if not capturing:camera.position=(player.position+Vector2(0,-80)).round()
	player.locked=ui.map.visible or not input_enabled
	target_marker.visible=player.index<player.path.size()
	if target_marker.visible:target_marker.position=player.path[-1]
	if player.manual:pending_point={}
	roof_timer-=delta
	if roof_timer<=0:
		roof_timer=0.15
		for building in get_tree().get_nodes_in_group("roof_fade"):
			var r:Rect2=building.get_meta("visual_rect")
			building.get_node("Sprite").self_modulate.a=0.48 if not capturing and r.has_point(player.position) and player.position.y<r.end.y-64 else 1.0
func point_position(point:Dictionary)->Vector2:
	return navigation.center(Vector2i(point.cell[0],point.cell[1]))
func go_to(world:Vector2):
	pending_point={}
	for id in ["mercador","acolhimento"]:
		var point:Dictionary=data.points.filter(func(p):return p.id==id)[0]
		if world.distance_to(point_position(point)+Vector2(-24,0))<27:choose_point(point);return
	# Clicking a whole facade chooses its door, rather than a point on the roof.
	for p in data.points:
		if p.has("building"):
			var b:Array=p.building
			if Rect2(b[0],b[1],b[2],b[3]).has_point(world):
				choose_point(p);return
	player.go(world)
func choose_point(point:Dictionary):
	pending_point=point if point.id in ["taverna","mercador","acolhimento"] else {}
	show_map(false)
	var c:Array=point.cell;player.go(navigation.center(Vector2i(c[0],c[1])))
func show_map(value:bool):
	ui.map.visible=value;player.locked=value
	ui.joystick.set_process_input(not value)
	ui.joystick.vector=Vector2.ZERO;ui.joystick.finger=-1;ui.joystick.queue_redraw();player.stick=Vector2.ZERO
	if value:ui.map.queue_redraw()
func toggle_map():
	show_map(not ui.map.visible)
func toggle_night():
	night=not night
	$Ambiente.color=Color(0.40,0.48,0.63) if night else Color(0.96,0.94,0.89)
	for light in get_tree().get_nodes_in_group("street_light"):light.enabled=night
func adjust_zoom(step:float):
	zoom_value=clampf(zoom_value+step,1.0,2.5);camera.zoom=Vector2.ONE*zoom_value
func _unhandled_input(event):
	if navigation==null or not input_enabled:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_M:toggle_map()
		elif event.physical_keycode==KEY_E and not ui.map.visible:
			for p in data.points:
				if p.id in ["taverna","mercador","acolhimento"] and player.position.distance_to(point_position(p))<48:choose_point(p);break
		elif event.physical_keycode==KEY_L and not integrated:toggle_night()
		elif event.physical_keycode==KEY_ESCAPE:
			if ui.map.visible:toggle_map()
		elif event.physical_keycode==KEY_EQUAL or event.physical_keycode==KEY_KP_ADD:adjust_zoom(0.25)
		elif event.physical_keycode==KEY_MINUS or event.physical_keycode==KEY_KP_SUBTRACT:adjust_zoom(-0.25)
	if event is InputEventMouseButton and event.pressed and not ui.map.visible:
		if event.button_index==MOUSE_BUTTON_LEFT:go_to(get_global_transform_with_canvas().affine_inverse()*event.position)
		elif event.button_index==MOUSE_BUTTON_WHEEL_UP:adjust_zoom(0.25)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:adjust_zoom(-0.25)
