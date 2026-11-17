extends RefCounted
const REFUGE = preload("res://simulacao/nativa/Refugio.gd")
const ADMIN = preload("res://simulacao/nativa/Administracao.gd")
const SERVICE = preload("res://simulacao/nativa/Atendimento.gd")
const FOOD = preload("res://interface/ComidaInterface.gd")
const TEXTS = preload("res://simulacao/nativa/textos-interface.json")
var controls = preload("res://interface/InventariosNativos.gd").new()
var food_ui = FOOD.new()
var stamp := ""
var form: Dictionary = {}
const HIRING = preload("res://simulacao/nativa/Contratacao.gd")
var mode := ""
var tab := ""
func number(value: Variant) -> String:return str(int(value)) if (value is float or value is int) and value==floor(value) else str(value)
func node(tag: String,children: Array,id: String = "",cls: String = "") -> Dictionary:return {"tag":tag,"children":children,"id":id,"cls":cls}
func text(value: String) -> Dictionary:return controls.text(value)
func label(value: String) -> Dictionary:return controls.label(value)
func money(value: float) -> String:return "$%.2f"%value
func register(kind: String,key: String,extra: Dictionary = {}) -> String:
	var path := "nativo:admin:"+kind+":"+key
	controls.actions[path]={"kind":kind,"key":key,"mode":mode,"tab":tab};controls.actions[path].merge(extra)
	return path
func button(title: String,kind: String,key: String = "",disabled: bool = false,extra: Dictionary = {}) -> Dictionary:
	var path := register(kind,key,extra)
	return {"tag":"button","text":title,"label":title,"path":path,"disabled":disabled}
func select(title: String,kind: String,key: String,value: Variant,options: Array,disabled: bool = false,extra: Dictionary = {}) -> Dictionary:
	return {"tag":"select","path":register(kind,key,extra),"label":title,"value":value,"options":options,"disabled":disabled}
func input(title: String,kind: String,key: String,value: Variant,min_value: float = 1,max_value: float = 100,step: float = 1) -> Dictionary:
	return {"tag":"input","path":register(kind,key),"label":title,"value":value,"type":"number","min":min_value,"max":max_value,"step":step,"disabled":false}
func table(headers: Array,rows: Array) -> Dictionary:
	var head: Array = []
	for value in headers:head.append(node("th",[text(number(value))]))
	var body: Array = []
	for row in rows:
		var cells: Array = []
		for value in row:cells.append(node("td",[value if value is Dictionary else text(number(value))]))
		body.append(node("tr",cells))
	return node("div",[node("table",[node("thead",[node("tr",head)]),node("tbody",body)])],"","tableWrap")
func time_options() -> Array:
	var result: Array = []
	for minute in range(360,1561,10):result.append([ADMIN.CALENDAR.time_text(minute)+(" (madrugada)" if minute>=1440 else ""),minute])
	return result
