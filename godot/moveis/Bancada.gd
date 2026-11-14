@tool
extends Node2D
## Modular pieces use the actual worktable wood, with a fixed camera and height.
@export_enum("Horizontal","Vertical","Canto") var forma: int = 0:
	set(value):
		forma=value
		queue_redraw()
var giro := 0
var vizinhos := 0
var perfis_vizinhos: Array = []
var unioes: Array[int] = [0,0,0,0]
const MESA = preload("res://moveis/MesaTrabalho.gd")
const ATLAS = MESA.BASE
const PASSO := 2
const CELULAS := 20
const ALTURA := MESA.ALTURA_BASE
static var centros_kit: Dictionary = {}
static var perfis: Dictionary = {}
const BORDA = Color("#302019")

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut := ShaderMaterial.new()
	cut.shader=preload("res://arte/taverna/recorte.gdshader")
	material=cut

func configurar(rotation_index: int, neighbors: int = 0, profiles: Array = []) -> void:
	if giro==posmod(rotation_index,4) and vizinhos==neighbors and perfis_vizinhos==profiles:return
	giro=posmod(rotation_index,4)
	vizinhos=neighbors
	perfis_vizinhos=profiles
	queue_redraw()

static func perfil(shape: int, rotation_index: int) -> PackedByteArray:
	var key := Vector2i(shape,posmod(rotation_index,4))
	if perfis.has(key):return perfis[key].duplicate()
	# Each module keeps its saved 40x40 footprint. H has the same 28px top
	# depth as the worktable; V runs back into the cell; the elbow joins both.
	var cells := PackedByteArray()
	cells.resize(CELULAS*CELULAS)
	for y in CELULAS:
		for x in CELULAS:
			var filled := y>=6 if shape==0 else x<14 if shape==1 else y>=6 or x<14
			if not filled:continue
			var point := Vector2i(x,y)
			for turn in posmod(rotation_index,4):point=Vector2i(CELULAS-1-point.y,point.x)
			cells[point.y*CELULAS+point.x]=1
	perfis[key]=cells
	return cells.duplicate()

static func centro_kit(shape: int, rotation_index: int) -> Vector2:
	var key := Vector2i(shape,posmod(rotation_index,4))
	if centros_kit.has(key):return centros_kit[key]
	var cells := perfil(shape,rotation_index)
	var centroid := Vector2.ZERO
	var count := 0
	for y in CELULAS:
		for x in CELULAS:
			if cells[y*CELULAS+x]:centroid+=Vector2(x+0.5,y+0.5);count+=1
	centroid/=count
	var best := Vector2(10,10)
	var distance := INF
	# The kit is 24x20 px on a counter. Keep its complete rectangle on wood,
	# choosing the position nearest the surface centroid (also for elbows).
	for y in range(5,16):
		for x in range(6,15):
			var fits := true
			for row in range(y-5,y+5):
				for col in range(x-6,x+6):
					if cells[row*CELULAS+col]==0:fits=false;break
				if not fits:break
			var candidate := Vector2(x,y)
			if fits and candidate.distance_squared_to(centroid)<distance:
				best=candidate;distance=candidate.distance_squared_to(centroid)
	centros_kit[key]=Vector2(-20,-40-ALTURA)+best*PASSO
	return centros_kit[key]

static func faixas(cells: PackedByteArray, horizontal: bool) -> int:
	var mask := 0
	for y in CELULAS:
		for x in CELULAS:
			if cells[y*CELULAS+x]!=0:mask|=1<<(y if horizontal else x)
	return mask

func superficie() -> PackedByteArray:
	var cells := perfil(forma,giro)
	unioes=[0,0,0,0]
	for side in 4:
		if (vizinhos&(1<<side))==0:continue
		var other: PackedByteArray = perfis_vizinhos[side] if perfis_vizinhos.size()==4 and not perfis_vizinhos[side].is_empty() else cells
		unioes[side]=faixas(cells,side%2==1)&faixas(other,side%2==1)
	# Extend the matching strips toward each neighbor, without widening a
	# vertical run or turning horizontal runs into identical square blocks.
	var original := cells.duplicate()
	for y in CELULAS:
		for x in CELULAS:
			if original[y*CELULAS+x]==0:continue
			if unido(0,x):
				for j in range(y):cells[j*CELULAS+x]=1
			if unido(1,y):
				for j in range(x+1,CELULAS):cells[y*CELULAS+j]=1
			if unido(2,x):
				for j in range(y+1,CELULAS):cells[j*CELULAS+x]=1
			if unido(3,y):
				for j in range(x):cells[y*CELULAS+j]=1
	return cells

func unido(side: int, index: int) -> bool:
	return (unioes[side]&(1<<index))!=0

func occupied(cells: PackedByteArray,x: int,y: int) -> bool:
	return x>=0 and x<CELULAS and y>=0 and y<CELULAS and cells[y*CELULAS+x]!=0

func _draw() -> void:
	var cells := superficie()
	# Fronts stay upright when rotating the footprint. Match the table's
	# apron and legs instead of stretching a thin apron into a tall cabinet.
	for y in CELULAS:
		var x := 0
		while x<CELULAS:
			if not occupied(cells,x,y) or occupied(cells,x,y+1) or (y==CELULAS-1 and unido(2,x)):
				x+=1;continue
			var start := x
			while x<CELULAS and occupied(cells,x,y) and not occupied(cells,x,y+1) and not (y==CELULAS-1 and unido(2,x)):x+=1
			var width := (x-start)*PASSO
			var face := Rect2(-20+start*PASSO,-40-ALTURA+(y+1)*PASSO,width,ALTURA)
			draw_texture_rect_region(ATLAS,face,Rect2(94,545,1245,454))
	# Sample the same tabletop without rotating wood grain or the camera.
	for y in CELULAS:
		var x := 0
		while x<CELULAS:
			if not occupied(cells,x,y):x+=1;continue
			var start := x
			while x<CELULAS and occupied(cells,x,y):x+=1
			var surface := Rect2(-20+start*PASSO,-40-ALTURA+y*PASSO,(x-start)*PASSO,PASSO)
			var source := Rect2(155+start*1124.0/CELULAS,152+posmod(y-6,14)*340.0/14,(x-start)*1124.0/CELULAS,340.0/14)
			draw_texture_rect_region(ATLAS,surface,source)
	# Outline exposed edges only; adjacent modules share a continuous top.
	for y in CELULAS:
		for x in CELULAS:
			if not occupied(cells,x,y):continue
			var p := Vector2(-20+x*PASSO,-40-ALTURA+y*PASSO)
			if not occupied(cells,x,y-1) and not (y==0 and unido(0,x)):draw_line(p,p+Vector2(PASSO,0),BORDA,1)
			if not occupied(cells,x+1,y) and not (x==CELULAS-1 and unido(1,y)):draw_line(p+Vector2(PASSO,0),p+Vector2(PASSO,PASSO),BORDA,1)
			if not occupied(cells,x-1,y) and not (x==0 and unido(3,y)):draw_line(p,p+Vector2(0,PASSO),BORDA,1)
			if not occupied(cells,x,y+1) and not (y==CELULAS-1 and unido(2,x)):draw_line(p+Vector2(0,PASSO),p+Vector2(PASSO,PASSO),Color("#e2a052"),1)
