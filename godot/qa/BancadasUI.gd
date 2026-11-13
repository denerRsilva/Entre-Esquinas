extends "res://qa/MaosUI.gd"
func run():
 root.size=Vector2i(960,700)
 g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
 await layout();await button("Começar na taverna")
 js("enterConstruction();renderDialog()");g.tick(0);await layout()
 var catalog=js("$('constructionPanel').textContent")
 for label in ["Bancada horizontal","Bancada vertical","Bancada de canto"]:check(catalog.contains(label),label+" no catálogo")
 js("exitConstruction()")
 for item in [["counterH",16,11],["counterCorner",17,11],["counterV",17,10]]:
  check(js("R.place(state,'"+item[0]+"',"+str(item[1])+","+str(item[2])+").ok")=="true","Comprar "+item[0])
 g.tick(0);await layout()
 check(js("R.valid(state)&&!!R.migrateSave(state)")=="true","Junção em L preserva acesso e save")
 var tiles:TileSet=load("res://arte/modular/Modulos.tres")
 check(tiles.get_source_count()==1 and tiles.get_source(0).get_tiles_count()==8,"TileSet editável com módulos de 32 px")
 if "--capturas" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/bancadas-paredes.png")
 print("FALHAS: ",failures)
 g.queue_free();await process_frame;quit(1 if failures else 0)
