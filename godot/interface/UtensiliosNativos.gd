extends RefCounted
var controls = preload("res://interface/InventariosNativos.gd").new()
func render(state: Dictionary) -> Dictionary:
	controls.actions.clear()
	var cards: Array = []
	for item in [["pot","Panela vazia",25,0],["plate","Prato limpo",5,320]]:
		var held: bool = state.player.get("hand")!=null
		var amount := 1 if held and state.player.hand.item==item[0] else 0
		cards.append({"tag":"div","cls":"card","children":[
			{"tag":"b","children":[controls.text(item[1])]},
			controls.label("$%.2f • nas mãos: %d"%[item[2],amount]),
			controls.button("Comprar","nativo:utensilio:"+item[0],{"item":item[0]},state.cash<item[2] or held or state.player.get("carry")!=null),
			{"tag":"canvas","cls":"furnitureSprite toolSprite","label":item[1],"art":[["img","esquina-tools.png",item[3],0,160,112,0,0,160,112,1]]}]})
	return {"tag":"div","id":"panel","children":[controls.label("Disponível: $%.2f • A compra vai diretamente para as mãos."%state.cash),{"tag":"div","cls":"cards","children":cards}]}