func render(s: Dictionary,model: Dictionary,override: Variant = null) -> Dictionary:
	controls.actions.clear();mode=model.mode;tab=model.tab
	var current := mode+":"+tab+":"+number(model.generation)
	if current!=stamp:
		stamp=current;form={"searchStaff":false,"hours":ADMIN.hours(s).duplicate(true),"quantities":{"arroz":10,"legumes":10,"frango":10},"qualities":{"arroz":0,"legumes":0,"frango":0},"time":660 if s.clock.minute<=660 else s.clock.minute}
	var titles := {"computer":"Computador • restaurante","options":"Opções","recipes":"Livro de receitas","container":"Inventários • "+SERVICE.BUILD.CATALOG.data[SERVICE.new().find(s.objects,model.object).type].name if mode=="container" else ""}
	var title: String = titles.get(mode,"Gestão da taverna" if REFUGE.active(s) else "Gestão do restaurante")
	var tabs: Dictionary = {} if mode=="recipes" else {"container":"Transferir itens"} if mode=="container" else {"supplier":"Fornecedor","tools":"Utensílios","menu":"Cardápio e preços","deliveries":"Entregas"} if mode=="computer" else {"camera":"Câmera","save":"Salvar e carregar","test":"Testes","guide":"Primeiros passos"} if mode=="options" else {"shifts":"Turnos","build":"Modo construção","team":"Equipe","finance":"Fechamento","customers":"Clientes","calendar":"Calendário","reputation":"Reputação"}
	if mode=="general" and REFUGE.active(s):
		var city_tabs := {"city":"Cidade","menu":"Cardápio"};city_tabs.merge(tabs);tabs=city_tabs
	var navigation: Array = []
	for key in tabs:
		var item := button(tabs[key],"tab",key);item.cls="active" if tab==key else ""
		if mode=="general" and REFUGE.active(s):item.cls+=" cityNavButton"
		navigation.append(item)
	var panel: Dictionary = override if override!=null else node("div",panel(s,model),"panel")
	return food_ui.decorate(node("dialog",[node("div",[node("b",[text(title)]),node("small",[text("Jogo pausado")]),button("Voltar ao jogo","close")],"","dialogHead"),node("nav",navigation,"tabs"),panel,node("p",[text(model.notice)] if not model.notice.is_empty() else [],"menuNotice")],"management"))
