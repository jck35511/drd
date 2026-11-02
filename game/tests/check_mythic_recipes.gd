extends SceneTree
const Game = preload("res://main.gd")
var fails: int = 0
func check(ok: bool, text: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + text)
    if not ok:
        fails += 1
func _initialize() -> void:
    call_deferred("run_checks")
func run_checks() -> void:
    var recipes: Array = []
    for recipe in Game.RECIPES:
        if int(recipe["result"]) >= 42 and int(recipe["result"]) <= 45:
            recipes.append(recipe)
    check(Game.RECIPES.size() == 39 and recipes.size() == 4, "39 total recipes, 4 mythic recipes")
    var keys: Dictionary = {}
    for recipe in recipes:
        var result: int = int(recipe["result"])
        var materials: Array = recipe["materials"]
        var key: Array = materials.duplicate()
        key.sort()
        check(materials.size() == 3 and not keys.has(str(key)), "three unique recipe ingredients for " + Game.DOGS[result])
        keys[str(key)] = true
        var valid: bool = int(recipe.get("item", -1)) == result and Game.BEAST_ITEMS.has(result)
        for m in materials:
            valid = valid and Game.GRADES[int(m)] == "맹수"
        check(valid, "mythic item and beast-tier materials for " + Game.DOGS[result])
        var game: Control = Game.new()
        for i in range(3):
            game.dogs.append({"cell":i,"kind":int(materials[i]),"cooldown":0.0})
        var old: Array = game.dogs.duplicate(true)
        game._craft_recipe_from_catalog(result)
        check(game.dogs == old, "missing item blocks " + Game.DOGS[result])
        game.beast_items[result] = 1
        game._craft_recipe_from_catalog(result)
        check(game.dogs.size() == 1 and int(game.dogs[0]["kind"]) == result and int(game.beast_items[result]) == 0, "item consumed and mythic created " + Game.DOGS[result])
        game.free()
    var shown: Control = Game.new()
    get_root().add_child(shown)
    shown._set_recipe_filter("신화")
    check(shown.recipe_list.get_child_count() == 4, "mythic tab displays four")
    shown.queue_free()
    print("MYTHIC RECIPE RESULT: %d failures" % fails)
    quit(0 if fails == 0 else 1)
