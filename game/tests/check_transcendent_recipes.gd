extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func ck(ok: bool, name: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + name)
    if not ok:
        failures += 1
func _initialize() -> void:
    call_deferred("go")
func go() -> void:
    var recipes: Array = []
    for r in Game.RECIPES:
        if Game.GRADES[int(r["result"])] == "초월":
            recipes.append(r)
    ck(Game.RECIPES.size() == 39 and recipes.size() == 3, "39 recipes, 3 transcendent")
    var signature_keys: Dictionary = {}
    for recipe in recipes:
        var result: int = int(recipe["result"])
        var mats: Array = recipe["materials"]
        var grades: Array = []
        for m in mats:
            grades.append(Game.GRADES[int(m)])
        grades.sort()
        var signature: Array = mats.duplicate()
        signature.sort()
        ck(mats.size() == 3 and grades == ["맹수", "신화", "신화"] and not signature_keys.has(str(signature)), "two mythics and one beast: " + Game.DOGS[result])
        signature_keys[str(signature)] = true
        ck(int(recipe.get("item", -1)) == result and Game.BEAST_ITEMS.has(result), "dedicated transcendent item: " + Game.DOGS[result])
        var game: Control = Game.new()
        for i in range(mats.size()):
            game.dogs.append({"cell": i, "kind": int(mats[i]), "cooldown": 0.0})
        var before: Array = game.dogs.duplicate(true)
        game._craft_recipe_from_catalog(result)
        ck(game.dogs == before, "missing item preserves materials: " + Game.DOGS[result])
        game.beast_items[result] = 1
        game.dogs.remove_at(2)
        before = game.dogs.duplicate(true)
        game._craft_recipe_from_catalog(result)
        ck(game.dogs == before and int(game.beast_items[result]) == 1, "missing beast/material does not consume item: " + Game.DOGS[result])
        game.dogs.append({"cell": 2, "kind": int(mats[2]), "cooldown": 0.0})
        game._craft_recipe_from_catalog(result)
        ck(game.dogs.size() == 1 and int(game.dogs[0]["kind"]) == result and int(game.beast_items[result]) == 0, "successful 3+item to 1: " + Game.DOGS[result])
        game.free()
    var ui: Control = Game.new()
    get_root().add_child(ui)
    ui._set_recipe_filter("초월")
    ck(ui.recipe_list.get_child_count() == 3, "transcendent catalog filter shows three")
    ui.queue_free()
    print("TRANSCENDENT RECIPE RESULT: %d failures" % failures)
    quit(0 if failures == 0 else 1)
