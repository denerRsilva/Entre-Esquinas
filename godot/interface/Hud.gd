extends Control
signal command(event: Dictionary)
const Builder = preload("res://interface/CatalogoUI.gd")
var builder = Builder.new()
var slots := {}
var cache := {}
var by_id := {}
var modal_background: ColorRect
var import_dialog: FileDialog
signal import_save(path:String)
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	builder.send=func(e): command.emit(e)
	area("hud",Rect2(8,5,940,47),false,false)
	area("ordersHud",Rect2(710,74,245,170))
	area("kitchenStatus",Rect2(8,74,320,120))
	area("openBtn",Rect2(0,0,100,38),false,false)
	area("context",Rect2(150,360,500,110),false,false)
	area("hint",Rect2(10,604,610,42),false,true)
	area("notice",Rect2(10,500,520,70),false,true)
	area("dock",Rect2(10,647,550,48),false,false)
	area("actions",Rect2(720,641,234,54),false,false)
	area("catalog",Rect2(10,649,168,44),false,false)
	area("drawer",Rect2(7,7,440,628))
	area("build",Rect2(188,615,762,80),false)
	modal_background=ColorRect.new()
	modal_background.color=Color(0.03,0.07,0.055,0.68)
	modal_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_background)
	area("modal",Rect2(58,44,844,612))
	import_dialog=FileDialog.new()
	import_dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.access=FileDialog.ACCESS_FILESYSTEM
	import_dialog.filters=PackedStringArray(["*.json ; Salvamento do restaurante"])
	import_dialog.file_selected.connect(func(path):import_save.emit(path))
	add_child(import_dialog)

func area(key:String,rect:Rect2,scrollable:=true,boxed:=true) -> void:
	var overlay := key in ["hint","notice"]
	var root:Control = Control.new() if overlay else PanelContainer.new() if boxed else MarginContainer.new()
	if overlay:
		root.clip_contents = true
		var background := ColorRect.new()
		background.color = Color(0.04,0.10,0.07,0.92)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(background)
	if key=="context": root.clip_contents=true
	root.position=rect.position
	root.size=rect.size
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE if key in ["hint","notice","hud","context"] else Control.MOUSE_FILTER_STOP
	add_child(root)
	var parent:Control=root
	if scrollable:
		var scroll:=ScrollContainer.new()
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		root.add_child(scroll)
		parent=scroll
	var content:=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if key in ["hud","hint","notice","context"]: content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(content)
	if overlay:
		content.position = Vector2(6,3)
		content.size = rect.size-Vector2(12,6)
	slots[key]=[root,content,rect]
	root.hide()

func sync(data: Dictionary) -> void:
	modal_background.visible = data.modal!=""
	for key in slots:
		var entry:Array=slots[key]
		var root:Control=entry[0]
		var item=data.ui.get(key)
		root.visible=item!=null and (item.has("path") or not item.get("children",[]).is_empty())
		if key=="context" and root.visible: root.visible=not item.children.is_empty()
		if not root.visible: continue
		if key=="context" and item.get("children",[]).size()>0:
			var anchor:Dictionary=item.children[0].get("anchor",{})
			if not anchor.is_empty():
				var cam:Array=data.camera
				var anchor_y := (float(anchor.y)*40.0-float(cam[1]))*float(cam[2])+60.0
				var panel_y := anchor_y-100.0 if anchor_y>=160.0 else anchor_y+80.0
				root.position=Vector2(clampf((float(anchor.x)+float(anchor.w)/2.0)*40.0*float(cam[2])-float(cam[0])*float(cam[2])-250.0,5.0,455.0),clampf(panel_y,60.0,520.0))
		if key=="modal":
			var welcome_small:bool=data.modal=="welcome" and not JSON.stringify(item).contains("Fechar tutorial")
			entry[2]=Rect2(178,218,604,234) if welcome_small else Rect2(58,44,844,612)
			root.position=entry[2].position
		if key=="notice":
			var notice_y:=500.0
			if slots.context[0].visible:
				var actions_y:float=slots.context[0].position.y
				notice_y=actions_y-80.0 if actions_y>=140.0 else actions_y+120.0
			root.position=Vector2(10,notice_y)
		if key=="openBtn":
			var sign_size:=Vector2(190,54) if data.room=="street" else Vector2(100,38)
			entry[2]=Rect2(Vector2.ZERO,sign_size)
			root.position=Vector2(data.door[0]-sign_size.x/2,minf(data.door[1]-19,570.0))
			root.set_deferred("size",sign_size)
		var signature:String=JSON.stringify(item)
		if cache.get(key)==signature: continue
		cache[key]=signature
		var content:VBoxContainer=entry[1]
		var scroll=content.get_parent() as ScrollContainer
		var scroll_y:int=scroll.scroll_vertical if scroll else 0
		for c in content.get_children():content.remove_child(c);c.queue_free()
		builder.compact=key in ["drawer","context","ordersHud","kitchenStatus"]
		if key=="hud":
			var bar:=HBoxContainer.new()
			bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
			content.add_child(bar)
			var title:Label=builder.label("ENTRE ESQUINAS",20)
			title.autowrap_mode=TextServer.AUTOWRAP_OFF
			title.custom_minimum_size.x=205
			title.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
			bar.add_child(title)
			var status:Label=builder.label(item.children[0].text,13)
			status.autowrap_mode=TextServer.AUTOWRAP_OFF
			status.clip_text=true
			status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
			bar.add_child(status)
		elif key=="hint":
			content.add_child(builder.label(item.children[0].text,12))
		else:
			builder.render(item,content)
		if key=="modal" and signature.contains("Salvar restaurante") and signature.contains("Carregar restaurante"):
			var b:=Button.new();b.text="Importar salvamento (.json)"
			b.pressed.connect(func():import_dialog.popup_centered_ratio(0.72))
			content.add_child(b)
		if key in ["hud","hint","notice"]:
			for decoration in content.find_children("*","Control",true,false):
				decoration.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if key=="context":
			for decoration in content.find_children("*","Control",true,false):
				if not decoration is BaseButton: decoration.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if scroll and scroll_y: scroll.set_deferred("scroll_vertical",scroll_y)
		root.set_deferred("size",entry[2].size)
