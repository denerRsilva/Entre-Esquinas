extends RefCounted
## Compact atlas of unchanged pixels from the purchased Modern UI pack.
## Original sheet is preserved; only the required bar regions are loaded.
const ATLAS = preload("res://arte/ui/barras-compactas-32.png")
const ROWS = {"green":0,"yellow":32,"red":64,"blue":96}

static func color_for(kind: String, fraction: float) -> String:
	return ("red" if fraction<=0.25 else "yellow" if fraction<=0.5 else "green") if kind=="patience" else kind

static func paint(canvas: CanvasItem, rect: Rect2, fraction: float, kind := "blue") -> void:
	if rect.size.x<12 or rect.size.y<=0:return
	var ratio := clampf(fraction,0,1)
	var scale := rect.size.y/16.0
	var cap := 6.0*scale
	var inner := Rect2(rect.position+Vector2(cap,0),Vector2(maxf(0,rect.size.x-2*cap),rect.size.y))
	canvas.draw_texture_rect_region(ATLAS,inner,Rect2(0,0,30,16))
	# Fill is clipped within the rim; the frame never shrinks with progress.
	var filled := floorf(inner.size.x*ratio)
	if filled>0:
		canvas.draw_texture_rect_region(ATLAS,Rect2(inner.position+Vector2(0,2*scale),Vector2(filled,10*scale)),Rect2(ROWS.get(color_for(kind,ratio),96),20,30,10))
	canvas.draw_texture_rect_region(ATLAS,Rect2(rect.position,Vector2(cap,rect.size.y)),Rect2(32,0,6,16))
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(rect.end.x-cap,rect.position.y),Vector2(cap,rect.size.y)),Rect2(40,0,6,16))
