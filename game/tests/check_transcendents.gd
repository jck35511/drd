extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func verify(ok: bool, description: String) -> void:
	if ok:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
func _initialize() -> void:
	call_deferred("_run_checks")
func _run_checks() -> void:
	var names := ["심연의 아몬", "천공의 라", "명계의 케르베로스"]
	var skills := [["heavy", "armor", "poison", "hp_percent"], ["magic_splash", "burn", "magic_res", "magic_aura"], ["area_stun", "slow", "speed_aura", "cooldown_aura"]]
	verify(Game.DOGS.size() == 49 and Game.GRADES.size() == 49 and Game.DOG_COLORS.size() == 49, "49 units and aligned arrays")
	for i in range(3):
		var k: int = i + 46
		verify(Game.DOGS[k] == names[i] and Game.GRADES[k] == "초월" and Game.DOG_SKILLS[k] == skills[i], "transcendent name, grade and four effects: " + names[i])
		verify(Game.ATTACK[k] > 0 and Game.COOLDOWN[k] > 0 and Game.RANGE[k] > 0, "positive base stats: " + names[i])
	verify(Game.RECIPES.size() == 39, "Step11 recipes preserved; three new transcendents")
	verify(Game.MYTHIC_DRAW_ITEM_IDS.size() == 4 and Game.DRAW_ITEM_IDS.size() == 6, "Step11 gacha unchanged")
	var game = Game.new()
	get_root().add_child(game)
	game.wave_running = false
	game.enemies.append({"progress": 0.5, "hp": 10000.0, "max_hp": 10000.0, "effects": {}})
	game._apply_status(0, "poison", 2.0, 25.0)
	game._tick_enemy_effects(1.0)
	verify(absf(float(game.enemies[0]["hp"]) - 9975.0) < 0.01, "poison deals damage")
	game._tick_enemy_effects(2.0)
	verify(not game.enemies[0]["effects"].has("poison"), "poison expires")
	game.dogs.append({"kind": 47, "cell": 0, "cooldown": 0.0})
	game.dogs.append({"kind": 44, "cell": 1, "cooldown": 0.0})
	var buffs: Dictionary = game._effective_auras(1)
	verify(absf(float(buffs["magic"]) - float(Game.TRANSCENDENT_POWER["aura"])) < 0.001, "Ra magic aura")
	game.dogs[0]["kind"] = 48
	buffs = game._effective_auras(1)
	verify(float(buffs["speed"]) > 0.0 and float(buffs["cooldown"]) > 0.0, "Cerberus two independent auras")
	game.dogs[0]["kind"] = 46
	var hp: float = float(game.enemies[0]["hp"])
	game.rng.seed = 789
	game._attack_with_skills(0, 0, game._effective_auras(0))
	verify(float(game.enemies[0]["hp"]) < hp, "Amon combat hit")
	game.queue_free()
	print("TRANSCENDENT TEST RESULT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
