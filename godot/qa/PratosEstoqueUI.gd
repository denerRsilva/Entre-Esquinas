extends "res://qa/BaseInterfaceNativa.gd"
const STOCK = preload("res://simulacao/nativa/Armazenamento.gd")
var table: Dictionary
func set_stock(count: int):
	g.session.state.equipment.plate+=count-int(table.plates);table.plates=count;g.tick(0)
func check_stock(count: int,label: String):
	var node = g.palco.pool.kitchen[0]
	check(table.plates==count and node.pratos_limpos==count,label+": estoque chega ao móvel")
	var layout: Dictionary = node.disposicao_pratos()
	check(layout.plates.size()==count and layout.piles==[mini(10,count),maxi(0,count-10)],label+": um sprite por prato, duas pilhas de até dez")
func run():
	await start_game()
	var s: Dictionary = g.session.state
	for o in s.objects:
		if o.type=="kitchen":table=o
	check_stock(12,"Início mobiliado")
	for count in [0,1,2,3,9,10,11,12,19,20,0,3]:
		set_stock(count);check_stock(count,"Quantidade "+str(count))
		check(g.session.SAVE.VALIDATOR.valid(s),"Conservação válida em "+str(count))
	await click_object("kitchen");check_stock(2,"Retira um prato")
	check(s.player.hand.item=="plate","Prato retirado fica nas mãos")
	await click_object("kitchen");check_stock(3,"Devolve um prato")
	set_stock(20)
	check(g.session.ADMIN.buy_tool(s,"plate"),"Compra prato adicional")
	var hand: Dictionary = s.player.hand.duplicate(true)
	var kitchen = g.session.SIM.KITCHEN.new()
	check(not kitchen.physical(s,table.id,"installPlates").ok and equivalent(s.player.hand,hand),"Mesa cheia recusa o 21º prato sem apagar item")
	g.tick(0);check_stock(20,"Capacidade cheia")
	set_stock(19)
	check(kitchen.physical(s,table.id,"installPlates").ok,"Repor o vigésimo prato funciona")
	g.tick(0);check_stock(20,"Reposição no limite")
	check(STOCK.space(table,"plate")==0,"Armazenamento aplica capacidade vinte")
	var invalid: Dictionary = s.duplicate(true)
	g.session.BUILD.find(invalid.objects,table.id).plates=21;invalid.equipment.plate+=1
	check(not g.session.SAVE.VALIDATOR.valid(invalid),"Estado novo com 21 pratos é inválido")
	set_stock(1)
	await click_object("kitchen");check_stock(0,"Retira o último prato")
	await click_object("kitchen");check_stock(1,"Repõe o primeiro prato")
	# Old valid saves could contain up to 99. Preserve overflow and totals.
	var old: Dictionary = s.duplicate(true)
	old.equipment.plate+=99-int(g.session.BUILD.find(old.objects,table.id).plates);g.session.BUILD.find(old.objects,table.id).plates=99
	var loaded = g.session.SAVE.new().load_value(old)
	check(loaded!=null,"Carrega save antigo com 99 pratos")
	if loaded!=null:
		check(g.session.BUILD.find(loaded.objects,table.id).plates==20 and loaded.equipment.plate==old.equipment.plate,"Limita pilha e preserva todos os pratos antigos")
		var stored := 0
		for o in loaded.objects:
			if o.has("inventory"):stored+=STOCK.count(o,"plate")
		check(stored==79,"Excedente antigo vai para armazenamento disponível")
		check(g.session.SAVE.serialize(loaded) is String,"Save migrado pode ser gravado novamente")
	var full_storage: Dictionary = old.duplicate(true)
	for o in full_storage.objects:
		if not o.has("inventory") or not STOCK.accepts(o,"plate"):continue
		for slot in o.inventory:
			if slot!=null:full_storage.recovery.append(slot.duplicate(true))
		for i in o.inventory.size():o.inventory[i]={"item":"plate","n":99};full_storage.equipment.plate+=99
	var recovered = g.session.SAVE.new().load_value(full_storage)
	check(recovered!=null,"Migração também funciona com geladeiras cheias")
	if recovered!=null:
		var extra := 0
		for p in recovered.recovery:
			if p.item=="plate":extra+=p.n
		check(extra==79 and recovered.equipment.plate==full_storage.equipment.plate,"Sem espaço, excedente fica preservado na recuperação")
	# Scene captures show actual quantities, without a decorative baked plate.
	if "--capture" in OS.get_cmdline_user_args():
		root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1920,1080);await layout();g.session.set_zoom(1.6)
		for count in [0,3,12,20]:
			set_stock(count);g.session.selected=null;g.tick(0);await layout();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/esquinas-pilha-"+str(count)+".png")
	set_stock(3)
	await take("frango");await click_object("prep");advance(2.1);await click_object("stove")
	await take("arroz");await click_object("stove");await click_object("stove");advance(8.1);await click_object("stove")
	await click_object("kitchen");advance(2.1);check_stock(2,"Empratar consome um prato real")
	check(s.player.hand.item=="pot","Panela vazia continua nas mãos")
	if "--capture" in OS.get_cmdline_user_args():
		g.session.selected=null;g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/esquinas-pilha-empratado.png")
	var raw = g.session.SAVE.serialize(s)
	var restored = g.session.SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
	check(restored!=null and g.session.BUILD.find(restored.objects,table.id).plates==2,"Salvar e carregar preserva estoque exibido")
	var built: Dictionary = g.session.BUILD.place(s,"counterCorner",20,11)
	check(built.ok and g.session.BUILD.install_kit(s,"platingKit",20,11).ok,"Instala kit em bancada")
	g.tick(0)
	var counter: Dictionary = built.object
	var view = g.palco.pool.platingKit[0]
	check(view.pratos_limpos==0 and view.disposicao_pratos().plates.is_empty(),"Kit novo não contém prato decorativo")
	counter.plates=3;s.equipment.plate+=3;g.tick(0)
	check(view.pratos_limpos==3 and view.disposicao_pratos().plates.size()==3,"Bancada mostra três pratos reais")
	check_stock(2,"Bancadas têm estoques independentes")
	# Reused views must reset to zero when a different object is assigned.
	var packet: Dictionary = g.session.step(0,[])
	packet.scene=[["furniture","kitchen",400,400,80,40,0,false,{"plates":20}],["furniture","kitchen",500,400,80,40,0,false,{"plates":0}]]
	g.palco.paint(packet)
	check(g.palco.pool.kitchen[0].pratos_limpos==20 and g.palco.pool.kitchen[1].pratos_limpos==0,"Duas instâncias recebem quantidades distintas")
	packet.scene.reverse();g.palco.paint(packet)
	check(g.palco.pool.kitchen[0].pratos_limpos==0 and g.palco.pool.kitchen[1].pratos_limpos==20,"Reuso não deixa pratos fantasmas")
	await finish()
