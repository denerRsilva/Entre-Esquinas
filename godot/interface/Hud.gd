extends Control
signal command(event: Dictionary)
const Builder = preload("res://interface/CatalogoUI.gd")
var builder = Builder.new()
var slots := {}
var cache := {}
var by_id := {}
var kitchen_bars: Array = []
var order_bars: Array = []
var layout_size := Vector2.ZERO
var layout_bounds := Rect2()
var small_modal := false
var modal_background: ColorRect
var import_dialog: FileDialog
var refuge = preload("res://interface/RefugioHUD.gd").new()
var comandas = preload("res://interface/Comandas.gd").new()
signal import_save(path:String)
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	builder.send=func(e): command.emit(e)
	area("hud",Rect2(8,5,940,47),false,false)
	area("ordersHud",Rect2(710,74,245,170))
	area("kitchenStatus",Rect2(8,74,320,120))
	area("context",Rect2(150,360,500,110),false,false)
	area("dock",Rect2(10,647,550,48),false,false)
	area("actions",Rect2(720,641,234,54),false,false)
	area("catalog",Rect2(10,649,168,44),false,false)
	area("drawer",Rect2(7,7,440,628))
	area("build",Rect2(188,535,762,160))
	resized.connect(func():fit_build.call_deferred())
	get_viewport().size_changed.connect(func():fit_build.call_deferred())
	add_child(comandas)
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
	add_child(refuge);refuge.action.connect(func(value):command.emit({"kind":"refuge","action":value}))

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

static func safe_layout(logical: Vector2, physical: Vector2, safe: Rect2) -> Rect2:
	var full := Rect2(Vector2.ZERO,logical)
	if physical.x<=0 or physical.y<=0 or not safe.has_area():return full
	var factor := logical/physical
	var area := full.intersection(Rect2(safe.position*factor,safe.size*factor))
	return area if area.size.x>=320 and area.size.y>=240 else full

func usable_rect() -> Rect2:
	var full := get_viewport_rect()
	if OS.has_feature("android"):
		return safe_layout(full.size,Vector2(DisplayServer.window_get_size()),Rect2(DisplayServer.get_display_safe_area()))
	return full

func region(key: String, rect: Rect2) -> void:
	rect.position+=layout_bounds.position
	var entry: Array = slots[key]
	entry[2]=rect
	entry[0].position=rect.position
	entry[0].size=rect.size
	if key in ["hint","notice"]:
		entry[1].size=rect.size-Vector2(12,6)

func fit_regions(welcome_small: bool) -> void:
	var bounds := usable_rect()
	var screen := bounds.size
	if bounds==layout_bounds and welcome_small==small_modal:return
	layout_size=screen;layout_bounds=bounds;small_modal=welcome_small
	var w := screen.x;var h := screen.y
	region("hud",Rect2(8,5,w-16,47))
	region("ordersHud",Rect2(w-253,64,245,minf(210,h-150)))
	region("kitchenStatus",Rect2(8,64,minf(320,w*0.34),minf(180,h-160)))
	region("dock",Rect2(10,h-53,minf(550,w-280),48))
	region("actions",Rect2(w-244,h-59,234,54))
	region("catalog",Rect2(10,h-51,168,44))
	region("drawer",Rect2(7,7,minf(440,w-20),h-70))
	var dialog_size := Vector2(minf(604 if welcome_small else 844,w-32),minf(300 if welcome_small else 612,h-32))
	region("modal",Rect2((screen-dialog_size)/2,dialog_size))
	region("context",Rect2(10,64,minf(500,w-20),110))
	if slots.build[0].visible:fit_build.call_deferred()

func progress_signature(item: Dictionary, values: Array) -> Dictionary:
	var result := item.duplicate()
	if item.get("tag")=="progress":
		values.append(item.value);result.value=0
	if item.has("children"):
		result.children=[]
		for child in item.children:result.children.append(progress_signature(child,values))
	return result

func update_kitchen_bars(values: Array) -> void:
	for i in mini(values.size(),kitchen_bars.size()):
		kitchen_bars[i].value=values[i]

func sync(data: Dictionary) -> void:
	refuge.sync(data.get("refuge"),usable_rect(),data.modal.is_empty() and not data.construction)
	modal_background.visible = data.modal!=""
	fit_regions(data.modal=="welcome" and not JSON.stringify(data.ui.get("modal",{})).contains("Fechar tutorial"))
	comandas.sync(data.ui.get("comandas",[]),usable_rect())
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
				var anchor_y := (float(anchor.y)*40.0-float(cam[1]))*float(cam[2])
				var panel_y := anchor_y-100.0 if anchor_y>=160.0 else anchor_y+80.0
				var width: float = entry[2].size.x
				root.position=Vector2(clampf((float(anchor.x)+float(anchor.w)/2.0)*40.0*float(cam[2])-float(cam[0])*float(cam[2])-width/2,layout_bounds.position.x+5,layout_bounds.end.x-width-5),clampf(panel_y,layout_bounds.position.y+60,layout_bounds.end.y-120))
		var progress_values: Array = []
		var signature:String=JSON.stringify(progress_signature(item,progress_values) if key in ["kitchenStatus","ordersHud"] else item)
		if cache.get(key)==signature:
			if key=="kitchenStatus":update_kitchen_bars(progress_values)
			elif key=="ordersHud":
				for i in mini(progress_values.size(),order_bars.size()):order_bars[i].value=progress_values[i]
			continue
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
		if key=="kitchenStatus":kitchen_bars=content.find_children("*","ProgressBar",true,false)
		elif key=="ordersHud":order_bars=content.find_children("*","ProgressBar",true,false)
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
	if slots.build[0].visible:fit_build.call_deferred()

func fit_build() -> void:
	if not slots.has("build"):return
	var panel: Control = slots.build[0]
	if not panel.visible:return
	var bounds := usable_rect()
	var viewport_size := bounds.size
	var width := minf(762,viewport_size.x-20)
	panel.size.x=width
	var content: VBoxContainer = slots.build[1]
	var desired_height := content.get_combined_minimum_size().y+28
	panel.size=Vector2(width,minf(desired_height,viewport_size.y-80))
	panel.position=bounds.position+Vector2(viewport_size.x-width-10,viewport_size.y-panel.size.y-8)
