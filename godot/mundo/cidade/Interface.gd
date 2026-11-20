extends CanvasLayer
var city
var map
var joystick
var hint:Label
var elapsed:=0.0
var marker:Polygon2D
func button(parent:Control,text:String,x:float,y:float,width:float,action:Callable)->Button:
	var b:=Button.new();b.text=text;b.position=Vector2(x,y);b.size=Vector2(width,46)
	b.add_theme_font_size_override("font_size",16)
	var style:=StyleBoxTexture.new();var atlas:=AtlasTexture.new();atlas.atlas=load("res://mundo/cidade/assets/ui.png");atlas.region=Rect2(0,0,64,64);style.texture=atlas
	for side in 4:style.set_texture_margin(side,12);style.set_content_margin(side,8)
	b.add_theme_stylebox_override("normal",style)
	var hover:=style.duplicate();hover.modulate_color=Color(1.15,1.10,1.02);b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("pressed",hover)
	b.add_theme_color_override("font_color",Color("292f2b"));b.add_theme_color_override("font_hover_color",Color("292f2b"));b.pressed.connect(action);parent.add_child(b)
	return b
func bind(value):
	city=value
	var canvas:=Control.new();canvas.name="Tela";canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(canvas)
	var dock:=Control.new();dock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);dock.offset_left=-112;dock.offset_top=70;dock.offset_right=-16;dock.offset_bottom=116;dock.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(dock)
	button(dock,"Mapa",0,0,94,city.toggle_map)
	hint=Label.new();hint.hide();canvas.add_child(hint)
	joystick=Control.new();joystick.set_script(load("res://mundo/cidade/Toque.gd"));joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);joystick.offset_top=-260;joystick.offset_left=8;joystick.offset_right=224;joystick.offset_bottom=-100;canvas.add_child(joystick)
	map=Control.new();map.set_script(load("res://mundo/cidade/Mapa.gd"));map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);map.visible=false;canvas.add_child(map);map.configure(city);map.chosen.connect(city.choose_point)
	marker=Polygon2D.new();marker.polygon=PackedVector2Array([Vector2(-7,0),Vector2(0,-7),Vector2(7,0),Vector2(0,7)]);marker.color=Color("71dbe5");map.add_child(marker)
	# The map remains closable through a visible button on touch screens.
	var close:=button(map,"Voltar",0,0,88,city.toggle_map);close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);close.offset_left=-110;close.offset_right=-22;close.offset_top=16;close.offset_bottom=62
func _process(delta):
	if city==null:return
	elapsed+=delta
	joystick.set_process_input(not map.visible)
	if map.visible:
		joystick.vector=Vector2.ZERO;joystick.finger=-1;joystick.queue_redraw()
	city.player.stick=joystick.vector
	if elapsed>10:hint.modulate.a=maxf(0,1-(elapsed-10)/2)
	if map.visible:marker.position=map.project(city.player.position)
