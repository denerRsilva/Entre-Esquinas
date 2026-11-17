extends SceneTree
# New 32px cells only. Existing owner atlases are never edited or resized.
var canvas := Image.create(288,32,false,Image.FORMAT_RGBA8)
var cell := 0
func box(x:int,y:int,w:int,h:int,c:String):canvas.fill_rect(Rect2i(cell*32+x,y,w,h),Color(c))
func potato(cut:bool):
	if cut:
		for p in [Vector2i(7,10),Vector2i(17,9),Vector2i(11,18)]:
			box(p.x,p.y,8,7,"#62402a");box(p.x+1,p.y+1,6,4,"#efd094");box(p.x+2,p.y+1,3,2,"#fff0ba")
	else:
		box(7,9,17,15,"#503421");box(5,12,21,9,"#503421");box(8,10,15,13,"#b88045");box(6,13,19,6,"#c89556");box(10,11,9,3,"#edbf78");box(18,18,3,2,"#916136");box(10,17,2,2,"#916136")
func carrot(cut:bool):
	if cut:
		for p in [Vector2i(5,12),Vector2i(14,8),Vector2i(18,19)]:
			box(p.x,p.y,8,6,"#763c21");box(p.x+1,p.y,6,5,"#ed8629");box(p.x+2,p.y+1,3,2,"#ffbe55")
	else:
		box(18,3,3,8,"#55732e");box(23,5,3,5,"#86a13e");box(14,5,4,5,"#86a13e");box(14,10,10,4,"#713a20");box(11,14,11,5,"#713a20");box(8,19,10,4,"#713a20");box(6,23,6,3,"#713a20");box(15,11,8,4,"#ee8528");box(12,15,9,4,"#ee8528");box(9,19,8,4,"#ee8528");box(7,23,4,2,"#ee8528");box(15,12,4,2,"#ffbf52");box(11,18,4,2,"#ffbf52")
func dish(kind:int):
	box(5,9,22,15,"#49372d");box(2,12,28,9,"#49372d");box(5,10,22,13,"#f0dfbd");box(3,13,26,7,"#fff1d7");box(7,12,18,9,"#bb9a69")
	if kind==0:
		box(6,13,20,7,"#c18a42");box(9,14,4,3,"#efcc8b");box(17,16,5,3,"#e4b86c");box(14,13,2,2,"#6e7935")
	else:
		box(7,12,16,8,"#f1d49f");box(9,11,11,2,"#fff0c8")
		for p in [Vector2i(9,15),Vector2i(18,16),Vector2i(14,12)]:box(p.x,p.y,4,3,"#e98b33")
		if kind==2:box(7,18,18,2,"#c28e40");box(17,13,5,3,"#d6b57b")
func _initialize():
	canvas.fill(Color.TRANSPARENT)
	potato(false);cell+=1;potato(true);cell+=1;carrot(false);cell+=1;carrot(true);cell+=1
	for i in 3:dish(i);cell+=1
	# Nutrition drumstick and estimated-time clock, native 32px as well.
	box(17,16,5,5,"#64482f");box(20,20,6,4,"#f7ebcf");box(24,19,3,3,"#fff3db");box(23,23,3,3,"#fff3db");box(5,6,14,13,"#593524");box(3,9,18,7,"#593524");box(6,7,12,11,"#b66b36");box(7,8,7,4,"#edaa53");cell+=1
	box(9,3,14,3,"#513b2e");box(5,6,22,20,"#513b2e");box(9,26,14,3,"#513b2e");box(7,7,18,18,"#eedaa5");box(10,5,12,22,"#eedaa5");box(15,8,2,10,"#624b3b");box(15,16,7,2,"#624b3b");box(15,5,2,2,"#ad8859");box(15,25,2,2,"#ad8859")
	var err := canvas.save_png("res://arte/inicio-32.png")
	print("Arte 32px criada: ",err);quit(err)
