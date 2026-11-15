@tool
extends Node2D
## Pixel density and wood phase are shared by all modules, including mirrored ones.
@export var grossa := false
@export_enum("Ponta esquerda","Horizontal","Ponta direita","Topo vertical","Vertical","Base vertical","Quina esquerda","Quina direita") var peca := 0
const ATLAS = preload("res://arte/modular/bancadas-piskel.png")
const FRONT := 30.0
const PIXEL_SCALE := 0.2
const BORDER := 32.0
const LIP := 6.0
const RECTS_THIN = [Rect2(11,201,139,229),Rect2(237,200,172,230),Rect2(502,198,143,232),Rect2(946,369,97,40),Rect2(946,437,97,176),Rect2(933,695,117,237),Rect2(1143,192,108,238),Rect2(1325,192,108,238)]
const RECTS_WIDE = [Rect2(5,647,156,300),Rect2(232,647,200,300),Rect2(502,645,153,302),Rect2(692,353,156,34),Rect2(690,433,157,178),Rect2(678,647,180,293),Rect2(1136,641,166,306),Rect2(1348,641,166,306)]
var espelhada := false
var origem := Vector2i.ZERO
func configurar(rotation_index: int, _neighbors: int = 0, _profiles: Array = []) -> void:
	var next := posmod(rotation_index,2)==1
	if next==espelhada:return
	espelhada=next;queue_redraw()
func definir_origem(value: Vector2i) -> void:
	if origem==value:return
	origem=value;queue_redraw()
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut := ShaderMaterial.new();cut.shader=preload("res://arte/taverna/recorte.gdshader");material=cut
func largura() -> float:return (157.0 if grossa else 97.0)*PIXEL_SCALE
func profundidade() -> float:return (123.0 if grossa else 70.0)*PIXEL_SCALE
func efetiva() -> int:
	if espelhada:return {0:2,2:0,6:7,7:6}.get(peca,peca)
	return peca
func patch(target: Rect2, source: Rect2) -> void:
	if target.size.x>0.001 and target.size.y>0.001:draw_texture_rect_region(ATLAS,target,source)
func tile(target: Rect2, source: Rect2, phase: Vector2 = Vector2.ZERO) -> void:
	# Crop/repeat instead of stretching panels, bevels or pixel clusters.
	var period := source.size*PIXEL_SCALE
	var y := 0.0
	while y<target.size.y-0.001:
		var sy := fposmod(phase.y+y,period.y)
		if period.y-sy<0.001:sy=0
		var height := minf(target.size.y-y,period.y-sy)
		var x := 0.0
		while x<target.size.x-0.001:
			var sx := fposmod(phase.x+x,period.x)
			if period.x-sx<0.001:sx=0
			var width := minf(target.size.x-x,period.x-sx)
			patch(Rect2(target.position+Vector2(x,y),Vector2(width,height)),Rect2(source.position+Vector2(sx,sy)/PIXEL_SCALE,Vector2(width,height)/PIXEL_SCALE))
			x+=width
		y+=height
func front(target: Rect2, source: Rect2, phase_x: float = 0.0) -> void:
	var border := BORDER*PIXEL_SCALE
	# Apron beams retain their thickness. Crop the upright grain between them.
	tile(Rect2(target.position,Vector2(target.size.x,border)),Rect2(source.position,Vector2(source.size.x,BORDER)),Vector2(phase_x,0))
	tile(Rect2(target.position+Vector2(0,border),Vector2(target.size.x,target.size.y-border*2)),Rect2(source.position+Vector2(0,BORDER),Vector2(source.size.x,source.size.y-BORDER*2)),Vector2(phase_x,0))
	tile(Rect2(target.position.x,target.end.y-border,target.size.x,border),Rect2(source.position.x,source.end.y-BORDER,source.size.x,BORDER),Vector2(phase_x,0))
