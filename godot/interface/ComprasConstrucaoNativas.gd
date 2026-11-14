extends RefCounted
const CATALOG = preload("res://simulacao/nativa/catalogo.json")
var controls = preload("res://interface/InventariosNativos.gd").new()
func render(state: Dictionary) -> Dictionary:
	controls.actions.clear()
	var cards: Array = []
	for id in CATALOG.data:
		if state.get("singleRoom",false) and id=="cold":continue
		var item: Dictionary = CATALOG.data[id]
		cards.append({"tag":"div","cls":"card","children":[
			{"tag":"canvas","art":[["furniture_icon",id]],"label":item.name},
			{"tag":"b","children":[controls.text(item.name)]},
			controls.label("$%.2f"%item.price),
			controls.button("Posicionar","nativo:comprar:"+id,{"type":id},state.open or state.cash<item.price)]})
	return {"tag":"div","id":"constructionPanel","children":[{"tag":"div","cls":"buildCards","children":cards}]}
func replace_panel(node: Dictionary,panel: Dictionary) -> void:
	var children: Array = node.get("children",[])
	for i in children.size():
		if children[i].get("id")=="constructionPanel":children[i]=panel
		else:replace_panel(children[i],panel)
