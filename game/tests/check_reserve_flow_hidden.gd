extends SceneTree
const Game = preload("res://main.gd")
const Storage = preload("res://scripts/run_storage.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	Storage.clear_save()
	var g: Control = Game.new()
	g.persistence_enabled=false
	root.add_child(g)
	g.set_process(false)
	assert(g.features.start_panel.visible and not g.difficulty_panel.visible)
	g.features.new_game()
	assert(g.difficulty_panel.visible and not g.features.start_panel.visible)
	g._select_difficulty("어려움")
	assert(g.difficulty_confirmed and not g.difficulty_panel.visible)
	g.gold=1000
	for i in range(40): g._summon()
	assert(g.gold==200 and g.dogs.is_empty())
	var total: int = 0
	for count in g.reserve_units.values(): total+=int(count)
	assert(total==40)
	var kind: int = -1
	for key in g.reserve_units:
		if int(g.reserve_units[key])>=2: kind=int(key)
	assert(kind>=0)
	var before: int = int(g.reserve_units[kind])
	assert(not g.features.deploy(kind,-1))
	assert(g.features.deploy(kind,0))
	assert(int(g.reserve_units.get(kind,0))==before-1)
	assert(not g.features.deploy(kind,0))
	assert(g.dogs.size()==1)
	g.features.open_reserve()
	assert(g.paused and g.features.reserve_panel.visible)
	g.features.select_reserve(kind)
	assert(not g.features.reserve_panel.visible and not g.paused)
	var touch := InputEventScreenTouch.new()
	touch.pressed=true
	touch.position=g._cell_center(1)
	g._board_input(touch)
	assert(g.dogs.size()==2 and g.pending_deploy==-1)
	g.hidden_tickets=3
	for hidden in [49,50,51]: assert(g.features.choose_hidden(hidden))
	assert(g.hidden_tickets==0 and not g.features.choose_hidden(49))
	for hidden in [49,50,51]:
		assert(g.features.deploy(hidden,hidden-47))
	assert(g.sky_art.hidden_frames.size()==12)
	g.features.toast("팝업 검증")
	assert(g.features.toast_panel.visible)
	g.features.tick(3)
	assert(not g.features.toast_panel.visible)
	g.draw_counts={"맹수":199,"신화":99,"초월":100}
	g.pity_tickets={"맹수":1,"신화":2,"초월":3}
	assert(Storage.save(g))
	var restored: Control=Game.new()
	restored.persistence_enabled=false
	assert(Storage.restore(restored))
	assert(restored.reserve_units==g.reserve_units and restored.draw_counts==g.draw_counts and restored.pity_tickets==g.pity_tickets)
	assert(restored.dogs.size()==g.dogs.size())
	restored.free()
	g.visual_effects_enabled=false
	g.dogs.clear()
	g.enemies.clear()
	g.wave=1
	g.dogs.append({"kind":49,"cell":0,"cooldown":0.0,"hidden_charge":4})
	g.enemies.append({"hp":10000.0,"max_hp":10000.0,"armor":0.0,"magic_res":0.5,"progress":0.0,"effects":{}})
	var auras: Dictionary={"damage":0.0,"speed":0.0,"magic":0.0,"cooldown":0.0}
	g._attack_with_skills(0,0,auras)
	assert(is_equal_approx(float(g.enemies[0]["hp"]),9430.0)) # (300+840)*0.5, defenses apply
	assert(int(g.dogs[0]["hidden_charge"])==0)
	g.dogs[0]={"kind":50,"cell":0,"cooldown":0.0,"hidden_charge":3}
	g._attack_with_skills(0,0,auras)
	assert(g.hidden_zones.size()==1)
	var hp: float=float(g.enemies[0]["hp"])
	g.HiddenCombat.tick(g,3.0)
	assert(g.hidden_zones.is_empty() and float(g.enemies[0]["hp"])<hp)
	g.dogs[0]={"kind":51,"cell":0,"cooldown":0.0,"hidden_charge":5}
	g._attack_with_skills(0,0,auras)
	assert(float(g.dogs[0]["dream_time"])==4.0)
	g.HiddenCombat.tick(g,4.0)
	assert(float(g.dogs[0]["dream_time"])==0.0)
	g.game_over=true
	g._refresh()
	assert(g.features.result_panel.visible)
	g.features.new_game()
	assert(g.difficulty_panel.visible and not g.difficulty_confirmed)
	assert(g.reserve_units.is_empty() and g.pity_tickets.is_empty() and g.dogs.is_empty())
	g._select_difficulty("지옥")
	g.victory=true
	g._refresh()
	assert(g.features.result_panel.visible)
	g.features.new_game()
	assert(g.difficulty_panel.visible and not g.victory)
	g.queue_free()
	Storage.clear_save()
	await process_frame
	print("PASS: title, retry, reserve selection/touch, hidden choices/combat/defenses, popup expiry and save")
	quit()
