extends Control
var item := "nutricao"
var count := 1
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _draw() -> void:
	var texture := preload("res://simulacao/nativa/Alimentos.gd").texture(item)
	for i in count:draw_texture_rect(texture,Rect2(i*20,0,20,20),false)
