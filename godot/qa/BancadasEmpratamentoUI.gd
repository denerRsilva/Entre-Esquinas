extends "res://qa/BaseInterfaceNativa.gd"
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var build = g.session.BUILD
	# Every small silhouette and rotation rejects plating, without payment.
	for type in ["counterH","counterV","counterCorner"]:
		for rotation in 4:
			var placed: Dictionary = build.place(s,type,20,11,rotation)
			check(placed.ok,"Compra bancada "+type+str(rotation))
			if not placed.ok:continue
			var counter: Dictionary = placed.object
			var cash: float = s.cash
			check(not build.install_kit(s,"platingKit",20,11).ok and counter.type==type and s.cash==cash,"Peça pequena recusa kit sem cobrar")
			check(build.install_kit(s,"cuttingKit",20,11).ok,"Peça pequena continua aceitando corte")
			check(build.remove_kit(s,counter.id).ok,"Retira kit de corte")
			check(build.remove(s,counter.id).ok,"Retira peça de teste")
	# The existing 2x1 work surface is the same size as the preparation table.
	var placed: Dictionary = build.place(s,"worktable",20,11)
	check(placed.ok and build.install_kit(s,"platingKit",20,11).ok,"Superfície 2x1 aceita empratamento")
	var large: Dictionary = placed.object
	check(STORE.plating_surface(large),"Critério usa tamanho da base física")
	large.rot=1
	check(STORE.plating_surface(large),"Rotação mantém compatibilidade")
	large.rot=0
	check(g.session.SAVE.VALIDATOR.valid(s),"Estado com superfícies permitidas é válido")
	# Legacy equipped small counters preserve stock/quality and refund the kit.
	var old: Dictionary = s.duplicate(true)
	var small = build.find(old.objects,large.id)
	small.baseType="counterCorner";small.plates=20;small.utensil=true
	small.dishes={"dish_sopa":4};small.dishQuality={"dish_sopa":[0,1,1,1]}
	old.equipment.plate+=24;old.equipment.spoon+=1;old.meals.made.sopa+=4
	var cash: float = old.cash
	var loaded = g.session.SAVE.new().load_value(old)
	check(loaded!=null,"Save antigo de bancada pequena carrega")
	if loaded!=null:
		var restored = build.find(loaded.objects,large.id)
		check(restored.type=="counterCorner" and not restored.has("tableKit"),"Recupera bancada sem alterar posição")
		check(loaded.cash==cash+35 and loaded.ledger.investment==old.ledger.investment-35,"Reembolsa integralmente kit removido")
		check(equivalent(loaded.equipment,old.equipment) and equivalent(loaded.meals,old.meals),"Preserva totais de louça, utensílios e comida")
		var qualities := [0,0,0,0];var plates := 0
		for container in g.session.SAVE.VALIDATOR.N.locations(loaded):
			for p in container:
				if p==null:continue
				if p.item=="dish_sopa":qualities[int(p.get("quality",0))]+=int(p.n)
				if p.item=="plate":plates+=int(p.n)
		check(qualities==[1,1,1,1] and plates==32,"Preserva cada prato e qualidade no armazenamento")
		var again = g.session.SAVE.new().load_value(loaded)
		check(again!=null and again.cash==loaded.cash,"Segundo carregamento não duplica reembolso")
	var pending: Dictionary = old.duplicate(true)
	pending.player.hand={"item":"pot_sopa_1","n":1,"quality":2};pending.equipment.pot+=1;pending.meals.made.sopa+=1
	pending.plating={"prep":large.id,"item":"pot_sopa_1","recipe":"sopa","portions":1,"count":1,"quality":2,"hand":true,"left":1,"total":2}
	loaded=g.session.SAVE.new().load_value(pending)
	check(loaded!=null and loaded.plating==null and loaded.player.hand.item=="pot_sopa_1","Tarefa antiga é cancelada e panela com comida permanece nas mãos")
	var corrupt: Dictionary = pending.duplicate(true);corrupt.plating.quality=3
	check(g.session.SAVE.new().load_value(corrupt)==null,"Migração rejeita tarefa corrompida em vez de ocultá-la")
	# Full stores use recovery; the original snapshot stays unchanged.
	var full: Dictionary = old.duplicate(true)
	for o in full.objects:
		if not o.has("inventory") or not STORE.accepts(o,"plate"):continue
		for p in o.inventory:
			if p!=null:full.recovery.append(p.duplicate(true))
		for i in o.inventory.size():o.inventory[i]={"item":"plate","n":99};full.equipment.plate+=99
	loaded=g.session.SAVE.new().load_value(full)
	check(loaded!=null and g.session.SAVE.serialize(loaded) is String,"Itens ficam recuperáveis quando não há espaço")
	check(build.find(old.objects,large.id).baseType=="counterCorner" and old.cash==cash,"Migração trabalha por cópia")
	check(not g.session.SAVE.VALIDATOR.valid(old),"Estado novo não pode manter empratamento em bancada pequena")
	await finish()
