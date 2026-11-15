@tool
extends Node2D
@export var indice := 3
const ATLAS = preload("res://arte/taverna/decoracao.png")
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut := ShaderMaterial.new();cut.shader=preload("res://arte/taverna/recorte.gdshader");material=cut
func _draw() -> void:
	var source := Rect2(727,29,154,200) if indice==3 else Rect2(1197,78,133,151)
	var size := Vector2(32,42) if indice==3 else Vector2(30,34)
	draw_texture_rect_region(ATLAS,Rect2(Vector2(-size.x/2,-size.y),size),source)
