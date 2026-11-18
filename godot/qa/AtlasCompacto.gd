extends "res://qa/BaseNativa.gd"
func run():
 var source: Image = load("res://arte/ui/modern-ui-32.png").get_image();source.convert(Image.FORMAT_RGBA8)
 var dest: Image = preload("res://interface/ArteBarras.gd").ATLAS.get_image();dest.convert(Image.FORMAT_RGBA8)
 check(dest.get_size()==Vector2i(128,32),"Somente as barras necessárias ocupam atlas compacto")
 var pieces := [[Rect2i(672,266,30,16),Vector2i(0,0)],[Rect2i(666,234,6,16),Vector2i(32,0)],[Rect2i(702,234,6,16),Vector2i(40,0)]]
 for pair in [[300,0],[396,32],[492,64],[588,96]]:pieces.append([Rect2i(672,pair[0],30,10),Vector2i(pair[1],20)])
 for piece in pieces:check(source.get_region(piece[0]).get_data()==dest.get_region(Rect2i(piece[1],piece[0].size)).get_data(),"Recorte preserva todos os pixels e alpha: "+str(piece[0]))
 print("FALHAS: ",failures);quit(1 if failures else 0)
