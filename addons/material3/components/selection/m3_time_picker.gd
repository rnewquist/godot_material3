@tool
class_name M3TimePicker
extends M3Control

## Material 3 Time Picker component supporting Dial and Input modes,
## 12-hour (AM/PM) and 24-hour formats, hour/minute selection, and animated clock hand.

enum TimeMode {
	DIAL,
	INPUT
}

signal time_changed(hour: int, minute: int, is_pm: bool)
signal time_confirmed(hour: int, minute: int, is_pm: bool)
signal cancelled()
signal mode_changed(new_mode: TimeMode)

const DIAL_CENTER := Vector2(164.0, 228.0)
const DIAL_RADIUS: float = 128.0
const NUMBER_RADIUS: float = 96.0
const INNER_NUMBER_RADIUS: float = 62.0
const RING_SPLIT_RADIUS: float = 79.0
const HOUR_BOX_RECT := Rect2(24.0, 36.0, 80.0, 56.0)
const MINUTE_BOX_RECT := Rect2(120.0, 36.0, 80.0, 56.0)
const AMPM_BOX_RECT := Rect2(216.0, 36.0, 52.0, 56.0)
const AM_RECT := Rect2(216.0, 36.0, 52.0, 28.0)
const PM_RECT := Rect2(216.0, 64.0, 52.0, 28.0)

@export var time_mode: TimeMode = TimeMode.DIAL:
	set(value):
		if time_mode != value:
			time_mode = value
			_sync_child_visibility()
			_animate_mode_switch()
			mode_changed.emit(time_mode)
			queue_redraw()

@export var mode: TimeMode:
	get:
		return time_mode
	set(value):
		time_mode = value

@export var use_24_hour: bool = false:
	set(value):
		if use_24_hour != value:
			use_24_hour = value
			is_inner_ring = (use_24_hour and not selecting_minutes and selected_hour >= 12)
			dial_hand_length = _compute_target_hand_length()
			queue_redraw()

@export var selected_hour: int = 7:
	set(value):
		var clamped: int = clampi(value, 0 if use_24_hour else 1, 23 if use_24_hour else 12)
		if selected_hour != clamped:
			selected_hour = clamped
			is_inner_ring = (use_24_hour and not selecting_minutes and selected_hour >= 12)
			_sync_input_fields()
			if not selecting_minutes:
				if is_inside_tree():
					_animate_dial_to(_compute_target_angle())
				else:
					dial_angle = _compute_target_angle()
					dial_hand_length = _compute_target_hand_length()
			queue_redraw()

@export var selected_minute: int = 30:
	set(value):
		var clamped: int = clampi(value, 0, 59)
		if selected_minute != clamped:
			selected_minute = clamped
			_sync_input_fields()
			if selecting_minutes:
				if is_inside_tree():
					_animate_dial_to(_compute_target_angle())
				else:
					dial_angle = _compute_target_angle()
					dial_hand_length = _compute_target_hand_length()
			queue_redraw()

@export var is_pm: bool = false:
	set(value):
		if is_pm != value:
			is_pm = value
			queue_redraw()

@export var selecting_minutes: bool = false:
	set(value):
		if selecting_minutes != value:
			selecting_minutes = value
			is_inner_ring = (use_24_hour and not selecting_minutes and selected_hour >= 12)
			if is_inside_tree():
				_animate_dial_to(_compute_target_angle())
			else:
				dial_angle = _compute_target_angle()
				dial_hand_length = _compute_target_hand_length()
			queue_redraw()

@export var is_open: bool = true:
	set(value):
		if is_open != value:
			is_open = value
			if is_inside_tree():
				_animate_open(is_open)
			else:
				open_progress = 1.0 if is_open else 0.0
				visible = is_open
			queue_redraw()

var dial_angle: float = 0.0:
	set(value):
		dial_angle = value
		queue_redraw()

var is_inner_ring: bool = false

var dial_hand_length: float = NUMBER_RADIUS:
	set(value):
		dial_hand_length = value
		queue_redraw()

var mode_anim_progress: float = 1.0:
	set(value):
		mode_anim_progress = value
		queue_redraw()

