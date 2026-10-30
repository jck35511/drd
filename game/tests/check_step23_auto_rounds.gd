extends SceneTree
const Game = preload("res://main.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if not ok: failures += 1
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var g: Control = Game.new()
    g.difficulty_confirmed = true
    g.wave = 1
    g.wave_running = true
    g.wave_time_left = 0.0
    g._complete_regular_wave()
    check(not g.wave_running and g.auto_advance_pending, "regular round queues next round")
    g._simulation_step(0.0)
    check(g.wave_running and g.wave == 2, "next regular round begins automatically")
    g.wave = 10
    g.wave_running = true
    g.wave_time_left = 0.0
    g._complete_regular_wave()
    check(g.boss_pending and g.auto_advance_pending, "round ten queues boss")
    g._simulation_step(0.0)
    check(g.boss_running and g.boss_round == 1, "boss starts automatically")
    g._complete_boss_round(true)
    check(g.auto_advance_pending and not g.game_over, "cleared boss queues next regular wave")
    g._simulation_step(0.0)
    check(g.wave == 11 and g.wave_running and not g.boss_running, "regular round eleven starts automatically")
    g._restart()
    check(not g.auto_advance_pending and not g.wave_running, "restart clears automatic advance")
    g.difficulty_confirmed = true
    g.wave = 1
    g.wave_running = true
    g._complete_regular_wave()
    g.game_over = true
    g._simulation_step(0.1)
    check(not g.wave_running, "defeat blocks automatic advance")
    print("STEP23 AUTO ROUNDS TEST RESULT: %d failures" % failures)
    # Release the unparented game Control and its owned resources before SceneTree exits.
    g.free()
    quit(1 if failures else 0)
