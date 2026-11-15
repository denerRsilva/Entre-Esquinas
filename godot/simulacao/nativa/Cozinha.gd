extends RefCounted
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
const BUILD = preload("res://simulacao/nativa/Construcao.gd")
const STORE = preload("res://simulacao/nativa/Armazenamento.gd")
const INV = preload("res://simulacao/nativa/Inventario.gd")
const RECIPES = preload("res://simulacao/nativa/Receitas.gd")
var manual_moving := false
func find(s: Dictionary,id: Variant) -> Variant:return BUILD.find(s.objects,id)
func name(item: String) -> String:return INV.ITEMS.data.get(item,{}).get("name","Item desconhecido")
func result(s: Dictionary,ok: bool,message: String) -> Dictionary:
	s.message=message
	return {"ok":ok,"error":null if ok else message,"message":message}
func feedback(s: Dictionary,o: Dictionary,label: String) -> Dictionary:
	o.feedback={"label":label,"until":s.time+0.9}
	return result(s,true,label+".")
func near(s: Dictionary,o: Variant,a: Variant = null) -> bool:
	if o==null:return false
	if a==null:a=s.player
	if a.get("motion")!=null or (a.id==s.player.id and manual_moving) or o.room!=a.room:return false
	for point in MOVE.access(s,o):
		if point.x==a.x and point.y==a.y:return true
	return false
func cancel_plate(s: Dictionary) -> Dictionary:
	s.plating=null
	return result(s,true,"Empratamento cancelado; itens preservados.")
func take_pan(s: Dictionary,o: Dictionary) -> Dictionary:
	if s.player.get("hand")!=null or s.player.get("carry")!=null:return result(s,false,"Suas mãos estão ocupadas.")
	if s.get("plating")!=null and s.plating.get("prep")==o.id:return result(s,false,"Cancele o empratamento antes de retirar.")
	if o.type=="kitchen" or STORE.is_support_surface(o):
		if o.get("support")==null:return result(s,false,"Não há panela apoiada.")
		s.player.hand=o.support;o.support=null
	else:
		if o.get("pan")==null or o.pan=="cookingPot":return result(s,false,"Aguarde o cozimento terminar.")
		if not o.get("ingredients",[]).is_empty():return result(s,false,"Retire os ingredientes antes de remover a panela.")
		s.player.hand={"item":o.pan,"n":1,"quality":RECIPES.batch_quality(s,o)}
		if o.get("burned",false):s.player.hand.burned=true
		o.pan=null;o.erase("readyBatch");o.erase("burned");o.erase("heatStage")
	return feedback(s,o,"Panela nas mãos")
func storage(s: Dictionary,id: Variant,action: String,index: Variant) -> Dictionary:
	var o = find(s,id)
	var a: Dictionary = s.player
	if o==null or not o.get("inventory") is Array or not near(s,o):return result(s,false,"Aproxime-se do armazenamento.")
	if s.get("chopping")!=null or s.get("plating")!=null or a.get("carry")!=null:return result(s,false,"Conclua a tarefa e libere as mãos.")
	if action=="take":
		if a.get("hand")!=null:return result(s,false,"Suas mãos estão ocupadas. Guarde o item antes de retirar outro.")
		if not BUILD.NUM.integer(index) or index<0 or index>=o.inventory.size():return result(s,false,"Espaço inválido.")
		var p = o.inventory[int(index)]
		if p==null:return result(s,false,"Espaço vazio.")
		a.hand=p.duplicate(true);a.hand.n=1;INV.remove(o.inventory,int(index),1);STORE.sync(s)
		return result(s,true,name(a.hand.item)+" nas mãos.")
	if action=="put":
		var p = a.get("hand")
		if p==null:return result(s,false,"Suas mãos estão vazias.")
		var added := false
		if STORE.accepts(o,p.item):
			if o.type=="potRack":added=STORE.put(s,o,p.item,1,p.get("quality",0))==1
			else:added=INV.add(o.inventory,p.item,1,p.get("quality",0),p.get("burned",false))
		if not added:return result(s,false,"Sem espaço compatível; item preservado nas mãos.")
		a.hand=null;STORE.sync(s);return result(s,true,"Item guardado.")
	return result(s,false,"Ação inválida.")
func recover(s: Dictionary,index: Variant) -> Dictionary:
	if s.player.get("hand")!=null or s.player.get("carry")!=null or s.get("chopping")!=null or s.get("plating")!=null:return result(s,false,"Libere as mãos.")
	if not BUILD.NUM.integer(index) or index<0 or index>=s.recovery.size():return result(s,false,"Item preservado ausente.")
	var p = s.recovery[int(index)]
	if p==null:return result(s,false,"Item preservado ausente.")
	s.player.hand=p.duplicate(true);s.player.hand.n=1;p.n-=1;s.recovery=s.recovery.filter(func(v):return v.n>0)
	return result(s,true,"Item antigo recuperado nas mãos.")