var open_progress: float = 1.0:
	set(value):
		open_progress = value
		queue_redraw()

var _dial_tween: Tween = null
var _mode_tween: Tween = null
var _open_tween: Tween = null
var _font: Font = null
var _dragging_dial: bool = false

var _mode_toggle_btn: M3IconButton = null
var _hour_input_field: M3TextField = null
var _minute_input_field: M3TextField = null
var _cancel_btn: M3Button = null
var _confirm_btn: M3Button = null

func _init() -> void:
	super._init()
	ripple_enabled = false
	shape_token = M3Shapes.ShapeToken.EXTRA_LARGE
	custom_minimum_size = Vector2(328.0, 420.0)
	size = custom_minimum_size
	is_inner_ring = (use_24_hour and not selecting_minutes and selected_hour >= 12)
	dial_angle = _compute_target_angle()
	dial_hand_length = _compute_target_hand_length()

func _ready() -> void:
	super._ready()
	_font = ThemeDB.fallback_font
	is_inner_ring = (use_24_hour and not selecting_minutes and selected_hour >= 12)
	dial_angle = _compute_target_angle()
	dial_hand_length = _compute_target_hand_length()
	open_progress = 1.0 if is_open else 0.0
	visible = is_open
	_setup_children()
	_layout_children()
	_sync_child_visibility()
	_sync_input_fields()

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_font = ThemeDB.fallback_font
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_children()

func _setup_children() -> void:
	if _mode_toggle_btn == null:
		_mode_toggle_btn = get_node_or_null(^"ModeToggleButton") as M3IconButton
		if _mode_toggle_btn == null:
			_mode_toggle_btn = M3IconButton.new()
			_mode_toggle_btn.name = "ModeToggleButton"
			add_child(_mode_toggle_btn)
		_mode_toggle_btn.variant = M3IconButton.Variant.STANDARD
		if not _mode_toggle_btn.pressed.is_connected(_on_mode_toggle_pressed):
			_mode_toggle_btn.pressed.connect(_on_mode_toggle_pressed)
		if not _mode_toggle_btn.draw.is_connected(_on_mode_btn_draw):
			_mode_toggle_btn.draw.connect(_on_mode_btn_draw)

	if _hour_input_field == null:
		_hour_input_field = get_node_or_null(^"HourInputField") as M3TextField
		if _hour_input_field == null:
			_hour_input_field = M3TextField.new()
			_hour_input_field.name = "HourInputField"
			_hour_input_field.variant = M3TextField.Variant.OUTLINED
			_hour_input_field.label = "Hour"
			_hour_input_field.helper_text = "Hour"
			_hour_input_field.text = "%02d" % selected_hour
			add_child(_hour_input_field)
		if not _hour_input_field.text_changed.is_connected(_on_hour_input_changed):
			_hour_input_field.text_changed.connect(_on_hour_input_changed)

	if _minute_input_field == null:
		_minute_input_field = get_node_or_null(^"MinuteInputField") as M3TextField
		if _minute_input_field == null:
			_minute_input_field = M3TextField.new()
			_minute_input_field.name = "MinuteInputField"
			_minute_input_field.variant = M3TextField.Variant.OUTLINED
			_minute_input_field.label = "Minute"
			_minute_input_field.helper_text = "Minute"
			_minute_input_field.text = "%02d" % selected_minute
			add_child(_minute_input_field)
		if not _minute_input_field.text_changed.is_connected(_on_minute_input_changed):
			_minute_input_field.text_changed.connect(_on_minute_input_changed)

	if _cancel_btn == null:
		_cancel_btn = get_node_or_null(^"CancelButton") as M3Button
		if _cancel_btn == null:
			_cancel_btn = M3Button.new()
			_cancel_btn.name = "CancelButton"
			add_child(_cancel_btn)
		_cancel_btn.variant = M3Button.Variant.TEXT
		_cancel_btn.text = "Cancel"
		if not _cancel_btn.pressed.is_connected(_on_cancel_pressed):
			_cancel_btn.pressed.connect(_on_cancel_pressed)

	if _confirm_btn == null:
		_confirm_btn = get_node_or_null(^"ConfirmButton") as M3Button
		if _confirm_btn == null:
			_confirm_btn = M3Button.new()
			_confirm_btn.name = "ConfirmButton"
			add_child(_confirm_btn)
		_confirm_btn.variant = M3Button.Variant.TEXT
		_confirm_btn.text = "OK"
		if not _confirm_btn.pressed.is_connected(_on_confirm_pressed):
			_confirm_btn.pressed.connect(_on_confirm_pressed)

