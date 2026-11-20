extends SceneTree
var scene:Node2D
var objects:Node2D
var collision:StaticBody2D
var assets:Dictionary
var layout:Dictionary
var used:Dictionary={}
var counts:Dictionary={}
var object_index:=0
var actor_index:=0
func texture(alias:String)->Texture2D:
	used[alias]=true;return load("res://"+assets[alias].file)
func own(n:Node,parent:Node):parent.add_child(n);n.owner=scene
func shape(rect:Array,parent:Node=collision,origin:Vector2=Vector2.ZERO):
	var c:=CollisionShape2D.new();var r:=RectangleShape2D.new();r.size=Vector2(rect[2],rect[3]);c.shape=r;c.position=Vector2(rect[0]+rect[2]/2.0,rect[1]+rect[3]/2.0)-origin;c.name="Solo_%04d"%parent.get_child_count();own(c,parent)
func terrain(data:Dictionary):
	var layer:=TileMapLayer.new();layer.name="Piso32";layer.z_index=-20;own(layer,scene)
	var tiles:=TileSet.new();tiles.tile_size=Vector2i(32,32);layer.tile_set=tiles
	var aliases:Array=[]
	for n in range(1,23):aliases.append("grama_%02d"%n)
	aliases.append_array(["calcada","asfalto"])
	for alias in aliases:
		var atlas:=TileSetAtlasSource.new();atlas.texture=texture(alias);atlas.texture_region_size=Vector2i(32,32)
		for y in int(atlas.texture.get_height()/32):
			for x in int(atlas.texture.get_width()/32):atlas.create_tile(Vector2i(x,y))
		tiles.add_source(atlas)
	var w:=int(data.world[0]);var h:=int(data.world[1]);var dirt:Dictionary={}
	for y in h:
		for x in w:
			if data.terrain[y*w+x]!="grass":dirt[Vector2i(x,y)]=true
	for y in h:
		for x in w:
			var cell:=Vector2i(x,y);var kind:String=data.terrain[y*w+x];var index:=22
			if kind=="dirt":index=21
			elif kind=="paving":index=23
			elif kind=="asphalt":index=24
			else:
				var u:=dirt.has(cell+Vector2i.UP);var d:=dirt.has(cell+Vector2i.DOWN);var l:=dirt.has(cell+Vector2i.LEFT);var r:=dirt.has(cell+Vector2i.RIGHT)
				if u:index=1 if l else 3 if r else 2
				elif d:index=7 if l else 5 if r else 6
				elif l:index=8
				elif r:index=4
				elif dirt.has(cell+Vector2i(-1,-1)):index=11
				elif dirt.has(cell+Vector2i(1,-1)):index=12
				elif dirt.has(cell+Vector2i(-1,1)):index=10
				elif dirt.has(cell+Vector2i(1,1)):index=9
			layer.set_cell(cell,index-1,Vector2i(x%2,y%2) if index>=23 else Vector2i.ZERO)
func add_object(data:Dictionary):
	var alias:String=data.asset;var size:Array=assets[alias].size
	counts[alias]=int(counts.get(alias,0))+1
	var visual_size:=Vector2(size[0],size[1])
	if data.has("animation"):visual_size=Vector2(data.animation.frame[0],data.animation.frame[1])
	var foot_height:float=data.get("offset_foot",visual_size.y)
	var holder:=Node2D.new();holder.name=alias+"_%03d"%int(counts[alias]);holder.set_meta("layout_index",object_index);object_index+=1;holder.position=Vector2(data.pos[0]+visual_size.x/2.0,data.pos[1]+foot_height);own(holder,objects)
	if data.get("ground",false):holder.z_index=-10
	var sprite:Sprite2D
	if data.has("animation"):
		var animated:=AnimatedSprite2D.new();animated.name="Animacao";var frames:=SpriteFrames.new();frames.remove_animation("default");frames.add_animation("loop");frames.set_animation_speed("loop",data.animation.fps)
		for i in int(data.animation.frames):
			var tex:=AtlasTexture.new();tex.atlas=texture(alias);tex.region=Rect2(i*visual_size.x,0,visual_size.x,visual_size.y);frames.add_frame("loop",tex)
		animated.sprite_frames=frames;animated.centered=false;animated.position=-Vector2(visual_size.x/2.0,foot_height);own(animated,holder);animated.play("loop")
	else:
		sprite=Sprite2D.new();sprite.name="Sprite";sprite.texture=texture(alias);sprite.centered=false;sprite.position=-Vector2(visual_size.x/2.0,foot_height);own(sprite,holder)
	if data.has("solid"):
		var body:=StaticBody2D.new();body.name="BaseFisica";own(body,holder);shape(data.solid,body,holder.position)
	if data.has("role") and visual_size.y>=192:
		holder.add_to_group("roof_fade",true);holder.set_meta("visual_rect",Rect2(data.pos[0],data.pos[1],visual_size.x,visual_size.y))
	# Long shadows use a single primitive under tall structures, not extra PNGs.
	if data.has("role"):
		var shadow:=Polygon2D.new();shadow.color=Color(0.07,0.09,0.10,0.14);shadow.z_index=-1;shadow.polygon=PackedVector2Array([Vector2(-visual_size.x/2,-48),Vector2(visual_size.x/2,-48),Vector2(visual_size.x/2+32,12),Vector2(-visual_size.x/2+20,12)]);own(shadow,holder)
