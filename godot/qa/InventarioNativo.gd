extends SceneTree
const INVENTORY = preload("res://simulacao/nativa/Inventario.gd")
func _initialize():
	var failures := 0
	var tests = load("res://qa/referencia-migracao/inventarios.json").data
	for test in tests:
		var slots: Array = [null,null]
		var ok := INVENTORY.add(slots,test.item,test.n,test.quality)
		if ok!=test.ok or JSON.parse_string(JSON.stringify(slots))!=test.inventory:failures+=1
	var slots: Array = [{"item":"arroz","n":2}]
	if INVENTORY.remove(slots,0,3) or slots[0].n!=2:failures+=1
	if not INVENTORY.remove(slots,0,2) or slots[0]!=null:failures+=1
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
