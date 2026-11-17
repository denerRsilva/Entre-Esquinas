extends "res://qa/BaseInterfaceNativa.gd"
const SESSION = preload("res://simulacao/nativa/SessaoCompleta.gd")
func buttons() -> Array:
	return g.hud.find_children("*","Button",true,false).filter(func(b):return b.is_visible_in_tree())
func snapshot(name: String,size: Vector2i) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	root.mode=Window.MODE_WINDOWED;root.size=size;g.tick(0);await layout();await RenderingServer.frame_post_draw
	for b in buttons():check(g.hud.usable_rect().encloses(b.get_global_rect()),"Botão dentro da tela: "+b.text)
	root.get_texture().get_image().save_png("/tmp/menu-unico-"+name+".png")
func run():
	root.size=Vector2i(1280,720);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
	check(buttons().map(func(b):return b.text)==["Novo jogo","Carregar jogo"],"Tela inicial tem apenas as duas opções solicitadas")
	check(buttons()[1].disabled,"Carregar sem progresso está desabilitado")
	await snapshot("inicio",Vector2i(1280,720))
	await snapshot("telefone",Vector2i(960,432))
	check(await press("Novo jogo") and g.frame_data.modal=="" and g.session.REFUGE.active(g.session.state) and g.session.state.workers.is_empty(),"Novo jogo abre diretamente refúgio sem funcionário")
	check(g.values.has(SESSION.SAVE_KEY) and g.values.has(SESSION.CHECKPOINT_KEY) and not g.values.has("entre-partida-1"),"Partida nova salva em uma única chave e mantém preparação interna")
	g.session.state.cash=321;g.session.save_game();g.tick(0)
	var saved: String = g.values[SESSION.SAVE_KEY]
	g.session.root_action("welcome");g.tick(0)
	check(await press("Novo jogo") and g.session.modal=="confirmNew" and g.values[SESSION.SAVE_KEY]==saved,"Novo jogo pede confirmação sem alterar salvamento")
	await snapshot("confirmacao",Vector2i(960,432))
	check(await press("Voltar") and g.values[SESSION.SAVE_KEY]==saved,"Voltar preserva progresso")
	check(await press("Carregar jogo") and g.session.modal=="" and g.session.state.cash==321,"Carregar na tela inicial restaura e fecha menu")
	g.session.open_dialog("options");g.session.tab="save";g.session.generation+=1;g.tick(0)
	var content := JSON.stringify(g.frame_data.ui.modal)
	check(content.contains("Salvar jogo") and content.contains("Carregar jogo") and not content.contains("Partida 2") and not content.contains("Partida 3"),"Opções não oferecem seleção de slots")
	await snapshot("salvamento",Vector2i(960,432))
	var restarted = SESSION.new();restarted.initialize(g.read_values());restarted.root_action("loadStart")
	check(restarted.modal=="" and restarted.state.cash==321,"Reabrir sessão carrega progresso gravado no disco")
	g.session.root_action("welcome");g.tick(0);await press("Novo jogo");await press("Começar novo jogo")
	check(g.session.state.day==1 and g.session.state.cash==200 and g.values["entre-partida-anterior"]==saved,"Confirmação substitui a partida e conserva cópia de segurança")
	var checkpoint: String = g.values[SESSION.CHECKPOINT_KEY]
	check(JSON.parse_string(checkpoint).cash==200,"Novo jogo não reutiliza preparação da campanha anterior")
	g.session.root_action("welcome");g.tick(0)
	check(buttons().map(func(b):return b.text)==["Novo jogo","Carregar jogo"] and not buttons()[1].disabled,"Tela com progresso continua mostrando só duas opções")
	# Legacy migration: active slot wins, all historical bytes remain untouched.
	var old: Dictionary = g.session.PARTIDA.furnished(true,true)
	var raw: Array = []
	for amount in [111,222,333]:
		old.cash=amount;raw.append(g.session.SAVE.serialize(old))
	var previous := {"entre-partida-1":raw[0],"entre-partida-2":raw[1],"entre-partida-3":raw[2],"entre-slot-ativo":"2","entre-refugio-preparo-2":checkpoint}
	var migrated = SESSION.new();migrated.initialize(previous)
	check(migrated.values[SESSION.SAVE_KEY]==raw[1] and migrated.values[SESSION.CHECKPOINT_KEY]==checkpoint,"Migra a partida ativa e o backup correspondente")
	check(previous.keys().all(func(k):return migrated.values[k]==previous[k]),"Migração não apaga nem modifica partidas antigas")
	var packet: Dictionary = migrated.step(0,[])
	check(packet.writes.get(SESSION.SAVE_KEY)==raw[1],"Migração é enviada à persistência antes de jogar")
	migrated.root_action("loadStart");check(migrated.state.cash==222,"Carrega slot legado escolhido para o espaço único")
	var again = SESSION.new();again.initialize(migrated.values)
	check(not again.writes.has(SESSION.SAVE_KEY),"Migração não se repete nem substitui o slot único")
	var fallback = SESSION.new();fallback.initialize({"entre-slot-ativo":"3","entre-partida-3":"{invalid","entre-partida-1":raw[0]})
	check(fallback.values[SESSION.SAVE_KEY]==raw[0],"Slot ativo inválido usa a primeira partida antiga válida")
	var alias = SESSION.new();alias.initialize({"entre-restaurante-12":raw[2]});alias.root_action("loadStart")
	check(alias.state.cash==333 and alias.values["entre-restaurante-12"]==raw[2],"Formato anterior sem slots continua compatível")
	var invalid = SESSION.new();invalid.initialize({SESSION.SAVE_KEY:"{invalid","entre-partida-1":raw[0]})
	var before: Dictionary = invalid.state.duplicate(true);before.erase("message");invalid.root_action("loadStart")
	var after: Dictionary = invalid.state.duplicate(true);after.erase("message")
	check(invalid.modal=="welcome" and JSON.stringify(after)==JSON.stringify(before) and JSON.stringify(invalid.ui()).contains("Não foi possível carregar"),"Save único inválido informa erro e preserva estado sem importar outra campanha")
	invalid.root_action("newGame");check(invalid.modal=="confirmNew","Save inválido também exige confirmação para substituição")
	var header = SESSION.new();header.initialize({SESSION.SAVE_KEY:'{"day":[]}'})
	header.open_dialog("options");header.tab="save"
	check(JSON.stringify(header.ui()).contains("Salvamento inválido"),"Resumo de arquivo malformado não derruba menu de salvamento")
	await finish()
