extends RefCounted
const ITEMS = preload("res://simulacao/nativa/itens.json")

static func limit(item: String) -> int:
	return int(ITEMS.data.get(item,{}).get("limit",99))

static func count(slots: Array, item: String) -> int:
	var total := 0
	for slot in slots:
		if slot!=null and slot.item==item:total+=int(slot.n)
	return total

static func space(slots: Array, item: String, quality: int = 0) -> int:
	var total := 0
	for slot in slots:
		if slot==null:total+=limit(item)
		elif slot.item==item and slot.get("quality",0)==quality:total+=limit(item)-int(slot.n)
	return total

static func add(slots: Array, item: String, quantity: int, quality: int = 0, burned: bool = false) -> bool:
	if not ITEMS.data.has(item) or quantity<1 or space(slots,item,quality)<quantity:return false
	var left := quantity
	for slot in slots:
		if left==0:break
		if slot!=null and slot.item==item and slot.get("quality",0)==quality and not slot.get("burned",false) and not burned:
			var amount := mini(left,limit(item)-int(slot.n))
			slot.n+=amount
			left-=amount
	for index in slots.size():
		if left==0:break
		if slots[index]==null:
			var amount := mini(left,limit(item))
			slots[index]={"item":item,"n":amount}
			if quality:slots[index].quality=quality
			if burned:slots[index].burned=true
			left-=amount
	return true

static func remove(slots: Array, index: int, quantity: int) -> bool:
	if index<0 or index>=slots.size():return false
	var slot = slots[index]
	if slot==null or quantity<1 or quantity>slot.n:return false
	slot.n-=quantity
	if slot.n==0:slots[index]=null
	return true
