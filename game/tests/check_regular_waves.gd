extends SceneTree
const Game = preload("res://main.gd")
var errors: int = 0
func check(ok: bool, name: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + name)
	if not ok:
		errors += 1
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var g: Control = Game.new()
	check(Game.MAX_REGULAR_WAVE == 80, "80 regular waves")
	check(Game.REGULAR_WAVE_ENEMY_COUNT == 18, "18 monsters per wave")
	check(is_equal_approx(Game.REGULAR_WAVE_DURATION, 40.0), "40-second rounds")
	check(Game.REGULAR_ENEMY_TYPES.size() == 4, "four enemy categories")
	g._start_wave()
	check(g.wave == 0, "difficulty selection required")
	g.difficulty_confirmed = true
	g.rng.seed = 12345
	var categories: Dictionary = {}
	for w in range(1, 81):
		g._start_wave()
		check(g.wave == w and g.wave_running, "wave start %d" % w)
		check(g.spawn_left == 18 and is_equal_approx(g.wave_time_left, 40.0), "wave %d count and timer" % w)
		check(Game.REGULAR_ENEMY_TYPES.has(g.wave_enemy_type), "wave %d selected type" % w)
		categories[g.wave_enemy_type] = true
		var selected_type: String = g.wave_enemy_type
		var produced: int = 0
		for i in range(18):
			g.spawn_clock = 0.0
			g._simulation_step(0.001)
			produced += 1
			check(g.enemies[g.enemies.size()-1].get("enemy_type", "") == selected_type, "wave %d enemy type %d" % [w, i + 1])
		check(produced == 18 and g.spawn_left == 0 and g.enemies.size() == 18, "wave %d exactly 18 enemies" % w)
		# Simulate the defender killing the group before the time limit.
		g.enemies.clear()
		g._simulation_step(40.0)
		check(not g.wave_running and g.enemies.is_empty() and g.last_completed_wave == w, "wave %d finishes at time limit" % w)
		if w % 10 == 0:
			check(g.boss_pending, "boss scheduled after regular %d" % w)
			g._start_wave()
			check(g.boss_running and g.enemies.size() == 1, "boss round begins after %d" % w)
			g.enemies[0]["hp"] = 0.0
			g._clear_defeated()
			check(not g.boss_running, "boss cleared after %d" % w)
	check(categories.size() == 4, "all categories occurred across 80 seeded waves")
	g._start_wave()
	check(g.wave == 80 and not g.wave_running and g.victory, "wave 81 blocked after final boss")
	g._restart()
	check(g.wave == 0 and not g.difficulty_confirmed and g.last_completed_wave == 0, "restart resets waves")
	g.free()
	print("REGULAR WAVES TEST RESULT: %d failures" % errors)
	quit(1 if errors > 0 else 0)
