extends SceneTree
## Original artwork authored at its native pixel dimensions; no downsampling.
const C = {"ink":"34291f","deep":"513927","shade":"72482e","wood":"945e36","honey":"b47a44","edge":"d49a58","shine":"e5b573","plaster":"c7ae85","plasterDark":"ac906d","plasterLight":"ddc59b","stone":"686762","stoneLight":"7c7a71","stoneShade":"525653","metal":"52564f","metalDark":"343b39","metalLight":"828b7c","cream":"dfd1ad","ivory":"f0e3c1","rust":"a76f46","green":"5d7241","blue":"768e82"}
var img: Image
var tiles: Array[Image] = []
var objects := {}
func col(k: String) -> Color:return Color(C[k])
func rect(x: int,y: int,w: int,h: int,k: String):img.fill_rect(Rect2i(x,y,w,h),col(k))
func px(x: int,y: int,k: String):img.set_pixel(x,y,col(k))
func begin(w: int=32,h: int=32):img=Image.create(w,h,false,Image.FORMAT_RGBA8);img.fill(Color.TRANSPARENT)
func grain(x: int,y: int,w: int,h: int,seed: int=0):
 for i in 12:
  var xx: int = x+2+posmod(i*11+seed,maxi(1,w-7));var yy: int = y+2+posmod(i*7+seed,maxi(1,h-4))
  rect(xx,yy,2+posmod(i,3),1,"honey" if i%2 else "shade")
func floor_wood(variant: int=0):
 begin();rect(0,0,32,32,"wood")
 for row in 4:
  var y := row*8;rect(0,y+7,32,1,"deep");rect(0,y,32,1,"honey")
  var joint: int = 8 if row%2==0 else 24
  rect(joint,y,1,7,"shade");px(joint+1,y+1,"edge")
 grain(1,1,30,29,variant*17)
func floor_stone():
 begin();rect(0,0,32,32,"stoneShade")
 for y in 2:
  for x in 2:
   rect(x*16+1,y*16+1,15,15,"stone" if (x+y)%2 else "stoneLight")
   rect(x*16+2,y*16+2,13,1,"stoneLight")
func wall_upper():
 begin();rect(0,0,32,32,"plaster");rect(0,0,32,2,"ink");rect(0,2,32,4,"wood");rect(0,2,32,1,"edge");rect(0,6,32,1,"deep")
 for p in [Vector2i(8,12),Vector2i(23,23),Vector2i(15,28)]:
  rect(p.x,p.y,3,2,"plasterDark");px(p.x-1,p.y+1,"plasterLight")
func wall_lower():
 begin();rect(0,0,32,32,"plaster");rect(0,12,32,2,"ink");rect(0,14,32,4,"wood");rect(0,14,32,1,"edge");rect(0,18,32,12,"shade")
 for x in range(2,32,8):rect(x,19,1,10,"deep");rect(x+1,19,1,10,"wood")
 rect(0,30,32,2,"deep");rect(0,30,32,1,"honey")
func side():
 begin();rect(8,0,16,32,"ink");rect(10,0,12,32,"wood");rect(11,0,2,32,"edge");rect(20,0,2,32,"shade");grain(13,0,7,32,2)
func front():
 begin();rect(0,12,32,12,"ink");rect(0,14,32,8,"wood");rect(0,14,32,2,"edge");rect(0,21,32,1,"shade")
func corner():side();rect(16,12,16,12,"ink");rect(16,14,16,8,"wood");rect(16,14,16,2,"edge")
func threshold():floor_wood();rect(0,6,32,2,"deep");rect(0,8,32,1,"edge");rect(0,25,32,1,"deep")
func window():
 wall_upper();rect(4,7,24,24,"ink");rect(5,8,22,22,"wood");rect(7,10,18,16,"deep")
 for y in [11,19]:
  for x in [8,17]:
   rect(x,y,7,6,"green");rect(x,y,6,2,"blue");rect(x+1,y+1,2,3,"plasterLight")
 rect(15,10,2,17,"honey");rect(7,17,18,2,"wood");rect(3,28,26,2,"edge");rect(4,30,24,1,"deep")
