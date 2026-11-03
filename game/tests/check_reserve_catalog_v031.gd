extends SceneTree
const Game=preload("res://main.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var g: Control=Game.new()
	g.persistence_enabled=false
	root.add_child(g)
	g.set_process(false)
	g.features.new_game()
	g._select_difficulty("보통")
	# Every kind can move field -> reserve -> field, preserving cooldown/charge.
	for kind in range(g.DOGS.size()):
		g.dogs.assign([{"kind":kind,"cell":0,"cooldown":0.75,"hidden_charge":3}])
		assert(g.features.stash(0))
		assert(g.dogs.is_empty() and int(g.reserve_units[kind])==1)
		assert(g.features.deploy(kind,1))
		assert(g.reserve_units.is_empty() and g.reserve_states.is_empty())
		assert(is_equal_approx(float(g.dogs[0]["cooldown"]),0.75))
		assert(int(g.dogs[0]["hidden_charge"])==3)
	g.dogs.clear()
	# All 39 recipes from reserve only: correct multiplicities, items and result location.
	for recipe in g.RECIPES:
		g.dogs.clear()
		g.reserve_units.clear()
		g.reserve_states.clear()
		g.beast_items.clear()
		var result: int=int(recipe["result"])
		for kind in recipe["materials"]: g.Inventory.add(g,int(kind))
		if recipe.has("item"):
			var unchanged: Dictionary=g.reserve_units.duplicate(true)
			g._craft_recipe_from_catalog(result)
			assert(g.reserve_units==unchanged)
			g.beast_items[int(recipe["item"])]=1
		g._craft_recipe_from_catalog(result)
		assert(g.dogs.size()==1 and int(g.dogs[0]["kind"])==result)
		assert(g.reserve_units.is_empty())
		if recipe.has("item"): assert(int(g.beast_items[int(recipe["item"])])==0)
		var once: Dictionary=g.reserve_units.duplicate(true)
		var once_field: Array=g.dogs.duplicate(true)
		g._craft_recipe_from_catalog(result)
		assert(g.reserve_units==once and g.dogs==once_field,"Repeated tap cannot duplicate a result")
	# Mixed location and selected-unit fusion.
	g.reserve_units.clear()
	g.dogs.assign([{"kind":0,"cell":9,"cooldown":0.0}])
	g.selected=0
	g.Inventory.add(g,0)
	g.Inventory.add(g,1)
	g._craft_recipe_from_catalog(4)
	assert(g.dogs.size()==1 and int(g.dogs[0]["kind"])==4 and int(g.dogs[0]["cell"])==9)
	assert(g.reserve_units.is_empty())
	g.dogs.assign([{"kind":0,"cell":9,"cooldown":0.0}])
	g.selected=0
	g.Inventory.add(g,0)
	g.Inventory.add(g,1)
	g._fuse_selected()
	assert(g.dogs.size()==1 and int(g.dogs[0]["kind"])==4)
	# A full field rejects a reserve-only craft without consuming resources.
	g.dogs.clear()
	for cell in range(36): g.dogs.append({"kind":49,"cell":cell,"cooldown":0.2})
	g.reserve_units={0:2,1:1}
	g._craft_recipe_from_catalog(4)
	assert(g.dogs.size()==36 and g.reserve_units=={0:2,1:1})
	g.dogs.remove_at(12)
	g._craft_recipe_from_catalog(4)
	assert(g.dogs.size()==36 and int(g.dogs.back()["kind"])==4 and int(g.dogs.back()["cell"])==12)
	assert(g.reserve_units.is_empty())
	# Missing duplicate preserves the entire inventory and selected field unit.
	g.dogs.clear()
	g.reserve_units={0:1,1:1}
	var before: Dictionary=g.reserve_units.duplicate()
	g._craft_recipe_from_catalog(4)
	assert(g.reserve_units==before)
	# Grade order, count, hidden cards and absence of All filter.
	var tabs: Node=g.recipe_panel.get_child(0).get_node("RecipeFilterGrid")
	assert(tabs.get_child_count()==7)
	for i in range(7): assert(tabs.get_child(i).text.begins_with(g.features.GRADES[i]))
	g._set_recipe_filter("소형견")
	assert(g.recipe_list.get_child_count()==10)
	g._set_recipe_filter("히든")
	assert(g.recipe_list.get_child_count()==3)
	assert(g.recipe_list.get_child(0).name=="Unit_49")
	g.features.open_reserve()
	for grade in g.features.GRADES: g.features.set_reserve_filter(grade)
	g.features.close_reserve()
	# Save/load held combat state, old saves without it remain valid.
	g.dogs.assign([{"kind":51,"cell":8,"cooldown":0.45,"hidden_charge":5}])
	assert(g.features.stash(0))
	g.bosses_defeated=3
	assert(g.RunStorage.save(g))
	var restored: Control=Game.new()
	restored.persistence_enabled=false
	assert(g.RunStorage.restore(restored))
	assert(restored.bosses_defeated==3)
	assert(restored.features.deploy(51,2))
	assert(int(restored.dogs[0]["hidden_charge"])==5)
	assert(is_equal_approx(float(restored.dogs[0]["cooldown"]),0.45))
	restored.free()
	g.RunStorage.clear_save()
	g.queue_free()
	await process_frame
	print("PASS: all grades storage, state preservation, 39 reserve recipes, mixed fusion, duplicate shortages, full field, grade catalog and save")
	quit()
