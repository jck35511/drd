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
    check(Game.DIFFICULTY_STATS.size() == 4, "four difficulty levels")
    check(not g.difficulty_confirmed, "difficulty must be selected at startup")
    g._start_wave()
    check(g.wave == 0, "wave blocked until difficulty chosen")
    var base: float = 100.0
    var values: Array[float] = []
    for tier in ["쉬움", "보통", "어려움", "지옥"]:
        g.difficulty = tier
        var stats: Dictionary = g._enemy_stats_for_difficulty(base, 10.0)
        values.append(float(stats["hp"]))
        check(is_equal_approx(float(stats["hp"]), base * float(Game.DIFFICULTY_STATS[tier]["hp"])), "HP multiplier: " + tier)
        check(is_equal_approx(float(stats["armor"]), 10.0 * float(Game.DIFFICULTY_STATS[tier]["armor"])), "armor multiplier: " + tier)
        check(is_equal_approx(float(stats["move_speed"]), Game.BASE_ENEMY_MOVE_SPEED), "unchanged movement: " + tier)
    check(values[0] < values[1] and values[1] < values[2] and values[2] < values[3], "difficulty HP rises")
    g._select_difficulty("지옥")
    check(g.difficulty_confirmed and g.difficulty == "지옥", "difficulty confirmation")
    g._select_difficulty("쉬움")
    check(g.difficulty == "지옥", "difficulty locked until restart")
    g._start_wave()
    check(g.wave == 1, "wave starts after selection")
    g.enemies.clear()
    g.enemies.append({"hp": 100.0, "max_hp": 100.0, "armor": 100.0, "effects": {}})
    g._hit_enemy(0, 100.0)
    check(is_equal_approx(float(g.enemies[0]["hp"]), 50.0), "armor affects physical damage")
    g._restart()
    check(not g.difficulty_confirmed and g.difficulty == "보통" and g.wave == 0, "restart reopens difficulty")
    g.free()
    print("DIFFICULTY TEST RESULT: %d failures" % errors)
    quit(1 if errors else 0)
