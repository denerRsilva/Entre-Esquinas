extends "res://qa/BaseNativa.gd"
func current_text(value: Dictionary) -> Dictionary:
	var encoded := JSON.stringify(value)
	encoded=encoded.replace("Horários atualizados. Abra o serviço pela plaquinha durante o período escolhido.","Horários atualizados. O restaurante abre automaticamente no horário escolhido.")
	encoded=encoded.replace("Restaurante fechado. O turno acompanha o relógio; reabra pela plaquinha enquanto estiver no horário.","Restaurante fechado. O próximo turno abre automaticamente no horário marcado.")
	return JSON.parse_string(encoded)
func run():
	var rules = preload("res://simulacao/nativa/Regras.gd").new()
	var tests = load("res://qa/referencia-migracao/administracao.json").data
	for test in tests:
		var actual = JSON.parse_string(rules.execute(JSON.stringify({"name":"administracao","args":[test.operation,test.input,test.params]},"",true,true)))
		check(equivalent(actual,current_text(test.expected)),test.operation)
	for test in load("res://qa/referencia-migracao/administracao-dias.json").data:
		var state: Dictionary = test.input.duplicate(true);var simulation = preload("res://simulacao/nativa/Simulacao.gd").new();simulation.service.random_source=func():return 0.5
		simulation.service.idle_walk_enabled=false;simulation.service.timed_orders_enabled=false
		simulation.step(state,test.dt);check(equivalent(state,current_text(test.expected)),"Dois dias completos")
	print("CASOS: ",tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
