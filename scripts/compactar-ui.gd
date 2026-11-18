extends SceneTree
## Lossless atlas packing: copy the purchased bar pixels, never redraw/resize them.
func _initialize():
 var source := Image.load_from_file(ProjectSettings.globalize_path("res://arte/ui/modern-ui-32.png"));source.convert(Image.FORMAT_RGBA8)
 var dest := Image.create(128,32,false,Image.FORMAT_RGBA8);dest.fill(Color.TRANSPARENT)
 var pieces := [[Rect2i(672,266,30,16),Vector2i(0,0)],[Rect2i(666,234,6,16),Vector2i(32,0)],[Rect2i(702,234,6,16),Vector2i(40,0)]]
 for pair in [[300,0],[396,32],[492,64],[588,96]]:pieces.append([Rect2i(672,pair[0],30,10),Vector2i(pair[1],20)])
 for piece in pieces:dest.blit_rect(source,piece[0],piece[1])
 for piece in pieces:assert(source.get_region(piece[0]).get_data()==dest.get_region(Rect2i(piece[1],piece[0].size)).get_data())
 assert(dest.save_png(ProjectSettings.globalize_path("res://arte/ui/barras-compactas-32.png"))==OK)
 print("Barras copiadas pixel a pixel: 1952x1376 -> 128x32; sem redução ou alteração visual")
 quit()
