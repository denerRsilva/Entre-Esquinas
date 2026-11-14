@tool
extends Node2D
@export_enum("Horizontal","Vertical","Canto") var forma: int = 0:
	set(value):
		forma=value
		queue_redraw()
var giro := 0
var vizinhos := 0
const ATLAS = preload("res://arte/modular/bancadas-modulares-revisadas.png")
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut := ShaderMaterial.new()
	cut.shader=preload("res://arte/taverna/recorte.gdshader")
	material=cut
func configurar(rotation_index: int, neighbors: int = 0) -> void:
	giro=rotation_index
	vizinhos=neighbors
	queue_redraw()
func _draw() -> void:
	# A fixed camera: rotate connections, never the frontal face of the sprite.
	draw_texture_rect_region(ATLAS,Rect2(-20,-68,40,40),Rect2(121,62,208,112))
	if (vizinhos & 1)==0:draw_line(Vector2(-20,-68),Vector2(20,-68),Color("#35251d"),2)
	if (vizinhos & 2)==0:draw_line(Vector2(19,-68),Vector2(19,-28),Color("#35251d"),2)
	if (vizinhos & 8)==0:draw_line(Vector2(-19,-68),Vector2(-19,-28),Color("#35251d"),2)
	if (vizinhos & 4)==0:
		draw_texture_rect_region(ATLAS,Rect2(-20,-28,40,28),Rect2(116,189,222,42))
