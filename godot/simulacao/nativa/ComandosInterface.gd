extends RefCounted
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const RECIPES = preload("res://simulacao/nativa/Receitas.gd")
static func execute(s: Dictionary,operation: String,args: Array) -> Dictionary:
	match operation:
		"priority":
			for order in s.orders:
				if order.id==args[0] and order.state=="ordered":s.priority=order.id;return {"ok":true,"message":null}
		"menu":
			if RECIPES.RECIPES.data.has(args[0]) and args[1] is bool:s.menu[args[0]]=args[1];return {"ok":true,"message":null}
		"price":
			if RECIPES.RECIPES.data.has(args[0]) and ADMIN.numeric(args[1]) and args[1]>=1 and args[1]<=100:
				s.prices[args[0]]=args[1]
				var cost := 0.0
				for food in RECIPES.RECIPES.data[args[0]].foods:cost+=RECIPES.RECIPES.data[args[0]].foods[food]*RECIPES.ITEMS.data[food].cost
				s.message="Preço atualizado. Margem por prato: $%.2f"%(args[1]-cost);return {"ok":true,"message":s.message}
			s.message="Informe um preço de 1 a 100.";return {"ok":false,"message":s.message}
		"task":
			if args[1] in (["none","waiter"] if s.singleRoom else ["none","logistics","waiter"]):
				for worker in s.workers:
					if worker.id==args[0]:worker.task=args[1];s.message="Tarefa contínua atribuída. Rotas respeitam móveis e outras pessoas.";return {"ok":true,"message":s.message}
		"clear":
			s.erase("tableStains");s.erase("floorDirt")
			var clean := PARTIDA.fresh(s.compact==true,s.singleRoom==true)
			s.erase("receivingQuality")
			for key in ["open","closing","tick","arrival","objects","equipment","meals","dirtyTables","inventory","selectedSlot","tools","inv","purchased","used","orders","deliveries","customers","residents","player","workers","cookActive","cooking","plating","chopping","recovery","ready","priority","flowWaits"]:s[key]=clean[key]
			s.message="Teste limpo: móveis e itens removidos. Serviço, entregas e preparos cancelados; dinheiro e dia preservados."
			return {"ok":true,"message":s.message}
	return {"ok":false,"message":null}