func cook_error(s: Dictionary,o: Variant,recipe: Variant) -> Variant:
	if o==null or o.type!="stove" or not RECIPES.RECIPES.data.has(recipe):return "Complete uma receita na panela."
	if s.player.get("hand")!=null or s.player.get("carry")!=null or s.get("chopping")!=null or s.get("plating")!=null:return "Libere as mãos e conclua o trabalho manual antes de cozinhar."
	if s.get("cooking")!=null:return "Há uma panela cozinhando."
	if o.get("pan")!="pot":return "Instale uma panela vazia."
	return "A combinação não corresponde à receita." if RECIPES.recognized(o)!=recipe else null
func cook(s: Dictionary,id: Variant,recipe: Variant) -> Dictionary:
	var o = find(s,id)
	if not near(s,o):return result(s,false,"Aproxime-se do fogão.")
	var error = cook_error(s,o,recipe)
	if error!=null:return result(s,false,error)
	var total := 0.0;var weighted := 0.0;var cost := 0.0
	for p in o.get("ingredients",[]):
		var raw: String = INV.ITEMS.data[p.item].get("raw",p.item)
		var q := int(p.get("quality",0))
		total+=p.n;weighted+=p.n*q;cost+=p.n*INV.ITEMS.data[raw].cost*[1,1.25,1.5,2][q];s.used[raw]+=p.n
	o.ingredients=[];o.pan="cookingPot";s.cookActive=true;s.ledger.foodCost+=cost
	s.cooking={"stove":id,"recipe":recipe,"servings":1,"quality":floor(weighted/total),"left":RECIPES.RECIPES.data[recipe].time,"total":RECIPES.RECIPES.data[recipe].time}
	return feedback(s,o,"Cozinhando — pode realizar outras tarefas")
func plating_plan(s: Dictionary,o: Variant) -> Dictionary:
	if o==null or o.type!="kitchen":return {"error":"Use a mesa de cozinha."}
	if s.player.get("carry")!=null:return {"error":"Libere as mãos."}
	var hand = s.player.get("hand")
	if hand!=null and not INV.ITEMS.data.get(hand.item,{}).get("servings",0):return {"error":"Libere as mãos."}
	if o.plates==0:return {"error":"Instale pratos limpos."}
	var from_hand: bool = hand!=null
	var p = hand if from_hand else o.get("support")
	if p==null or not INV.ITEMS.data.get(p.item,{}).get("servings",0) or p.get("burned",false):return {"error":"Apoie uma panela com comida utilizável."}
	var portions: int = INV.ITEMS.data[p.item].servings if from_hand else 1
	if o.plates<portions:return {"error":"Instale pratos limpos suficientes."}
	if STORE.ready_count(o)+portions>STORE.READY_DISH_CAPACITY:return {"error":"Área de retirada cheia."}
	var plan := {"recipe":INV.ITEMS.data[p.item].recipe,"item":p.item,"quality":p.get("quality",0),"portions":INV.ITEMS.data[p.item].servings,"count":portions}
	if from_hand:plan.hand=true
	return plan
func plate(s: Dictionary,id: Variant) -> Dictionary:
	var o = find(s,id)
	if not near(s,o):return result(s,false,"Aproxime-se da mesa de cozinha.")
	if s.get("plating")!=null or s.get("chopping")!=null:return result(s,false,"Conclua ou cancele o trabalho manual.")
	var plan := plating_plan(s,o)
	if plan.has("error"):return result(s,false,plan.error)
	s.plating={"prep":id,"left":2,"total":2};s.plating.merge(plan)
	return feedback(s,o,"Empratando uma porção")
func chop_step(s: Dictionary,dt: float) -> void:
	var job = s.get("chopping")
	if job==null:return
	var o = find(s,job.table)
	var p = s.player.get("hand")
	if o==null or p==null or p.item!=job.item or p.get("quality",0)!=job.quality:s.chopping=null;return
	if not near(s,o):return
	job.left=maxf(0,job.left-dt)
	if job.left>1e-8:return
	s.player.hand={"item":job.item+"_cut","n":1,"quality":job.quality};s.chopping=null;feedback(s,o,"Ingrediente cortado nas mãos")
