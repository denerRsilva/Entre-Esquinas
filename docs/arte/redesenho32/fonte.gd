extends SceneTree
## New pixel clusters drawn on final-size canvases. No source image is loaded or resized.
const C = {
 "ink":"30271f","dark":"493323","wood0":"61402b","wood1":"805033","wood2":"a36a3c","wood3":"bf864a","wood4":"dda362","wood5":"edc080",
 "metal0":"2e3432","metal1":"484d48","metal2":"686e63","metal3":"91968a","metal4":"bbc0ad",
 "ivory0":"8f785c","ivory1":"b9a17e","ivory2":"dfccaa","ivory3":"f1e1bf","ivory4":"fff0d2",
 "rust0":"784a32","rust1":"a96b43","rust2":"c48c58","stone0":"484e49","stone1":"666a60","stone2":"818477","stone3":"a1a18d",
 "green0":"35492f","green1":"52663b","green2":"778d48","green3":"a1b65e","green4":"c3cb7d",
 "red0":"6e3430","red1":"9b4f3e","red2":"bf7251","red3":"da9b68",
 "orange0":"98451f","orange1":"c26928","orange2":"e59034","orange3":"ffc15b","yellow":"ffe28b",
 "blue0":"344c4e","blue1":"4e7070","blue2":"77958b","blue3":"a4b6a4",
 "skin0":"8b5534","skin1":"bc8150","skin2":"dfa96e","skin3":"f1c791",
 "pink0":"a75f4f","pink1":"d58b75","pink2":"ebb39b","purple0":"4e3b4b","purple1":"785369","black":"181f1d"
}
var im: Image
var entries: Array = []
var art := {}
var out: String
func color(k: String) -> Color:return Color(C.get(k,k))
func begin(w: int=32,h: int=32):
 im=Image.create(w,h,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
func box(x: int,y: int,w: int,h: int,k: String):
 if w>0 and h>0:im.fill_rect(Rect2i(x,y,w,h).intersection(Rect2i(Vector2i.ZERO,im.get_size())),color(k))
func px(x: int,y: int,k: String):
 if x>=0 and x<im.get_width() and y>=0 and y<im.get_height():im.set_pixel(x,y,color(k))
func line(x0: int,y0: int,x1: int,y1: int,k: String):
 var dx := absi(x1-x0);var sx := 1 if x0<x1 else -1;var dy := -absi(y1-y0);var sy := 1 if y0<y1 else -1;var err := dx+dy
 while true:
  px(x0,y0,k)
  if x0==x1 and y0==y1:break
  var e := 2*err
  if e>=dy:err+=dy;x0+=sx
  if e<=dx:err+=dx;y0+=sy
func poly(coords: Array,k: String):
 var pts := PackedVector2Array();var lo := Vector2i(999,999);var hi := Vector2i.ZERO
 for i in range(0,coords.size(),2):
  var p := Vector2i(coords[i],coords[i+1]);pts.append(Vector2(p));lo=lo.min(p);hi=hi.max(p)
 for y in range(maxi(0,lo.y),mini(im.get_height(),hi.y+1)):
  for x in range(maxi(0,lo.x),mini(im.get_width(),hi.x+1)):
   if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),pts):px(x,y,k)
func oval(cx: float,cy: float,rx: float,ry: float,k: String):
 for y in range(maxi(0,int(cy-ry)),mini(im.get_height(),int(ceil(cy+ry)))):
  for x in range(maxi(0,int(cx-rx)),mini(im.get_width(),int(ceil(cx+rx)))):
   if pow((x+0.5-cx)/rx,2)+pow((y+0.5-cy)/ry,2)<=1:px(x,y,k)
func grain(x: int,y: int,w: int,h: int,seed: int=0):
 for i in 9:
  var xx := x+posmod(i*13+seed,maxi(1,w-5));var yy := y+posmod(i*7+seed,maxi(1,h-2))
  box(xx,yy,2+i%3,1,"wood1" if i%2 else "wood3")
func wood_top(x: int,y: int,w: int,h: int):
 box(x,y,w,h,"ink");box(x+1,y+1,w-2,h-2,"wood2");box(x+2,y+1,w-4,1,"wood4");box(x+1,y+2,1,h-4,"wood3");box(x+2,y+h-3,w-4,1,"wood1")
 for row in range(y+7,y+h-3,7):box(x+2,row,w-4,1,"wood0");box(x+2,row+1,w-4,1,"wood3")
 grain(x+3,y+3,w-6,h-6,3)
func table(decorated: bool=false):
 begin(64,64)
 # The same open worktable base is used by cutting and plating, without tools or drawers.
 for x in [5,53]:box(x,28,6,32,"ink");box(x+1,29,4,29,"wood1");box(x+1,30,1,27,"wood3");box(x+4,33,1,24,"wood0")
 box(10,46,44,5,"ink");box(11,47,42,2,"wood2");box(12,47,40,1,"wood3")
 box(3,27,58,9,"ink");box(5,28,54,6,"wood1");box(6,28,52,2,"wood3");grain(7,31,48,3,1)
 wood_top(2,8,60,24)
 if decorated:
  poly([31,10,46,20,32,32,17,21],"wood0");poly([31,11,44,20,32,30,19,21],"ivory2");poly([31,13,41,20,32,28,22,21],"red2")
  for y in [17,23]:line(25,y,36,y+2,"ivory3")
  oval(32,21,5,3,"ink");oval(32,20,4,2,"wood4");box(30,12,4,8,"ivory1");box(30,12,2,7,"ivory4");box(31,8,2,5,"orange2");px(31,9,"yellow");px(31,8,"orange1")
func chair(direction: int):
 begin()
 if direction<2:
  box(5,3,22,5,"ink");box(6,4,20,3,"wood2");box(7,4,18,1,"wood4")
  for x in [6,12,18,24]:box(x,8,2,12,"wood0");box(x,8,1,10,"wood3")
  if direction==1:box(6,8,20,6,"wood1");box(7,8,18,1,"wood2")
  box(4,18,24,8,"ink");box(5,19,22,4,"wood2");box(6,19,20,1,"wood4");box(6,22,20,1,"wood1")
  for x in [5,24]:box(x,24,3,7,"ink");box(x+1,24,1,6,"wood3")
  box(8,27,16,2,"wood0")
 else:
  var back := 22 if direction==2 else 7
  box(back,3,4,27,"ink");box(back+1,4,2,25,"wood2");box(back+1,4,1,23,"wood4")
  box(5,18,23,7,"ink");box(6,19,21,4,"wood2");box(7,19,18,1,"wood4");box(7,22,18,1,"wood1")
  for x in [6,23]:box(x,24,3,7,"ink");box(x+1,24,1,6,"wood3")
func plate(dirty: bool=false):
 begin();oval(16,18,10,6,"ink");oval(16,18,9,5,"ivory0");oval(16,17,9,5,"ivory1");oval(16,16,10,6,"ink");oval(16,16,9,5,"ivory2");oval(15.5,15,8.5,4,"ivory3");oval(16,16,7,3,"ivory1");oval(16,16,6,2,"ivory3")
 box(10,12,5,1,"ivory4");px(8,14,"ivory4");box(19,20,3,1,"ivory4")
 if dirty:
  box(12,15,3,2,"rust1");px(13,17,"rust2");box(19,14,2,2,"rust1");px(18,18,"rust0");px(10,17,"rust1")
func pot(burned: bool=false):
 begin();box(1,12,5,7,"ink");box(2,13,3,4,"metal3");box(26,12,5,7,"ink");box(27,13,3,4,"metal2")
 oval(16,21,11,8,"ink");box(5,11,22,11,"ink");box(6,12,20,11,"metal1" if burned else "metal2");oval(16,22,10,6,"metal1" if burned else "metal2")
 box(8,14,3,9,"metal3" if not burned else "rust0");box(11,15,1,9,"metal4" if not burned else "rust1");box(24,14,2,8,"metal1")
 oval(16,11,12,6,"ink");oval(16,11,11,5,"metal3");oval(16,10.5,9,3.5,"metal0" if burned else "metal1");box(9,7,10,1,"metal4")
 if burned:box(16,22,3,3,"rust1");px(20,19,"rust2");box(7,18,2,2,"rust0")
