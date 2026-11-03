extends Control
var text: String = ""
var ink: Color = Color.WHITE
func _draw() -> void:
	var font: Font=get_theme_font("font","Label")
	var point_size: int=58
	while point_size>36 and font.get_height(point_size)>size.y:
		point_size-=1
	var baseline: float=(size.y-font.get_height(point_size))*0.5+font.get_ascent(point_size)
	draw_string(font,Vector2(0,baseline),text,HORIZONTAL_ALIGNMENT_RIGHT,size.x,point_size,ink)
