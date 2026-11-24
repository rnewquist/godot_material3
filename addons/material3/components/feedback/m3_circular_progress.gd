@tool
class_name M3CircularProgress
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

@export var stroke_width: float = 4.0:
	set(val):
		stroke_width = maxf(2.0, val)
		queue_redraw()

@export var show_track: bool = true:
	set(val):
		show_track = val
		queue_redraw()

@export var wavy: bool = false:
	set(val):
		wavy = val
		_update_processing()
		queue_redraw()

@export var wave_amplitude: float = 2.0:
	set(val):
		wave_amplitude = maxf(0.5, val)
		queue_redraw()

@export var wave_cycles: int = 8:
	set(val):
		wave_cycles = maxi(1, val)
		queue_redraw()

@export var wave_speed: float = 5.0:
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
	custom_minimum_size = Vector2(48, 48)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	if _ripple_effect:
		_ripple_effect.visible = false
		_ripple_effect.mouse_filter = MOUSE_FILTER_IGNORE
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
	_set_displayed_value(value)
	_update_processing()

func _update_processing() -> void:
	set_process(indeterminate or wavy)

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
		_indeterminate_time += delta * 2.0
		_anim_time = _indeterminate_time
		_indeterminate_phase = fmod(_indeterminate_time * 2.5, TAU) / TAU
		needs_redraw = true
	if wavy:
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

func _draw_wavy_arc(center: Vector2, base_radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var span: float = end_angle - start_angle
	if absf(span) <= 0.01:
		return
	var steps: int = maxi(24, int(ceil((absf(span) / TAU) * 96.0)))
	var cycles: float = float(maxi(1, wave_cycles))
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var theta: float = start_angle + span * t
		var r: float = base_radius + sin(theta * cycles + _wave_phase) * wave_amplitude
		pts.append(center + Vector2(cos(theta), sin(theta)) * r)
	if pts.size() >= 2:
		draw_polyline(pts, color, stroke_width, true)
		draw_circle(pts[0], stroke_width * 0.5, color)
		draw_circle(pts[pts.size() - 1], stroke_width * 0.5, color)

func _draw() -> void:
	var s := get_scheme()
	var center := size * 0.5
	var radius := (minf(size.x, size.y) - stroke_width) * 0.5
	if wavy:
		radius = maxf(4.0, radius - wave_amplitude)
	if radius <= 0.0:
		return

	# Draw Track if enabled
	if show_track:
		draw_arc(center, radius, 0.0, TAU, 64, s.surface_container_highest, stroke_width, false)

	# Draw Indicator Arc
	if not indeterminate:
		var sweep := TAU * _animated_val
		if sweep > 0.01:
			var start_angle := -PI * 0.5
			var end_angle := start_angle + sweep
			if wavy:
				_draw_wavy_arc(center, radius, start_angle, end_angle, s.primary)
			else:
				draw_arc(center, radius, start_angle, end_angle, 64, s.primary, stroke_width, false)
	else:
		var rotation_angle := fmod(_indeterminate_time * 2.5, TAU) - PI * 0.5
		var cycle := (sin(_indeterminate_time * 2.0) + 1.0) * 0.5
		var sweep_len := lerpf(0.15 * TAU, 0.75 * TAU, cycle)
		if wavy:
			_draw_wavy_arc(center, radius, rotation_angle, rotation_angle + sweep_len, s.primary)
		else:
			draw_arc(center, radius, rotation_angle, rotation_angle + sweep_len, 64, s.primary, stroke_width, false)
