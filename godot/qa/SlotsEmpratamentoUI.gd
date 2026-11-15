extends "res://qa/BaseInterfaceNativa.gd"
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const LAYOUT = preload("res://moveis/LayoutEmpratamento.gd")
func totals(state: Dictionary) -> Array:
	var result := [0,0,0,0]
	for container in g.session.SAVE.VALIDATOR.N.locations(state):
		for portion in container:
			if portion!=null and portion.item=="dish_sopa":result[int(portion.get("quality",0))]+=int(portion.n)
	for o in state.objects:
		if o.type!="kitchen":continue
		result[0]-=STORE.count(o,"dish_sopa")
		for q in 4:result[q]+=STORE.quality_count(o,"dish_sopa",q)
	return result
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var table: Dictionary
	for o in s.objects:
		if o.type=="kitchen":table=o
	var kitchen = g.session.SIM.KITCHEN.new()
	# Distinct meals occupy four real places, never a single drawn stack.
	for q in 4:
		check(STORE.put(s,table,"dish_sopa",1,q)==1,"Insere prato na vaga "+str(q+1))
		s.equipment.plate+=1;s.meals.made.sopa+=1
	check(STORE.put(s,table,"dish_sopa",1)==0 and STORE.ready_count(table)==4,"Recusa quinto prato sem alterar estoque")
	s.player.hand={"item":"pot_sopa_1","n":1,"quality":2};s.equipment.pot+=1;s.meals.made.sopa+=1
	var count: int = table.plates
	check(kitchen.plating_plan(s,table).get("error")=="Área de retirada cheia." and table.plates==count and s.player.hand.item=="pot_sopa_1","Mesa cheia preserva panela e pratos limpos")
	g.tick(0)
	var node = g.palco.pool.kitchen[0]
	var stock_layout: Dictionary = node.disposicao_pratos()
	check(stock_layout.plates[0].position.x==stock_layout.plates[10].position.x and stock_layout.plates[0].position.y<stock_layout.plates[10].position.y,"Pilhas à esquerda, uma acima da outra")
	var scene: Array = g.session.step(0,[]).scene
	var food := []
	for command in scene:
		if command[0]=="food" and command[1]=="sopa":food.append(command)
	check(food.size()==4,"Quatro sprites de refeições")
	if food.size()==4:
		check(food[0][2]==food[1][2] and food[0][3]>food[1][3],"Direita inferior e superior")
		check(food[2][2]==food[3][2] and food[2][3]<food[3][3] and food[2][2]<food[0][2],"Centro superior e inferior")
		for a in 4:
			for b in range(a+1,4):check(not Rect2(food[a][2],food[a][3],food[a][4],food[a][5]).intersects(Rect2(food[b][2],food[b][3],food[b][4],food[b][5])),"Pratos prontos não se sobrepõem")
	# Old valid saves can contain more food. Preserve quantity and quality.
	var old: Dictionary = s.duplicate(true)
	var old_table = g.session.BUILD.find(old.objects,table.id)
	old_table.dishes.dish_sopa+=3;old_table.dishQuality.dish_sopa[3]+=3
	old.equipment.plate+=3;old.meals.made.sopa+=3
	var before := totals(old)
	var loaded = g.session.SAVE.new().load_value(old)
	check(loaded!=null,"Carrega sete pratos de save antigo")
	if loaded!=null:
		check(STORE.ready_count(g.session.BUILD.find(loaded.objects,table.id))==4 and totals(loaded)==before,"Preserva todas as receitas e qualidades do excedente")
		check(g.session.SAVE.serialize(loaded) is String and equivalent(loaded.meals,old.meals) and equivalent(loaded.equipment,old.equipment),"Save migrado conserva refeições e equipamentos")
	var full: Dictionary = old.duplicate(true)
	for o in full.objects:
		if not o.has("inventory") or not STORE.accepts(o,"dish_sopa"):continue
		for slot in o.inventory:
			if slot!=null:full.recovery.append(slot.duplicate(true))
		for i in o.inventory.size():o.inventory[i]={"item":"plate","n":99};full.equipment.plate+=99
	loaded=g.session.SAVE.new().load_value(full)
	check(loaded!=null,"Carrega save com armazenamento cheio")
	if loaded!=null:
		var extra := 0
		for p in loaded.recovery:
			if p.item=="dish_sopa":extra+=int(p.n)
		check(extra==3 and totals(loaded)==before and g.session.SAVE.serialize(loaded) is String,"Recuperação preserva excedente com qualidade")
	var malformed: Dictionary = old.duplicate(true)
	g.session.BUILD.find(malformed.objects,table.id).dishQuality.dish_sopa=[0,0,0,99]
	check(g.session.SAVE.new().load_value(malformed)==null,"Rejeita qualidade corrompida sem mascará-la")
	check(g.session.BUILD.find(old.objects,table.id).dishes.dish_sopa==7,"Migração não altera arquivo de origem")
	# One removed dish frees one place; a completed job waits if that place fills.
	STORE.take(s,table,"dish_sopa",1,0);s.recovery.append({"item":"dish_sopa","n":1})
	check(not kitchen.plating_plan(s,table).has("error"),"Retirada libera uma vaga")
	await click_object("kitchen")
	check(s.plating!=null,"Começa empratamento na vaga livre")
	STORE.put(s,table,"dish_sopa",1,0);s.equipment.plate+=1;s.meals.made.sopa+=1
	kitchen.plate_step(s,2.1)
	check(s.plating!=null and s.player.hand.item=="pot_sopa_1" and table.plates==count,"Sem vaga, tarefa aguarda sem perder comida")
	STORE.take(s,table,"dish_sopa",1,0);s.recovery.append({"item":"dish_sopa","n":1})
	kitchen.plate_step(s,0)
	check(s.plating==null and s.player.hand.item=="pot" and table.plates==count-1 and STORE.ready_count(table)==4,"Conclui ao liberar vaga e mantém panela vazia nas mãos")
	check(g.session.SAVE.VALIDATOR.valid(s),"Estado final conserva comida e pratos")
	# All compact/rotated layouts keep their six positions distinct and oval.
	for axes in [Vector2.ONE,Vector2(0.5,2)]:
		for counter in [false,true]:
			var geometry := LAYOUT.frame(axes,counter)
			for i in 4:
				var dish := Rect2(LAYOUT.ready(i,geometry)-Vector2(9,5)*geometry.size,Vector2(18,10)*geometry.size)
				for pile in 2:
					for layer in 10:check(not dish.intersects(LAYOUT.clean(pile,layer,geometry)),"Limpos e servidos separados nas rotações")
	if "--capture" in OS.get_cmdline_user_args():
		root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1920,1080);await layout();g.session.set_zoom(1.6)
		for plates in [0,3,20]:
			s.equipment.plate+=plates-int(table.plates);table.plates=plates;g.session.selected=null;g.tick(0);await layout();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/esquinas-quatro-pratos-"+str(plates)+".png")
	await finish()
