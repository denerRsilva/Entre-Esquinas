extends RefCounted
## Optional exterior position. Older campaign saves do not require it.
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.get("version")!=1:return false
 for field in ["x","y","zoom"]:
  if not (value.get(field) is int or value.get(field) is float) or not is_finite(float(value[field])):return false
 return value.x>=32 and value.x<=2528 and value.y>=32 and value.y<=2016 and value.zoom>=1 and value.zoom<=2.5
