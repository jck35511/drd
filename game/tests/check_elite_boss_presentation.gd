extends SceneTree
const Game = preload("res://main.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var g: Control = Game.new()
	g.persistence_enabled = false
	root.add_child(g)
	g.set_process(false)
	g._select_difficulty("보통")
	var auras: Dictionary = {"damage":0.0,"magic":0.0,"speed":0.0,"cooldown":0.0}
	for kind in range(36,49):
		g.dogs = [{"kind":kind,"cell":0,"cooldown":0.0}]
		g.enemies = [{"progress":0.0,"hp":100000000.0,"max_hp":100000000.0,"armor":3.0,"magic_res":0.1,"effects":{}}]
		g.combat_fx.clear()
		g._attack_with_skills(0,0,auras)
		assert(g.attack_vectors.has(0),"Elite must have a directional attack motion")
		assert(g.combat_fx.size()>0 and g.combat_fx[0]["style"]==g.ELITE_STYLES[kind-36])
		assert(g.game_audio.sounds.has(g._attack_sound(kind)))
		assert(g.game_audio.sounds.has("skill_"+g.ELITE_STYLES[kind-36]))
		var proc_seen: bool = false
		g.rng.seed = 48000+kind
		for attempt in range(100):
			g._attack_with_skills(0,0,auras)
			for fx in g.combat_fx:
				if not str(fx.get("skill","")).is_empty(): proc_seen = true
		assert(proc_seen,"Every elite's real skill procs must produce feedback")
		assert(g.combat_fx.size()<=96,"Effects must stay within the mobile budget")
	# Visual/audio hooks must not consume combat RNG or alter outcomes.
	g.dogs = [{"kind":46,"cell":0,"cooldown":0.0}]
	var enemy: Dictionary = {"progress":0.0,"hp":100000.0,"max_hp":100000.0,"armor":3.0,"magic_res":0.1,"effects":{}}
	g.enemies = [enemy.duplicate(true)]
	g.rng.seed = 321
	g.visual_effects_enabled = true
	g._attack_with_skills(0,0,auras)
	var first: Dictionary = g.enemies[0].duplicate(true)
	var first_rng: int = g.rng.state
	g.enemies = [enemy.duplicate(true)]
	g.rng.seed = 321
	g.visual_effects_enabled = false
	g._attack_with_skills(0,0,auras)
	assert(g.enemies[0] == first and g.rng.state == first_rng)
	g.wave = 10
	g.boss_pending = true
	g._start_boss_round()
	g.selected = 0
	g.wave_time_left = 9.4
	g._refresh()
	assert(g.boss_hud.visible and g.boss_countdown.text.contains("9.4"),"Boss deadline must remain visible with a selected unit")
	assert(g.game_audio.boss_mode and g.game_audio.music.stream == g.game_audio.music_tracks["boss_theme"])
	assert(g.game_audio.music.stream.get_length()>20.0)
	g.paused = true
	g._refresh()
	assert(g.boss_countdown.text.contains("일시정지"))
	g.paused = false
	g._complete_boss_round(true)
	assert(not g.boss_hud.visible and not g.game_audio.boss_mode)
	assert(g.game_audio.music.stream == g.game_audio.music_tracks["sky_theme"])
	g.boss_pending = true
	g._start_boss_round()
	g.dogs.clear()
	g.wave_time_left = 0.01
	g._simulation_step(0.02)
	assert(g.game_over and not g.boss_hud.visible and not g.game_audio.boss_mode)
	g.queue_free()
	await process_frame
	quit()