func lid():
 begin();oval(16,20,14,6,"ink");oval(16,19,13,5,"metal2");oval(16,17,11,4,"metal3");box(10,17,8,1,"metal4");box(12,9,8,7,"ink");box(14,10,4,4,"metal1");box(13,10,6,1,"metal3");box(14,12,4,3,"black")
func board(knife: bool=true):
 begin();wood_top(2,9,23,17);box(25,14,5,7,"ink");box(25,15,4,5,"wood2");box(27,16,1,2,"wood0")
 line(7,14,17,16,"wood1");line(10,12,10,19,"wood3")
 if knife:
  poly([19,8,25,4,28,4,28,7,21,17,18,16],"ink");poly([20,9,26,5,27,5,26,8,21,15,19,15],"metal4");line(21,9,26,5,"ivory4");line(18,17,15,22,"ink");line(19,17,16,22,"wood1");px(17,20,"wood3")
func stove(lit: bool=false):
 begin(64,64)
 # Empty cooktop: the simulation supplies the actual pot.
 box(42,2,14,23,"ink");box(44,3,10,21,"metal1");box(45,4,2,18,"metal2");box(43,1,12,3,"ink");box(44,1,10,1,"metal3")
 box(4,26,56,33,"ink");box(5,28,54,29,"metal1");box(6,29,52,2,"metal3");box(6,53,52,3,"metal2")
 box(3,22,58,9,"ink");box(4,23,56,6,"metal2");box(5,23,54,1,"metal3");box(7,28,49,1,"metal1")
 for x in [15,31]:oval(x,26,6,2,"metal0");box(x-3,25,6,1,"ink")
 box(9,34,29,18,"ink");box(11,36,25,14,"metal2");box(12,37,23,12,"orange0" if lit else "metal0")
 if lit:
  box(13,38,21,10,"orange2");box(15,39,17,7,"yellow");box(17,39,4,6,"ivory4");box(27,40,3,5,"orange3")
 for x in [17,25]:box(x,37,2,12,"metal1")
 box(12,42,23,2,"metal1");box(41,35,14,15,"ink");box(42,36,12,13,"metal2");box(44,38,8,1,"metal3");box(44,43,3,2,"metal0")
 for x in [7,52]:box(x,58,5,4,"ink");box(x+1,58,3,2,"metal2")
 px(49,48,"rust1");px(50,47,"rust0");box(8,51,3,1,"rust0")
func fridge(opened: bool=false):
 begin(64 if opened else 32,64)
 var x := 26 if opened else 3;var w := 30 if opened else 26
 poly([x+4,2,x+w-4,2,x+w,6,x+w,60,x+2,62,x,58,x,7],"ink")
 box(x+1,8,w-2,51,"ivory1");box(x+3,5,w-6,3,"ivory3");box(x+2,8,w-4,2,"ivory4");box(x+w-3,11,1,45,"ivory0")
 if opened:
  box(x+4,12,w-8,43,"metal0");box(x+5,13,w-10,40,"ivory0")
  for y in [24,38,52]:box(x+4,y,w-8,3,"ivory3");box(x+5,y+2,w-10,1,"ivory0")
  poly([x,8,8,17,7,59,x,57],"ink");poly([x-1,11,10,18,9,56,x-1,54],"ivory2");line(11,20,10,53,"ivory4");line(23,15,23,53,"ivory0")
 else:
  box(x+2,11,w-5,45,"ivory2");box(x+3,12,2,39,"ivory3");box(x+20,25,2,20,"ink");box(x+21,26,1,18,"ivory4")
  poly([8,17,13,17,13,21,11,21,10,24,7,23,7,19],"rust1");box(19,47,4,4,"rust1");px(22,46,"rust2");box(8,52,4,3,"rust1")
 box(x+5,61,4,2,"metal0");box(x+w-9,61,4,2,"metal0")
func sink():
 table();box(4,30,56,28,"ink");box(6,32,52,24,"wood1")
 for x in [8,33]:box(x,34,23,20,"wood0");box(x+1,35,21,18,"wood2");box(x+2,35,19,1,"wood3");box(x+3,37,1,14,"wood1")
 box(27,41,2,4,"wood4");box(35,41,2,4,"wood4")
 box(2,12,60,21,"ink");box(3,13,58,18,"ivory1");box(4,13,56,2,"ivory3");box(5,29,54,2,"ivory2")
 box(17,17,30,11,"ivory0");box(19,18,26,8,"blue0");box(20,18,24,1,"ivory0");box(21,20,22,5,"blue1");box(22,20,20,1,"blue2")
 for x in [6,49]:
  for y in [18,21,24]:box(x,y,9,1,"ivory0");box(x,y-1,8,1,"ivory2")
 box(30,3,4,15,"ink");box(31,4,2,12,"metal3");box(33,2,8,4,"ink");box(34,3,6,2,"metal3");box(39,5,4,5,"ink");box(40,5,2,4,"metal2")
 for x in [11,49]:box(x,10,4,6,"metal1");box(x-1,10,6,2,"wood3");px(x+1,10,"wood5")
func rack(full: bool=false,cabinet: bool=false):
 begin(32,64);box(3,4,26,57,"ink");box(5,6,22,52,"wood0")
 for y in [7,23,39,55]:box(5,y,22,4,"ink");box(5,y,22,2,"wood3");box(6,y,20,1,"wood4")
 for x in [3,26]:box(x,4,3,57,"wood2");box(x,5,1,54,"wood4")
 box(7,60,4,3,"ink");box(21,60,4,3,"ink")
 if cabinet:
  box(5,44,22,13,"ink");box(6,45,9,11,"wood2");box(17,45,9,11,"wood2");box(7,46,7,1,"wood4");box(18,46,7,1,"wood4");px(13,50,"wood5");px(18,50,"wood5")
 if full:
  for y in [12,28]:
   box(9,y,10,9,"ivory1");box(9,y,10,2,"ivory3");box(20,y+3,4,6,"wood3");px(21,y+4,"wood5")
func trash():
 begin();box(6,9,20,20,"ink");box(8,10,16,17,"metal2");oval(16,27,8,3,"metal1")
 for x in [9,14,19]:box(x,12,1,14,"metal3");box(x+1,12,1,14,"metal1")
 oval(16,9,12,5,"ink");oval(16,8,11,4,"metal2");box(11,2,10,6,"ink");box(13,3,6,4,"metal3");box(14,4,4,2,"metal1");box(8,7,9,1,"metal4")
func bench():
 begin(64,32);box(6,15,5,14,"ink");box(53,15,5,14,"ink");box(7,16,3,11,"wood2");box(54,16,3,11,"wood2");wood_top(2,6,60,13)
func shelf_jars():
 begin(64,32);box(2,22,60,5,"ink");box(3,23,58,2,"wood2");box(4,23,56,1,"wood4")
 for x in [8,25,43]:
  box(x,6,12,17,"ink");box(x+1,8,10,13,"ivory1" if x==8 else ("wood3" if x==25 else "metal2"));box(x+1,6,10,3,"wood0");box(x+2,8,8,1,"ivory3");box(x+3,10,2,8,"ivory2" if x==8 else "wood4")
func crate(full: bool=false):
 begin();box(2,10,28,19,"ink");box(3,11,26,16,"wood1")
 for y in [12,18,24]:box(3,y,26,4,"wood2");box(4,y,24,1,"wood3");box(4,y+3,24,1,"wood0")
 for x in [4,25]:box(x,10,3,18,"wood0");box(x,11,1,15,"wood4")
 if full:
  for x in [7,14,21]:oval(x,9,5,5,"green0");oval(x-1,8,3,3,"green2");px(x-1,7,"green3")
