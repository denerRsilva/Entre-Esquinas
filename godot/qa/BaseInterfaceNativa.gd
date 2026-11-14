extends "res://qa/BaseNativa.gd"
var g
func layout():
	for i in 8:await process_frame
func start_game() -> void:
	root.size=Vector2i(960,700);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
	await press("Começar na taverna")
func press(title: String) -> bool:
	await layout()
	for control in g.hud.find_children("*","Button",true,false):
		if control.is_visible_in_tree() and not control.disabled and (control.text==title or control.tooltip_text==title):
			control.emit_signal("pressed");g.tick(0);await layout();return true
	return false
func widget(path: String,value: Variant = null) -> void:g.events.append({"kind":"widget","path":path,"value":value});g.tick(0)
func advance(seconds: float) -> void:
	for i in int(ceil(seconds/0.05)):g.tick(0.05)
func click_object(type: String) -> void:
	var target: Variant = null
	for object in g.session.state.objects:
		if object.type==type:target=object;break
	if target==null:check(false,"Objeto "+type+" existe");return
	var point: Dictionary = g.session.CAMERA.screen_point(target.x*40+20,target.y*40+20,g.session.rect,g.session.viewport,g.session.camera)
	g.events.append({"kind":"pointer","phase":"down","x":point.x,"y":point.y});g.events.append({"kind":"pointer","phase":"up","x":point.x,"y":point.y});g.tick(0)
	for i in 300:
		g.tick(0.05)
		if g.session.pending==null and g.session.state.player.get("motion")==null and (g.session.state.player.get("goal")==null or g.session.MOVE.arrived(g.session.state.player)):break
	await layout()
func take(food: String) -> void:
	await click_object("fridge")
	var fridge: Variant = null
	for object in g.session.state.objects:
		if object.type=="fridge":fridge=object;break
	var index := -1
	for i in fridge.inventory.size():
		if fridge.inventory[i]!=null and fridge.inventory[i].item==food:index=i;break
	widget("nativo:retirar:"+str(int(fridge.id))+":"+str(index));await layout()
func finish() -> void:
	print("FALHAS: ",failures);g.queue_free();await process_frame;quit(1 if failures else 0)
