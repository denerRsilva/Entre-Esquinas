extends RefCounted
const VALIDATOR = preload("res://simulacao/nativa/ValidadorSave.gd")
const MIGRATE = preload("res://simulacao/nativa/MigracaoSave.gd")
const CALENDAR = preload("res://simulacao/nativa/Calendario.gd")
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const ITEMS = preload("res://simulacao/nativa/itens.json")
func convert(value: Variant,random_values: Array = []) -> Dictionary:
	var service = SERVICE.new()
	service.random_values=random_values
	if not value is Dictionary or not VALIDATOR.N.integer(value.get("version")) or int(value.version) not in [4,5,6,7,8,9,10,11,12]:return {"value":null}
	var s: Dictionary = value.duplicate(true)
	var source: int = s.version
	if not s.get("objects") is Array or not s.get("customers") is Array or not s.get("inventory") is Array or not s.get("inv") is Dictionary:return {"value":null}
	for o in s.objects:
		if not o is Dictionary or not o.get("type") is String:return {"value":null}
		if source<10 and o.type=="prep":o.type="kitchen"
	if not s.has("serviceHours"):s.serviceHours=CALENDAR.hours()
	if s.version==4:
		s.version=5;s.experience={"visits":[],"events":[]}
		for c in s.customers:
			if not c is Dictionary or not c.has("state"):return {"value":null}
			c.experience=service.experience();c.experience.legacy=true;c.experience.reviewResolved=true
			if c.state=="waiting":service.begin(s,c,"service")
			elif c.state=="ordered":service.begin(s,c,"food")
	if service.needs_random:return {"needsRandom":true}
	if s.version==5:
		if not s.get("experience") is Dictionary or not s.experience.get("visits") is Array:return {"value":null}
		s.version=6;s.clock={"minute":360,"remainder":0,"ending":false};s.reputation={"initial":0,"score":0,"history":[],"processed":[]}
		for visit in s.experience.visits:
			if not visit is Dictionary or not visit.has("id"):return {"value":null}
			s.reputation.processed.append(visit.id)
	if not s.get("recovery",[]) is Array:return {"value":null}
	for o in s.objects:
		if o.has("inventory"):
			if not o.inventory is Array:return {"value":null}
			for p in o.inventory:
				if p!=null and not VALIDATOR.K.stack(p):return {"value":null}
	if s.version==6:MIGRATE.kitchen(s)
	if int(s.version) in [7,8,9,10,11,12]:
		if not s.get("recovery") is Array:return {"value":null}
		MIGRATE.cleaning(s)
	for o in s.objects:
		var pan = o.get("pan")
		if o.type=="stove" and pan is String and pan.begins_with("pot_") and not o.get("readyBatch"):
			if not ITEMS.data.has(pan) or not s.has("time"):return {"value":null}
			o.readyBatch={"recipe":ITEMS.data[pan].recipe,"quality":0,"doneAt":s.time}
	MIGRATE.physical(s,source)
	if source<12:
		if s.get("chopping")!=null and not s.chopping.get("hand",false):s.chopping=null
		if s.inventory.size() not in [0,5,10] or not VALIDATOR.valid(s,s.inventory.size()):return {"value":null}
		if not MIGRATE.hands(s):return {"value":null}
	return {"value":s if VALIDATOR.valid(s) else null}
func parse_text(raw: Variant,random_values: Array = []) -> Dictionary:
	if not raw is String:return {"value":null}
	var parser := JSON.new()
	if parser.parse(raw)!=OK:return {"value":null}
	return self.convert(parser.data,random_values)
static func serialize(value: Variant) -> Variant:
	if not VALIDATOR.valid(value):return null
	return JSON.stringify(value,"",true,true)
func load_value(value: Variant,rng: Callable = randf) -> Variant:
	var draws: Array = []
	while true:
		var result: Dictionary = self.convert(value,draws)
		if not result.get("needsRandom",false):return result.value
		draws.append(rng.call())

	return null