func character(alias:String,pos:Vector2,is_player:bool):
	var actor:Node2D
	if is_player:
		actor=CharacterBody2D.new();actor.name="Jogador"
		var c:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=7;c.shape=circle;c.position=Vector2(0,-4);actor.add_child(c)
	else:actor=Node2D.new();actor.name="Morador_%02d"%actor_index;actor_index+=1;actor.add_to_group("resident",true)
	actor.position=pos;own(actor,objects)
	for child in actor.get_children():child.owner=scene
	var sprite:=Sprite2D.new();sprite.name="Sprite";sprite.texture=texture(alias);sprite.region_enabled=true;sprite.region_rect=Rect2(96,0,32,64);sprite.position=Vector2(0,-24);own(sprite,actor)
	actor.set_script(load("res://Jogador.gd" if is_player else "res://Morador.gd"))
func lamp(pos:Array):
	var light:=PointLight2D.new();light.name="Poste_Luz_%02d"%get_nodes_in_group("street_light").size();light.position=Vector2(pos[0],pos[1]);light.color=Color(1.0,0.72,0.38);light.energy=1.2;light.texture_scale=2.6;light.enabled=false
	var gradient:=Gradient.new();gradient.set_color(0,Color(1,1,1,0.85));gradient.set_color(1,Color(1,1,1,0))
	var tex:=GradientTexture2D.new();tex.gradient=gradient;tex.width=128;tex.height=128;tex.fill=GradientTexture2D.FILL_RADIAL;tex.fill_from=Vector2(0.5,0.5);tex.fill_to=Vector2(1,0.5);light.texture=tex
	light.add_to_group("street_light",true);own(light,scene)
func _initialize():call_deferred("run")
func run():
	assets=JSON.parse_string(FileAccess.get_file_as_string("res://assets.json"));layout=JSON.parse_string(FileAccess.get_file_as_string("res://cidade.json"))
	scene=Node2D.new();scene.name="CidadeRefugio";root.add_child(scene)
	terrain(layout)
	objects=Node2D.new();objects.name="Objetos";objects.y_sort_enabled=true;own(objects,scene)
	collision=StaticBody2D.new();collision.name="ColisoesDoSolo";own(collision,scene)
	# Match the navigation border with physical bounds for keyboard and touch input.
	var world_w:float=layout.world[0]*32;var world_h:float=layout.world[1]*32
	for border in [[0,0,world_w,32],[0,world_h-32,world_w,32],[0,0,32,world_h],[world_w-32,0,32,world_h]]:shape(border)
	for o in layout.objects:add_object(o)
	for p in layout.lamps:lamp(p)
	character("morador_1",Vector2(layout.spawn[0]*32+16,layout.spawn[1]*32+16),true)
	for person in layout.people:character(person.asset,Vector2.ZERO,false)
	var destinations:=Node2D.new();destinations.name="Destinos";own(destinations,scene)
	for point in layout.points:
		var marker:=Marker2D.new();marker.name=point.id;marker.position=Vector2(point.cell[0]*32+16,point.cell[1]*32+16);marker.set_meta("nome",point.name);own(marker,destinations)
	var modulate:=CanvasModulate.new();modulate.name="Ambiente";modulate.color=Color(0.96,0.94,0.89);own(modulate,scene)
	var camera:=Camera2D.new();camera.name="Camera";camera.zoom=Vector2(1.5,1.5);camera.position=Vector2(1232,1024);camera.position_smoothing_enabled=false;own(camera,scene)
	var hud:=CanvasLayer.new();hud.name="HUD";own(hud,scene);hud.set_script(load("res://Interface.gd"))
	scene.set_script(load("res://Cidade.gd"))
	var packed:=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,"res://Cidade.tscn")==OK)
	used["ui"]=true
	var f:=FileAccess.open("res://used-assets.json",FileAccess.WRITE);f.store_string(JSON.stringify(used.keys()));f.close()
	print("Cena editável salva; objetos: ",layout.objects.size(),"; recursos: ",used.size());quit()
