extends "res://qa/UIBase.gd"
func compare_section(id: String):
	var reference = JSON.parse_string(js("JSON.stringify(section('"+id+"'))"))
	var native = g.session.section(id)
	# Normalize Godot int/float values through the save representation.
	native=JSON.parse_string(JSON.stringify(native))
	check(native==reference,"Menu nativo equivalente: "+id)
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	await layout()
	js(FileAccess.get_file_as_string("res://qa/referencia-migracao/menus-legado.txt"))
	compare_section("welcome")
	await button("Começar na taverna")
	for command in ["openDialog('general')","openDialog('options')","openDialog('recipes')","$('management').close();enterConstruction()"]:
		js(command);g.tick(0);await layout()
		compare_section("constructionDrawer" if js("constructionMode")=="true" else "management")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
