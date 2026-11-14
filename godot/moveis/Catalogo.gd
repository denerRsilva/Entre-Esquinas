extends RefCounted
## Shared scenes keep construction thumbnails and world furniture in sync.
const CENAS: Dictionary[String,PackedScene] = {
	"worktable":preload("res://moveis/MesaTrabalho.tscn"), "cuttingKit":preload("res://moveis/KitCorte.tscn"), "platingKit":preload("res://moveis/KitEmpratamento.tscn"),
	"counterH":preload("res://moveis/BancadaH.tscn"),"counterV":preload("res://moveis/BancadaV.tscn"),"counterCorner":preload("res://moveis/BancadaCanto.tscn"),
	"computer":preload("res://moveis/Computador.tscn"),"receiving":preload("res://moveis/Recebimento.tscn"),
	"stove":preload("res://moveis/Fogao.tscn"), "kitchen":preload("res://moveis/Cozinha.tscn"), "prep":preload("res://moveis/Preparo.tscn"),
	"sink":preload("res://moveis/Pia.tscn"), "fridge":preload("res://moveis/Geladeira.tscn"),
	"cold":preload("res://moveis/Geladeira.tscn"), "chair":preload("res://moveis/Cadeira.tscn"),
	"table":preload("res://moveis/Mesa.tscn"), "shelf":preload("res://moveis/Prateleira.tscn"),
	"potRack":preload("res://moveis/EstantePanelas.tscn"), "bin":preload("res://moveis/Lixeira.tscn")}
