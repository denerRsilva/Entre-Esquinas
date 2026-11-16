extends SceneTree
## Export current pixels and actual Godot renderings. No redraw or downscaling.
const FURN = preload("res://moveis/Catalogo.gd")
const DATA = preload("res://simulacao/nativa/catalogo.json")
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
const COUNTER = preload("res://moveis/BancadaPiskel.gd")
const SCENE = preload("res://simulacao/nativa/Cena.gd")
const DETAILS = preload("res://mundo/Tracos.gd")
var output := "/tmp/entre-esquinas-sprites"
var manifest: Array = []
var images := {}
var cuts: Dictionary

class ExteriorProp extends "res://mundo/RuaDetalhes.gd":
	var kind := "arvore"
	func _draw():
		if kind=="arvore":tree(48,110)
		else:bench(8,20)

func _initialize():
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	call_deferred("run")
func save_image(im: Image, path: String, meta: Dictionary = {}) -> void:
	assert(im!=null and not im.is_empty(),path)
	DirAccess.make_dir_recursive_absolute((output+"/"+path).get_base_dir())
	assert(im.save_png(output+"/"+path)==OK,path)
	meta.file=path;meta.size=[im.get_width(),im.get_height()]
	meta.empty=not im.get_used_rect().has_area()
	manifest.append(meta)
func image_at(path: String) -> Image:
	if not images.has(path):
		var im := Image.new()
		if path.ends_with(".svg"):assert(im.load_svg_from_string(FileAccess.get_file_as_string(path),1)==OK)
		else:assert(im.load(path)==OK,path)
		images[path]=im
	return images[path]
