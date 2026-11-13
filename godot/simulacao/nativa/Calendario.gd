extends RefCounted
const SEASONS = ["Primavera","Verão","Outono","Inverno"]
const WEEKDAYS = ["Segunda","Terça","Quarta","Quinta","Sexta","Sábado","Domingo"]
static func hours() -> Array:
	return [{"start":660,"end":900},{"start":1080,"end":1320}]
static func valid_hours(value: Variant) -> bool:
	if not value is Array or value.size()!=2:return false
	for h in value:
		if not h is Dictionary or not h.has("start") or not h.has("end"):return false
		for key in ["start","end"]:
			if not (h[key] is float or h[key] is int) or not is_finite(h[key]) or h[key]!=floor(h[key]):return false
		if h.start<360 or h.end>1560 or h.start>=h.end or int(h.start)%10 or int(h.end)%10:return false
	return value[0].end<=value[1].start
static func time_text(minute: float) -> String:
	return "%02d:%02d"%[int(fposmod(minute,1440)/60),int(fposmod(minute,60))]
static func date(day: int) -> Dictionary:
	var index := day-1
	var season := int(floor(float(index)/28))%4
	return {"day":index%28+1,"weekday":WEEKDAYS[index%7],"season":SEASONS[season],"seasonIndex":season,"year":int(floor(float(index)/112))+1}
static func reputation_level(score: float) -> String:
	if score>=80:return "Referência local"
	if score>=60:return "Bem avaliado"
	if score>=40:return "Reconhecido"
	if score>=20:return "Pouco conhecido"
	return "Desconhecido"
