@tool
extends Node2D
@export_enum("Horizontal","Vertical","Canto") var forma:int=0:
 set(value):
  forma=value
  queue_redraw()
var giro:int=0
const ATLAS=preload("res://arte/modular/modulos.svg")
func configurar(rotation_index:int):
 giro=rotation_index
 queue_redraw()
func _draw():
 var tile:=4+forma
 if forma<2:tile=4+((forma+giro)%2)
 if forma==2:
  draw_set_transform(Vector2(0,-20),giro*PI/2)
  draw_texture_rect_region(ATLAS,Rect2(-20,-20,40,40),Rect2(tile*32,0,32,32))
 else:
  draw_texture_rect_region(ATLAS,Rect2(-20,-40,40,40),Rect2(tile*32,0,32,32))
