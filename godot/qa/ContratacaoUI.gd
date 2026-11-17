extends "res://qa/CidadeUI.gd"
const HIRE = preload("res://simulacao/nativa/Contratacao.gd")
func run():
	await start_game();g.session.root_action("refuge");g.tick(0)
	var s: Dictionary = g.session.state
	check(s.workers.is_empty() and s.refuge.hiring.hires.is_empty(),"Campanha nova começa sem funcionário")
	check(not g.frame_data.scene.any(func(op):return op[0]=="npc" and op[1]=="worker2"),"Garçom inicial não aparece no salão")
	check(g.session.SAVE.serialize(s)!=null,"Início sem funcionário pode ser salvo")
	await press("Gestão");await press("Equipe")
	var content := JSON.stringify(g.frame_data.ui.modal)
	check(content.contains("primeira vaga") and not content.contains("Procurar contratação"),"Equipe informa a conquista sem oferecer contratação antecipada")
	var cash: float = s.cash
	check(not HIRE.hire(s,4).ok and s.cash==cash and s.workers.is_empty(),"Não contrata antes do crescimento da cidade")
	await screenshot("bloqueada");await press("Voltar ao jogo")
	attack(s,95);g.tick(0)
	g.events.append({"kind":"refuge","action":"continue"});g.tick(0)
	check(s.refuge.residents.size()==4 and HIRE.unlocked(s) and s.workers.is_empty(),"Chegada do quarto morador libera vaga sem contratar automaticamente")
	await press("Gestão");await press("Equipe")
	check(await press("Procurar contratação"),"Jogador procura pessoas disponíveis")
	check(JSON.stringify(g.frame_data.ui.modal).contains("Contratar Íris"),"Primeiro novo habitante pode ser escolhido")
	await screenshot("candidatos")
	await screenshot("telefone",Vector2i(2340,1080))
	s.cash=HIRE.HIRE_COST-1;var before := JSON.stringify(s)
	check(not HIRE.hire(s,4).ok and JSON.stringify(s)==before,"Contratação sem saldo não cobra nem cria ator")
	s.cash=cash;g.tick(0)
	var visiting: Dictionary = s.duplicate(true)
	visiting.customers.append({"refugeResident":4})
	check(not HIRE.hire(visiting,4).ok and visiting.cash==s.cash,"Aguarda visita terminar para não duplicar a pessoa")
	check(await press("Contratar Íris"),"Contratação funciona pelo botão nativo")
	check(s.workers.size()==1 and s.workers[0].task=="waiter" and s.workers[0].refugeResident==4 and s.cash==cash-HIRE.HIRE_COST,"Contrata a pessoa escolhida e desconta uma única vez")
	check(s.refuge.hiring.hires.size()==1 and HIRE.employed(s,4),"Registro vincula morador, função e funcionário")
	var paid: float = s.cash
	check(not HIRE.hire(s,4).ok and s.cash==paid and s.workers.size()==1,"Não duplica vaga nem cobrança")
	check(reload(s)!=null,"Pessoa e função contratadas persistem")
	check(not g.session.UI_COMMAND.execute(s,"task",["worker2","logistics"]).ok and s.workers[0].task=="waiter","Não atribui função que ainda não foi desbloqueada")
	await screenshot("equipe")
	g.session.UI_COMMAND.execute(s,"task",["worker2","none"])
	var paused = reload(s)
	check(paused!=null and paused.workers[0].task=="none","Pausa voluntária do contratado persiste")
	if paused!=null:
		g.session.load_state(paused);g.tick(0)
		check(g.session.state.workers[0].task=="none","Carregar não reativa contratado pausado")
	await press("Voltar ao jogo")
	g.session.load_state(s);g.session.UI_COMMAND.execute(s,"task",["worker2","waiter"]);g.tick(0)
	# The recruited resident cannot also spawn as a dining guest.
	for person in s.refuge.residents:
		if person.id!=4:s.refuge.visits.append(REF.visit_key(s,person.id))
	check(REF.next_resident(s)==null,"Funcionário não aparece simultaneamente como cliente")
	s.refuge.visits=[]
	var simulation = g.session.SIM.new();simulation.service.random_source=func():return 0.0
	check(simulation.spawn(s),"Morador chega para testar o serviço contratado")
	var saw_progress := false
	for i in 800:
		simulation.step(s,0.05)
		if s.workers[0].get("noteJob")!=null:saw_progress=true
		if s.customers[0].state=="ordered":break
	check(saw_progress and s.customers[0].state=="ordered" and s.orders.size()==1,"Contratado caminha e anota pedido com progresso real")
	check(g.session.SAVE.serialize(s)!=null,"Atendimento pelo contratado conserva estado válido")
	# More inhabitants produce more choices; the choice changes the actor.
	var choice := clone_campaign();attack(choice,95);attack(choice,95);REF.continue_day(choice);g.session.ADMIN.finish_day(choice)
	check(HIRE.candidates(choice).map(func(p):return p.id)==[4,5],"Lista cresce com os habitantes disponíveis")
	check(HIRE.hire(choice,5).ok and choice.workers[0].refugeResident==5,"Pode escolher outra pessoa entre os candidatos")
	check(reload(choice)!=null,"Escolha alternativa pode ser salva")
	var cleaned: Dictionary = choice.duplicate(true)
	check(g.session.UI_COMMAND.execute(cleaned,"clear",[]).ok and cleaned.workers.size()==1 and cleaned.refuge.hiring.hires[0].resident==5 and reload(cleaned)!=null,"Limpar cenário de teste mantém contratação sem criar funcionário gratuito")
	var empty := clone_campaign();g.session.UI_COMMAND.execute(empty,"clear",[])
	check(empty.workers.is_empty() and reload(empty)!=null,"Limpar teste antes de contratar mantém início sem funcionário")
	# Already existing workers, pause and dirty plates survive an old save.
	var old: Dictionary = load("res://qa/referencia-refugio-v1.json").data.initial.duplicate(true)
	old.workers[0].task="none";old.workers[0].carry={"kind":"dirtyPlates","n":3};old.equipment.plate+=3
	var migrated = g.session.SAVE.new().load_value(old)
	check(migrated!=null and migrated.workers.size()==1 and migrated.workers[0].carry.n==3 and migrated.workers[0].task=="none","Migração preserva trabalhador antigo, pausa e louça em trânsito")
	if migrated!=null:check(migrated.refuge.hiring.hires[0].legacy and reload(migrated)!=null,"Funcionário antigo é reconhecido sem nova cobrança")
	for corruption in ["role","duplicate","missingActor","resident","customer"]:
		var invalid: Dictionary = choice.duplicate(true)
		match corruption:
			"role":invalid.refuge.hiring.hires[0].role="chef"
			"duplicate":invalid.refuge.hiring.hires.append(invalid.refuge.hiring.hires[0].duplicate(true))
			"missingActor":invalid.workers=[]
			"resident":invalid.refuge.hiring.hires[0].resident=1
			"customer":invalid.customers.append(null)
		check(g.session.SAVE.serialize(invalid)==null,"Save rejeita contratação inválida: "+corruption)
	await finish()
func screenshot(name: String,size: Vector2i = Vector2i(1280,720)) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=size;g.tick(0);await layout();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/contratacao-"+name+".png")
