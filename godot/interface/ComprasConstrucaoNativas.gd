extends RefCounted
const CATALOG = preload("res://simulacao/nativa/catalogo.json")
const SECTIONS = {"bancadas":"Bancadas","ferramentas":"Ferramentas","moveis":"Móveis","decoracoes":"Decorações","equipamentos":"Equipamentos"}
var category := "moveis"
var controls = preload("res://interface/InventariosNativos.gd").new()
static func category_of(type: String) -> String:
	return CATALOG.data.get(type,{}).get("category","equipamentos")
func render(state: Dictionary) -> Dictionary:
	controls.actions.clear()
	var navigation: Array = []
	for key in SECTIONS:
		navigation.append(controls.button(SECTIONS[key],"nativo:categoria:"+key,{"category":key},category==key,"constructionSectionButton"))
	var cards: Array = []
	var thin: Array = [];var wide: Array = []
	for id in CATALOG.data:
		if id in ["computer","receiving"] and state.get("refuge") is Dictionary:continue
		# Original generated counters remain loadable, but only edited art is sold.
		if id in ["prep","kitchen","counterH","counterV","counterCorner"]:continue
		if state.get("singleRoom",false) and id=="cold":continue
		if category_of(id)!=category:continue
		var item: Dictionary = CATALOG.data[id]
		var art := [["img","modular/prato-vazio.png",125,166,1249,736]] if id=="platingKit" else [["furniture_icon",id]]
		var card := {"tag":"div","cls":"card","children":[
			{"tag":"canvas","art":art,"label":item.name},
			{"tag":"b","children":[controls.text(item.name)]},controls.label("$%.2f"%item.price),
			controls.button("Posicionar","nativo:comprar:"+id,{"type":id},state.open or state.cash<item.price)]}
		if category=="bancadas":
			if item.counterFamily=="thin":thin.append(card)
			else:wide.append(card)
		else:cards.append(card)
	var children: Array = [{"tag":"nav","cls":"constructionSections","children":navigation},{"tag":"b","children":[controls.text(SECTIONS[category])]}]
	if category=="bancadas":
		children.append({"tag":"b","children":[controls.text("Bancada fina")]})
		children.append({"tag":"div","cls":"buildCards","children":thin})
		children.append({"tag":"b","children":[controls.text("Bancada grossa")]})
		children.append({"tag":"div","cls":"buildCards","children":wide})
	else:children.append({"tag":"div","cls":"buildCards","children":cards})
	return {"tag":"div","id":"constructionPanel","children":children}
func replace_panel(node: Dictionary,panel: Dictionary) -> void:
	var children: Array = node.get("children",[])
	for i in children.size():
		if children[i].get("id")=="constructionPanel":children[i]=panel
		else:replace_panel(children[i],panel)