func barrel():
 begin();oval(16,25,11,5,"ink");box(5,8,22,17,"ink");box(6,9,20,15,"wood2");oval(16,24,10,4,"wood1")
 for x in [9,14,20]:box(x,11,1,13,"wood0");box(x+1,11,1,12,"wood3")
 oval(16,8,11,5,"ink");oval(16,8,10,4,"wood3");oval(16,8,8,2,"wood1");box(6,13,20,3,"metal1");box(6,13,19,1,"metal3");box(6,22,20,3,"metal1");box(6,22,19,1,"metal2")
func towel():
 begin();poly([9,5,23,5,23,27,19,25,16,28,12,26,9,27],"ivory0");box(10,6,12,18,"ivory3");box(11,6,1,18,"ivory4");box(19,6,1,18,"red1");box(10,20,12,2,"red2")
func flower_pot(flowers: bool=false,hanging: bool=false):
 begin(32,64 if hanging else 32);var y := 28 if hanging else 9
 if hanging:
  line(16,1,3,29,"wood0");line(16,1,28,29,"wood0");box(15,0,3,3,"metal0")
 box(8,y+12,16,9,"ink");box(9,y+13,14,7,"rust1");box(10,y+14,3,5,"rust2");box(7,y+10,18,4,"ink");box(8,y+11,16,2,"wood3")
 for p in [Vector2i(9,y+4),Vector2i(14,y),Vector2i(21,y+2),Vector2i(17,y+7),Vector2i(6,y+8),Vector2i(24,y+7)]:
  oval(p.x,p.y+3,5,4,"green0");oval(p.x-1,p.y+2,3,3,"green1");line(p.x-2,p.y+1,p.x+2,p.y+3,"green3")
  if flowers:oval(p.x,p.y+1,2,2,"red2");px(p.x,p.y,"yellow")
 if hanging:
  for x in [5,11,25]:
   line(x,y+10,x-1,y+29,"green0")
   for yy in [y+14,y+21,y+27]:oval(x-2,yy,3,2,"green1");px(x-3,yy-1,"green3")
func lantern(lit: bool=true):
 begin();box(12,1,8,6,"ink");box(14,2,4,3,"metal2");poly([12,7,20,7,25,12,7,12],"ink");box(7,12,18,16,"ink");box(9,13,14,13,"wood1")
 box(10,14,12,10,"orange2" if lit else "metal1");box(12,14,7,10,"yellow" if lit else "metal2");box(14,15,3,8,"ivory4" if lit else "metal3")
 for x in [9,15,21]:box(x,13,1,13,"metal0")
 box(7,26,18,3,"metal0");box(10,29,12,2,"metal1")
func candle():
 begin();oval(16,26,8,4,"ink");oval(16,25,7,3,"wood3");box(13,13,6,12,"ivory1");box(13,13,3,11,"ivory4");box(17,14,1,9,"ivory2");oval(16,10,3,5,"orange1");oval(16,10,2,3,"yellow");px(16,8,"ivory4")
func rug():
 begin(96,64);box(2,4,92,56,"wood0");box(4,6,88,52,"red0");box(5,7,86,50,"wood3");box(8,10,80,44,"red1");box(11,13,74,38,"red0")
 for x in range(4,94,5):box(x,3,2,2,"ivory1");box(x,59,2,2,"ivory1")
 for y in range(7,58,7):box(5,y,3,3,"wood4");box(88,y,3,3,"wood4")
 for x in range(14,82,8):box(x,11,3,2,"red3");box(x,51,3,2,"red3")
 poly([48,22,60,32,48,42,36,32],"red1");poly([48,25,56,32,48,39,40,32],"wood3");poly([48,28,52,32,48,36,44,32],"red1")
func sign_board(warning: bool=false):
 begin();wood_top(2,5,28,23)
 if warning:
  poly([16,8,26,24,6,24],"ink");poly([16,10,24,23,8,23],"wood4");box(15,14,2,5,"ink");px(15,21,"ink")
 else:
  box(7,10,8,9,"ivory2");box(17,12,8,11,"ivory1");box(8,11,5,1,"rust1");box(18,14,5,1,"wood0");box(18,17,4,1,"wood0")
func rice():
 begin();poly([8,6,24,6,22,11,26,17,27,27,23,30,8,30,5,27,6,16,10,11],"ink");poly([9,7,23,7,21,12,24,17,25,27,22,28,9,28,7,26,8,17,11,12],"ivory1");box(10,15,3,10,"ivory2");box(10,25,12,2,"ivory0");oval(16,7,7,4,"ivory3");oval(16,6,5,2,"ivory4");box(10,10,12,2,"wood0");line(14,18,19,21,"wood1");line(13,20,17,23,"wood1");line(16,17,21,20,"wood1")
func carrot():
 begin();poly([19,11,20,5,22,3,24,4,23,9,27,6,30,7,29,10,24,13],"green0");poly([20,11,22,5,23,5,22,11,28,8,28,10,23,13],"green2");px(22,6,"green3")
 poly([17,11,22,13,23,16,18,22,11,28,4,30,5,25,10,18],"ink");poly([17,12,21,14,21,16,16,21,10,27,5,29,7,24,11,18],"orange1");poly([17,13,20,14,17,18,12,21,9,26,6,28,9,22,12,17],"orange2");box(15,14,3,1,"orange3");box(16,18,3,1,"orange0");box(11,23,2,1,"orange0")
func potato():
 begin();oval(16,18,14,11,"ink");oval(16,17,13,10,"wood2");oval(14,15,11,7,"wood3");oval(12,13,7,3,"wood4");box(9,12,4,1,"wood5");box(11,20,2,1,"wood0");box(22,15,2,2,"wood1");px(24,22,"wood0");px(8,17,"wood1");box(18,23,2,1,"wood1")
func cabbage():
 begin();oval(16,17,13,12,"ink");oval(16,16,12,11,"green0");oval(15,15,10,10,"green1");oval(14,14,8,8,"green2");oval(12,11,4,4,"green3")
 for p in [[8,14,13,23],[13,9,20,22],[20,10,23,19],[7,17,17,25]]:line(p[0],p[1],p[2],p[3],"green0")
 line(12,15,17,19,"green4");line(19,12,18,20,"green3")
func chicken():
 begin();poly([4,12,8,8,17,7,23,11,28,11,30,15,27,18,27,23,21,27,10,27,3,22,2,17],"ink");poly([5,12,9,9,17,8,22,12,27,12,28,15,24,18,25,22,20,25,10,25,5,21,3,17],"pink0");oval(14,15,9,7,"pink1");oval(12,13,6,4,"pink2");line(15,18,20,23,"pink0");poly([21,18,25,13,28,13,28,15,25,18,23,23,20,24,19,22],"pink2");box(7,12,4,1,"ivory3")
func chunks(kind: String):
 begin()
 for i in 5:
  var x: int = [5,14,22,9,18][i];var y: int = [12,9,15,22,23][i]
  if kind=="carrot":
   oval(x,y+3,5,4,"ink");oval(x,y+2,4,3,"orange1");oval(x,y,5,3,"ink");oval(x,y,4,2,"orange2");box(x-1,y-1,2,1,"orange3")
  else:
   box(x-3,y-3,8,8,"ink");box(x-2,y-2,6,6,"wood3" if kind=="potato" else "pink1");box(x-2,y-2,5,3,"ivory3" if kind=="potato" else "pink2");box(x+2,y,2,3,"wood2" if kind=="potato" else "pink0");px(x-1,y-2,"ivory4")
func cut_vegetables():
 chunks("carrot")
 for p in [[8,8],[22,22],[6,24]]:
  box(p[0],p[1],4,3,"green0");box(p[0],p[1],3,2,"green2");px(p[0],p[1],"green3")
