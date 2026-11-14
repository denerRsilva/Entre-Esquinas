extends RefCounted
const CALENDAR = preload("res://simulacao/nativa/Calendario.gd")
const NUM = preload("res://simulacao/nativa/Conservacao.gd")
const ITEMS = preload("res://simulacao/nativa/itens.json")
const STATE = preload("res://simulacao/nativa/EstadoCozinha.gd")
static func hours(s: Dictionary) -> Array:return s.get("serviceHours",CALENDAR.hours())
static func pending(s: Dictionary) -> bool:
	if not s.customers.is_empty() or STATE.truthy(s.get("chopping")) or STATE.truthy(s.get("cooking")) or STATE.truthy(s.get("plating")) or not s.ready.is_empty():return true
	for order in s.orders:
		if order.state not in ["paid","lost"]:return true
	for actor in NUM.actors(s):
		var carry = actor.get("carry")
		if carry==null or carry.kind!="dish":continue
		var canceled := false
		for order in s.orders:
			if order.id==carry.order and order.state=="lost":canceled=true
		if not canceled:return true
	return false
static func sync(s: Dictionary) -> void:
	var times := hours(s)
	var now: float = s.clock.minute
	if s.open and not s.closing and now>=times[int(s.period)].end:s.closing=true;s.message="Horário encerrado. Novas entradas suspensas; conclua os clientes presentes."
	if not s.open and not s.closing:s.period=1 if now>=times[0].end else 0
static func open_error(s: Dictionary) -> String:
	var h: Dictionary = hours(s)[int(s.period)]
	if s.clock.minute<h.start:return "Este turno começa às "+CALENDAR.time_text(h.start)+"."
	if s.clock.minute>=h.end:return "O horário deste turno já terminou."
	return ""
static func set_hours(s: Dictionary,value: Variant) -> Dictionary:
	if s.open or s.closing or pending(s):return {"ok":false,"message":"Conclua o serviço antes de alterar os horários."}
	if not CALENDAR.valid_hours(value):return {"ok":false,"message":"Use horários entre 06:00 e 02:00, em intervalos de 10 minutos. O almoço deve terminar antes do jantar começar."}
	s.serviceHours=value.duplicate(true);sync(s)
	return {"ok":true,"message":"Horários atualizados. Abra o serviço pela plaquinha durante o período escolhido."}
static func finish_period(s: Dictionary) -> void:
	s.open=false;s.closing=false;s.cookActive=false;sync(s)
	s.message="Restaurante fechado. O turno acompanha o relógio; reabra pela plaquinha enquanto estiver no horário."
static func toggle(s: Dictionary) -> bool:
	if s.clock.ending:s.message="Conclua o serviço pendente das 02:00 antes de reabrir.";return false
	if s.closing:return false
	if not s.open:
		sync(s)
		var error := open_error(s)
		if not error.is_empty():s.message=error;return false
	if s.open:s.closing=true;s.message="Entrada encerrada. Conclua os pedidos e deixe os clientes saírem.";return true
	s.open=true;s.arrival=17
	s.message=("Almoço" if s.period==0 else "Jantar")+" aberto. Receba pedidos nas mesas, prepare e sirva."
	return true
static func advance_clock(s: Dictionary,dt: float) -> void:
	if s.clock.ending:return
	s.clock.remainder+=dt
	if s.clock.remainder+1e-9<7:return
	s.clock.remainder=maxf(0,s.clock.remainder-7)
	s.clock.minute=minf(1560,s.clock.minute+10)
	if s.clock.minute==1560:
		s.clock.ending=true;s.clock.remainder=0
		if s.open or pending(s):s.closing=true
		s.message="02:00: entrada encerrada. Conclua clientes e preparos para começar o próximo dia."
