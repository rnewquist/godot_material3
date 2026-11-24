@tool
class_name M3Ripple
extends Control

## Procedural state layer and ripple wave effect for Material 3 controls.

@export var ripple_color: Color = Color.WHITE:
	set(value):
		ripple_color = value
		queue_redraw()

@export var corner_radius: float = 0.0:
	set(value):
		corner_radius = value
		queue_redraw()

@export var hover_opacity: float = 0.08
@export var focus_opacity: float = 0.10
@export var press_opacity: float = 0.10
@export var dragged_opacity: float = 0.16
@export var bounded: bool = true

var _state_layer_alpha: float = 0.0
var _wave_radius: float = 0.0
var _wave_alpha: float = 0.0
var _wave_count: int = 0
var _is_hovered: bool = false
var _is_focused: bool = false
var _is_pressed: bool = false
var _is_dragged: bool = false

var _state_tween: Tween = null
var _waves: Array[Dictionary] = []

class RippleWave:
	var center: Vector2
	var radius: float = 0.0
	var max_radius: float = 0.0
	var alpha: float = 0.12
	var is_releasing: bool = false
	var tween: Tween = null

var _active_waves: Array[RippleWave] = []

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	clip_contents = bounded

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	clip_contents = bounded
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)

func set_hovered(hovered: bool) -> void:
	if _is_hovered == hovered:
		return
	_is_hovered = hovered
	_update_state_layer()

func set_focused(focused: bool) -> void:
	if _is_focused == focused:
		return
	_is_focused = focused
	_update_state_layer()

func set_pressed_state(pressed: bool) -> void:
	if _is_pressed == pressed:
		return
	_is_pressed = pressed
	_update_state_layer()

func set_dragged(dragged: bool) -> void:
	if _is_dragged == dragged:
		return
	_is_dragged = dragged
	_update_state_layer()

func _update_state_layer() -> void:
	var target_alpha: float = 0.0
	if _is_pressed:
		target_alpha = press_opacity
	elif _is_dragged:
		target_alpha = dragged_opacity
	elif _is_hovered:
		target_alpha = hover_opacity
	elif _is_focused:
		target_alpha = focus_opacity

	if _state_tween != null and _state_tween.is_valid():
		_state_tween.kill()

	_state_tween = create_tween()
	if _state_tween:
		_state_tween.bind_node(self)
		_state_tween.set_parallel(true)
		_state_tween.set_trans(Tween.TRANS_CUBIC)
		_state_tween.set_ease(Tween.EASE_OUT)
		_state_tween.tween_property(self, ^"_state_layer_alpha", target_alpha, 0.15)
		_state_tween.tween_method(func(_val: Variant) -> void: _sync_and_redraw(), 0.0, 1.0, 0.15)
		_state_tween.chain().tween_callback(_sync_and_redraw)

func _sync_and_redraw() -> void:
	_wave_count = _active_waves.size()
	if _active_waves.is_empty():
		_wave_radius = 0.0
		_wave_alpha = 0.0
	else:
		var latest: RippleWave = _active_waves[_active_waves.size() - 1]
		_wave_radius = latest.radius
		_wave_alpha = latest.alpha
	var p: Node = get_parent()
	if p != null:
		if "_state_layer_alpha" in p:
			p.set("_state_layer_alpha", _state_layer_alpha)
		if "_ripple_wave_radius" in p:
			p.set("_ripple_wave_radius", _wave_radius)
		if "_ripple_wave_alpha" in p:
			p.set("_ripple_wave_alpha", _wave_alpha)
		if "_ripple_wave_count" in p:
			p.set("_ripple_wave_count", _wave_count)
	queue_redraw()

func start_press(local_pos: Vector2 = Vector2.ZERO) -> void:
	set_pressed_state(true)
	_spawn_wave(local_pos)

func end_press() -> void:
	set_pressed_state(false)
	_release_all_waves()

func cancel_ripple() -> void:
	set_pressed_state(false)
	set_hovered(false)
	set_focused(false)
	set_dragged(false)
	_release_all_waves()

func _spawn_wave(local_pos: Vector2) -> void:
	var center: Vector2 = local_pos
	if center == Vector2.ZERO or not Rect2(Vector2.ZERO, size).has_point(center):
		center = size * 0.5

	# Calculate max radius to cover all 4 corners
	var corners: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(0, size.y),
		Vector2(size.x, size.y)
	]
	var max_dist: float = 0.0
	for corner in corners:
		var d: float = center.distance_to(corner)
		if d > max_dist:
			max_dist = d
	var target_radius: float = max_dist * 1.15
	if target_radius < 10.0:
		target_radius = 50.0

	var wave := RippleWave.new()
	wave.center = center
	wave.radius = 0.0
	wave.max_radius = target_radius
	wave.alpha = press_opacity
	wave.is_releasing = false

	var tw := create_tween()
	if tw:
		tw.bind_node(self)
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_CUBIC)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(wave, ^"radius", target_radius, 0.35)
		tw.tween_method(func(_val: Variant) -> void: _sync_and_redraw(), 0.0, 1.0, 0.35)
		wave.tween = tw

	_active_waves.append(wave)
	_sync_and_redraw()

func _release_all_waves() -> void:
	for wave in _active_waves:
		if wave.is_releasing:
			continue
		wave.is_releasing = true
		if wave.tween != null and wave.tween.is_valid():
			wave.tween.kill()

		var tw := create_tween()
		if tw:
			tw.bind_node(self)
			tw.set_parallel(true)
			tw.set_trans(Tween.TRANS_CUBIC)
			tw.set_ease(Tween.EASE_OUT)
			tw.tween_property(wave, ^"alpha", 0.0, 0.25)
			tw.tween_method(func(_val: Variant) -> void: _sync_and_redraw(), 0.0, 1.0, 0.25)
			tw.chain().tween_callback(func() -> void:
				_active_waves.erase(wave)
				_sync_and_redraw()
			)
			wave.tween = tw

func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	# Draw state layer
	if _state_layer_alpha > 0.001:
		var state_col := Color(ripple_color.r, ripple_color.g, ripple_color.b, ripple_color.a * _state_layer_alpha)
		if corner_radius > 0.5:
			var sb := StyleBoxFlat.new()
			sb.bg_color = state_col
			sb.set_corner_radius_all(int(corner_radius))
			draw_style_box(sb, r)
		else:
			draw_rect(r, state_col, true)

	# Draw active ripple waves
	for wave in _active_waves:
		if wave.alpha > 0.001 and wave.radius > 0.0:
			var wave_col := Color(ripple_color.r, ripple_color.g, ripple_color.b, ripple_color.a * wave.alpha)
			draw_circle(wave.center, wave.radius, wave_col)
