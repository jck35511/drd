extends SceneTree
const Game = preload("res://main.gd")
const TouchScroll = preload("res://scripts/touch_scroll.gd")
var failures: int = 0
var clicks: int = 0
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
func _initialize() -> void:
	call_deferred("run")
func touch(sc: Control, point: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = point
	e.pressed = pressed
	sc._input(e)
func drag(sc: Control, point: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = point
	sc._input(e)
func run() -> void:
	var g: Control = Game.new()
	g.persistence_enabled = false
	root.add_child(g)
	g.set_process(false)
	await process_frame
	await process_frame
	check(g.ui_theme.default_font is FontVariation,"weighted Korean font used")
	check(g.ui_theme.default_font_size >= 24,"readable body font")
	check(g.game_audio.sounds.size() == 10 and g.game_audio.music.stream != null,"music and ten sound effects packaged")
	check(g.game_audio.music.stream.get_length() > 40.0,"full music loop generated")
	g.game_audio.set_level("music",0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"zero music volume mutes only music bus")
	g.game_audio.set_level("sfx",0.55)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"effects independent of music mute")
	g.game_audio.set_level("music",0.35)
	g.game_audio.music.play()
	g.game_audio.set_backgrounded(true)
	check(g.game_audio.music.stream_paused,"music pauses in background")
	g.game_audio.set_backgrounded(false)
	g.game_audio.music.stop()
	g._toggle_settings()
	check(g.audio_sliders.size() == 3,"three independent volume controls")
	g.audio_sliders["master"].value = 42
	check(is_equal_approx(float(g.game_audio.levels["master"]),0.42),"slider changes actual volume")
	g._toggle_settings()
	g._toggle_recipes()
	await process_frame
	await process_frame
	var sc: Control = g.recipe_list.get_parent()
	check(sc is TouchScroll,"recipe catalog uses touch scrolling")
	check(sc.size.y > 200 and g.recipe_panel.size.y <= 900,"scroll area fits popup")
	var point: Vector2 = sc.global_position + Vector2(100, minf(300,sc.size.y-20))
	touch(sc,point,true)
	drag(sc,point-Vector2(0,130))
	var before: int = sc.scroll_vertical
	touch(sc,point-Vector2(0,130),false)
	sc._process(0.05)
	check(before > 50 and sc.scroll_vertical > before,"drag scrolls and release keeps inertia")
	g._toggle_recipes()
	# A drag starting over an enabled button must not trigger its action.
	var box := TouchScroll.new()
	box.position = Vector2(20,20)
	box.size = Vector2(300,300)
	root.add_child(box)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	for i in range(12):
		var b := Button.new()
		b.text = "tap"
		b.custom_minimum_size = Vector2(260,80)
		b.pressed.connect(func() -> void: clicks += 1)
		list.add_child(b)
	await process_frame
	await process_frame
	var p: Vector2 = list.get_child(1).global_position + Vector2(70,30)
	touch(box,p,true)
	drag(box,p-Vector2(0,80))
	touch(box,p-Vector2(0,80),false)
	check(clicks == 0,"drag over button never crafts accidentally")
	box.reset_position()
	await process_frame
	p = list.get_child(0).global_position + Vector2(70,30)
	touch(box,p,true)
	touch(box,p,false)
	check(clicks == 1,"ordinary tap still activates button")
	box.queue_free()
	g.queue_free()
	print("READABILITY AUDIO SCROLL RESULT: %d failures" % failures)
	quit(1 if failures else 0)
