extends SceneTree
const Game = preload("res://main.gd")
var failed: int = 0
func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failed += 1
        push_error(label)
func _initialize() -> void:
    call_deferred("_test")
func _test() -> void:
    check(Game.DOGS.size() == 49, "49 units")
    var expected: Array[String] = ["빙결의 펜리르", "태양의 레오", "뇌신의 백호", "생명의 구미호"]
    var skills: Array = [["magic_splash", "slow", "freeze"], ["splash", "armor", "attack_aura"], ["chain", "stun", "magic_res"], ["burn", "speed_aura", "vulnerable"]]
    for i in range(4):
        var k: int = i + 42
        check(Game.DOGS[k] == expected[i] and Game.GRADES[k] == "신화" and Game.DOG_SKILLS[k] == skills[i], "mythic unit and 3 skills: " + expected[i])
        check(Game.ATTACK[k] > 0 and Game.COOLDOWN[k] > 0 and Game.RANGE[k] > 0, "mythic base stats: " + expected[i])
    check(Game.RECIPES.size() == 39, "32 originals plus 4 mythic and 3 transcendent recipes")
    var game: Control = Game.new()
    check(game._draw_reward_for_roll(0, 1).get("item", -1) == 36 and Game.DRAW_COST == 50, "Step8 draw unchanged")
    game.enemies.append({"progress": 0.0, "hp": 500.0, "max_hp": 500.0, "effects": {}})
    game._apply_status(0, "freeze", 0.75)
    check(game.enemies[0]["effects"].has("freeze"), "freeze status stored")
    game._tick_enemy_effects(0.8)
    check(not game.enemies[0]["effects"].has("freeze"), "freeze expires")
    game._apply_status(0, "burn", 2.0, 12.0)
    game._tick_enemy_effects(1.0)
    check(absf(float(game.enemies[0]["hp"]) - 488.0) < 0.01, "burn deals damage")
    game._apply_status(0, "vulnerable", 2.0, 0.20)
    game._hit_enemy(0, 10.0)
    check(absf(float(game.enemies[0]["hp"]) - 476.0) < 0.01, "received-damage debuff applies")
    game.dogs.append({"cell": 0, "kind": 43, "cooldown": 0.0})
    game.dogs.append({"cell": 1, "kind": 0, "cooldown": 0.0})
    var aura: Dictionary = game._effective_auras(1)
    check(absf(float(aura["damage"]) - Game.MYTHIC_POWER["aura"]) < 0.001, "Leo attack aura")
    game.dogs[0]["kind"] = 45
    aura = game._effective_auras(1)
    check(absf(float(aura["speed"]) - Game.MYTHIC_POWER["aura"]) < 0.001, "Nine-tail speed aura")
    game.dogs[0]["kind"] = 44
    game._attack_with_skills(0, 0, {"damage": 0.0, "speed": 0.0})
    check(float(game.enemies[0]["hp"]) < 476.0, "White Tiger combat hit")
    game.free()
    print("MYTHIC TEST RESULT: %d failures" % failed)
    quit(0 if failed == 0 else 1)
