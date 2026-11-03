extends RefCounted
# The approved composite is used directly as an atlas: no regeneration or repaint.
# Keep the frame, lettering, dogs and button artwork exactly as supplied.
const SOURCE := "res://assets/screens/approved-layout.png"
const REGIONS := {
	"start":Rect2(20.0/1568.0,60.0/1003.0,495.0/1568.0,874.0/1003.0),
	"victory":Rect2(536.0/1568.0,60.0/1003.0,495.0/1568.0,874.0/1003.0),
	"defeat":Rect2(1053.0/1568.0,60.0/1003.0,495.0/1568.0,874.0/1003.0)
}
static func has_art() -> bool:
	return ResourceLoader.exists(SOURCE)
static func text(parent: Control, value: String, rect: Rect2, size: int, color: Color = Color("#fff4d8")) -> Label:
	var node := Label.new()
	node.text=value
	node.position=rect.position
	node.size=rect.size
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
static func action(parent: Control, name: String, value: String, rect: Rect2, callback: Callable) -> Button:
	var node := Button.new()
	node.name=name
	node.text=value
	node.position=rect.position
	node.size=rect.size
	node.add_theme_font_size_override("font_size",34)
	if has_art():
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color=Color(0.05,0.08,0.15,0.55) if state=="disabled" else Color(1,1,1,0.12) if state=="pressed" else Color(0,0,0,0)
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
	style.bg_color=Color("#101b30")
	outer.add_theme_stylebox_override("panel",style)
	g.add_child(outer)
	var canvas := Control.new()
	canvas.name="Canvas"
	canvas.custom_minimum_size=Vector2(720,1280)
	outer.add_child(canvas)
	if has_art():
		var source: Texture2D=load(SOURCE)
		var normalized: Rect2=REGIONS[kind]
		var atlas := AtlasTexture.new()
		atlas.atlas=source
		atlas.region=Rect2(normalized.position*source.get_size(),normalized.size*source.get_size())
		var art := TextureRect.new()
		art.texture=atlas
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_SCALE
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		canvas.add_child(art)
	else:
		# Functional tests can run before the original artwork is attached.
		text(canvas,"멍랜디" if kind=="start" else "승리" if kind=="victory" else "패배",Rect2(40,80,640,160),64)
	return outer
static func start(g: Control, f: RefCounted) -> PanelContainer:
	var outer := create(g,"start",310)
	var canvas: Control=outer.get_node("Canvas")
	action(canvas,"NewGame","게임 시작",Rect2(58,824,605,140),f.new_game)
	var resume := action(canvas,"Resume","이어하기",Rect2(65,1002,590,104),f.continue_game)
	resume.disabled=not FileAccess.file_exists(g.RunStorage.PATH)
	action(canvas,"Catalog","조합 도감",Rect2(44,1148,294,89),f.title_catalog)
	action(canvas,"Settings","설정",Rect2(382,1148,294,89),f.title_settings)
	return outer
static func result(g: Control, f: RefCounted) -> PanelContainer:
	var outer := create(g,"victory" if g.victory else "defeat",320)
	var canvas: Control=outer.get_node("Canvas")
	# Only the example statistics are covered; all surrounding approved art stays.
	var stats := ColorRect.new()
	stats.position=Vector2(65,675)
	stats.size=Vector2(590,197)
	stats.color=Color("#111b2e")
	stats.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(stats)
	var rows: Array=[["난이도",g.difficulty],["도달 라운드","%d / 80" % g.wave],["처치한 보스","%d / 8" % g.bosses_defeated]]
	for i in range(rows.size()):
		var left := text(stats,str(rows[i][0]),Rect2(12,i*65,280,63),31)
		left.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		var right := text(stats,str(rows[i][1]),Rect2(302,i*65,276,63),34,Color("#ffe197") if i==0 else Color("#fff7e7"))
		right.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	action(canvas,"Retry","다시하기",Rect2(48,917,624,132),f.new_game)
	action(canvas,"Difficulty","난이도 선택으로 이동",Rect2(57,1065,606,65),f.new_game)
	action(canvas,"Home","시작 화면",Rect2(57,1154,606,84),f.go_home)
	return outer
