@tool
extends Node2D
## Original Piskel pieces. Open edges share anchors; closed ends keep their width.
@export var grossa := false
@export_enum("Ponta esquerda","Horizontal","Ponta direita","Topo vertical","Vertical","Base vertical","Quina esquerda","Quina direita") var peca := 0
const ATLAS = preload("res://arte/modular/bancadas-piskel.png")
const FRONT := 30.0
const LIP := 5.0
const RECTS_THIN = [Rect2(11,201,139,228),Rect2(237,200,172,228),Rect2(502,198,143,228),Rect2(946,369,97,40),Rect2(946,437,97,176),Rect2(933,695,117,237),Rect2(1143,193,108,236),Rect2(1325,192,108,236)]
const RECTS_WIDE = [Rect2(5,647,156,294),Rect2(232,647,200,294),Rect2(502,645,153,294),Rect2(692,353,156,34),Rect2(690,433,157,178),Rect2(678,647,180,293),Rect2(1136,641,166,303),Rect2(1348,644,166,303)]
# The copied pieces have different Y origins; align the same golden rim/apron.
const SEAMS_THIN = [271.0,270.0,268.0,0.0,0.0,755.0,271.0,270.0]
const SEAMS_WIDE = [770.0,770.0,768.0,0.0,0.0,769.0,773.0,776.0]
var espelhada := false
func configurar(rotation_index: int, _neighbors: int = 0, _profiles: Array = []) -> void:
	var next := posmod(rotation_index,2)==1
	if next==espelhada:return
	espelhada=next;queue_redraw()
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	# Preserve the authored alpha, including edge pixels discarded by the old shader.
func largura() -> float:return 31.0 if grossa else 23.0
func profundidade() -> float:return 24.0 if grossa else 14.0
func efetiva() -> int:
	return {0:2,2:0,6:7,7:6}.get(peca,peca) if espelhada else peca
static func apoio(wide: bool, vertical: bool, mirrored: bool) -> Vector2:
	if vertical:return Vector2((2.5 if wide else 5.5)*(-1 if mirrored else 1),-50)
	return Vector2(0,-FRONT-(12 if wide else 7))
func patch(target: Rect2, source: Rect2) -> void:
	if target.size.x>0 and target.size.y>0:draw_texture_rect_region(ATLAS,target,source)
func upper_height(part: int) -> float:
	var source: Rect2 = (RECTS_WIDE if grossa else RECTS_THIN)[part]
	var seam: float = (SEAMS_WIDE if grossa else SEAMS_THIN)[part]
	var rim: float = seam-(27 if grossa else 24)
	return roundf((rim-source.position.y)*0.2)
func piece_columns(part: int) -> Array:
	var source: Rect2 = (RECTS_WIDE if grossa else RECTS_THIN)[part]
	var xscale := 40.0/(200 if grossa else 172)
	if part<=2:
		var width := roundf(source.size.x*xscale)
		var x := 20-width if part==0 else -20.0
		return [[x,width,source.position.x,source.size.x]]
	if part in [6,7]:
		# The upper opening is exactly the width of the supplied vertical strip.
		var port := 157.0 if grossa else 97.0
		var stub := source.size.x-port
		var native_stub := 2.0 if grossa else 3.0
		if part==6:return [[20-native_stub-largura(),largura(),source.position.x,port],[20-native_stub,native_stub,source.position.x+port,stub]]
		return [[-20.0,native_stub,source.position.x,stub],[-20+native_stub,largura(),source.position.x+stub,port]]
	var center := apoio(grossa,true,espelhada).x
	var port := 157.0 if grossa else 98.0
	var before := 12.0 if grossa else 10.0
	var after := source.size.x-before-port
	var left := roundf(before*xscale);var right := roundf(after*xscale)
	return [[center-largura()/2-left,left,source.position.x,before],[center-largura()/2,largura(),source.position.x+before,port],[center+largura()/2,right,source.position.x+before+port,after]]
func original_piece(part: int) -> void:
	var source: Rect2 = (RECTS_WIDE if grossa else RECTS_THIN)[part]
	var seam: float = (SEAMS_WIDE if grossa else SEAMS_THIN)[part]
	var rim := seam-(27 if grossa else 24)
	var height := upper_height(part)
	for column in piece_columns(part):
		# Every original pixel column is retained, including panels and legs.
		patch(Rect2(column[0],-FRONT-LIP-height,column[1],height),Rect2(column[2],source.position.y,column[3],rim-source.position.y))
		patch(Rect2(column[0],-FRONT-LIP,column[1],LIP),Rect2(column[2],rim,column[3],seam-rim))
		patch(Rect2(column[0],-FRONT,column[1],FRONT),Rect2(column[2],seam,column[3],source.end.y-seam))
func vertical_band(x: float, y: float, height: float) -> void:
	var source: Rect2 = (RECTS_WIDE if grossa else RECTS_THIN)[4]
	# Crop the supplied extension to the required span; do not invent wood patterns.
	var source_y := source.position.y+(y+FRONT+40)*source.size.y/40
	patch(Rect2(x,y,largura(),height),Rect2(source.position.x,source_y,source.size.x,height*source.size.y/40))
func _draw() -> void:
	var part := efetiva()
	var regions: Array = RECTS_WIDE if grossa else RECTS_THIN
	var center := apoio(grossa,true,espelhada).x
	var x := center-largura()/2
	if part<=2:original_piece(part)
	elif part==3:
		var cap: Rect2 = regions[3]
		var height := roundf(cap.size.y*0.2)
		patch(Rect2(x,-FRONT-40,largura(),height),cap)
		vertical_band(x,-FRONT-40+height,40-height)
	elif part==4:vertical_band(x,-FRONT-40,40)
	elif part==5:
		original_piece(part)
		# Cover only the back rim where the user's extension enters its base.
		vertical_band(x,-FRONT-40,40-upper_height(part)-LIP+2)
	else:
		var columns := piece_columns(part)
		var port_x: float = columns[0][0] if part==6 else columns[1][0]
		var height := 40-upper_height(part)-LIP
		vertical_band(port_x,-FRONT-40,height)
		original_piece(part)
