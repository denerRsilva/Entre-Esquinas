extends SceneTree
## Diagnostic timings, not absolute performance assertions tied to one machine.
var game
func _initialize():call_deferred("run")
func js(code:String)->String:return RestauranteVM.executar(code)
func measure(label:String,code:String):
	var start:=Time.get_ticks_usec()
	js(code)
	print(label,": ",(Time.get_ticks_usec()-start)/1000.0," ms")
func run():
	game=load("res://mundo/Restaurante.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	await process_frame
	measure("Furnished rules","globalThis.benchState=R.furnishedTest()")
	var start:=Time.get_ticks_usec()
	js("$('startFurnishedBtn').click()")
	game.tick(0)
	print("Furnished UI: ",(Time.get_ticks_usec()-start)/1000.0," ms")
	js("enterConstruction();beginBuild('chair')")
	game.tick(0)
	var samples:=[]
	var rendered:=[]
	for i in 12:
		start=Time.get_ticks_usec()
		game.queue_command({"kind":"pointer","phase":"move","x":100+i*40,"y":340,"drag":false})
		game.tick(1.0/60.0)
		samples.append((Time.get_ticks_usec()-start)/1000.0)
		if "--render" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			rendered.append((Time.get_ticks_usec()-start)/1000.0)
	print("Preview CPU ms: ",samples)
	if not rendered.is_empty():print("Preview including render ms: ",rendered)
	measure("Repeated validation x10","for(let i=0;i<10;i++)previewError({type:'chair',room:'restaurant',x:2,y:7,rot:0})")
	game.queue_free();await process_frame;quit()