static func finish_day(s: Dictionary) -> bool:
	if not s.clock.ending or pending(s):return false
	var report: Dictionary = s.ledger.duplicate(true)
	report.merge({"day":s.day,"expense":12,"result":s.ledger.revenue-s.ledger.foodCost-12,"cash":s.cash-12},true)
	s.cash-=12;s.reports.append(report);s.lastReport=report
	s.ledger={"revenue":0,"foodCost":0,"purchases":0,"investment":0,"lost":0,"sales":0}
	preload("res://simulacao/nativa/HistoricoPedidos.gd").compact(s)
	s.day+=1;s.period=0;s.open=false;s.closing=false;s.clock={"minute":360,"remainder":0,"ending":false}
	s.message="Novo dia às 06:00. Relatório diário disponível na Gestão."
	return true
static func test_clock(s: Dictionary,minute: Variant) -> Dictionary:
	if not NUM.integer(minute) or minute<360 or minute>1560 or int(minute)%10:return {"ok":false,"message":"Escolha um horário entre 06:00 e 02:00, em intervalos de 10 minutos."}
	if s.clock.ending:return {"ok":false,"message":"Conclua o dia atual antes de avançar o horário."}
	if minute<s.clock.minute:return {"ok":false,"message":"Escolha um horário igual ou posterior ao atual. Esta ferramenta não volta o relógio."}
	if minute==s.clock.minute:return {"ok":true,"message":"O relógio já está em "+CALENDAR.time_text(s.clock.minute)+"."}
	var day = s.day
	s.clock.minute=minute;s.clock.remainder=0;s.clock.ending=minute==1560
	if s.clock.ending and (s.open or pending(s)):s.closing=true
	sync(s)
	if s.closing and not pending(s):finish_period(s)
	finish_day(s)
	return {"ok":true,"message":"Horário de teste avançado: novo dia às 06:00." if s.day!=day else "Horário de teste avançado para "+CALENDAR.time_text(s.clock.minute)+"."+(" Conclua os clientes e preparos pendentes." if s.closing else "")}
static func receive(s: Dictionary,food: String,amount: float,quality: int = 0) -> void:
	s.inv.receiving[food]+=amount
	if quality:
		if not s.has("receivingQuality"):s.receivingQuality={}
		if not s.receivingQuality.has(food):s.receivingQuality[food]=[0,0,0,0]
		s.receivingQuality[food][quality]+=amount
static func receiving_count(s: Dictionary,food: String,quality: int) -> float:
	var counts: Array = s.get("receivingQuality",{}).get(food,[0,0,0,0])
	return counts[quality] if quality else s.inv.receiving[food]-counts[1]-counts[2]-counts[3]
static func purchase(s: Dictionary,food: Variant,quantity: Variant,quality: Variant = 0) -> bool:
	if s.get("singleRoom",false):
		var found := false
		for object in s.objects:
			if object.type=="receiving":found=true
		if not found:return false
	if not NUM.integer(quality) or quality<0 or quality>3 or food not in ["arroz","legumes","frango"] or not NUM.integer(quantity) or quantity<1 or quantity>100:return false
	var cost: float = ITEMS.data[food].cost*quantity*[1,1.25,1.5,2][int(quality)]
	if s.cash<cost:return false
	s.cash-=cost;s.ledger.purchases+=cost;s.purchased[food]+=quantity
	s.deliveries.append({"id":s.serial,"food":food,"quality":quality,"total":quantity,"pending":quantity,"received":0,"eta":s.time+5});s.serial+=1
	return true
static func deliver(s: Dictionary) -> void:
	for delivery in s.deliveries:
		if s.time<delivery.eta:continue
		var amount := 0.0
		for value in s.inv.receiving.values():amount+=value
		var quantity := minf(delivery.pending,60-amount)
		receive(s,delivery.food,quantity,delivery.get("quality",0))
		delivery.pending-=quantity;delivery.received+=quantity
