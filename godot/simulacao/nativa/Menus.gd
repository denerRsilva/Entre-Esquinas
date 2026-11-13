extends RefCounted
## Builds the native Control description from a temporary legacy node snapshot.
var widget_paths: Array = []

func summary(node: Variant) -> String:
	if node is String:return node
	if node.attrs.get("aria-hidden")=="true":return ""
	var words: PackedStringArray = []
	for child in node.nodes:words.append(summary(child))
	var text := " ".join(words)
	return text if not text.is_empty() else str(node.attrs.get("aria-label",""))

func text_content(node: Variant) -> String:
	if node is String:return node
	var result := ""
	for child in node.nodes:result+=text_content(child)
	return result

func artwork(node: Variant) -> Variant:
	if node is String:return null
	if node.tag=="canvas":return node.get("art",[])
	if node.has("svg"):return [["svg",node.svg]]
	for child in node.nodes:
		var found = artwork(child)
		if found!=null:return found
	return null

func pack(node: Variant, path: String) -> Variant:
	if node is String:
		return {"tag":"text","text":node.strip_edges()} if not node.strip_edges().is_empty() else null
	if node.hidden or node.attrs.get("aria-hidden")=="true":return null
	var value := {"tag":node.tag,"cls":node.cls,"id":node.id}
	if node.has("anchor"):value.anchor=node.anchor
	if node.tag in ["button","input","select","a"]:
		widget_paths.append(path)
		value.merge({"path":path,"disabled":node.disabled,"label":node.attrs.get("aria-label",node.title),"text":summary(node).strip_edges() if node.tag=="button" else "","value":node.value,"type":node.type,"checked":node.checked})
		for key in ["min","max","step"]:
			if node.has(key):value[key]=node[key]
		if "inventorySlot" in node.cls:
			var children: Array = node.nodes.filter(func(n):return n is Dictionary)
			value.text=text_content(children[-1]) if not children.is_empty() else "—"
		if node.tag=="select":
			value.options=[]
			for child in node.nodes:
				if child is Dictionary:value.options.append([text_content(child),child.value])
		var art = artwork(node)
		if art!=null:value.art=art
	elif node.tag=="canvas":
		value.art=node.art
		if node.attrs.has("aria-label"):value.label=node.attrs["aria-label"]
	elif node.tag=="progress":
		value.value=node.value
		value.max=node.get("max",0)
	elif node.has("svg"):
		value.art=[["svg",node.svg]]
		if node.attrs.has("aria-label"):value.label=node.attrs["aria-label"]
	else:
		value.children=[]
		for index in node.nodes.size():
			var child = pack(node.nodes[index],path+"/"+str(index))
			if child!=null:value.children.append(child)
	return value
