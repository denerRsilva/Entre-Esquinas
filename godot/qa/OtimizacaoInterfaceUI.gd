extends "res://qa/BaseInterfaceNativa.gd"
const BANCADA = preload("res://moveis/Bancada.gd")
func panel(values: Array) -> Dictionary:
	var rows := []
	for value in values:rows.append({"tag":"label","children":[{"tag":"text","text":"Cozinhando"},{"tag":"progress","max":10,"value":value,"label":"Cozinhando"}]})
	return {"tag":"div","children":rows}
func run():
	await start_game()
	var packet: Dictionary = g.session.step(0,[])
	packet.ui.kitchenStatus=panel([1,2]);g.hud.sync(packet);await layout()
	var bars: Array = g.hud.kitchen_bars.duplicate()
	var ids := [bars[0].get_instance_id(),bars[1].get_instance_id()]
	for i in 60:
		packet.ui.kitchenStatus=panel([1+i*0.1,2+i*0.1]);g.hud.sync(packet)
	check(g.hud.kitchen_bars[0].get_instance_id()==ids[0] and g.hud.kitchen_bars[1].get_instance_id()==ids[1],"Progresso atualiza os mesmos controles, sem recriar nós")
	check(is_equal_approx(g.hud.kitchen_bars[0].value,6.9) and is_equal_approx(g.hud.kitchen_bars[1].value,7.9),"Duas barras recebem valores independentes")
	packet.ui.kitchenStatus=panel([]);g.hud.sync(packet)
	check(not g.hud.slots.kitchenStatus[0].visible,"Painel some ao concluir tarefas")
	packet.ui.kitchenStatus=panel([0]);g.hud.sync(packet);await layout()
	check(g.hud.kitchen_bars.size()==1 and g.hud.kitchen_bars[0].value==0 and g.hud.slots.kitchenStatus[0].visible,"Nova tarefa reaparece sem progresso antigo")
	packet.ui.kitchenStatus.children[0].children[1].max=20;g.hud.sync(packet);await layout()
	check(g.hud.kitchen_bars[0].max_value==20,"Mudança de duração atualiza a escala")
	packet.ui.kitchenStatus={"tag":"div","children":[{"tag":"label","children":[{"tag":"text","text":"Queimado"}]}]};g.hud.sync(packet);await layout()
	check(g.hud.kitchen_bars.is_empty(),"Alerta sem progresso remove a barra antiga")
	for shape in 3:
		for rot in 4:
			var profile := BANCADA.perfil(shape,rot)
			var expected := profile.duplicate()
			profile.fill(0)
			check(BANCADA.perfil(shape,rot)==expected,"Cache não é alterado pelas conexões da bancada")
	var simulation = g.session.simulation
	for i in 20:g.session.step(0.02,[])
	check(g.session.simulation==simulation,"Sessão reaproveita seu controlador de simulação")
	await finish()
