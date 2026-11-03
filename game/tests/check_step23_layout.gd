extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = Game.new()
	root.add_child(game)
	check(game.wave_hud_label != null, "separate wave HUD exists")
	check(game.status_label.position.y < 100, "compact header displays resources")
	check(game.info_label.position.y >= 817 and game.info_label.position.y + game.info_label.size.y < 985, "status message visible above bottom dock")
	var route_top: float = game.ROUTE[0].y - 25.0
	for b in [game.speed_button, game.settings_button]:
		check(b.position.y + b.size.y < route_top, "top toolbar does not overlap path: " + b.text)
	for b in [game.summon_button, game.wave_button, game.fusion_button, game.recipe_button, game.draw_button, game.mythic_draw_button, game.transcendent_draw_button, game.draw_info_button]:
		check(b.position.y >= 998 and b.position.y + b.size.y <= 1280, "bottom control entirely visible: " + b.text)
	check(game.ROUTE.size() == 4 and game.GRID_ORIGIN == Vector2(127,197) and game.COLS == 6 and game.ROWS == 6, "aligned rectangular path with 6x6 board")
	check(game.mission_button.position.y >= 998, "mission button stays in bottom dock")
	check(game.sell_button != null and game.sell_button.position.y + game.sell_button.size.y < 992, "contextual sale button above controls")
	check(game.board.size.y < game.info_label.position.y, "gameboard touch input does not cover info text")
	check(game.CELL == 77.0 and game.ROUTE[0] == Vector2(93,149) and game.ROUTE[2] == Vector2(627,700), "enlarged board and aligned enemy route")
	check(game.selected_context_label != null and game.selected_context_panel != null, "selected-unit contextual panel exists")
	check(game.sell_button.position.y >= game.board.size.y and game.sell_button.position.y + game.sell_button.size.y < 817, "sell button between battlefield and chat")
	game.queue_free()
	print("STEP23 LAYOUT TEST RESULT: %d failures" % failures)
	quit(1 if failures else 0)
