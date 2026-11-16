extends ScrollContainer
## One persistent paper per recorded order. Only the existing animated bar
## changes every frame; images and Controls are shared/reused.
const BAR = preload("res://interface/BarraAnimada.gd")
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
const PAPER = preload("res://arte/ui/comanda-aprovada.png")
const CARD_SIZE := Vector2(108,120)
var row := HBoxContainer.new()
var cards: Dictionary = {}

class Ticket extends Control:
	const DIGITS = ["111101101101111","010110010010111","111001111100111","111001111001111","101101111001001","111100111001111","111100111101111","111001001001001","111101111101111","111101111001111"]
	var table := ""
	var recipe := ""
	var dish := TextureRect.new()
	var bar = BAR.new()

	func _init() -> void:
		custom_minimum_size=CARD_SIZE
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		dish.position=Vector2(14,38);dish.size=Vector2(80,49)
		dish.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		dish.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dish.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(dish)
		bar.position=Vector2(15,92);bar.size=Vector2(78,16)
		bar.max_value=1;bar.kind="patience"
		add_child(bar)

	func sync(entry: Dictionary) -> void:
		var number := str(int(entry.table)).pad_zeros(2)
		if table!=number or recipe!=entry.recipe:
			accessibility_name="Mesa "+number+" • "+preload("res://simulacao/nativa/receitas.json").data[entry.recipe].name
		if table!=number:table=number;queue_redraw()
		if recipe!=entry.recipe:
			recipe=entry.recipe;dish.texture=FOOD.texture(recipe)
		bar.value=entry.ratio

	func _draw() -> void:
		# The approved sheet stays untouched; use only its empty paper and icon.
		draw_texture_rect_region(PAPER,Rect2(Vector2.ZERO,CARD_SIZE),Rect2(948,70,729,793))
		draw_texture_rect_region(PAPER,Rect2(15,13,22,20),Rect2(147,117,143,125))
		for digit in table.length():
			var glyph: String = DIGITS[int(table[digit])]
			for pixel in 15:
				if glyph[pixel]=="1":
					draw_rect(Rect2(45+digit*12+(pixel%3)*3,16+int(pixel/3)*3,3,3),Color("352316"))

func _init() -> void:
	name="Comandas"
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll_deadzone=8
	row.add_theme_constant_override("separation",8)
	add_child(row)
	hide()

func sync(entries: Array, bounds: Rect2) -> void:
	var live := {}
	for entry in entries:
		var key: String = str(entry.id)
		live[key]=true
		if not cards.has(key):
			var card := Ticket.new()
			# Set the initial value before _ready to avoid animating from zero.
			card.sync(entry);cards[key]=card;row.add_child(card)
		cards[key].sync(entry)
		if cards[key].get_index()!=live.size()-1:row.move_child(cards[key],live.size()-1)
	for key in cards.keys():
		if not live.has(key):
			var old: Control = cards[key]
			row.remove_child(old);old.queue_free();cards.erase(key)
	visible=not entries.is_empty()
	var width := minf(456,minf(bounds.size.x-24,entries.size()*116-8))
	position=Vector2(bounds.end.x-width-8,bounds.position.y+60)
	size=Vector2(maxf(0,width),134)
