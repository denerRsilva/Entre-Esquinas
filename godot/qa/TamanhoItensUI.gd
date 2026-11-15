extends "res://qa/BaseInterfaceNativa.gd"
const CENA = preload("res://simulacao/nativa/Cena.gd")
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
var renderer = CENA.new()
func sprite_size(command: Array) -> Vector2:
	var image: Array = FOOD.image_command(command) if command[0]=="food" else command
	return Vector2(image[8],image[9])
func held_size(state: Dictionary, item: Dictionary) -> Vector2:
	renderer.commands=[];renderer.draw_held(state,item,100,100)
	return sprite_size(renderer.commands[0])
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var clean := held_size(s,{"item":"plate","n":1})
	var table
	for o in s.objects:
		if o.type=="kitchen":table=o
	var view = g.palco.pool.kitchen[0]
	for scale in [Vector2.ONE,Vector2(0.5,2),Vector2(0.5,1)]:
		view.scale=scale;view.atualizar_pratos(20)
		for rect in view.disposicao_pratos().plates:check(rect.size==clean,"Prato limpo tem o tamanho das mãos em qualquer superfície")
	check(held_size(s,{"item":"dirtyPlate","n":1})==clean,"Prato sujo mantém tamanho da louça limpa")
	g.tick(0)
	await take("frango")
	var whole := held_size(s,s.player.hand)
	await click_object("prep")
	renderer.commands=[];renderer.feedback(s)
	for command in renderer.commands:
		if command[0]=="food" and command[1]=="frango":check(sprite_size(command)==whole,"Ingrediente não encolhe durante o corte")
	advance(2.1)
	var chopped := held_size(s,s.player.hand)
	await click_object("stove")
	var stove
	for o in s.objects:
		if o.type=="stove":stove=o
	renderer.commands=[];renderer.object(s,stove,false)
	for command in renderer.commands:
		if command[0]=="food" and command[1]=="frango_cut":check(sprite_size(command)==chopped,"Ingrediente cortado mantém tamanho ao ir ao fogão")
	await take("arroz")
	var rice := held_size(s,s.player.hand)
	await click_object("stove")
	renderer.commands=[];renderer.object(s,stove,false)
	for command in renderer.commands:
		if command[0]=="food" and command[1]=="arroz":check(sprite_size(command)==rice,"Arroz mantém tamanho entre mão e fogão")
	await click_object("stove");advance(8.1);await click_object("stove");await click_object("kitchen");advance(2.1)
	var meal := held_size(s,{"item":"dish_frangoArroz","n":1})
	renderer.commands=[];renderer.object(s,table,false)
	for command in renderer.commands:
		if command[0]=="food" and command[1]=="frangoArroz":check(sprite_size(command)==meal,"Prato pronto mantém tamanho entre bancada e mãos")
	# Serving uses the same real plate as carrying, independently of the table rotation.
	var dining := {"id":900,"type":"table","room":"restaurant","x":8,"y":10,"rot":0}
	var chair := {"id":901,"type":"chair","room":"restaurant","x":8,"y":11,"rot":0}
	var scene: Dictionary = s.duplicate(true)
	scene.objects=[dining,chair];scene.customers=[{"seat":901,"state":"eating","recipe":"frangoArroz","order":999}]
	renderer.commands=[];renderer.object(scene,dining,false)
	for command in renderer.commands:
		if command[0]=="food":check(sprite_size(command)==meal,"Prato servido mantém tamanho da preparação e das mãos")
	check(g.session.SAVE.VALIDATOR.valid(s),"Fluxo preserva comida e equipamentos")
	if "--capture" in OS.get_cmdline_user_args():
		root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1920,1080);await layout();g.session.set_zoom(1.6)
		# A full station shows actual clean stacks and four served plates.
		s.equipment.plate+=20-int(table.plates);table.plates=20
		for i in 3:g.session.BUILD.STORE.put(s,table,"dish_frangoArroz",1);s.equipment.plate+=1;s.meals.made.frangoArroz+=1
		g.session.selected=null;g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-tamanho-unico-mesa.png")
	await finish()
