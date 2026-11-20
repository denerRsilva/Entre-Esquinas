extends SubViewportContainer
## Actual exterior coordinates are optional save data; legacy economy anchors stay stable.
const CITY=preload("res://mundo/cidade/Cidade.tscn")
const DETAILS=preload("res://mundo/Tracos.gd")
const VIEW=preload("res://simulacao/nativa/Cena.gd")
var game
var city
var viewport:SubViewport
var bound_state:Dictionary={}
var visiting:=false
var carried
var renderer=VIEW.new()
var vendors:Dictionary={}
func bind(owner_game):
 game=owner_game
 stretch=true;mouse_filter=Control.MOUSE_FILTER_STOP;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 viewport=SubViewport.new();viewport.name="MundoCidade";viewport.size=Vector2i(game.view_size);viewport.world_2d=World2D.new()
 viewport.handle_input_locally=true;add_child(viewport)
 city=CITY.instantiate();viewport.add_child(city);city.service_requested.connect(service)
 for id in ["mercador","acolhimento"]:
  var npc:=Sprite2D.new();npc.name="Beto" if id=="mercador" else "Nina";npc.texture=load("res://mundo/cidade/assets/morador_6.png" if id=="mercador" else "res://mundo/cidade/assets/viajante_2.png");npc.region_enabled=true;npc.region_rect=Rect2(96,0,32,64);npc.offset=Vector2(0,-32);npc.position=point(id)+Vector2(-24,0);city.get_node("Objetos").add_child(npc);vendors[id]=npc
 carried=DETAILS.new();carried.scale=Vector2.ONE*0.8;city.player.add_child(carried)
 hide();city.process_mode=Node.PROCESS_MODE_DISABLED;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
func point(id:String)->Vector2:
 for p in city.data.points:
  if p.id==id:return city.point_position(p)
 return point("taverna")
func remember():
 if visiting and is_same(bound_state,game.session.state):
  game.session.state.cityVisit={"version":1,"x":city.player.position.x,"y":city.player.position.y,"zoom":city.zoom_value}
func sync():
 var s:Dictionary=game.session.state
 var outside:bool=s.player.room=="street" and game.session.modal!="welcome"
 if not outside:
  visiting=false;hide();city.process_mode=Node.PROCESS_MODE_DISABLED;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
  bound_state=s
  game.get_node("Mapa").show();game.hud.show();return
 if not visiting or not is_same(bound_state,s):
  var restoring:bool=not is_same(bound_state,s)
  bound_state=s;visiting=true;game.session.release_keyboard();game.session.pending=null
  s.player.motion=null;s.player.goal=null;s.player.settled=null
  var saved:Dictionary=s.get("cityVisit",{})
  city.player.position=Vector2(saved.x,saved.y) if restoring and valid_visit(saved) else point("taverna")+Vector2(0,32)
  city.zoom_value=float(saved.get("zoom",1.5));city.adjust_zoom(0)
  city.player.path=PackedVector2Array();city.player.velocity=Vector2.ZERO;city.player.manual=false;city.pending_point={};city.ui.map.hide()
  remember()
 show();game.get_node("Mapa").hide()
 vendors.acolhimento.visible=game.session.MARKET.visiting(s)
 game.hud.visible=not city.ui.map.visible or not game.session.modal.is_empty() or game.frame_data.get("refuge")!=null
 size=game.view_size
 var paused:bool=not game.focused or not game.session.modal.is_empty() or game.frame_data.get("refuge")!=null
 if paused:city.ui.map.hide()
 city.process_mode=Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
 city.input_enabled=not paused;city.player.locked=paused
 city.ui.joystick.set_process_input(not paused and not city.ui.map.visible)
 viewport.gui_disable_input=paused;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 if paused:
  city.ui.joystick.vector=Vector2.ZERO;city.ui.joystick.finger=-1;city.player.stick=Vector2.ZERO;city.player.avatar.pause()
 var is_night:bool=s.clock.minute>=1080 or s.clock.minute<360
 if city.night!=is_night:city.toggle_night()
 renderer.commands.clear();renderer.draw_held(s,VIEW.held(s,s.player),-12 if city.player.direction==0 else 12 if city.player.direction==2 else 8,-32 if city.player.direction==1 else -22)
 carried.set_commands(renderer.commands.duplicate(true))
func service(id:String):
 if not visiting or not game.session.modal.is_empty():return
 var s:Dictionary=game.session.state
 game.session.release_keyboard();game.session.pending=null
 if id=="taverna":
  remember();s.player.room="restaurant";s.player.x=7;s.player.y=13;s.player.motion=null;s.player.goal=null;s.player.settled=null
 elif id in ["mercador","acolhimento"]:
  var person_id:String="beto" if id=="mercador" else "nina"
  for person in s.residents:
   if person.id==person_id:
    s.player.x=person.x-1;s.player.y=person.y;s.player.motion=null;s.player.goal=null;s.player.settled=null
  game.session.open_dialog("merchant" if id=="mercador" else "traveler")
 game.tick(0)
static func valid_visit(value:Variant)->bool:
 return preload("res://simulacao/nativa/VisitaCidade.gd").valid(value)