func bricks():
 begin();rect(0,0,32,32,"deep")
 for row in 4:
  for x in range(-8 if row%2 else 0,32,16):
   var left := maxi(0,x);var right := mini(32,x+15)
   rect(left,row*8+1,right-left,6,"shade");rect(left,row*8+1,right-left,1,"wood")
func table():
 begin(64,64)
 for x in [8,51]:rect(x,31,6,30,"ink");rect(x+1,34,3,25,"shade");rect(x+1,34,1,24,"honey")
 rect(12,52,41,4,"deep");rect(13,52,39,1,"wood")
 rect(5,31,54,13,"ink");rect(7,32,50,10,"shade");rect(8,32,48,2,"honey")
 for x in [10,26,42]:rect(x,36,12,5,"wood");rect(x,36,12,1,"honey")
 rect(3,7,58,26,"ink");rect(4,8,56,24,"wood");rect(5,9,54,1,"edge");rect(5,30,54,1,"honey")
 for y in [16,24]:rect(5,y,54,1,"shade");rect(5,y+1,54,1,"honey")
 grain(5,10,54,20,4);rect(4,11,1,18,"honey");rect(59,10,1,21,"shade")
func chair(back: bool=false):
 begin();rect(5,2,22,13,"ink");rect(6,3,20,4,"wood");rect(7,3,18,1,"edge")
 for x in [6,12,19,24]:rect(x,7,2,12,"shade");rect(x,7,1,10,"honey")
 rect(5,18,22,8,"ink");rect(6,18,20,6,"wood");rect(7,19,18,1,"edge")
 for x in [6,23]:rect(x,25,3,6,"ink");rect(x+1,25,1,5,"honey")
 if back:rect(6,7,20,9,"shade");rect(7,8,18,1,"wood")
func fridge():
 begin(32,64);rect(3,2,26,60,"ink");rect(4,3,24,58,"plasterDark");rect(5,4,22,55,"cream");rect(6,5,20,2,"ivory");rect(26,5,1,53,"plasterDark")
 rect(5,24,22,2,"shade");rect(6,25,20,1,"ivory");rect(7,12,2,8,"metalDark");rect(7,32,2,12,"metalDark");rect(7,12,1,7,"metalLight");rect(7,32,1,11,"metalLight")
 for p in [Vector2i(20,19),Vector2i(11,52),Vector2i(23,45)]:rect(p.x,p.y,3,3,"rust");px(p.x+2,p.y-1,"plasterDark")
 rect(7,61,4,2,"deep");rect(22,61,4,2,"deep")
func stove():
 begin(64,64);rect(4,23,56,38,"ink");rect(6,25,52,34,"metalDark");rect(7,26,50,2,"metalLight");rect(7,51,50,6,"metal")
 rect(9,34,29,17,"ink");rect(11,36,25,12,"metal");rect(14,38,3,9,"metalDark");rect(21,38,3,9,"metalDark");rect(28,38,3,9,"metalDark")
 rect(41,35,13,14,"metal");rect(43,37,9,1,"metalLight");rect(43,42,3,2,"ink")
 rect(3,16,58,11,"ink");rect(5,17,54,8,"metal");rect(6,17,52,1,"metalLight")
 for x in [13,31]:rect(x,20,10,4,"metalDark");rect(x+2,20,6,1,"ink")
 rect(44,0,11,18,"ink");rect(46,1,7,16,"metal");rect(47,1,1,16,"metalLight");rect(43,0,13,3,"metalDark")
 rect(8,60,5,3,"ink");rect(51,60,5,3,"ink")
func sink():
 table();rect(4,8,56,24,"ink");rect(5,9,54,22,"cream");rect(6,10,52,2,"ivory");rect(10,13,44,14,"metalDark");rect(12,14,40,10,"metal");rect(15,16,34,7,"blue");rect(15,16,34,1,"metalLight")
 rect(30,0,4,15,"ink");rect(31,1,2,12,"metalLight");rect(32,0,9,3,"ink");rect(33,1,7,1,"metalLight");rect(39,2,3,5,"metalDark")
