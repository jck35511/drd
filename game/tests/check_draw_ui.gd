extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func _check(ok: bool, msg: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1
func _initialize() -> void:
	call_deferred("_run_checks")
func _run_checks() -> void:
	var game: Control = Game.new()
	get_root().add_child(game)
	_check(game.draw_info_panel != null and game.draw_info_button != null, "draw info button and panel created")
	game._toggle_draw_info()
	_check(game.draw_info_panel.visible and game.draw_info_list.get_child_count() >= 8, "inventory lists all six beast items")
	game.beast_items[36] = 2
	game._refresh_draw_info()
	_check(game.draw_info_list.get_child_count() >= 8, "inventory refresh after item gained")
	game._record_draw({"type":"item", "item":36})
	game._record_draw({"type":"gold", "multiplier":2, "gold":100})
	game._set_draw_info_tab("최근 결과")
	_check(game.draw_history.size() == 2 and game.draw_info_list.get_child_count() >= 3, "recent draw results displayed")
	game._set_draw_info_tab("확률표")
	_check(game.draw_info_list.get_child_count() >= 20, "full probability table displayed")
	var total: float = 18.0
	for weight in Game.DRAW_GOLD_WEIGHTS:
		total += 82.0 * float(weight) / float(Game.DRAW_GOLD_WEIGHT_TOTAL)
	_check(absf(total - 100.0) < 0.001, "item and gold odds sum to 100 percent")
	game._restart()
	_check(game.draw_history.is_empty() and game.beast_items.is_empty(), "restart clears draw history and inventory")
	game.queue_free()
	print("DRAW UI TEST RESULT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
