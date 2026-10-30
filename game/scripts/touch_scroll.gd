extends ScrollContainer
# Own touch gestures before nested Buttons can consume them. Native mouse/keyboard remain available.
var finger: int = -1
var start_point := Vector2.ZERO
var previous_point := Vector2.ZERO
var offset: float = 0.0
var velocity: float = 0.0
var dragging: bool = false
var tap_button: BaseButton
var last_motion: int = 0
var suppress_emulated_mouse: bool = false
func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	follow_focus = false
	scroll_deadzone = 10
	get_v_scroll_bar().custom_minimum_size.x = 18
func reset_position() -> void:
	velocity = 0.0
	offset = 0.0
	scroll_vertical = 0
func is_interacting() -> bool:
	return finger >= 0 or absf(velocity) > 10.0
func _button_at(node: Node, point: Vector2) -> BaseButton:
	for child in node.get_children():
		if child is Control and not child.is_visible_in_tree(): continue
		var found: BaseButton = _button_at(child, point)
		if found != null: return found
	if node is BaseButton and not node.disabled and node.get_global_rect().has_point(point):
		return node
	return null
func _move_to(value: float) -> void:
	var maximum: float = maxf(0.0,get_v_scroll_bar().max_value-get_v_scroll_bar().page)
	offset = clampf(value,0.0,maximum)
	scroll_vertical = roundi(offset)
	if not is_equal_approx(offset,value): velocity = 0.0
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		finger = -1
		velocity = 0.0
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION and suppress_emulated_mouse:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and get_v_scroll_bar().visible and local.x >= size.x-get_v_scroll_bar().size.x:
			suppress_emulated_mouse = false
			return
		if event.pressed and not Rect2(Vector2.ZERO,size).has_point(local):
			suppress_emulated_mouse = false
		if event.pressed and finger < 0 and Rect2(Vector2.ZERO,size).has_point(local):
			finger = event.index
			start_point = local
			previous_point = local
			offset = float(scroll_vertical)
			velocity = 0.0
			dragging = false
			tap_button = _button_at(self,event.position)
			suppress_emulated_mouse = true
			last_motion = Time.get_ticks_msec()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			finger = -1
			if Time.get_ticks_msec()-last_motion > 120: velocity = 0.0
			if not dragging and is_instance_valid(tap_button) and not tap_button.disabled and tap_button.get_global_rect().has_point(event.position):
				tap_button.pressed.emit()
			if dragging:
				propagate_notification(NOTIFICATION_SCROLL_END)
				scroll_ended.emit()
			tap_button = null
			dragging = false
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		var motion: float = local.y-previous_point.y
		if dragging or absf(local.y-start_point.y) > 10.0:
			if not dragging:
				dragging = true
				propagate_notification(NOTIFICATION_SCROLL_BEGIN)
				scroll_started.emit()
			var elapsed: float = maxf(0.008,float(Time.get_ticks_msec()-last_motion)/1000.0)
			velocity = lerpf(velocity,clampf(-motion/elapsed,-2600.0,2600.0),0.55)
			_move_to(offset-motion)
		previous_point = local
		last_motion = Time.get_ticks_msec()
		get_viewport().set_input_as_handled()
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		velocity = 0.0
		finger = -1
		return
	if finger >= 0 or absf(velocity) < 10.0: return
	_move_to(offset + velocity * minf(delta,0.05))
	velocity *= exp(-6.0 * delta)
