extends SceneTree
const Game = preload("res://main.gd")
var fails: int = 0
func ck(condition: bool, text: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + text)
	if not condition:
		fails += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var g: Control = Game.new()
	root.add_child(g)
	ck(g.forest_background != null and g.forest_background.texture != null, "forest backdrop asset loaded")
	ck(g.settings_button != null and g.settings_panel != null, "settings button and panel exist")
	ck(g.reset_button == null, "no restart button on combat controls")
	ck(g.settings_panel.visible == false, "settings hidden initially")
	ck(g.summon_button.text.find("20G") >= 0 and g.wave_button != null, "random 20G summon and wave start preserved")
	ck(g.draw_button != null and g.mythic_draw_button != null and g.transcendent_draw_button != null, "three gacha buttons remain")
	ck(g.board != null and g.COLS == 6 and g.ROWS == 6 and g.ROUTE.size() == 4, "6x6 board and rectangular enemy route preserved")
	g._select_difficulty("보통")
	g._toggle_settings()
	ck(g.settings_panel.visible, "settings opens")
	g.gold = 200
	g._ask_restart()
	ck(g.gold == 200 and g.difficulty_confirmed, "requesting restart does not reset immediately")
	g.restart_confirmation.hide()
	ck(g.gold == 200, "closing confirmation preserves progress")
	g._restart()
	ck(g.gold == 100 and not g.difficulty_confirmed and not g.settings_panel.visible, "confirmed restart resets and closes settings")
	g.queue_free()
	print("STEP23 UI TEST RESULT: %d failures" % fails)
	quit(1 if fails else 0)