func horizontal(part: int, regions: Array, corner: bool = false) -> void:
	var seam := 770.0 if grossa else 270.0
	var middle: Rect2 = regions[1]
	var source: Rect2 = regions[part]
	var edge := BORDER*PIXEL_SCALE
	var left := part in [0,6]
	var right := part in [2,7]
	var start := -20.0+(edge if left else 0.0)
	var width := 40.0-(edge if left or right else 0.0)
	var phase_x := float(origem.x)+start+20
	tile(Rect2(-20 if corner else start,-FRONT-profundidade(),40 if corner else width,profundidade()),Rect2(middle.position.x,middle.position.y,middle.size.x,seam-middle.position.y),Vector2(origem.x if corner else phase_x,0))
	# Repeat one complete panel between matching posts, with a global phase.
	var grain := Rect2(239,770,95,177) if grossa else Rect2(247,270,80,160)
	front(Rect2(start,-FRONT,width,FRONT),grain,phase_x)
	if left or right:
		var x := -20.0 if left else 20.0-edge
		var sx := source.position.x if left else source.end.x-BORDER
		front(Rect2(x,-FRONT,edge,FRONT),Rect2(sx,seam,BORDER,source.end.y-seam))
		if not corner:
			# Clip the end's own rounded silhouette; no wood is painted behind it.
			patch(Rect2(x,-FRONT-profundidade(),edge,profundidade()),Rect2(sx,middle.position.y,BORDER,seam-middle.position.y))
func vertical_surface(target: Rect2, source: Rect2) -> void:
	tile(target,source,Vector2(0,float(origem.y)+target.position.y+FRONT+40))
func side(x: float, right: bool, regions: Array, start_y: float = -FRONT-40) -> void:
	var end: Rect2 = regions[2 if right else 0]
	var seam := 770.0 if grossa else 270.0
	var sx := end.end.x-15 if right else end.position.x
	tile(Rect2(x,start_y,3,-FRONT-start_y),Rect2(sx,seam+BORDER,15,end.end.y-seam-BORDER*2),Vector2(0,float(origem.y)))
func _draw() -> void:
	var regions: Array = RECTS_WIDE if grossa else RECTS_THIN
	var part := efetiva()
	var width := largura();var depth := profundidade()
	if part<=2:
		horizontal(part,regions)
		return
	var right := part==7 or (part in [3,4,5] and espelhada)
	var x := 20.0-width if right else -20.0
	var band: Rect2 = regions[4]
	if part in [3,4,5]:
		side(x-2 if right else x+width-1,not right,regions,-FRONT-40+(regions[3].size.y*PIXEL_SCALE if part==3 else 0))
		if part==3:
			var cap: Rect2 = regions[3]
			var size := cap.size*PIXEL_SCALE
			patch(Rect2(x+(width-size.x)/2,-FRONT-40,size.x,size.y),cap)
			vertical_surface(Rect2(x,-FRONT-40+size.y,width,40-size.y),band)
		elif part==4:vertical_surface(Rect2(x,-FRONT-40,width,40),band)
		else:
			var base: Rect2 = regions[5]
			var seam := 770.0 if grossa else 761.0
			var top_height := (seam-base.position.y)*PIXEL_SCALE
			var base_width := base.size.x*PIXEL_SCALE
			vertical_surface(Rect2(x,-FRONT-40,width,40-top_height+1),band)
			patch(Rect2(x+(width-base_width)/2,-FRONT-top_height,base_width,top_height),Rect2(base.position.x,base.position.y,base.size.x,seam-base.position.y))
			front(Rect2(x+(width-base_width)/2,-FRONT,base_width,FRONT),Rect2(base.position.x,seam,base.size.x,base.end.y-seam))
	else:
		side(x-2 if right else x+width-1,not right,regions)
		horizontal(part,regions,true)
		vertical_surface(Rect2(x,-FRONT-40,width,40-depth),band)
		# The connecting arm covers the back rim, leaving the shared front lip.
		var inside := Rect2(band.position+Vector2(10,0),band.size-Vector2(20,0))
		vertical_surface(Rect2(x,-FRONT-depth,width,depth-LIP),inside)
		var sx := band.end.x-10 if right else band.position.x
		vertical_surface(Rect2(20-2 if right else -20,-FRONT-depth,2,depth),Rect2(sx,band.position.y,10,band.size.y))
