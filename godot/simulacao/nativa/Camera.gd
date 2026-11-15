extends RefCounted
const MOVE = preload("res://simulacao/nativa/Movimento.gd")
static func level(value: float) -> float:return floor(clampf(value,0.7,2.0)*10+0.5)/10
static func update(state: Dictionary,camera: Dictionary,viewport: Dictionary,zoom_level: float,construction: bool,full_view: bool = false) -> Dictionary:
	if full_view:return expanded_view(state,camera,viewport,zoom_level,construction)
	var result: Dictionary = camera.duplicate(true)
	var player := MOVE.position(state.player)
	var mode := "build" if construction else "play"
	var compact: bool = state.get("compact",false)==true and state.player.room=="restaurant"
	var left := 160.0 if compact else 0.0
	var top := (240.0 if state.get("singleRoom",false) else 80.0) if compact else 0.0
	var width := 800.0 if compact else 960.0
	var height := (400.0 if state.get("singleRoom",false) else 560.0) if compact else 640.0
	result.zoom=(minf(viewport.width/width,(viewport.height-50)/height) if compact else maxf(1,viewport.height/height))*zoom_level
	var maximum_x := maxf(0,left+width-viewport.width/result.zoom)
	var maximum_y := maxf(0,top+height-viewport.height/result.zoom)
	if not construction or camera.get("mode")!=mode:
		result.x=player.x*40+20-viewport.width/2/result.zoom
		result.y=player.y*40+20-viewport.height/2/result.zoom
	result.x=left+(width-viewport.width/result.zoom)/2 if viewport.width/result.zoom>width else clampf(result.x,left,maximum_x)
	result.y=top+(height-viewport.height/result.zoom)/2 if viewport.height/result.zoom>height else clampf(result.y,top,maximum_y)
	result.mode=mode
	return result
static func room_bounds(state: Dictionary) -> Rect2:
	if state.player.room=="restaurant" and state.get("compact",false):
		return Rect2(160,240,800,400) if state.get("singleRoom",false) else Rect2(160,80,800,560)
	return Rect2(0,0,960,640)

static func expanded_view(state: Dictionary,camera: Dictionary,viewport: Dictionary,zoom_level: float,construction: bool) -> Dictionary:
	var bounds := room_bounds(state)
	# Fit the interior with breathing room for the overlay HUD. Wider screens
	# reveal more world/void rather than stretching sprites or adding side bars.
	var base := minf((viewport.width-64)/bounds.size.x,(viewport.height-120)/bounds.size.y)
	var zoom := maxf(0.35,base)*zoom_level
	var limits := bounds.grow(40)
	var player := MOVE.position(state.player)
	var result := {"zoom":zoom,"mode":"build" if construction else "play"}
	# Keep camera coordinates as doubles; Vector2 would quantize every drag.
	for axis in [["x",viewport.width/zoom,player.x*40+20,limits.position.x,limits.size.x],["y",viewport.height/zoom,player.y*40+20,limits.position.y,limits.size.y]]:
		var key: String = axis[0]
		var position: float = camera[key] if construction and camera.get("mode")=="build" else axis[2]-axis[1]/2
		result[key]=axis[3]+(axis[4]-axis[1])/2 if axis[1]>=axis[4] else clampf(position,axis[3],axis[3]+axis[4]-axis[1])
	return result

static func world_pointer(point: Dictionary,rect: Dictionary,viewport: Dictionary,camera: Dictionary) -> Dictionary:
	return {"x":((point.clientX-rect.left)*viewport.width/rect.width/camera.zoom+camera.x)/40,"y":((point.clientY-rect.top)*viewport.height/rect.height/camera.zoom+camera.y)/40}
static func screen_point(x: float,y: float,rect: Dictionary,viewport: Dictionary,camera: Dictionary) -> Dictionary:
	return {"x":rect.left+(x-camera.x)*camera.zoom*rect.width/viewport.width,"y":rect.top+(y-camera.y)*camera.zoom*rect.height/viewport.height}
static func door(state: Dictionary,camera: Dictionary,viewport: Dictionary,rect: Dictionary,construction: bool,management: bool,welcome: bool) -> Dictionary:
	var outside: bool = state.player.room=="street"
	var point := screen_point(675 if outside else 345,245 if outside else 615,rect,viewport,camera)
	return {"hidden":state.player.room not in ["restaurant","street"] or construction or management or welcome or point.x<rect.left+28 or point.x>rect.left+rect.width-28 or point.y<rect.top+22 or point.y>rect.top+rect.height-12,"left":point.x,"top":point.y}
static func drag(camera: Dictionary,point: Dictionary,previous: Dictionary,rect: Dictionary,viewport: Dictionary) -> Dictionary:
	var result: Dictionary = camera.duplicate(true)
	result.x-=(point.clientX-previous.x)*viewport.width/rect.width/camera.zoom
	result.y-=(point.clientY-previous.y)*viewport.height/rect.height/camera.zoom
	return result
static func pan_key(camera: Dictionary,key: String) -> Dictionary:
	var result: Dictionary = camera.duplicate(true)
	result.x+=-30 if key in ["a","arrowleft"] else 30 if key in ["d","arrowright"] else 0
	result.y+=-30 if key in ["w","arrowup"] else 30 if key in ["s","arrowdown"] else 0
	return result
static func resize(width: float,height: float,top: float,ratio: float) -> Dictionary:
	var available := maxf(1,height-top)
	var scale := minf(2,ratio if ratio!=0 else 1)
	return {"viewport":{"width":960,"height":960*available/width},"pixels":{"width":floor(width*scale+0.5),"height":floor(available*scale+0.5)},"height":available}
