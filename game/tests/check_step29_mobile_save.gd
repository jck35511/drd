extends SceneTree
const Game = preload("res://main.gd")
const Storage = preload("res://scripts/run_storage.gd")
var failures: int = 0
func verify(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
func _initialize() -> void:
	call_deferred("run")
func touch(g: Control, cell: int) -> void:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.position = g._cell_center(cell)
	g._board_input(event)
func run() -> void:
	Storage.clear_save()
	var g: Control = Game.new()
	g.persistence_enabled = false
	g.difficulty_confirmed = true
	g.difficulty = "지옥"
	g.gold = 357
	g.wave = 23
	g.wave_running = true
	g.wave_time_left = 17.5
	g.beast_items = {36:2,48:1}
	g.first_transcendent_claimed = {48:true}
	g.rng.seed = 123456
	g.dogs.append({"kind":42,"cell":0,"cooldown":0.5})
	g.enemies.append({"hp":250.0,"max_hp":500.0,"progress":1.2,"armor":25.0,"magic_res":0.2,"move_speed":0.1,"effects":{"burn":{"time":2.0,"power":10.0}}})
	touch(g,0)
	verify(g.selected == 0,"touch selects unit")
	touch(g,5)
	verify(g.dogs[0]["cell"] == 5 and g.selected == -1,"touch moves to empty cell")
	verify(Storage.save(g),"atomic save succeeds")
	var expected_rng: int = g.rng.randi()
	var restored: Control = Game.new()
	restored.persistence_enabled = false
	verify(Storage.restore(restored),"restore succeeds")
	verify(restored.gold == 357 and restored.wave == 23 and restored.difficulty == "지옥","difficulty and progress restored")
	verify(restored.dogs.size() == 1 and int(restored.dogs[0]["kind"]) == 42 and int(restored.dogs[0]["cell"]) == 5 and is_equal_approx(float(restored.dogs[0]["cooldown"]),0.5),"unit identity, position and cooldown restored")
	verify(restored.enemies.size() == 1 and is_equal_approx(float(restored.enemies[0]["hp"]),250.0) and is_equal_approx(float(restored.enemies[0]["progress"]),1.2) and is_equal_approx(float(restored.enemies[0]["effects"]["burn"]["time"]),2.0) and is_equal_approx(float(restored.enemies[0]["effects"]["burn"]["power"]),10.0),"enemy HP, progress and active damage effect restored")
	verify(restored.beast_items.get(48) == 1 and restored.first_transcendent_claimed.has(48),"integer item keys survive JSON")
	verify(restored.rng.randi() == expected_rng,"random sequence survives restart")
	verify(restored.paused,"restored game waits for explicit resume")
	var time_before: float = restored.wave_time_left
	restored._process(1.0)
	verify(restored.wave_time_left == time_before,"paused game does not advance")
	restored._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	verify(restored.paused,"background transition pauses")
	g.game_over = true
	Storage.save(g)
	verify(not FileAccess.file_exists(Storage.PATH),"defeat removes stale resumable run")
	var file := FileAccess.open(Storage.PATH,FileAccess.WRITE)
	file.store_string("{invalid")
	file.close()
	verify(not Storage.restore(restored),"corrupt save safely rejected")
	Storage.clear_save()
	g.free()
	restored.free()
	var ui: Control = Game.new()
	ui.persistence_enabled = false
	get_root().add_child(ui)
	ui.set_process(false)
	verify(ui._dog_portraits.size() == 49,"49 illustrated units loaded")
	ui._open_unit_gallery()
	verify(ui.unit_gallery != null and ui.unit_gallery.visible,"illustrated unit gallery opens")
	ui.queue_free()
	print("STEP29 MOBILE SAVE RESULT: %d failures" % failures)
	quit(1 if failures else 0)
