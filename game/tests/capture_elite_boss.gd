extends SceneTree
const Game = preload("res://main.gd")
func _initialize() -> void:
	call_deferred("run")
func snap(name: String, preview: bool = true) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	picture.save_png("res://previews/"+name+".png")
	if preview:
		picture.resize(360,640)
		print("ELITE_PREVIEW_"+name+":"+Marshalls.raw_to_base64(picture.save_jpg_to_buffer(0.8)))
func run() -> void:
	root.size = Vector2i(720,1280)
	var g: Control = Game.new()
	g.persistence_enabled = false
	root.add_child(g)
	g.set_process(false)
	g._select_difficulty("보통")
	g.wave = 10
	g.boss_pending = true
	g._start_boss_round()
	g.game_audio.music.stop()
	g.dogs.clear()
	g.dogs.append({"kind":44,"cell":0,"cooldown":0.0})
	g.selected = 0
	g.wave_time_left = 9.4
	g._emit_attack_visual(0,0)
	g._emit_skill_visual(0,0,"chain")
	g.presentation_clock = 0.14
	for fx in g.combat_fx: fx["age"] = 0.14
	g._refresh()
	await snap("boss-countdown-selected")
	# A save fixture exercises the production APK's restore path without debug cheats.
	g.dogs.clear()
	var cells: Array[int] = [0,1,2,3,4,5,6,11,12,17,18,23,30]
	for i in range(13): g.dogs.append({"kind":36+i,"cell":cells[i],"cooldown":0.0})
	g.selected = -1
	g.wave_time_left = 60.0
	g.enemies[0]["hp"] = 10000000.0
	g.enemies[0]["max_hp"] = 10000000.0
	g.rng.seed = 3898
	var fixture: Dictionary = {"version":1,"rng_state":str(g.rng.state)}
	for field in g.RunStorage.FIELDS: fixture[field] = g.get(field)
	var file := FileAccess.open("res://previews/boss-fixture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture))
	file.close()
	# Review all units in four phone-sized pages; keep the viewport's real scale.
	g.visible = false
	for page in range(4):
		var grid := GridContainer.new()
		grid.columns = 4
		grid.theme = g.ui_theme
		grid.position = Vector2(8,60)
		grid.add_theme_constant_override("h_separation",8)
		grid.add_theme_constant_override("v_separation",8)
		root.add_child(grid)
		for kind in range(page*16,mini(49,(page+1)*16)):
			var panel := PanelContainer.new()
			panel.custom_minimum_size = Vector2(170,224)
			var bg := StyleBoxFlat.new()
			bg.bg_color = Color("#253451") if kind%2==0 else Color("#d6deed")
			panel.add_theme_stylebox_override("panel",bg)
			grid.add_child(panel)
			var column := VBoxContainer.new()
			panel.add_child(column)
			var texture := TextureRect.new()
			texture.texture = g.sky_art.unit_texture(kind)
			texture.custom_minimum_size = Vector2(168,170)
			texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			column.add_child(texture)
			var label := Label.new()
			label.text = "%02d %s" % [kind,g.DOGS[kind]]
			label.custom_minimum_size = Vector2(164,46)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size",19)
			label.add_theme_color_override("font_color",Color.WHITE if kind%2==0 else Color("#14223b"))
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(label)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var gallery: Image = root.get_texture().get_image()
		gallery.save_png("res://previews/unit-gallery-%d.png" % (page+1))
		print("UNIT_GALLERY_%d:" % (page+1)+Marshalls.raw_to_base64(gallery.save_jpg_to_buffer(0.85)))
		grid.queue_free()
		await process_frame
	# Render every elite effect family, including shader-free mobile paths.
	var effects := GridContainer.new()
	effects.columns = 4
	effects.position = Vector2(8,30)
	effects.add_theme_constant_override("h_separation",8)
	effects.add_theme_constant_override("v_separation",8)
	root.add_child(effects)
	for kind in range(36,49):
		var card := Control.new()
		card.custom_minimum_size = Vector2(170,280)
		card.clip_contents = true
		effects.add_child(card)
		card.draw.connect(draw_effect_card.bind(card,g,kind))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var sheet: Image = root.get_texture().get_image()
	sheet.save_png("res://previews/all-13-elite-effects.png")
	print("EFFECT_GALLERY:"+Marshalls.raw_to_base64(sheet.save_jpg_to_buffer(0.85)))
	effects.queue_free()
	g.queue_free()
	await process_frame
	quit()

func draw_effect_card(card: Control, g: Control, kind: int) -> void:
	card.draw_rect(Rect2(0,0,170,280),Color("#17243c"))
	var font: Font = g.ui_theme.default_font
	card.draw_string(font,Vector2(5,24),g.DOGS[kind],HORIZONTAL_ALIGNMENT_LEFT,160,17,Color.WHITE)
	g.sky_art.draw_character(card,g.sky_art.unit_texture(kind),Vector2(85,218),92)
	var fx: Dictionary = {"from":Vector2(85,208),"to":Vector2(85,102),"style":g.ELITE_STYLES[kind-36],"age":0.25,"duration":0.85,"kind":kind,"skill":g.DOG_SKILLS[kind][0]}
	g.sky_art._draw_effect(card,fx,g)
