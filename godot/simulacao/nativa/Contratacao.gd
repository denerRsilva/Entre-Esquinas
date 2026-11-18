extends RefCounted
## First profession; recruitment is separate from task assignment and city growth.
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const MIN_POPULATION := 4
const HIRE_COST := 100
static func active(s: Dictionary) -> bool:return s.get("refuge") is Dictionary and s.refuge.has("hiring")
static func integer(v: Variant) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v)
static func initialize(s: Dictionary) -> void:
	s.refuge.hiring={"version":1,"hires":[]};s.workers=[];s.waiterDefaultApplied=true
static func migrate(s: Dictionary) -> bool:
	if not s.get("refuge") is Dictionary or active(s):return true
	if not s.get("workers") is Array:return false
	if s.workers.size()!=(1 if s.get("singleRoom",false) else 2):return false
	var hires: Array = []
	for worker in s.workers:
		if not worker is Dictionary or worker.get("id") not in ["worker1","worker2"]:return false
		hires.append({"actor":worker.id,"resident":null,"role":"waiter" if worker.id=="worker2" else "logistics","name":"Garçom" if worker.id=="worker2" else "Logística","legacy":true})
	s.refuge.hiring={"version":1,"hires":hires};s.waiterDefaultApplied=true
	return true
static func employed(s: Dictionary,resident_id: Variant) -> bool:
	if not active(s):return false
	for record in s.refuge.hiring.hires:
		if record.resident==resident_id:return true
	return false
static func task_allowed(s: Dictionary,actor_id: Variant,task: Variant) -> bool:
	if not active(s):return true
	for record in s.refuge.hiring.hires:
		if record.actor==actor_id:return record.legacy or task in ["none",record.role]
	return false
static func unlocked(s: Dictionary) -> bool:return active(s) and s.refuge.residents.size()>=MIN_POPULATION
static func occupied(s: Dictionary) -> bool:
	if not active(s):return false
	for record in s.refuge.hiring.hires:
		if record.role=="waiter":return true
	return false
static func candidates(s: Dictionary) -> Array:
	var result: Array = []
	if not unlocked(s):return result
	# Founding inhabitants retain their city roles; new arrivals open choices.
	for person in s.refuge.residents:
		if person.id>=4 and not employed(s,person.id):result.append(person)
	return result
static func visiting(s: Dictionary,id: Variant) -> bool:
	for c in s.customers:
		if c.get("refugeResident")==id and not c.get("done",false):return true
	return false
static func spawn_point(s: Dictionary) -> Variant:
	var busy := {}
	for actor in MOVE.ACTORS.actors(s):
		if actor.room!="restaurant":continue
		for cell in MOVE.reserved(actor):busy[Vector2i(cell.x,cell.y)]=true
	var cells: Array = [Vector2i(12,10)]
	for y in range(7,14):
		for x in range(5,14):cells.append(Vector2i(x,y))
	for point in cells:
		if point in [Vector2i(7,13),Vector2i(7,14)] or busy.has(point) or MOVE.MAP.blocked(s,"restaurant",point):continue
		if MOVE.MAP.route(s,"restaurant",point,Vector2i(7,13))!=null:return point
	return null
static func error(s: Dictionary,resident_id: Variant) -> String:
	if not unlocked(s):return "Novos moradores abrirão a primeira vaga de garçom."
	if s.refuge.phase!="day":return "Aguarde a cidade voltar à rotina."
	if occupied(s):return "A vaga de garçom já está preenchida."
	var found := false
	for person in candidates(s):
		if person.id==resident_id:found=true;break
	if not found:return "Pessoa indisponível para contratação."
	if visiting(s,resident_id):return "Aguarde essa pessoa terminar sua visita."
	if s.cash<HIRE_COST:return "Dinheiro insuficiente para a contratação."
	return ""
static func hire(s: Dictionary,resident_id: Variant) -> Dictionary:
	var message := error(s,resident_id)
	if not message.is_empty():return {"ok":false,"message":message}
	var point = spawn_point(s)
	if point==null:return {"ok":false,"message":"Abra um espaço acessível no salão antes de contratar."}
	var person: Dictionary
	for candidate in candidates(s):
		if candidate.id==resident_id:person=candidate;break
	var worker := {"id":"worker2","room":"restaurant","x":point.x,"y":point.y,"goal":null,"motion":null,"wait":0,"hold":0,"carry":null,"task":"waiter","refugeResident":person.id,"skin":person.skin}
	s.workers.append(worker)
	s.refuge.hiring.hires.append({"actor":"worker2","resident":person.id,"role":"waiter","name":person.name,"legacy":false})
	s.cash-=HIRE_COST;s.ledger.investment+=HIRE_COST
	return {"ok":true,"message":person.name+" começou a trabalhar como garçom."}
static func valid(s: Dictionary) -> bool:
	if not active(s):return true
	var data = s.refuge.hiring
	if not data is Dictionary or data.get("version")!=1 or not data.get("hires") is Array or data.hires.size()>2:return false
	if not s.refuge.get("residents") is Array or data.hires.size()!=s.workers.size():return false
	if s.customers.any(func(c):return not c is Dictionary):return false
	var actors := {};var residents := {}
	for record in data.hires:
		if not record is Dictionary or record.get("actor") not in ["worker1","worker2"] or actors.has(record.actor) or not record.get("legacy") is bool:return false
		if not record.get("name") is String or record.name.is_empty() or record.name.length()>32:return false
		actors[record.actor]=true
		var matching: Array = s.workers.filter(func(w):return w is Dictionary and w.get("id")==record.actor)
		if matching.size()!=1:return false
		var worker: Dictionary = matching[0]
		if record.legacy:
			if record.get("resident")!=null or record.get("role")!=("waiter" if record.actor=="worker2" else "logistics"):return false
		else:
			if record.actor!="worker2" or record.get("role")!="waiter" or not integer(record.get("resident")) or record.resident<4 or residents.has(int(record.resident)):return false
			if not unlocked(s) or worker.get("refugeResident")!=record.resident or worker.get("task") not in ["none","waiter"]:return false
			residents[int(record.resident)]=true
			var found := false
			for person in s.refuge.residents:
				if not person is Dictionary:return false
				if person.get("id")==record.resident:
					if person.get("name")!=record.name or person.get("skin")!=worker.get("skin"):return false
					found=true
			if not found or visiting(s,record.resident):return false
	return true