func dish(kind: String):
 plate();oval(16,16,7,3,"orange0" if kind in ["sopa","caldoBatata","canja"] else "wood3")
 if kind in ["arrozLegumes","arrozCenoura","frangoArroz"]:
  oval(14,14,5,4,"ivory2")
  for p in [[11,12],[14,12],[17,14],[12,15],[10,16],[15,16]]:box(p[0],p[1],2,1,"ivory4");px(p[0],p[1]+1,"wood4")
 if kind in ["arrozLegumes","arrozCenoura","sopa","canja"]:
  for p in [[19,14],[16,17],[21,16]]:box(p[0],p[1],2,2,"orange2");px(p[0],p[1],"orange3")
  box(20,17,2,1,"green1");px(22,16,"green3")
 if kind=="arrozLegumes":
  box(19,13,3,2,"green0");box(19,13,2,1,"green3");box(21,16,2,2,"green2")
 if kind=="caldoBatata":
  for p in [[11,14],[18,13],[16,17]]:box(p[0],p[1],3,2,"wood3");box(p[0],p[1],2,1,"ivory3");px(p[0],p[1],"ivory4")
 if kind=="frangoArroz":oval(20,16,4,2,"rust0");oval(20,15,3,2,"orange1");box(19,14,2,1,"wood4")
 if kind=="canja":box(11,15,3,1,"ivory2");box(18,16,3,1,"ivory2");px(12,14,"ivory4")
 px(10,17,"green2");px(17,13,"green2")
func clock():
 begin();oval(16,16,12,12,"ink");oval(16,16,11,11,"wood3");oval(16,16,9,9,"ivory3");line(16,9,16,16,"wood0");line(16,16,21,19,"wood0");box(15,15,3,3,"ink");box(15,6,2,2,"wood1");box(7,15,2,2,"wood1");box(23,15,2,2,"wood1")
func nutrition():
 begin();poly([5,20,12,13,13,7,18,4,24,5,28,10,27,16,23,20,17,21,11,27,7,27,4,24],"ink");oval(21,12,7,7,"orange0");oval(20,11,6,6,"orange1");oval(19,9,3,3,"orange2");line(14,17,8,23,"ivory3");box(5,21,3,5,"ivory4");box(7,24,3,3,"ivory2")
func floor_tile(kind: int):
 begin()
 if kind in [0,1]:
  box(0,0,32,32,"wood2")
  for row in 4:
   var y := row*8;box(0,y,32,1,"wood3");box(0,y+7,32,1,"wood0");var joint := 9 if row%2==0 else 25;box(joint,y,1,7,"wood1");px(joint+1,y+1,"wood4")
  grain(1,1,30,29,kind*17)
 elif kind in [2,3]:
  box(0,0,32,32,"stone0")
  for y in 2:
   for x in 2:
    box(x*16+1,y*16+1,15,15,"stone1" if (x+y)%2==0 else "stone2");box(x*16+2,y*16+2,13,1,"stone3");box(x*16+2,y*16+15,13,1,"stone1")
   if kind==3:box(19,22,2,1,"stone1");px(20,23,"stone0")
 elif kind==4:
  box(0,0,32,32,"wood1");box(0,0,32,1,"wood2")
  for p in [[3,9],[18,23],[24,6],[9,25]]:box(p[0],p[1],2,1,"wood3")
 elif kind in [5,6]:
  box(0,0,32,32,"stone0")
  for y in 3:
   for x in 3:
    var xx := x*13-6*(y%2);var yy := y*12-1;box(xx+1,yy+1,12,11,"stone1");box(xx+2,yy+2,10,1,"stone2")
  if kind==6:
   for p in [[1,11],[14,24],[28,9]]:box(p[0],p[1],3,2,"green0");px(p[0],p[1],"green2")
 elif kind==7:
  box(0,0,32,32,"green0")
  for i in 28:
   var x := posmod(i*13,32);var y := posmod(i*7,32);box(x,y,1,3,"green1");px(x+1,y,"green2")
func wall_tile(kind: int):
 begin()
 if kind<=3:
  box(0,0,32,32,"ivory1");box(0,0,32,3,"ink");box(0,3,32,4,"wood2");box(0,3,32,1,"wood4");box(0,7,32,1,"wood0")
  if kind%2==1:
   box(0,15,32,3,"wood0");box(0,16,32,2,"wood3");box(0,18,32,12,"wood1")
   for x in range(2,32,8):box(x,19,1,11,"wood0");box(x+1,19,1,10,"wood2")
   box(0,30,32,2,"wood0")
  else:
   for p in [[8,14],[24,23],[16,28]]:box(p[0],p[1],2,1,"ivory0");px(p[0]+2,p[1],"ivory2")
  if kind>=2:
   for y in range(9,32,8):box(0,y,32,1,"ivory0")
   for x in [7,15,23,31]:box(x,8,1,24,"ivory0")
 elif kind in [4,5]:
  box(8,0,16,32,"ink");box(10,0,12,32,"wood2");box(11,0,2,32,"wood4");box(20,0,2,32,"wood1");grain(14,0,5,32,1 if kind==4 else 4)
 elif kind in [6,7]:
  box(0,10,32,14,"ink");box(0,12,32,10,"wood2");box(0,12,32,2,"wood4");box(0,20,32,2,"wood1")
  if kind==7:box(0,17,32,2,"wood1")
 else:
  wall_tile(4);box(16,10,16,14,"ink");box(16,12,16,10,"wood2");box(16,12,16,2,"wood4")
func window():
 begin(32,64);box(2,7,28,48,"ink");box(3,8,26,46,"wood1");box(5,10,22,42,"wood3");box(7,12,18,38,"ink")
 for y in [13,33]:
  for x in [8,18]:box(x,y,7,16,"ivory2");box(x,y,6,3,"ivory4");box(x+5,y+3,1,12,"ivory0")
 box(6,30,20,3,"wood0");box(15,11,3,40,"wood0");box(1,54,30,4,"ink");box(2,54,28,2,"wood4")
func door():
 begin(32,64);box(1,0,30,64,"ink");box(3,1,26,61,"wood1");box(4,2,24,2,"wood4");box(6,5,20,54,"wood0");box(7,6,18,51,"wood2")
 for x in [12,19]:box(x,7,1,48,"wood0");box(x+1,7,1,48,"wood3")
 for y in [13,44]:box(6,y,20,3,"metal0");box(7,y,18,1,"metal2")
 box(23,29,3,6,"ink");box(24,30,1,4,"wood4")
func roof(kind: int):
 begin();box(0,0,32,32,"rust0")
 for y in 2:
  for x in 4:
   var xx := x*9-4*(y%2);box(xx,y*16+1,8,14,"rust1");box(xx+1,y*16+2,1,12,"rust2");box(xx,y*16+15,8,1,"wood0")
 if kind:box(0,28,32,4,"ink");box(0,29,32,1,"wood2")
func counter(wide: bool,part: int):
 var depth := 24 if wide else 12;var width := 24 if wide else 12;var x0 := (32-width)/2
 begin(32,32 if part in [3,4] else 64)
 if part in [3,4]:
  box(x0,0,width,32,"ink");box(x0+1,0,width-2,32,"wood2");box(x0+1,0,1,32,"wood4");box(x0+width-2,0,1,32,"wood0")
  box(x0+4,0,1,32,"wood1")
  if part==3:box(x0,0,width,1,"ink");box(x0+1,1,width-2,1,"wood4")
  return
 var from_x := 0;var to_x := 32
 if part==5:from_x=x0;to_x=x0+width
 if part==6:from_x=x0
 if part==7:to_x=x0+width
 if part in [5,6,7]:
  box(x0,0,width,32,"ink");box(x0+1,0,width-2,32,"wood2");box(x0+1,0,1,32,"wood4");box(x0+width-2,0,1,32,"wood0");box(x0+4,0,1,32,"wood1")
 box(from_x,32-depth,to_x-from_x,depth,"wood2");box(from_x,32-depth,to_x-from_x,1,"wood4")
 for y in range(36-depth,31,6):box(from_x,y,to_x-from_x,1,"wood1");box(from_x,y+1,to_x-from_x,1,"wood3")
 box(from_x,32,to_x-from_x,3,"wood3");box(from_x,32,to_x-from_x,1,"wood5");box(from_x,35,to_x-from_x,23,"ink");box(from_x,36,to_x-from_x,20,"wood1")
 for x in range(from_x+3,to_x-1,8):box(x,37,1,18,"wood0");box(x+1,37,1,18,"wood2")
 box(from_x,56,to_x-from_x,2,"wood0");box(from_x,56,to_x-from_x,1,"wood3")
 if part==0:box(0,32-depth,1,26+depth,"ink");box(1,33-depth,1,depth-2,"wood4")
 if part==2:box(31,32-depth,1,26+depth,"ink");box(30,33-depth,1,depth-2,"wood1")
 if part in [5,6]:box(from_x,32-depth,1,depth,"ink")
 if part in [5,7]:box(to_x-1,32-depth,1,depth,"ink")
