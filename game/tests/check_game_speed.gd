extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0

func verify(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var g: Control = Game.new()
	verify(g.game_speed == 1 and Game.GAME_SPEEDS == [1, 2, 3], "default 1x and supported 1x/2x/3x")
	g._cycle_game_speed()
	verify(g.game_speed == 1, "speed cannot change before difficulty selection")
	g.difficulty_confirmed = true
	for speed in [2, 3, 1]:
		g._cycle_game_speed()
		verify(g.game_speed == speed, "speed button cycle %dx" % speed)
	verify(is_equal_approx(Engine.time_scale, 1.0), "global Engine.time_scale unchanged")
	# Independent test cases keep enemies absent so damage cannot end the wave.
	for speed in [1, 2, 3]:
		g.game_speed = speed
		g.wave_running = true
		g.game_over = false
		g.boss_running = false
		g.wave = 1
		g.wave_time_left = 40.0
		g.spawn_left = 0
		g.spawn_clock = 0.0
		g.enemies.clear()
		g.dogs.clear()
		g._process(1.0)
		verify(is_equal_approx(g.wave_time_left, 40.0 - float(speed)), "regular timer at %dx" % speed)
		# Enemy movement and status time use the same scaled delta.
		g.enemies.clear()
		g.enemies.append({"progress": 0.0, "hp": 100.0, "max_hp": 100.0, "move_speed": 0.2, "effects": {"slow": {"time": 10.0, "power": 0.0}}})
		g._process(0.5)
		verify(is_equal_approx(float(g.enemies[0]["progress"]), 0.1 * float(speed)), "enemy movement at %dx" % speed)
		verify(is_equal_approx(float(g.enemies[0]["effects"]["slow"]["time"]), 10.0 - 0.5 * float(speed)), "effect expiry at %dx" % speed)
	# Boss clock also follows speed; no change to nominal boss duration.
	g.enemies.clear()
	g.dogs.clear()
	g.game_speed = 3
	g.wave_running = true
	g.boss_running = true
	g.wave_time_left = 60.0
	g._process(1.0)
	verify(is_equal_approx(g.wave_time_left, 57.0), "boss 60s clock at 3x")
	g._restart()
	verify(g.game_speed == 1, "restart resets speed to 1x")
	verify(is_equal_approx(Engine.time_scale, 1.0), "restart does not affect global time")
	g.free()
	print("SPEED TEST RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
