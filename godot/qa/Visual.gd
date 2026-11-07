extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(name: String):
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/esquinas-"+name+".png")
func press(text: String):
	for b in game.hud.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and b.text == text:
			b.pressed.emit()
			game.tick(0)
			return
func run():
	game = load("res://mundo/Restaurante.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await capture("welcome")
	press("Começar mobiliado (teste)")
	await capture("restaurant")
	press("Gestão")
	press("Modo construção")
	press("Construção")
	await capture("construction")
	quit()
