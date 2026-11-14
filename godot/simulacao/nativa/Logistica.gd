extends RefCounted
const KITCHEN = preload("res://simulacao/nativa/Cozinha.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const FOODS = ["arroz","legumes","frango"]
static func storage(s: Dictionary,loc: String,food: String,mode: Variant = null,quality: int = 0) -> Variant:
	for o in s.objects:
		if o.has("inventory") and STORE.location(o)==loc and STORE.accepts(o,food):
			if mode=="take" and STORE.count(o,food)<=0:continue
			if mode=="put" and STORE.space(o,food,quality)<=0:continue
			return o
	return null
static func chunk(s: Dictionary,loc: String,food: String) -> Variant:
	if loc=="receiving":
		for q in 4:
			var amount := ADMIN.receiving_count(s,food,q)
			if amount!=0:return {"n":amount,"quality":q}
		return null
	for source in s.objects:
		if not source.has("inventory") or STORE.location(source)!=loc:continue
		for p in source.inventory:
			if p!=null and p.item==food:return {"n":p.n,"quality":p.get("quality",0),"source":source}
	return null
static func take(s: Dictionary,loc: String,food: String,portion: Dictionary,quantity: float) -> void:
	if loc=="receiving":ADMIN.receive(s,food,-quantity,portion.quality)
	else:STORE.take(s,portion.source,food,quantity,portion.quality)
static func worker(s: Dictionary,w: Dictionary) -> void:
	var carry = w.get("carry")
	if carry!=null and carry.kind=="food":
		var target = storage(s,carry.to,carry.food,"put",carry.get("quality",0))
		if target==null:w.goal=null;return
		var point = MOVE.closest(s,w,target)
		if point!=null:MOVE.go(w,point)
		if MOVE.arrived(w):
			var amount := minf(carry.n,STORE.space(target,carry.food,carry.get("quality",0)))
			STORE.put(s,target,carry.food,amount,carry.get("quality",0));carry.n-=amount
			if carry.n==0:w.carry=null
		return
	for route in [["storage","kitchen"],["receiving","storage"]]:
		var choice: Variant = null
		for food in FOODS:
			var portion = chunk(s,route[0],food)
			if portion!=null and storage(s,route[1],food,"put",portion.quality)!=null:choice={"food":food,"chunk":portion};break
		if choice==null:continue
		var portion: Dictionary = choice.chunk
		var point: Variant = {"room":"restaurant","x":21,"y":12} if route[0]=="receiving" else MOVE.closest(s,w,portion.source)
		if point==null:continue
		MOVE.go(w,point)
		if MOVE.arrived(w):
			var target = storage(s,route[1],choice.food,"put",portion.quality)
			var amount := minf(minf(4,portion.n),STORE.space(target,choice.food,portion.quality))
			if amount!=0:take(s,route[0],choice.food,portion,amount);w.carry={"kind":"food","food":choice.food,"n":amount,"to":route[1],"quality":portion.quality}
		return
	w.goal=null
static func change(s: Dictionary,loc: String,food: String,quantity: float) -> float:
	if loc=="receiving":s.inv.receiving[food]+=quantity;return absf(quantity)
	var left := absf(quantity)
	for o in s.objects:
		if o.has("inventory") and STORE.location(o)==loc:
			var amount: float = STORE.put(s,o,food,left) if quantity>0 else STORE.take(s,o,food,left)
			left-=amount
			if left==0:break
	return absf(quantity)-left
static func transfer(s: Dictionary,source: String,destination: String,food: String,quantity: float) -> float:
	var moved := 0.0
	while moved<quantity:
		var portion = chunk(s,source,food)
		if portion==null:break
		var target = null if destination=="receiving" else storage(s,destination,food,"put",portion.quality)
		var space: float = 60-STORE.amount(s,destination,food) if destination=="receiving" else STORE.space(target,food,portion.quality) if target!=null else 0
		var amount := minf(minf(quantity-moved,portion.n),space)
		if amount<=0:break
		take(s,source,food,portion,amount)
		if target!=null:STORE.put(s,target,food,amount,portion.quality)
		else:ADMIN.receive(s,food,amount,portion.quality)
		moved+=amount
	return moved

static func utility_near(s: Dictionary,type: String,kitchen: RefCounted) -> bool:
	if not s.singleRoom:return s.player.room=="restaurant" and absf(s.player.x-(16 if type=="computer" else 21))+absf(s.player.y-12)<=1
	for o in s.objects:
		if o.type==type and kitchen.near(s,o):return true
	return false
static func collect(s: Dictionary,kitchen: RefCounted) -> String:
	if s.player.get("motion")!=null or kitchen.manual_moving or not utility_near(s,"receiving",kitchen):return "Aproxime-se do recebimento."
	if s.player.get("hand")!=null or s.player.get("carry")!=null or s.get("chopping")!=null or s.get("plating")!=null:return "Libere as mãos antes de recolher."
	for food in FOODS:
		for q in 4:
			if ADMIN.receiving_count(s,food,q)>0:
				ADMIN.receive(s,food,-1,q);s.player.hand={"item":food,"n":1,"quality":q};return "Uma unidade de "+STORE.INV.ITEMS.data[food].name+" nas mãos."
	return "Não há entregas para recolher."
static func supply(s: Dictionary,loc: String,food: String,deposit: bool,kitchen: RefCounted) -> String:
	if loc=="receiving":return collect(s,kitchen)
	var target: Variant = null
	for o in s.objects:
		if not o.has("inventory") or STORE.location(o)!=loc or not STORE.accepts(o,food):continue
		for p in MOVE.access(s,o):
			if s.player.room==p.room and s.player.x==p.x and s.player.y==p.y:target=o;break
		if target!=null:break
	if target==null:return "Aproxime-se do equipamento adequado."
	var index: int = int(s.selectedSlot) if deposit else -1
	if not deposit:
		for i in target.inventory.size():
			if target.inventory[i]!=null and target.inventory[i].item==food:index=i;break
	var response: Dictionary = kitchen.storage(s,target.id,"put" if deposit else "take",index)
	# Preserve the old public supplyAction result (including its missing n field).
	return "Transferiu undefined "+STORE.INV.ITEMS.data[food].name+"." if response.ok else response.error
