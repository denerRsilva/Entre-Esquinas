extends "res://qa/BaseNativa.gd"
const CATALOGO = preload("res://moveis/Catalogo.gd")
const BANCADA = preload("res://moveis/Bancada.gd")
const MESA = preload("res://moveis/MesaTrabalho.gd")
func run():
	root.size=Vector2i(1100,1100)
	var preview := SubViewport.new()
	preview.size=Vector2i(1100,1100)
	preview.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(preview)
	var stage := Node2D.new()
	preview.add_child(stage)
	var background := ColorRect.new()
	background.color=Color("#35473e");background.size=Vector2(1100,1100);stage.add_child(background)
	var shapes := []
	for i in 3:
		var type: String = ["counterH","counterV","counterCorner"][i]
		var counter = CATALOGO.CENAS[type].instantiate()
		stage.add_child(counter);counter.position=Vector2(410+i*230,240);counter.scale=Vector2.ONE*3
		shapes.append(counter.superficie())
		check(counter.ATLAS==MESA.BASE,"Bancada usa a madeira real da mesa: "+type)
		var base: PackedByteArray = counter.superficie()
		counter.configurar(1)
		check(base!=counter.superficie(),"Rotação altera o formato: "+type)
		counter.configurar(4)
		check(base==counter.superficie(),"Volta completa restaura formato: "+type)
		for rotation in 4:
			var rotated = CATALOGO.CENAS[type].instantiate()
			stage.add_child(rotated);rotated.position=Vector2(220+rotation*220,410+i*150);rotated.scale=Vector2.ONE*2
			rotated.configurar(rotation)
	check(shapes[0]!=shapes[1] and shapes[1]!=shapes[2] and shapes[0]!=shapes[2],"Catálogo instancia três silhuetas distintas")
	check(BANCADA.ALTURA==MESA.ALTURA_BASE,"Bancada e mesa têm a mesma altura física")
	var table = CATALOGO.CENAS.worktable.instantiate();stage.add_child(table);table.position=Vector2(150,240);table.scale=Vector2.ONE*3
	for i in 4:
		var label := Label.new();label.text=["Mesa de preparo (base)","Horizontal","Vertical","Quina"][i];label.position=Vector2([30,340,600,830][i],25);stage.add_child(label)
	# A real L assembly: vertical, elbow, horizontal, with reciprocal ports.
	var assembly := [
		["counterV",Vector2i(0,0),4],
		["counterCorner",Vector2i(0,1),3],
		["counterH",Vector2i(1,1),10],
		["counterH",Vector2i(2,1),8]]
	var profiles := {}
	var nodes := {}
	for item in assembly:
		var node = CATALOGO.CENAS[item[0]].instantiate()
		stage.add_child(node);node.position=Vector2(270,990)+Vector2(item[1])*80;node.scale=Vector2.ONE*2
		profiles[item[1]]=node.superficie();nodes[item[1]]=node
	for item in assembly:
		var adjacent := []
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:adjacent.append(profiles.get(item[1]+direction,PackedByteArray()))
		var node = nodes[item[1]];node.configurar(0,item[2],adjacent);node.superficie()
	for item in assembly:
		var node = nodes[item[1]]
		for side in [1,2]:
			var other = nodes.get(item[1]+(Vector2i.RIGHT if side==1 else Vector2i.DOWN))
			if other!=null:check(node.unioes[side]==other.unioes[(side+2)%4],"Junção recíproca sem fresta: "+str(item[1]))
	check(nodes[Vector2i(0,0)].superficie()==profiles[Vector2i(0,0)],"Conexão vertical não alarga o tampo")
	check(nodes[Vector2i(1,1)].superficie()==profiles[Vector2i(1,1)],"Conexão horizontal mantém profundidade da mesa")
	if DisplayServer.get_name()!="headless":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var shot := preview.get_texture().get_image()
		shot.save_png("/tmp/esquinas-bancadas-comparacao.png")
		var h := shot.get_region(Rect2i(350,30,120,210)).get_data()
		var v := shot.get_region(Rect2i(580,30,120,210)).get_data()
		var c := shot.get_region(Rect2i(810,30,120,210)).get_data()
		check(h!=v and h!=c and v!=c,"Renderização das três peças é diferente")
	preview.queue_free();await process_frame
	print("FALHAS: ",failures);quit(1 if failures else 0)
