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
	g._select_difficulty("보통")
	g._toggle_recipes()
	await snap("readable-recipes")
	g._toggle_recipes()
	g._set_draw_info_tab("확률표")
	g._toggle_draw_info()
	await snap("readable-draw-info")
	g._toggle_draw_info()
	g._toggle_settings()
	await snap("audio-settings")
	var layout: Dictionary = {}
	for key in g.audio_sliders:
		var slider: HSlider = g.audio_sliders[key]
		layout[key] = {"x":slider.global_position.x,"y":slider.global_position.y,"width":slider.size.x,"height":slider.size.y}
	var layout_file := FileAccess.open("res://previews/audio-layout.json",FileAccess.WRITE)
	layout_file.store_string(JSON.stringify(layout))
	layout_file.close()
	g.queue_free()
	await process_frame
	quit()