func board():
 begin();rect(2,11,24,14,"ink");rect(3,12,22,12,"honey");rect(4,13,20,1,"shine");rect(4,22,20,1,"wood");rect(25,15,4,6,"ink");rect(26,16,2,4,"wood");rect(8,17,10,1,"wood");rect(12,15,1,5,"edge")
func _initialize():
 var out: String = get_script().resource_path.get_base_dir()
 var makers := [func():floor_wood(0),func():floor_wood(1),floor_stone,func():floor_wood(2),wall_upper,wall_lower,side,front,corner,threshold,window,bricks,func():floor_wood(3),floor_stone,wall_upper,wall_lower]
 var atlas := Image.create(128,128,false,Image.FORMAT_RGBA8);atlas.fill(Color.TRANSPARENT)
 for i in makers.size():
  makers[i].call();tiles.append(img);atlas.blit_rect(img,Rect2i(0,0,32,32),Vector2i(i%4*32,i/4*32));img.save_png(out+"/tile_%02d.png"%i)
 atlas.save_png(out+"/tileset.png")
 for pair in [["mesa_trabalho",table],["mesa_jantar",table],["cadeira_frente",func():chair(false)],["cadeira_costas",func():chair(true)],["geladeira",fridge],["fogao",stove],["pia",sink],["tabua_corte",board]]:
  pair[1].call();objects[pair[0]]=img;img.save_png(out+"/"+pair[0]+".png")
 var room := Image.create(448,320,false,Image.FORMAT_RGBA8);room.fill(Color("181b18"))
 for y in range(2,10):
  for x in range(1,13):room.blend_rect(tiles[2 if x>=8 else (x+y)%2],Rect2i(0,0,32,32),Vector2i(x*32,y*32))
 for x in range(1,13):
  room.blend_rect(tiles[10 if x in [3,10] else 4],Rect2i(0,0,32,32),Vector2i(x*32,0));room.blend_rect(tiles[5],Rect2i(0,0,32,32),Vector2i(x*32,32))
  if x!=6:room.blend_rect(tiles[7],Rect2i(0,0,32,32),Vector2i(x*32,288))
 for y in range(10):
  for x in [0,13]:room.blend_rect(tiles[6],Rect2i(0,0,32,32),Vector2i(x*32,y*32))
 var placements := [["geladeira",272,40],["fogao",304,40],["pia",368,40],["cadeira_costas",64,72],["cadeira_costas",96,72],["mesa_jantar",64,104],["cadeira_frente",64,168],["cadeira_frente",96,168],["cadeira_costas",144,160],["cadeira_costas",176,160],["mesa_jantar",144,192],["cadeira_frente",144,256],["cadeira_frente",176,256],["mesa_trabalho",304,176],["tabua_corte",320,184]]
 for p in placements:room.blend_rect(objects[p[0]],Rect2i(Vector2i.ZERO,objects[p[0]].get_size()),Vector2i(p[1],p[2]))
 room.save_png(out+"/amostra.png");room.resize(1344,960,Image.INTERPOLATE_NEAREST);room.save_png(out+"/previa-3x.png")
 var manifest := {"unit":32,"original_artwork":true,"atlas":{"file":"tileset.png","width":128,"height":128,"cell_width":32,"cell_height":32},"objects":[],"placements":placements}
 for id in objects:manifest.objects.append({"file":id+".png","width":objects[id].get_width(),"height":objects[id].get_height(),"pivot_px":[objects[id].get_width()/2,objects[id].get_height()],"footprint_cells":[0,0] if id=="tabua_corte" else [objects[id].get_width()/32,1]})
 FileAccess.open(out+"/manifesto.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
 print("Kit original: 16 células 32px e 8 móveis/objetos em múltiplos de 32")
 quit()
