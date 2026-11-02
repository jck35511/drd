extends SceneTree
const Game = preload("res://main.gd")
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png("res://previews/" + name + ".png")
	picture.resize(360,640)
	print("UI_PREVIEW_" + name + ":" + Marshalls.raw_to_base64(picture.save_png_to_buffer()))
func run() -> void:
	root.size = Vector2i(720,1280)
	var g: Control = Game.new()
	g.persistence_enabled = false
	root.add_child(g)
	g.set_process(false)
	g.game_audio.music.stop()
	await process_frame
	await process_frame
	var layout: Dictionary = {}
	for child in g.difficulty_panel.get_child(0).get_children():
		if child is Button and child.text.begins_with("보통"):
			layout["normal_difficulty"] = {"x":child.global_position.x,"y":child.global_position.y,"width":child.size.x,"height":child.size.y}
	g._select_difficulty("보통")
	g._toggle_recipes()
	await snap("readable-recipes")
	for grade in ["맹수", "신화", "초월"]:
		g._set_recipe_filter(grade)
		g.recipe_list.get_parent().reset_position()
		await snap("recipe-portraits-"+grade)
	g.dogs.assign([{"kind":0,"cell":0,"cooldown":0.0},{"kind":0,"cell":1,"cooldown":0.0},{"kind":1,"cell":2,"cooldown":0.0}])
	g._set_recipe_filter("전체")
	await process_frame
	await process_frame
	g.recipe_list.get_parent().ensure_control_visible(g.recipe_list.get_node("Recipe_4"))
	await snap("recipe-duplicate-materials")
	g.dogs.clear()
	g._set_recipe_filter("전체")
	g.recipe_list.get_parent().reset_position()
	g._toggle_recipes()
	g._set_draw_info_tab("확률표")
	g._toggle_draw_info()
	await snap("readable-draw-info")
	g._toggle_draw_info()
	g._toggle_settings()
	await snap("audio-settings")
	for key in g.audio_sliders:
		var slider: HSlider = g.audio_sliders[key]
		layout[key] = {"x":slider.global_position.x,"y":slider.global_position.y,"width":slider.size.x,"height":slider.size.y}
	var controls: Dictionary = {
		"summon":g.summon_button,
		"start_wave":g.wave_button,
		"draw_probability_tab":g.draw_info_panel.get_child(0).get_node("DrawInfoTabRow").get_child(2),
		"draw_close":g.draw_info_panel.get_child(0).get_child(0).get_children().back(),
		"recipe_close":g.recipe_panel.get_child(0).get_child(0).get_children().back(),
		"settings_close":g.settings_panel.get_child(0).get_children().back()
	}
	for key in controls:
		var control: Control = controls[key]
		layout[key] = {"x":control.global_position.x,"y":control.global_position.y,"width":control.size.x,"height":control.size.y}
	var layout_file := FileAccess.open("res://previews/audio-layout.json",FileAccess.WRITE)
	layout_file.store_string(JSON.stringify(layout))
	layout_file.close()
	g.queue_free()
	await process_frame
	quit()