func person(profile: Dictionary,direction: int,frame: int):
 begin();var back := direction==3;var side := direction in [1,2];var face := -1 if direction==1 else 1;var step: int = [0,1,0,-1][frame]
 var hair: String = profile.hair;var shirt: String = profile.shirt;var trousers: String = profile.trousers;var skin: String = profile.get("skin","skin2")
 # Feet keep the same baseline in every frame/direction; walk changes limbs only.
 if side:
  box(12,23,4,6,"ink");box(17,23,4,6,"ink");box(11+step,28,6,2,"wood0");box(17-step,28,6,2,"wood0")
  box(11,17,11,8,"ink");box(12,18,9,6,shirt);box(12,24,9,3,trousers);box(13,18,2,5,"ivory3" if profile.get("apron",false) else shirt)
  box(9 if face<0 else 20,18,3,6,"ink");box(10 if face<0 else 20,19+step,2,4,skin)
  box(10,5,13,13,"ink");box(11,6,11,10,hair);box(10 if face<0 else 18,9,4,7,skin);box(9 if face<0 else 22,12,2,3,skin);px(11 if face<0 else 21,11,"black")
  box(12,6,9,3,hair);box(15 if face<0 else 10,9,6,7,hair)
 else:
  box(10,24,5,5,"ink");box(17,24,5,5,"ink");box(10,25,4,3,trousers);box(18,25,3,3,trousers);box(9,28+mini(step,0),6,2,"wood0");box(17,28+mini(-step,0),6,2,"wood0")
  box(8,17,16,9,"ink");box(9,18,14,6,shirt);box(10,24,12,3,trousers)
  box(6,18,3,7,"ink");box(23,18,3,7,"ink");box(7,19+step,2,4,skin);box(23,19-step,2,4,skin)
  if profile.get("apron",false):box(11,18,10,2,"ivory1");box(12,20,8,5,"ivory2" if profile.get("waiter",false) else "blue1");box(12,20,2,4,"ivory3" if profile.get("waiter",false) else "blue2")
  poly([12,5,20,5,23,8,23,14,20,18,12,18,9,14,9,8],"ink");poly([12,6,20,6,22,8,22,14,19,17,12,17,10,14,10,8],hair)
  if not back:
   poly([11,9,21,9,22,11,21,15,19,17,13,17,10,14,10,11],skin);box(11,10,10,5,skin);box(12,11,2,2,"black");box(18,11,2,2,"black");px(16,15,"skin0");box(10,7,12,3,hair);box(10,9,2,3,hair)
  else:poly([12,6,20,6,22,8,22,14,19,17,12,17,10,14,10,8],hair);box(12,7,3,1,"wood2" if hair=="wood0" else hair)
 var shine: String = {"wood0":"wood1","rust1":"rust2","metal3":"metal4","dark":"wood0"}.get(hair,hair)
 box(13,6,5,1,shine);px(12,7,shine)
 if profile.get("curly",false):
  for p in [[10,6],[14,5],[18,5],[21,7]]:box(p[0],p[1],3,2,hair);px(p[0],p[1],shine)
 if profile.get("bun",false):oval(16 if not side else 18-face*4,4,4,3,"ink");oval(15 if not side else 17-face*4,3.5,3,2.5,hair)
 if profile.get("hat",false):box(8,4,17,5,"ink");box(10,2,12,5,"wood1");box(10,2,12,1,"wood3");box(7,7,19,2,"wood2")
 if profile.get("beard",false) and not back:box(13 if not side else 11 if face<0 else 20,14,6 if not side else 3,3,hair)
func paper():
 begin(64,96);poly([5,2,59,2,60,81,50,93,4,92],"wood0");poly([6,3,58,3,59,80,49,91,5,91],"ivory1");box(6,4,51,76,"ivory3");box(7,4,49,2,"ivory4");poly([49,81,59,81,49,91],"ivory0");poly([49,80,59,80,49,89],"ivory2")
func tree():
 begin(64,96);box(27,52,10,39,"ink");box(29,54,6,35,"wood1");box(29,55,2,32,"wood3");line(29,70,18,56,"wood0");line(34,67,45,52,"wood0")
 for p in [[19,27,16,19],[42,24,17,20],[14,43,13,16],[47,42,14,17],[31,14,18,13],[31,44,19,18]]:
  oval(p[0],p[1],p[2],p[3],"ink");oval(p[0]-1,p[1]-2,p[2]-1,p[3]-2,"green0");oval(p[0]-3,p[1]-5,p[2]-4,p[3]-5,"green1");oval(p[0]-4,p[1]-7,p[2]-8,p[3]-8,"green2")
 for p in [[14,20],[34,9],[47,23],[22,34],[40,43]]:box(p[0],p[1],4,2,"green3")
func save(id: String,group: String,footprint: Array=[1,1]):
 assert(not art.has(id),"Identificador duplicado: "+id)
 assert(im.get_width()%32==0 and im.get_height()%32==0,id)
 var opaque := 0;var colors := {}
 for y in im.get_height():
  for x in im.get_width():
   var c := im.get_pixel(x,y);assert(c.a==0.0 or c.a==1.0,id)
   if c.a>0:opaque+=1;colors[c.to_rgba32()]=true
 assert(opaque>0,id);assert(colors.size()<=48,id)
 var folder := out+"/png/"+group;DirAccess.make_dir_recursive_absolute(folder)
 assert(im.save_png(folder+"/"+id+".png")==OK,id)
 var region := im.get_used_rect();art[id]=im.duplicate()
 entries.append({"id":id,"group":group,"file":"png/"+group+"/"+id+".png","canvas":[im.get_width(),im.get_height()],"cells":[im.get_width()/32,im.get_height()/32],"footprint":footprint,"pivot":[im.get_width()/2,im.get_height()],"opaque_bounds":[region.position.x,region.position.y,region.size.x,region.size.y],"palette_colors":colors.size(),"authorship":"redrawn on final-size pixel canvas; no source pixels sampled"})
func _initialize():
 out=get_script().resource_path.get_base_dir();DirAccess.make_dir_recursive_absolute(out+"/previas");call_deferred("run")
