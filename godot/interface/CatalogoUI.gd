extends RefCounted
## Converts the game's actions into real Godot Controls. Input paths resolve to
## the current simulation state, even after an inventory or stock count changes.
const Paint = preload("res://mundo/Tracos.gd")
var send: Callable
var compact := false

func label(text: String, size := 15) -> Label:
	var n := Label.new()
	n.text = text
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.add_theme_font_size_override("font_size",size)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

func texture(ops: Array) -> Texture2D:
	for op in ops:
		if op[0]=="food":return preload("res://simulacao/nativa/Alimentos.gd").texture(str(op[1]))
		if op[0]=="svg": return Paint.vector(op[1])
		if op[0]=="img":
			var tex := AtlasTexture.new()
			tex.atlas = Paint.artwork(op[1])
			tex.region = Rect2(op[2],op[3],op[4],op[5])
			tex.filter_clip = true
			return tex
	return null

func furniture_control(type: String, title: String) -> Control:
	var icon := TextureRect.new()
	icon.name = "Furniture_"+type
	icon.tooltip_text = title
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(96,80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var viewport := SubViewport.new()
	viewport.size = Vector2i(120,112)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	icon.add_child(viewport)
	var scene: PackedScene = preload("res://moveis/Catalogo.gd").CENAS.get(type)
	if scene:
		var furniture: Node2D = scene.instantiate()
		furniture.position = Vector2(60,104)
		if preload("res://simulacao/nativa/catalogo.json").data.get(type,{}).has("counterPart"):
			furniture.scale=Vector2.ONE*1.4
		viewport.add_child(furniture)
	icon.texture = viewport.get_texture()
	return icon

func art_control(d: Dictionary) -> Control:
	if not d.art.is_empty() and d.art[0][0]=="furniture_icon":
		return furniture_control(str(d.art[0][1]),d.get("label",""))
	var n := TextureRect.new()
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.texture = texture(d.art)
	var mat:=ShaderMaterial.new()
	mat.shader=load("res://arte/taverna/recorte.gdshader")
	n.material=mat
	n.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	n.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	n.custom_minimum_size = Vector2(180,130) if d.get("cls","")=="recipeHero" else Vector2(52,42)
	n.tooltip_text = d.get("label","")
	return n

func render(d: Dictionary, parent: Control) -> void:
	if d.is_empty(): return
	var tag: String = d.tag
	var cls: String = d.get("cls","")
	var id: String = d.get("id","")
	if tag=="text":
		parent.add_child(label(d.text))
		return
	if tag=="button":
		var b := Button.new()
		var title: String = d.text.strip_edges()
		b.text = title if title else d.label
		b.tooltip_text = d.label
		b.disabled = d.disabled
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(78,44)
		if parent.name=="BuildActions": b.autowrap_mode=TextServer.AUTOWRAP_OFF
		if parent is HFlowContainer:
			b.custom_minimum_size.x = clampf(24+7.3*b.text.length(),76,225)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if cls.contains("cityNavButton"):
			b.autowrap_mode=TextServer.AUTOWRAP_OFF
			b.custom_minimum_size=Vector2(0,40)
			b.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		if cls=="constructionSectionButton":
			b.autowrap_mode=TextServer.AUTOWRAP_OFF
			b.custom_minimum_size=Vector2(0,40)
			b.add_theme_font_size_override("font_size",14)
		if d.has("art"):
			b.icon = texture(d.art)
			b.add_theme_constant_override("icon_max_width",32)
		if cls.contains("objectAction"):
			b.text = ""
			b.tooltip_text = ""
			b.accessibility_name = d.label
			b.set_meta("action_label",d.label)
			b.icon = preload("res://interface/IconesAcao.gd").icon(d.label,b.icon)
			b.add_theme_constant_override("icon_max_width",56)
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.custom_minimum_size = Vector2(76,64)
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if cls.contains("inventorySlot"):
			b.custom_minimum_size=Vector2(72,80)
			var arrow:=TextureRect.new()
			arrow.texture=Paint.vector('<svg viewBox="0 0 16 16" shape-rendering="crispEdges"><path fill="#243c32" d="M0 0h16v16H0z"/><path fill="#f4cb65" d="M6 2h4v7h4l-6 6-6-6h4z"/></svg>')
			arrow.mouse_filter=Control.MOUSE_FILTER_IGNORE
			arrow.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			arrow.position=Vector2(48,26)
			arrow.size=Vector2(20,20)
			b.add_child(arrow)
			b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
			b.add_theme_font_size_override("font_size",12)
			b.tooltip_text=d.label
			for op in d.get("art",[]):
				if op[0]=="poly":
					b.text+=" ★"
					b.add_theme_color_override("font_color",Color.from_string(op[2],Color.WHITE).darkened(0.36))
		if cls.contains("selected") or cls.contains("active"):
			b.modulate = Color("#ffdb84")
		b.pressed.connect(func():send.call({"kind":"widget","path":d.path,"id":id}))
		parent.add_child(b)
		return
	if tag=="select":
		var n := OptionButton.new()
		n.tooltip_text = d.label
		n.disabled = d.disabled
		for i in d.options.size():
			n.add_item(str(d.options[i][0]))
			var option: Variant = d.options[i][1]
			var numeric: bool = (option is int or option is float) and (d.value is int or d.value is float)
			if (float(option)==float(d.value)) if numeric else (str(option)==str(d.value)):n.select(i)
		n.item_selected.connect(func(i):send.call({"kind":"widget","path":d.path,"value":d.options[i][1]}))
		parent.add_child(n)
		return
	if tag=="input":
		if d.type=="checkbox":
			var n := CheckButton.new()
			n.text = "Oferecer"
			n.button_pressed = d.checked
			n.disabled = d.disabled
			n.toggled.connect(func(v):send.call({"kind":"widget","path":d.path,"value":v}))
			parent.add_child(n)
		else:
			var n := SpinBox.new()
			n.min_value = float(d.get("min",0))
			n.max_value = float(d.get("max",100))
			n.step = float(d.get("step",1))
			n.value = float(d.value)
			n.editable = not d.disabled
			n.tooltip_text = d.label
			n.value_changed.connect(func(v):send.call({"kind":"widget","path":d.path,"value":v}))
			parent.add_child(n)
		return
	if tag=="progress":
		var bar := preload("res://interface/BarraAnimada.gd").new()
		bar.max_value = d.max
		bar.value = d.value
		bar.show_percentage = false
		bar.kind = d.get("color","blue")
		bar.tooltip_text = d.get("label","")
		parent.add_child(bar)
		return
	if d.has("art"):
		parent.add_child(art_control(d))
		return
	var kids: Array = d.get("children",[])
	if kids.is_empty(): return
	if tag=="table":
		var rows := []
		for group in kids: rows.append_array(group.get("children",[]))
		var grid := GridContainer.new()
		grid.columns = maxi(1,rows[0].get("children",[]).size()) if not rows.is_empty() else 1
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parent.add_child(grid)
		for row in rows:
			for cell in row.get("children",[]):
				var cell_box := VBoxContainer.new()
				cell_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(cell_box)
				for c in cell.get("children",[]): render(c,cell_box)
		return
	if tag in ["p","b","label","span","strong","small","h1","h2"] and kids.any(func(k):return k.tag=="canvas") and kids.all(func(k):return k.tag in ["canvas","text"]):
		var rich:=RichTextLabel.new()
		rich.fit_content=true
		rich.scroll_active=false
		rich.mouse_filter=Control.MOUSE_FILTER_IGNORE
		rich.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		for k in kids:
			if k.tag=="text":rich.add_text(k.text+" ")
			else:
				var tex:=texture(k.art)
				if tex:rich.add_image(tex,28,22,Color.WHITE,INLINE_ALIGNMENT_CENTER)
				rich.add_text(" ")
		parent.add_child(rich)
		return
	if tag in ["h1","h2","strong","b","p","small","li","span","label","td","th"]:
		var texts := PackedStringArray()
		var plain := true
		for k in kids:
			if k.tag=="text": texts.append(k.text)
			else: plain=false
		if plain:
			var n := label(" ".join(texts),30 if tag=="h1" else 21 if tag=="h2" else 17 if tag in ["strong","b"] else 16)
			if tag in ["h1","h2"]:
				var serif:=SystemFont.new()
				serif.font_names=PackedStringArray(["Georgia","Liberation Serif","DejaVu Serif"])
				serif.font_weight=700
				n.add_theme_font_override("font",serif)
			parent.add_child(n)
			return
	var group: Container
	if cls=="recipeBook":
		var grid:=GridContainer.new()
		grid.columns=3
		grid.add_theme_constant_override("h_separation",12)
		group=grid
	elif cls in ["recipeIngredients","recipeFlow"]:
		group=HBoxContainer.new()
		group.add_theme_constant_override("separation",12)
	elif cls=="buildActions":
		group=HFlowContainer.new()
		group.name="BuildActions"
	elif id=="buildBar":
		group=VBoxContainer.new()
	elif cls=="hotbarSlots":
		var grid:=GridContainer.new()
		grid.columns=5
		group=grid
	elif cls=="constructionSections":
		var grid := GridContainer.new();grid.columns=3
		grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6)
		group=grid
	elif cls=="buildCards":
		var grid := GridContainer.new()
		grid.name = "ConstructionGrid"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation",10)
		grid.add_theme_constant_override("v_separation",10)
		group=grid
	elif cls in ["cards","recipeGrid","inventoryGrid","splitInventories","prepSlots","prepPrimary"]:
		var grid := GridContainer.new()
		grid.columns = 1 if compact else (5 if cls=="inventoryGrid" else 3 if cls in ["cards","recipeGrid"] else 2)
		if cls=="inventoryGrid" and compact: grid.columns=2
		if cls in ["prepSlots","prepPrimary"]: grid.columns=2
		group=grid
	elif tag=="nav" or id in ["dock","actions"] or cls in ["welcomeActions","dialogHead","objectActions"]:
		group=HFlowContainer.new()
	else:
		group=VBoxContainer.new()
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if cls=="card" or cls=="inventoryPane":
		var panel := PanelContainer.new()
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		parent.add_child(panel)
		panel.add_child(group)
		group.add_theme_constant_override("separation",8)
	else: parent.add_child(group)
	if cls=="card":
		kids=kids.filter(func(k):return k.has("art"))+kids.filter(func(k):return not k.has("art"))
	for k in kids: render(k,group)
