extends SceneTree
const Game = preload("res://main.gd")
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(720,1280)
	var game: Control=Game.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.set_process(false)
	game._select_difficulty("보통")
	game.wave=24
	game.boss_round=2
	game.wave_running=true
	game.wave_time_left=26.0
	game.gold=320
	game.dogs.clear()
	var kinds: Array[int]=[10,5,8,36,42,44,45,47,48]
	var cells: Array[int]=[0,4,11,18,12,22,27,32,35]
	for i in range(kinds.size()):
		game.dogs.append({"kind":kinds[i],"cell":cells[i],"cooldown":0.0})
	for i in range(14):
		var stats: Dictionary=game._regular_wave_stats(24)
		game.enemies.append({"progress":float(i)*0.27,"hp":stats["hp"],"max_hp":stats["hp"],"enemy_type":game.REGULAR_ENEMY_TYPES[i%4],"effects":{}})
	game.selected=4
	game._emit_attack_visual(5,3)
	game._emit_attack_visual(7,5)
	game._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://previews")
	var shot: Image = root.get_texture().get_image()
	shot.save_png("res://previews/gameplay-720x1280.png")
	shot.resize(360, 640)
	print("SKY_PREVIEW:" + Marshalls.raw_to_base64(shot.save_png_to_buffer()))
	game.difficulty_panel.visible=true
	game.board.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/difficulty-720x1280.png")
	game.queue_free()
	await process_frame
	quit(0)
