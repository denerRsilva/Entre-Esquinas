extends Node
const STORE = "user://restaurante.json"
var session = preload("res://simulacao/nativa/SessaoCompleta.gd").new()
var events:Array=[]
var active:=false
var frame_data:Dictionary
var values:Dictionary={}
var focused := true
var view_size := Vector2.ZERO
var tone_cache: Dictionary = {}
@onready var hud=$HUD
@onready var palco=$Mapa/Palco

func _ready() -> void:
	values=read_values()
	session.initialize(values)
	hud.command.connect(queue_command)
	hud.import_save.connect(import_save)
	$Mapa.gui_input.connect(map_input)
	active=true
	get_viewport().size_changed.connect(resize_view)
	resize_view()
	tick(0)

func resize_view() -> void:
	var size := get_viewport().get_visible_rect().size
	if size.x<=0 or size.y<=0 or size==view_size:return
	view_size=size
	$Mapa.position=Vector2.ZERO
	$Mapa.size=size
	$HUD.size=size
	session.resize_view(size.x,size.y)
	# Resizing must also repaint menus, which normally suspend the game loop.
	if active:tick(0)

func saved_dictionary(path: String):
	if not FileAccess.file_exists(path): return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return null
	return parser.data if parser.data is Dictionary else null

func read_values() -> Dictionary:
	for path in [STORE,STORE+".bak"]:
		var saved = saved_dictionary(path)
		if saved is Dictionary: return saved
	return {}

func persist(next: Dictionary) -> bool:
	var file:=FileAccess.open(STORE+".tmp",FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify(next,"",true,true));file.flush()
	var err:=file.get_error()
	file.close()
	if err!=OK:return false
	if saved_dictionary(STORE) is Dictionary:
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(STORE),ProjectSettings.globalize_path(STORE+".bak"))!=OK:return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(STORE+".tmp"),ProjectSettings.globalize_path(STORE))==OK

func import_save(path:String) -> void:
	var raw:=FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	var loaded: Variant = null
	if parser.parse(raw)==OK:loaded=preload("res://simulacao/nativa/Salvamentos.gd").new().load_value(parser.data)
	if loaded==null:
		session.notify("Arquivo de salvamento inválido.",true)
		tick(0)
		return
	var next=values.duplicate()
	next["entre-partida-anterior"]=str(values.get(session.SAVE_KEY,""))
	next["entre-refugio-preparo-anterior"]=str(values.get(session.CHECKPOINT_KEY,""))
	next[session.SAVE_KEY]=raw
	next[session.CHECKPOINT_KEY]=""
	if persist(next):
		values=next
		session.values=values.duplicate(true)
		session.notify("Arquivo importado. Use Carregar jogo para continuar.")
	else: session.notify("Falha ao gravar o arquivo importado.",true)
	tick(0)

func toggle_fullscreen() -> void:
	var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func queue_command(e:Dictionary) -> void:
	if e.get("id","")=="fullscreenBtn":
		toggle_fullscreen();return
	events.append(e)

func tick(dt:float) -> void:
	var batch:=events.duplicate();events.clear()
	var packet:Dictionary=session.step(dt,batch)
	if packet.is_empty():
		active=false
		push_error("Falha de simulação na sessão nativa")
		$Erro.text="Falha ao iniciar a sessão nativa."
		$Erro.show()
		return
	frame_data=packet
	if not packet.writes.is_empty():
		var next:=values.duplicate();next.merge(packet.writes,true)
		if persist(next):values=next
		else:
			session.values=values.duplicate(true)
			session.notify("Não foi possível gravar o salvamento no disco.",true)
	palco.paint(packet)
	hud.sync(packet)
	for frequency in packet.sounds: play_tone(frequency)

func play_tone(hz:float) -> void:
	if tone_cache.has(hz):
		$Sinais.stream = tone_cache[hz]
		if DisplayServer.get_name() != "headless": $Sinais.play()
		return
	var wave:=AudioStreamWAV.new()
	wave.mix_rate=16000;wave.format=AudioStreamWAV.FORMAT_16_BITS
	var samples:=PackedByteArray();samples.resize(6400)
	for i in 3200:
		samples.encode_s16(i*2,int(1400*sin(TAU*i*hz/16000.0)*exp(-float(i)/820.0)))
	wave.data=samples
	tone_cache[hz] = wave
	$Sinais.stream=wave
	if DisplayServer.get_name() != "headless": $Sinais.play()

func _process(delta:float) -> void:
	if not active or not focused:return
	if events.is_empty() and frame_data.get("modal","")!="" and not frame_data.get("liveInventory",false):return
	# Update on every rendered frame; a timer threshold can skip alternating
	# frames when the monitor delta is slightly below 1/60 second.
	tick(delta)

func map_input(event:InputEvent) -> void:
	if not active or frame_data.get("modal","")!="":return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		var point:Vector2=event.position+$Mapa.position
		events.append({"kind":"pointer","phase":"down" if event.pressed else "up","x":point.x,"y":point.y})
	elif event is InputEventMouseMotion and frame_data.get("construction",false):
		var point:Vector2=event.position+$Mapa.position
		var e={"kind":"pointer","phase":"move","drag":bool(event.button_mask&MOUSE_BUTTON_MASK_LEFT),"x":point.x,"y":point.y}
		if not events.is_empty() and events.back().get("phase")=="move":events.pop_back()
		events.append(e)

func _input(event:InputEvent) -> void:
	if not active or not event is InputEventKey or event.echo:return
	if event.keycode==KEY_F11 and event.pressed:
		toggle_fullscreen();return
	var editing := get_viewport().gui_get_focus_owner() is LineEdit
	if editing and event.pressed and event.keycode != KEY_ESCAPE:return
	var names={KEY_UP:"arrowup",KEY_DOWN:"arrowdown",KEY_LEFT:"arrowleft",KEY_RIGHT:"arrowright",KEY_ESCAPE:"escape",KEY_W:"w",KEY_S:"s",KEY_A:"a",KEY_D:"d",KEY_E:"e",KEY_R:"r"}
	if names.has(event.keycode):
		events.append({"kind":"key","key":names[event.keycode],"down":event.pressed})

func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and active:
		focused = false
		events.clear()
		session.focus(false)
		palco.pause_actors()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN and active:
		focused = true
		session.focus(true)

func _exit_tree() -> void:
	$Sinais.stop()
	$Sinais.stream = null
	tone_cache.clear()
