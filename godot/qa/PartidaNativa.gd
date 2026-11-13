extends SceneTree
func _initialize():
	var expected = load("res://qa/referencia-migracao/partidas.json").data
	var actual = preload("res://simulacao/nativa/Partida.gd").templates()
	actual=JSON.parse_string(JSON.stringify(actual))
	var failures := 0
	for key in expected:
		for mode in ["empty","furnished"]:
			for field in expected[key][mode]:
				if expected[key][mode][field] != actual[key][mode].get(field):
					push_error(key+" "+mode+" "+field+" esperado="+JSON.stringify(expected[key][mode][field])+" atual="+JSON.stringify(actual[key][mode].get(field)))
					failures += 1
	var first = preload("res://simulacao/nativa/Partida.gd").fresh()
	first.player.x=99
	assert(preload("res://simulacao/nativa/Partida.gd").fresh().player.x==7)
	print("FALHAS: ",failures)
	quit(1 if failures else 0)
