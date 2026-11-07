extends Node2D
## Static exterior details. Props stay in the map's existing blocked side strips.
func fill(x:float,y:float,w:float,h:float,color:String):
	draw_rect(Rect2(x,y,w,h),Color(color))
func text(value:String,point:Vector2,size:int=14,color:Color=Color("fff0cf")):
	draw_string(ThemeDB.fallback_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func tree(x:float,y:float):
	fill(x-22,y-8,44,12,"5a6748")
	fill(x-5,y-45,10,43,"745135")
	fill(x-23,y-94,46,25,"385c44")
	fill(x-32,y-77,64,34,"426e4b")
	fill(x-23,y-53,46,19,"527b4c")
	fill(x-21,y-87,22,8,"6b9256")
	fill(x+5,y-67,18,7,"638b50")
func bench(x:float,y:float):
	fill(x+5,y+15,5,18,"384c44");fill(x+71,y+15,5,18,"384c44")
	fill(x,y-13,81,9,"98663e");fill(x,y-2,81,9,"b9844f")
	fill(x-3,y+10,87,10,"c29058");fill(x-3,y+19,87,4,"735033")
func _draw():
	# A continuous road, curb and pedestrian crossing in front of the sidewalk.
	fill(0,460,960,180,"646c69")
	fill(0,456,960,5,"e4cf9f");fill(0,461,960,4,"424e49")
	for x in range(20,960,100):fill(x,549,48,4,"e1d19d")
	for y in range(475,635,22):fill(633,y,72,12,"e7dfc4")
	for x in range(0,960,80):fill(x,452,1,5,"907f61")
	# Neighbouring façades and planted edges explain the non-walkable sides.
	fill(0,90,140,110,"bd9971");fill(820,85,140,115,"c9b17f")
	fill(13,114,108,12,"4e7560");fill(840,110,103,12,"8e5b42")
	fill(25,141,36,52,"486151");fill(76,141,37,52,"486151")
	fill(848,138,80,58,"66785b")
	fill(28,145,30,19,"bfc89d");fill(79,145,31,19,"bfc89d")
	text("MERCEARIA",Vector2(19,124),13)
	text("CAFÉ",Vector2(866,120),13)
	fill(0,200,160,240,"71855b");fill(800,200,160,240,"71855b")
	fill(155,200,5,240,"c5b58b");fill(800,200,5,240,"c5b58b")
	fill(0,436,160,4,"c5b58b");fill(800,436,160,4,"c5b58b")
	for x in [74,885]:
		fill(x-33,250,66,166,"647b55")
		fill(x-35,408,70,9,"9d8662")
		tree(x,322)
	bench(39,370);bench(835,370)
	# Restaurant awning and a welcoming entrance, aligned with portal (12, 5).
	fill(404,135,164,18,"46735a")
	for x in range(406,568,24):fill(x,136,12,15,"e9d5a6")
	fill(404,152,164,5,"314c40")
	fill(462,190,76,10,"c7a978")
	fill(464,200,72,5,"d8c094")
	fill(27,30,139,28,"334f42")
	text("Rua das Esquinas",Vector2(34,49),14)
