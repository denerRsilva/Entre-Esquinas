extends RefCounted
# Physical world sizes. Camera zoom is applied later to the whole scene.
# HUD/menu icons may use other sizes; carried and placed items share these.
const CLEAN_PLATE_SIZE := Vector2(20,12)
const DISH_SIZE := Vector2(20,14)
const INGREDIENT_SIZE := Vector2(24,24)
const CLEAN_PLATE_SOURCE := Rect2(125,166,1249,736)
const EARLY_ATLAS = preload("res://arte/inicio-32.png")
const EARLY_KEYS = ["batata","batata_cut","cenoura","cenoura_cut","caldoBatata","arrozCenoura","canja","nutricao","tempo"]
const ATLAS = preload("res://arte/taverna/alimentos.png")
const KEYS = ["arroz","legumes","frango","arrozLegumes","sopa","frangoArroz","legumes_cut","frango_cut"]
const CROPS = [Rect2(154,44,310,306),Rect2(594,35,344,323),Rect2(1054,103,361,244),Rect2(83,714,440,280),Rect2(588,714,350,280),Rect2(1004,714,448,280),Rect2(586,425,361,212),Rect2(1067,428,327,208)]
static var cache: Dictionary = {}

static func food_key(item: String) -> String:
	if item in KEYS or item in EARLY_KEYS:return item
	if item.begins_with("dish_"):return item.substr(5)
	if item.begins_with("pot_"):return item.split("_")[1]
	return ""

static func texture(item: String) -> Texture2D:
	var key := food_key(item)
	var index := KEYS.find(key)
	var early := EARLY_KEYS.find(key)
	if index<0 and early<0:return null
	if not cache.has(key):
		var tex := AtlasTexture.new()
		tex.atlas=EARLY_ATLAS if early>=0 else ATLAS
		tex.region=Rect2(early*32,0,32,32) if early>=0 else CROPS[index]
		tex.filter_clip=true
		cache[key]=tex
	return cache[key]

# Preserve Math.round's tie rule, including negative coordinates.
static func pixel(value: float) -> float:
	return floorf(value+0.5)

static func image_command(op: Array) -> Array:
	var key := food_key(str(op[1]))
	var index := KEYS.find(key)
	var early := EARLY_KEYS.find(key)
	if index<0 and early<0:return []
	var crop: Rect2 = Rect2(early*32,0,32,32) if early>=0 else CROPS[index]
	var ratio := minf(float(op[4])/crop.size.x,float(op[5])/crop.size.y)
	var width := crop.size.x*ratio
	var height := crop.size.y*ratio
	var x := pixel(float(op[2])+(float(op[4])-width)/2)
	var y := pixel(float(op[3])+(float(op[5])-height)/2)
	return ["img","inicio-32.png" if early>=0 else "taverna/alimentos.png",crop.position.x,crop.position.y,crop.size.x,crop.size.y,pixel(float(op[8])+x*float(op[6])),pixel(float(op[9])+y*float(op[7])),pixel(width)*float(op[6]),pixel(height)*float(op[7]),op[10]]
