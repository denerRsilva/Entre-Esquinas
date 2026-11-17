extends RefCounted
const INV = preload("res://simulacao/nativa/Inventario.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const NUM = preload("res://simulacao/nativa/Conservacao.gd")
const RECIPE_COST := 30
static func active(s: Dictionary) -> bool:return s.get("refuge") is Dictionary
static func visiting(s: Dictionary) -> bool:return s.day>=4 and int(s.day)%4==0
static func daily(s: Dictionary) -> Dictionary:return {"arroz":12,"batata":12,"cenoura":12} if s.has("startKit") else {"arroz":12,"legumes":12,"frango":6}
static func initialize(s: Dictionary) -> bool:
	if not active(s) or s.has("market"):return true
	if not NUM.integer(s.get("day")) or s.day<1:return false
	s.market={"version":1,"day":s.day,"stock":daily(s),"travelStock":6 if visiting(s) else 0}
	return true
static func restock(s: Dictionary) -> void:
	if not active(s):return
	if not s.has("market"):initialize(s)
	if s.market.day==s.day:return
	s.market.day=s.day;s.market.stock=daily(s);s.market.travelStock=6 if visiting(s) else 0
static func near(s: Dictionary,traveler: bool = false) -> bool:
	if not active(s) or s.player.room!="street" or s.player.get("motion")!=null:return false
	for person in s.residents:
		if person.id==("nina" if traveler else "beto"):
			return s.player.room==person.room and absf(s.player.x-person.x)+absf(s.player.y-person.y)<=1 and s.refuge.phase=="day" and (not traveler or visiting(s))
	return false
static func error(s: Dictionary,food: String,amount: Variant,traveler: bool = false) -> String:
	if not near(s,traveler) or not s.get("market") is Dictionary:return "Aproxime-se do vendedor na cidade."
	if not NUM.integer(amount) or amount<1 or amount>12:return "Quantidade inválida."
	var stock: Dictionary = {"frango":s.market.travelStock} if traveler else s.market.stock
	if not stock.has(food) or stock[food]<amount:return "Estoque esgotado por hoje."
	if s.cash<INV.ITEMS.data[food].cost*amount:return "Dinheiro insuficiente."
	var capacity := 0
	for o in s.objects:
		if o.type=="fridge":capacity+=INV.space(o.inventory,food)
	if capacity<amount:return "Libere espaço na geladeira antes de comprar."
	return ""
static func buy(s: Dictionary,food: String,amount: Variant,traveler: bool = false) -> Dictionary:
	var reason := error(s,food,amount,traveler)
	if not reason.is_empty():return {"ok":false,"message":reason}
	var left: int = int(amount)
	for o in s.objects:
		if o.type!="fridge":continue
		var count := mini(left,INV.space(o.inventory,food))
		if count>0:INV.add(o.inventory,food,count);left-=count
		if left==0:break
	var price: float = INV.ITEMS.data[food].cost*amount
	s.cash-=price;s.ledger.purchases+=price;s.purchased[food]=s.purchased.get(food,0)+amount
	if traveler:s.market.travelStock-=amount
	else:s.market.stock[food]-=amount
	STORE.sync(s)
	return {"ok":true,"message":"Compra entregue na geladeira."}
static func learn(s: Dictionary) -> bool:
	if not near(s,true) or not s.get("startKit") is Dictionary or "canja" in s.startKit.recipes or s.cash<RECIPE_COST:return false
	s.cash-=RECIPE_COST;s.ledger.investment+=RECIPE_COST;s.startKit.recipes.append("canja");s.menu.canja=true
	return true
static func valid(s: Dictionary) -> bool:
	if not s.has("market"):return not s.has("startKit")
	var m = s.market
	if not active(s) or not m is Dictionary or m.get("version")!=1 or m.get("day")!=s.day or not m.get("stock") is Dictionary:return false
	var maximum := daily(s)
	if m.stock.size()!=maximum.size():return false
	for food in maximum:
		if not NUM.integer(m.stock.get(food)) or m.stock[food]<0 or m.stock[food]>maximum[food]:return false
	return NUM.integer(m.get("travelStock")) and m.travelStock>=0 and m.travelStock<=(6 if visiting(s) else 0)
