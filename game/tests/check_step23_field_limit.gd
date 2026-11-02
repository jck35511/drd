extends SceneTree
const Game = preload("res://main.gd")
var failures := 0
func verify(ok: bool, name: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + name)
    if not ok: failures += 1
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var g: Control = Game.new()
    g.difficulty_confirmed = true
    for name in ["쉬움", "보통", "어려움", "지옥"]:
        g.difficulty = name
        var limit: int = int(g.FIELD_LIMITS[name])
        verify(g._field_limit() == limit, "field limit " + name)
        g.enemies.clear()
        for i in range(limit - 1):
            g.enemies.append({"progress": 0.0, "hp": 1e7, "max_hp": 1e7, "move_speed": 0.0, "effects": {}})
        g.game_over = false
        g.wave = 0
        g.wave_running = false
        g._start_wave()
        g._simulation_step(0.01)
        verify(g.game_over and g.enemies.size() == limit, "loss upon reaching field limit " + name)
    g._restart()
    g.difficulty_confirmed = true
    g.enemies.append({"progress": 3.99, "hp": 1e8, "max_hp": 1e8, "move_speed": 0.2, "effects": {}})
    g.wave_running = true
    g.wave_time_left = 40.0
    g._simulation_step(1.0)
    verify(not g.game_over and g.enemies.size() == 1 and float(g.enemies[0]["progress"]) < 4.0, "normal enemy loops around route")
    g._restart()
    g.difficulty_confirmed = true
    g.wave = 10
    g.boss_pending = true
    g._start_wave()
    g.enemies[0]["progress"] = 3.99
    g._simulation_step(1.0)
    verify(not g.game_over and g.boss_running, "boss loop is not defeat")
    g._simulation_step(60.0)
    verify(g.game_over and not g.victory, "boss timeout is defeat")
    print("STEP23 FIELD LIMIT & BOSS TIMER TEST RESULT: %d failures" % failures)
    # Release the unparented game Control and its owned resources before SceneTree exits.
    g.free()
    quit(1 if failures else 0)
