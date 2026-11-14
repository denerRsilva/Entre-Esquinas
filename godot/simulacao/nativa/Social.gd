extends RefCounted
## Existing prototype conversations and one relationship point per resident/day.
const LINES = {
	"lia":'Lia • agricultora: "Estou testando legumes para os restaurantes do bairro. Prepare sua cozinha antes de abrir!"',
	"beto":'Beto • cozinheiro: "Uma panela e um utensílio já rendem os primeiros pratos. Duas mesas não ajudam quando o fogão é o gargalo."',
	"nina":'Nina • moradora: "Gosto de uma sopa no jantar. Deixe um corredor livre: ninguém quer esbarrar no garçom."'
}
static func talk(state: Dictionary,id: String) -> String:
	if not LINES.has(id):return ""
	var resident: Variant = null
	for actor in state.residents:
		if actor.id==id:resident=actor;break
	if resident==null or state.player.room!=resident.room or absf(state.player.x-resident.x)+absf(state.player.y-resident.y)>1:return "Aproxime-se para conversar."
	var key := str(int(state.day))+":"+id
	if not state.talked.get(key,false):state.friends[id]+=1;state.talked[key]=true
	return LINES[id]+" Vínculo: "+str(int(state.friends[id]))+". Conversas demonstrativas; desbloqueios e economia social ainda pendentes."
