extends SceneTree
## Run in an isolated Godot user-data directory because the smoke test saves a game.
var failures:=0
var g
func _initialize():call_deferred("run")

func check(ok:bool,msg:String) -> void:
	if ok: print("OK  ",msg)
	else: failures+=1;push_error(msg)

func js(code:String) -> String:return RestauranteVM.executar(code)

func test_source(name:String) -> void:
	var s=FileAccess.get_file_as_string("res://qa/regras/"+name+".test.cjs")
	var result=js("(function(){"+s+";return 'PASSOU'})()")
	check(result=="PASSOU",name+" / "+result.left(120))

func press_named(text:String) -> bool:
	for b in g.hud.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and b.text==text and not b.disabled:
			b.pressed.emit()
			g.tick(0)
			return true
	return false

func run():
	g=load("res://mundo/Restaurante.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	await process_frame
	check(g.active,"Cena principal iniciou")
	check(g.hud.z_index==4096,"Interface acima de todos os móveis")
	check(g.palco.get_node("Salao/Piso").get_used_cells().size()==200,"200 células na taverna sem estoque")
	check(press_named("Tutorial") and press_named("Fechar tutorial"),"Tutorial abre e recolhe")
	check(press_named("Começar na taverna"),"Entrada mobiliada pelo botão nativo")
	check(js("R.valid(state)")=="true","Estado inicial válido")
	check(g.palco.pool["cozinheira"][0] is AnimatedSprite2D,"Cozinheira em AnimatedSprite2D")
	check(press_named("Gestão") and press_named("Modo construção"),"Gestão abre construção")
	var paused=js("state.time")
	g.tick(1.0)
	check(js("state.time")==paused and not g.hud.slots.dock[0].visible,"Construção pausa e recolhe HUD")
	check(press_named("Construção") and press_named("Voltar ao jogo"),"Catálogo abre e retorna")
	check(js("state.inventory.length===0")=="true" and not g.hud.slots.has("hotbar"),"Sem mochila e sem barra")
	check(press_named("Opções") and press_named("Salvar e carregar"),"Salvar/carregar acessível")
	var original_cash=js("state.cash")
	check(press_named("Salvar restaurante"),"Salvar pelo botão nativo")
	js("state.cash=1")
	check(press_named("Carregar restaurante") and js("state.cash")==original_cash,"Carregar restaura o caixa")
	check(press_named("Voltar ao jogo"),"Retorno do menu")
	var legacy=FileAccess.get_file_as_string("res://qa/regras/restaurant-core-0.12.0.cjs")
	js("globalThis.OldRules=(function(){const module={exports:{}};"+legacy+";return module.exports})();globalThis.Restaurant=R;")
	js("globalThis.console={log(){}};globalThis.structuredClone=x=>JSON.parse(JSON.stringify(x));globalThis.require=k=>k.includes('assert')?checkAssert:k.includes('legacy')?OldRules:R;function checkAssert(b,msg){if(!b)throw Error(msg||'assert')};checkAssert.equal=(a,b)=>checkAssert(a===b,'equal: '+a+' / '+b);checkAssert.notEqual=(a,b)=>checkAssert(a!==b);checkAssert.deepEqual=(a,b)=>checkAssert(JSON.stringify(a)===JSON.stringify(b),'deepEqual')")
	for name in [] if "--rapido" in OS.get_cmdline_user_args() or "--regressoes" in OS.get_cmdline_user_args() else ["arrivals","service-hours"]:
		test_source(name)
	var flows=FileAccess.get_file_as_string("res://qa/percursos.js")
	if "--percursos-antigos" in OS.get_cmdline_user_args():
		check(js("(function(){"+flows+";return 'PASSOU'})()")=="PASSOU","Percursos integrados de jogo")
	g.tick(0)
	# A slow frame must advance the same amount of game time, not silently drop it.
	js("state=R.furnishedTest();constructionMode=false;$('management').close();$('welcome').close();document.hidden=false;releaseKeyboard()")
	g.tick(0)
	var before := float(js("state.time"))
	g._process(0.8)
	check(absf(float(js("state.time"))-before-0.8)<0.001,"Quadro lento preserva 0,8 s de simulação")
	var actor: AnimatedSprite2D = g.palco.pool["cozinheira"][0]
	actor.play("baixo")
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not actor.is_playing(),"Perda de foco pausa animações")
	before = float(js("state.time"))
	g._process(2.0)
	check(float(js("state.time"))==before,"Sem avanço enquanto janela sem foco")
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	g._process(0.1)
	check(absf(float(js("state.time"))-before-0.1)<0.001,"Retorno de foco não acumula tempo oculto")
	var edit := LineEdit.new()
	g.hud.add_child(edit)
	edit.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_I
	key.pressed = true
	g._input(key)
	check(g.events.is_empty(),"Editar campo não dispara atalho do inventário")
	edit.release_focus()
	edit.queue_free()
	g.play_tone(440)
	var tone = g.get_node("Sinais").stream
	g.play_tone(440)
	check(g.get_node("Sinais").stream==tone,"Alerta sonoro reutiliza áudio gerado")
	check(g.active,"Último quadro processado sem falha")
	print("FALHAS: ",failures)
	g.get_node("Sinais").stop()
	g.get_node("Sinais").stream = null
	g.tone_cache.clear()
	tone = null
	g.queue_free()
	await process_frame
	g = null
	await create_timer(0.1).timeout
	quit(1 if failures else 0)
