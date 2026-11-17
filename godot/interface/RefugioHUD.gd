extends Control
## Compact status strip and a skippable, noninteractive defense vignette.
signal action(value: String)
const BARS = preload("res://interface/ArteBarras.gd")
const FRAMES = [preload("res://personagens/Cliente1.tres"),preload("res://personagens/Cliente2.tres"),preload("res://personagens/Cliente3.tres")]
var model: Dictionary = {}
var bounds := Rect2()
var summary := Button.new()
var proceed := Button.new()
var status_rect := Rect2()
var battle_rect := Rect2()
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	summary.text="Moradores";summary.pressed.connect(func():action.emit("status"));add_child(summary)
	proceed.pressed.connect(func():action.emit("skip" if model.get("phase")=="battle" else "retry" if model.get("phase")=="gameover" else "continue"));add_child(proceed)
func sync(data: Variant,area: Rect2,show_day: bool) -> void:
	visible=data!=null
	if data==null:return
	model=data;bounds=area
	position=Vector2.ZERO;size=get_viewport_rect().size
	var event: bool = model.phase!="day"
	mouse_filter=Control.MOUSE_FILTER_STOP if event else Control.MOUSE_FILTER_IGNORE
	status_rect=Rect2(area.position+Vector2(12,54),Vector2(minf(294,area.size.x-24),102))
	summary.visible=not event and show_day
	summary.position=status_rect.position;summary.size=Vector2(status_rect.size.x,30)
	summary.text=str(model.population)+" moradores · "+("Horda hoje" if model.days==0 else "Horda em "+str(model.days)+" dias")
	battle_rect=Rect2(area.position+Vector2(12,maxf(12,(area.size.y-520)/2)),Vector2(area.size.x-24,minf(520,area.size.y-24)))
	proceed.visible=event
	proceed.text="Pular animação" if model.phase=="battle" else "Retomar preparação" if model.phase=="gameover" else "Amanhecer"
	proceed.position=Vector2(area.get_center().x-116,battle_rect.end.y-52);proceed.size=Vector2(232,42)
	set_meta("show_day",show_day)
	queue_redraw()
func text(value: String,p: Vector2,font_size: int=16,col: Color=Color("fff0cf"),center: bool=false) -> void:
	var font := ThemeDB.fallback_font
	if center:p.x-=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x/2
	draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,col)
func block(x: float,y: float,w: float,h: float,col: String) -> void:
	draw_rect(Rect2(x,y,w,h),Color(col))
func character(person: Dictionary,x: float,y: float,frame: int,direction: String="direita",zombie: bool=false) -> void:
	var texture: Texture2D = FRAMES[int(person.skin)-12].get_frame_texture(direction,frame%4)
	draw_texture_rect(texture,Rect2(x,y,32,32),false,Color(0.4,0.65,0.42) if zombie else Color.WHITE)
	if zombie:
		block(x+14,y+12,2,1,"b3d27b");block(x+14,y+14,2,1,"b3d27b")
func battlefield() -> void:
	var width := 384.0
	var scale_value := minf(2,floorf(minf((battle_rect.size.x-16)/width,(battle_rect.size.y-158)/160)))
	scale_value=maxf(0.5,scale_value)
	var origin := Vector2(bounds.get_center().x-width*scale_value/2,battle_rect.position.y+50)
	draw_set_transform(origin,0,Vector2.ONE*scale_value)
	block(0,0,384,160,"14252c");block(0,96,384,64,"3f4e3d")
	for x in range(0,384,32):
		block(x,120,32,1,"556147");block(x,152,32,1,"556147")
	for x in [16,64,112]:
		block(x,36,32,60,"433d35");block(x-2,32,36,8,"2b3233")
		block(x+8,53,12,16,"dba05a" if model.level>0 else "766c4c")
		block(x+13,53,2,16,"4a392b");block(x+8,60,12,2,"4a392b")
	var elapsed: float = model.battle.elapsed
	var frame := int(elapsed*4)%4
	var failure: bool = model.battle.result in ["retreat","fallen"]
	var late: float = clampf((elapsed-5)/3,0,1)
	var fence_x := 218.0
	for y in range(48,144,24):
		block(fence_x,y,8,24,"8e6240");block(fence_x-3,y+4,14,4,"b18951")
		if not failure or elapsed<5:block(fence_x-3,y+14,14,4,"b18951")
	for i in mini(4,int(model.battle.population)):
		var person: Dictionary = model.residents[i]
		var tired: bool = person.energy<40
		var y: float = 48+i*23
		var retreat: float = late*45 if failure else 0.0
		character(person,183-retreat+(0 if tired else sin(elapsed*5+i)*2),y,1 if tired else frame)
		if model.phase=="battle" and elapsed>1 and int(elapsed*5+i)%5==0:block(216,y+13,8,2,"dfc277")
	for i in 5:
		var offset: float = 0 if failure else late*65
		var x: float = 312-(minf(elapsed,5)*13)+(i%2)*34+offset
		character(model.residents[i%model.residents.size()],x,45+i*17,frame,"esquerda",true)
	if model.defeats>0:
		block(18,113,26,5,"704b36");block(24,109,10,4,"997149")
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func _draw() -> void:
	if model.is_empty():return
	if model.phase=="day":
		if not get_meta("show_day",false):return
		draw_rect(status_rect,Color(0.05,0.1,0.08,0.88))
		var names := ["Alimentação","Energia","Moral"]
		for i in 3:
			var key: String = ["food","energy","morale"][i]
			var y: float = status_rect.position.y+34+i*21
			text(names[i],Vector2(status_rect.position.x+8,y+13),13)
			BARS.paint(self,Rect2(status_rect.position.x+100,y+2,status_rect.size.x-143,12),model.stats[key]/100,"patience")
			text(str(int(model.stats[key])),Vector2(status_rect.end.x-32,y+13),13)
		return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.025,0.03,0.96))
	var center: float = bounds.get_center().x
	var titles := {"calm":"A cidade resistiu","held":"Defesa sofrida","retreat":"Recuo para a última defesa","fallen":"O refúgio caiu"}
	text("A horda chegou" if model.phase=="battle" else titles[model.battle.result],Vector2(center,battle_rect.position.y+28),22,Color("fff0cf"),true)
	battlefield()
	var y: float = battle_rect.end.y-120
	var words: String = "Moradores em seus postos" if model.phase=="battle" else "A oficina foi recuperada · tempo de corte −20%" if model.level==1 and model.battle.result in ["calm","held"] else "Um novo morador encontrou abrigo" if model.battle.result in ["calm","held"] else "Uma chance restante · recupere a cidade" if model.phase!="gameover" else "Retome o preparo e tente outra estratégia"
	# Two short lines stay legible in small landscape windows.
	if words.length()>45 and words.contains(" · "):
		var parts := words.split(" · ");text(parts[0],Vector2(center,y),16,Color("e7c695"),true);text(parts[1],Vector2(center,y+20),16,Color("e7c695"),true)
	else:text(words,Vector2(center,y+10),16,Color("e7c695"),true)
	if model.phase!="battle":
		text("Preparo %d  /  Horda %d  ·  Defesa %d"%[model.battle.readiness,model.battle.strength,model.defense],Vector2(center,y+42),14,Color("b8c7b3"),true)
