extends SceneTree
## Assemble real Godot resources after importing the native PNGs.
func _initialize():
 var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifesto.json"))
 var source := TileSetAtlasSource.new();source.texture=load("res://tileset-32.png");source.texture_region_size=Vector2i(32,32)
 var tiles := {};var index := 0
 for e in data.entries:
  if e.group!="tiles":continue
  var at := Vector2i(index%8,index/8);source.create_tile(at);tiles[e.id]=at;index+=1
 var tile_set := TileSet.new();tile_set.tile_size=Vector2i(32,32);tile_set.add_source(source,0)
 assert(ResourceSaver.save(tile_set,"res://Taverna32.tres")==OK)
 var scene := Node2D.new();scene.name="Amostra32";scene.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var floor_layer := TileMapLayer.new();floor_layer.name="Piso32";floor_layer.tile_set=tile_set;scene.add_child(floor_layer);floor_layer.owner=scene
 var walls := TileMapLayer.new();walls.name="Paredes32";walls.tile_set=tile_set;scene.add_child(walls);walls.owner=scene
 for y in range(2,11):
  for x in range(1,15):floor_layer.set_cell(Vector2i(x,y),0,tiles["piso_cozinha_a" if x>=9 else "piso_madeira_a" if (x+y)%2==0 else "piso_madeira_b"])
 for x in range(1,15):
  walls.set_cell(Vector2i(x,0),0,tiles["parede_azulejo_superior" if x>=9 else "parede_reboco_superior"]);walls.set_cell(Vector2i(x,1),0,tiles["parede_azulejo_inferior" if x>=9 else "parede_lambril"])
  if x!=4:walls.set_cell(Vector2i(x,10),0,tiles.parede_frontal)
 for y in range(11):
  for x in [0,15]:walls.set_cell(Vector2i(x,y),0,tiles.viga_vertical_a)
 var placements: Array = JSON.parse_string(FileAccess.get_file_as_string("res://posicoes-amostra.json"))
 var by_id := {}
 for e in data.entries:by_id[e.id]=e
 for p in placements:
  var sprite := Sprite2D.new();sprite.name=p[0];sprite.texture=load("res://"+by_id[p[0]].file);sprite.centered=false;sprite.position=Vector2(p[1],p[2]);scene.add_child(sprite);sprite.owner=scene
 for p in [["cozinheira",390,181],["garcom",228,157],["cliente_01",112,118]]:
  var sprite := AnimatedSprite2D.new();sprite.name=p[0];sprite.sprite_frames=load("res://png/personagens/"+p[0]+".tres");sprite.animation="baixo";sprite.frame=1;sprite.centered=false;sprite.position=Vector2(p[1],p[2]);scene.add_child(sprite);sprite.owner=scene
 var packed := PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,"res://Amostra.tscn")==OK)
 assert(floor_layer.get_used_cells().size()==126);assert(tile_set.tile_size==Vector2i(32,32));scene.free()
 print("Cena editável: 126 células de piso, paredes, sprites independentes e personagens 32px.");quit()
