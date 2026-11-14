extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false)
	g.session.root_action("furnished");g.tick(0)
	await process_frame
	var s: Dictionary = g.session.state
	if "--bancadas" in OS.get_cmdline_user_args():
		for x in range(15,23):g.session.PARTIDA.add_object(s,"counterCorner",x,13,1)
	var stove: Dictionary
	for o in s.objects:
		if o.type=="stove":stove=o
	stove.pan="cookingPot"
	s.cooking={"stove":stove.id,"recipe":"frangoArroz","servings":1,"quality":0,"left":100,"total":100}
	var totals := [0.0,0.0,0.0];var peak_nodes := 0
	for i in 240:
		var t:=Time.get_ticks_usec();var packet: Dictionary=g.session.step(1.0/60,[]);totals[0]+=Time.get_ticks_usec()-t
		t=Time.get_ticks_usec();g.palco.paint(packet);totals[1]+=Time.get_ticks_usec()-t
		t=Time.get_ticks_usec();g.hud.sync(packet);totals[2]+=Time.get_ticks_usec()-t
		peak_nodes=maxi(peak_nodes,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		await process_frame
	print("PROFILE ms/frame simulation,world,HUD: ",Vector3(totals[0],totals[1],totals[2])/240000.0," peak_nodes: ",peak_nodes)
	g.queue_free();await process_frame;quit()
