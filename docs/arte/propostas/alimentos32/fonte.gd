extends SceneTree
## Pixel clusters authored directly on 32px canvases. No source downsampling.
const COLORS = {
 "ink":"38291f", "deep":"543722", "wood":"77502f", "brown":"9c6334", "tan":"bc8144", "ochre":"d49b53", "sand":"e6b96d", "light":"f3d593",
 "rimDark":"89704e", "rimShade":"b69970", "rim":"d6bf94", "ivory":"eedbb4", "white":"fff0d0",
 "orangeDark":"a64a21", "orangeShade":"c76124", "orange":"e7842c", "orangeLight":"f5aa45", "orangePale":"ffd06c",
 "greenDark":"3d4928", "green":"5f7136", "leaf":"829349", "leafLight":"a2af60",
 "brothDark":"987036", "broth":"bc9145", "brothLight":"d7ad5d", "brothPale":"e7c77c", "chickenShade":"bc8a4c", "chicken":"e0b979"
}
var canvas: Image
var sprites: Array[Image] = []
func color(key: String) -> Color:return Color(COLORS[key])
func px(x: int,y: int,c: String) -> void:
 if x>=0 and x<32 and y>=0 and y<32:canvas.set_pixel(x,y,color(c))
func rect(x: int,y: int,w: int,h: int,c: String) -> void:
 for yy in range(y,y+h):
  for xx in range(x,x+w):px(xx,yy,c)
func polygon(points: Array,c: String) -> void:
 for y in 32:
  for x in 32:
   var hit := false
   var j: int = points.size()-1
   for i in points.size():
    var a: Vector2 = points[i];var b: Vector2 = points[j]
    if (a.y>y+0.5)!=(b.y>y+0.5) and x+0.5<(b.x-a.x)*(y+0.5-a.y)/(b.y-a.y)+a.x:hit=not hit
    j=i
   if hit:px(x,y,c)
func poly(coords: Array,c: String) -> void:
 var points := []
 for i in range(0,coords.size(),2):points.append(Vector2(coords[i],coords[i+1]))
 polygon(points,c)
func oval(cx: float,cy: float,rx: float,ry: float,c: String) -> void:
 for y in 32:
  for x in 32:
   if pow((x+0.5-cx)/rx,2)+pow((y+0.5-cy)/ry,2)<=1:px(x,y,c)
func begin() -> void:canvas=Image.create(32,32,false,Image.FORMAT_RGBA8);canvas.fill(Color.TRANSPARENT)
func potato() -> void:
 poly([4,14,7,10,12,8,21,7,26,10,29,15,28,21,24,25,16,27,9,25,4,22,2,18],"ink")
 poly([4,14,8,11,13,9,21,8,25,11,27,15,27,21,23,24,16,25,9,24,4,21,3,18],"brown")
 poly([4,15,9,11,14,10,21,10,25,13,26,17,23,21,18,23,10,22,5,20],"tan")
 poly([6,14,10,12,16,11,20,11,21,13,18,15,11,17,6,18],"ochre")
 rect(8,13,4,1,"sand");rect(7,14,3,1,"sand");rect(12,12,3,1,"sand")
 rect(10,19,2,1,"deep");px(10,18,"brown");px(12,19,"ochre")
 rect(21,13,2,2,"wood");px(22,13,"deep");px(23,15,"ochre")
 rect(18,22,2,1,"wood");px(17,21,"brown");px(20,22,"ochre")
 px(24,19,"deep");px(25,19,"ochre");px(6,20,"brown")
func cube(x: int,y: int,w: int=8,h: int=5) -> void:
 poly([x,y+2,x+2,y,x+w-2,y,x+w,y+2,x+w,y+h-1,x+w-3,y+h+2,x+1,y+h+1,x-1,y+h-1],"ink")
 poly([x+1,y+3,x+w-2,y+3,x+w-1,y+h-1,x+w-3,y+h+1,x+1,y+h],"sand")
 poly([x+w-2,y+3,x+w-1,y+2,x+w-1,y+h-1,x+w-3,y+h+1,x+w-3,y+5],"ochre")
 poly([x,y+2,x+2,y+1,x+w-2,y+1,x+w-1,y+2,x+w-3,y+4,x+1,y+4],"light")
 rect(x+2,y+1,w-5,1,"white");px(x+1,y+h-1,"tan");px(x+w-2,y+h-1,"brown")
func potato_cut() -> void:
 cube(13,8,8,5);cube(5,13,8,5);cube(20,14,7,5);cube(12,16,8,5);cube(9,22,7,4)
func carrot() -> void:
 poly([19,10,21,7,21,3,24,3,25,5,24,8,28,7,30,8,29,11,25,13,21,14],"greenDark")
 poly([20,10,22,7,22,4,24,4,23,9,25,10,28,8,29,9,26,12,22,13],"green")
 rect(22,5,1,3,"leafLight");px(22,8,"leaf");rect(25,10,2,1,"leafLight")
 poly([18,11,21,12,23,15,21,19,17,22,14,25,9,28,4,29,5,25,8,20,12,15,16,12],"ink")
 poly([18,12,21,13,22,15,20,18,16,21,13,24,8,27,5,28,7,24,10,20,13,16],"orangeShade")
 poly([17,13,20,14,20,16,17,19,13,21,11,24,7,26,10,21,13,17],"orange")
 poly([17,13,19,14,17,16,14,17,12,20,11,20,13,16],"orangeLight")
 px(17,13,"orangePale");rect(17,17,3,1,"orangeDark");rect(12,21,2,1,"orangeDark");px(8,25,"orangeLight");px(10,24,"orangeDark")
