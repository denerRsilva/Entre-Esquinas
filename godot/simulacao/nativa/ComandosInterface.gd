extends RefCounted
const BAL = preload("res://simulacao/nativa/Equilibrio.gd")
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const RECIPES = preload("res://simulacao/nativa/Receitas.gd")
static func execute(s: Dictionary,operation: String,args: Array) -> Dictionary:
	match operation:
		"priority":
			for order in s.orders:
				if order.id==args[0] and order.state=="ordered":s.priority=order.id;return {"ok":true,"message":null}
		"menu":
			if args[0] in RECIPES.available(s) and args[1] is bool:s.menu[args[0]]=args[1];return {"ok":true,"message":null}
		"price":
			if args[0] in RECIPES.available(s) and ADMIN.numeric(args[1]) and args[1]>=(BAL.bounds(args[0]).x if BAL.active(s) else 1) and args[1]<=(BAL.bounds(args[0]).y if BAL.active(s) else 100):
				s.prices[args[0]]=args[1]
				var cost := 0.0
				for food in RECIPES.RECIPES.data[args[0]].foods:cost+=RECIPES.RECIPES.data[args[0]].foods[food]*RECIPES.ITEMS.data[food].cost
				s.message="Preço atualizado. Margem por prato: $%.2f"%(args[1]-cost);return {"ok":true,"message":s.message}
			s.message="Use a faixa de preço indicada no cardápio." if BAL.active(s) else "Informe um preço de 1 a 100.";return {"ok":false,"message":s.message}
		"task":
			if not preload("res://simulacao/nativa/Contratacao.gd").task_allowed(s,args[0],args[1]):return {"ok":false,"message":"Essa função ainda não está disponível para a pessoa contratada."}
			if args[1] in (["none","waiter"] if s.singleRoom else ["none","logistics","waiter"]):
				for worker in s.workers:
					if worker.id==args[0]:worker.task=args[1];s.message="Tarefa contínua atribuída. Rotas respeitam móveis e outras pessoas.";return {"ok":true,"message":s.message}
		"clear":
			var hired: Array = s.workers.duplicate(true) if preload("res://simulacao/nativa/Contratacao.gd").active(s) else []
			s.erase("tableStains");s.erase("floorDirt");s.erase("washing")
			var clean := PARTIDA.fresh(s.compact==true,s.singleRoom==true)
			s.erase("receivingQuality")
			for key in ["open","closing","tick","arrival","objects","equipment","meals","dirtyTables","inventory","selectedSlot","tools","inv","purchased","used","orders","deliveries","customers","residents","player","workers","cookActive","cooking","plating","chopping","recovery","ready","priority","flowWaits"]:s[key]=clean[key]
			if preload("res://simulacao/nativa/Contratacao.gd").active(s):
				for worker in hired:
					worker.merge({"room":"restaurant","x":12 if worker.id=="worker2" else 13,"y":10,"goal":null,"motion":null,"carry":null,"wait":0,"hold":0},true)
					worker.erase("settled");worker.erase("noteJob");worker.erase("idleUntil");worker.erase("mealBreak")
				s.workers=hired
			if s.has("startKit"):
				for raw in preload("res://simulacao/nativa/Inventario.gd").RAWS:
					s.purchased[raw]=s.purchased.get(raw,0);s.used[raw]=s.used.get(raw,0)
					for loc in s.inv:s.inv[loc][raw]=s.inv[loc].get(raw,0)
				for id in RECIPES.RECIPES.data:
					for kind in ["made","eaten","wasted"]:s.meals[kind][id]=s.meals[kind].get(id,0)
			s.message="Teste limpo: móveis e itens removidos. Serviço, entregas e preparos cancelados; dinheiro e dia preservados."
			return {"ok":true,"message":s.message}
	return {"ok":false,"message":null}
