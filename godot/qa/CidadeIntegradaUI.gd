extends "res://qa/InicioUI.gd"
var city
func arrive(id:String)->bool:
 var p:Dictionary=city.data.points.filter(func(v):return v.id==id)[0]
 city.choose_point(p)
 for i in 16000:
  await physics_frame
  if not g.session.modal.is_empty() or not g.exterior.visiting:return true
  if city.player.index>=city.player.path.size() and id not in ["mercador","acolhimento","taverna"]:return city.player.position.distance_to(city.point_position(p))<8
 return false
func capture(name:String):
 if not "--capture" in OS.get_cmdline_user_args():return
 for i in 5:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/cidade-integrada-"+name+".png")
func run():
 root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout();await press("Novo jogo")
 var s:Dictionary=g.session.state
 check(s.refuge.residents.size()==50 and s.cash==200 and s.workers.is_empty(),"Kit da campanha preservado")
 await capture("cozinha")
 # Carry the real pot outside; taking it must conserve the equipment ledger.
 await click_object("stove");check(held()=="pot","Panela real nas mãos antes da viagem")
 g.session.MOVE.go(s.player,{"room":"street","x":12,"y":6})
 for i in 1000:
  g.tick(0.05)
  if s.player.room=="street":break
 check(s.player.room=="street" and g.exterior.visiting and g.exterior.visible,"Porta da taverna leva ao mapa aprovado")
 city=g.exterior.city
 check(city.get_node("Piso32").tile_set.tile_size==Vector2i(32,32) and city.get_node("Piso32").get_used_cells().size()==5120,"Cidade editável de 80x64 tiles nativos32")
 check(city.player.avatar.sprite_frames==preload("res://personagens/Cozinheira.tres"),"Mesma personagem no interior e exterior")
 check(not g.exterior.carried.commands.is_empty() and held()=="pot","Panela acompanha personagem na cidade")
 await capture("taverna")
 var reach:Dictionary=city.navigation.connected(city.navigation.cell_at(city.player.position))
 for p in city.data.points:check(reach.has(Vector2i(p.cell[0],p.cell[1])),"Destino conectado: "+p.id)
 # Test native SubViewportContainer input forwarding using the main window coordinates.
 var target:Vector2=city.player.position+Vector2(48,32);var screen:Vector2=city.get_global_transform_with_canvas()*target
 var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=screen;click.global_position=screen;root.push_input(click,true);await layout()
 check(not city.player.path.is_empty(),"Clique real do mapa principal chega ao SubViewport")
 click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2(100,g.exterior.size.y-150);click.global_position=click.position;root.push_input(click,true);await layout()
 check(not city.player.path.is_empty(),"Área invisível do joystick não bloqueia clique do PC")
 var key:=InputEventKey.new();key.keycode=KEY_M;key.physical_keycode=KEY_M;key.pressed=true;root.push_input(key,true);await layout()
 check(city.ui.map.visible,"Tecla M do jogo abre mapa da cidade")
 var pos:Vector2=city.player.position
 for i in 4:await physics_frame
 check(city.player.position.distance_to(pos)<0.1,"Mapa pausa a caminhada")
 city.toggle_map();g.tick(0)
 Engine.time_scale=12;Engine.physics_ticks_per_second=240;Engine.max_physics_steps_per_frame=64
 check(await arrive("mercador") and g.session.modal=="market","Caminhada física até Beto abre mercado real")
 var count:float=s.inv.kitchen.batata;var cash:float=s.cash
 check(await press("Comprar 5 Batata · $10"),"Compra pelo menu Godot no novo mercado")
 check(s.market.stock.batata==7 and s.inv.kitchen.batata==count+5 and s.cash==cash-10,"Compra conserva estoque limitado, dinheiro e entrega")
 var frozen:Vector2=city.player.position;var time:float=s.time
 g.tick(5);await layout()
 check(city.player.position==frozen and s.time==time,"Comércio pausa personagem e simulação")
 await capture("mercador")
 await press("Voltar ao jogo")
 check(await arrive("horta"),"Travessia real até horta")
 g.tick(0);g.session.save_game();g.tick(0)
 var position:Vector2=city.player.position;var saved=g.session.SAVE.new().load_value(JSON.parse_string(g.session.values[g.session.SAVE_KEY]))
 check(saved!=null and Vector2(saved.cityVisit.x,saved.cityVisit.y).distance_to(position)<1,"Save guarda posição real da cidade")
 if saved!=null:
  g.session.load_state(saved);g.tick(0)
  check(city.player.position.distance_to(position)<1 and held()=="pot" and g.session.state.market.stock.batata==7,"Carregar restaura viagem, panela e estoque")
  s=g.session.state
 # The shared viewport scales to PC, phone and compact landscape layouts.
 Engine.time_scale=1
 for resolution in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(960,432)]:
  root.size=resolution;root.content_scale_size=resolution;await layout();g.tick(0);await layout()
  check(g.exterior.size.is_equal_approx(root.get_visible_rect().size),"Cidade preenche a tela: "+str(resolution))
  var button:Button=city.ui.get_node("Tela").find_children("*","Button",true,false).filter(func(b):return b.text=="Mapa")[0]
  check(Rect2(Vector2.ZERO,g.exterior.size).encloses(button.get_global_rect()),"Mapa acessível: "+str(resolution))
  button.emit_signal("pressed");g.tick(0);await layout()
  var buttons:Array=city.ui.map.legend.find_children("*","Button",true,false)
  city.ui.map.legend.ensure_control_visible(buttons.back());await layout()
  check(city.ui.map.legend.get_global_rect().encloses(buttons.back().get_global_rect()),"Lista rolável alcança o portão: "+str(resolution))
  city.toggle_map();g.tick(0)
 await capture("cidade-celular")
 # Native touch events pass through the real exterior container.
 var joystick=city.ui.joystick;var start:Vector2=city.player.position
 var touch:=InputEventScreenTouch.new();touch.index=3;touch.pressed=true;touch.position=joystick.get_global_rect().get_center();root.push_input(touch,true);await layout()
 var drag:=InputEventScreenDrag.new();drag.index=3;drag.position=touch.position+Vector2(52,0);drag.relative=Vector2(52,0);root.push_input(drag,true)
 for i in 20:await physics_frame
 check(joystick.vector.x>0.8 and city.player.position.x>start.x,"Joystick real funciona dentro do jogo")
 touch=InputEventScreenTouch.new();touch.index=3;touch.pressed=false;touch.position=drag.position;root.push_input(touch,true);await layout()
 check(joystick.finger==-1 and joystick.vector==Vector2.ZERO,"Soltar toque limpa movimento")
 Engine.time_scale=12
 var broken:Dictionary=s.duplicate(true);broken.cityVisit.x=999999
 check(g.session.SAVE.serialize(broken)==null,"Posição externa inválida é rejeitada")
 var old:Dictionary=s.duplicate(true);old.erase("cityVisit")
 check(g.session.SAVE.new().load_value(old)!=null,"Save antigo sem cidade nova continua válido")
 check(await arrive("taverna") and s.player.room=="restaurant","Retorno pela fachada entra na cozinha")
 check(held()=="pot" and not g.exterior.visible and g.get_node("Mapa").visible,"Retorno preserva panela e restaura câmera interna")
 # Native cooking workflow still uses the selected new appliance scenes.
 await click_object("stove");await prepare("caldoBatata")
 check(s.meals.made.caldoBatata==1 and g.session.SAVE.serialize(s)!=null,"Corte, fogão e empratamento funcionam após ida e volta")
 # A second exit must spawn below the entrance, not immediately re-enter.
 g.session.MOVE.go(s.player,{"room":"street","x":12,"y":6})
 for i in 1000:
  g.tick(0.05)
  if s.player.room=="street":break
 await layout()
 check(s.player.room=="street" and city.player.position.distance_to(g.exterior.point("taverna"))>20,"Segunda saída não devolve jogador automaticamente para dentro")
 g.exterior.service("taverna")
 for name in ["Fogao","Pia","Geladeira"]:
  var art=load("res://moveis/"+name+".tscn").instantiate();check(art.get_node("Arte").texture.resource_path=="res://arte/interiores/cozinha32.png","Asset pago nativo na cena e catálogo: "+name);art.free()
 root.size=Vector2i(1280,720);await layout();g.tick(0)
 await capture("cozinha-final")
 Engine.time_scale=1;Engine.physics_ticks_per_second=60
 await finish()
