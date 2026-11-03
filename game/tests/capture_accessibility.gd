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
	for pair in [["new_game","NewGame"],["continue_game","Resume"]]:
		var child: Control=g.features.start_panel.get_node("Canvas/"+str(pair[1]))
		layout[pair[0]]={"x":child.global_position.x,"y":child.global_position.y,"width":child.size.x,"height":child.size.y}
	await snap("start-screen")
	g.features.new_game()
	await process_frame
	await process_frame
	for child in g.difficulty_panel.get_child(0).get_children():
		if child is Button and child.text.begins_with("보통"):
			layout["normal_difficulty"] = {"x":child.global_position.x,"y":child.global_position.y,"width":child.size.x,"height":child.size.y}
	g._select_difficulty("보통")
	g.reserve_units={0:4,49:1,50:1,51:1}
	g._refresh()
	g.features.open_reserve()
	await snap("summon-reserve")
	var pick: Control=g.features.reserve_list.get_child(0).get_child(1)
	layout["reserve_pick"]={"x":pick.global_position.x,"y":pick.global_position.y,"width":pick.size.x,"height":pick.size.y}
	g.features.close_reserve()
	g.reserve_units.clear()
	g.hidden_tickets=1
	g.features.open_choice("히든")
	await snap("hidden-choice")
	g.features.close_choice()
	g.hidden_tickets=0
	g.dogs.assign([{"kind":49,"cell":0,"cooldown":0.0},{"kind":50,"cell":5,"cooldown":0.0},{"kind":51,"cell":30,"cooldown":0.0}])
	for index in range(3):
		g.combat_fx.clear()
		g.HiddenCombat.emit(g,index,Vector2(360,149),["star_collapse","void_rift","dream_resonance"][index])
		g.combat_fx[0]["age"]=0.7
		g.board.queue_redraw()
		await snap("hidden-skill-"+str(index))
	g.combat_fx.clear()
	g.dogs.clear()
	g.board.queue_redraw()
	g.features.toast("초월 골드 3배 · +600G\n천장! 초월 조합 아이템 선택권 +1")
	await snap("draw-result-popup")
	g.features.tick(3)
	g.game_over=true
	g._refresh()
	await snap("defeat-retry")
	g.features.new_game()
	g._select_difficulty("보통")
	g.victory=true
	g._refresh()
	await snap("victory-retry")
	g.features.new_game()
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
