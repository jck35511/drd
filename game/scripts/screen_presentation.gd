extends RefCounted
const ScoreValue=preload("res://scripts/score_value.gd")
# Original mobile preview PNGs, reused byte-for-byte from the approved artwork.
const SOURCES := {
	"start":"res://assets/screens/start.png",
	"victory":"res://assets/screens/victory.png",
	"defeat":"res://assets/screens/defeat.png"
}
static func has_art() -> bool:
	for path in SOURCES.values():
		if not ResourceLoader.exists(path): return false
	return true
static func action(parent: Control, name: String, value: String, rect: Rect2, callback: Callable) -> Button:
	var node := Button.new()
	node.name=name
	node.text=value
	node.position=rect.position
	node.size=rect.size
	node.add_theme_font_size_override("font_size",34)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color=Color(0.04,0.07,0.14,0.58) if state=="disabled" else Color(1,1,1,0.14) if state=="pressed" else Color(0,0,0,0)
		node.add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
		node.add_theme_color_override(state,Color(1,1,1,0))
	node.pressed.connect(callback)
	parent.add_child(node)
	return node
static func create(g: Control, kind: String, z: int) -> PanelContainer:
	var outer := PanelContainer.new()
	outer.size=Vector2(720,1280)
	outer.z_index=z
	outer.mouse_filter=Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color=Color("#10182c")
	outer.add_theme_stylebox_override("panel",style)
	g.add_child(outer)
	var holder := Control.new()
	holder.custom_minimum_size=Vector2(720,1280)
	outer.add_child(holder)
	var canvas := Control.new()
	canvas.name="Canvas"
	canvas.size=Vector2(1024,1536)
	canvas.scale=Vector2(0.703125,0.703125)
	canvas.position=Vector2(0,100)
	# Keep all source pixels at their original aspect ratio, with mobile safe margins.
	holder.add_child(canvas)
	# Expose the same stable path used by UI actions and verification scripts.
	holder.name="Holder"
	var art := TextureRect.new()
	art.name="OriginalArtwork"
	art.texture=load(SOURCES[kind])
	art.size=Vector2(1024,1536)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(art)
	# The presentation caption is not part of the playable screen.
	var footer := ColorRect.new()
	footer.position=Vector2(160,1468 if kind=="defeat" else 1405 if kind=="victory" else 1450)
	footer.size=Vector2(704,60 if kind=="defeat" else 90 if kind=="victory" else 55)
	footer.color=Color("#111c31")
	footer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(footer)
	return outer
static func canvas_of(panel: Control) -> Control:
	return panel.get_node("Holder/Canvas")
static func start(g: Control, f: RefCounted) -> PanelContainer:
	var outer := create(g,"start",310)
	var canvas := canvas_of(outer)
	action(canvas,"NewGame","게임 시작",Rect2(110,944,805,187),f.new_game)
	var resume := action(canvas,"Resume","이어하기",Rect2(104,1166,811,136),f.continue_game)
	resume.disabled=not FileAccess.file_exists(g.RunStorage.PATH)
	action(canvas,"Catalog","조합 도감",Rect2(83,1327,433,108),f.title_catalog)
	action(canvas,"Settings","설정",Rect2(544,1327,423,108),f.title_settings)
	return outer
static func result(g: Control, f: RefCounted) -> PanelContainer:
	var kind: String="victory" if g.victory else "defeat"
	var outer := create(g,kind,320)
	var canvas := canvas_of(outer)
	var source: Texture2D=load(SOURCES[kind])
	# A blank vertical strip includes the original divider lines and panel shading.
	# Stretch only this empty strip over the example numbers; preserve all artwork.
	var top: float=710.0 if g.victory else 750.0
	var height: float=250.0 if g.victory else 235.0
	var sample := AtlasTexture.new()
	sample.atlas=source
	sample.region=Rect2(550,top,20,height)
	var cover := TextureRect.new()
	cover.texture=sample
	cover.position=Vector2(590,top)
	cover.size=Vector2(357,height)
	cover.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode=TextureRect.STRETCH_SCALE
	cover.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(cover)
	var ys: Array=[720,800,880] if g.victory else [750,831,912]
	var values: Array=[g.difficulty,"%d / 80" % g.wave,"%d / 8" % g.bosses_defeated]
	for i in range(3):
		var value := ScoreValue.new()
		value.position=Vector2(600,float(ys[i]))
		value.size=Vector2(330,75)
		value.text=str(values[i])
		value.ink=(Color("#ffe48c") if g.victory else Color("#ff8a8d")) if i==0 else Color("#fff9ef")
		value.name=["DifficultyValue","WaveValue","BossValue"][i]
		value.mouse_filter=Control.MOUSE_FILTER_IGNORE
		canvas.add_child(value)
	action(canvas,"Retry","다시하기",Rect2(95,993 if g.victory else 1024,835,169 if g.victory else 153),f.new_game)
	action(canvas,"Difficulty","난이도 선택으로 이동",Rect2(130,1182 if g.victory else 1190,760,74),f.new_game)
	action(canvas,"Home","시작 화면",Rect2(112,1267 if g.victory else 1280,801,121),f.go_home)
	return outer
