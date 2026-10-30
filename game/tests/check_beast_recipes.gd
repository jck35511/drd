extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func _check(ok: bool, title: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + title)
    if not ok:
        failures += 1
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var beast_recipes: Array[Dictionary] = []
    var signatures: Dictionary = {}
    var all_valid: bool = true
    for recipe in Game.RECIPES:
        var result: int = int(recipe["result"])
        var ingredients: Array = recipe["materials"]
        if result < 36 or result > 41:
            continue
        beast_recipes.append(recipe)
        var sorted: Array = ingredients.duplicate()
        sorted.sort()
        var key: String = str(sorted)
        if signatures.has(key):
            all_valid = false
        signatures[key] = true
        if ingredients.size() != 3 or not recipe.has("item") or int(recipe["item"]) != result or not Game.BEAST_ITEMS.has(result):
            all_valid = false
        for kind in ingredients:
            if int(kind) < 0 or int(kind) >= Game.GRADES.size() or Game.GRADES[int(kind)] != "대형견":
                all_valid = false
    _check(Game.RECIPES.size() == 39 and beast_recipes.size() == 6, "39 recipes including 6 beasts")
    _check(all_valid and signatures.size() == 6, "beast ingredients all large tier and distinct recipes")
    for recipe in beast_recipes:
        var game: Control = Game.new()
        var ingredients: Array = recipe["materials"]
        for i in range(ingredients.size()):
            game.dogs.append({"cell": i, "kind": int(ingredients[i]), "cooldown": 0.0})
        var original: Array = game.dogs.duplicate(true)
        game._craft_recipe_from_catalog(int(recipe["result"]))
        _check(game.dogs == original, "missing exclusive item blocks " + Game.DOGS[int(recipe["result"])])
        game.beast_items[int(recipe["result"])] = 1
        game._craft_recipe_from_catalog(int(recipe["result"]))
        _check(game.dogs.size() == 1 and int(game.dogs[0]["kind"]) == int(recipe["result"]) and int(game.beast_items.get(int(recipe["result"]), 0)) == 0, "catalog craft and item consumed " + Game.DOGS[int(recipe["result"])])
        game.free()
    var game: Control = Game.new()
    var first: Dictionary = beast_recipes[0]
    for i in range(2):
        game.dogs.append({"cell": i, "kind": int(first["materials"][i]), "cooldown": 0.0})
    var before: Array = game.dogs.duplicate(true)
    game._craft_recipe_from_catalog(int(first["result"]))
    _check(game.dogs == before, "missing ingredients do not remove units")
    game.free()
    game = Game.new()
    root.add_child(game)
    game.recipe_panel.visible = true
    game._set_recipe_filter("맹수")
    _check(game.recipe_list.get_child_count() == 6, "beast catalog filter has six entries")
    root.remove_child(game)
    game.free()
    print("BEAST FUSION TEST RESULT: %d failures" % failures)
    quit(0 if failures == 0 else 1)
