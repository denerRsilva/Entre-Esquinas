extends RefCounted
## Shared tabletop coordinates for real clean stock and four served dishes.
const READY_CENTERS = [Vector2(24,8),Vector2(24,-7),Vector2(0,-7),Vector2(0,8)]
static func frame(furniture_scale: Vector2, counter: bool = false) -> Dictionary:
	var axes := Vector2(24.0/68,20.0/32) if counter else furniture_scale.abs()
	return {"axes":axes,"size":minf(axes.x,axes.y),"offset":Vector2(0,1) if counter else Vector2.ZERO}
static func point(local: Vector2, layout: Dictionary) -> Vector2:
	return local*layout.axes+layout.offset
static func rect(local: Rect2, layout: Dictionary) -> Rect2:
	return Rect2(point(local.get_center(),layout)-local.size*layout.size/2,local.size*layout.size)
static func ready(index: int, layout: Dictionary) -> Vector2:
	return point(READY_CENTERS[index],layout)
static func clean(pile: int, layer: int, layout: Dictionary) -> Rect2:
	return rect(Rect2(-34,(-5 if pile==0 else 9)-layer,10,5),layout)