func _layout_children() -> void:
	var w: float = maxf(size.x, 328.0)
	var h: float = maxf(size.y, 420.0)
	if _mode_toggle_btn != null:
		_mode_toggle_btn.position = Vector2(16.0, h - 52.0)
		_mode_toggle_btn.size = Vector2(40.0, 40.0)
	if _hour_input_field != null:
		_hour_input_field.position = Vector2(24.0, 128.0)
		_hour_input_field.size = Vector2(130.0, 76.0)
	if _minute_input_field != null:
		_minute_input_field.position = Vector2(174.0, 128.0)
		_minute_input_field.size = Vector2(130.0, 76.0)
	if _cancel_btn != null:
		_cancel_btn.position = Vector2(w - 160.0, h - 52.0)
		_cancel_btn.size = Vector2(72.0, 40.0)
	if _confirm_btn != null:
		_confirm_btn.position = Vector2(w - 80.0, h - 52.0)
		_confirm_btn.size = Vector2(64.0, 40.0)

func _sync_child_visibility() -> void:
	var is_input: bool = (time_mode == TimeMode.INPUT)
	if _hour_input_field != null:
		_hour_input_field.visible = is_input
	if _minute_input_field != null:
		_minute_input_field.visible = is_input
	if _mode_toggle_btn != null:
		_mode_toggle_btn.queue_redraw()

func _sync_input_fields() -> void:
	if _hour_input_field != null:
		var h_str: String = "%02d" % selected_hour
		if _hour_input_field.text != h_str:
			_hour_input_field.text = h_str
	if _minute_input_field != null:
		var m_str: String = "%02d" % selected_minute
		if _minute_input_field.text != m_str:
			_minute_input_field.text = m_str

func _on_mode_btn_draw() -> void:
	if _mode_toggle_btn == null:
		return
	var col := get_m3_color(&"on_surface_variant")
	var c := _mode_toggle_btn.size * 0.5
	if time_mode == TimeMode.DIAL:
		# Keyboard icon
		var kr := Rect2(c - Vector2(9.0, 6.0), Vector2(18.0, 12.0))
		_mode_toggle_btn.draw_rect(kr, col, false, 1.8)
		for kx in [-5.0, 0.0, 5.0]:
			_mode_toggle_btn.draw_circle(c + Vector2(kx, -2.0), 1.0, col)
		_mode_toggle_btn.draw_line(c + Vector2(-5.0, 3.0), c + Vector2(5.0, 3.0), col, 1.8)
	else:
		# Schedule / clock icon
		_mode_toggle_btn.draw_arc(c, 8.5, 0.0, TAU, 24, col, 1.8, true)
		_mode_toggle_btn.draw_line(c, c + Vector2(0.0, -5.0), col, 1.8, true)
		_mode_toggle_btn.draw_line(c, c + Vector2(4.0, 2.0), col, 1.8, true)

func _on_mode_toggle_pressed() -> void:
	if time_mode == TimeMode.DIAL:
		time_mode = TimeMode.INPUT
	else:
		time_mode = TimeMode.DIAL

func _on_hour_input_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		var h: int = new_text.to_int()
		var min_h: int = 0 if use_24_hour else 1
		var max_h: int = 23 if use_24_hour else 12
		if h >= min_h and h <= max_h and h != selected_hour:
			selected_hour = h
			time_changed.emit(selected_hour, selected_minute, is_pm)

func _on_minute_input_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		var m: int = new_text.to_int()
		if m >= 0 and m <= 59 and m != selected_minute:
			selected_minute = m
			time_changed.emit(selected_hour, selected_minute, is_pm)

func _on_cancel_pressed() -> void:
	cancelled.emit()
	close()

func _on_confirm_pressed() -> void:
	time_confirmed.emit(selected_hour, selected_minute, is_pm)

