@tool
class_name M3Snackbar
extends PanelContainer

signal action_pressed
signal dismissed

@export var message: String = "Snackbar message":
	set(value):
		message = value
		_update_ui()

@export var action_label: String = "":
	set(value):
		action_label = value
		if action_text != value:
			action_text = value
		_update_ui()

@export var action_text: String = "":
	set(value):
		action_text = value
		if action_label != value:
			action_label = value
		_update_ui()

@export var duration: float = 0.0:
	set(value):
		duration = maxf(0.0, value)
		if _timer and is_inside_tree():
			if duration > 0.0:
				_timer.wait_time = duration
				_timer.start()
			else:
				_timer.stop()

@export var show_close_button: bool = false:
	set(value):
		show_close_button = value
		if show_close_icon != value:
			show_close_icon = value
		_update_ui()

@export var show_close_icon: bool = false:
	set(value):
		show_close_icon = value
		if show_close_button != value:
			show_close_button = value
		_update_ui()

var open_progress: float = 1.0
var is_open: bool = true
var action_click_count: int = 0
var free_on_dismiss: bool = false

var _label: Label
var _action_btn: Button
var _close_btn: Button
var _timer: Timer
var _tween: Tween
var _rest_y: float = 0.0
var _has_rest_y: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(320, 48)
	size = custom_minimum_size
	mouse_filter = MOUSE_FILTER_STOP

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	_apply_styling()
	_update_ui()
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))

	_timer = Timer.new()
	_timer.name = "AutoDismissTimer"
	_timer.one_shot = true
	_timer.timeout.connect(dismiss)
	add_child(_timer)
	if duration > 0.0 and is_inside_tree():
		_timer.wait_time = duration
		_timer.start()

func _exit_tree() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.disconnect(_on_theme_changed)

func _setup_theme_listener() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and not mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.connect(_on_theme_changed)

func _on_theme_changed() -> void:
	_apply_styling()
	queue_redraw()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func get_action_button() -> Button:
	return _action_btn

func get_close_button() -> Button:
	return _close_btn

func _build_ui() -> void:
	for c in get_children():
		if c != _timer:
			c.queue_free()

	var margin := MarginContainer.new()
	margin.name = "ContentMargin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.name = "ContentRow"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	_label = Label.new()
	_label.name = "MessageLabel"
	_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(_label)

	_action_btn = Button.new()
	_action_btn.name = "ActionButton"
	_action_btn.flat = true
	_action_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_action_btn.pressed.connect(_on_action_clicked)
	hbox.add_child(_action_btn)

	_close_btn = Button.new()
	_close_btn.name = "CloseButton"
	_close_btn.text = "✕"
	_close_btn.flat = true
	_close_btn.custom_minimum_size = Vector2(36, 36)
	_close_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_close_btn.visible = show_close_button
	_close_btn.pressed.connect(dismiss)
	hbox.add_child(_close_btn)

func _update_ui() -> void:
	if not _label:
		return
	_label.text = message
	_action_btn.text = action_label
	_action_btn.visible = action_label != ""
	_close_btn.visible = show_close_button

func _apply_styling() -> void:
	var s := get_scheme()
	var sb := StyleBoxFlat.new()
	sb.bg_color = s.inverse_surface
	sb.set_corner_radius_all(4)
	sb.shadow_size = 6
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_offset = Vector2(0, 3)
	add_theme_stylebox_override("panel", sb)

	if _label:
		_label.add_theme_color_override("font_color", s.inverse_on_surface)
	if _action_btn:
		_action_btn.add_theme_color_override("font_color", s.inverse_primary)
		_action_btn.add_theme_color_override("font_hover_color", s.inverse_primary)
		_action_btn.add_theme_color_override("font_pressed_color", s.inverse_primary)
		_action_btn.add_theme_color_override("font_focus_color", s.inverse_primary)
	if _close_btn:
		_close_btn.add_theme_color_override("font_color", s.inverse_on_surface)
		_close_btn.add_theme_color_override("font_hover_color", s.inverse_on_surface)
		_close_btn.add_theme_color_override("font_pressed_color", s.inverse_on_surface)

func _on_action_clicked() -> void:
	action_click_count += 1
	action_pressed.emit()
	dismiss()

func _set_open_progress(val: float) -> void:
	open_progress = val
	modulate.a = clampf(val, 0.0, 1.0)
	queue_redraw()

func show_snackbar() -> void:
	show_animated()

func show_animated() -> void:
	visible = true
	is_open = true
	if not is_inside_tree():
		_set_open_progress(1.0)
		return
	var target_y: float = _rest_y if _has_rest_y else position.y
	_rest_y = target_y
	_has_rest_y = true
	_set_open_progress(0.0)
	position.y = target_y + 20.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_set_open_progress, 0.0, 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", target_y, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if _timer and duration > 0.0:
		_timer.wait_time = duration
		_timer.start()

func dismiss() -> void:
	if _timer:
		_timer.stop()
	is_open = false
	if not is_inside_tree():
		_set_open_progress(0.0)
		visible = false
		dismissed.emit()
		if free_on_dismiss:
			queue_free()
		return
	var base_y: float = _rest_y if _has_rest_y else position.y
	_rest_y = base_y
	_has_rest_y = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_set_open_progress, open_progress, 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "position:y", base_y + 20.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(func() -> void:
		visible = false
		dismissed.emit()
		if free_on_dismiss:
			queue_free()
	)

static func show_message(parent: Node, msg: String, action: String = "", on_action: Callable = Callable(), dur: float = 4.0) -> M3Snackbar:
	var snackbar := M3Snackbar.new()
	snackbar.message = msg
	snackbar.action_label = action
	snackbar.duration = dur
	snackbar.free_on_dismiss = true

	var vp_size: Vector2 = parent.get_viewport().get_visible_rect().size if parent.get_viewport() else Vector2(1280, 720)
	snackbar.position = Vector2((vp_size.x - 320.0) * 0.5, vp_size.y - 72.0)

	if on_action.is_valid():
		snackbar.action_pressed.connect(on_action)

	parent.add_child(snackbar)
	snackbar.show_animated()
	return snackbar
