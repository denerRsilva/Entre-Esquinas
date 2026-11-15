extends "res://qa/BaseNativa.gd"
func run():
	var tests = load("res://qa/referencia-migracao/cenas.json").data
	for test in tests:
		var actual = preload("res://simulacao/nativa/Cena.gd").new().draw(test.state.duplicate(true),test.ui)
		# Migration snapshots precede the purchased UI atlas. Compare the old
		# progress geometry/value here; BarrasAnimadasUI checks the new renderer.
		var legacy := []
		for command in actual:
			if command[0]!="progress":legacy.append(command);continue
			if str(command[1]).begins_with("patience:"):continue
			var heat: bool = str(command[1]).begins_with("heat:")
			var height := 5 if heat else 4
			var color: String = {"green":"#74b66b","yellow":"#e0a044","red":"#d75b3e"}.get(command[7],"#f3c56e") if heat else "#f3c56e"
			var pixel = preload("res://simulacao/nativa/Alimentos.gd")
			legacy.append(["rect",pixel.pixel(command[2]),pixel.pixel(command[3]),pixel.pixel(command[4]),height,"#315447",1.0])
			legacy.append(["rect",pixel.pixel(command[2]),pixel.pixel(command[3]),pixel.pixel(command[4]*command[6]),height,color,1.0])
		actual=legacy
		# Neighbor mask is new native rendering metadata, absent in migration snapshots.
		for command in actual:
			if command[0]=="furniture" and str(command[1]).begins_with("counter") and command.size()==9:command.pop_back()
		check(equivalent(actual,test.expected),"Composição visual nativa")
	print("CENAS: ",tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
