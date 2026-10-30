extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0

func verify(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("_run")

func _new_enemy(category: String, boss: bool = false) -> Dictionary:
	return {"hp": 10000.0, "max_hp": 10000.0, "armor": 0.0, "magic_res": 0.0, "enemy_type": category, "is_boss": boss, "progress": 0.0, "effects": {}}

func _run() -> void:
	var g: Control = Game.new()
	verify(is_equal_approx(Game.MATCHUP_BONUS, 1.2), "advantage is 120%")
	verify(is_equal_approx(Game.MATCHUP_PENALTY, 0.9), "disadvantage is 90%")
	var units := {"소형견": 0, "중형견": 3, "대형견": 6, "맹수": 36, "신화": 42, "초월": 46}
	var cases := {
		"소형견": {"소형견": 1.0, "중형견": 0.9, "대형견": 1.2, "맹수": 1.0},
		"중형견": {"소형견": 1.2, "중형견": 1.0, "대형견": 0.9, "맹수": 1.0},
		"대형견": {"소형견": 0.9, "중형견": 1.2, "대형견": 1.0, "맹수": 1.0}
	}
	for tier in cases.keys():
		for enemy_type in cases[tier].keys():
			g.enemies.clear()
			g.enemies.append(_new_enemy(enemy_type))
			var expected: float = cases[tier][enemy_type]
			verify(is_equal_approx(g._matchup_multiplier(units[tier], 0), expected), "matchup %s vs %s" % [tier, enemy_type])
			g._hit_basic_dog_enemy(units[tier], 0, 100.0)
			verify(is_equal_approx(float(g.enemies[0]["hp"]), 10000.0 - 100.0 * expected), "real physical damage %s vs %s" % [tier, enemy_type])
	for tier in ["맹수", "신화", "초월"]:
		for enemy_type in ["소형견", "중형견", "대형견", "맹수"]:
			g.enemies.clear()
			g.enemies.append(_new_enemy(enemy_type))
			verify(is_equal_approx(g._matchup_multiplier(units[tier], 0), 1.0), "%s unaffected vs %s" % [tier, enemy_type])
	for tier in ["소형견", "중형견", "대형견"]:
		g.enemies.clear()
		g.enemies.append(_new_enemy("보스", true))
		verify(is_equal_approx(g._matchup_multiplier(units[tier], 0), 1.0), "boss is neutral vs %s" % tier)
	g.enemies.clear()
	g.enemies.append(_new_enemy("대형견"))
	g.enemies.append(_new_enemy("중형견"))
	g._hit_basic_dog_enemy(0, 0, 100.0)
	g._hit_basic_dog_enemy(0, 1, 100.0)
	verify(is_equal_approx(float(g.enemies[0]["hp"]), 9880.0), "AoE target A uses own favorable matchup")
	verify(is_equal_approx(float(g.enemies[1]["hp"]), 9910.0), "AoE target B uses own unfavorable matchup")
	verify(is_equal_approx(g._matchup_multiplier(-1, 0), 1.0), "invalid attacker safely neutral")
	verify(is_equal_approx(g._matchup_multiplier(0, 999), 1.0), "invalid target safely neutral")
	g.free()
	print("MATCHUP TEST RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