func crop(source: String, region: Rect2, path: String) -> void:
	# Fractional source frames are preserved in the manifest; integer crops
	# enclose them without resampling, with at most one shared border pixel.
	var rect := Rect2i(Vector2i(floor(region.position.x),floor(region.position.y)),Vector2i(ceil(region.end.x),ceil(region.end.y))-Vector2i(floor(region.position.x),floor(region.position.y)))
	var source_image := image_at(source)
	assert(Rect2i(Vector2i.ZERO,source_image.get_size()).encloses(rect),path)
	save_image(source_image.get_region(rect),"02-recortes/"+path,{"kind":"source_crop","source":source,"sourceRect":[region.position.x,region.position.y,region.size.x,region.size.y],"integerRect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"resampled":false})
func view(size: Vector2i) -> SubViewport:
	var v := SubViewport.new()
	v.size=size;v.transparent_bg=true;v.disable_3d=true
	v.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(v)
	return v
func capture(v: SubViewport) -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	return v.get_texture().get_image()
func raw_crops():
	for category in ["moveis","decoracao"]:
		for i in cuts[category].size():
			var r: Array = cuts[category][i]
			crop("res://arte/taverna/"+category+".png",Rect2(r[0],r[1],r[2],r[3]),category+"/%02d.png"%i)
	for i in FOOD.KEYS.size():crop("res://arte/taverna/alimentos.png",FOOD.CROPS[i],"alimentos/"+FOOD.KEYS[i]+".png")
	crop("res://arte/modular/prato-vazio.png",FOOD.CLEAN_PLATE_SOURCE,"utensilios/prato-vazio.png")
	crop("res://arte/taverna/moveis.png",Rect2(710,802,180,140),"utensilios/panela-usada-no-jogo.png")
	crop("res://arte/modular/mesa-trabalho.png",Rect2(94,122,1245,877),"moveis/mesa-trabalho-atual.png")
	crop("res://arte/modular/kits-mesa.png",Rect2(155,335,599,255),"utensilios/kit-corte-atual.png")
	for family in 2:
		var rects: Array = COUNTER.RECTS_THIN if family==0 else COUNTER.RECTS_WIDE
		for i in rects.size():crop("res://arte/modular/bancadas-piskel.png",rects[i],"bancadas/"+("fina" if family==0 else "grossa")+"-%02d.png"%i)
	crop("res://arte/taverna/arquitetura.png",Rect2(270,24,128,128),"pisos/madeira-taverna.png")
	crop("res://arte/taverna/arquitetura.png",Rect2(809,24,128,128),"pisos/ceramica-cozinha.png")
	crop("res://arte/taverna/arquitetura.png",Rect2(1310,607,64,88),"paredes/janela.png")
	var wall_names := ["horizontal","vertical","quina","rodape","bancada-antiga-h","bancada-antiga-v","bancada-antiga-quina","variante-reservada"]
	for i in 8:crop("res://arte/modular/modulos.svg",Rect2(i*32,0,32,32),"paredes/"+wall_names[i]+".png")
	# Old/exterior TileMaps use prebuilt 40px atlases. Export every distinct
	# tile and preserve the cell->file mapping, instead of hundreds of duplicates.
	var tile_maps := {}
	for map in ["street","stock","restaurant"]:
		var source: String = "res://mundo/"+map+".png"
		var im := image_at(source)
		var unique := {};var cells: Array = []
		for y in int(im.get_height()/40):
			for x in int(im.get_width()/40):
				var rect := Rect2i(x*40,y*40,40,40)
				var key := im.get_region(rect).get_data().hex_encode().sha256_text()
				if not unique.has(key):
					var name: String = "pisos/mapas-40px/"+map+"/tile-%03d.png"%unique.size()
					unique[key]="02-recortes/"+name;crop(source,Rect2(rect),name)
				cells.append({"x":x,"y":y,"file":unique[key]})
		tile_maps[map]={"source":source,"tileSize":[40,40],"cells":cells,"uniqueTiles":unique.size()}
	FileAccess.open(output+"/tiles-de-mapas.json",FileAccess.WRITE).store_string(JSON.stringify(tile_maps,"\t"))
	crop("res://arte/ui/comanda-aprovada.png",Rect2(948,70,729,793),"interface/comanda-vazia.png")
	crop("res://arte/ui/comanda-aprovada.png",Rect2(147,117,143,125),"interface/icone-mesa-comanda.png")
	var bar_parts := {"moldura-meio":Rect2(672,266,30,16),"moldura-esquerda":Rect2(666,234,6,16),"moldura-direita":Rect2(702,234,6,16),"verde":Rect2(672,300,30,10),"amarelo":Rect2(672,396,30,10),"vermelho":Rect2(672,492,30,10),"azul":Rect2(672,588,30,10)}
	for key in bar_parts:crop("res://arte/ui/modern-ui-32.png",bar_parts[key],"interface/barra-"+key+".png")

func furniture():
	var frame := Vector2i(256,256)
	var v := view(Vector2i(frame.x*4,frame.y*FURN.CENAS.size()))
	var records: Array = []
	var row := 0
	for type in FURN.CENAS:
		for rot in 4:
			var n: Node2D = FURN.CENAS[type].instantiate()
			n.position=Vector2(128+rot*256,224+row*256)
			v.add_child(n)
			var original := Vector2(40,40)
			if type in ["computer","receiving","stove","prep","kitchen","worktable","cuttingKit","platingKit","sink","table","shelf","potRack"]:original.x=80
			if type in ["fridge","cold"]:original.y=80
			var spec: Dictionary = DATA.data[type]
			n.scale=Vector2(spec.h*40.0,spec.w*40.0)/original if rot%2 else Vector2(spec.w*40.0,spec.h*40.0)/original
			if type.begins_with("counter"):n.configurar(rot)
			if type=="chair":
				var r: Array = cuts.moveis[[9,10,8,10][rot]]
				var sprite: Sprite2D = n.get_node("Arte")
				sprite.region_rect=Rect2(r[0],r[1],r[2],r[3]);sprite.scale=Vector2(30.0/r[2],40.0/r[3])
				if rot==1:n.scale.x*=-1
			records.append({"kind":"native_render","type":type,"title":spec.name,"rotation":rot,"scene":FURN.CENAS[type].resource_path,"pivot":[128,224],"cell":[rot,row]})
		row+=1
	var sheet: Image = await capture(v)
	for record in records:
		var cell: Array = record.cell
		var im := sheet.get_region(Rect2i(cell[0]*256,cell[1]*256,256,256))
		if im.get_used_rect().has_area():
			var used := im.get_used_rect()
			assert(used.position.x>0 and used.position.y>0 and used.end.x<256 and used.end.y<256,record.type)
		save_image(im,"03-renderizados/moveis/"+record.type+"-r"+str(record.rotation)+".png",record)
	save_image(sheet,"03-renderizados/moveis-folha.png",{"kind":"native_contact_sheet","frameSize":[256,256],"columns":4})
	v.queue_free()
	for count in [0,1,10,11,20]:
		var sample := view(frame)
		var table: Node2D = FURN.CENAS.kitchen.instantiate();sample.add_child(table)
		table.position=Vector2(128,224);table.atualizar_pratos(count)
		save_image(await capture(sample),"03-renderizados/empratamento/pratos-%02d.png"%count,{"kind":"native_render","plates":count,"pivot":[128,224]})
		sample.queue_free()

func characters():
	for file in DirAccess.get_files_at("res://personagens"):
		if not file.ends_with(".tscn"):continue
		var scene: PackedScene = load("res://personagens/"+file)
		var template = scene.instantiate()
		assert(template is AnimatedSprite2D,file)
		var frames: SpriteFrames = template.sprite_frames
		var animations := ["baixo","esquerda","direita","cima"]
		var columns := 0
		for anim in animations:columns=maxi(columns,frames.get_frame_count(anim))
		var v := view(Vector2i(columns*96,384))
		var records := []
		for row in 4:
			var anim: String = animations[row]
			for i in frames.get_frame_count(anim):
				var n: AnimatedSprite2D = scene.instantiate();v.add_child(n)
				n.position=Vector2(48+i*96,80+row*96);n.pause();n.animation=anim;n.frame=i
				var texture: Texture2D = frames.get_frame_texture(anim,i)
				var name := file.get_basename()+"/"+anim+"-%02d.png"%i
				if texture is AtlasTexture:crop(texture.atlas.resource_path,texture.region,"personagens/"+name)
				records.append({"kind":"native_render","scene":scene.resource_path,"animation":anim,"frame":i,"speed":frames.get_animation_speed(anim),"pivot":[48,80],"cell":[i,row],"fileName":name})
		var sheet: Image = await capture(v)
		for record in records:
			var cell: Array = record.cell
			save_image(sheet.get_region(Rect2i(cell[0]*96,cell[1]*96,96,96)),"03-renderizados/personagens/"+record.fileName,record)
		save_image(sheet,"03-renderizados/personagens/"+file.get_basename()+"-folha.png",{"kind":"native_contact_sheet","frameSize":[96,96],"columns":columns,"rows":animations})
		template.free();v.queue_free()

func drawn_elements():
	for kind in ["arvore","banco"]:
		var v := view(Vector2i(96,128 if kind=="arvore" else 64))
		var prop := ExteriorProp.new();prop.kind=kind;v.add_child(prop)
		save_image(await capture(v),"03-renderizados/exterior/"+kind+".png",{"kind":"native_render","source":"res://mundo/RuaDetalhes.gd"});v.queue_free()
	for name in ["Rua","Salao"]:
		var v := view(Vector2i(960,640))
		var layer = load("res://mundo/"+name+".tscn").instantiate();v.add_child(layer)
		if name=="Salao":layer.set_layout(true,true)
		save_image(await capture(v),"03-renderizados/cenario/"+name+"-completo.png",{"kind":"native_scene_reference","source":layer.scene_file_path})
		if name=="Salao":
			layer.get_node("Piso").hide()
			save_image(await capture(v),"03-renderizados/cenario/paredes-e-decoracao.png",{"kind":"native_layer","source":"res://mundo/Taverna.gd"})
		v.queue_free()
	var scene := SCENE.new()
	var elements := ["panela-vazia","panela-cheia","panela-cozinhando","prato-limpo","prato-sujo","talher","estrela-prata","estrela-ouro","estrela-roxa"]
	for element in elements:
		scene.commands=[]
		if element.begins_with("panela"):scene.pot(32,40,element!="panela-vazia",element=="panela-cozinhando",0)
		elif element.begins_with("prato"):scene.plate(32,36,null,element=="prato-sujo")
		elif element=="talher":scene.draw_held({"time":0},{"item":"spoon","n":1},32,36)
		else:scene.star(elements.find(element)-5,24,24,16)
		var v := view(Vector2i(64,64));var detail := DETAILS.new();v.add_child(detail);detail.set_commands(scene.commands)
		save_image(await capture(v),"03-renderizados/utensilios/"+element+".png",{"kind":"native_render","source":"res://simulacao/nativa/Cena.gd"});v.queue_free()
	var icons: Dictionary = preload("res://simulacao/nativa/icones-controle.json").data
	for kind in icons:
		var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none" stroke="#fff0cf" stroke-width="1.7" stroke-linejoin="round"><path d="'+icons[kind]+'"/></svg>'
		var im := Image.new();assert(im.load_svg_from_string(svg,2)==OK)
		save_image(im,"02-recortes/interface/icones/"+kind+".png",{"kind":"svg_raster","source":"res://simulacao/nativa/icones-controle.json","key":kind})
		FileAccess.open(output+"/02-recortes/interface/icones/"+kind+".svg",FileAccess.WRITE).store_string(svg)
	for label in ["Instalar prato","Retirar prato","Empratar","Apoiar panela","Retirar panela","Cozinhar","Cortar ingrediente","Lavar prato","Descartar comida","Cancelar prato"]:
		var texture: Texture2D = preload("res://interface/IconesAcao.gd").icon(label,null)
		save_image(texture.get_image(),"02-recortes/interface/acoes/"+label.to_snake_case().replace(" ","-")+".png",{"kind":"current_action_icon","source":"res://interface/IconesAcao.gd","action":label})

func run():
	assert(DisplayServer.get_name()!="headless","Execute com um display gráfico")
	cuts=JSON.parse_string(FileAccess.get_file_as_string("res://arte/taverna/recortes.json"))
	raw_crops()
	await furniture()
	await characters()
	await drawn_elements()
	FileAccess.open(output+"/recortes-e-renderizacoes.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	print("SPRITES EXPORTADAS: ",manifest.size()," • pasta: ",output)
	quit()
