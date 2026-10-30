extends SceneTree
const Game = preload("res://main.gd")
var failed: int = 0

func _check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failed += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var names: Array[String] = ["사자", "호랑이", "늑대", "재규어", "표범", "여우"]
	var skills: Array = [["splash", "armor"], ["heavy", "bleed"], ["multi", "speed_aura"], ["area_stun", "hp_percent"], ["crit", "slow"], ["magic_splash", "magic_res"]]
	_check(Game.DOGS.size() == 49, "49 units including 6 beasts")
	for i in range(6):
		var k: int = i + 36
		_check(Game.DOGS[k] == names[i] and Game.GRADES[k] == "맹수" and Game.DOG_SKILLS[k] == skills[i], "beast %s name, grade and two skills" % names[i])
		_check(Game.ATTACK[k] > 0.0 and Game.RANGE[k] > 0.0 and Game.COOLDOWN[k] > 0.0, "beast %s basic stats" % names[i])
	var game: Control = Game.new()
	game.enemies.append({"progress": 0.0, "hp": 1000.0, "max_hp": 1000.0, "effects": {}})
	game.dogs.append({"cell": 0, "kind": 36, "cooldown": 0.0})
	game.rng.seed = 42
	game._attack_with_skills(0, 0, {"damage": 0.0, "speed": 0.0})
	_check(float(game.enemies[0]["hp"]) < 1000.0, "lion combat damage executes")
	game._apply_status(0, "magic_res", 3.0, 0.20)
	var before: float = float(game.enemies[0]["hp"])
	game._hit_enemy(0, 100.0, true)
	_check(is_equal_approx(before - float(game.enemies[0]["hp"]), 120.0), "magic vulnerability affects magic damage")
	game._tick_enemy_effects(3.1)
	_check(not game.enemies[0]["effects"].has("magic_res"), "magic vulnerability expires")
	game.dogs[0]["kind"] = 38
	var aura: Dictionary = game._effective_auras(0)
	_check(float(aura["speed"]) >= float(Game.BEAST_POWER["aura"]), "wolf speed aura")
	game.free()
	print("BEAST TEST RESULT: %d failures" % failed)
	quit(0 if failed == 0 else 1)
