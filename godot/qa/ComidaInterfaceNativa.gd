extends "res://qa/BaseNativa.gd"
func run():
	var tests = load("res://qa/referencia-migracao/comida-interface.json").data
	var view = preload("res://interface/ComidaInterface.gd").new()
	for test in tests.parts:check(equivalent(view.parts(test.text),test.expected),test.text)
	for test in tests.icons:check(equivalent(view.icon(test.item,test.quality),test.expected),test.item+" "+str(test.quality))
	print("CASOS: ",tests.parts.size()+tests.icons.size()," FALHAS: ",failures);quit(1 if failures else 0)