func run():
 table();save("mesa_trabalho","moveis",[2,1]);table(true);save("mesa_jantar","moveis",[2,1])
 for d in 4:chair(d);save(["cadeira_frente","cadeira_costas","cadeira_esquerda","cadeira_direita"][d],"moveis")
 stove();save("fogao_apagado","moveis",[2,1]);stove(true);save("fogao_aceso","moveis",[2,1]);fridge();save("geladeira_fechada","moveis");fridge(true);save("geladeira_aberta","moveis")
 sink();save("pia","moveis",[2,1]);rack();save("estante_panelas_vazia","moveis");rack(false,true);save("armario_vazio","moveis");rack(true,true);save("armario_louca","moveis");trash();save("lixeira","moveis");bench();save("banco","moveis",[2,1]);shelf_jars();save("prateleira_potes","moveis",[2,0])
 plate();save("prato_limpo","utensilios",[0,0]);plate(true);save("prato_sujo","utensilios",[0,0]);pot();save("panela_vazia","utensilios",[0,0]);pot(true);save("panela_queimada","utensilios",[0,0]);lid();save("tampa_panela","utensilios",[0,0]);board();save("kit_corte","utensilios",[0,0]);board(false);save("tabua_vazia","utensilios",[0,0]);towel();save("pano","utensilios",[0,0])
 rice();save("arroz","alimentos",[0,0]);cabbage();save("legumes","alimentos",[0,0]);chicken();save("frango","alimentos",[0,0]);potato();save("batata","alimentos",[0,0]);carrot();save("cenoura","alimentos",[0,0])
 for pair in [["batata_cut","potato"],["cenoura_cut","carrot"],["frango_cut","chicken"]]:chunks(pair[1]);save(pair[0],"alimentos",[0,0])
 cut_vegetables();save("legumes_cut","alimentos",[0,0])
 for id in ["arrozLegumes","sopa","frangoArroz","caldoBatata","arrozCenoura","canja"]:dish(id);save(id,"receitas",[0,0])
 clock();save("tempo","icones",[0,0]);nutrition();save("nutricao","icones",[0,0]);paper();save("comanda_vazia","interface",[0,0])
 flower_pot();save("vaso_folhagem","decoracao");flower_pot(true);save("vaso_flores","decoracao");flower_pot(false,true);save("planta_pendente","decoracao",[0,0]);lantern();save("lanterna_acesa","decoracao",[0,0]);lantern(false);save("lanterna_apagada","decoracao",[0,0]);candle();save("vela","decoracao",[0,0]);rug();save("tapete","decoracao",[0,0]);crate();save("caixa_vazia","decoracao");crate(true);save("caixa_legumes","decoracao");barrel();save("barril","decoracao");sign_board();save("quadro_avisos","decoracao",[0,0]);sign_board(true);save("placa_perigo","decoracao",[0,0]);window();save("janela","arquitetura",[0,0]);door();save("porta","arquitetura");tree();save("arvore","exterior",[1,1])
 for i in 8:floor_tile(i);save(["piso_madeira_a","piso_madeira_b","piso_cozinha_a","piso_cozinha_b","terra","pedra_rua","pedra_musgo","grama"][i],"tiles",[0,0])
 for i in 9:wall_tile(i);save(["parede_reboco_superior","parede_lambril","parede_azulejo_superior","parede_azulejo_inferior","viga_vertical_a","viga_vertical_b","parede_frontal","soleira","quina_parede"][i],"tiles",[0,0])
 for i in 2:roof(i);save("telhado_"+str(i),"tiles",[0,0])
 for wide in [false,true]:
  for part in 8:counter(wide,part);save("bancada_"+("grossa_" if wide else "fina_")+["esquerda","horizontal","direita","topo","vertical","base","quina_esquerda","quina_direita"][part],"bancadas")
 var people := {"cozinheira":{"hair":"wood0","shirt":"ivory3","trousers":"blue0","bun":true,"apron":true},"garcom":{"hair":"wood0","shirt":"blue0","trousers":"wood0","apron":true,"waiter":true},"cliente_01":{"hair":"dark","shirt":"wood3","trousers":"green0","skin":"skin1","curly":true},"cliente_02":{"hair":"metal3","shirt":"rust1","trousers":"wood0","beard":true},"cliente_03":{"hair":"rust1","shirt":"blue1","trousers":"purple0","bun":true},"lia":{"hair":"wood1","shirt":"green1","trousers":"wood0","bun":true},"beto":{"hair":"wood0","shirt":"wood3","trousers":"blue0","hat":true,"beard":true},"nina":{"hair":"rust0","shirt":"purple1","trousers":"blue0","bun":true},"manequim":{"hair":"ivory0","shirt":"ivory1","trousers":"ivory0","skin":"ivory2"}}
 for id in people:
  var sheet := Image.create(128,128,false,Image.FORMAT_RGBA8);sheet.fill(Color.TRANSPARENT)
  for d in 4:
   for f in 4:person(people[id],d,f);sheet.blit_rect(im,Rect2i(0,0,32,32),Vector2i(f*32,d*32))
  im=sheet;save(id,"personagens");entries[-1].frame=[32,32];entries[-1].directions=["baixo","esquerda","direita","cima"];entries[-1].frames_per_direction=4;entries[-1].pivot=[16,32]
 kettle();save("chaleira","utensilios",[0,0]);frying_pan();save("frigideira","utensilios",[0,0]);tool_rack();save("suporte_utensilios","decoracao",[0,0]);doormat();save("capacho","decoracao",[0,0]);folded_towel();save("toalha_dobrada","utensilios",[0,0]);banner();save("bandeira","decoracao",[0,0])
 stall();save("barraca_vazia","exterior",[2,1]);stall(true);save("barraca_mercador","exterior",[2,1]);stall(false,true);save("banca_ferro_velho","exterior",[2,1]);awning();save("toldo","exterior",[0,0]);gear();save("engrenagem","exterior",[0,0]);pipes();save("tubos","exterior",[0,0]);toolbox();save("caixa_ferramentas","exterior");parts();save("pecas_geladeira","exterior",[0,0]);flower_box();save("floreira","exterior",[2,1]);ruins();save("ruina","exterior",[2,1]);bucket();save("balde","utensilios",[0,0]);broom();save("vassoura","utensilios",[0,0]);logs();save("lenha","exterior",[0,0]);computer();save("computador_legado","legado",[2,1])
 frame32();save("moldura_32","interface",[0,0])
 for base in ["prato","panela","corte"]:
  for remove in [false,true]:item_action(base,remove);save(base+("_retirar" if remove else "_inserir"),"icones",[0,0])
 for id in ["confirmar","cancelar","martelo","livro","mesa","lavar"]:control(id);save(id,"icones",[0,0])
 FileAccess.open(out+"/manifesto.json",FileAccess.WRITE).store_string(JSON.stringify({"unit":32,"method":"redrawn directly using integer pixel clusters; no Image.load or resize in authoring","integrated_in_game":false,"entries":entries},"\t"))
 compose_previews();compose_details();make_scene();print("REDESENHO 32: ",entries.size()," PNGs originais; personagens em 32x32 por frame; sem reduzir imagens-fonte.");quit()
func kettle():
 begin();oval(16,21,10,8,"ink");oval(16,20,9,7,"rust1");oval(14,18,6,4,"rust2");box(11,14,8,1,"wood4");poly([8,18,3,14,1,15,3,21,8,24],"ink");poly([7,19,3,16,4,20,7,22],"rust2");oval(17,12,10,9,"ink");oval(17,12,7,6,"wood0");box(9,15,15,8,"rust1");oval(16,15,8,3,"metal0");oval(16,14,7,2,"metal2");box(14,10,5,4,"ink");box(15,10,3,2,"metal3")
func frying_pan():
 begin();oval(15,23,10,7,"ink");oval(15,22,9,6,"metal2");oval(15,21,7,4,"metal0");box(13,2,5,15,"ink");box(14,3,3,11,"metal2");box(15,4,1,2,"black");box(7,20,2,3,"metal3");box(14,28,7,1,"metal1")
func tool_rack():
 begin(64,32);box(2,3,60,5,"ink");box(3,4,58,2,"wood2");box(5,4,52,1,"wood4")
 for x in [13,31,49]:box(x,7,2,7,"metal0");px(x+1,8,"metal3")
 oval(14,22,9,9,"ink");oval(14,22,7,7,"metal1");oval(14,21,5,4,"metal0");box(13,13,2,6,"metal2")
 box(31,12,2,13,"metal2");oval(32,27,4,4,"metal0");oval(32,26,3,2,"metal3")
 box(48,12,3,14,"wood2");box(48,13,1,12,"wood4");oval(50,27,5,4,"wood1");oval(49,26,3,2,"wood3")
func doormat():
 begin(64,32);box(2,7,60,20,"wood0");box(3,8,58,18,"wood2");box(5,10,54,14,"wood3")
 for x in range(6,59,4):box(x,11,1,12,"wood1")
 box(6,13,52,1,"wood4");box(6,21,52,1,"wood4")
func folded_towel():
 begin();poly([3,13,18,6,29,14,28,24,12,29,3,22],"ivory0");poly([4,14,18,8,27,14,13,20],"ivory3");poly([4,15,13,21,27,16,27,23,12,27,4,21],"ivory1");line(7,13,16,18,"red1");line(11,11,20,16,"red2");line(6,21,13,24,"ivory3")
