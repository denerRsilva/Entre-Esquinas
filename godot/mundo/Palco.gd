extends Node2D
const Tracos = preload("res://mundo/Tracos.gd")
@export var cozinheira: PackedScene = preload("res://personagens/Cozinheira.tscn")
@export var moveis: Dictionary[String,PackedScene] = {
	"computer":preload("res://moveis/Computador.tscn"),"receiving":preload("res://moveis/Recebimento.tscn"),
	"stove":preload("res://moveis/Fogao.tscn"), "kitchen":preload("res://moveis/Cozinha.tscn"), "prep":preload("res://moveis/Preparo.tscn"),
	"sink":preload("res://moveis/Pia.tscn"), "fridge":preload("res://moveis/Geladeira.tscn"),
	"cold":preload("res://moveis/Geladeira.tscn"), "chair":preload("res://moveis/Cadeira.tscn"),
	"table":preload("res://moveis/Mesa.tscn"), "shelf":preload("res://moveis/Prateleira.tscn"),
	"potRack":preload("res://moveis/EstantePanelas.tscn"), "bin":preload("res://moveis/Lixeira.tscn")}
@export var garcom: PackedScene = preload("res://personagens/Garcom.tscn")
@export var logistica: PackedScene = preload("res://personagens/Logistica.tscn")
@export var moradora: PackedScene = preload("res://personagens/Moradora.tscn")
const CLIENTES = [preload("res://personagens/Cliente1.tscn"),preload("res://personagens/Cliente2.tscn"),preload("res://personagens/Cliente3.tscn")]
const DIRECOES = {"up":"cima","down":"baixo","left":"esquerda","right":"direita"}
var pool: Dictionary = {}
var used: Dictionary = {}
var order := 0
var art_cuts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://arte/taverna/recortes.json"))

func piece(key: String, scene: PackedScene = null) -> Node2D:
	var i: int = used.get(key,0)
	used[key] = i+1
	var nodes: Array = pool.get(key,[])
	if i == nodes.size():
		var child: Node2D = scene.instantiate() if scene else Tracos.new()
		add_child(child)
		nodes.append(child)
		pool[key] = nodes
	var n: Node2D = nodes[i]
	n.visible = true
	n.z_index = order
	order += 1
	return n

func paint(data: Dictionary) -> void:
	used.clear()
	$Salao.set_layout(data.get("compact",false),data.get("singleRoom",false))
	order = 0
	$Salao.visible = data.room=="restaurant"
	$Rua.visible = data.room=="street"
	$Estoque.visible = data.room=="stock"
	var camera: Array = data.camera
	scale = Vector2.ONE*float(camera[2])
	position = -Vector2(camera[0],camera[1])*scale
	var segment := []
	for op in data.scene:
		if op[0] not in ["cook","furniture","npc"]:
			segment.append(op)
			continue
		if not segment.is_empty(): piece("detalhes").set_commands(segment)
		segment = []
		if op[0] in ["cook","npc"]:
			var n: AnimatedSprite2D
			if op[0]=="npc":
				var skin := int(op[2])
				var model: PackedScene = CLIENTES[skin-12] if skin>=12 and skin<=14 else garcom if skin==9 else logistica if skin==10 else moradora
				# Pool by model, in display order, to bound memory across days.
				n = piece(model.resource_path,model) as AnimatedSprite2D
				op = ["cook",op[3],op[4],op[5],op[6]]
			else:
				n = piece("cozinheira",cozinheira) as AnimatedSprite2D
			n.position = Vector2(op[1],op[2]).round()
			var anim: StringName = DIRECOES[op[3]]
			if n.animation != anim:
				n.animation = anim
			if op[4] and not data.construction and data.modal=="":
				if not n.is_playing(): n.play(anim)
			elif not op[4]:
				n.pause()
				n.frame = mini(1,n.sprite_frames.get_frame_count(anim)-1)
			else:
				n.pause()
		else:
			var n := piece(op[1],moveis[op[1]])
			n.position = Vector2(op[2]+op[4]/2,op[3]+op[5])
			n.modulate.a = 0.65 if op[7] else 1.0
			var original := Vector2(40,40)
			if op[1] in ["computer","receiving","stove","prep","kitchen","sink","table","shelf","potRack"]: original.x=80
			if op[1] in ["fridge","cold"]: original.y=80
			n.scale = Vector2(float(op[4])/original.x,float(op[5])/original.y)
			if op[1]=="chair":
				var facing := int(op[6])
				var crop: Array = art_cuts.moveis[[9,10,8,10][facing]]
				var sprite: Sprite2D = n.get_node("Arte")
				sprite.region_rect = Rect2(crop[0],crop[1],crop[2],crop[3])
				sprite.scale = Vector2(30.0/crop[2],40.0/crop[3])
				if facing==1: n.scale.x *= -1
	if not segment.is_empty(): piece("detalhes").set_commands(segment)
	for key in pool:
		for i in range(used.get(key,0),pool[key].size()):
			var unused: Node2D = pool[key][i]
			unused.hide()
			if unused is AnimatedSprite2D: unused.pause()

func pause_actors() -> void:
	for nodes in pool.values():
		for node in nodes:
			if node is AnimatedSprite2D: node.pause()
