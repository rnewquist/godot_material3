@tool
class_name M3Checkbox
extends M3Control

## Material 3 Checkbox component with Checked, Unchecked, and Indeterminate states, animated checkmark/dash morphing.

enum CheckState {
	UNCHECKED,
	CHECKED,
	INDETERMINATE
}

signal toggled(checked: bool)
signal check_state_changed(new_state: CheckState)

@export var check_state: CheckState = CheckState.UNCHECKED:
	set(value):
		if check_state != value:
			check_state = value
			_animate_transition()
			check_state_changed.emit(check_state)
			toggled.emit(check_state == CheckState.CHECKED)
			queue_redraw()

@export var checked: bool:
	get:
		return check_state == CheckState.CHECKED
	set(value):
		check_state = CheckState.CHECKED if value else CheckState.UNCHECKED

@export var indeterminate: bool:
	get:
		return check_state == CheckState.INDETERMINATE
	set(value):
		if value:
			check_state = CheckState.INDETERMINATE
		else:
			check_state = CheckState.CHECKED if checked else CheckState.UNCHECKED

@export var tristate: bool = false
@export var is_error: bool = false:
	set(value):
		if is_error != value:
			is_error = value
			_update_ripple_colors()
			queue_redraw()

@export var error: bool:
	get:
		return is_error
	set(value):
		is_error = value

@export var text: String = "":
	set(value):
		text = value
		_update_min_size()
		queue_redraw()

@export var box_size: float = 18.0:
	set(value):
		box_size = value
		_update_min_size()
		queue_redraw()

var _anim_progress: float = 0.0
var _anim_tween: Tween = null
var _font: Font = null
var _font_size: int = 14

func _init() -> void:
	super._init()
	custom_minimum_size = Vector2(48.0, 48.0)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_update_font()
	_anim_progress = 1.0 if check_state != CheckState.UNCHECKED else 0.0
	_update_min_size()
	_update_ripple_colors()

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = 14

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()
	_update_ripple_colors()

func _update_ripple_colors() -> void:
	if _ripple != null and is_instance_valid(_ripple):
		var r_col: Color
		if is_error:
			r_col = get_m3_color(&"error")
		elif check_state != CheckState.UNCHECKED:
			r_col = get_m3_color(&"primary")
		else:
			r_col = get_m3_color(&"on_surface")
		_ripple.set("ripple_color", r_col)

func _animate_transition() -> void:
	var target: float = 1.0 if check_state != CheckState.UNCHECKED else 0.0
	if not is_inside_tree():
		_anim_progress = target
		return
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween()
	if _anim_tween:
		_anim_tween.bind_node(self)
		_anim_tween.set_parallel(true)
		_anim_tween.set_trans(Tween.TRANS_SPRING)
		_anim_tween.set_ease(Tween.EASE_OUT)
		_anim_tween.tween_property(self, ^"_anim_progress", target, 0.2)
		_anim_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)
	_update_ripple_colors()

func _update_min_size() -> void:
	var w: float = 48.0
	if _font != null and not text.is_empty():
		var text_w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		w = 48.0 + text_w + 8.0
	custom_minimum_size = Vector2(w, 48.0)
	size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
	update_minimum_size()

func _on_pressed_action() -> void:
	if tristate:
		match check_state:
			CheckState.UNCHECKED:
				check_state = CheckState.CHECKED
			CheckState.CHECKED:
				check_state = CheckState.INDETERMINATE
			CheckState.INDETERMINATE:
				check_state = CheckState.UNCHECKED
	else:
		check_state = CheckState.UNCHECKED if check_state == CheckState.CHECKED else CheckState.CHECKED

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var box_center := Vector2(24.0, size.y * 0.5)
	var box_rect := Rect2(box_center - Vector2(box_size, box_size) * 0.5, Vector2(box_size, box_size))

	var primary_col := get_m3_color(&"primary")
	var on_surface_var := get_m3_color(&"on_surface_variant")
	var on_surface_col := get_m3_color(&"on_surface")
	var on_primary_col := get_m3_color(&"on_primary")
	var error_col := get_m3_color(&"error")
	var on_error_col := get_m3_color(&"on_error")

	var active_fill := error_col if is_error else primary_col
	var active_glyph := on_error_col if is_error else on_primary_col
	var inactive_border := error_col if is_error else on_surface_var

	if disabled:
		var dis_col := Color(on_surface_col, M3Color.DISABLED_CONTENT_OPACITY)
		if check_state == CheckState.UNCHECKED:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color.TRANSPARENT
			sb.border_color = dis_col
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(2)
			draw_style_box(sb, box_rect)
		else:
			var sb := StyleBoxFlat.new()
			sb.bg_color = dis_col
			sb.set_corner_radius_all(2)
			draw_style_box(sb, box_rect)
			_draw_glyph(box_center, box_size, get_m3_color(&"surface"))
	else:
		if _anim_progress > 0.01:
			var sb := StyleBoxFlat.new()
			sb.bg_color = active_fill
			sb.set_corner_radius_all(2)
			draw_style_box(sb, box_rect)
			_draw_glyph(box_center, box_size * _anim_progress, active_glyph)
		else:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color.TRANSPARENT
			sb.border_color = inactive_border
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(2)
			draw_style_box(sb, box_rect)

	# Draw label
	if _font != null and not text.is_empty():
		var label_col := Color(on_surface_col, M3Color.DISABLED_CONTENT_OPACITY) if disabled else on_surface_col
		var text_x: float = 44.0
		var font_ascent := _font.get_ascent(_font_size)
		var text_y := (size.y - _font.get_height(_font_size)) * 0.5 + font_ascent
		draw_string(_font, Vector2(text_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, label_col)

func _draw_glyph(center: Vector2, s: float, col: Color) -> void:
	var scale_factor := s / 18.0
	var sw: float = maxf(1.5, 2.0 * scale_factor)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(9.0, 9.0)) * scale_factor

	if check_state == CheckState.INDETERMINATE:
		draw_line(t.call(Vector2(4.0, 9.0)), t.call(Vector2(14.0, 9.0)), col, sw, true)
	else:
		var pts := PackedVector2Array([
			t.call(Vector2(3.5, 9.0)),
			t.call(Vector2(7.5, 13.0)),
			t.call(Vector2(14.5, 5.0))
		])
		draw_polyline(pts, col, sw, true)