func banner():
 begin(32,64);box(3,4,26,4,"ink");box(4,5,24,2,"metal2");box(7,8,18,45,"ink");box(8,8,16,42,"red0");box(10,8,2,40,"red2");box(21,8,2,40,"red1");poly([8,46,24,46,16,58],"ink");poly([9,46,23,46,16,55],"red1");poly([16,16,22,26,16,36,10,26],"wood4");poly([16,20,19,26,16,32,13,26],"red1")
func stall(stock: bool=false,junk: bool=false):
 begin(64,64)
 for x in [3,56]:box(x,4,5,58,"ink");box(x+1,5,3,56,"wood2");box(x+1,6,1,53,"wood4")
 box(2,3,60,5,"ink");box(3,4,58,2,"wood3")
 poly([8,8,56,8,63,27,1,27],"ink");poly([9,9,55,9,61,25,3,25],"ivory2")
 for x in [12,28,44]:poly([x,9,x+8,9,x+11,25,x-3,25],"red1")
 box(2,25,60,5,"wood0");box(3,25,58,2,"ivory1");wood_top(5,39,54,11);box(6,50,52,10,"wood1");box(7,51,50,1,"wood3")
 for x in range(12,56,10):box(x,52,1,7,"wood0")
 if stock:
  for x in [16,29,42]:oval(x,37,6,5,"green0");oval(x-1,35,4,3,"green2");px(x-1,34,"green3")
 if junk:
  box(14,32,10,8,"metal0");box(15,33,8,5,"metal2");box(28,28,6,12,"metal1");box(29,29,2,10,"metal3");box(39,35,12,6,"rust0");box(40,35,8,1,"rust2")
func awning():
 begin(64,32);poly([8,3,56,3,63,25,1,25],"ink");poly([9,4,55,4,61,24,3,24],"ivory2")
 for x in [12,28,44]:poly([x,4,x+8,4,x+11,24,x-3,24],"red1")
 box(2,25,60,3,"wood0");box(3,25,58,1,"ivory0")
func gear():
 begin()
 for y in range(3,30,5):box(13,y,6,4,"metal0")
 for x in range(3,30,5):box(x,13,4,6,"metal0")
 oval(16,16,11,11,"metal0");oval(16,16,9,9,"metal2");oval(15,15,7,7,"metal3");oval(16,16,5,5,"metal0");oval(16,16,3,3,"metal1")
 box(7,7,5,4,"metal1");box(21,21,5,4,"metal1");box(21,7,4,4,"metal3");box(7,21,4,4,"metal2")
func pipes():
 begin();box(4,12,24,8,"ink");box(5,13,22,6,"metal2");box(6,13,20,1,"metal3");box(5,17,22,2,"metal1");box(9,2,8,27,"ink");box(10,3,6,25,"metal1");box(10,4,2,22,"metal3")
 for y in [4,23]:box(8,y,10,3,"metal0");box(9,y,8,1,"metal3")
func toolbox():
 begin();box(4,12,25,17,"ink");box(5,13,23,14,"rust0");box(5,13,23,3,"rust1");box(7,13,19,1,"rust2");box(10,5,12,8,"ink");box(12,7,8,5,"metal2");box(13,8,6,4,"black");box(14,18,5,6,"metal0");box(15,19,3,3,"wood4");box(6,24,21,2,"wood0")
func parts():
 begin();box(4,7,24,21,"metal0");box(5,8,22,19,"metal2");box(6,9,20,17,"metal1")
 for y in [11,15,19,23]:box(8,y,16,1,"metal0");box(8,y+1,15,1,"metal3")
 box(3,2,8,6,"ink");box(4,3,6,4,"rust1");box(23,25,7,5,"rust0");px(25,25,"rust2")
func flower_box():
 begin(64,32);box(2,14,60,16,"ink");box(3,15,58,13,"wood1")
 for y in [16,22]:box(4,y,56,4,"wood2");box(5,y,54,1,"wood3")
 for x in [5,16,29,42,55]:
  oval(x,12,6,5,"green0");oval(x-1,10,4,4,"green2");oval(x,8,3,3,"red1");px(x,7,"wood5")
func ruins():
 begin(64,64)
 for row in 4:
  for col in 4:
   var x := col*16;var y := row*15+3
   if row==0 and col in [1,3]:continue
   box(x+1,y,15,14,"stone0");box(x+2,y+1,13,12,"stone1");box(x+3,y+1,11,2,"stone2");box(x+2,y+11,13,2,"stone0")
 for p in [[6,4],[20,21],[44,15],[49,35],[29,48]]:
  oval(p[0],p[1]+3,6,4,"green0");oval(p[0]-1,p[1]+1,4,3,"green1");px(p[0]-2,p[1],"green3")
func bucket():
 begin();oval(16,17,11,13,"ink");oval(16,17,9,11,"wood0");box(5,13,22,12,"ink");box(6,14,20,10,"metal2");oval(16,24,10,5,"metal2");box(8,15,2,10,"metal3");box(24,15,1,8,"metal1");oval(16,13,11,5,"ink");oval(16,13,10,4,"metal3");oval(16,13,8,2,"metal0")
func broom():
 begin();line(12,27,22,3,"ink");line(13,26,23,3,"wood3");line(14,26,24,3,"wood0");poly([9,19,18,22,18,30,3,29],"ink");poly([10,20,17,23,16,29,5,28],"wood3");line(9,22,7,27,"wood5");line(12,23,10,28,"wood1");line(15,24,14,29,"wood1");line(9,21,17,24,"rust0")
func logs():
 begin()
 for p in [[6,12],[14,10],[19,18],[5,22]]:
  box(p[0],p[1],10,6,"ink");box(p[0]+1,p[1]+1,8,4,"wood1");box(p[0]+2,p[1]+1,6,1,"wood3");oval(p[0]+9,p[1]+3,3,3,"wood0");oval(p[0]+9,p[1]+3,2,2,"wood3");px(p[0]+9,p[1]+3,"wood1")
func computer():
 table();box(15,0,34,26,"ink");box(17,2,30,21,"metal2");box(20,4,24,15,"blue0");box(21,5,22,2,"blue2");box(28,24,7,4,"metal1");box(12,27,40,5,"metal0");box(14,28,35,2,"metal3")
