extends "res://qa/FluxoCompletoNativoUI.gd"
func start_game(waiter_active: bool = false) -> void:
	await super.start_game(waiter_active)
	for object in g.session.state.objects:
		if object.type=="prep":
			object.baseType="counterH"
			object.tableKit="cuttingKit" if object.type=="prep" else "platingKit"
	g.tick(0)
