extends SceneTree
## Infraestrutura de entrada nativa, independente do fluxo de cozinha.
var g
var failures:=0
func _initialize():call_deferred("run")
func js(code:String) -> String:return RestauranteVM.executar(code)
func check(ok:bool,message:String):
	print("OK " if ok else "FALHOU ",message)
	if not ok:failures+=1
func layout():
	for i in 8: await process_frame
func capture(name: String):
	if "--capturas" not in OS.get_cmdline_user_args(): return
	await layout()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/esquinas-ui-"+name+".png")
func click_at(point: Vector2):
	var motion := InputEventMouseMotion.new()
	motion.position=point;motion.global_position=point;root.push_input(motion)
	var mouse := InputEventMouseButton.new()
	mouse.position=point;mouse.global_position=point;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true
	root.push_input(mouse)
	mouse=mouse.duplicate();mouse.pressed=false;root.push_input(mouse)
	g.tick(0)
func button(text: String) -> bool:
	for b in g.hud.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and (b.text==text or b.tooltip_text==text) and not b.disabled:
			var ancestor: Node = b.get_parent()
			while ancestor:
				if ancestor is ScrollContainer:
					ancestor.ensure_control_visible(b)
					await layout()
				ancestor=ancestor.get_parent()
			var point: Vector2 = b.get_global_rect().get_center()
			if not root.get_visible_rect().has_point(point): return false
			click_at(point)
			return true
	return false
func walk_to_selected():
	for i in 140:
		g.tick(.08)
		if js("!state.player.motion && !state.player.goal")=="true": break