func open() -> void:
	is_open = true

func close() -> void:
	is_open = false

func _compute_target_angle() -> float:
	if selecting_minutes:
		return float(selected_minute % 60) * (TAU / 60.0) - PI * 0.5
	return float(selected_hour % 12) * (TAU / 12.0) - PI * 0.5

func _compute_target_hand_length() -> float:
	if selecting_minutes:
		return NUMBER_RADIUS
	if use_24_hour and selected_hour >= 12:
		return INNER_NUMBER_RADIUS
	return NUMBER_RADIUS

## Returns the local coordinates of `hour` (1..12 or 0..23 in 24-hour mode) on the clock dial face.
func get_dial_hour_position(hour: int) -> Vector2:
	var angle: float = float(hour % 12) * (TAU / 12.0) - PI * 0.5
	var rad: float = INNER_NUMBER_RADIUS if (use_24_hour and hour >= 12) else NUMBER_RADIUS
	return DIAL_CENTER + Vector2(cos(angle), sin(angle)) * rad

## Returns the local coordinates of `minute` (0..59) on the clock dial face.
func get_dial_minute_position(minute: int) -> Vector2:
	var angle: float = float(minute % 60) * (TAU / 60.0) - PI * 0.5
	return DIAL_CENTER + Vector2(cos(angle), sin(angle)) * NUMBER_RADIUS

func _animate_dial_to(target_angle: float) -> void:
	is_inner_ring = (use_24_hour and not selecting_minutes and selected_hour >= 12)
	var target_len: float = _compute_target_hand_length()
	if _dial_tween != null and _dial_tween.is_valid():
		_dial_tween.kill()
	_dial_tween = create_tween().set_parallel(true)
	if _dial_tween:
		_dial_tween.bind_node(self)
		_dial_tween.set_trans(Tween.TRANS_CUBIC)
		_dial_tween.set_ease(Tween.EASE_OUT)
		_dial_tween.tween_property(self, ^"dial_angle", target_angle, 0.22)
		_dial_tween.tween_property(self, ^"dial_hand_length", target_len, 0.22)
		_dial_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.22)

func _animate_mode_switch() -> void:
	mode_anim_progress = 0.0
	if _mode_tween != null and _mode_tween.is_valid():
		_mode_tween.kill()
	_mode_tween = create_tween().set_parallel(true)
	if _mode_tween:
		_mode_tween.bind_node(self)
		_mode_tween.set_trans(Tween.TRANS_CUBIC)
		_mode_tween.set_ease(Tween.EASE_OUT)
		_mode_tween.tween_property(self, ^"mode_anim_progress", 1.0, 0.2)
		_mode_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)

func _animate_open(opening: bool) -> void:
	visible = true
	var target: float = 1.0 if opening else 0.0
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true)
	if _open_tween:
		_open_tween.bind_node(self)
		_open_tween.set_trans(Tween.TRANS_CUBIC)
		_open_tween.set_ease(Tween.EASE_OUT)
		_open_tween.tween_property(self, ^"open_progress", target, 0.22)
		_open_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.22)

