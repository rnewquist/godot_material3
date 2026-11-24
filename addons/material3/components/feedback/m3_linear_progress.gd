@tool
class_name M3LinearProgress
extends M3BaseControl

@export var indeterminate: bool = false:
	set(val):
		indeterminate = val
		_update_processing()
		queue_redraw()

@export_range(0.0, 1.0) var value: float = 0.0:
	set(new_val):
		var clamped := clampf(new_val, 0.0, 1.0)
		if not is_equal_approx(value, clamped):
			value = clamped
			if _suppress_tween:
				return
			if is_inside_tree() and not indeterminate:
				_animate_value(0.25)
			else:
				_set_displayed_value(value)

@export var track_height: float = 4.0:
	set(val):
		track_height = maxf(2.0, val)
		_sync_minimum_height()
		queue_redraw()

@export var track_gap: float = 4.0:
	set(val):
		track_gap = maxf(0.0, val)
		queue_redraw()

@export var show_stop_indicator: bool = true:
	set(val):
		show_stop_indicator = val
		queue_redraw()

@export var stop_indicator_size: float = 4.0:
	set(val):
		stop_indicator_size = maxf(2.0, val)
		queue_redraw()

@export var wavy: bool = false:
	set(val):
		wavy = val
		_sync_minimum_height()
		_update_processing()
		queue_redraw()

@export var wave_amplitude: float = 3.0:
	set(val):
		wave_amplitude = maxf(0.5, val)
		_sync_minimum_height()
		queue_redraw()

@export var wave_wavelength: float = 24.0:
	set(val):
		wave_wavelength = maxf(4.0, val)
		queue_redraw()

@export var wave_speed: float = 6.0:
	set(val):
		wave_speed = val
		queue_redraw()

var displayed_value: float = 0.0
var _animated_val: float = 0.0
var _tween: Tween
var _suppress_tween: bool = false
var _indeterminate_time: float = 0.0
var _anim_time: float = 0.0
var _indeterminate_phase: float = 0.0
var _wave_phase: float = 0.0

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	custom_minimum_size = Vector2(200, 4)
	size = custom_minimum_size
	size_flags_horizontal = SIZE_EXPAND_FILL

func _ready() -> void:
	super._ready()
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	if _ripple_effect:
		_ripple_effect.visible = false
		_ripple_effect.mouse_filter = MOUSE_FILTER_IGNORE
	_sync_minimum_height()
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
	_set_displayed_value(value)
	_update_processing()

func _update_processing() -> void:
	set_process(indeterminate or wavy)

func _sync_minimum_height() -> void:
	var min_h: float = _get_minimum_size().y
	custom_minimum_size.y = min_h
	if size.y < min_h:
		size.y = min_h
	update_minimum_size()

func _get_minimum_size() -> Vector2:
	if wavy:
		return Vector2(0.0, maxf(track_height + wave_amplitude * 2.5, 12.0))
	return Vector2(0.0, track_height)

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func set_value_immediate(target: float) -> void:
	var clamped := clampf(target, 0.0, 1.0)
	if _tween and _tween.is_valid():
		_tween.kill()
	_suppress_tween = true
	value = clamped
	_suppress_tween = false
	_set_displayed_value(clamped)

func set_value_animated(target: float, duration: float = 0.25) -> void:
	var clamped := clampf(target, 0.0, 1.0)
	_suppress_tween = true
	value = clamped
	_suppress_tween = false
	_animate_value(duration)

func _set_displayed_value(v: float) -> void:
	displayed_value = v
	_animated_val = v
	queue_redraw()

