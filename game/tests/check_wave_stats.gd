extends SceneTree
const Game = preload("res://main.gd")
var errors: int = 0

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		errors += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var g: Control = Game.new()
	var waves: Array[int] = [1, 10, 20, 40, 60, 80]
	var previous_hp: float = -1.0
	var previous_armor: float = -1.0
	var previous_res: float = -1.0
	for w in range(1, 81):
		var base: Dictionary = g._regular_wave_base_stats(w)
		if w > 1 and (float(base["hp"]) <= previous_hp or float(base["armor"]) <= previous_armor or float(base["magic_res"]) < previous_res):
			check(false, "monotonic stats at wave %d" % w)
		previous_hp = float(base["hp"])
		previous_armor = float(base["armor"])
		previous_res = float(base["magic_res"])
	check(is_equal_approx(float(g._regular_wave_base_stats(1)["hp"]), 100.0), "wave 1 starts at 100 HP")
	check(is_equal_approx(float(g._regular_wave_base_stats(80)["hp"]), 100.0 * pow(1.055, 79.0)), "wave 80 HP follows exponential curve")
	check(is_equal_approx(float(g._regular_wave_base_stats(80)["armor"]), 3.0 + 0.42 * 79.0 + 0.012 * 79.0 * 79.0), "wave 80 armor formula")
	check(is_equal_approx(float(g._regular_wave_base_stats(80)["magic_res"]), 0.25), "base magic resistance capped at 25 percent")
	check(is_equal_approx(float(g._regular_wave_base_stats(90)["hp"]), float(g._regular_wave_base_stats(80)["hp"])), "wave scaling safely capped at 80")
	var speeds: Array[float] = []
	for tier in ["쉬움", "보통", "어려움", "지옥"]:
		g.difficulty = tier
		for w in waves:
			var base: Dictionary = g._regular_wave_base_stats(w)
			var stats: Dictionary = g._regular_wave_stats(w)
			check(is_equal_approx(float(stats["hp"]), float(base["hp"]) * float(Game.DIFFICULTY_STATS[tier]["hp"])), "HP multiplier %s %d" % [tier, w])
			check(is_equal_approx(float(stats["armor"]), float(base["armor"]) * float(Game.DIFFICULTY_STATS[tier]["armor"])), "armor multiplier %s %d" % [tier, w])
			check(float(stats["magic_res"]) >= 0.0 and float(stats["magic_res"]) <= 0.5, "valid magic resist %s %d" % [tier, w])
			speeds.append(float(stats["move_speed"]))
	var speed_fixed: bool = true
	for speed in speeds:
		if not is_equal_approx(speed, Game.BASE_ENEMY_MOVE_SPEED):
			speed_fixed = false
	check(speed_fixed, "movement speed fixed across all difficulties and waves")
	g.difficulty = "보통"
	g.difficulty_confirmed = true
	g.wave_running = true
	g.wave = 80
	g.spawn_left = 1
	g.wave_time_left = Game.REGULAR_WAVE_DURATION
	g.wave_enemy_type = "소형견"
	g.spawn_clock = 0.0
	g._simulation_step(0.01)
	check(g.enemies.size() == 1, "live process spawns a wave-80 enemy")
	if g.enemies.size() == 1:
		var e: Dictionary = g.enemies[0]
		var expected: Dictionary = g._regular_wave_stats(80)
		check(is_equal_approx(float(e["max_hp"]), float(expected["hp"])), "live spawn receives scaled HP")
		check(is_equal_approx(float(e["armor"]), float(expected["armor"])), "live spawn receives scaled armor")
		check(is_equal_approx(float(e["magic_res"]), float(expected["magic_res"])), "live spawn receives scaled magic resistance")
		check(is_equal_approx(float(e["move_speed"]), Game.BASE_ENEMY_MOVE_SPEED), "live spawn receives fixed speed")
	g.enemies.clear()
	g.spawn_left = 0
	g.wave_running = false
	g.free()
	print("WAVE STATS TEST RESULT: %d failures" % errors)
	quit(1 if errors else 0)
