@tool
extends Node2D
## One physical base, shared by empty, cutting and plating workstations.
@export_enum("Vazia","Corte","Empratamento") var kit: int = 0:
	set(value):
		kit=value
		queue_redraw()
@export var mostrar_base := true
@export_range(0,20,1) var pratos_limpos: int = 0:
	set(value):
		var next := clampi(value,0,STOCK.CLEAN_PLATE_CAPACITY)
		if pratos_limpos==next:return
		pratos_limpos=next
		layout_pratos.clear()
		queue_redraw()
var layout_pratos: Dictionary = {}
var escala_kit := Vector2.ZERO
var bancada := false
const LAYOUT = preload("res://moveis/LayoutEmpratamento.gd")
const STOCK = preload("res://simulacao/nativa/Armazenamento.gd")
const ALTURA_BASE := 30
const PROFUNDIDADE_TAMPO := 28
const BASE = preload("res://arte/modular/mesa-trabalho.png")
const PRATO = preload("res://arte/modular/prato-vazio.png")
const UTENSILIOS = preload("res://arte/modular/kit-empratamento-utensilios.png")
const KITS = preload("res://arte/modular/kits-mesa.png")
const CENTRO_KIT := Vector2(0,-ALTURA_BASE-PROFUNDIDADE_TAMPO/2.0)
const RECORTES = [Rect2(155,335,599,255),Rect2(1017,335,621,255)]
func atualizar_pratos(quantidade: int, compacta: bool = false) -> void:
	pratos_limpos=quantidade
	if escala_kit!=scale or bancada!=compacta:
		escala_kit=scale;bancada=compacta;layout_pratos.clear();queue_redraw()

func disposicao_pratos() -> Dictionary:
	if not layout_pratos.is_empty():return layout_pratos
	var plates: Array[Rect2] = []
	var piles := [mini(STOCK.PLATES_PER_STACK,pratos_limpos),maxi(0,pratos_limpos-STOCK.PLATES_PER_STACK)]
	var geometry := LAYOUT.frame(scale,bancada)
	for pile in 2:
		for layer in piles[pile]:plates.append(LAYOUT.clean(pile,layer,geometry))
	layout_pratos={"plates":plates,"piles":piles}
	return layout_pratos

func desenhar_empratamento() -> void:
	var layout := disposicao_pratos()
	# The furniture footprint may rotate/stretch; the ceramic stays oval.
	var compensate := Vector2(1/maxf(absf(scale.x),0.001),1/maxf(absf(scale.y),0.001))
	draw_set_transform(CENTRO_KIT,0,compensate)
	var geometry := LAYOUT.frame(scale,bancada)
	draw_texture_rect_region(UTENSILIOS,LAYOUT.rect(Rect2(-35,8,11,6),geometry),Rect2(157,461,619,356))
	draw_texture_rect_region(UTENSILIOS,LAYOUT.rect(Rect2(-22,-3,6,12),geometry),Rect2(899,270,509,515))
	# One sprite per real clean plate, including zero. Never use a baked stack.
	for rect in layout.plates:draw_texture_rect_region(PRATO,rect,Rect2(125,166,1249,736))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut := ShaderMaterial.new()
	cut.shader=preload("res://arte/taverna/recorte.gdshader")
	material=cut
func _draw() -> void:
	if mostrar_base:draw_texture_rect_region(BASE,Rect2(-38,-ALTURA_BASE-PROFUNDIDADE_TAMPO,76,ALTURA_BASE+PROFUNDIDADE_TAMPO),Rect2(94,122,1245,877))
	if kit==1:
		draw_texture_rect_region(KITS,Rect2(CENTRO_KIT-Vector2(24,10),Vector2(48,20)),RECORTES[0])
	elif kit==2:desenhar_empratamento()
