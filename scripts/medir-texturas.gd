extends SceneTree
func _initialize():call_deferred("measure")
func measure():
 if not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/"):
  push_error("Use XDG_DATA_HOME isolado em /tmp para não tocar em partidas reais.");quit(1);return
 root.size=Vector2i(1280,720)
 var game=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(game);game.set_process(false)
 for i in 10:await process_frame
 game.session.root_action("refuge");game.tick(0)
 for i in 15:await process_frame
 await RenderingServer.frame_post_draw
 print("MEMORIA_TEXTURAS_BYTES ",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
 print("TEXTURA_BARRAS ",preload("res://interface/ArteBarras.gd").ATLAS.get_size())
 game.queue_free();await process_frame;quit()
