extends RefCounted
# A plan accounts for individual field units and quantities in reserve. No state
# changes occur until every ingredient and the dedicated item have been checked.
static func plan(g: Control, recipe: Dictionary, required_selected: bool) -> Dictionary:
	var remaining: Array = recipe["materials"].duplicate()
	var field: Array[int] = []
	var reserve: Dictionary = {}
	if required_selected:
		if g.selected < 0 or g.selected >= g.dogs.size(): return {}
		var selected_kind: int = int(g.dogs[g.selected]["kind"])
		if not remaining.has(selected_kind): return {}
		field.append(g.selected)
		remaining.erase(selected_kind)
	for value in remaining:
		var kind: int = int(value)
		if int(g.reserve_units.get(kind,0)) > int(reserve.get(kind,0)):
			reserve[kind] = int(reserve.get(kind,0))+1
			continue
		var found: int = -1
		for i in range(g.dogs.size()):
			if not field.has(i) and int(g.dogs[i]["kind"]) == kind:
				found = i
				break
		if found < 0: return {}
		field.append(found)
	return {"field":field,"reserve":reserve}

static func add(g: Control, kind: int, state: Dictionary = {}) -> void:
	g.reserve_units[kind] = int(g.reserve_units.get(kind,0))+1
	if not state.is_empty():
		var states: Array = g.reserve_states.get(kind,[])
		var saved: Dictionary = state.duplicate(true)
		saved.erase("cell")
		states.append(saved)
		g.reserve_states[kind] = states

static func take(g: Control, kind: int) -> Dictionary:
	var count: int = int(g.reserve_units.get(kind,0))
	if count <= 0: return {}
	var states: Array = g.reserve_states.get(kind,[])
	var state: Dictionary = {"kind":kind,"cooldown":0.0,"hidden_charge":0}
	# Consume newly acquired copies first, retaining stored combat state.
	if count <= states.size():
		state = states.pop_front()
		if states.is_empty(): g.reserve_states.erase(kind)
		else: g.reserve_states[kind] = states
	if count == 1: g.reserve_units.erase(kind)
	else: g.reserve_units[kind] = count-1
	return state

static func craft(g: Control, recipe: Dictionary, required_selected: bool) -> bool:
	if g.game_over or g.victory or not g._recipe_item_ready(recipe): return false
	var result: int = int(recipe["result"])
	if result < 0 or result >= g.DOGS.size(): return false
	var chosen: Dictionary = plan(g,recipe,required_selected)
	if chosen.is_empty(): return false
	var field: Array[int] = chosen["field"]
	var cell: int = -1
	if not field.is_empty():
		var index: int = g.selected if field.has(g.selected) else field[0]
		cell = int(g.dogs[index]["cell"])
		if cell < 0 or cell >= 36: return false
	if cell < 0:
		var occupied: Dictionary={}
		for dog in g.dogs: occupied[int(dog["cell"])]=true
		for candidate in range(36):
			if not occupied.has(candidate):
				cell=candidate
				break
		if cell < 0: return false
	# The verified plan is consumed synchronously; repeated taps re-check stock.
	field.sort()
	field.reverse()
	for index in field: g.dogs.remove_at(index)
	for kind in chosen["reserve"]:
		for copy in range(int(chosen["reserve"][kind])): take(g,int(kind))
	g._consume_recipe_item(recipe)
	g.dogs.append({"kind":result,"cell":cell,"cooldown":0.0,"hidden_charge":0})
	g.selected=g.dogs.size()-1
	g.pending_deploy = -1
	g._aura_signature=""
	g._aura_present.clear()
	g.attack_flashes.clear()
	g.attack_vectors.clear()
	g.attack_durations.clear()
	var bonus: int = g._on_successful_fusion(result)
	g.recipe_last_signature = ""
	g._refresh()
	g._set_recipe_feedback("조합 성공! "+g.DOGS[result]+" · 필드에 배치"+(" · 미션 +%dG" % bonus if bonus>0 else ""),true)
	g.features.persist()
	return true