static func buy_tool(s: Dictionary,type: Variant) -> bool:
	if type not in ["pot","plate"] or STATE.truthy(s.player.get("hand")) or STATE.truthy(s.player.get("carry")) or STATE.truthy(s.get("chopping")) or STATE.truthy(s.get("plating")):return false
	var price := 25 if type=="pot" else 5
	if s.cash<price:return false
	s.player.hand={"item":type,"n":1};s.cash-=price;s.ledger.investment+=price;s.equipment[type]+=1
	if type!="plate":s.tools[type]=true
	return true
static func reputation(s: Dictionary,visit: Dictionary,event: Variant,registered: bool,event_registered: bool) -> bool:
	var type: Variant = "abandonment" if visit.outcome=="abandoned" else event.type if event!=null else null
	if event!=null and (not event_registered or event.visitId!=visit.id or (visit.outcome=="abandoned" and event.type=="praise")):return false
	if visit.id in s.reputation.processed or (type!=null and type not in ["praise","complaint","abandonment"]):return false
	if not registered:return false
	s.reputation.processed.append(visit.id)
	if type==null:return false
	var before: float = s.reputation.score
	var delta := 1 if type=="praise" else -1
	var after := clampf(before+delta,0,100)
	s.reputation.score=after
	s.reputation.history.append({"visitId":visit.id,"type":type,"manifestation":event.type if event!=null else null,"requestedDelta":delta,"delta":after-before,"before":before,"after":after,"day":s.day,"time":s.time})
	return true
static func numeric(value: Variant) -> bool:return (value is int or value is float) and is_finite(value)
static func valid_time_reputation(s: Dictionary) -> bool:
	if s.has("serviceHours") and not CALENDAR.valid_hours(s.serviceHours):return false
	var c = s.get("clock")
	var r = s.get("reputation")
	if not c is Dictionary or not NUM.integer(c.get("minute")):return false
	if c.minute<360 or c.minute>1560 or int(c.minute-360)%10:return false
	if not numeric(c.get("remainder")) or c.remainder<0 or c.remainder>=7:return false
	if not c.get("ending") is bool or c.ending!=(c.minute==1560) or (c.ending and c.remainder!=0):return false
	if not r is Dictionary or not numeric(r.get("score")) or r.score<0 or r.score>100 or not numeric(r.get("initial")) or r.initial<0 or r.initial>100:return false
	if not r.get("history") is Array or not r.get("processed") is Array:return false
	var processed := {}
	for id in r.processed:
		if processed.has(id):return false
		processed[id]=true
		var found := false
		for visit in s.experience.visits:
			if typeof(visit.id)==typeof(id) and visit.id==id:found=true;break
		if not found:return false
	var expected: float = r.initial
	var visited := {}
	for entry in r.history:
		var visit: Variant = null
		var manifest: Variant = null
		for candidate in s.experience.visits:
			if candidate.id==entry.get("visitId"):visit=candidate;break
		for candidate in s.experience.events:
			if candidate.visitId==entry.get("visitId"):manifest=candidate;break
		if not processed.has(entry.get("visitId")) or visit==null or visited.has(entry.visitId) or entry.get("type") not in ["praise","complaint","abandonment"]:return false
		if (visit.outcome=="abandoned" and entry.type!="abandonment") or (entry.type=="abandonment" and visit.outcome!="abandoned"):return false
		var manifestation: Variant = manifest.type if manifest!=null else null
		if entry.get("manifestation")!=manifestation or (entry.type!="abandonment" and entry.type!=manifestation):return false
		if not numeric(entry.get("requestedDelta")) or not numeric(entry.get("delta")) or entry.get("before")!=expected:return false
		if entry.get("after")!=clampf(entry.before+entry.requestedDelta,0,100) or entry.delta!=entry.after-entry.before:return false
		if not numeric(entry.get("time")) or entry.time>s.time or not NUM.integer(entry.get("day")) or entry.day<1:return false
		visited[entry.visitId]=true;expected=entry.after
	return r.score==expected