func _select_from_dial_point(pos: Vector2) -> void:
	var delta: Vector2 = pos - DIAL_CENTER
	if delta.length() < 8.0:
		return
	var raw_angle: float = atan2(delta.y, delta.x)
	var normalized: float = fposmod(raw_angle + PI * 0.5, TAU)
	if selecting_minutes:
		var m: int = int(round(normalized / (TAU / 60.0))) % 60
		selected_minute = m
		_animate_dial_to(_compute_target_angle())
		time_changed.emit(selected_hour, selected_minute, is_pm)
	else:
		var slot: int = int(round(normalized / (TAU / 12.0))) % 12
		var h: int = slot
		if use_24_hour:
			var inner: bool = (delta.length() < RING_SPLIT_RADIUS)
			h = (slot + 12) if inner else slot
		else:
			if h == 0:
				h = 12
		selected_hour = h
		_animate_dial_to(_compute_target_angle())
		time_changed.emit(selected_hour, selected_minute, is_pm)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if HOUR_BOX_RECT.has_point(mb.position):
					selecting_minutes = false
					accept_event()
					return
				if MINUTE_BOX_RECT.has_point(mb.position):
					selecting_minutes = true
					accept_event()
					return
				if not use_24_hour:
					if AM_RECT.has_point(mb.position):
						if is_pm:
							is_pm = false
							time_changed.emit(selected_hour, selected_minute, is_pm)
						accept_event()
						return
					if PM_RECT.has_point(mb.position):
						if not is_pm:
							is_pm = true
							time_changed.emit(selected_hour, selected_minute, is_pm)
						accept_event()
						return
				if time_mode == TimeMode.DIAL and mb.position.distance_to(DIAL_CENTER) <= DIAL_RADIUS:
					_dragging_dial = true
					_select_from_dial_point(mb.position)
					accept_event()
					return
			else:
				_dragging_dial = false
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging_dial and time_mode == TimeMode.DIAL:
			_select_from_dial_point(mm.position)
			accept_event()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var surf_high := get_m3_color(&"surface_container_high")
	var surf_highest := get_m3_color(&"surface_container_highest")
	var on_surf := get_m3_color(&"on_surface")
	var on_surf_var := get_m3_color(&"on_surface_variant")
	var primary_col := get_m3_color(&"primary")
	var on_primary_col := get_m3_color(&"on_primary")
	var primary_container := get_m3_color(&"primary_container")
	var on_primary_container := get_m3_color(&"on_primary_container")
	var tertiary_container := get_m3_color(&"tertiary_container")
	var on_tertiary_container := get_m3_color(&"on_tertiary_container")
	var outline_col := get_m3_color(&"outline")

	# 1. Container surface (28dp corner radius per M3 Time Picker spec)
	var sb := StyleBoxFlat.new()
	sb.bg_color = surf_high
	sb.set_corner_radius_all(28)
	sb.shadow_color = Color(0, 0, 0, 0.22 * open_progress)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	draw_style_box(sb, r)

	if _font == null:
		return

	# 2. Overline label
	var overline_str: String = "Enter time" if time_mode == TimeMode.INPUT else "Select time"
	draw_string(_font, Vector2(24.0, 24.0), overline_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, on_surf_var)

	# 3. Digital Time Selector Header (Hour box : Minute box + AM/PM toggle)
	var hour_sb := StyleBoxFlat.new()
	hour_sb.bg_color = primary_container if not selecting_minutes else surf_highest
	hour_sb.set_corner_radius_all(8)
	draw_style_box(hour_sb, HOUR_BOX_RECT)

	var hour_str: String = "%02d" % selected_hour
	var hour_col: Color = on_primary_container if not selecting_minutes else on_surf
	var hw: float = _font.get_string_size(hour_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var hy: float = HOUR_BOX_RECT.position.y + (HOUR_BOX_RECT.size.y - _font.get_height(28)) * 0.5 + _font.get_ascent(28)
	draw_string(_font, Vector2(HOUR_BOX_RECT.get_center().x - hw * 0.5, hy), hour_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, hour_col)

	# Colon separator
	var colon_w: float = _font.get_string_size(":", HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	draw_string(_font, Vector2(112.0 - colon_w * 0.5, hy), ":", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, on_surf)

	var min_sb := StyleBoxFlat.new()
	min_sb.bg_color = primary_container if selecting_minutes else surf_highest
	min_sb.set_corner_radius_all(8)
	draw_style_box(min_sb, MINUTE_BOX_RECT)

	var min_str: String = "%02d" % selected_minute
	var min_col: Color = on_primary_container if selecting_minutes else on_surf
	var mw: float = _font.get_string_size(min_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	draw_string(_font, Vector2(MINUTE_BOX_RECT.get_center().x - mw * 0.5, hy), min_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, min_col)

	# AM / PM vertical segmented toggle
	if not use_24_hour:
		var am_sb := StyleBoxFlat.new()
		am_sb.bg_color = tertiary_container if not is_pm else Color.TRANSPARENT
		am_sb.corner_radius_top_left = 8
		am_sb.corner_radius_top_right = 8
		draw_style_box(am_sb, AM_RECT)

		var pm_sb := StyleBoxFlat.new()
		pm_sb.bg_color = tertiary_container if is_pm else Color.TRANSPARENT
		pm_sb.corner_radius_bottom_left = 8
		pm_sb.corner_radius_bottom_right = 8
		draw_style_box(pm_sb, PM_RECT)

		var border_sb := StyleBoxFlat.new()
		border_sb.bg_color = Color.TRANSPARENT
		border_sb.border_color = outline_col
		border_sb.set_border_width_all(1)
		border_sb.set_corner_radius_all(8)
		draw_style_box(border_sb, AMPM_BOX_RECT)
		draw_line(Vector2(AMPM_BOX_RECT.position.x, AM_RECT.end.y), Vector2(AMPM_BOX_RECT.end.x, AM_RECT.end.y), outline_col, 1.0)

		var am_col: Color = on_tertiary_container if not is_pm else on_surf_var
		var pm_col: Color = on_tertiary_container if is_pm else on_surf_var
		var am_w: float = _font.get_string_size("AM", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var pm_w: float = _font.get_string_size("PM", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var am_y: float = AM_RECT.position.y + (AM_RECT.size.y - _font.get_height(13)) * 0.5 + _font.get_ascent(13)
		var pm_y: float = PM_RECT.position.y + (PM_RECT.size.y - _font.get_height(13)) * 0.5 + _font.get_ascent(13)
		draw_string(_font, Vector2(AM_RECT.get_center().x - am_w * 0.5, am_y), "AM", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, am_col)
		draw_string(_font, Vector2(PM_RECT.get_center().x - pm_w * 0.5, pm_y), "PM", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, pm_col)

	if time_mode != TimeMode.DIAL:
		return

	# 4. Clock Dial Face (256x256 circular surface_container_highest)
	draw_circle(DIAL_CENTER, DIAL_RADIUS, surf_highest)

	# 5. Clock Hand & Selector Bob
	var hand_dir := Vector2(cos(dial_angle), sin(dial_angle))
	var hand_len: float = dial_hand_length if (use_24_hour and not selecting_minutes) else NUMBER_RADIUS
	var bob_pos := DIAL_CENTER + hand_dir * hand_len
	var bob_radius: float = 17.0 if (use_24_hour and not selecting_minutes and hand_len < RING_SPLIT_RADIUS) else 20.0
	draw_circle(DIAL_CENTER, 4.0, primary_col)
	draw_line(DIAL_CENTER, bob_pos, primary_col, 2.0, true)
	draw_circle(bob_pos, bob_radius, primary_col)

	# 6. Clock Dial Numbers (12 hours, 24-hour dual ring, or 00..55 minutes)
	for i in range(12):
		var a: float = float(i) * (TAU / 12.0) - PI * 0.5
		var npos := DIAL_CENTER + Vector2(cos(a), sin(a)) * NUMBER_RADIUS
		var label_str: String = ""
		if selecting_minutes:
			label_str = "%02d" % (i * 5)
		elif use_24_hour:
			label_str = "00" if i == 0 else str(i)
		else:
			var h_val: int = 12 if i == 0 else i
			label_str = str(h_val)

		var is_under_bob: bool = npos.distance_to(bob_pos) < 16.0
		var num_col: Color = on_primary_col if is_under_bob else on_surf
		var nw: float = _font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var ny: float = npos.y - _font.get_height(14) * 0.5 + _font.get_ascent(14)
		draw_string(_font, Vector2(npos.x - nw * 0.5, ny), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, num_col)

		if use_24_hour and not selecting_minutes:
			var ipos := DIAL_CENTER + Vector2(cos(a), sin(a)) * INNER_NUMBER_RADIUS
			var ih_val: int = 12 if i == 0 else (i + 12)
			var ilabel: String = str(ih_val)
			var inner_under_bob: bool = ipos.distance_to(bob_pos) < 15.0
			var inum_col: Color = on_primary_col if inner_under_bob else on_surf_var
			var inw: float = _font.get_string_size(ilabel, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var iny: float = ipos.y - _font.get_height(12) * 0.5 + _font.get_ascent(12)
			draw_string(_font, Vector2(ipos.x - inw * 0.5, iny), ilabel, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, inum_col)
