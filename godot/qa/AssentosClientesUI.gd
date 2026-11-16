extends "res://qa/BaseNativa.gd"
const PARTIDA = preload("res://simulacao/nativa/Partida.gd")
const SIM = preload("res://simulacao/nativa/Simulacao.gd")
const SAVE = preload("res://simulacao/nativa/Salvamentos.gd")
func simulation(draws: Array = []):
	var sim = SIM.new()
	var queue := draws.duplicate()
	sim.service.random_source=func():return queue.pop_front() if not queue.is_empty() else 0.5
	sim.service.idle_walk_enabled=false
	return sim
func seated(s: Dictionary,sim) -> Dictionary:
	var c: Dictionary = s.customers.back()
	var chair = sim.BUILD.find(s.objects,c.seat)
	c.merge({"x":chair.x,"y":chair.y,"motion":null,"goal":null,"state":"waiting"},true)
	sim.service.begin(s,c,"service")
	return c
func dirty(s: Dictionary,chair: Dictionary) -> void:
	s.dirtyTables[str(int(chair.id))]=1;s.equipment.plate+=1
func restored(s: Dictionary) -> Variant:
	var raw: Variant = SAVE.serialize(s)
	return SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
func run():
	var baseline := PARTIDA.furnished(true,true)
	baseline.workers[0].task="none" # Inspect dirty-seat reactions without automatic cleaning.
	var closed_day: Dictionary = baseline.duplicate(true)
	closed_day.clock.ending=true
	check(not simulation().spawn(closed_day),"Fim do dia não recebe cliente")
	var no_menu: Dictionary = baseline.duplicate(true)
	for recipe in no_menu.menu:no_menu.menu[recipe]=false
	check(not simulation().spawn(no_menu) and no_menu.ledger.lost==1,"Sem cardápio não cria cliente")
	var no_seats: Dictionary = baseline.duplicate(true)
	no_seats.objects=no_seats.objects.filter(func(o):return o.type!="chair")
	check(not simulation().spawn(no_seats),"Sem cadeira válida não cria cliente")
	var available: Array = SIM.BUILD.seats(baseline)
	var chosen := {}
	for i in available.size():
		var s: Dictionary = baseline.duplicate(true)
		var sim = simulation([(i+0.5)/available.size()])
		check(sim.spawn(s),"Chegada pode sortear uma cadeira válida")
		chosen[s.customers[0].seat]=true
	check(chosen.size()==available.size() and chosen.size()>3,"Sorteio alcança todas as cadeiras, não só a primeira de cada mesa")
	# All chairs, including several at one table, can be reserved independently.
	var crowded: Dictionary = baseline.duplicate(true)
	var crowded_sim = simulation([0])
	var occupied := {}
	for i in available.size():
		check(crowded_sim.spawn(crowded),"Cadeira livre aceita cliente mesmo com outro na mesma mesa")
		var c := seated(crowded,crowded_sim)
		check(not occupied.has(c.seat),"Clientes em trânsito ou sentados não compartilham cadeira")
		occupied[c.seat]=true
	check(not crowded_sim.spawn(crowded),"Lotação não cria cliente sobre outro")
	check(SAVE.VALIDATOR.valid(crowded),"Salão lotado mantém reservas e salvamento válidos")
	# Reserve a chair while the first customer is still walking to it.
	var walking: Dictionary = baseline.duplicate(true)
	var walking_sim = simulation([0,0.5,0.5,0.5,0])
	check(walking_sim.spawn(walking),"Primeiro cliente escolhe cadeira")
	var first: Dictionary = walking.customers[0]
	first.x=8;first.y=13
	check(walking_sim.spawn(walking) and walking.customers[1].seat!=first.seat,"Reserva começa antes de chegar à cadeira")
	var live: Dictionary = baseline.duplicate(true)
	live.workers[0].task="none"
	var live_sim = simulation([0,0.5,0.5,0.5,0])
	check(live_sim.spawn(live),"Primeiro cliente começa trajeto real")
	for i in 16:live_sim.step(live,0.05)
	check(live_sim.spawn(live),"Segundo cliente entra depois que a porta fica livre")
	for i in 240:live_sim.step(live,0.05)
	check(live.customers.size()==2 and live.customers[0].state=="waiting" and live.customers[1].state=="waiting","Dois clientes chegam às cadeiras usando navegação real")
	if live.customers.size()==2:
		var a = SIM.BUILD.find(live.objects,live.customers[0].seat)
		var b = SIM.BUILD.find(live.objects,live.customers[1].seat)
		check(a.id!=b.id and SIM.BUILD.chair_table(a,live.objects).id==SIM.BUILD.chair_table(b,live.objects).id,"Clientes compartilham mesa mantendo assentos separados")
	check(SAVE.VALIDATOR.valid(live),"Trânsito e chegada preservam posições e reservas válidas")
	# A blocked entrance must not create records, consume IDs, or penalize hygiene.
	var blocked: Dictionary = baseline.duplicate(true)
	blocked.player.x=7;blocked.player.y=13
	var serial: int = blocked.serial
	check(not simulation().spawn(blocked) and blocked.serial==serial and blocked.ledger.lost==0 and blocked.experience.visits.is_empty(),"Entrada ocupada não gera visita fantasma")
	# Dirty first choice -> stay, selecting another clean chair at the same table.
	var unhappy: Dictionary = baseline.duplicate(true)
	var dirty_chair = SIM.BUILD.find(unhappy.objects,available[0])
	dirty(unhappy,dirty_chair)
	var unhappy_sim = simulation([0,0,0])
	check(unhappy_sim.spawn(unhappy),"Cliente pode decidir ficar após encontrar louça")
	var guest := seated(unhappy,unhappy_sim)
	var alternate = SIM.BUILD.find(unhappy.objects,guest.seat)
	check(guest.seat!=dirty_chair.id and SIM.BUILD.chair_table(alternate,unhappy.objects).id==SIM.BUILD.chair_table(dirty_chair,unhappy.objects).id,"Troca usa outra cadeira limpa da mesma mesa")
	check(is_equal_approx(unhappy_sim.service.ratio(guest.experience),0.2) and guest.experience.arrivalIssue=="dirtySeat","Troca começa insatisfeita, com 20% da paciência")
	check(unhappy.orders.is_empty() and unhappy.ledger.lost==0,"Troca não inventa pedido nem contabiliza abandono")
	var loaded: Variant = restored(unhappy)
	check(loaded!=null and is_equal_approx(loaded.customers[0].experience.elapsed.service,guest.experience.elapsed.service),"Save/load preserva primeira impressão e paciência reduzida")
	if loaded!=null:
		loaded.customers[0].experience.arrivalIssue="invalid"
		check(not SAVE.VALIDATOR.valid(loaded),"Save rejeita motivo de insatisfação desconhecido")
	# The negative first impression contributes to the final service rating.
	var impression: Dictionary = guest.experience.duplicate(true)
	unhappy_sim.service.finish(guest);impression.results.service=guest.experience.results.service
	impression.results.food=1;impression.servedQuality=0
	check(unhappy_sim.service.satisfaction(impression).score<65,"Atendimento imediato não apaga a insatisfação inicial da avaliação")
	# Same choice -> leave. A visible visitor walks straight back to the exit.
	var rejected: Dictionary = baseline.duplicate(true)
	dirty(rejected,SIM.BUILD.find(rejected.objects,available[0]))
	var rejected_sim = simulation([0,0.99])
	check(rejected_sim.spawn(rejected),"Cliente entra e decide ir embora")
	var leaving: Dictionary = rejected.customers[0]
	check(leaving.state=="leave" and leaving.goal.y==14 and leaving.order==null,"Cliente insatisfeito volta à saída sem pedido")
	check(leaving.experience.satisfaction.score==0 and rejected.experience.visits.size()==1 and rejected.ledger.lost==1,"Abandono tem satisfação zero e uma única visita perdida")
	check(rejected.reputation.history.size()==1 and rejected.reputation.history[0].type=="abandonment","Abandono por higiene afeta a reputação")
	check(restored(rejected)!=null,"Saída insatisfeita pode ser salva e carregada")
	check(not rejected_sim.service.reject_dirty(rejected,leaving,"dirtySeat") and rejected.ledger.lost==1,"Reação não registra duas vezes o mesmo abandono")
	for i in 20:rejected_sim.step(rejected,0.05)
	check(rejected.customers.is_empty() and rejected.ledger.lost==1 and rejected.experience.visits.size()==1,"Cliente sai de fato e não deixa reserva ou novo abandono")
	var full_dirty_table: Dictionary = baseline.duplicate(true)
	var first_table = SIM.BUILD.chair_table(SIM.BUILD.find(full_dirty_table.objects,available[0]),full_dirty_table.objects)
	for id in available:
		var chair = SIM.BUILD.find(full_dirty_table.objects,id)
		if SIM.BUILD.chair_table(chair,full_dirty_table.objects).id==first_table.id:dirty(full_dirty_table,chair)
	check(simulation([0,0]).spawn(full_dirty_table) and full_dirty_table.customers[0].state=="leave","Sem alternativa limpa na mesa escolhida, cliente vai embora")
	var other_table_sim = simulation([0.99])
	var other_choice: Dictionary = other_table_sim.choose_seat(full_dirty_table)
	check(not other_choice.get("reject",false) and not other_choice.get("unhappy",false),"Escolher outra mesa limpa não herda insatisfação de uma mesa suja")
	# One dirty plate per table is enough for the explicitly requested global rule.
	var filthy: Dictionary = baseline.duplicate(true)
	var table_ids := {}
	for id in available:
		var chair = SIM.BUILD.find(filthy.objects,id)
		var table = SIM.BUILD.chair_table(chair,filthy.objects)
		if not table_ids.has(table.id):dirty(filthy,chair);table_ids[table.id]=true
	var filthy_sim = simulation()
	check(filthy_sim.spawn(filthy) and filthy.customers[0].state=="leave","Todas as mesas com louça forçam saída, mesmo havendo cadeiras limpas")
	check(filthy.experience.visits[0].arrivalIssue=="dirtyDiningRoom" and filthy.experience.visits[0].satisfaction.score==0,"Salão sujo registra motivo e insatisfação total")
	check(restored(filthy)!=null,"Estado com todas as mesas sujas continua válido")
	for i in 20:filthy_sim.step(filthy,0.05)
	check(filthy_sim.spawn(filthy) and filthy.ledger.lost==2,"Novos clientes continuam chegando e saindo em vez de desaparecer")
	# Clean one table: the rejection is no longer unconditional.
	for i in 20:filthy_sim.step(filthy,0.05)
	var clean_table_id: int = table_ids.keys()[0]
	var clean_seat := -1
	for id in available:
		var chair = SIM.BUILD.find(filthy.objects,id)
		if SIM.BUILD.chair_table(chair,filthy.objects).id!=clean_table_id:continue
		if clean_seat<0:clean_seat=available.find(id)
	var table = SIM.BUILD.find(filthy.objects,clean_table_id)
	var home := Vector2i(filthy.player.x,filthy.player.y)
	var access = SIM.MOVE.closest(filthy,filthy.player,table)
	check(access!=null,"Jogador pode alcançar mesa suja")
	if access!=null:
		filthy.player.merge({"x":access.x,"y":access.y,"motion":null,"goal":null,"settled":null},true)
		check(filthy_sim.kitchen.collect_dirty(filthy,clean_table_id).ok and filthy.player.hand.item=="dirtyPlate","Interação real de limpeza recolhe a louça e libera a mesa")
		filthy.player.x=home.x;filthy.player.y=home.y
	filthy_sim.service.random_source=func():return (clean_seat+0.5)/available.size()
	check(filthy_sim.spawn(filthy) and filthy.customers.back().state=="walk","Limpar mesa permite voltar a receber clientes normalmente")
	check(filthy.ledger.lost==2 and SAVE.VALIDATOR.valid(filthy),"Limpeza não altera abandonos anteriores nem conserva louça incorretamente")
	print("CADEIRAS: ",available.size()," FALHAS: ",failures)
	quit(1 if failures else 0)
