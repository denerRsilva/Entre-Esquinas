extends RefCounted
## Owns frame timing and pause policy. Legacy calls below only update controls,
## interaction queues and sound presentation until those views are replaced.
var evaluate: Callable
var ui_timer := 0.0
func _init(executor: Callable):evaluate=executor
func read(expression: String) -> Variant:return JSON.parse_string(evaluate.call("JSON.stringify("+expression+")"))
func frame(delta: float) -> void:
	evaluate.call("Host.clock+="+JSON.stringify(delta*1000,"",true,true))
	var context = read("({now:Host.clock,last,hidden:!!document.hidden,management:!!$('management').open,container:dialogMode==='container',welcome:!!$('welcome').open,construction:constructionMode,message:state.message})")
	var dt := maxf(0,(context.now-context.last)/1000)
	evaluate.call("last=Host.clock")
	if not context.hidden and (not context.management or context.container) and not context.welcome and not context.construction:
		var remaining := dt
		while remaining>1e-9:
			var slice := minf(0.08,remaining)
			evaluate.call("if(!$('management').open)keyboardMove();R.step(state,"+JSON.stringify(slice,"",true,true)+");processInteraction()")
			remaining=maxf(0,remaining-slice)
		if read("state.message")!=context.message:evaluate.call("$('notice').textContent=state.message;$('notice').style.opacity='1';noticeTime=Host.clock+4500")
		evaluate.call("kitchenSounds()")
		ui_timer+=dt
		if ui_timer>0.25:
			ui_timer=0
			evaluate.call("if($('management').open&&dialogMode==='container')renderDialog();else refresh()")
	evaluate.call("if(Host.clock>noticeTime)$('notice').style.opacity='0';updateCamera();positionActions()")
