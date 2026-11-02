extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1
func run_checks() -> void:
	var game = Game.new()
	root.add_child(game)
	check(game.COLS == 6 and game.ROWS == 6 and game.CELL == 77.0, "6x6 battlefield unchanged")
	check(game.selected_context_panel.size.y == 109, "effects panel expanded")
	check(game.info_label.position.y == 885 and game.info_label.position.y + game.info_label.size.y < 992, "chat inside bottom dock boundary")
	game.difficulty_confirmed = true
	game.dogs.clear()
	game.dogs.append({"cell": 1, "kind": 17, "cooldown": 0.0})
	game.selected = 0
	game._refresh()
	check("보더콜리" in game.selected_context_label.text and "기본 %.0f" % Game.ATTACK[17] in game.selected_context_label.text, "selected dog stats")
	check("공격속도 오라" in game.selected_context_label.text, "actual owned skill shown")
	game.dogs.clear()
	game.dogs.append({"cell": 1, "kind": 46, "cooldown": 0.0})
	game.selected = 0
	game._refresh()
	check("중독" in game.selected_context_label.text and "최대 체력 비례 피해" in game.selected_context_label.text, "all 4 transcendent skills shown")
	check(game._sell_value(0) == 10 and game._sell_value(3) == 40 and game._sell_value(6) == 100, "selling rules preserved")
	game.queue_free()
	print("STEP23 EFFECTS CHAT TEST RESULT: %d failures" % failures)
	quit(1 if failures else 0)
