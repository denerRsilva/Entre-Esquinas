@tool
extends Node2D
## One physical base, shared by empty, cutting and plating workstations.
@export_enum("Vazia","Corte","Empratamento") var kit: int = 0:
	set(value):
		kit=value
		queue_redraw()
@export var mostrar_base := true
const ALTURA_BASE := 30
const PROFUNDIDADE_TAMPO := 28
const BASE = preload("res://arte/modular/mesa-trabalho.png")
const KITS = preload("res://arte/modular/kits-mesa.png")
const CENTRO_KIT := Vector2(0,-ALTURA_BASE-PROFUNDIDADE_TAMPO/2.0)
const RECORTES = [Rect2(155,335,599,255),Rect2(1017,335,621,255)]
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut := ShaderMaterial.new()
	cut.shader=preload("res://arte/taverna/recorte.gdshader")
	material=cut
func _draw() -> void:
	if mostrar_base:draw_texture_rect_region(BASE,Rect2(-38,-ALTURA_BASE-PROFUNDIDADE_TAMPO,76,ALTURA_BASE+PROFUNDIDADE_TAMPO),Rect2(94,122,1245,877))
	if kit>0:
		draw_texture_rect_region(KITS,Rect2(CENTRO_KIT-Vector2(24,10),Vector2(48,20)),RECORTES[kit-1])