func plate_step(s: Dictionary,dt: float) -> void:
	var job = s.get("plating")
	if job==null:return
	var o = find(s,job.prep)
	var p = s.player.get("hand") if job.get("hand",false) else o.get("support") if o!=null else null
	if o==null or p==null or p.item!=job.item or p.get("quality",0)!=job.quality or p.get("burned",false):cancel_plate(s);return
	if not near(s,o):return
	job.left=maxf(0,job.left-dt)
	if job.left>1e-8 or o.plates<job.count or STORE.ready_count(o)+job.count>STORE.READY_DISH_CAPACITY:return
	if job.get("hand",false):s.player.hand={"item":"pot","n":1}
	else:o.support={"item":"pot","n":1} if job.portions==1 else {"item":"pot_"+job.recipe+"_"+str(int(job.portions)-1),"n":1,"quality":job.quality}
	o.plates-=job.count;STORE.put(s,o,"dish_"+job.recipe,job.count,job.quality);s.plating=null;feedback(s,o,"Um prato pronto")
func step(s: Dictionary,dt: float) -> void:
	var job = s.get("cooking")
	if job!=null:
		var o = find(s,job.stove)
		if o!=null and o.get("pan")=="cookingPot":
			job.left=maxf(0,job.left-dt)
			if job.left<=1e-8:
				var servings: float = job.get("servings",4)
				if servings==0:servings=4
				o.pan="pot_"+job.recipe+"_"+str(int(servings));o.readyBatch={"recipe":job.recipe,"quality":job.get("quality",0),"doneAt":s.time};s.meals.made[job.recipe]+=servings;s.cooking=null;s.cookActive=false;feedback(s,o,"Panela pronta — retirar")
	for o in s.objects:
		if o.get("readyBatch")!=null and o.get("pan") is String and o.pan.begins_with("pot_"):
			var heat := RECIPES.heat(s,o)
			if heat.stage!=o.get("heatStage"):
				o.heatStage=heat.stage;o.heatEvent=o.get("heatEvent",0)+1
				if heat.stage=="burned":o.burned=true
				s.message=heat.label
	chop_step(s,dt);plate_step(s,dt)
func wash(s: Dictionary,id: Variant) -> Dictionary:
	var o = find(s,id)
	if o==null or o.type!="sink" or not near(s,o):return result(s,false,"Aproxime-se da pia.")
	var hand = s.player.get("hand")
	if hand==null or hand.item!="dirtyPlate" or s.get("chopping")!=null or s.get("plating")!=null:return result(s,false,"Traga um prato sujo nas mãos.")
	s.player.hand={"item":"plate","n":1};return result(s,true,"Prato limpo nas mãos.")
func collect_dirty(s: Dictionary,id: Variant) -> Dictionary:
	var table = find(s,id)
	if table==null or table.type!="table" or not near(s,table):return result(s,false,"Aproxime-se da mesa.")
	if s.player.get("hand")!=null or s.player.get("carry")!=null or s.get("chopping")!=null or s.get("plating")!=null:return result(s,false,"Libere as mãos para recolher a louça.")
	for chair in s.objects:
		if chair.type!="chair":continue
		var linked = BUILD.chair_table(chair,s.objects)
		var key := str(int(chair.id))
		if linked!=null and linked.id==id and s.dirtyTables.get(key,0)>0:
			s.dirtyTables[key]-=1;s.player.hand={"item":"dirtyPlate","n":1};return result(s,true,"Prato sujo nas mãos. Leve à pia.")
	return result(s,false,"Não há pratos sujos nesta mesa.")