func compose_previews():
 var room := Image.create(512,352,false,Image.FORMAT_RGBA8);room.fill(color("black"))
 for y in range(2,11):
  for x in range(1,15):room.blend_rect(art["piso_cozinha_a" if x>=9 else "piso_madeira_a" if (x+y)%2==0 else "piso_madeira_b"],Rect2i(0,0,32,32),Vector2i(x*32,y*32))
 for x in range(1,15):
  room.blend_rect(art["parede_azulejo_superior" if x>=9 else "parede_reboco_superior"],Rect2i(0,0,32,32),Vector2i(x*32,0));room.blend_rect(art["parede_azulejo_inferior" if x>=9 else "parede_lambril"],Rect2i(0,0,32,32),Vector2i(x*32,32))
 for y in range(11):
  for x in [0,15]:room.blend_rect(art["viga_vertical_a"],Rect2i(0,0,32,32),Vector2i(x*32,y*32))
 var places := [["janela",82,0],["prateleira_potes",171,24],["planta_pendente",249,1],["geladeira_fechada",288,40],["fogao_aceso",320,40],["panela_vazia",333,38],["pia",384,40],["estante_panelas_vazia",449,40],["panela_vazia",449,44],["panela_vazia",449,61],["mesa_jantar",64,112],["cadeira_costas",64,87],["cadeira_costas",96,87],["cadeira_frente",64,177],["cadeira_frente",96,177],["tapete",171,112],["mesa_jantar",176,225],["cadeira_costas",176,201],["cadeira_costas",208,201],["cadeira_frente",176,289],["cadeira_frente",208,289],["mesa_trabalho",320,225],["mesa_trabalho",416,225],["kit_corte",431,225],["vaso_folhagem",36,60],["vaso_folhagem",39,285],["lanterna_acesa",38,9],["lanterna_acesa",247,9],["prato_limpo",318,227],["prato_limpo",318,226],["prato_limpo",318,225],["prato_limpo",318,224],["arrozCenoura",344,225]]
 for x in range(1,15):
  if x!=4:room.blend_rect(art["parede_frontal"],Rect2i(0,0,32,32),Vector2i(x*32,320))
 for p in places:room.blend_rect(art[p[0]],Rect2i(Vector2i.ZERO,art[p[0]].get_size()),Vector2i(p[1],p[2]))
 for p in [["cozinheira",390,181],["garcom",228,157],["cliente_01",112,118]]:room.blend_rect(art[p[0]],Rect2i(32,0,32,32),Vector2i(p[1],p[2]))
 room.save_png(out+"/previas/amostra-nativa.png")
 var enlarged := room.duplicate();enlarged.resize(1536,1056,Image.INTERPOLATE_NEAREST);enlarged.save_png(out+"/previas/previa-amostra-3x.png")
 var columns := 8;var cell := 96;var rows := int(ceil(entries.size()/float(columns)));var gallery := Image.create(columns*cell,rows*cell,false,Image.FORMAT_RGBA8);gallery.fill(color("black"));var positions := []
 for i in entries.size():
  var e: Dictionary = entries[i];var image: Image = art[e.id];var rect := Rect2i(Vector2i.ZERO,image.get_size());var x := i%columns*cell;var y := i/columns*cell
  if e.group=="personagens":rect=Rect2i(32,0,32,32)
  gallery.fill_rect(Rect2i(x+1,y+1,cell-2,cell-2),Color("252a25"));var at := Vector2i(x+(cell-rect.size.x)/2,y+(cell-rect.size.y)/2);gallery.blend_rect(image,rect,at);positions.append({"id":e.id,"column":i%columns,"row":i/columns})
 gallery.save_png(out+"/previas/catalogo-nativo.png");var big := gallery.duplicate();big.resize(gallery.get_width()*2,gallery.get_height()*2,Image.INTERPOLATE_NEAREST);big.save_png(out+"/previas/previa-catalogo-2x.png")
 FileAccess.open(out+"/indice-catalogo.json",FileAccess.WRITE).store_string(JSON.stringify({"cell":96,"columns":columns,"positions":positions},"\t"))
 var connections := Image.create(256,160,false,Image.FORMAT_RGBA8);connections.fill(color("black"))
 for wide in [false,true]:
  var prefix := "bancada_"+("grossa_" if wide else "fina_");var origin := Vector2i(144 if wide else 16,16)
  for p in [["topo",0,0],["vertical",0,32],["quina_esquerda",0,64],["horizontal",32,64],["direita",64,64]]:connections.blend_rect(art[prefix+p[0]],Rect2i(Vector2i.ZERO,art[prefix+p[0]].get_size()),origin+Vector2i(p[1],p[2]))
 connections.save_png(out+"/previas/conexoes-nativas.png");connections.resize(1024,640,Image.INTERPOLATE_NEAREST);connections.save_png(out+"/previas/previa-conexoes-4x.png")
 var tiles := Image.create(256,96,false,Image.FORMAT_RGBA8);tiles.fill(Color.TRANSPARENT);var index := 0
 for e in entries:
  if e.group!="tiles":continue
  tiles.blit_rect(art[e.id],Rect2i(0,0,32,32),Vector2i(index%8*32,index/8*32));index+=1
 tiles.save_png(out+"/tileset-32.png")
 FileAccess.open(out+"/posicoes-amostra.json",FileAccess.WRITE).store_string(JSON.stringify(places,"\t"))
func make_scene():
 for e in entries:
  if e.group!="personagens":continue
  var text: String = '[gd_resource type="SpriteFrames" format=3]\n[ext_resource type="Texture2D" path="res://'+e.file+'" id="sheet"]\n'
  for d in 4:
   for f in 4:text+='[sub_resource type="AtlasTexture" id="f'+str(d*4+f)+'"]\natlas = ExtResource("sheet")\nregion = Rect2('+str(f*32)+', '+str(d*32)+', 32, 32)\nfilter_clip = true\n'
  text+='[resource]\nanimations = [\n'
  for d in 4:
   text+='{"frames": ['
   for f in 4:text+='{"duration":1.0,"texture":SubResource("f'+str(d*4+f)+'")}' + (',' if f<3 else '')
   text+='],"loop":true,"name":&"'+e.directions[d]+'","speed":5.0}' + (',' if d<3 else '')+'\n'
  text+=']\n';FileAccess.open(out+"/png/personagens/"+e.id+".tres",FileAccess.WRITE).store_string(text)
func frame32():
 begin();box(1,1,30,30,"ink");box(2,2,28,28,"wood0");box(3,3,26,26,"wood3");box(4,4,24,24,"wood1");box(5,5,22,22,"ivory1");box(6,6,20,20,"ivory2");box(3,3,25,1,"wood5");box(3,4,1,23,"wood4");box(4,28,25,1,"wood0")
 for p in [[2,2],[27,2],[2,27],[27,27]]:box(p[0],p[1],3,3,"metal0");px(p[0]+1,p[1]+1,"wood4")
func item_action(base: String,remove: bool=false):
 if base=="prato":plate()
 elif base=="panela":pot()
 else:board()
 if remove:
  line(4,10,11,3,"ink");line(3,10,10,3,"ivory4");box(8,2,5,2,"ink");box(11,3,2,5,"ink");box(9,3,3,1,"ivory4");box(11,4,1,3,"ivory4")
 else:
  line(3,2,10,9,"ink");line(4,2,11,9,"green3");box(8,9,6,3,"ink");box(12,6,2,5,"ink");box(9,9,4,1,"green3");box(12,7,1,3,"green3")
func control(kind: String):
 begin()
 if kind=="confirmar":
  poly([4,15,8,12,13,17,25,5,29,9,13,26],"ink");poly([5,15,8,14,13,19,25,7,27,9,13,24],"green2");line(7,15,13,21,"green3")
 elif kind=="cancelar":
  poly([6,4,16,13,25,4,29,8,20,17,29,25,25,29,16,21,7,29,3,25,12,17,3,8],"ink");line(6,7,25,26,"red2");line(7,7,26,26,"red2");line(6,25,25,6,"red2");line(7,25,26,6,"red2")
 elif kind=="martelo":
  line(8,27,23,7,"ink");line(10,27,25,7,"wood2");line(10,25,23,8,"wood4");poly([13,6,18,2,30,9,26,15],"ink");poly([15,6,18,4,28,10,26,13],"metal2");line(17,5,26,10,"metal4")
 elif kind=="livro":
  box(5,3,23,27,"ink");box(6,4,20,24,"blue0");box(8,5,2,21,"wood3");box(11,6,13,17,"blue1");box(11,25,14,2,"ivory2");box(13,10,9,1,"ivory3");box(13,14,7,1,"ivory2");box(13,18,5,1,"ivory2")
 elif kind=="mesa":
  box(5,15,4,14,"ink");box(24,15,4,14,"ink");box(6,16,2,11,"wood3");box(25,16,2,11,"wood3");wood_top(2,5,28,15)
 elif kind=="lavar":
  box(3,14,26,14,"ink");box(4,15,24,11,"ivory2");box(7,17,18,6,"blue1");box(8,18,16,2,"blue2");box(14,4,4,12,"metal0");box(15,5,2,9,"metal3");box(18,3,6,4,"metal0");box(18,4,5,2,"metal3");box(22,7,2,3,"blue3");px(22,12,"blue2")

func compose_details():
 var sheet := Image.create(128,96,false,Image.FORMAT_RGBA8);sheet.fill(Color("252a25"))
 for pair in [["fogao_apagado",0,0],["fogao_aceso",64,0],["prato_limpo",0,64],["prato_sujo",32,64],["caldoBatata",64,64],["arrozCenoura",96,64]]:
  var source: Image = art[pair[0]];sheet.blend_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),Vector2i(pair[1],pair[2]))
 sheet.resize(768,576,Image.INTERPOLATE_NEAREST);sheet.save_png(out+"/previas/previa-prato-fogao-6x.png")
