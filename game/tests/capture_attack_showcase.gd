extends SceneTree
const Game = preload("res://main.gd")
const Animator = preload("res://scripts/attack_animator.gd")
var game: Control
var phase: float = 0.0
var cards: Array[Control] = []
func _initialize() -> void:
	call_deferred("run")
func draw_motion(card: Control, kind: int, title: String) -> void:
	card.draw_rect(Rect2(0,0,346,285),Color("#18253c"))
	card.draw_string(game.ui_theme.default_font,Vector2(14,35),title,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color.WHITE)
	var aim := Vector2(0.8,-0.6)
	card.draw_circle(Vector2(170,225),42,Color(0,0,0,0.25))
	game.sky_art.draw_unit_pose(card,kind,Vector2(170,175),phase,aim,110.0)
	var stage: String = "준비" if phase<0.22 else "타격" if phase<0.53 else "복귀"
	card.draw_string(game.ui_theme.default_font,Vector2(14,270),stage,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#ffe09d"))
func run() -> void:
	root.size=Vector2i(720,1280)
	game=Game.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.set_process(false)
	game.visible=false
	game.game_audio.music.stop()
	var grid:=GridContainer.new()
	grid.columns=2
	grid.position=Vector2(10,35)
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",12)
	root.add_child(grid)
	var kinds: Array[int]=[42,43,44,45,46,47,48]
	var titles: Array[String]=["빙결의 펜리르","태양의 레오","뇌신의 백호","생명의 구미호","심연의 아몬","천공의 라","명계의 케르베로스"]
	for i in range(7):
		var card:=Control.new()
		card.custom_minimum_size=Vector2(346,285)
		card.clip_contents=true
		grid.add_child(card)
		card.draw.connect(draw_motion.bind(card,kinds[i],titles[i]))
		cards.append(card)
	for frame in range(32):
		phase=float(frame)/31.0
		for card in cards: card.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var shot: Image=root.get_texture().get_image()
		shot.save_png("res://previews/motion-frame-%02d.png" % frame)
		if frame in [6,12,22]:
			shot.resize(360,640)
			print("MOTION_PHASE_%d:" % frame+Marshalls.raw_to_base64(shot.save_jpg_to_buffer(0.85)))
	grid.queue_free()
	await process_frame
	# Render every skill semantic, not just one skill for each creature.
	var skills: Array = game.GameAudio.SKILL_SOUNDS
	for page in range(2):
		var fx_grid:=GridContainer.new()
		fx_grid.columns=3
		fx_grid.position=Vector2(8,30)
		fx_grid.add_theme_constant_override("h_separation",8)
		fx_grid.add_theme_constant_override("v_separation",8)
		root.add_child(fx_grid)
		for i in range(page*12,mini(skills.size(),(page+1)*12)):
			var card:=Control.new()
			card.custom_minimum_size=Vector2(228,290)
			card.clip_contents=true
			fx_grid.add_child(card)
			card.draw.connect(draw_skill.bind(card,str(skills[i])))
		await process_frame
		await RenderingServer.frame_post_draw
		var shot: Image=root.get_texture().get_image()
		shot.save_png("res://previews/skill-semantics-%d.png" % page)
		print("SKILL_SEMANTICS_%d:" % page+Marshalls.raw_to_base64(shot.save_jpg_to_buffer(0.8)))
		fx_grid.queue_free()
		await process_frame
	game.queue_free()
	await process_frame
	quit()
func draw_skill(card: Control, skill: String) -> void:
	card.draw_rect(Rect2(0,0,228,290),Color("#17243c"))
	card.draw_string(game.ui_theme.default_font,Vector2(8,32),game.SKILL_NAMES[skill],HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color.WHITE)
	var fx: Dictionary={"from":Vector2(114,245),"to":Vector2(114,160),"style":"lightning","kind":42 if skill in ["slow","freeze"] else 47 if skill in ["burn","magic_splash"] else 46 if skill in ["heavy","poison"] else 44,"skill":skill,"age":0.35,"duration":1.1,"apparition":not skill.ends_with("_aura")}
	game.sky_art._draw_effect(card,fx,game)
