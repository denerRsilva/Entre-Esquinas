extends "res://qa/PlaytestDoZeroUI.gd"
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
const CENA = preload("res://simulacao/nativa/Cena.gd")
var evidence: Array = []
var folder := "/tmp/auditoria-visual-antes" if "--baseline" in OS.get_cmdline_user_args() else "/tmp/auditoria-visual-depois"
func pixels() -> bool:return "--pixels" in OS.get_cmdline_user_args()
func inspect(item: String,stage: String) -> void:
	g.tick(0);await layout()
	var key := FOOD.food_key(item)
	var ops: Array = g.frame_data.scene.filter(func(op):return op[0]=="food" and FOOD.food_key(op[1])==key)
	check(not ops.is_empty(),"Cenário emite desenho de "+item+" em "+stage)
	var visible := -1
	var width := 0
	if pixels():
		await RenderingServer.frame_post_draw
		var actual: Image = root.get_texture().get_image()
		actual.save_png(folder+"/"+stage+".png")
		if not ops.is_empty():
			var op: Array = ops[0]
			# Screenshots contain physical pixels; to_global alone omits window stretch.
			var transform: Transform2D = root.get_stretch_transform()*g.palco.get_global_transform_with_canvas()
			var start: Vector2 = transform*Vector2(op[2],op[3])
			var finish: Vector2 = transform*Vector2(op[2]+op[4],op[3]+op[5])
			var region := Rect2i(Vector2i(start.floor()),Vector2i((finish-start).ceil())).intersection(Rect2i(Vector2i.ZERO,actual.get_size()))
			var hidden: Dictionary = g.frame_data.duplicate(true)
			hidden.scene=hidden.scene.filter(func(v):return not (v[0]=="food" and FOOD.food_key(v[1])==key))
			g.palco.paint(hidden);await process_frame;await process_frame;await RenderingServer.frame_post_draw
			var baseline: Image = root.get_texture().get_image()
			var min_x: int = region.end.x;var max_x: int = region.position.x
			visible=0
			for y in range(region.position.y,region.end.y):
				for x in range(region.position.x,region.end.x):
					if actual.get_pixel(x,y)!=baseline.get_pixel(x,y):visible+=1;min_x=mini(min_x,x);max_x=maxi(max_x,x)
			width=max_x-min_x+1 if visible else 0
			g.palco.paint(g.frame_data);await process_frame;await process_frame;await RenderingServer.frame_post_draw
			check(visible>=8,"Pixels realmente visíveis de "+item+" em "+stage)
	evidence.append({"stage":stage,"item":item,"draw_commands":ops.size(),"visible_pixels":visible,"pixel_width":width,"zoom":g.session.camera.zoom})
func catalog() -> void:
	var renderer := CENA.new()
	var ids: Array = FOOD.KEYS+FOOD.EARLY_KEYS
	ids.append_array(["dish_caldoBatata","dish_arrozCenoura","dish_canja"])
	for i in ids.size():check(renderer.food(ids[i],(i%8)*64+8,(i/8)*64+8,48,48),"Compositor aceita alimento/ícone "+ids[i])
	for raw in g.session.INTERACT.INV.RAWS:
		check(FOOD.texture(raw)!=null,"Ingrediente cadastrado tem arte: "+raw)
	for raw in g.session.INTERACT.INV.CUTTABLE:check(FOOD.texture(raw+"_cut")!=null,"Corte cadastrado tem arte: "+raw)
	for recipe in g.session.INTERACT.SERVICE.RECIPES.data:check(FOOD.texture(recipe)!=null,"Receita cadastrada tem arte: "+recipe)
	for recipe in FOOD.EARLY_DISHES:
		check(FOOD.texture(recipe).get_size()==Vector2(32,32),"Livro preserva canvas nativo de "+recipe)
		var image := FOOD.image_command(["food",recipe,0,0,FOOD.DISH_SIZE.x,FOOD.DISH_SIZE.y,1,1,0,0,1])
		check(image[8]==FOOD.CLEAN_PLATE_SIZE.x,"Prato pronto tem a largura da louça vazia: "+recipe)
	if not pixels():return
	var view := SubViewport.new();view.size=Vector2i(512,192);view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var art := preload("res://mundo/Tracos.gd").new();view.add_child(art);art.set_commands(renderer.commands)
	await RenderingServer.frame_post_draw;var painted: Image = view.get_texture().get_image()
	painted.save_png(folder+"/catalogo.png")
	for i in ids.size():
		var count := 0
		for y in range((i/8)*64+8,(i/8)*64+56):
			for x in range((i%8)*64+8,(i%8)*64+56):
				if painted.get_pixel(x,y).a>0.5:count+=1
		check(count>=8,"Catálogo produz pixels opacos de "+ids[i])
	view.queue_free();await process_frame
func fresh() -> void:
	if is_instance_valid(g):g.queue_free();await process_frame
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
	await choose("Novo jogo")
	if g.session.modal=="confirmNew":await choose("Começar novo jogo")
	g.session.rng=func():return 0.5
	check(g.session.REFUGE.active(g.session.state),"Auditoria visual começa em Novo jogo")
func run():
	var phone := "--phone" in OS.get_cmdline_user_args()
	if phone:folder+="-telefone"
	DirAccess.make_dir_recursive_absolute(folder);root.size=Vector2i(960,432) if phone else Vector2i(1280,720)
	check(not pixels() or DisplayServer.get_name()!="headless","Verificação de pixels usa renderizador gráfico")
	await fresh();await catalog()
	await use("fridge");await choose("Retirar Batata •",true);await inspect("batata","batata-inteira")
	await use("prep");advance(2.1);await inspect("batata_cut","batata-cortada")
	await use("stove");await inspect("batata_cut","batata-na-panela")
	await use("stove");advance(5.1);await inspect("caldoBatata","caldo-pronto-no-fogao")
	await use("stove");await use("kitchen");advance(2.1);await inspect("caldoBatata","caldo-empratado")
	await use("stove");await use("kitchen");await inspect("caldoBatata","caldo-na-mao")
	check(g.session.SAVE.serialize(g.session.state)!=null,"Visibilidade não altera conservação do caldo")
	await fresh()
	await use("fridge");await choose("Retirar Cenoura •",true);await inspect("cenoura","cenoura-inteira")
	await use("prep");advance(2.1);await inspect("cenoura_cut","cenoura-cortada")
	await use("stove");await inspect("cenoura_cut","cenoura-na-panela")
	await use("fridge");await choose("Retirar Arroz •",true);await use("stove");await use("stove");advance(6.1)
	await inspect("arrozCenoura","arroz-pronto-no-fogao")
	await use("stove");await use("kitchen");advance(2.1);await inspect("arrozCenoura","arroz-empratado")
	await use("stove");await use("kitchen");await inspect("arrozCenoura","arroz-na-mao")
	check(g.session.SAVE.serialize(g.session.state)!=null,"Visibilidade não altera conservação do arroz")
	FileAccess.open(folder+"/metricas.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t"))
	print("EVIDENCIAS VISUAIS ",JSON.stringify(evidence))
	await finish()
