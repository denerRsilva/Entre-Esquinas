extends SceneTree
## Export the actual native Godot artwork without generating/repainting assets.
## Run with a graphics display, e.g. godot --path godot --script /absolute/path/to/this.gd
const CATALOG = preload("res://moveis/Catalogo.gd")
const FRAME := Vector2i(64,80)
const PIVOT := Vector2(32,74)
const TYPES = ["counterH","counterV","counterCorner"]
const NAMES = ["horizontal","vertical","quina"]
var output := "/tmp/entre-esquinas-bancadas"
func _initialize() -> void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	call_deferred("run")
func viewport(size: Vector2i) -> SubViewport:
	var view := SubViewport.new()
	view.size=size;view.transparent_bg=true;view.disable_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	return view
func capture(view: SubViewport) -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func run() -> void:
	assert(DisplayServer.get_name()!="headless","Use a graphics display to capture the renderer.")
	DirAccess.make_dir_recursive_absolute(output+"/rotacoes")
	var view := viewport(Vector2i(FRAME.x*4,FRAME.y*3))
	var frames := []
	for row in 3:
		for column in 4:
			var piece = CATALOG.CENAS[TYPES[row]].instantiate()
			piece.position=PIVOT+Vector2(column*FRAME.x,row*FRAME.y)
			view.add_child(piece);piece.configurar(column)
			frames.append({"type":TYPES[row],"name":NAMES[row],"rotation":column,"degrees":column*90,"rect":[column*FRAME.x,row*FRAME.y,FRAME.x,FRAME.y],"pivot":[PIVOT.x,PIVOT.y],"file":"rotacoes/bancada-"+NAMES[row]+"-"+str(column*90)+".png"})
	var sheet: Image = await capture(view)
	assert(sheet.save_png(output+"/bancadas-para-editar.png")==OK)
	for frame in frames:
		var rect: Array = frame.rect
		var sprite := sheet.get_region(Rect2i(rect[0],rect[1],rect[2],rect[3]))
		var used := sprite.get_used_rect()
		assert(used.has_area() and used.position.x>0 and used.position.y>0 and used.end.x<FRAME.x and used.end.y<FRAME.y,"The complete counter must fit in its transparent frame.")
		assert(sprite.save_png(output+"/"+frame.file)==OK)
		if frame.rotation==0:assert(sprite.save_png(output+"/bancada-"+frame.name+".png")==OK)
	view.queue_free()
	# Show how the current ports join, at the same native pixel scale.
	var joined := viewport(Vector2i(320,160))
	var assembly := [
		["counterH",Vector2i(0,1),2],["counterH",Vector2i(1,1),10],["counterH",Vector2i(2,1),8],
		["counterV",Vector2i(4,0),4],["counterCorner",Vector2i(4,1),3],["counterH",Vector2i(5,1),10],["counterH",Vector2i(6,1),8]]
	var nodes := {};var profiles := {}
	for item in assembly:
		var piece = CATALOG.CENAS[item[0]].instantiate()
		piece.position=Vector2(24,74)+Vector2(item[1])*40
		joined.add_child(piece);nodes[item[1]]=piece;profiles[item[1]]=piece.superficie()
	for item in assembly:
		var neighbors := []
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:neighbors.append(profiles.get(item[1]+direction,PackedByteArray()))
		nodes[item[1]].configurar(0,item[2],neighbors)
	var connections: Image = await capture(joined)
	assert(connections.save_png(output+"/referencia-conexoes.png")==OK)
	joined.queue_free()
	var manifest := {"source":"Bancada.gd / Godot native renderer","sheet":"bancadas-para-editar.png","sheetSize":[256,240],"frameSize":[64,80],"footprint":[40,40],"frontHeight":30,"scale":1,"rows":NAMES,"columnsDegrees":[0,90,180,270],"frames":frames}
	FileAccess.open(output+"/frames.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	print("Exportados: 3 modelos, 12 orientações, transparência e escala nativa. Pasta: ",output)
	quit()
