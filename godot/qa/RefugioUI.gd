extends "res://qa/FluxoCompletoNativoUI.gd"
const REF = preload("res://simulacao/nativa/Refugio.gd")
func clone_campaign() -> Dictionary:
	var s: Dictionary = g.session.PARTIDA.furnished(true,true);REF.start(s)
	return s
func stats(s: Dictionary,value: float) -> void:
	for key in REF.STATS:s.refuge.stats[key]=value
func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720);g.tick(0);await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/refugio-"+name+".png")
	if name=="horda":
		root.size=Vector2i(960,432);g.tick(0);await layout();await RenderingServer.frame_post_draw
		check(g.hud.usable_rect().encloses(g.hud.refuge.proceed.get_global_rect()),"Controle da horda permanece na tela larga do celular")
		root.get_texture().get_image().save_png("/tmp/refugio-horda-telefone.png")
		root.size=Vector2i(1280,720);g.tick(0);await layout()
func run():
	root.size=Vector2i(960,700);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
	check(await press("Novo jogo"),"Entrada jogável da nova premissa")
	var s: Dictionary = g.session.state
	check(REF.active(s) and s.refuge.residents.size()==3 and s.refuge.nextHorde==3,"Três moradores e primeira horda no terceiro dia")
	check(g.session.SAVE.VALIDATOR.valid(s) and g.values.has(g.session.checkpoint_key()),"Campanha começa válida e com retomada persistida")
	for worker in s.workers:worker.task="none"
	g.session.simulation.service.idle_walk_enabled=false
	await capture("inicio")
	check(not g.hud.refuge.visible and g.frame_data.refuge==null,"Status não aparecem durante a partida")
	check(await press("Gestão") and await press("Cidade"),"Acesso por Gestão → Cidade")
	check(g.frame_data.modal=="management" and g.session.tab=="city","Consulta das barras coletivas no menu")
	var time: float = s.time;g.tick(1);check(s.time==time,"Consulta pausa o preparo")
	check(await press("Voltar ao jogo"),"Retorno da consulta")
	# Keep the prior service regression on a legacy campaign; InicioUI covers the new menu.
	s=clone_campaign();g.session.load_state(s);g.tick(0)
	# Real cooking and service: the same survivor later appears in defense.
	await take("frango");await click_object("prep");advance(2.1)
	await click_object("stove");await take("arroz");await click_object("stove");await click_object("stove");advance(8.1)
	await click_object("stove");await click_object("kitchen");advance(2.1)
	await click_object("stove");await click_object("kitchen")
	check(held()=="dish_frangoArroz","Preparo original continua funcional no refúgio")
	g.session.ADMIN.test_clock(s,660)
	for recipe in s.menu:s.menu[recipe]=recipe=="frangoArroz"
	g.tick(0.05);s.arrival=0;await click_object("table")
	var sim = g.session.SIM.new();sim.service.random_source=func():return 0.0
	check(sim.spawn(s),"Morador entra na taverna")
	var old_food: float = s.refuge.stats.food
	g.session.ADMIN.test_clock(s,900);advance(6)
	await click_object("table");await click_object("table");advance(4.1)
	check(s.ledger.sales==1 and s.refuge.stats.food>old_food and s.refuge.stats.morale>65,"Refeição concluída alimenta e anima a comunidade")
	check(g.session.SAVE.VALIDATOR.valid(s),"Serviço mantém conservação e estado do refúgio válidos")
	var served_raw = g.session.SAVE.serialize(s)
	var served_copy = g.session.SAVE.new().load_value(JSON.parse_string(served_raw)) if served_raw is String else null
	check(served_copy!=null and served_copy.refuge.visits==s.refuge.visits,"Morador alimentado e registros do turno carregam juntos")
	await capture("alimentado")
	# Ordinary dinners remain available. There is no hidden daily attack.
	var ordinary := clone_campaign();ordinary.clock.minute=1080;g.session.ADMIN.auto_open(ordinary)
	check(ordinary.open and ordinary.period==1 and not REF.due(ordinary),"Primeiro dia mantém jantar")
	# No canceled-dinner drain; routine and sleep have bounded status effects.
	var horde := clone_campaign();horde.day=3;horde.clock.minute=1080
	var before: Dictionary = REF.collective(horde)
	REF.end_shift(horde,1);g.session.ADMIN.auto_open(horde)
	check(not horde.open and REF.collective(horde)==before,"Dia de horda suspende jantar sem penalizar status")
	REF.end_shift(horde,0);var once: Dictionary = REF.collective(horde);REF.end_shift(horde,0)
	check(REF.collective(horde)==once,"Fechar turno repetidamente não duplica perda de status")
	check(not g.session.ADMIN.finish_day(horde),"Não pula o ataque dormindo")
	# Victory unlocks a tangible kitchen improvement and one new resident.
	stats(horde,90);g.session.load_state(horde);g.tick(0.1)
	check(horde.refuge.phase=="battle","Alarme inicia defesa sem combate controlável")
	var world_time: float = horde.time;g.tick(2)
	check(horde.time==world_time and horde.refuge.battle.elapsed>0,"Batalha anima sem avançar serviço ou fome")
	await capture("horda")
	var raw = g.session.SAVE.serialize(horde)
	var restored = g.session.SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
	check(restored!=null and restored.refuge.battle.elapsed==horde.refuge.battle.elapsed,"Save retoma a animação e seu resultado calculado")
	if restored!=null:
		REF.battle_step(restored,8)
		check(restored.refuge.phase=="aftermath" and restored.refuge.nextHorde==7 and g.session.SAVE.VALIDATOR.valid(restored),"Batalha carregada conclui e agenda o próximo ataque sem erro de tipo")
	g.events.append({"kind":"refuge","action":"skip"});g.tick(0)
	check(horde.refuge.phase=="aftermath" and horde.refuge.level==1 and horde.refuge.residents.size()==4,"Vitória reconstrói oficina e acolhe um sobrevivente")
	check(REF.cut_time(horde)==1.6 and REF.cut_time(clone_campaign())==2,"Melhoria reduz o corte em vinte por cento")
	var level: int = horde.refuge.level;REF.resolve(horde)
	check(horde.refuge.level==level and horde.refuge.residents.size()==4,"Pular ou resolver novamente não duplica recompensa")
	await capture("vitoria")
	g.events.append({"kind":"refuge","action":"continue"});g.tick(0)
	check(horde.day==4 and horde.refuge.phase=="day" and horde.refuge.nextHorde==7,"Amanhecer preserva crescimento e agenda próxima horda em quatro dias")
	check(g.session.SAVE.VALIDATOR.valid(horde),"Estado após reconstrução pode ser salvo")
	await capture("reconstrucao")
	await take("legumes");await click_object("prep")
	check(horde.chopping!=null and horde.chopping.total==1.6 and g.session.SAVE.serialize(horde)!=null,"Ferramenta melhorada cria corte mais curto e salvável")
	advance(1.7);check(held()=="legumes_cut","Corte melhorado termina com ingrediente real nas mãos")
	# Two defeats, with a guaranteed playable checkpoint before preparation.
	var loss := clone_campaign();loss.day=3;loss.clock.minute=360;stats(loss,0)
	g.session.load_state(loss);g.session.checkpoint(true)
	var checkpoint_raw: String = g.session.values[g.session.checkpoint_key()]
	loss.clock.minute=1080;g.tick(0.1);g.tick(8.1)
	check(loss.refuge.phase=="aftermath" and loss.refuge.defeats==1 and loss.refuge.defense==45,"Primeira derrota recua e mantém uma chance")
	g.events.append({"kind":"refuge","action":"continue"});g.tick(0)
	loss.day=7;preload("res://simulacao/nativa/Mercado.gd").restock(loss);loss.clock.minute=360;g.session.checkpoint(true);loss.clock.minute=1080;g.tick(0.1);g.tick(8.1)
	check(loss.refuge.phase=="gameover" and loss.refuge.defeats==2,"Segunda derrota encerra a campanha")
	var day: int = loss.day;g.tick(100)
	check(loss.day==day and loss.refuge.defeats==2,"Game over não simula nem cobra novas consequências")
	check(g.session.SAVE.VALIDATOR.valid(loss),"Game over é um estado válido")
	await capture("recuo")
	g.session.save_game() # Even a manual save here must not destroy preparation.
	g.events.append({"kind":"refuge","action":"retry"});g.tick(0)
	check(g.session.state.day==7 and g.session.state.clock.minute==360 and g.session.state.refuge.defeats==1 and g.session.state.refuge.phase=="day","Retomada recupera a manhã anterior ao segundo ataque")
	check(g.session.values[g.session.checkpoint_key()]!=checkpoint_raw,"Backup acompanha a próxima fase de preparação")
	for patch in [{"food":101},{"morale":-1},{"energy":"alto"}]:
		var invalid := clone_campaign();invalid.refuge.stats.merge(patch,true)
		check(g.session.SAVE.serialize(invalid)==null,"Save rejeita status inválidos")
	var unattended := clone_campaign()
	for i in 2:
		unattended.clock={"minute":1560,"remainder":0,"ending":true}
		check(g.session.ADMIN.finish_day(unattended),"Dias comuns podem terminar normalmente")
	unattended.clock.minute=1080;unattended.clock.ending=false
	g.session.SIM.new().step(unattended,0.1)
	check(unattended.refuge.battle.result=="retreat","Ignorar todas as refeições deixa o primeiro ataque insuficientemente preparado")
	for field in ["wave","defeats","level"]:
		var invalid := clone_campaign();invalid.refuge[field]=1
		check(g.session.SAVE.serialize(invalid)==null,"Save recusa progressão inconsistente")
	var legacy: Dictionary = g.session.PARTIDA.furnished(true,true)
	check(g.session.SAVE.serialize(legacy)!=null and not REF.active(g.session.SAVE.new().load_value(legacy)),"Partidas antigas continuam carregando sem conversão forçada")
	var imported = g.session.get_script().new();imported.load_state(loss.duplicate(true))
	imported.refuge_action("retry")
	check(imported.modal=="welcome","Game over importado sem backup permite escolher outra partida")
	await finish()
