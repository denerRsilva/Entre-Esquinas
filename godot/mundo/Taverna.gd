extends Node2D
## Art layers use the same geometry as the simulation; decorations on walls are non-blocking.
const ARCH=preload("res://arte/taverna/arquitetura.png")
const DECOR=preload("res://arte/taverna/decoracao.png")
const FURN=preload("res://arte/taverna/moveis.png")
var cuts:Dictionary
var compact := false
var single_room := false
func set_layout(value:bool,single:bool):
	if compact == value and single_room == single:return
	compact=value
	single_room=single
	var floor_layer:TileMapLayer=get_node("Piso")
	for y in range(16):
		for x in range(24):
			if compact and (x<4 or y<(6 if single_room else 2)):floor_layer.erase_cell(Vector2i(x,y))
			else:floor_layer.set_cell(Vector2i(x,y),0 if x<14 else 1,Vector2i.ZERO)
	queue_redraw()
func _ready():
	cuts=JSON.parse_string(FileAccess.get_file_as_string("res://arte/taverna/recortes.json"))
	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Piso"
	floor_layer.z_index = -1
	floor_layer.scale = Vector2.ONE * (40.0 / 128.0)
	floor_layer.tile_set = TileSet.new()
	floor_layer.tile_set.tile_size = Vector2i(128,128)
	for origin in [Vector2(270,24),Vector2(809,24)]:
		var texture := AtlasTexture.new()
		texture.atlas = ARCH
		texture.region = Rect2(origin,Vector2(128,128))
		var source := TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(128,128)
		source.create_tile(Vector2i.ZERO)
		floor_layer.tile_set.add_source(source)
	for y in range(16):
		for x in range(24):
			floor_layer.set_cell(Vector2i(x,y),0 if x<14 else 1,Vector2i.ZERO)
	add_child(floor_layer)
	queue_redraw()
func asset(tex:Texture2D, source:Array, target:Rect2):
	draw_texture_rect_region(tex,target,Rect2(source[0],source[1],source[2],source[3]))
func decor(index:int, target:Rect2):asset(DECOR,cuts.decoracao[index],target)
func wall(x:int,y:int)->bool:return x==0 or x==23 or y==0 or y==15 or (x==14 and y!=7) or (x>=15 and y==10 and x!=18)
func _draw():
	if cuts==null:return
	# Back walls and their wood plinth.
	var left := 160 if compact else 0
	var top := (240 if single_room else 80) if compact else 0
	for x in range(4 if compact else 0,24,2):
		asset(ARCH,[27,220,285,150] if x<14 else [28,413,281,124],Rect2(x*40,top,80,62))
	# Continuous side walls: only plaster repeats, never the horizontal wall's plinth.
	var spans := [[left,top+40,600],[920,top+40,600],[560,top+40,400]] if single_room else [[left,top+40,600],[920,top+40,600],[560,top+40,280],[560,320,600]]
	for span in spans:
		side_wall(span[0],span[1],span[2])
	if not single_room:
		for x in range(15,23):
			if x==18:continue
			draw_rect(Rect2(x*40,400,40,40),Color("5a4030"))
			draw_rect(Rect2(x*40+2,403,36,12),Color("a17850"))
	for x in range(4 if compact else 0,24):
		if x==7:continue
		asset(ARCH,[24,619,172,77],Rect2(x*40,600,40,40))
	# Windows, lamps, foliage and carpet reproduce the approved reference's mood.
	for x in ([240,400] if compact else [120,360]):asset(ARCH,[1310,607,64,88],Rect2(x,top+2,48,58))
	for x in ([205,350,530,730] if compact else [65,270,530,730]):decor(0,Rect2(x,top+8,28,45))
	decor(6,Rect2(360,400,120,75) if single_room else Rect2(320,300,160,100))
	decor(7,Rect2(280,560,80,40))
	decor(4,Rect2(480,top+10,54,85))
	decor(3,Rect2(left+45,520,35,44))
	decor(3,Rect2(525,520,35,44))
	asset(FURN,cuts.moveis[24],Rect2(390,top+8,105,44))
	if not single_room:
		# Existing administrative computer remains accessible at its actual coordinates.
		asset(FURN,cuts.moveis[26],Rect2(640,424,80,56))
		draw_rect(Rect2(659,423,42,30),Color("303b3b"))
		draw_rect(Rect2(663,426,34,22),Color("95a68a"))
		draw_rect(Rect2(675,453,12,7),Color("303b3b"))
		for x in [800,840,880]:decor(18,Rect2(x,443,40,37))

func side_wall(x:float, top:float, bottom:float):
	var height := bottom-top
	draw_rect(Rect2(x,top,40,height),Color("49352b"))
	var y := top
	while y < bottom:
		var segment := minf(80,bottom-y)
		asset(ARCH,[70,262,80,segment*0.6],Rect2(x+8,y,24,segment))
		y += segment
	# Longitudinal timber edges and end caps frame the passage without a ladder pattern.
	draw_rect(Rect2(x+2,top,5,height),Color("846047"))
	draw_rect(Rect2(x+33,top,4,height),Color("694832"))
	draw_rect(Rect2(x+7,top,26,4),Color("a57b52"))
	draw_rect(Rect2(x+7,bottom-5,26,5),Color("60432f"))
