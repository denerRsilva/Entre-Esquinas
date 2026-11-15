extends RefCounted
## Shared tabletop coordinates. Physical items never shrink with the furniture.
const FOOD = preload("res://simulacao/nativa/Alimentos.gd")
const READY_SIZE := FOOD.DISH_SIZE
const READY_CENTERS = [Vector2(24,7),Vector2(24,-7),Vector2(0,-7),Vector2(0,7)]
static func frame(furniture_scale: Vector2) -> Dictionary:
	return {"vertical":furniture_scale.y>furniture_scale.x}
static func ready(index: int, layout: Dictionary) -> Vector2:
	if layout.vertical:return [Vector2(10,21),Vector2(10,-21),Vector2(10,-7),Vector2(10,7)][index]
	return READY_CENTERS[index]
static func clean(pile: int, layer: int, layout: Dictionary) -> Rect2:
	if layout.vertical:return Rect2(Vector2(-20,(-27 if pile==0 else 15)-layer),FOOD.CLEAN_PLATE_SIZE)
	return Rect2(Vector2(-36,(-14 if pile==0 else 2)-layer),FOOD.CLEAN_PLATE_SIZE)
