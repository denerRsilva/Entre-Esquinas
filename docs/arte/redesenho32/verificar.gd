extends SceneTree
var checks := 0
func check(ok: bool,label: String):
 checks+=1
 assert(ok,label)
func raw(file: String) -> Image:return Image.load_from_file(ProjectSettings.globalize_path("res://"+file))
func _initialize():
 var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifesto.json"));var by_id := {};var total_bytes := 0;var frames := 0
 check(data.integrated_in_game==false,"Kit não se apresenta como arte já instalada no jogo")
 for e in data.entries:
  check(not by_id.has(e.id),e.id+" identificador único");by_id[e.id]=e;var image := raw(e.file);check(image.get_size()==Vector2i(e.canvas[0],e.canvas[1]),e.id+" canvas");check(image.get_width()%32==0 and image.get_height()%32==0,e.id+" grade")
  total_bytes+=FileAccess.get_file_as_bytes("res://"+e.file).size()
  var colors := {};var solid := 0
  for y in image.get_height():
   for x in image.get_width():
    var c := image.get_pixel(x,y);check(c.a==0 or c.a==1,e.id+" alpha binário")
    if c.a>0:colors[c.to_rgba32()]=true;solid+=1
  check(solid>0 and colors.size()<=48,e.id+" conteúdo/paleta")
  if e.group=="personagens":
   var animations: SpriteFrames = load("res://png/personagens/"+e.id+".tres")
   for name in e.directions:
    check(animations.get_frame_count(name)==4,e.id+" quadros "+name)
    for f in 4:
     var texture: AtlasTexture = animations.get_frame_texture(name,f);check(texture.region.size==Vector2(32,32),e.id+" frame real32");frames+=1
   for d in 4:
    var baseline := -1
    for f in 4:
     var frame := image.get_region(Rect2i(f*32,d*32,32,32));var foot := frame.get_used_rect().end.y
     if baseline<0:baseline=foot
     check(foot==baseline,e.id+" pés sem saltos")
 # Keep the plate silhouette identical in every recipe and cleaning state.
 var clean := raw(by_id.prato_limpo.file)
 for id in ["prato_sujo","caldoBatata","arrozCenoura","canja","arrozLegumes","sopa","frangoArroz"]:
  var dish := raw(by_id[id].file)
  for y in 32:
   for x in 32:check(dish.get_pixel(x,y).a==clean.get_pixel(x,y).a,id+" mesma louça")
 for wide in [false,true]:
  var prefix := "bancada_"+("grossa_" if wide else "fina_");var depth := 24 if wide else 12
  var middle := raw(by_id[prefix+"horizontal"].file);var corner := raw(by_id[prefix+"quina_esquerda"].file);var vertical := raw(by_id[prefix+"vertical"].file)
  for y in range(32-depth,58):check(middle.get_pixel(0,y).a==1 and corner.get_pixel(31,y).a==1,prefix+" junção horizontal sem frestas")
  for x in 32:check(vertical.get_pixel(x,31).a==corner.get_pixel(x,0).a,prefix+" encaixe vertical exato")
  var right := raw(by_id[prefix+"quina_direita"].file)
  for x in 32:check(vertical.get_pixel(x,31).a==right.get_pixel(x,0).a,prefix+" encaixe vertical direito")
  for y in range(32-depth,58):check(right.get_pixel(0,y).a==middle.get_pixel(31,y).a,prefix+" encaixe horizontal direito")
 var set: TileSet = load("res://Taverna32.tres");check(set.tile_size==Vector2i(32,32),"TileSet 32 real");check(set.get_source(0).get_tiles_count()==19,"Dezenove módulos editáveis")
 var cold := raw(by_id.fogao_apagado.file);var hot := raw(by_id.fogao_aceso.file)
 for y in 64:
  for x in 64:check(cold.get_pixel(x,y).a==hot.get_pixel(x,y).a,"Fogão conserva contorno ao acender")
 var scene: Node2D = load("res://Amostra.tscn").instantiate();check(scene.get_node("Piso32").get_used_cells().size()==126,"Cena editável usa tiles");scene.free()
 print("VALIDADO: ",data.entries.size()," PNGs; ",frames," frames 32x32; ",checks," verificações; ",total_bytes," bytes de PNGs de produção.");quit()
