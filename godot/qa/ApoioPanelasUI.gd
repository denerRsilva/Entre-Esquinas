extends "res://qa/BaseInterfaceNativa.gd"
const KITCHEN = preload("res://simulacao/nativa/Cozinha.gd")
var kitchen = KITCHEN.new()
func nearby(s: Dictionary,o: Dictionary):
	var point: Dictionary = g.session.MOVE.access(s,o).back()
	s.player.room=o.room;s.player.x=point.x;s.player.y=point.y;s.player.motion=null;s.player.goal=null
	g.session.velocity=null;kitchen.manual_moving=false
func act(s: Dictionary,o: Dictionary,action: String) -> Dictionary:
	nearby(s,o);return kitchen.physical(s,o.id,action)
func saved(s: Dictionary,label: String) -> Variant:
	var raw = g.session.SAVE.serialize(s)
	var loaded = g.session.SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
	check(loaded!=null,label+": salva e carrega com conservação")
	return loaded
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var surfaces := []
	for entry in [["worktable",20,11],["counterH",19,11],["counterV",22,11],["counterCorner",22,12]]:
		var built: Dictionary = g.session.BUILD.place(s,entry[0],entry[1],entry[2])
		check(built.ok,"Compra de "+entry[0])
		if not built.ok:await finish();return
		surfaces.append(built.object)
	var stove: Dictionary;var prep: Dictionary;var plating: Dictionary;var rack: Dictionary
	for o in s.objects:
		if o.type=="stove":stove=o
		if o.type=="prep":prep=o
		if o.type=="kitchen":plating=o
		if o.type=="potRack":rack=o
	check(act(s,stove,"takePan").ok,"Retira panela vazia do fogão")
	for surface in surfaces:
		var portion: Dictionary = s.player.hand.duplicate(true)
		check(act(s,surface,"support").ok and s.player.hand==null and equivalent(surface.support,portion),surface.type+": panela ocupa superfície livre")
		var loaded = saved(s,surface.type)
		if surface.type=="counterH":
			for key in ["inventory","ingredients","dishes"]:
				var corrupt: Dictionary = s.duplicate(true)
				g.session.BUILD.find(corrupt.objects,surface.id)[key]=null
				check(not g.session.SAVE.VALIDATOR.K.physical(corrupt),"Conteúdo malformado da bancada é rejeitado sem erro: "+key)
		if loaded!=null:
			var restored = g.session.BUILD.find(loaded.objects,surface.id)
			check(act(loaded,restored,"takePan").ok and equivalent(loaded.player.hand,portion),surface.type+": retira panela após carregar")
		var cash: float = s.cash
		check(g.session.BUILD.kit_error(s,"cuttingKit",surface.x,surface.y)!=null and s.cash==cash,"Kit não sobrepõe panela")
		check(not g.session.BUILD.remove(s,surface.id).ok,"Não vende superfície com panela")
		nearby(s,rack)
		check(kitchen.storage(s,rack.id,"take",0).ok,"Segunda panela retirada da estante")
		var before: Dictionary = surface.duplicate(true);var hand: Dictionary = s.player.hand.duplicate(true)
		check(not act(s,surface,"support").ok and equivalent(before,surface) and equivalent(hand,s.player.hand),"Não sobrepõe duas panelas")
		nearby(s,rack);check(kitchen.storage(s,rack.id,"put",0).ok,"Segunda panela volta à estante")
		check(act(s,surface,"takePan").ok and equivalent(s.player.hand,portion),"Retira panela sem perder conteúdo")
	# Any contents block support, including tools or plates left by another system.
	var bench: Dictionary = surfaces[0]
	for content in [{"plates":1},{"utensil":true},{"dishes":{"dish_frangoArroz":1}},{"inventory":[{"item":"plate","n":1}]},{"tableKit":"cuttingKit"},{"ingredients":[{"item":"arroz","n":1}]}]:
		bench.merge(content,true)
		var before: Dictionary = bench.duplicate(true);var hand: Dictionary = s.player.hand.duplicate(true)
		check(not act(s,bench,"support").ok and equivalent(bench,before) and equivalent(s.player.hand,hand),"Qualquer conteúdo impede apoio: "+str(content.keys()))
		for key in content:bench.erase(key)
	for target in [prep,plating]:
		var before: Dictionary = target.duplicate(true)
		check(not act(s,target,"support").ok and equivalent(before,target) and s.player.hand.item=="pot","Kit de ferramentas bloqueia panela, mesmo sem utensílios avulsos")
	var orphan: Dictionary = stove.duplicate(true)
	stove.ingredients=[{"item":"arroz","n":1}]
	check(not act(s,stove,"installPan").ok and s.player.hand.item=="pot","Ingrediente já presente também impede colocar panela")
	stove.ingredients=orphan.ingredients
	check(act(s,stove,"installPan").ok,"Panela vazia volta ao fogão")
	# Real cooking, support, pickup, return to the stove and plating from hand.
	g.tick(0);await take("frango");await click_object("prep");advance(2.1)
	await click_object("stove");await take("arroz");await click_object("stove");await click_object("stove");advance(8.1);await click_object("stove")
	check(s.player.hand!=null and s.player.hand.item=="pot_frangoArroz_1","Cozimento real entrega panela cheia")
	if s.player.hand==null or s.player.hand.item!="pot_frangoArroz_1":
		await finish();return
	var full: Dictionary = s.player.hand.duplicate(true)
	await click_object("worktable")
	check(s.player.hand==null and equivalent(bench.support,full),"Clique apoia panela cheia na mesa vazia")
	var packet: Dictionary = g.session.step(0,[])
	check(packet.scene.any(func(op):return op[0]=="img" and op[1]=="taverna/moveis.png" and op[2]==710),"Panela apoiada aparece no cenário")
	var loaded = saved(s,"Panela cheia na mesa")
	if loaded!=null:check(equivalent(g.session.BUILD.find(loaded.objects,bench.id).support,full),"Save preserva comida e qualidade")
	await click_object("worktable");check(equivalent(s.player.hand,full),"Clique retira panela cheia intacta")
	# Exercise the other shapes with full pots, too.
	for surface in surfaces.slice(1):
		check(act(s,surface,"support").ok,"Bancada aceita panela cheia: "+surface.type)
		saved(s,"Panela cheia "+surface.type)
		check(act(s,surface,"takePan").ok and equivalent(s.player.hand,full),"Bancada devolve porções e qualidade")
	var legacy: Dictionary = s.duplicate(true)
	var old_table = g.session.BUILD.find(legacy.objects,plating.id)
	old_table.support=legacy.player.hand;legacy.player.hand=null
	check(saved(legacy,"Save antigo com panela no empratamento")!=null,"Save antigo não perde panela")
	check(act(legacy,old_table,"takePan").ok,"Panela antiga continua recuperável")
	var burned: Dictionary = s.duplicate(true);burned.player.hand.burned=true;burned.player.hand.quality=2
	var other_stove = g.session.BUILD.find(burned.objects,stove.id)
	check(act(burned,other_stove,"installPan").ok and other_stove.get("burned",false),"Fogão preserva condição queimada")
	check(act(burned,other_stove,"takePan").ok and burned.player.hand.get("burned",false) and burned.player.hand.quality==2,"Retirada preserva condição e qualidade")
	await click_object("stove")
	check(s.player.hand==null and stove.pan==full.item and stove.readyBatch.quality==full.get("quality",0),"Fogão vazio aceita panela cheia")
	saved(s,"Panela cheia no fogão")
	# Attempt a second pot on an occupied stove without changing either item.
	nearby(s,rack);check(kitchen.storage(s,rack.id,"take",0).ok,"Pega segunda panela para teste de fogão ocupado")
	var snapshot: Dictionary = stove.duplicate(true)
	check(not act(s,stove,"installPan").ok and equivalent(stove,snapshot) and s.player.hand.item=="pot","Fogão ocupado não sobrescreve panela cheia")
	nearby(s,rack);kitchen.storage(s,rack.id,"put",0)
	await click_object("stove");await click_object("kitchen")
	check(s.plating!=null and s.plating.get("hand",false) and plating.get("support")==null,"Emprata nas mãos sem apoiar no kit ocupado")
	advance(2.1);check(s.player.hand.item=="pot" and plating.get("support")==null,"Empratamento devolve panela vazia às mãos")
	await click_object("kitchen")
	check(s.player.hand.item=="pot" and plating.get("support")==null,"Panela vazia não é apoiada sobre pratos e talheres")
	saved(s,"Fluxo completo")
	await click_object("worktable")
	s.player.x=17;s.player.y=10;s.player.motion=null;s.player.goal=null;s.player.erase("settled")
	g.session.enter_construction()
	var moved: Dictionary = g.session.BUILD.place(s,"worktable",20,10,1,bench.id)
	check(moved.ok and moved.object.get("support",{}).get("item")=="pot","Mover e girar mesa transporta a panela")
	if moved.ok:saved(s,"Mesa movida com panela")
	g.session.root_action("exitConstruction");g.tick(0)
	if "--capture" in OS.get_cmdline_user_args():
		for surface in surfaces.slice(1):
			nearby(s,rack)
			for slot in rack.inventory.size():
				if rack.inventory[slot]!=null:
					kitchen.storage(s,rack.id,"take",slot);break
			check(act(s,surface,"support").ok,"Panela visível na captura de "+surface.type)
		s.player.x=18;s.player.y=11;s.player.motion=null;s.player.goal=null;s.player.erase("settled");g.session.selected=null
		root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1920,1080);await layout();g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-apoio-panelas.png")
	await finish()
