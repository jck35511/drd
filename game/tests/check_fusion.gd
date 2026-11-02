extends SceneTree
# Run: godot --headless --path . --script res://tests/check_fusion.gd
const GAME_SCRIPT = preload("res://main.gd")

func _initialize() -> void:
	var passed: bool = true
	var small_recipe: Dictionary = {}
	var duplicate_recipe: Dictionary = {}
	for recipe in GAME_SCRIPT.RECIPES:
		if small_recipe.is_empty() and GAME_SCRIPT.GRADES[int(recipe["result"])] == "중형견":
			small_recipe = recipe
		var materials: Array = recipe["materials"]
		if duplicate_recipe.is_empty() and (materials[0] == materials[1] or materials[1] == materials[2] or materials[0] == materials[2]):
			duplicate_recipe = recipe
	passed = _test_success(small_recipe) and passed
	passed = _test_missing(small_recipe) and passed
	passed = _test_duplicate(duplicate_recipe) and passed
	passed = _test_invalid_selection(small_recipe) and passed
	if passed:
		print("PASS: fusion 3-to-1, missing materials, duplicate instances, invalid selection")
	else:
		push_error("FAIL: fusion regression test")
	quit(0 if passed else 1)

func _create_game(recipe: Dictionary, count: int = 3) -> Control:
	var game: Control = GAME_SCRIPT.new()
	for i in range(count):
		game.dogs.append({"cell": i, "kind": int(recipe["materials"][i]), "cooldown": 0.0})
	game.selected = 0
	return game

func _test_success(recipe: Dictionary) -> bool:
	var game: Control = _create_game(recipe)
	game._fuse_selected()
	var ok: bool = game.dogs.size() == 1 and int(game.dogs[0]["kind"]) == int(recipe["result"]) and int(game.dogs[0]["cell"]) == 0 and game.selected == 0
	game.free()
	return _check(ok, "three ingredients -> one result at selected cell")

func _test_missing(recipe: Dictionary) -> bool:
	var game: Control = _create_game(recipe, 2)
	var before: Array = game.dogs.duplicate(true)
	game._fuse_selected()
	var ok: bool = game.dogs == before and game.selected == 0
	game.free()
	return _check(ok, "missing material must not modify dogs")

func _test_duplicate(recipe: Dictionary) -> bool:
	if recipe.is_empty():
		return _check(false, "duplicate-material recipe exists")
	var game: Control = _create_game(recipe, 2)
	var before: Array = game.dogs.duplicate(true)
	game._fuse_selected()
	var refused: bool = game.dogs == before
	game.dogs.append({"cell": 2, "kind": int(recipe["materials"][2]), "cooldown": 0.0})
	game._fuse_selected()
	var succeeded: bool = game.dogs.size() == 1 and int(game.dogs[0]["kind"]) == int(recipe["result"])
	game.free()
	return _check(refused and succeeded, "duplicate materials require distinct instances")

func _test_invalid_selection(recipe: Dictionary) -> bool:
	var game: Control = _create_game(recipe)
	var before: Array = game.dogs.duplicate(true)
	game.selected = -1
	game._fuse_selected()
	var ok: bool = game.dogs == before
	game.free()
	return _check(ok, "invalid selection cannot fuse")

func _check(value: bool, label: String) -> bool:
	print(("PASS: " if value else "FAIL: ") + label)
	return value