func physical(s: Dictionary,id: Variant,action: String) -> Dictionary:
	var o = find(s,id)
	var a: Dictionary = s.player
	if o==null or not near(s,o):return result(s,false,"Aproxime-se do objeto.")
	if action=="cancelCut":s.chopping=null;return result(s,true,"Corte cancelado; ingrediente permanece nas mãos.")
	if action=="cancelPlate":return cancel_plate(s)
	if s.get("chopping")!=null or s.get("plating")!=null:return result(s,false,"Conclua ou cancele a tarefa manual.")
	if action=="takePan":return take_pan(s,o)
	var p = a.get("hand")
	match action:
		"chop":
			if a.get("carry")!=null or o.type!="prep" or p==null or p.item not in ["legumes","frango"]:return result(s,false,"Traga frango cru ou legumes inteiros nas mãos.")
			s.chopping={"hand":true,"table":id,"item":p.item,"quality":p.get("quality",0),"left":2,"total":2};return feedback(s,o,"Cortando "+name(p.item))
		"support":
			if a.get("carry")!=null or p==null or not STORE.is_pot(p.item) or not STORE.surface_empty(o):return result(s,false,"Traga uma panela e libere o apoio.")
			o.support=p;a.hand=null;return feedback(s,o,"Panela apoiada")
		"installPan":
			if o.type!="stove" or a.get("carry")!=null or p==null or not STORE.is_pot(p.item) or STORE.space(o,p.item)==0:return result(s,false,"Traga uma panela para um fogão livre.")
			STORE.put(s,o,p.item,1,p.get("quality",0))
			for key in ["readyBatch","burned","heatStage"]:o.erase(key)
			if INV.ITEMS.data[p.item].get("servings",0)>0:o.readyBatch={"recipe":INV.ITEMS.data[p.item].recipe,"quality":p.get("quality",0),"doneAt":s.time}
			if p.get("burned",false):o.burned=true
			a.hand=null;return feedback(s,o,"Panela instalada")
		"add":
			if o.type!="stove" or o.get("pan")!="pot":return result(s,false,"Instale uma panela vazia.")
			if p==null or p.item not in ["arroz","legumes_cut","frango_cut"]:return result(s,false,"Traga arroz, frango cortado ou legumes cortados nas mãos.")
			var next: Array = o.get("ingredients",[]).duplicate(true)
			var portion: Dictionary = p.duplicate(true);portion.n=1;next.append(portion)
			var possible := false
			for recipe in RECIPES.RECIPES.data.values():
				var matches := true
				for part in next:
					var count := 0.0
					for v in next:
						if v.item==part.item:count+=v.n
					if count>recipe.foods.get(INV.ITEMS.data.get(part.item,{}).get("raw",part.item),0):matches=false
				if matches:possible=true
			if not possible:return result(s,false,"Ingrediente incompatível ou excedente; continua nas mãos.")
			a.hand=null;o.ingredients=next;return feedback(s,o,"Receita identificada" if RECIPES.recognized(o)!=null else "Ingrediente adicionado")
		"removeIngredient":
			if p!=null or a.get("carry")!=null or o.type!="stove" or o.get("pan")!="pot":return result(s,false,"Libere as mãos; só é possível corrigir antes de cozinhar.")
			if o.get("ingredients",[]).is_empty():return result(s,false,"Não há ingredientes na panela.")
			a.hand=o.ingredients.pop_back();return feedback(s,o,"Ingrediente devolvido às mãos")
		"cook":return cook(s,id,RECIPES.recognized(o))
		"plate":return plate(s,id)
		"takeDish":
			if p!=null or a.get("carry")!=null:return result(s,false,"Libere as mãos.")
			for dish in o.get("dishes",{}):
				if o.dishes[dish]>0:
					var quality := STORE.first_quality(o,dish)
					STORE.take(s,o,dish,1,quality);a.hand={"item":dish,"n":1,"quality":quality};return feedback(s,o,"Prato nas mãos")
			return result(s,false,"Não há prato pronto.")
		"putDish":
			if o.type!="kitchen" or o.get("support")!=null or p==null or not str(p.item).begins_with("dish_") or STORE.space(o,p.item)==0:return result(s,false,"Sem espaço para apoiar o prato.")
			STORE.put(s,o,p.item,1,p.get("quality",0));a.hand=null;return feedback(s,o,"Prato apoiado")
		"installPlates":
			if o.type!="kitchen" or o.get("support")!=null or p==null or p.item!="plate" or o.plates>=STORE.CLEAN_PLATE_CAPACITY:return result(s,false,"Traga um prato limpo; verifique o espaço na mesa.")
			o.plates+=1;a.hand=null;return feedback(s,o,"Prato limpo instalado")
		"takePlates","takeUtensil":
			if o.type!="kitchen" or p!=null or a.get("carry")!=null:return result(s,false,"Libere as mãos.")
			if action=="takePlates":
				if o.plates==0:return result(s,false,"Não há pratos limpos.")
				o.plates-=1;a.hand={"item":"plate","n":1}
			else:
				if not o.utensil:return result(s,false,"Não há talher instalado.")
				o.utensil=false;a.hand={"item":"spoon","n":1}
			return feedback(s,o,"Item nas mãos")
		"wash":return wash(s,id)
		"discardHand":
			var data: Dictionary = INV.ITEMS.data.get(p.item,{}) if p!=null else {}
			if o.type not in ["sink","bin"] or not data.has("recipe"):return result(s,false,"Traga comida pronta para descartar.")
			s.meals.wasted[data.recipe]+=data.get("servings",1);a.hand={"item":"pot" if data.has("servings") else "dirtyPlate","n":1};return result(s,true,"Comida descartada; recipiente nas mãos.")
	return result(s,false,"Ação indisponível.")