func slice(x: int,y: int,w: int=9,h: int=7) -> void:
 oval(x+w/2.0,y+h/2.0+2,w/2.0+1,h/2.0+1,"ink")
 oval(x+w/2.0,y+h/2.0+1,w/2.0,h/2.0,"orangeShade")
 oval(x+w/2.0,y+h/2.0-1,w/2.0+1,h/2.0+1,"ink")
 oval(x+w/2.0,y+h/2.0-1,w/2.0,h/2.0,"orange")
 oval(x+w/2.0,y+h/2.0-1,w/2.0-2,h/2.0-1,"orangePale")
 rect(x+w/2-1,y+h/2-2,2,2,"orangeLight")
func carrot_cut() -> void:
 slice(14,9,10,8);slice(5,15,9,7);slice(19,18,8,6);slice(12,21,8,6)
func plate() -> void:
 oval(16,18,14,8,"ink")
 oval(16,18,13,7,"rimDark")
 oval(16,17,13,7,"rimShade")
 oval(16,16,14,8,"ink")
 oval(16,16,13,7,"rim")
 oval(15.5,15,12.5,6,"ivory")
 oval(16,15,10.5,4.5,"rimShade")
 oval(16,15.5,9.5,3.5,"ivory")
 rect(9,10,6,1,"white");rect(6,12,2,1,"white");rect(18,21,6,1,"rim");rect(12,23,9,1,"ivory")
func potato_soup() -> void:
 plate();oval(16,15,10,4.5,"brothDark");oval(15.5,14.5,9.5,3.5,"broth");oval(14,13.5,7,2,"brothLight")
 poly([9,13,12,12,15,14,14,16,11,17,8,15],"ochre")
 poly([10,12,13,12,14,14,12,15,9,14],"light");rect(10,12,2,1,"white")
 poly([19,12,22,13,22,15,19,16,17,14],"ochre");rect(18,12,3,2,"light");px(19,12,"white")
 poly([15,17,18,16,21,18,20,20,16,20,14,19],"ochre");rect(16,17,3,2,"light");px(16,17,"white")
 px(7,14,"green");rect(16,11,2,1,"green");px(24,15,"green");px(11,18,"leaf");px(22,17,"greenDark")
func rice_grain(x: int,y: int,bright: bool=true) -> void:
 rect(x,y,2,1,"white" if bright else "ivory");px(x,y+1,"sand")
func rice_carrot() -> void:
 plate();oval(16,15,10,4.5,"ochre");oval(15.5,14.5,9,4,"sand")
 for p in [Vector2i(9,13),Vector2i(12,12),Vector2i(15,11),Vector2i(17,13),Vector2i(20,12),Vector2i(22,14),Vector2i(11,15),Vector2i(14,14),Vector2i(16,16),Vector2i(19,15),Vector2i(8,16),Vector2i(12,17),Vector2i(19,18),Vector2i(22,16)]:rice_grain(p.x,p.y)
 for p in [Vector2i(10,12),Vector2i(18,11),Vector2i(14,16),Vector2i(21,16)]:
  rect(p.x,p.y,3,2,"orangeShade");rect(p.x,p.y,2,1,"orangeLight")
 px(16,18,"green");px(23,13,"leaf")
func chicken_soup() -> void:
 plate();oval(16,15,10,4.5,"brothDark");oval(15.5,14.5,9.5,3.5,"broth")
 for p in [Vector2i(9,13),Vector2i(14,11),Vector2i(20,12),Vector2i(11,17),Vector2i(17,16),Vector2i(23,15),Vector2i(18,18)]:rice_grain(p.x,p.y)
 for p in [Vector2i(12,13),Vector2i(19,15)]:
  rect(p.x,p.y,4,3,"chickenShade");rect(p.x,p.y,3,2,"chicken");px(p.x,p.y,"light")
 for p in [Vector2i(19,12),Vector2i(9,16),Vector2i(15,18)]:
  rect(p.x,p.y,2,2,"orangeShade");px(p.x,p.y,"orangeLight")
 px(8,15,"green");px(17,12,"leaf");px(23,17,"green")
func _initialize():
 var out: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else get_script().resource_path.get_base_dir()
 DirAccess.make_dir_recursive_absolute(out)
 var ids := ["batata","batata_cut","cenoura","cenoura_cut","caldoBatata","arrozCenoura","canja","prato_vazio"]
 var funcs := [potato,potato_cut,carrot,carrot_cut,potato_soup,rice_carrot,chicken_soup,plate]
 var sheet := Image.create(128,64,false,Image.FORMAT_RGBA8);sheet.fill(Color.TRANSPARENT)
 var manifest := {"cell_width":32,"cell_height":32,"columns":4,"rows":2,"filter":"nearest","integrated":false,"sprites":[]}
 for i in ids.size():
  begin();funcs[i].call();sprites.append(canvas)
  for y in 32:
   for x in 32:assert(canvas.get_pixel(x,y).a==0 or canvas.get_pixel(x,y).a==1)
  assert(canvas.get_size()==Vector2i(32,32));assert(canvas.save_png(out+"/"+ids[i]+".png")==OK)
  sheet.blit_rect(canvas,Rect2i(0,0,32,32),Vector2i(i%4*32,i/4*32))
  manifest.sprites.append({"id":ids[i],"file":ids[i]+".png","x":i%4*32,"y":i/4*32,"w":32,"h":32})
 assert(sheet.save_png(out+"/spritesheet.png")==OK)
 sheet.resize(1024,512,Image.INTERPOLATE_NEAREST);sheet.save_png(out+"/previa-8x.png")
 FileAccess.open(out+"/manifesto.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
 print("8 sprites 32x32 e atlas 128x64 exportados: ",out)
 quit()
