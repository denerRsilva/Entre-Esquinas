extends RefCounted
## Retain active references and a short recent history; financial totals live
## in ledger/reports and meal/reputation totals are independent of old orders.
static func compact(state: Dictionary) -> void:
	if not state.get("orders") is Array or state.orders.size()<4500:return
	var referenced := {}
	for actor in state.get("workers",[])+[state.get("player",{})]:
		if actor is Dictionary and actor.get("carry") is Dictionary and actor.carry.get("kind")=="dish":referenced[actor.carry.get("order")]=true
	for customer in state.get("customers",[]):
		if customer is Dictionary:referenced[customer.get("order")]=true
	for id in state.get("ready",[]):referenced[id]=true
	var retained: Array = []
	var recent := 0
	for i in range(state.orders.size()-1,-1,-1):
		var order = state.orders[i]
		if not order is Dictionary:return
		if order.get("state") not in ["paid","lost"] or referenced.has(order.get("id")) or recent<200:
			retained.push_front(order)
			if order.get("state") in ["paid","lost"]:recent+=1
	state.orders=retained
