extends RefCounted
## Event routing belongs to Godot. Calls into legacy actions are temporary
## endpoints; the routing policy is no longer duplicated in JavaScript.
var execute: Callable

func _init(executor: Callable):
	execute = executor

func query(expression: String) -> Variant:
	return JSON.parse_string(execute.call("JSON.stringify(("+expression+")??null)"))

func dispatch(event: Dictionary) -> void:
	match event.get("kind",""):
		"widget": widget(event)
		"pointer": pointer(event)
		"key": keyboard(event)
		"blur": execute.call("releaseKeyboard()")

func widget(event: Dictionary) -> void:
	var path := JSON.stringify(str(event.get("path","")))
	var info = query("(()=>{const w=Host.widgets.get("+path+");return w?{tag:w.tag,disabled:!!w.disabled}:null})()")
	if not info is Dictionary or info.disabled:return
	if info.tag=="button":
		execute.call("Host.widgets.get("+path+").click()")
	else:
		var value := JSON.stringify(event.get("value"))
		execute.call("(()=>{const w=Host.widgets.get("+path+");w.value="+value+";w.checked="+value+";w.onchange?.()})()")

func pointer(event: Dictionary) -> void:
	var phase: String = str(event.get("phase",""))
	if phase not in ["down","move","up","cancel"]:return
	if query("$('welcome').open||$('management').open"):return
	var x := float(event.get("x",0))
	var y := float(event.get("y",0))
	if not is_finite(x) or not is_finite(y):return
	var data := {"clientX":x,"clientY":y,"buttons":1 if event.get("drag",false) else 0,"pointerId":1,"pointerType":"mouse"}
	execute.call("canvas["+JSON.stringify("onpointer"+phase)+"]?.("+JSON.stringify(data)+")")

func keyboard(event: Dictionary) -> void:
	var key := str(event.get("key",""))
	var down := bool(event.get("down",false))
	if key=="escape" and down and query("$('management').open"):
		execute.call("$('management').close()")
		return
	var signal_name := "keydown" if down else "keyup"
	execute.call("document.emit("+JSON.stringify(signal_name)+",{key:"+JSON.stringify(key)+",repeat:false,preventDefault(){}})")