func _process(delta: float) -> void:
	var needs_redraw: bool = false
	if indeterminate:
		_indeterminate_time += delta * 1.5
		_anim_time = _indeterminate_time
		_indeterminate_phase = fmod(_indeterminate_time, 2.0) * 0.5
		needs_redraw = true
	if wavy and (indeterminate or displayed_value > 0.0):
		_wave_phase = fmod(_wave_phase + delta * wave_speed, TAU)
		needs_redraw = true
	elif wavy:
		_wave_phase = fmod(_wave_phase + delta * wave_speed, TAU)
		needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _animate_value(duration: float = 0.25) -> void:
	if indeterminate or not is_inside_tree():
		_set_displayed_value(value)
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_displayed_value, displayed_value, value, maxf(0.05, duration)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _draw_wavy_segment(x_start: float, x_end: float, cy: float, color: Color) -> void:
	if x_end - x_start <= 0.5:
		return
	var wl: float = maxf(4.0, wave_wavelength)
	var pts := PackedVector2Array()
	var x: float = x_start
	while x < x_end:
		var wy: float = cy + sin((x / wl) * TAU + _wave_phase) * wave_amplitude
		pts.append(Vector2(x, wy))
		x += 2.0
	var end_y: float = cy + sin((x_end / wl) * TAU + _wave_phase) * wave_amplitude
	pts.append(Vector2(x_end, end_y))
	if pts.size() >= 2:
		draw_polyline(pts, color, track_height, true)
		draw_circle(pts[0], track_height * 0.5, color)
		draw_circle(pts[pts.size() - 1], track_height * 0.5, color)

func _draw() -> void:
	var s := get_scheme()
	var radius: float = track_height * 0.5
	var y: float = (size.y - track_height) * 0.5
	var cy: float = size.y * 0.5

	if not indeterminate:
		var fill_w: float = clampf(size.x * _animated_val, 0.0, size.x)
		var gap: float = track_gap if (fill_w > 0.5 and fill_w < size.x - 0.5) else 0.0
		var track_x: float = minf(size.x, fill_w + gap) if fill_w > 0.5 else 0.0
		var track_w: float = maxf(0.0, size.x - track_x)

		# Draw inactive track segment (after active indicator + track_gap)
		if track_w > 0.5:
			var track_rect := Rect2(Vector2(track_x, y), Vector2(track_w, track_height))
			var track_sb := create_stylebox(s.surface_container_highest, radius)
			draw_style_box(track_sb, track_rect)

		# Draw active indicator segment
		if fill_w > 0.5:
			if wavy:
				var x0: float = minf(radius, fill_w * 0.5)
				var x1: float = maxf(x0 + 0.5, fill_w - radius)
				_draw_wavy_segment(x0, x1, cy, s.primary)
			else:
				var fill_rect := Rect2(Vector2(0, y), Vector2(fill_w, track_height))
				var fill_sb := create_stylebox(s.primary, radius)
				draw_style_box(fill_sb, fill_rect)

		# Draw M3 2024/2025 stop indicator dot at end of track
		if show_stop_indicator and _animated_val < 0.999 and size.x >= stop_indicator_size:
			var stop_r: float = stop_indicator_size * 0.5
			var stop_center := Vector2(size.x - stop_r, y + track_height * 0.5)
			draw_circle(stop_center, stop_r, s.primary)
	else:
		# Draw full track
		var track_rect := Rect2(Vector2(0, y), Vector2(size.x, track_height))
		var track_sb := create_stylebox(s.surface_container_highest, radius)
		draw_style_box(track_sb, track_rect)

		var t := fmod(_indeterminate_time, 2.0)
		var h1 := clampf((t * 1.2) - 0.2, 0.0, 1.0)
		var t1 := clampf((t * 1.2) - 0.7, 0.0, 1.0)
		if h1 > t1:
			if wavy:
				_draw_wavy_segment(size.x * t1, size.x * h1, cy, s.primary)
			else:
				var seg1_rect := Rect2(Vector2(size.x * t1, y), Vector2(size.x * (h1 - t1), track_height))
				var seg1_sb := create_stylebox(s.primary, radius)
				draw_style_box(seg1_sb, seg1_rect)

		var t_sub := fmod(_indeterminate_time + 1.0, 2.0)
		var h2 := clampf((t_sub * 1.0) - 0.1, 0.0, 1.0)
		var t2 := clampf((t_sub * 1.0) - 0.5, 0.0, 1.0)
		if h2 > t2:
			if wavy:
				_draw_wavy_segment(size.x * t2, size.x * h2, cy, s.primary)
			else:
				var seg2_rect := Rect2(Vector2(size.x * t2, y), Vector2(size.x * (h2 - t2), track_height))
				var seg2_sb := create_stylebox(s.primary, radius)
				draw_style_box(seg2_sb, seg2_rect)
