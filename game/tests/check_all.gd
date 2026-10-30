extends SceneTree
# All checks must execute inside Godot 4.7.2. Run with --headless --script.
const Game = preload("res://main.gd")
var failures: Array[String] = []
var checks: int = 0

func _check(ok: bool, label: String) -> void:
    checks += 1
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)

func _new_game() -> Control:
    return Game.new()

func _fill(game: Control, materials: Array) -> void:
    for i in range(materials.size()):
        game.dogs.append({"cell": i, "kind": int(materials[i]), "cooldown": 0.0})

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Game.COLS == 6 and Game.ROWS == 6, "board 6x6")
    _check(Game.COST == 20 and Game.KILL_REWARD == 5, "summon and kill economy")
    var data: Array = [Game.DOGS, Game.GRADES, Game.ATTACK, Game.RANGE, Game.COOLDOWN, Game.DOG_COLORS]
    var names: Array[String] = ["DOGS", "GRADES", "ATTACK", "RANGE", "COOLDOWN", "DOG_COLORS"]
    for i in range(data.size()):
        _check(data[i].size() == 49, "49 entries: " + names[i])
    if Game.GRADES.size() != 49 or Game.DOGS.size() != 49:
        _finish()
        return
    var small: Array[int] = []
    var middle: Array[int] = []
    var large: Array[int] = []
    for i in range(36):
        match Game.GRADES[i]:
            "소형견": small.append(i)
            "중형견": middle.append(i)
            "대형견": large.append(i)
    _check(small.size() == 10 and middle.size() == 13 and large.size() == 13, "grade counts 10/13/13")
    _check(Game.RECIPES.size() == 39, "39 crafting recipes")
    var found: Dictionary = {}
    var signatures: Dictionary = {}
    var valid: bool = true
    for recipe in Game.RECIPES:
        var result: int = int(recipe.get("result", -1))
        var ingredients: Array = recipe.get("materials", [])
        if result < 0 or result >= 49 or ingredients.size() != 3 or found.has(result):
            valid = false
            continue
        found[result] = true
        var expected: String = "대형견"
        if Game.GRADES[result] == "중형견":
            expected = "소형견"
        elif Game.GRADES[result] == "대형견":
            expected = "중형견"
        if Game.GRADES[result] == "신화":
            expected = "맹수"
        if Game.GRADES[result] not in ["중형견", "대형견", "맹수", "신화", "초월"]:
            valid = false
        var signature_array: Array[int] = []
        for raw in ingredients:
            var m: int = int(raw)
            if m < 0 or m >= 49:
                valid = false
                continue
            signature_array.append(m)
            if m == result or (Game.GRADES[m] != expected and Game.GRADES[result] != "초월"):
                valid = false
        if Game.GRADES[result] == "초월":
            var grades: Array = []
            for m in ingredients:
                grades.append(Game.GRADES[int(m)])
            grades.sort()
            if grades != ["맹수", "신화", "신화"] or int(recipe.get("item", -1)) != result:
                valid = false
        signature_array.sort()
        var signature: String = str(signature_array)
        if signatures.has(signature):
            valid = false
        signatures[signature] = true
    _check(valid and found.size() == 39, "unique, valid, correct-tier recipes")
    var all_reachable: bool = true
    for idx in middle + large + [36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48]:
        if not found.has(idx):
            all_reachable = false
    _check(all_reachable, "all 39 results reachable from smaller tiers")
    var game: Control = _new_game()
    var recipe: Dictionary = Game.RECIPES[0]
    var materials: Array = recipe["materials"]
    _fill(game, materials)
    var expected_cell: int = int(game.dogs[0]["cell"])
    game.selected = 0
    game._fuse_selected()
    _check(game.dogs.size() == 1 and int(game.dogs[0]["kind"]) == int(recipe["result"]) and int(game.dogs[0]["cell"]) == expected_cell, "selected fusion consumes 3 creates 1")
    game.free()
    game = _new_game()
    _fill(game, [materials[0], materials[1]])
    var before: Array = game.dogs.duplicate(true)
    game.selected = 0
    game._fuse_selected()
    _check(game.dogs == before, "missing materials cannot mutate selected fusion")
    game._craft_recipe_from_catalog(int(recipe["result"]))
    _check(game.dogs == before, "missing materials cannot mutate catalog crafting")
    game.free()
    game = _new_game()
    _fill(game, materials)
    game._craft_recipe_from_catalog(int(recipe["result"]))
    _check(game.dogs.size() == 1 and int(game.dogs[0]["kind"]) == int(recipe["result"]) and game.selected == 0, "catalog crafting 3-to-1")
    game.free()
    var duplicate_recipe: Dictionary = {}
    for item in Game.RECIPES:
        var m: Array = item["materials"]
        if m[0] == m[1] or m[1] == m[2] or m[0] == m[2]:
            duplicate_recipe = item
            break
    _check(not duplicate_recipe.is_empty(), "duplicate-material recipe exists")
    if not duplicate_recipe.is_empty():
        game = _new_game()
        _fill(game, duplicate_recipe["materials"].slice(0, 2))
        before = game.dogs.duplicate(true)
        game._craft_recipe_from_catalog(int(duplicate_recipe["result"]))
        _check(game.dogs == before, "duplicate material requires separate instances")
        game.free()
    game = _new_game()
    game.rng.seed = 12345
    var summon_ok: bool = true
    for i in range(5):
        var previous_gold: int = game.gold
        game._summon()
        if game.dogs.size() != i + 1 or game.gold != previous_gold - 20 or Game.GRADES[int(game.dogs[-1]["kind"])] != "소형견":
            summon_ok = false
    _check(summon_ok, "summon only small dogs; 20G deducted on success")
    var no_gold_dogs: Array = game.dogs.duplicate(true)
    game._summon()
    _check(game.gold == 0 and game.dogs == no_gold_dogs, "insufficient gold leaves inventory unchanged")
    game.free()
    game = _new_game()
    for i in range(36):
        game.dogs.append({"cell": i, "kind": small[0], "cooldown": 0.0})
    var old_gold: int = game.gold
    game._summon()
    _check(game.gold == old_gold and game.dogs.size() == 36, "full board: no gold charge or extra unit")
    game.free()
    _check(Game.DOG_SKILLS.size() == 35, "22 dog, 6 beast, 4 mythic and 3 transcendent skill sets preserved")
    for tier in ["소형견", "중형견", "대형견"]:
        _check(Game.SKILL_CHANCE.has(tier) and Game.SKILL_POWER.has(tier), "skill balance tier: " + tier)
    game = _new_game()
    game.enemies.append({"progress": 0.0, "hp": 100.0, "max_hp": 100.0, "effects": {}})
    game._apply_status(0, "armor", 3.0, 0.16)
    game._hit_enemy(0, 10.0)
    _check(absf(float(game.enemies[0]["hp"]) - 90.0) < 0.01, "armor reduction has no extra damage bonus against zero armor")
    game._apply_status(0, "bleed", 2.0, 4.0)
    game._tick_enemy_effects(1.0)
    _check(absf(float(game.enemies[0]["hp"]) - 86.0) < 0.01, "bleed damage tick")
    game._apply_status(0, "stun", 0.4)
    game._tick_enemy_effects(0.5)
    _check(not game.enemies[0]["effects"].has("stun"), "stun expires")
    var gold_before: int = game.gold
    game.enemies[0]["hp"] = 0.0
    game._clear_defeated()
    _check(game.enemies.is_empty() and game.gold == gold_before + Game.KILL_REWARD, "defeat cleanup awards 5G")
    game.free()
    # UI: instantiate scene script and check that the recipe catalog exists.
    game = _new_game()
    root.add_child(game)
    _check(game.board != null and game.recipe_panel != null and game.recipe_list != null, "UI and catalog initialize")
    _check(game.recipe_button != null and game.fusion_button != null, "fusion and catalog buttons initialize")
    game.recipe_panel.visible = true
    game._refresh_recipes()
    _check(game.recipe_list.get_child_count() == 39, "catalog renders 39 recipes")
    game._set_recipe_filter("중형견")
    _check(game.recipe_list.get_child_count() == 13, "medium filter renders 13")
    game._set_recipe_filter("대형견")
    _check(game.recipe_list.get_child_count() == 13, "large filter renders 13")
    game._set_recipe_filter("맹수")
    _check(game.recipe_list.get_child_count() == 6, "beast filter renders 6")
    game._set_recipe_filter("신화")
    _check(game.recipe_list.get_child_count() == 4, "mythic filter renders 4")
    root.remove_child(game)
    game.free()
    _finish()

func _finish() -> void:
    print("RESULT: %d checks, %d failures" % [checks, failures.size()])
    for failure in failures:
        push_error("FAIL: " + failure)
    quit(0 if failures.is_empty() else 1)
