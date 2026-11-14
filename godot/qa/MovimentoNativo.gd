extends "res://qa/BaseNativa.gd"
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
func run():
	var tests = load("res://qa/referencia-migracao/movimento.json").data
	for test in tests:
		var state: Dictionary = test.input.duplicate(true);var velocity: Variant = null
		for command in test.commands:
			if command.kind=="input":velocity=MOVE.input(state.player,velocity,command.x,command.y)
			elif command.kind=="go":
				for actor in MOVE.ACTORS.actors(state):
					if actor.id==command.id:MOVE.go(actor,command.target);break
				if command.id=="player":velocity=null
			else:MOVE.move(state,command.dt,velocity)
		var actual := {"player":state.player,"workers":state.workers,"residents":state.residents,"customers":state.customers,"flowWaits":state.flowWaits}
		check(equivalent(actual,test.expected),test.label);check(equivalent(velocity,test.velocity),"Entrada transitória")
	print("CASOS: ",tests.size()," FALHAS: ",failures);quit(1 if failures else 0)
