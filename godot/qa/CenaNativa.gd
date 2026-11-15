extends "res://qa/BaseNativa.gd"
func run():
	var tests = load("res://qa/referencia-migracao/cenas.json").data
	for test in tests:
		# Historical snapshots retain their pre-cleanup labels explicitly.
		# Current/default rendering is covered by InterfaceLimpaUI.
		var legacy_ui: Dictionary = test.ui.duplicate(true)
		legacy_ui.cleanView=false
		var actual = preload("res://simulacao/nativa/Cena.gd").new().draw(test.state.duplicate(true),legacy_ui)
		# Migration snapshots precede the purchased UI atlas. Compare the old
		# progress geometry/value here; BarrasAnimadasUI checks the new renderer.
		var legacy := []
		for command in actual:
			# The held plate sprite replaces the old two rectangles; compare
			# their placement against historical snapshots without retaining old art.
			if command[0]=="img" and command[1]=="modular/prato-vazio.png":
				var x: float = command[6]+10;var y: float = command[7]+6
				legacy.append(["rect",x-7,y-3,14,6,"#e4d5aa",command[10]])
				legacy.append(["rect",x-5,y-5,10,10,"#fff4d5",command[10]])
				continue
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
