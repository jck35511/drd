extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var script_ref = load("res://main.gd")
	if script_ref == null:
		push_error("FAIL: cannot load main.gd")
		quit(1)
		return
	var game: Control = script_ref.new()
	root.add_child(game)
	var failures: Array[String] = []
	if script_ref.COLS != 6 or script_ref.ROWS != 6:
		failures.append("board is not 6x6")
	if script_ref.DOGS.size() != 49 or script_ref.DOG_COLORS.size() != 49:
		failures.append("data is not 49 units")
	var expected: Dictionary = {"소형견": 10, "중형견": 13, "대형견": 13}
	for tier in expected.keys():
		if not script_ref.SKILL_CHANCE.has(tier) or not script_ref.SKILL_POWER.has(tier):
			failures.append("missing skill balance tier: " + str(tier))
	for kind in script_ref.DOG_SKILLS.keys():
		if int(kind) < 0 or int(kind) >= 49:
			failures.append("invalid skill unit index: " + str(kind))
		for skill in script_ref.DOG_SKILLS[kind]:
			if not script_ref.SKILL_NAMES.has(skill):
				failures.append("missing skill name: " + str(skill))
	if not failures.is_empty():
		for failure in failures:
			push_error("FAIL: " + failure)
		quit(1)
		return
	game.enemies.clear()
	game.enemies.append({"progress": 0.0, "hp": 100.0, "max_hp": 100.0, "effects": {}})
	game._apply_status(0, "stun", 0.6)
	game._apply_status(0, "slow", 2.0, 0.4)
	game._apply_status(0, "armor", 3.0, 0.16)
	game._apply_status(0, "bleed", 2.0, 4.0)
	game._hit_enemy(0, 10.0)
	if absf(float(game.enemies[0]["hp"]) - 90.0) > 0.01:
		failures.append("armor damage calculation")
	game._tick_enemy_effects(1.0)
	if absf(float(game.enemies[0]["hp"]) - 86.0) > 0.01:
		failures.append("bleed damage per second")
	if game.enemies[0]["effects"].has("stun"):
		failures.append("stun timer did not expire")
	game._apply_status(0, "slow", 2.0, 0.2)
	if absf(float(game.enemies[0]["effects"]["slow"]["power"]) - 0.4) > 0.01:
		failures.append("weak slow overwrote stronger slow")
	game._tick_enemy_effects(3.0)
	if not game.enemies[0]["effects"].is_empty():
		failures.append("effects did not expire")
	game.enemies[0]["hp"] = -1.0
	var before_gold: int = game.gold
	game._clear_defeated()
	if game.gold != before_gold + script_ref.KILL_REWARD or not game.enemies.is_empty():
		failures.append("kill reward or enemy cleanup")
	if failures.is_empty():
		print("PASS: skill data, armor, bleed, status expiry, capped slow, kill rewards")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: " + failure)
		quit(1)
