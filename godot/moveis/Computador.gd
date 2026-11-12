extends Node2D
func _draw():
	if name != "Tela":return
	draw_rect(Rect2(-23,-82,46,31),Color("303b3b"))
	draw_rect(Rect2(-19,-78,38,23),Color("95a68a"))
	draw_rect(Rect2(-5,-51,10,7),Color("303b3b"))
	draw_rect(Rect2(-19,-44,38,4),Color("b7ac8b"))
