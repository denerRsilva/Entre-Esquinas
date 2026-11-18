extends SceneTree
func _initialize():
 var data = JSON.parse_string(FileAccess.get_file_as_string("res://manifesto.json"))
 var root_node := Node2D.new();root_node.name="Amostra32px";root_node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var set: TileSet = load("res://PisosParedes.tres")
 var floor_layer := TileMapLayer.new();floor_layer.name="Piso32";floor_layer.tile_set=set;root_node.add_child(floor_layer);floor_layer.owner=root_node
 var walls := TileMapLayer.new();walls.name="Paredes32";walls.tile_set=set;walls.z_index=1;root_node.add_child(walls);walls.owner=root_node
 for y in range(2,10):
  for x in range(1,13):floor_layer.set_cell(Vector2i(x,y),0,Vector2i(2 if x>=8 else (x+y)%2,0))
 for x in range(1,13):
  walls.set_cell(Vector2i(x,0),0,Vector2i(2,2) if x in [3,10] else Vector2i(0,1));walls.set_cell(Vector2i(x,1),0,Vector2i(1,1))
  if x!=6:walls.set_cell(Vector2i(x,9),0,Vector2i(3,1))
 for y in range(10):
  for x in [0,13]:walls.set_cell(Vector2i(x,y),0,Vector2i(2,1))
 for p in data.placements:
  var sprite := Sprite2D.new();sprite.name=p[0];sprite.texture=load("res://"+p[0]+".png");sprite.centered=false;sprite.position=Vector2(p[1],p[2]);sprite.z_index=2
  root_node.add_child(sprite);sprite.owner=root_node
 var scene := PackedScene.new();assert(scene.pack(root_node)==OK);assert(ResourceSaver.save(scene,"res://Amostra.tscn")==OK)
 assert(set.tile_size==Vector2i(32,32));assert(floor_layer.get_used_cells().size()==96)
 for object in data.objects:
  var texture: Texture2D = load("res://"+object.file);assert(texture.get_width()%32==0 and texture.get_height()%32==0)
 print("Cena editável e TileSet 32px validados")
 root_node.free();quit()
