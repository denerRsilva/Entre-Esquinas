extends SceneTree
var failures:=0
var scene
var observations:=[]
func check(condition:bool,message:String):
	observations.append({"check":message,"passed":condition})
	if not condition:failures+=1;print("FALHOU: ",message)
func wait_frames(n:int):
	for i in n:await process_frame
func key(code:int):
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;root.push_input(event,true);await wait_frames(2)
	event=InputEventKey.new();event.physical_keycode=code;event.pressed=false;root.push_input(event,true);await wait_frames(2)
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
	scene=load("res://Cidade.tscn").instantiate();root.add_child(scene);await wait_frames(5)
	var nav=scene.navigation;var player=scene.player
	check(scene.get_node("Piso32").tile_set.tile_size==Vector2i(32,32),"TileMap editável em 32px")
	check(scene.get_node("Piso32").get_used_cells().size()==5120,"Mapa completo de 80x64 células")
	var connected:Dictionary=nav.connected(nav.cell_at(player.position))
	for p in scene.data.points:
		var c:=Vector2i(p.cell[0],p.cell[1]);check(nav.walkable(c) and connected.has(c),"Destino acessível: "+p.id)
	for p in scene.data.people:
		if p.route<0:continue
		for target in scene.data.routes[int(p.route)]:check(nav.walkable(Vector2i(target[0],target[1])),"Rota de morador sem obstáculo")
	# Mouse selection is transformed through the real camera and goes to a door.
	var world:=Vector2(1200,850);var point:Vector2=scene.get_global_transform_with_canvas()*world
	var mouse:=InputEventMouseMotion.new();mouse.position=point;mouse.global_position=point;root.push_input(mouse,true)
	var click:=InputEventMouseButton.new();click.position=point;click.global_position=point;click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;root.push_input(click,true);await wait_frames(3)
	check(not player.path.is_empty(),"Clique na fachada encontra a entrada da taverna")
	var door:Vector2=nav.center(Vector2i(38,30));check(player.path[-1].distance_to(door)<1,"Destino de fachada é a porta, não o telhado")
	# Accelerated tour runs actual physics, all static colliders, route following and NPCs.
	Engine.time_scale=10;Engine.physics_ticks_per_second=240;Engine.max_physics_steps_per_frame=64
	for id in ["taverna","mercador","carpinteiro","campamento","acolhimento","portao","horta","ferro_velho","enfermaria","moradias_leste","moradias_norte","moradias_oeste","reconstrucao","praca"]:
		var p:Dictionary=scene.data.points.filter(func(v):return v.id==id)[0]
		scene.choose_point(p)
		var target:Vector2=nav.center(Vector2i(p.cell[0],p.cell[1]))
		var settled:=false
		for i in 8000:
			await physics_frame
			if player.path.is_empty():break
			if player.index>=player.path.size():settled=true;break
		check(settled and player.position.distance_to(target)<8,"Travessia real até "+id)
	# The map is a real modal and a selected destination resumes navigation.
	await key(KEY_M);check(scene.ui.map.visible,"M abre o mapa de navegação")
	await wait_frames(2);check(not scene.ui.joystick.is_processing_input(),"Mapa suspende joystick para não interceptar toques")
	var previous:Vector2=player.position
	Input.action_press("ui_right");for i in 10:await physics_frame
	Input.action_release("ui_right");check(player.position.distance_to(previous)<0.1,"Mapa não move o personagem ao consultar")
	var c:Array=scene.data.points[4].cell;var marker:Vector2=scene.ui.map.project(Vector2(c[0]*32+16,c[1]*32+16))
	var input:=InputEventMouseButton.new();input.position=marker;input.button_index=MOUSE_BUTTON_LEFT;input.pressed=true
	scene.ui.map._gui_input(input);await wait_frames(2)
	check(not scene.ui.map.visible and not player.path.is_empty(),"Escolher destino no mapa fecha e traça caminho")
	# Long destination lists stay usable on touch screens through real scrolling.
	scene.toggle_map();await wait_frames(3)
	var buttons:Array=scene.ui.map.legend.find_children("*","Button",true,false)
	var last:Button=buttons.back();scene.ui.map.legend.ensure_control_visible(last);await wait_frames(4)
	check(scene.ui.map.legend.get_global_rect().encloses(last.get_global_rect()) and last.size.y>=44,"Último destino é alcançável na lista rolável com alvo de 44px")
	last.emit_signal("pressed");await wait_frames(2)
	check(not scene.ui.map.visible and player.path[-1].distance_to(nav.center(Vector2i(40,57)))<1,"Botão do último destino escolhe o portão correto")
	# Key input cancels automatic movement immediately.
	Input.action_press("ui_left");for i in 8:await physics_frame
	Input.action_release("ui_left");await physics_frame
	check(player.path.is_empty(),"Teclado cancela o caminho automático")
	# Real touch input moves using the joystick, which always resets on release.
	var joystick=scene.ui.joystick;var start:Vector2=player.position
	var touch:=InputEventScreenTouch.new();touch.index=3;touch.pressed=true;touch.position=joystick.get_global_rect().get_center();root.push_input(touch,true);await wait_frames(2)
	var drag:=InputEventScreenDrag.new();drag.index=3;drag.position=touch.position+Vector2(52,0);drag.relative=Vector2(52,0);root.push_input(drag,true)
	for i in 12:await physics_frame
	check(joystick.vector.x>0.8 and player.position.x>start.x,"Joystick por toque move o morador")
	touch=InputEventScreenTouch.new();touch.index=3;touch.pressed=false;touch.position=drag.position;root.push_input(touch,true);await wait_frames(2)
	check(joystick.finger==-1 and joystick.vector==Vector2.ZERO,"Soltar toque interrompe o joystick")
	var color:Color=scene.get_node("Ambiente").color
	await key(KEY_L);check(scene.night and scene.get_node("Ambiente").color!=color,"L alterna a noite")
	check(get_nodes_in_group("street_light").all(func(l):return l.enabled),"Postes iluminam a cidade à noite")
	await key(KEY_L);check(not scene.night and get_nodes_in_group("street_light").all(func(l):return not l.enabled),"L restaura o dia e desliga as luzes")
	# Keyboard cannot escape through the open southern road into the black void.
	player.path=PackedVector2Array();player.position=Vector2(1296,1990)
	Input.action_press("ui_down");for i in 100:await physics_frame
	Input.action_release("ui_down");await physics_frame
	check(player.position.y<2016,"Limite físico impede sair do mapa")
	check(get_nodes_in_group("resident").size()==17,"17 moradores visuais independentes da campanha")
	check(get_nodes_in_group("resident").any(func(n):return n.walks>0),"Moradores caminham e pausam em seus destinos")
	check(nav.cache.size()<=128,"Cache de caminhos limitado")
	var nodes:=root.get_tree().get_node_count();check(nodes<4000,"Cena permanece abaixo de 4 mil nós")
	Engine.time_scale=1;Engine.physics_ticks_per_second=60
	for size in [Vector2i(1280,720),Vector2i(2340,1080)]:
		root.size=size;root.content_scale_size=size;await wait_frames(4)
		for b in scene.get_node("HUD").find_children("*","Button",true,false):
			if b.is_visible_in_tree():check(Rect2(Vector2.ZERO,Vector2(size)).encloses(b.get_global_rect()),"Botão dentro da tela "+str(size)+": "+b.text)
	# Moving an authored prop, destination marker and floor tile is reflected at runtime.
	var measured_cache_size:int=nav.cache.size()
	scene.queue_free();await process_frame;await process_frame
	var edited=load("res://Cidade.tscn").instantiate()
	edited.get_node("Objetos/barril_001").position=Vector2(1296,1300)
	edited.get_node("Destinos/praca").position=Vector2(45*32+16,39*32+16)
	edited.get_node("Piso32").set_cell(Vector2i(40,40),23,Vector2i.ZERO)
	root.add_child(edited);await wait_frames(3)
	check(edited.navigation.solids.has(Vector2i(40,40)),"Mover objeto no editor também move sua colisão e navegação")
	check(edited.data.points.filter(func(p):return p.id=="praca")[0].cell==[45,39],"Marker editável atualiza o destino do mapa")
	check(edited.data.terrain[40*80+40]=="asphalt","Piso pintado no TileMap atualiza a leitura do mapa")
	var final_cache_size:int=measured_cache_size
	var report={"failures":failures,"checks":observations,"reachable_cells":connected.size(),"cached_paths":final_cache_size,"nodes":nodes,"platform":"Linux/Godot 4.6.3; toque simulado; sem aparelho Android"}
	var file:=FileAccess.open("res://validacao.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("Células alcançáveis: ",connected.size()," | Caminhos em cache: ",final_cache_size," | Nós: ",nodes)
	print("FALHAS: ",failures)
	edited.queue_free();await process_frame;quit(1 if failures else 0)
