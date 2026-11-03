extends SceneTree
const Game=preload("res://main.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	Game.RunStorage.clear_save()
	var g: Control=Game.new()
	g.persistence_enabled=false
	root.add_child(g)
	g.set_process(false)
	await process_frame
	assert(g.features.Screens.has_art())
	var canvas: Control=g.features.start_panel.get_node("Holder/Canvas")
	assert(canvas.get_node("OriginalArtwork").texture.get_size()==Vector2(1024,1536))
	assert(canvas.get_node("Resume").disabled)
	canvas.get_node("Catalog").pressed.emit()
	assert(g.recipe_panel.visible and g.recipe_panel.z_index>g.features.start_panel.z_index)
	g._toggle_recipes()
	canvas.get_node("Settings").pressed.emit()
	assert(g.settings_panel.visible)
	g._notification(Control.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(not g.settings_panel.visible)
	canvas.get_node("NewGame").pressed.emit()
	assert(g.difficulty_panel.visible and not g.features.start_panel.visible)
	g._select_difficulty("보통")
	g.wave=23
	g.bosses_defeated=2
	g.game_over=true
	g._refresh()
	await process_frame
	var result: Control=g.features.result_panel.get_node("Holder/Canvas")
	assert(result.get_node("OriginalArtwork").texture.resource_path.ends_with("defeat.png"))
	assert(result.get_node("DifficultyValue").text=="보통")
	assert(result.get_node("WaveValue").text=="23 / 80")
	assert(result.get_node("BossValue").text=="2 / 8")
	result.get_node("Home").pressed.emit()
	assert(g.features.start_panel.visible and not g.features.result_panel.visible)
	canvas.get_node("NewGame").pressed.emit()
	g._select_difficulty("어려움")
	g.wave=80
	g.bosses_defeated=8
	g.victory=true
	g._refresh()
	await process_frame
	result=g.features.result_panel.get_node("Holder/Canvas")
	assert(result.get_node("OriginalArtwork").texture.resource_path.ends_with("victory.png"))
	assert(result.get_node("WaveValue").text=="80 / 80" and result.get_node("BossValue").text=="8 / 8")
	result.get_node("Retry").pressed.emit()
	assert(g.difficulty_panel.visible and not g.difficulty_confirmed and not g.victory)
	assert(g.wave==0 and g.bosses_defeated==0)
	g.queue_free()
	await process_frame
	print("PASS: original 3 screen assets, title menus, dynamic results, home and retry to difficulty")
	quit()
