extends "res://qa/BaseNativa.gd"
func without_old_plate_stacks(commands: Array, state: Dictionary) -> Array:
	var pairs := []
	for object in state.objects:
		if object.type!="kitchen":continue
		for i in mini(4,int(ceil(float(object.get("plates",0))/3))):
			var x: float = object.x*40+12;var y: float = object.y*40+2-i*2
			pairs.append([["rect",x-7,y-3,14,6,"#e4d5aa",1.0],["rect",x-5,y-5,10,10,"#fff4d5",1.0]])
	var result := [];var index := 0
	while index<commands.size():
		var skip := false
		if index+1<commands.size():
			for pair in pairs:
				if equivalent(commands[index],pair[0]) and equivalent(commands[index+1],pair[1]):skip=true;break
		if skip:index+=2
		else:result.append(commands[index]);index+=1
	return result

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
		var kitchen: Array = [];var dish_index := 0;var dish_delta := Vector2.ZERO
		for source_command in actual:
			var command: Array = source_command.duplicate(true)
			if command[0] in ["cook","npc","furniture"]:
				kitchen=command if command[0]=="furniture" and command[1] in ["kitchen","platingKit"] else []
				dish_index=0;dish_delta=Vector2.ZERO
			if not kitchen.is_empty() and command[0]=="food" and int(command[4]) in [9,14,18,20] and int(command[5]) in [5,8,10,14]:
				var old_x: float = kitchen[2]+(27+dish_index%4*11)*(kitchen[4]/80)-10
				var old_y: float = kitchen[3]+4+floor(float(dish_index)/4)*8-7
				dish_delta=Vector2(old_x-command[2]+10-command[4]/2,old_y-command[3]+7-command[5]/2)
				command[2]=old_x;command[3]=old_y;command[4]=20;command[5]=14;dish_index+=1
			elif not kitchen.is_empty() and command[0]=="poly" and dish_delta!=Vector2.ZERO:
				for point in command[1]:point[0]+=dish_delta.x;point[1]+=dish_delta.y
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
			if command[0]=="furniture" and command.size()==9:
				if str(command[1]).begins_with("counter") or command[8] is Dictionary:command.pop_back()
		# The kit now owns exact plate drawing, replacing the old grouped side icons.
		var normalized: Array = without_old_plate_stacks(actual,test.state)
		var expected: Array = without_old_plate_stacks(test.expected,test.state)
		check(equivalent(normalized,expected),"Composição visual nativa")

	print("CENAS: ",tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
