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
	g.difficulty_confirmed = true
	check(Game.MAX_BOSS_ROUNDS == 8 and Game.BOSS_INTERVAL == 10, "8 bosses after every 10 regular waves")
	check(is_equal_approx(Game.BOSS_DURATION, 60.0), "boss lasts 60 seconds")
	for n in range(1, 9):
		g.wave = n * 10
		g.boss_pending = true
		g._start_wave()
		check(g.wave == n * 10 and g.boss_round == n and g.boss_running, "boss %d after 10 regular" % n)
		check(g.enemies.size() == 1 and g.enemies[0].get("is_boss", false), "boss %d spawns alone" % n)
		check(is_equal_approx(g.wave_time_left, 60.0), "boss %d timer" % n)
		check(float(g.enemies[0]["hp"]) > 0.0 and float(g.enemies[0]["armor"]) > 0.0, "boss %d stats" % n)
		g._start_wave()
		check(g.enemies.size() == 1, "boss %d cannot duplicate" % n)
		g.enemies[0]["hp"] = 0.0
		g._clear_defeated()
		check(not g.boss_running and not g.wave_running, "boss %d kill advances" % n)
	check(g.victory and not g.game_over, "final boss victory")
	g._start_wave()
	check(g.wave == 80 and g.enemies.is_empty(), "no wave after victory")
	g._restart()
	check(not g.victory and g.boss_round == 0 and not g.difficulty_confirmed, "restart resets bosses and difficulty")
	g.difficulty_confirmed = true
	g.wave = 10
	g.boss_pending = true
	g._start_wave()
	g._simulation_step(60.0)
	check(g.game_over and not g.boss_running and not g.victory, "boss timeout is defeat")
	g._restart()
	g.difficulty_confirmed = true
	g.wave = 10
	g.boss_pending = true
	g._start_wave()
	g.enemies[0]["progress"] = 4.0
	g._simulation_step(0.01)
	check(not g.game_over and g.boss_running and g.enemies.size() == 1, "boss circles instead of escaping")
	g.free()
	print("BOSS ROUND TEST RESULT: %d failures" % errors)
	quit(1 if errors > 0 else 0)
