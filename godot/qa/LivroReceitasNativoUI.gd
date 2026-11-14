extends "res://qa/UIBase.gd"
func find_id(node: Dictionary,id: String) -> Variant:
	if node.get("id")==id:return node
	for child in node.get("children",[]):
		var result = find_id(child,id)
		if result!=null:return result
	return null
func run():
	root.size=Vector2i(960,700)
	g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	await layout()
	check(await button("Começar na taverna"),"Início mobiliado")
	js("openDialog('recipes')");g.tick(0);await layout()
	check(js("$('panel').children.length")=="0","Livro sem conteúdo DOM legado")
	var panel = find_id(g.frame_data.ui.modal,"panel")
	check(panel!=null and panel.children.size()==1 and panel.children[0].children.size()==3,"Três páginas nativas")
	if panel!=null:
		for page in panel.children[0].children:
			var hero: Dictionary = page.children[0]
			check(hero.cls=="recipeHero" and hero.art[0][0]=="food" and preload("res://simulacao/nativa/Alimentos.gd").texture(hero.art[0][1])!=null,"Arte da comida pronta: "+hero.label)
			check(page.children[3].cls=="recipeIngredients" and page.children[4].children.size()==3,"Ingredientes visuais e três passos")
	check(await button("Voltar ao jogo"),"Fechar livro e voltar ao jogo")
	print("FALHAS: ",failures)
	g.queue_free();await process_frame;quit(1 if failures else 0)
