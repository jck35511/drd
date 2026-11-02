extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var main_script = load("res://main.gd")
	var game = main_script.new()
	root.add_child(game)
	assert(game.COLS == 6 and game.ROWS == 6)
	assert(game._sell_value(0) == 10)
	assert(game._sell_value(3) == 40)
	assert(game._sell_value(6) == 100)
	assert(game._sell_value(36) == 0)
	assert(game._sell_value(42) == 0)
	assert(game._sell_value(46) == 0)
	game.difficulty_confirmed = true
	game.gold = 0
	game.dogs.clear()
	game.dogs.append({"cell": 0, "kind": 0, "cooldown": 0.0})
	game.dogs.append({"cell": 1, "kind": 3, "cooldown": 0.0})
	game.dogs.append({"cell": 2, "kind": 6, "cooldown": 0.0})
	game.selected = 0
	game._sell_selected()
	assert(game.gold == 10 and game.dogs.size() == 2 and game.selected == -1)
	game.selected = 0
	game._sell_selected()
	assert(game.gold == 50 and game.dogs.size() == 1)
	game.selected = 0
	game._sell_selected()
	assert(game.gold == 150 and game.dogs.is_empty())
	game.selected = -1
	game._sell_selected()
	assert(game.gold == 150)
	game.dogs.clear()
	game.dogs.append({"cell": 0, "kind": 36, "cooldown": 0.0})
	game.selected = 0
	game._sell_selected()
	assert(game.gold == 150 and game.dogs.size() == 1)
	assert(game.GRID_ORIGIN.y == 197)
	assert(game.ROUTE[0].distance_to(game.ROUTE[1]) == 534.0)
	print("STEP23 SALES TEST RESULT: 0 failures")
	quit()
