extends Control
var city
var rect:=Rect2()
var scale_factor:=1.0
var legend:ScrollContainer
signal chosen(point:Dictionary)
func _ready():mouse_filter=Control.MOUSE_FILTER_STOP;resized.connect(queue_redraw)
func configure(value):
	city=value
	legend=ScrollContainer.new();legend.name="Destinos";legend.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE);legend.offset_left=-320;legend.offset_right=-20;legend.offset_top=96;legend.offset_bottom=-80;add_child(legend)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",2);legend.add_child(list)
	for i in city.data.points.size():
		var destination:Dictionary=city.data.points[i]
		var button:=Button.new();button.text=str(i+1)+"  "+destination.name;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.custom_minimum_size=Vector2(280,44);button.add_theme_font_size_override("font_size",14)
		var style:=StyleBoxFlat.new();style.bg_color=Color(0.12,0.17,0.16,0.3);style.set_content_margin(SIDE_LEFT,10);button.add_theme_stylebox_override("normal",style)
		var hover:=style.duplicate();hover.bg_color=Color("445548");button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
		button.add_theme_color_override("font_color",Color("e3d4b9"));button.pressed.connect(func():chosen.emit(destination));list.add_child(button)
	queue_redraw()
func project(point:Vector2)->Vector2:return rect.position+point*scale_factor
func _draw():
	if city==null:return
	var size=get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.035,0.055,0.07,0.98))
	var world:=Vector2(city.data.world[0]*32,city.data.world[1]*32)
	scale_factor=minf((size.x-360)/world.x,(size.y-150)/world.y)
	rect=Rect2(Vector2(28,100),(world*scale_factor))
	var colors={"grass":Color("304b3f"),"dirt":Color("a17a52"),"paving":Color("c5b59b"),"asphalt":Color("596064")}
	var w:=int(city.data.world[0]);var h:=int(city.data.world[1])
	for y in h:
		var start:=0
		while start<w:
			var kind:String=city.data.terrain[y*w+start];var end:=start+1
			while end<w and city.data.terrain[y*w+end]==kind:end+=1
			draw_rect(Rect2(project(Vector2(start*32,y*32)),Vector2((end-start)*32,32)*scale_factor),colors[kind]);start=end
	for o in city.data.objects:
		if not o.has("solid"):continue
		var r: Array = o.solid
		var clipped:=Rect2(r[0],r[1],r[2],r[3]).intersection(Rect2(Vector2.ZERO,world))
		draw_rect(Rect2(project(clipped.position),clipped.size*scale_factor),Color("78665a") if o.has("role") else Color("53634d"))
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(28,42),"MAPA DO REFÚGIO",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("f1d9af"))
	draw_string(font,Vector2(28,73),"Toque em um destino para caminhar até lá",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c1af"))
	for i in city.data.points.size():
		var p:Dictionary=city.data.points[i];var c: Array=p.cell
		var v:=project(Vector2(c[0]*32+16,c[1]*32+16))
		draw_circle(v,10,Color("e0a555"));draw_string(font,v+Vector2(-5,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("212b2b"))

	draw_string(font,Vector2(size.x-300,size.y-60),"Deslize a lista • M: voltar",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b8c1af"))
func _gui_input(event):
	if city==null:return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var target:Variant=null;var best:=24.0
		for i in city.data.points.size():
			var p:Dictionary=city.data.points[i];var c:Array=p.cell
			var d:float=event.position.distance_to(project(Vector2(c[0]*32+16,c[1]*32+16)))
			if d<best:target=p;best=d
		if target!=null:chosen.emit(target)
		accept_event()
