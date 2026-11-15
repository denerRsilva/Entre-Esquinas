extends RefCounted
## Atlas original do pacote Modern UI Style 1. Recortes em tempo de desenho;
## a textura permanece compartilhada e os pixels usam filtro nearest.
const ATLAS = preload("res://arte/ui/modern-ui-32.png")
const ROWS = {"green":300,"yellow":396,"red":492,"blue":588}

static func color_for(kind: String, fraction: float) -> String:
	return ("red" if fraction<=0.25 else "yellow" if fraction<=0.5 else "green") if kind=="patience" else kind

static func paint(canvas: CanvasItem, rect: Rect2, fraction: float, kind := "blue") -> void:
	if rect.size.x<12 or rect.size.y<=0:return
	var ratio := clampf(fraction,0,1)
	var scale := rect.size.y/16.0
	var cap := 6.0*scale
	var inner := Rect2(rect.position+Vector2(cap,0),Vector2(maxf(0,rect.size.x-2*cap),rect.size.y))
	canvas.draw_texture_rect_region(ATLAS,inner,Rect2(672,266,30,16))
	# Fill is clipped within the rim; the frame never shrinks with progress.
	var filled := floorf(inner.size.x*ratio)
	if filled>0:
		canvas.draw_texture_rect_region(ATLAS,Rect2(inner.position+Vector2(0,2*scale),Vector2(filled,10*scale)),Rect2(672,ROWS.get(color_for(kind,ratio),588),30,10))
	canvas.draw_texture_rect_region(ATLAS,Rect2(rect.position,Vector2(cap,rect.size.y)),Rect2(666,234,6,16))
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(rect.end.x-cap,rect.position.y),Vector2(cap,rect.size.y)),Rect2(702,234,6,16))
