extends "res://qa/RefugioUI.gd"
func progress_nodes(node: Variant) -> Array:
	var result: Array = []
	if not node is Dictionary:return result
	if node.get("tag")=="progress":result.append(node)
	for child in node.get("children",[]):result.append_array(progress_nodes(child))
	return result
func attack(s: Dictionary,value: float) -> void:
	if s.refuge.phase=="aftermath":REF.continue_day(s);g.session.ADMIN.finish_day(s)
	s.day=s.refuge.nextHorde;preload("res://simulacao/nativa/Mercado.gd").restock(s);s.clock={"minute":1080,"remainder":0,"ending":false}
	s.refuge.closed=[];s.refuge.visits=[];stats(s,value)
	REF.begin_attack(s);REF.battle_step(s,8)
func reload(s: Dictionary) -> Variant:
	var raw = g.session.SAVE.serialize(s)
	return g.session.SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
func run():
	await start_game();g.session.root_action("refuge");g.tick(0)
	var s: Dictionary = g.session.state
	check(not g.hud.refuge.visible and g.frame_data.refuge==null,"Partida sem painel permanente, barras ou atalho flutuante da cidade")
	s.refuge.stats={"food":31.25,"energy":58.0,"morale":42.0}
	check(await press("Gestão"),"Gestão acessível pelo botão existente")
	check(await press("Cidade") and g.session.tab=="city","Aba Cidade disponível na gestão")
	for control in g.hud.find_children("*","Button",true,false):
		if control.is_visible_in_tree() and control.text=="Fechamento":check(control.autowrap_mode==TextServer.AUTOWRAP_OFF,"Navegação mantém palavras inteiras")
	var bars := progress_nodes(g.frame_data.ui.modal)
	check(bars.size()==3 and bars.all(func(b):return b.max==100),"Exibe somente as três barras coletivas de 0 a 100")
	check(bars.map(func(b):return b.value)==[31.25,58.0,42.0],"Menu usa o estado coletivo salvo, sem recalcular médias")
	var content := JSON.stringify(g.frame_data.ui.modal)
	for label in ["População","Defesas","Situação","Próxima horda","Normal"]:check(content.contains(label),"Menu informa "+label)
	var time: float = s.time;g.tick(30)
	check(s.time==time,"Consulta da cidade pausa o mundo")
	await snapshot_city("menu")
	check(await press("Voltar ao jogo") and not g.hud.refuge.visible,"Fechar menu mantém tela de jogo limpa")
	await snapshot_city("jogo")
	var loaded = reload(s)
	check(loaded!=null and loaded.refuge.stats==s.refuge.stats and loaded.refuge.residents.all(func(p):return not p.has("food") and not p.has("energy") and not p.has("morale")),"Estado persistido tem apenas barras coletivas e mantém identidades")
	if loaded!=null:
		var before: float = loaded.refuge.stats.food
		REF.completed(loaded,{"refugeResident":1,"experience":{"satisfaction":{"score":100}}},"completed")
		check(loaded.refuge.stats.food>before and loaded.refuge.stats.morale>42,"Uma refeição contribui para os status da cidade")
		loaded.refuge.stats.food=100;loaded.refuge.stats.morale=100
		REF.completed(loaded,{"refugeResident":2,"experience":{"satisfaction":{"score":100}}},"completed")
		check(loaded.refuge.stats.food==100 and loaded.refuge.stats.morale==100,"Ganhos respeitam o limite de cem")
	# Loss → win → loss is still recoverable, and reconstruction survives reset.
	var campaign := clone_campaign();attack(campaign,0)
	check(campaign.refuge.defeats==1 and campaign.refuge.losses==1 and campaign.refuge.phase=="aftermath","Primeira derrota leva a recuo")
	g.session.load_state(campaign);g.tick(0);g.events.append({"kind":"refuge","action":"continue"});g.tick(0)
	check(await press("Gestão") and await press("Cidade"),"Recuo pode ser consultado na cidade")
	check(JSON.stringify(g.frame_data.ui.modal).contains("Situação: Recuo"),"Situação mostra recuo após derrota")
	await snapshot_city("recuo");await press("Voltar ao jogo")
	attack(campaign,95)
	check(campaign.refuge.defeats==0 and campaign.refuge.victories==1 and campaign.refuge.losses==1,"Vitória zera sequência sem apagar o histórico")
	check(campaign.refuge.level==1 and campaign.refuge.residents.size()==4,"Reconstrução permanece independente da sequência de derrotas")
	campaign=reload(campaign)
	check(campaign!=null,"Vitória após derrota pode ser salva e carregada")
	if campaign!=null:
		attack(campaign,0)
		check(campaign.refuge.defeats==1 and campaign.refuge.phase=="aftermath" and campaign.refuge.level==1,"Derrota/vitória/derrota não encerra campanha nem apaga melhorias")
		campaign=reload(campaign)
		check(campaign!=null,"Recuo posterior à vitória continua salvável")
		if campaign!=null:
			attack(campaign,0)
			check(campaign.refuge.defeats==2 and campaign.refuge.phase=="gameover" and reload(campaign)!=null,"Duas derrotas consecutivas encerram campanha")
	# Actual .46 snapshots, exported and validated before changing the schema.
	var old: Dictionary = load("res://qa/referencia-refugio-v1.json").data
	var source := JSON.stringify(old)
	for key in old:
		var migrated = g.session.SAVE.new().load_value(old[key])
		check(migrated!=null,"Migra save real .46: "+key)
		if migrated==null:continue
		check(migrated.refuge.version==2 and migrated.refuge.residents.all(func(p):return not p.has("food")),"Converte uma vez e remove status individuais: "+key)
		check(migrated.cash==old[key].cash and migrated.objects==old[key].objects and migrated.refuge.level==old[key].refuge.level,"Migração preserva dinheiro, móveis e reconstrução: "+key)
		if key=="initial":check(migrated.refuge.stats=={"food":65.0,"energy":70.0,"morale":65.0},"Conversão inicial preserva os valores exibidos")
		if key=="victory_after_loss":check(migrated.refuge.defeats==0 and migrated.refuge.losses==1 and migrated.refuge.victories==1,"Vitória antiga limpa derrota acumulada")
		if key=="pending_after_victory":
			check(migrated.refuge.defeats==0 and migrated.refuge.battle.result=="retreat","Batalha antiga pendente não transforma derrota acumulada em game over")
			REF.battle_step(migrated,8)
			check(migrated.refuge.defeats==1 and migrated.refuge.phase=="aftermath","Batalha migrada termina com uma chance restante")
		if key=="completed_old_gameover":check(migrated.refuge.phase=="gameover","Resultado antigo já encerrado continua preservado")
		var once = reload(migrated)
		check(once!=null and once.refuge.stats==migrated.refuge.stats and once.refuge.losses==migrated.refuge.losses,"Recarregar não repete migração ou consequências: "+key)
	check(JSON.stringify(old)==source,"Carregamento não modifica os arquivos originais")
	var corrupt: Dictionary = old.initial.duplicate(true);corrupt.refuge.residents[0].food=999
	check(g.session.SAVE.new().load_value(corrupt)==null,"Migração rejeita status antigos inválidos")
	for corruption in ["customers","day","missingDay"]:
		var broken: Dictionary = old.initial.duplicate(true)
		if corruption=="customers":broken.customers=["inválido"]
		elif corruption=="day":broken.day="inválido"
		else:broken.erase("day")
		check(g.session.SAVE.new().load_value(broken)==null,"Save antigo malformado é recusado com segurança: "+corruption)
	for patch in [{"food":101},{"morale":-1},{"energy":"alta"},{"food":NAN}]:
		var invalid := clone_campaign();invalid.refuge.stats.merge(patch,true)
		check(g.session.SAVE.serialize(invalid)==null,"Save rejeita barra coletiva inválida")
	var invalid := clone_campaign();invalid.refuge.residents[0].food=65
	check(g.session.SAVE.serialize(invalid)==null,"Schema novo rejeita misturar status individuais e coletivos")
	var free = g.session.PARTIDA.furnished(true,true)
	g.session.load_state(free);g.tick(0);await press("Gestão")
	check(not JSON.stringify(g.frame_data.ui.modal).contains('"text":"Cidade"'),"Modo livre continua sem status de cidade fictícios")
	await finish()
func snapshot_city(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720);g.tick(0);await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/cidade-"+name+".png")
	if name=="menu":
		root.size=Vector2i(960,432);g.tick(0);await layout();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/cidade-menu-telefone.png")
		root.size=Vector2i(1280,720);g.tick(0);await layout()
