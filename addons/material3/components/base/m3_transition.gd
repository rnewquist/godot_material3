@tool
class_name M3Transition
extends Control

## Material 3 Motion Transition Pattern Controller & Visualizer.
## Implements the 4 canonical M3 transition patterns:
##   1. Container Transform (morphs bounding rect, corner radius, surface color, and cross-fades content)
##   2. Shared Axis (X, Y, Z directional translation/scale + fade-through)
##   3. Fade Through (outgoing fades out 0..35% and scales 1.0->0.92; incoming fades in 35..100% and scales 0.92->1.0)
##   4. Fade (simple enter/exit opacity cross-fade with Effects spring)

signal transition_completed(is_expanded: bool)

@export var pattern: M3Motion.TransitionPattern = M3Motion.TransitionPattern.CONTAINER_TRANSFORM:
	set(value):
		pattern = value
		_update_kinematics()
		queue_redraw()

@export var spring_speed: M3Motion.SpringSpeed = M3Motion.SpringSpeed.DEFAULT:
	set(value):
		spring_speed = value
		_update_kinematics()
		queue_redraw()

@export var collapsed_rect: Rect2 = Rect2(16, 20, 96, 56)
@export var expanded_rect: Rect2 = Rect2(16, 12, 240, 116)
@export var collapsed_radius: float = 16.0
@export var expanded_radius: float = 24.0
@export var outgoing_label: String = "FAB / Card"
@export var incoming_label: String = "Expanded Sheet"

var transition_progress: float = 0.0
var spatial_spring_val: float = 0.0
var effects_spring_val: float = 0.0
var current_rect: Rect2 = Rect2(16, 20, 96, 56)
var current_radius: float = 16.0
var outgoing_alpha: float = 1.0
var incoming_alpha: float = 0.0
var is_expanded: bool = false
var _tween: Tween = null

func _init() -> void:
	custom_minimum_size = Vector2(272, 140)
	size = Vector2(272, 140)
	_update_kinematics()

func set_progress(t: float) -> void:
	transition_progress = clampf(t, 0.0, 1.0)
	_update_kinematics()
	queue_redraw()

func play_transition(expand: bool = true, duration: float = 0.36) -> Tween:
	is_expanded = expand
	var start_t: float = transition_progress
	var target_t: float = 1.0 if expand else 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if _tween:
		_tween.bind_node(self)
		_tween.tween_method(set_progress, start_t, target_t, duration)
		_tween.tween_callback(func() -> void:
			transition_completed.emit(is_expanded)
		)
	return _tween

func _update_kinematics() -> void:
	spatial_spring_val = M3Motion.evaluate_spring(M3Motion.SpringType.SPATIAL, spring_speed, transition_progress)
	effects_spring_val = M3Motion.evaluate_spring(M3Motion.SpringType.EFFECTS, spring_speed, transition_progress)

	# Outgoing fades out in first 35%, incoming fades in over 35%..100%
	outgoing_alpha = clampf(1.0 - (effects_spring_val / 0.35), 0.0, 1.0)
	incoming_alpha = clampf((effects_spring_val - 0.30) / 0.70, 0.0, 1.0)

	match pattern:
		M3Motion.TransitionPattern.CONTAINER_TRANSFORM:
			current_rect = Rect2(
				collapsed_rect.position.lerp(expanded_rect.position, spatial_spring_val),
				collapsed_rect.size.lerp(expanded_rect.size, spatial_spring_val)
			)
			current_radius = lerpf(collapsed_radius, expanded_radius, spatial_spring_val)
		M3Motion.TransitionPattern.SHARED_AXIS_X:
			var offset_x: float = (1.0 - spatial_spring_val) * 48.0
			current_rect = Rect2(expanded_rect.position + Vector2(offset_x, 0.0), expanded_rect.size)
			current_radius = expanded_radius
		M3Motion.TransitionPattern.SHARED_AXIS_Y:
			var offset_y: float = (1.0 - spatial_spring_val) * 36.0
			current_rect = Rect2(expanded_rect.position + Vector2(0.0, offset_y), expanded_rect.size)
			current_radius = expanded_radius
		M3Motion.TransitionPattern.SHARED_AXIS_Z:
			var sc: float = lerpf(0.82, 1.0, spatial_spring_val)
			var center: Vector2 = expanded_rect.position + expanded_rect.size * 0.5
			var sz: Vector2 = expanded_rect.size * sc
			current_rect = Rect2(center - sz * 0.5, sz)
			current_radius = expanded_radius * sc
		M3Motion.TransitionPattern.FADE_THROUGH:
			var sc: float = lerpf(0.92, 1.0, incoming_alpha) if transition_progress >= 0.35 else lerpf(1.0, 0.92, 1.0 - outgoing_alpha)
			var center: Vector2 = expanded_rect.position + expanded_rect.size * 0.5
			var sz: Vector2 = expanded_rect.size * sc
			current_rect = Rect2(center - sz * 0.5, sz)
			current_radius = expanded_radius
		M3Motion.TransitionPattern.FADE:
			current_rect = expanded_rect
			current_radius = expanded_radius

func _draw() -> void:
	var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()
	var frame_sb := M3Shapes.create_stylebox(scheme.surface_container_low, M3Shapes.MEDIUM, 1, scheme.outline_variant)
	draw_style_box(frame_sb, Rect2(Vector2.ZERO, size))

	var bg_col: Color = scheme.primary_container.lerp(scheme.secondary_container, effects_spring_val)
	var border_col: Color = scheme.primary.lerp(scheme.secondary, effects_spring_val)
	var morph_sb := M3Shapes.create_stylebox(bg_col, int(round(maxf(0.0, current_radius))), 2, border_col)
	var safe_rect := Rect2(current_rect.position, Vector2(maxf(12.0, current_rect.size.x), maxf(12.0, current_rect.size.y)))
	draw_style_box(morph_sb, safe_rect)

	var font: Font = ThemeDB.fallback_font
	if outgoing_alpha > 0.02:
		var out_col := Color(scheme.on_primary_container.r, scheme.on_primary_container.g, scheme.on_primary_container.b, outgoing_alpha)
		draw_string(font, safe_rect.position + Vector2(10, safe_rect.size.y * 0.5 + 4), outgoing_label, HORIZONTAL_ALIGNMENT_LEFT, safe_rect.size.x - 16, 12, out_col)
	if incoming_alpha > 0.02:
		var in_col := Color(scheme.on_secondary_container.r, scheme.on_secondary_container.g, scheme.on_secondary_container.b, incoming_alpha)
		draw_string(font, safe_rect.position + Vector2(12, safe_rect.size.y * 0.5 + 4), incoming_label, HORIZONTAL_ALIGNMENT_LEFT, safe_rect.size.x - 20, 13, in_col)
