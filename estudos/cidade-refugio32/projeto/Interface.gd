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
	var style:=StyleBoxTexture.new();var atlas:=AtlasTexture.new();atlas.atlas=load("res://assets/ui.png");atlas.region=Rect2(112,256,64,64);style.texture=atlas
	for side in 4:style.set_texture_margin(side,12);style.set_content_margin(side,8)
	b.add_theme_stylebox_override("normal",style)
	var hover:=style.duplicate();hover.modulate_color=Color(1.15,1.10,1.02);b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("pressed",hover)
	b.add_theme_color_override("font_color",Color("292f2b"));b.add_theme_color_override("font_hover_color",Color("292f2b"));b.pressed.connect(action);parent.add_child(b)
	return b
func bind(value):
	city=value
	var canvas:=Control.new();canvas.name="Tela";canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(canvas)
	var top:=ColorRect.new();top.name="Faixa";top.color=Color(0.06,0.08,0.09,0.93);top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);top.offset_bottom=62;top.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(top)
	var title:=Label.new();title.text="ENTRE ESQUINAS";title.position=Vector2(24,13);title.add_theme_font_size_override("font_size",25);title.add_theme_color_override("font_color",Color("eddbb5"));canvas.add_child(title)
	var subtitle:=Label.new();subtitle.text="Cidade em reconstrução";subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);subtitle.offset_left=-263;subtitle.offset_right=-20;subtitle.offset_top=22;subtitle.add_theme_font_size_override("font_size",15);subtitle.add_theme_color_override("font_color",Color("aebcad"));canvas.add_child(subtitle)
	var dock:=Control.new();dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);dock.offset_left=-286;dock.offset_top=-68;dock.offset_right=-20;dock.offset_bottom=-20;dock.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(dock)
	button(dock,"Mapa",0,0,94,city.toggle_map)
	button(dock,"Luz",102,0,64,city.toggle_night)
	button(dock,"−",174,0,40,func():city.adjust_zoom(-0.25))
	button(dock,"+",222,0,40,func():city.adjust_zoom(0.25))
	hint=Label.new();hint.text="WASD / setas ou toque para andar   ·   M: mapa   ·   L: dia/noite"
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);hint.offset_left=22;hint.offset_top=-38;hint.add_theme_font_size_override("font_size",13);hint.add_theme_color_override("font_color",Color("e2dbbc"));hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(hint)
	joystick=Control.new();joystick.set_script(load("res://Toque.gd"));joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);joystick.offset_top=-220;joystick.offset_left=8;joystick.offset_right=224;joystick.offset_bottom=-40;canvas.add_child(joystick)
	map=Control.new();map.set_script(load("res://Mapa.gd"));map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);map.visible=false;canvas.add_child(map);map.configure(city);map.chosen.connect(city.choose_point)
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
