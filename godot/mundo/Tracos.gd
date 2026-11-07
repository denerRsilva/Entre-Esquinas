extends Node2D
## Details attached to the scene: utensils, dishes, shadows, indicators and order labels.
var commands: Array = []
static var textures: Dictionary = {}
static var vectors: Dictionary = {}

static func artwork(file: String) -> Texture2D:
	if not textures.has(file):
		textures[file] = load("res://arte/" + file)
	return textures[file]

static func vector(source: String) -> Texture2D:
	if not vectors.has(source):
		var img := Image.new()
		var svg := source.replace("currentColor", "#fff0cf")
		if not svg.contains("xmlns="):
			svg = svg.replace("<svg ", '<svg xmlns="http://www.w3.org/2000/svg" ')
		if img.load_svg_from_string(svg, 2.0) == OK:
			vectors[source] = ImageTexture.create_from_image(img)
	return vectors.get(source)

func set_commands(next: Array) -> void:
	if commands != next:
		commands = next
		queue_redraw()

func _draw() -> void:
	for op in commands:
		match op[0]:
			"rect","line":
				var col := Color.from_string(op[5],Color.WHITE)
				if op[0] == "rect":
					col.a *= op[6]
				if op[3] > 0 and op[4] > 0:
					draw_rect(Rect2(op[1],op[2],op[3],op[4]),col,op[0]=="rect",op[6] if op[0]=="line" else -1)
			"text":
				var font := ThemeDB.fallback_font
				var p := Vector2(op[1],op[2])
				if op[6]=="center":
					p.x -= font.get_string_size(str(op[3]),HORIZONTAL_ALIGNMENT_LEFT,-1,op[4]).x/2
				draw_string(font,p,str(op[3]),HORIZONTAL_ALIGNMENT_LEFT,-1,op[4],Color.from_string(op[5],Color.WHITE))
			"img":
				var dw: float = op[8]
				draw_set_transform(Vector2(op[6],op[7]),0,Vector2(signf(dw),1))
				draw_texture_rect_region(artwork(op[1]),Rect2(0,0,absf(dw),op[9]),Rect2(op[2],op[3],op[4],op[5]),Color(1,1,1,op[10]))
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			"poly":
				var pts := PackedVector2Array()
				for p in op[1]:
					pts.append(Vector2(p[0],p[1]))
				draw_colored_polygon(pts,Color.from_string(op[2],Color.WHITE))
