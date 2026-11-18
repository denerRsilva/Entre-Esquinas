extends RefCounted
const Paint=preload("res://mundo/Tracos.gd")
static func icon(label:String, fallback:Texture2D)->Texture2D:
 var text:=label.to_lower()
 var item:=""
 if "prato" in text or "empratar" in text:
  item='<path fill="#6c513d" d="M4 13h4V9h24v4h4v14h-4v4H8v-4H4z"/><path fill="#f4e5be" d="M6 14h4v-3h20v3h4v12h-4v3H10v-3H6z"/><path fill="#cbb58b" d="M10 16h20v9H10z"/>'
 elif "panela" in text or "cozinh" in text or "item" in text:
  item='<path fill="#333e3e" d="M4 12h32v5h-4v14H8V17H4z"/><path fill="#abb5a5" d="M10 12h20v16H10z"/><path fill="#5e6d66" d="M12 14h16v4H12z"/>'
 elif "ingrediente" in text or "cortar" in text or "comida" in text:
  item='<path fill="#5d8e42" d="M14 5h5v8h-5zM20 4h5v10h-5z"/><path fill="#ef9b35" d="M12 13h17v7h-4v5h-5v5h-5v4h-5z"/>'
 else:
  return fallback
 # Distinguish a cooked plate from clean stacks using the existing food colors.
 if "prato nas mãos" in text:
  item+='<path fill="#dd963d" d="M12 17h8v6h-8z"/><path fill="#6c903e" d="M22 16h6v7h-6z"/>'
 elif "pratos limpos" in text:
  item+='<path fill="#6c513d" d="M8 31h24v3H8zM8 35h24v3H8z"/>'
 var badge:=""
 if "cancel" in text or "descart" in text:
  badge='<path stroke="#f3b481" stroke-width="4" d="M38 26l12 12m0-12L38 38"/>'
 elif "retirar" in text or "pegar" in text or "recolher" in text:
  badge='<path fill="#f4cb65" d="M42 23h4v9h6l-8 9-8-9h6z"/>'
 elif "instalar" in text or "colocar" in text or "apoiar" in text or "devolver" in text or "adicionar" in text or "guardar" in text:
  badge='<path fill="#9ddd9b" d="M42 40h4v-9h6l-8-9-8 9h6z"/>'
 elif "lavar" in text:
  badge='<path fill="#86d9eb" d="M44 22l7 12v5H37v-5z"/>'
 elif "cozinh" in text:
  badge='<path fill="#f4a246" d="M44 21l4 10 4-3v10l-7 4-8-5v-7l4 3z"/>'
 elif "cortar" in text:
  badge='<path fill="#e7e6cc" d="M38 32l11-11 4 4-11 11z"/><path fill="#ac764a" d="M34 36l5-5 4 4-5 5z"/>'
 else:
  badge='<path fill="#f4cb65" d="M36 36h17v4H36zM39 34v-6h11v6z"/>'
 return Paint.vector('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 44" shape-rendering="crispEdges">'+item+'<path fill="#243c32" d="M34 20h21v23H34z"/>'+badge+'</svg>')
