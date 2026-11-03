extends HSlider
# Touch coordinates are handled directly; desktop mouse and keyboard use HSlider normally.
var active_finger: int = -1
func _set_from_point(point: Vector2) -> void:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * point
	var fraction: float = clampf((local.x-8.0)/maxf(1.0,size.x-16.0),0.0,1.0)
	value = min_value + fraction * (max_value-min_value)
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		active_finger = -1
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if Rect2(Vector2.ZERO,size).has_point(local) or active_finger >= 0:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and active_finger < 0 and Rect2(Vector2.ZERO,size).has_point(local):
			active_finger = event.index
			grab_focus()
			drag_started.emit()
			_set_from_point(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == active_finger:
			_set_from_point(event.position)
			active_finger = -1
			drag_ended.emit(true)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == active_finger:
		_set_from_point(event.position)
		get_viewport().set_input_as_handled()
