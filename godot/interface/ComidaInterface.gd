extends RefCounted
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
const NAMES = ["Arroz","Legumes","Frango","Arroz com legumes","Sopa de legumes","Frango com arroz","Legumes cortados","Frango cortado"]
const LOOKUP = {"arroz":"arroz","legumes":"legumes","frango":"frango","arroz com legumes":"arrozLegumes","sopa de legumes":"sopa","frango com arroz":"frangoArroz"}
var pattern = RegEx.new()
func _init():pattern.compile("(?i)(?<![\\p{L}])(?:arroz com legumes|sopa de legumes|frango com arroz|arroz|legumes|frango)(?![\\p{L}])")
static func icon(item: String,quality: int = 0) -> Dictionary:
	var key := FOOD.food_key(item)
	var index := FOOD.KEYS.find(key)
	var art: Array = []
	if index>=0:art.append(["food",item,0,0,64,64,1,1,0,0,1])
	if quality>0 and not item.begins_with("pot_"):
		var points: Array = []
		for i in 10:
			var angle := -PI/2+i*PI/5
			var radius := 18*(0.22 if i%2 else 0.5)
			points.append([53+cos(angle)*radius,53+sin(angle)*radius])
		art.append(["poly",points,["","#c5c9cc","#ffd14c","#c286ff"][quality]])
	return {"tag":"canvas","cls":"foodArt","label":(NAMES[index] if index>=0 else "Comida")+" • "+["Comum","Prata","Ouro","Roxa"][quality],"art":art}
func parts(value: String) -> Array:
	var result: Array = []
	var offset := 0
	for found in pattern.search_all(value):
		if found.get_start()>offset:result.append(value.substr(offset,found.get_start()-offset))
		result.append({"food":LOOKUP[found.get_string().to_lower()]});offset=found.get_end()
	if offset<value.length():result.append(value.substr(offset))
	return result
func decorate(model: Variant) -> Variant:
	if not model is Dictionary or model.get("tag") in ["canvas","option"] or model.get("cls")=="recipeBook":return model
	var children: Array = []
	for child in model.get("children",[]):
		if child.get("tag")=="text":
			for part in parts(child.text):
				if part is String:
					if not part.strip_edges().is_empty():children.append({"tag":"text","text":part.strip_edges()})
				else:children.append(icon(part.food))
		else:children.append(decorate(child))
	if model.has("children"):model.children=children
	return model
