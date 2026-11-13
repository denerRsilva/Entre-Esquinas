extends "res://qa/MaosUI.gd"
func run():
 root.size=Vector2i(960,700)
 g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
 await layout();await button("Começar na taverna")
 for i in 3:
  check(js("R.spawn(state,()=>.5)")=="true","Cliente criado")
  advance(5)
 g.tick(0);await layout()
 for name in ["Garcom","Cliente1","Cliente2","Cliente3"]:
  var path="res://personagens/"+name+".tscn"
  check(g.palco.pool.has(path),"Modelo visível: "+name)
  if not g.palco.pool.has(path):continue
  var actor:AnimatedSprite2D=g.palco.pool[path][0]
  for direction in ["baixo","esquerda","direita","cima"]:
   check(actor.sprite_frames.get_frame_count(direction)==4,name+" quatro quadros: "+direction)
  check(actor.sprite_frames.get_frame_texture("baixo",1).atlas.resource_path.contains("estudo-sprites"),"Atlas novo: "+name)
 check(js("R.valid(state)&&!!R.migrateSave(state)")=="true","Estado e save válidos")
 if "--capturas" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/npcs-integrados.png")
 print("FALHAS: ",failures)
 g.queue_free();await process_frame;quit(1 if failures else 0)