func panel(s: Dictionary,model: Dictionary) -> Array:
	var result: Array = []
	if TEXTS.data.has(tab):result.append(label(TEXTS.data[tab]))
	match tab:
		"city":
			if not REFUGE.active(s):return [label("Comece no refúgio para acompanhar a cidade.")]
			var city: Dictionary = s.refuge
			if s.has("market"):
				result.append(label("Beto vende ingredientes na rua; reposição ao amanhecer."))
				result.append(label("Caravana com Nina: hoje." if preload("res://simulacao/nativa/Mercado.gd").visiting(s) else "Próxima caravana: dia "+str((int(s.day)/4+1)*4)+"."))
			var days: int = maxi(0,int(city.nextHorde-s.day))
			var situation: String = "Recuo" if city.defeats>0 else "Preparação para a horda" if days<=1 else "Normal"
			result.append(node("h2",[text("Cidade")]))
			result.append(label("Situação: "+situation+" · População: "+number(city.residents.size())))
			var statuses: Array = []
			for pair in [["food","Alimentação"],["energy","Energia"],["morale","Moral"]]:
				statuses.append(node("b",[text(pair[1]+"  "+number(round(city.stats[pair[0]]))+" / 100")]))
				statuses.append({"tag":"progress","label":pair[1],"max":100,"value":city.stats[pair[0]],"color":"patience"})
			result.append(node("div",statuses,"","card"))
			var condition: String = "Boas condições" if city.defense>=75 else "Estáveis" if city.defense>=50 else "Precisam de reparos"
			result.append(label("Defesas: "+condition+" · "+number(city.defense)+" / 100"))
			result.append(label("Próxima horda: hoje" if days==0 else "Próxima horda: em "+number(days)+(" dia" if days==1 else " dias")))
			result.append(label("Derrotas seguidas: "+number(city.defeats)+" / 2 · Uma vitória reinicia a sequência."))
		"camera":
			result.append(node("div",[button("− Afastar","zoom","out",model.camera<=0.7),node("output",[text(number(round(model.camera*100))+"%")]),button("+ Aproximar","zoom","in",model.camera>=2)],"","cameraControls"))
			result.append(button("Restaurar zoom padrão (100%)","zoom","reset"));var fullscreen := button("Alternar tela cheia","fullscreen");fullscreen.id="fullscreenBtn";result.append(fullscreen)
		"shifts":
			var busy: bool = s.open or s.closing or ADMIN.pending(s)
			for i in 2:
				var parts: Array = [node("b",[text("Almoço" if i==0 else "Jantar")])]
				for key in ["start","end"]:parts.append(node("label",[text("Início" if key=="start" else "Término"),select(("Almoço" if i==0 else "Jantar")+" — "+("Início" if key=="start" else "Término"),"hours",str(i)+":"+key,form.hours[i][key],time_options(),busy,{"index":i,"field":key})]))
				result.append(node("div",parts,"","card"))
			result.append(button("Aplicar horários","applyHours","",busy))
		"supplier":
			var receiving := false
			for o in s.objects:
				if o.type=="receiving":receiving=true
			if s.singleRoom and not receiving:return [label("Instale as caixas de recebimento pelo modo construção antes de comprar ingredientes.")]
			result.append(label("As entregas chegam às caixas de recebimento. Recolha os ingredientes e leve-os nas mãos à geladeira ou prateleira." if s.singleRoom else "As entregas chegam ao recebimento em 5 segundos de jogo. O jogo pausa nesta tela."))
			var cards: Array = [];var rows: Array = []
			for food in ["arroz","legumes","frango"]:
				var data: Dictionary = SERVICE.INV.ITEMS.data[food];var quality := int(form.qualities[food]);var tiers: Array = []
				for q in 4:tiers.append([["Comum","Prata","Ouro","Roxa"][q],q])
				cards.append(node("div",[node("b",[FOOD.icon(food,quality)]),label(money(data.cost*[1,1.25,1.5,2][quality])+"/un. • "+("Armazenamento seco" if data.kind=="dry" else "Refrigerado")),select("Qualidade do ingrediente","quality",food,quality,tiers),input("Quantidade de "+data.name,"quantity",food,form.quantities[food]),button("Comprar","purchase",food)],"","card"))
				for q in 4:
					var values: Array = [FOOD.icon(food,q),ADMIN.receiving_count(s,food,q)]
					for location in ["storage","kitchen"]:
						var amount := 0
						for o in s.objects:
							if o.has("inventory") and SERVICE.STORE.location(o)==location:amount+=SERVICE.STORE.quality_count(o,food,q)
						values.append(amount)
					rows.append(values)
			result.append(node("div",cards,"","cards"));result.append(table(["Ingrediente","Recebimento","Estoque","Cozinha"],rows))
		"menu":
			result.append(label("Escolha os pratos oferecidos e ajuste os preços. Receitas e custos são hipóteses de teste. Pedidos já anotados mantêm o preço combinado."));var cards: Array = []
			for id in preload("res://simulacao/nativa/Receitas.gd").available(s):
				var recipe: Dictionary = SERVICE.RECIPES.data[id];var cost := 0.0;var ingredients: PackedStringArray = []
				for food in recipe.foods:cost+=recipe.foods[food]*SERVICE.INV.ITEMS.data[food].cost;ingredients.append(number(recipe.foods[food])+" "+SERVICE.INV.ITEMS.data[food].name)
				cards.append(node("div",[node("b",[text(recipe.name)]),FOOD.icon(id),preload("res://interface/LivroReceitasNativo.gd").ratings(s,id),label(" + ".join(ingredients)+" • custo "+money(cost)+" • preparo "+number(recipe.time)+"s por porção"),{"tag":"input","type":"checkbox","checked":s.menu[id],"value":s.menu[id],"label":"Oferecer no cardápio","path":register("menu",id),"disabled":false},input("Preço de "+recipe.name,"price",id,s.prices[id],1,100,0.25)],"","card"))
			result.append(node("div",cards,"","cards"))
		"deliveries":
			var rows: Array = []
			for delivery in s.deliveries:rows.append(["#"+number(delivery.id),FOOD.icon(delivery.food,delivery.get("quality",0)),delivery.total,delivery.received,delivery.pending,number(ceil(delivery.eta-s.time))+"s" if delivery.eta>s.time else "No recebimento / aguarda espaço"])
			result.append(table(["Pedido","Ingrediente","Total","Recebido","Pendente","Chegada"],rows))
		"team":
			if HIRING.active(s):
				result.append(node("h2",[text("Equipe da taverna")]))
				if not HIRING.occupied(s):
					if not HIRING.unlocked(s):
						result.append(label("A chegada de novos moradores abrirá a primeira vaga: Garçom."))
						result.append(label("Moradores: "+number(s.refuge.residents.size())+" / "+number(HIRING.MIN_POPULATION)))
					else:result.append(button("Procurar contratação","searchStaff"))
				for record in s.refuge.hiring.hires:
					var worker = SERVICE.new().find(s.workers,record.actor)
					result.append(node("div",[node("b",[text(record.name+" · "+("Garçom" if record.role=="waiter" else "Logística"))]),select("Tarefa de "+record.name,"task",record.actor,worker.task,[["Pausado","none"],["Anotar, servir e recolher louça","waiter"]] if record.role=="waiter" else [["Pausado","none"],["Logística","logistics"]])],"","card"))
				if form.get("searchStaff",false) and not HIRING.occupied(s):
					for person in HIRING.candidates(s):
						var reason := HIRING.error(s,person.id)
						var portrait := {"tag":"canvas","art":[["img","taverna/cliente-0"+number(person.skin-11)+"-estudo-sprites.png",313.5,0,313.5,313.5,0,0,32,32,1.0]]}
						result.append(node("div",[node("b",[portrait,text(person.name)]),label("Garçom · contratação "+money(HIRING.HIRE_COST)),button("Contratar "+person.name,"hire",number(person.id),not reason.is_empty()),label(reason) if not reason.is_empty() else label("Anota pedidos, serve e recolhe louça.")],"","card"))
				return result
			result.append(label("Garçom do salão. Atribua o atendimento abaixo." if s.singleRoom else "Funcionários de teste. A carga em trânsito é entregue antes da troca de função."))
			for worker in s.workers:
				var name: String = "Garçom" if worker.id=="worker2" else "Logística"
				result.append(node("div",[node("b",[text(name)]),label({"restaurant":"Restaurante • salão e cozinha","street":"Rua da Praça","stock":"Estoque • recebimento e administração"}[worker.room]+" • "+("Aguardando passagem" if worker.wait>=5 else "Transportando carga" if worker.get("carry")!=null else "Em deslocamento" if worker.get("goal")!=null else "Aguardando trabalho ou ingredientes")),select("Tarefa de "+name,"task",worker.id,worker.task,[["Parado","none"],["Anotar, servir e recolher louça","waiter"]] if s.singleRoom else [["Parado","none"],["Recebimento → estoque → cozinha","logistics"],["Anotar, servir e recolher louça","waiter"]])],"","card"))
		"finance":
			result.append(table(["Indicador","Hoje"],[["Receita",money(s.ledger.revenue)],["Ingredientes consumidos",money(s.ledger.foodCost)],["Compras",money(s.ledger.purchases)],["Investimentos",money(s.ledger.investment)],["Clientes pagos",s.ledger.sales],["Clientes perdidos (inclui abandono)",s.ledger.lost],["Esperas por circulação",s.flowWaits]]))
			if s.get("lastReport")!=null:
				var report: Dictionary = s.lastReport
				result.append(table(["Último fechamento • dia "+number(report.day),"Valor"],[["Receita",money(report.revenue)],["Custo dos ingredientes",money(report.foodCost)],["Despesa",money(report.expense)],["Resultado operacional",money(report.result)],["Caixa final",money(report.cash)]]))
		"customers":
			var rows: Array = [];var service = SERVICE.new()
			for customer in s.customers:
				var indicator = service.indicator(s,customer);var profile: Dictionary = customer.experience
				rows.append([customer.id,{"impatient":"Impaciente","normal":"Normal","patient":"Paciente"}[profile.profile],"Atendimento" if profile.phase=="service" else "Comida" if profile.phase=="food" else "Desistiu" if profile.abandoned else "Comendo" if customer.state=="eating" else "Em deslocamento",indicator.emoji+" "+number(ceil(indicator.remaining))+"s" if indicator!=null and indicator.phase!=null else indicator.emoji if indicator!=null else "—"])
			result.append(table(["Cliente","Perfil","Etapa","Paciência restante"],rows));rows=[]
			var classes: Dictionary = {}
			for entry in SERVICE.CONFIG.data.satisfaction.classes:classes[entry.id]=entry.label
			var visits: Array = s.experience.visits.slice(maxi(0,s.experience.visits.size()-20));visits.reverse()
			for visit in visits:
				var manifestation := "Nenhuma"
				for event in s.experience.events:
					if event.visitId==visit.id:manifestation={"praise":"Elogio","complaint":"Reclamação"}.get(event.type,"Nenhuma");break
				rows.append([visit.id,"Abandono" if visit.outcome=="abandoned" else "Concluída","Insatisfeito" if visit.outcome=="abandoned" else number(floor(visit.satisfaction.score+0.5))+"/100 • "+classes[visit.satisfaction.classification],manifestation])
			result.append(table(["Últimas 20 visitas","Resultado","Satisfação","Manifestação"],rows))
		"calendar":
			var date := ADMIN.CALENDAR.date(int(s.day))
			result.append(table(["Calendário","Agora"],[["Horário",ADMIN.CALENDAR.time_text(s.clock.minute)],["Data",date.weekday+", "+number(date.day)+" de "+date.season+", ano "+number(date.year)],["Dia acumulado",s.day],["Situação","02:00 — concluindo serviço pendente" if s.clock.ending else "Dia em andamento"]]))
		"reputation":
			result.append(label("Reputação: "+number(s.reputation.score)+"/100 — "+ADMIN.CALENDAR.reputation_level(s.reputation.score)+". Valores provisórios: início em 0; elogio 1; reclamação -1; abandono -1. O abandono não acumula outra penalidade pela reclamação da mesma visita. Fluxo de clientes e preços permanecem sem influência da reputação. Avaliações antigas não são reaplicadas ao carregar."))
			var entries: Array = s.reputation.history.slice(maxi(0,s.reputation.history.size()-20));entries.reverse();var rows: Array = []
			for entry in entries:rows.append([entry.visitId,{"praise":"Elogio","complaint":"Reclamação","abandonment":"Abandono"}[entry.type],{"praise":"Elogio","complaint":"Reclamação"}.get(entry.manifestation,"Nenhuma"),("+" if entry.delta>0 else "")+number(entry.delta),number(entry.before)+" → "+number(entry.after)])
			result.append(table(["Últimos 20 impactos","Tipo","Manifestação","Variação","Pontuação"],rows))
		"test":
			result.append(label("Avançar horário de teste • Agora: "+ADMIN.CALENDAR.time_text(s.clock.minute)+". O salto não acelera a paciência, as entregas nem os preparos. Ao passar do fim do turno, a entrada de clientes é encerrada."));result.append(node("label",[text("Ir para o horário: "),select("Horário de teste","time","",form.time,time_options())]));result.append(button("Avançar horário","advance"));result.append(label("O avanço é somente para a frente no dia atual. Às 02:00, valem o fechamento e a virada de dia normais. Para testar clientes, escolha 11:00 e abra o restaurante."));result.append(label("Ferramenta provisória de testes. Remove os móveis e esvazia os armazenamentos, o recebimento e as mãos dos personagens. Cancela clientes, pedidos, entregas e preparos. Preserva dinheiro, dia, preços, cardápio e relatórios. Não devolve o valor dos itens apagados. O salvamento só muda ao usar Salvar jogo."));result.append(button("Excluir todos os móveis e limpar inventários","clear"))
		"save":result.append(button("Salvar jogo","save"));result.append(button("Carregar jogo","load"))
	return result
