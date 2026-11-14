extends "res://qa/BaseNativa.gd"
const SAVE = preload("res://simulacao/nativa/Salvamentos.gd")
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
func run():
	var service = SERVICE.new()
	var tests: Array = load("res://qa/referencia-migracao/atendimento-acoes.json").data
	var s: Dictionary = tests[80].input.duplicate(true)
	var c: Dictionary = s.customers[0]
	s.player.x=c.x-1;s.player.y=c.y;s.player.motion=null
	var waiter: Dictionary = s.workers.back()
	var order = service.find(s.orders,c.order)
	order.state="ready";waiter.carry={"kind":"dish","order":order.id,"quality":1}
	var hand: Dictionary = s.player.hand.duplicate(true)
	check(not service.interact(s,c.id),"Jogador não disputa pedido já transportado pelo garçom")
	check(equivalent(s.player.hand,hand) and order.state=="ready" and c.state=="ordered","Pratos e pedido preservados ao disputar entrega")
	waiter.x=c.x+1;waiter.y=c.y;waiter.room=c.room;waiter.motion=null
	check(service.serve(s,waiter,c) and waiter.carry==null and c.state=="eating","Garçom conclui a entrega reservada")
	check(not service.interact(s,c.id) and equivalent(s.player.hand,hand),"Segundo clique não consome outro prato")
	for value in [42,{},null,{"item":"inexistente","n":1}]:
		var broken := PARTIDA.furnished(true,true)
		broken.recovery=[value]
		check(SAVE.new().load_value(broken)==null,"Recuperação malformada rejeitada sem erro de script")
	var broken := PARTIDA.furnished(true,true)
	broken.inv.kitchen=null
	check(SAVE.new().load_value(broken)==null,"Estoque malformado rejeitado antes da migração")
	var furnished := PARTIDA.furnished(true,true)
	var chair: Variant = null
	for object in furnished.objects:
		if object.type=="chair":chair=object;break
	furnished.dirtyTables[str(int(chair.id))]=0
	check(SAVE.VALIDATOR.valid(furnished),"Cadeira com louça já recolhida começa válida")
	check(BUILD.remove(furnished,chair.id).ok,"Cadeira limpa pode ser removida")
	check(SAVE.serialize(furnished)!=null,"Remover cadeira após recolher louça mantém save válido")
	print("FALHAS: ",failures);quit(1 if failures else 0)
