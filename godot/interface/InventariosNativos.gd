extends RefCounted
## Native inventory view and native action registry. Remaining kitchen rules are
## called through the temporary simulation boundary, never through DOM widgets.
const ITEMS = preload("res://simulacao/nativa/itens.json")
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
var actions: Dictionary = {}

func text(value: String) -> Dictionary:return {"tag":"text","text":value}
func label(value: String) -> Dictionary:return {"tag":"p","children":[text(value)]}
func name(item: String) -> String:return ITEMS.data.get(item,{}).get("name","Item desconhecido")
func button(title: String,path: String,action: Dictionary,disabled: bool = false,cls: String = "",art: Array = []) -> Dictionary:
	if not disabled:actions[path]=action
	var result := {"tag":"button","id":"","cls":cls,"path":path,"label":title,"text":title,"disabled":disabled}
	if not art.is_empty():result.art=art
	return result
func item_art(item: String,quality: int = 0) -> Array:
	var result: Array = []
	if FOOD.texture(item)!=null:result.append(["food",item,0,0,64,64,1,1,0,0,1])
	elif item in ["pot","spoon","plate"]:result.append(["img","esquina-tools.png",["pot","spoon","plate"].find(item)*160,0,160,112,0,0,160,112,1])
	else:result.append(["svg",'<svg viewBox="0 0 32 32"><path fill="#e0bd79" d="M5 8h22v17H5z"/><path fill="#755033" d="M4 5h24v5H4z"/></svg>'])
	if quality>0 and not item.begins_with("pot_"):
		var points: Array = []
		for i in 10:
			var angle := -PI/2+i*PI/5
			var radius := 18*(0.22 if i%2 else 0.5)
			points.append([53+cos(angle)*radius,53+sin(angle)*radius])
		result.append(["poly",points,["","#c5c9cc","#ffd14c","#c286ff"][quality]])
	return result
func render(state: Dictionary,id: Variant) -> Dictionary:
	actions.clear()
	var object: Variant = null
	for candidate in state.objects:
		if candidate.id==id:object=candidate;break
	if object==null or not object.get("inventory") is Array:return {"tag":"div","id":"panel","children":[]}
	var held = state.player.get("hand")
	var children: Array = [label(("Nas mãos: "+name(held.item) if held!=null else "Mãos vazias")+" • Retire uma unidade por vez. O tempo continua passando.")]
	var title := "Guardar "+(name(held.item) if held!=null else "item das mãos")
	children.append(button(title,"nativo:guardar:"+str(int(id)),{"kind":"put","id":id},held==null,"objectAction",item_art(held.item,int(held.get("quality",0))) if held!=null else []))
	var slots: Array = []
	for index in object.inventory.size():
		var slot = object.inventory[index]
		var caption := "Retirar "+(name(slot.item) if slot!=null else "vazio")+" • espaço "+str(index+1)
		var control := button(caption,"nativo:retirar:"+str(int(id))+":"+str(index),{"kind":"take","id":id,"index":index},slot==null or held!=null,"inventorySlot",item_art(slot.item,int(slot.get("quality",0))) if slot!=null else [])
		control.text="× "+str(int(slot.n)) if slot!=null else ""
		slots.append(control)
	children.append({"tag":"div","cls":"inventoryGrid","children":slots})
	if not state.recovery.is_empty():
		children.append(label("Itens preservados de saves antigos (não cabiam nos móveis):"))
		for index in state.recovery.size():
			var slot: Dictionary = state.recovery[index]
			children.append(button("Recuperar "+name(slot.item)+" × "+str(int(slot.n)),"nativo:recuperar:"+str(index),{"kind":"recover","index":index},held!=null))
	return {"tag":"div","id":"panel","children":children}
func replace_panel(node: Dictionary,panel: Dictionary) -> void:
	var children: Array = node.get("children",[])
	for index in children.size():
		if children[index].get("id")=="panel":children[index]=panel
		else:replace_panel(children[index],panel)
func dispatch(path: String,execute: Callable) -> bool:
	if not actions.has(path):return false
	var action: Dictionary = actions[path]
	# Revalidate visibility in addition to the current native registry.
	var expression := "R.recoverHand(state,"+str(action.get("index",0))+")" if action.kind=="recover" else "R.handStorage(state,"+str(int(action.id))+","+JSON.stringify(action.kind)+","+str(action.get("index",0))+")"
	execute.call("(()=>{if(!$('management').open||dialogMode!=='container')return;const result="+expression+";if(result.ok&&"+str(action.kind!="put").to_lower()+")$('management').close();tell(result.message,!result.ok)})()")
	return true
