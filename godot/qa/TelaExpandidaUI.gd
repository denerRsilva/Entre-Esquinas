extends "res://qa/BaseInterfaceNativa.gd"
const CAMERA = preload("res://simulacao/nativa/Camera.gd")
func run():
	root.mode=Window.MODE_WINDOWED
	await start_game()
	var start_position := Vector2(g.session.state.player.x,g.session.state.player.y)
	check(ProjectSettings.get_setting("display/window/stretch/aspect")=="expand","Janela expande a área visível sem barras laterais fixas")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2340,1080),Vector2i(2560,1080),Vector2i(1024,768),Vector2i(960,540)]:
		root.size=resolution;await layout();g.tick(0);await layout()
		var screen := root.get_visible_rect().size
		check(is_equal_approx(screen.x/screen.y,float(resolution.x)/resolution.y),str(resolution)+": proporção real preservada")
		check(g.get_node("Mapa").size.is_equal_approx(screen) and g.hud.size.is_equal_approx(screen),str(resolution)+": mapa e HUD ocupam toda área da tela")
		check(is_equal_approx(g.session.viewport.width,screen.x) and is_equal_approx(g.session.viewport.height,screen.y) and g.session.rect.top==0,str(resolution)+": câmera e entrada recebem dimensões reais")
		for key in ["hud","dock","actions","catalog","ordersHud","kitchenStatus"]:
			var panel: Control = g.hud.slots[key][0]
			check(Rect2(Vector2.ZERO,screen).encloses(panel.get_global_rect()),str(resolution)+": "+key+" dentro da tela")
		var cam: Dictionary = g.session.camera
		var world := Vector2(820,480)
		var point := CAMERA.screen_point(world.x,world.y,g.session.rect,g.session.viewport,cam)
		var back := CAMERA.world_pointer({"clientX":point.x,"clientY":point.y},g.session.rect,g.session.viewport,cam)
		check(Vector2(back.x,back.y).is_equal_approx(world/40),str(resolution)+": clique e câmera concordam")
		if resolution in [Vector2i(1920,1080),Vector2i(2340,1080)]:
			await click_object("fridge")
			var fridge: Dictionary
			for o in g.session.state.objects:
				if o.type=="fridge":fridge=o
			check(g.session.selected==fridge.id,str(resolution)+": clique no mapa seleciona a geladeira correta")
			g.session.close_dialog();g.tick(0)
		g.session.open_dialog("options");g.tick(0);await layout()
		check(Rect2(Vector2.ZERO,screen).encloses(g.hud.slots.modal[0].get_global_rect()),str(resolution)+": opções centralizadas e dentro da tela")
		g.session.close_dialog();g.tick(0)
		g.session.enter_construction();g.session.begin_build("worktable");g.tick(0);await layout()
		var panel: Control = g.hud.slots.build[0]
		check(Rect2(Vector2.ZERO,screen).encloses(panel.get_global_rect()),str(resolution)+": confirmação da construção dentro da tela")
		g.session.root_action("exitConstruction");g.tick(0)
	var safe: Rect2 = g.hud.safe_layout(Vector2(1170,540),Vector2(2340,1080),Rect2(80,0,2180,1040))
	check(safe==Rect2(40,0,1090,520),"Área de recorte e barra de gestos convertida para coordenadas da HUD")
	# Walking to an edge at high zoom must reveal void beyond all four walls.
	var s: Dictionary = g.session.state
	var bounds := CAMERA.room_bounds(s)
	for point in [bounds.position+Vector2(40,40),bounds.end-Vector2(40,40)]:
		s.player.x=point.x/40;s.player.y=point.y/40;s.player.motion=null
		var cam := CAMERA.update(s,{"x":0,"y":0,"zoom":1,"mode":null},{"width":960,"height":540},2,false,true)
		var visible := Rect2(cam.x,cam.y,960/cam.zoom,540/cam.zoom)
		check(visible.position.x<bounds.position.x or visible.end.x>bounds.end.x,"Limite horizontal mostra espaço além da parede")
		check(visible.position.y<bounds.position.y or visible.end.y>bounds.end.y,"Limite vertical mostra espaço além da parede")
	check(ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color").r<0.04,"Espaço fora dos interiores fica escuro")
	if "--capture" in OS.get_cmdline_user_args():
		s.player.x=start_position.x;s.player.y=start_position.y;g.session.notice_until=-1
		root.size=Vector2i(1920,1080);await layout();g.session.set_zoom(1);g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-tela-16x9.png")
		root.size=Vector2i(2340,1080);await layout();g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-tela-celular.png")
	await finish()
