extends SceneTree
const Game = preload("res://main.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures += 1
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var game: Control = Game.new()
    root.add_child(game)
    var enemy_rect := Rect2(game.status_label.position, game.status_label.size)
    var wave_rect := Rect2(game.wave_hud_label.position, game.wave_hud_label.size)
    check(enemy_rect.position.x >= 16 and enemy_rect.end.x <= 124, "enemy label fits expanded 118px HUD card")
    check(game.status_label.get_theme_font_size("font_size") >= 22, "enemy counter remains readable")
    check(wave_rect.position.x >= 255 and wave_rect.end.x <= 504, "wave text fits narrower HUD card")
    check(wave_rect.position.y >= 15 and wave_rect.end.y <= 65, "wave two-line label inside vertical borders")
    check(game.wave_hud_label.get_theme_font_size("font_size") >= 18, "wave font enlarged")
    game._select_difficulty("쉬움")
    game.enemies.clear()
    game._refresh()
    check(game.status_label.text.contains("/100"), "field capacity remains shown")
    check(game.wave_hud_label.text.find("\n") >= 0, "wave status maintains two lines")
    game.queue_free()
    print("STEP23 HUD TEXT FIT TEST RESULT: %d failures" % failures)
    quit(1 if failures else 0)
