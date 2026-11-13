extends SceneTree
const MAP = preload("res://simulacao/nativa/Mapa.gd")
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
func _initialize():
	var failures := 0
	var count := 0
	for fixture in load("res://qa/referencia-migracao/mapas.json").data:
		var state = PARTIDA.furnished(fixture.compact,fixture.single)
		for cell in fixture.cells:
			count += 1
			if MAP.wall(cell[0],cell[1],cell[2],state)!=cell[3] or MAP.fixed(cell[0],cell[1],cell[2],state)!=cell[4] or MAP.blocked(state,cell[0],Vector2i(cell[1],cell[2]))!=cell[5]:failures+=1
		var path = MAP.route(state,"restaurant",Vector2i(7,13),Vector2i(7,14))
		if path==null or path.size()!=1:failures+=1
		if MAP.route(state,"restaurant",Vector2i(7,13),Vector2i(0,0))!=null:failures+=1
	print("CÉLULAS: ",count," FALHAS: ",failures)
	quit(1 if failures else 0)
