extends Node2D
## Estrutura vazia; as panelas são desenhadas a partir do conteúdo da simulação.
func _draw() -> void:
	draw_rect(Rect2(-38,-58,76,58),Color("#503e2d"))
	draw_rect(Rect2(-34,-54,68,46),Color("#826143"))
	draw_rect(Rect2(-36,-58,72,5),Color("#d0ab76"))
	draw_rect(Rect2(-38,-56,5,56),Color("#b88b58"))
	draw_rect(Rect2(33,-56,5,56),Color("#b88b58"))
	draw_rect(Rect2(-35,-32,70,4),Color("#c29861"))
	draw_rect(Rect2(-35,-12,70,5),Color("#d0ab76"))
	draw_rect(Rect2(-34,-7,5,7),Color("#60432e"))
	draw_rect(Rect2(29,-7,5,7),Color("#60432e"))
