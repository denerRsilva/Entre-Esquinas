extends RefCounted
## Visual recipe pages rendered by the native Godot interface.
const RECIPES = preload("res://simulacao/nativa/Receitas.gd")
const ITEMS = preload("res://simulacao/nativa/itens.json")
const PATHS = {
	"cut":"M2 13l4-4 M5 8l6-6 3 3-6 6z M2 15h12",
	"pot":"M3 6h10v6l-2 2H5l-2-2z M1 7h2 M13 7h2 M4 4h8 M7 2h2",
	"flame":"M8 1l3 6 2-2 1 5-3 4H6l-4-4 3-5 1 3z",
	"serve":"M1 12h14 M3 10a5 5 0 0 1 10 0z M7 3h2"
}
func node(tag: String,children: Array,cls: String = "") -> Dictionary:return {"tag":tag,"cls":cls,"children":children}
func caption(value: String,tag: String = "small") -> Dictionary:return node(tag,[{"tag":"text","text":value}])
func food(item: String,hero: bool = false) -> Dictionary:
	return {"tag":"canvas","cls":"recipeHero" if hero else "foodArt","label":ITEMS.data.get(item,RECIPES.RECIPES.data.get(item,{})).get("name","Comida"),"art":[["food",item,0,0,64,64,1,1,0,0,1]]}
func icon(kind: String) -> Dictionary:
	return {"tag":"span","cls":"controlIcon","art":[["svg",'<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="'+PATHS[kind]+'"/></svg>']]}
func render() -> Dictionary:
	var pages: Array = []
	for id in RECIPES.RECIPES.data:
		var recipe: Dictionary = RECIPES.RECIPES.data[id]
		var ingredients: Array = []
		for item in recipe.foods:
			var symbols: Array = [food(item),caption(str(int(recipe.foods[item]))+" ×")]
			if item!="arroz":symbols.append(icon("cut"))
			symbols.append(caption("Cortar" if item!="arroz" else "Direto"))
			ingredients.append(node("div",symbols,"recipeIngredient"))
		var flow: Array = []
		for step in [["pot","Panela"],["flame",str(int(recipe.time))+" s"],["serve","Prato"]]:flow.append(node("div",[icon(step[0]),caption(step[1])]))
		pages.append(node("div",[food(id,true),caption(recipe.name,"b"),caption("1 porção"),node("div",ingredients,"recipeIngredients"),node("div",flow,"recipeFlow")],"card"))
	return {"tag":"div","id":"panel","children":[node("div",pages,"recipeBook")]}
