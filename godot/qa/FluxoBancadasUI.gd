extends "res://qa/FluxoCompletoNativoUI.gd"
func start_game() -> void:
	await super.start_game()
	for object in g.session.state.objects:
		if object.type in ["prep","kitchen"]:
			object.baseType="counterH"
			object.tableKit="cuttingKit" if object.type=="prep" else "platingKit"
	g.tick(0)
