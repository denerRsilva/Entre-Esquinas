extends "res://qa/BaseInterfaceNativa.gd"
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const COOK = preload("res://simulacao/nativa/Cozinha.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
const SAVE = preload("res://simulacao/nativa/Salvamentos.gd")
const SCENE = preload("res://simulacao/nativa/Cena.gd")
const DISHES = preload("res://simulacao/nativa/Louca.gd")
func object(s: Dictionary,type: String):
	for o in s.objects:
		if o.type==type:return o
	return null
func beside(s: Dictionary,a: Dictionary,o: Dictionary):
	var p = SIM.MOVE.closest(s,a,o)
	check(p!=null,"Pia acessível")
	if p!=null:a.merge({"x":p.x,"y":p.y,"goal":null,"motion":null,"settled":null},true)
func bar() -> Array:
	for op in g.frame_data.scene:
		if op[0]=="progress" and str(op[1]).contains(":wash:"):return op
	return []
func snapshot(s: Dictionary,name: String):
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	g.session.state=s;g.session.selected=object(s,"sink").id;g.tick(0);await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/esquinas-pia-"+name+".png")
func run():
	await start_game()
	var s: Dictionary = g.session.state
	var sink = object(s,"sink")
	sink.dirtyPlates=10;s.equipment.plate+=10
	await click_object("sink")
	check(s.get("washing")!=null and s.player.get("hand")==null and sink.dirtyPlates==10 and sink.get("cleanPlates",0)==0,"Clique inicia tarefa, sem lavar instantaneamente nem levar limpos para a mão")
	g.tick(1.0)
	var first := bar()
	check(not first.is_empty() and is_equal_approx(first[6],0.5) and first[7]=="blue","Mesmo estilo de barra mostra metade do primeiro prato")
	check(sink.dirtyPlates==10 and sink.get("cleanPlates",0)==0,"Prato continua na pilha suja antes de completar o ciclo")
	advance(1.0)
	var second := bar()
	check(sink.dirtyPlates==9 and sink.cleanPlates==1 and s.washing.plate==1,"Primeiro ciclo transfere exatamente um prato da esquerda para a direita")
	check(not second.is_empty() and second[1]!=first[1] and is_zero_approx(second[6]),"Cada prato reinicia sua própria barra sem herdar preenchimento anterior")
	advance(8.0);g.tick(0)
	check(sink.dirtyPlates==5 and sink.cleanPlates==5,"Cinco ciclos produzem duas pilhas de cinco")
	advance(0.3)
	var left: float = s.washing.left
	var serialized: Variant = SAVE.serialize(s)
	var loaded: Variant = SAVE.new().load_value(JSON.parse_string(serialized)) if serialized is String else null
	check(loaded!=null and is_equal_approx(loaded.washing.left,left),"Save/load preserva o progresso do prato atual")
	if loaded!=null:
		var resumed := COOK.new();resumed.wash_step(loaded,2)
		check(object(loaded,"sink").cleanPlates==6 and object(loaded,"sink").dirtyPlates==4 and SAVE.VALIDATOR.valid(loaded),"Retomar save completa uma vez, sem duplicar ou perder louça")
	await snapshot(s,"metade")
	var kitchen := COOK.new()
	check(kitchen.wash(s,sink.id).ok and is_equal_approx(s.washing.left,left),"Clicar novamente não reinicia o progresso")
	check(not SIM.BUILD.place(s,"sink",sink.x,sink.y,sink.rot,sink.id).ok,"Não move pia durante a tarefa")
	check(g.session.ADMIN.pending(s),"Lavagem em andamento conta como tarefa pendente")
	s.player.merge({"x":18,"y":11,"motion":null,"goal":null,"settled":null},true);g.tick(0.7)
	check(is_equal_approx(s.washing.left,left),"Afastar-se pausa a lavagem")
	beside(s,s.player,sink);kitchen.manual_moving=true;kitchen.wash_step(s,1)
	check(is_equal_approx(s.washing.left,left),"Andar pelo teclado também pausa o trabalho manual")
	kitchen.manual_moving=false;g.tick(20)
	check(s.get("washing")==null and sink.dirtyPlates==0 and sink.cleanPlates==10 and s.player.get("hand")==null,"Fila termina com dez limpos à direita, sem ultrapassar capacidade")
	await snapshot(s,"limpos")
	check(not SIM.BUILD.remove(s,sink.id).ok,"Reembolso não apaga a pilha de pratos limpos")
	sink.dirtyPlates=1;s.equipment.plate+=1
	check(not kitchen.wash(s,sink.id).ok and sink.dirtyPlates==1 and sink.cleanPlates==10,"Pilha limpa cheia impede consumir outro prato sujo")
	# Right-hand half of the actual sink picks up the clean pile, up to five.
	var area := SIM.MOVE.MAP.rect(sink)
	var point: Dictionary = g.session.CAMERA.screen_point((sink.x+area.size.x*0.75)*40,(sink.y+0.5)*40,g.session.rect,g.session.viewport,g.session.camera)
	g.events.append({"kind":"pointer","phase":"down","x":point.x,"y":point.y});g.events.append({"kind":"pointer","phase":"up","x":point.x,"y":point.y});g.tick(0)
	check(s.player.hand!=null and s.player.hand.item=="plate" and s.player.hand.n==5 and sink.cleanPlates==5,"Clique na direita retira até cinco pratos limpos")
	check(not kitchen.take_clean(s,sink.id).ok and sink.cleanPlates==5,"Não cria uma sexta unidade na mão")
	var station = object(s,"kitchen");beside(s,s.player,station)
	check(kitchen.physical(s,station.id,"installPlates").ok and s.player.get("hand")==null,"Pilha retirada pode reabastecer o empratamento")
	beside(s,s.player,sink);check(kitchen.wash(s,sink.id).ok,"Retirar limpos libera espaço para continuar lavando")
	kitchen.wash_step(s,1)
	check(kitchen.cancel_wash(s,sink.id).ok and sink.dirtyPlates==1 and sink.cleanPlates==5,"Cancelar pela metade preserva prato ainda sujo e todos os limpos")
	check(SAVE.VALIDATOR.valid(s),"Conservação após lavagem, retirada, instalação e cancelamento")
	# Two independent piles of ten in every rotation, with unchanged dish size.
	for rot in 4:
		var visual: Dictionary = sink.duplicate(true);visual.rot=rot;visual.dirtyPlates=10;visual.cleanPlates=10
		var renderer := SCENE.new();renderer.object(s,visual,false)
		var plates: Array = renderer.commands.filter(func(op):return op[0]=="img" and op[1]=="modular/prato-vazio.png")
		check(plates.size()==20,"Renderiza dez sujos e dez limpos, um sprite por prato")
		check(plates[0][6]<plates[10][6] and plates[9][7]<plates[0][7] and plates[19][7]<plates[10][7],"Sujos à esquerda, limpos à direita, camadas empilhadas")
		check(plates.all(func(op):return op[8]==20 and op[9]==12),"Rotação não altera tamanho dos pratos")
	var legacy: Dictionary = PARTIDA.furnished(true,true)
	object(legacy,"sink").dirtyPlates=20;legacy.equipment.plate+=20
	var migrated: Variant = SAVE.new().load_value(JSON.parse_string(JSON.stringify(legacy)))
	check(migrated!=null and object(migrated,"sink").dirtyPlates==10 and SIM.BUILD.STORE.INV.count(migrated.recovery,"dirtyPlate")==10,"Save antigo preserva dez excedentes na recuperação")
	if migrated!=null:check(SAVE.VALIDATOR.valid(migrated),"Migração mantém a contabilidade de todos os pratos")
	PARTIDA.add_object(legacy,"sink",20,12)
	migrated=SAVE.new().load_value(JSON.parse_string(JSON.stringify(legacy)))
	check(migrated!=null and migrated.objects.filter(func(o):return o.type=="sink").all(func(o):return o.dirtyPlates==10) and migrated.recovery.is_empty(),"Excesso antigo é redistribuído para outra pia livre")
	var limits: Dictionary = PARTIDA.furnished(true,true)
	var limits_sink = object(limits,"sink")
	limits_sink.dirtyPlates=8;limits.equipment.plate+=13
	var worker: Dictionary = limits.workers[0];DISHES.set_held(worker,5);beside(limits,worker,limits_sink)
	check(DISHES.deposit(limits,worker,limits_sink)==2 and limits_sink.dirtyPlates==10 and DISHES.held(worker)==3,"Garçom respeita dez sujos e mantém a sobra nas mãos")
	check(SAVE.VALIDATOR.valid(limits),"Depósito parcial do NPC conserva os pratos")
	var unattended: Dictionary = PARTIDA.furnished(true,true)
	object(unattended,"sink").dirtyPlates=10;unattended.equipment.plate+=10
	var sim := SIM.new();sim.service.random_source=func():return 0.5
	for i in 200:sim.step(unattended,0.05)
	check(object(unattended,"sink").dirtyPlates==10 and object(unattended,"sink").get("cleanPlates",0)==0,"Garçom continua só recolhendo; não lava automaticamente")
	for fields in [{"dirtyPlates":11},{"cleanPlates":11},{"cleanPlates":-1},{"dirtyPlates":1.5}]:
		var invalid: Dictionary = PARTIDA.furnished(true,true);object(invalid,"sink").merge(fields,true)
		check(not SAVE.VALIDATOR.valid(invalid),"Save rejeita capacidade ou quantidade inválida")
	var interrupted: Dictionary = PARTIDA.furnished(true,true)
	var interrupted_sink = object(interrupted,"sink")
	interrupted_sink.dirtyPlates=2;interrupted.equipment.plate+=2;beside(interrupted,interrupted.player,interrupted_sink)
	check(kitchen.wash(interrupted,interrupted_sink.id).ok,"Inicia lavagem para testar conflitos manuais")
	check(not g.session.ADMIN.buy_tool(interrupted,"plate") and not kitchen.collect_dirty(interrupted,object(interrupted,"table").id).ok,"Outra ação não ocupa mãos enquanto lava")
	for patch in [{"left":-1},{"left":3},{"total":0},{"sink":99999},{"plate":10},{"plate":0.5}]:
		var invalid: Dictionary = interrupted.duplicate(true);invalid.washing.merge(patch,true)
		check(SAVE.serialize(invalid)==null,"Save recusa tarefa de lavagem inválida")
	interrupted.player.hand={"item":"plate","n":1};interrupted.equipment.plate+=1
	check(SAVE.serialize(interrupted)==null,"Save não permite lavar com mãos ocupadas")
	var partial: Dictionary = PARTIDA.furnished(true,true)
	var partial_sink = object(partial,"sink")
	partial_sink.dirtyPlates=8;partial.equipment.plate+=13;partial.player.hand={"item":"dirtyPlate","n":5};beside(partial,partial.player,partial_sink)
	check(kitchen.wash(partial,partial_sink.id).ok and partial_sink.dirtyPlates==10 and partial.player.hand.n==3 and partial.get("washing")==null,"Depósito parcial preserva a sobra na mão e não inicia lavagem com mãos ocupadas")
	check(SAVE.VALIDATOR.valid(partial),"Pia cheia mantém a contabilidade da pilha parcial")
	await finish()
