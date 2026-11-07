extends SceneTree
const Game=preload("res://main.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Game.RunStorage.clear_save()
	var g: Control=Game.new()
	g.persistence_enabled=false
	root.add_child(g)
	g.set_process(false)
	g.features.new_game()
	assert(not g.features.sell_reserve(0))
	g._select_difficulty("보통")
	g.gold=0
	g.reserve_units={0:2,3:1,6:1,36:1,42:1,46:1,49:1}
	g.dogs.assign([{"kind":0,"cell":0,"cooldown":0.5}])
	g.features.open_reserve()
	var row: Node=g.features.reserve_list.get_child(0)
	assert(row.get_child(1) is Button and row.get_child(2) is Button)
	row.get_child(2).pressed.emit()
	assert(g.gold==10 and int(g.reserve_units[0])==1 and g.dogs.size()==1)
	g.pending_deploy=0
	assert(g.features.sell_reserve(0))
	assert(g.gold==20 and not g.reserve_units.has(0) and g.pending_deploy==-1)
	assert(not g.features.sell_reserve(0) and g.gold==20)
	assert(g.features.sell_reserve(3) and g.gold==60)
	assert(g.features.sell_reserve(6) and g.gold==160)
	for kind in [36,42,46,49]:
		assert(not g.features.sell_reserve(kind))
		assert(int(g.reserve_units[kind])==1 and g.gold==160)
	assert(not g.features.sell_reserve(-1) and not g.features.sell_reserve(999))
	# A stored individual is removed once; stale state cannot survive a sale.
	g.reserve_units.clear()
	g.reserve_states.clear()
	assert(g.features.stash(0))
	assert(g.reserve_states.has(0))
	assert(g.features.sell_reserve(0))
	assert(g.reserve_units.is_empty() and g.reserve_states.is_empty() and g.gold==170)
	g.reserve_units={0:1}
	g.victory=true
	assert(not g.features.sell_reserve(0))
	g.victory=false
	g.game_over=true
	assert(not g.features.sell_reserve(0))
	g.game_over=false
	g.features.close_reserve()
	g.persistence_enabled=true
	assert(g.features.sell_reserve(0))
	var restored: Control=Game.new()
	restored.persistence_enabled=false
	assert(g.RunStorage.restore(restored))
	assert(restored.gold==180 and restored.reserve_units.is_empty())
	restored.free()
	g.RunStorage.clear_save()
	g.queue_free()
	await process_frame
	print("PASS: reserve sale button, exact one-copy removal, existing prices, protected grades, saved balance and stale clicks")
	quit()
