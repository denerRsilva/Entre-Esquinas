extends SceneTree
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
func _initialize():
	var failures := 0
	var tests = load("res://qa/referencia-migracao/alimentos.json").data
	for test in tests:
		var actual = JSON.parse_string(JSON.stringify(FOOD.image_command(test.command)))
		if actual!=test.expected:
			failures+=1
			push_error(JSON.stringify(test.command))
	for key in FOOD.KEYS:
		if FOOD.texture(key)==null:failures+=1
	if FOOD.texture("dish_sopa")!=FOOD.texture("sopa"):failures+=1
	if FOOD.texture("invalid")!=null:failures+=1
	print("CASOS: ",tests.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