func consume(s: Dictionary,item: String,quantity: int) -> bool:
	if INV.count(s.inventory,item)<quantity:return false
	for index in s.inventory.size():
		if quantity==0:break
		var p = s.inventory[index]
		if p!=null and p.item==item:
			var amount := mini(quantity,int(p.n));INV.remove(s.inventory,index,amount);quantity-=amount
	return true
func discard(s: Dictionary,id: Variant,index: Variant) -> Dictionary:
	var o = find(s,id)
	if o==null or o.type not in ["sink","bin"] or not near(s,o):return result(s,false,"Aproxime-se da pia ou do lixo.")
	if (s.get("chopping")!=null and s.chopping.get("index")==index) or (s.get("plating")!=null and s.plating.get("slot")==index):return result(s,false,"A panela está sendo usada no empratamento.")
	var p: Variant = s.inventory[int(index)] if BUILD.NUM.integer(index) and index>=0 and index<s.inventory.size() else null
	if p==null or (not str(p.item).begins_with("pot_") and not str(p.item).begins_with("dish_")):return result(s,false,"Selecione uma panela com comida ou um prato pronto na mochila.")
	var data: Dictionary = INV.ITEMS.data[p.item]
	var next: Array = s.inventory.duplicate(true)
	INV.remove(next,int(index),1)
	if not INV.add(next,"pot" if data.has("servings") else "dirtyPlate",1):return result(s,false,"Libere espaço na mochila para devolver a panela ou o prato.")
	s.inventory=next;s.meals.wasted[data.recipe]+=data.get("servings",1)
	return result(s,true,"Comida descartada. "+("Panela vazia na mochila." if data.has("servings") else "Prato sujo na mochila."))
func legacy(s: Dictionary,id: Variant,action: String,item: Variant = null) -> Dictionary:
	var o = find(s,id)
	if o==null or o.type not in ["stove","kitchen","prep"] or not near(s,o):return result(s,false,"Aproxime-se do equipamento selecionado.")
	if s.get("plating")!=null and s.plating.prep==id:return result(s,false,"Empratamento em andamento. Aguarde ou cancele.")
	if action=="installPan" and o.type=="stove":
		if o.get("pan")!=null:return result(s,false,"O fogão já tem uma panela.")
		if not consume(s,"pot",1):return result(s,false,"Falta uma panela vazia na mochila.")
		o.pan="pot";return feedback(s,o,"Panela instalada")
	if action=="takePan" and o.type in ["stove","kitchen"]:return take_pan(s,o)
	if o.type=="kitchen":
		match action:
			"installPlates":
				var amount := mini(INV.count(s.inventory,"plate"),maxi(0,STORE.CLEAN_PLATE_CAPACITY-int(o.plates)))
				if amount==0:return result(s,false,"Encaixe de pratos completo." if o.plates>=STORE.CLEAN_PLATE_CAPACITY else "Faltam pratos limpos na mochila.")
				consume(s,"plate",amount);o.plates+=amount;return feedback(s,o,str(amount)+" pratos instalados")
			"installUtensil":
				if o.utensil:return result(s,false,"O talher já está instalado.")
				if not consume(s,"spoon",1):return result(s,false,"Falta um talher (colher) na mochila.")
				o.utensil=true;return feedback(s,o,"Talher instalado")
			"takePlates":
				var amount := mini(int(o.plates),INV.space(s.inventory,"plate"))
				if amount==0:return result(s,false,"Sem pratos limpos disponíveis ou mochila cheia.")
				INV.add(s.inventory,"plate",amount);o.plates-=amount;return feedback(s,o,str(amount)+" pratos na mochila")
			"takeUtensil":
				if not o.utensil or not INV.add(s.inventory,"spoon",1):return result(s,false,"Sem talher instalado ou mochila cheia.")
				o.utensil=false;return feedback(s,o,"Talher na mochila")
			"takeDish":
				var dish: Variant = item
				if dish==null:
					for key in o.dishes:
						if o.dishes[key]>0:dish=key;break
				if not dish is String or not dish.begins_with("dish_") or not o.dishes.get(dish,0):return result(s,false,"Não há esse prato pronto na bancada.")
				var quality := STORE.first_quality(o,dish)
				if not INV.add(s.inventory,dish,1,quality):return result(s,false,"Mochila cheia. O prato continua na bancada.")
				STORE.take(s,o,dish,1,quality);return feedback(s,o,"Prato pronto na mochila")
	return result(s,false,"Ação indisponível.")
