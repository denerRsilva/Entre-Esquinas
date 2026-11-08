extends Node
const STORE = "user://restaurante.json"
const SCRIPTS = ["apresentacao","restaurant-core","comidas","cenografia","acoes","sessao"]
var events:Array=[]
var active:=false
var frame_data:Dictionary
var values:Dictionary={}
var focused := true
var tone_cache: Dictionary = {}
@onready var hud=$HUD
@onready var palco=$Mapa/Palco

func _ready() -> void:
	RestauranteVM.executar("@nova-sessao")
	var layout=FileAccess.get_file_as_string("res://simulacao/interface-base.json")
	RestauranteVM.executar("const InterfaceBase="+layout)
	values=read_values()
	for source in SCRIPTS:
		var code=FileAccess.get_file_as_string("res://simulacao/"+source+".js")
		RestauranteVM.executar(code)
		if source=="apresentacao": RestauranteVM.executar("Host.values="+JSON.stringify(values))
	hud.command.connect(queue_command)
	hud.import_save.connect(import_save)
	$Mapa.gui_input.connect(map_input)
	active=true
	tick(0)

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
	file.store_string(JSON.stringify(next));file.flush()
	var err:=file.get_error()
	file.close()
	if err!=OK:return false
	if saved_dictionary(STORE) is Dictionary:
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(STORE),ProjectSettings.globalize_path(STORE+".bak"))!=OK:return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(STORE+".tmp"),ProjectSettings.globalize_path(STORE))==OK

func import_save(path:String) -> void:
	var raw:=FileAccess.get_file_as_string(path)
	var valid:String=RestauranteVM.executar("(()=>{try{return Boolean(R.migrateSave(JSON.parse("+JSON.stringify(raw)+")))}catch{return false}})()")
	if valid!="true":
		RestauranteVM.executar("tell('Arquivo de salvamento inválido.',true)")
		tick(0)
		return
	var next=values.duplicate()
	next["entre-restaurante-10"]=raw
	if persist(next):
		values=next
		RestauranteVM.executar("Host.values="+JSON.stringify(values)+";tell('Arquivo importado. Use Carregar restaurante para continuar.')")
	else: RestauranteVM.executar("tell('Falha ao gravar o arquivo importado.',true)")
	tick(0)

func queue_command(e:Dictionary) -> void:
	if e.get("id","")=="mercearia":
		var path:="user://mercearia-0.8.8.html"
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file:
			file.store_string(FileAccess.get_file_as_string("res://historico/mercearia-0.8.8.html"))
			file.close()
			OS.shell_open(ProjectSettings.globalize_path(path))
		return
	if e.get("id","")=="fullscreenBtn":
		var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	events.append(e)

func tick(dt:float) -> void:
	var batch:=events.duplicate();events.clear()
	var result:String=RestauranteVM.executar("snapshot("+str(dt)+","+JSON.stringify(batch)+")")
	var packet=JSON.parse_string(result)
	if not packet is Dictionary:
		active=false
		push_error("Falha de simulação: "+result)
		$Erro.text="Falha ao iniciar a simulação. "+result
		$Erro.show()
		return
	frame_data=packet
	if not packet.writes.is_empty():
		var next:=values.duplicate();next.merge(packet.writes,true)
		if persist(next):values=next
		else:RestauranteVM.executar("Host.values="+JSON.stringify(values)+";tell('Não foi possível gravar o salvamento no disco.',true)")
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
	var editing := get_viewport().gui_get_focus_owner() is LineEdit
	if editing and event.pressed and event.keycode != KEY_ESCAPE:return
	var names={KEY_UP:"arrowup",KEY_DOWN:"arrowdown",KEY_LEFT:"arrowleft",KEY_RIGHT:"arrowright",KEY_ESCAPE:"escape",KEY_W:"w",KEY_S:"s",KEY_A:"a",KEY_D:"d",KEY_E:"e",KEY_I:"i",KEY_R:"r"}
	if names.has(event.keycode):
		events.append({"kind":"key","key":names[event.keycode],"down":event.pressed})

func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and active:
		focused = false
		events.clear()
		RestauranteVM.executar("document.hidden=true;releaseKeyboard()")
		palco.pause_actors()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN and active:
		focused = true
		RestauranteVM.executar("document.hidden=false")

func _exit_tree() -> void:
	$Sinais.stop()
	$Sinais.stream = null
	tone_cache.clear()
