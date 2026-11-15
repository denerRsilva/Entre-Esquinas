@tool
extends Node2D
## Exact regions from the user's Piskel sheet; tops/fronts align on the 40px grid.
@export var grossa := false
@export_enum("Ponta esquerda","Horizontal","Ponta direita","Topo vertical","Vertical","Base vertical","Quina esquerda","Quina direita") var peca := 0
const ATLAS = preload("res://arte/modular/bancadas-piskel.png")
const FRONT := 30.0
const RECTS_THIN = [Rect2(11,201,139,229),Rect2(237,200,172,230),Rect2(502,198,143,232),Rect2(946,369,97,40),Rect2(946,437,97,176),Rect2(933,695,117,237),Rect2(1143,192,108,238),Rect2(1325,192,108,238)]
const RECTS_WIDE = [Rect2(5,647,156,300),Rect2(232,647,200,300),Rect2(502,645,153,302),Rect2(692,353,156,34),Rect2(690,433,157,178),Rect2(678,647,180,293),Rect2(1136,641,166,306),Rect2(1348,641,166,306)]
var espelhada := false
func configurar(rotation_index: int, _neighbors: int = 0, _profiles: Array = []) -> void:
	var next := posmod(rotation_index,2)==1
	if next==espelhada:return
	espelhada=next;queue_redraw()
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut := ShaderMaterial.new();cut.shader=preload("res://arte/taverna/recorte.gdshader");material=cut
func largura() -> float:return 32.0 if grossa else 20.0
func profundidade() -> float:return 24.0 if grossa else 14.0
func patch(target: Rect2, source: Rect2) -> void:
	draw_texture_rect_region(ATLAS,target,source)
func panel(rect: Rect2, source: Rect2, seam: float) -> void:
	# Keep the apron height fixed; only the top plane changes depth.
	var top := Rect2(source.position,Vector2(source.size.x,seam-source.position.y))
	var front := Rect2(source.position.x,seam,source.size.x,source.end.y-seam)
	patch(Rect2(rect.position,Vector2(rect.size.x,rect.size.y-FRONT)),top)
	patch(Rect2(rect.position.x,rect.end.y-FRONT,rect.size.x,FRONT),front)
func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if espelhada else 1,1))
	var regions: Array = RECTS_WIDE if grossa else RECTS_THIN
	var source: Rect2 = regions[peca]
	var width := largura();var depth := profundidade()
	if peca<=2:
		panel(Rect2(-20,-FRONT-depth,40,FRONT+depth),source,770 if grossa else 270)
	elif peca in [3,4]:
		var band: Rect2 = regions[4]
		patch(Rect2(-20,-FRONT-40,width,40),band)
		if peca==3:patch(Rect2(-20,-FRONT-40,width,7),source)
	elif peca==5:
		# A vertical run has no repeated apron. Its base alone closes the front.
		patch(Rect2(-20,-FRONT-40,width,40-depth),regions[4])
		var overhang := 2.0
		panel(Rect2(-20-overhang,-FRONT-depth,width+overhang*2,FRONT+depth),source,770 if grossa else 761)
	else:
		# Vertical arm reaches the back edge of its cell, flush with a run above.
		var arm_x := -20.0 if peca==6 else 20.0-width
		patch(Rect2(arm_x,-FRONT-40,width,40),regions[4])
		var split: float = (1282 if grossa else 1229) if peca==6 else (1370 if grossa else 1347)
		var left_width := width if peca==6 else 40-width
		var a := Rect2(source.position,Vector2(split-source.position.x,source.size.y))
		var b := Rect2(split,source.position.y,source.end.x-split,source.size.y)
		var seam := 770.0 if grossa else 270.0
		var horizontal_top: float = (650 if peca==6 else 653) if grossa else (201 if peca==6 else 200)
		for column in [[-20,left_width,a],[-20+left_width,40-left_width,b]]:
			var part: Rect2 = column[2]
			patch(Rect2(column[0],-FRONT-depth,column[1],depth),Rect2(part.position.x,horizontal_top,part.size.x,seam-horizontal_top))
			patch(Rect2(column[0],-FRONT,column[1],FRONT),Rect2(part.position.x,seam,part.size.x,source.end.y-seam))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
