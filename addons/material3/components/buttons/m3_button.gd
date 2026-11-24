@tool
class_name M3Button
extends M3Control

## Material 3 Common Button component with Filled, Elevated, Tonal, Outlined, and Text variants,
## plus M3 Expressive sizes (XS..XL) and shapes (Round/Square).

enum Variant {
	FILLED,
	ELEVATED,
	TONAL,
	OUTLINED,
	TEXT
}

enum ButtonType {
	ELEVATED,
	FILLED,
	FILLED_TONAL,
	OUTLINED,
	TEXT
}

enum ButtonSize {
	EXTRA_SMALL,
	SMALL,
	MEDIUM,
	LARGE,
	EXTRA_LARGE
}

enum ButtonShape {
	ROUND,
	SQUARE
}

signal pressed()
signal toggled(toggled_on: bool)

@export var text: String = "Button":
	set(value):
		text = value
		_update_layout()
		queue_redraw()

@export var variant: Variant = Variant.FILLED:
	set(value):
		variant = value
		_update_elevation_and_colors()
		_update_layout()
		queue_redraw()

@export var button_type: ButtonType:
	get:
		match variant:
			Variant.ELEVATED: return ButtonType.ELEVATED
			Variant.FILLED: return ButtonType.FILLED
			Variant.TONAL: return ButtonType.FILLED_TONAL
			Variant.OUTLINED: return ButtonType.OUTLINED
			Variant.TEXT: return ButtonType.TEXT
		return ButtonType.FILLED
	set(value):
		match value:
			ButtonType.ELEVATED: variant = Variant.ELEVATED
			ButtonType.FILLED: variant = Variant.FILLED
			ButtonType.FILLED_TONAL: variant = Variant.TONAL
			ButtonType.OUTLINED: variant = Variant.OUTLINED
			ButtonType.TEXT: variant = Variant.TEXT

@export var button_size: ButtonSize = ButtonSize.SMALL:
	set(value):
		button_size = value
		_update_font()
		_update_layout()
		queue_redraw()

@export var button_shape: ButtonShape = ButtonShape.ROUND:
	set(value):
		button_shape = value
		_update_shapes()
		queue_redraw()

@export var leading_icon: StringName = &"":
	set(value):
		leading_icon = value
		_update_layout()
		queue_redraw()

@export var leading_icon_texture: Texture2D = null:
	set(value):
		leading_icon_texture = value
		_update_layout()
		queue_redraw()

@export var trailing_icon: StringName = &"":
	set(value):
		trailing_icon = value
		_update_layout()
		queue_redraw()

@export var trailing_icon_texture: Texture2D = null:
	set(value):
		trailing_icon_texture = value
		_update_layout()
		queue_redraw()

@export var toggle_mode: bool = false
@export var button_pressed: bool = false:
	set(value):
		if button_pressed != value:
			button_pressed = value
			_update_elevation_and_colors()
			queue_redraw()

@export var icon_size: float = 18.0:
	set(value):
		icon_size = value
		_update_layout()
		queue_redraw()

@export var custom_primary_color: Color = Color.TRANSPARENT:
	set(value):
		custom_primary_color = value
		queue_redraw()

var corner_top_left: float = -1.0
var corner_top_right: float = -1.0
var corner_bottom_right: float = -1.0
var corner_bottom_left: float = -1.0
var width_bonus: float = 0.0:
	set(value):
		if not is_equal_approx(width_bonus, value):
			width_bonus = value
			_update_layout()
			queue_redraw()

var _font: Font = null
var _font_size: int = 14
var _current_elevation: int = 0
var _target_elevation: int = 0
var _elevation_tween: Tween = null
var _hover_progress: float = 0.0
var _press_progress: float = 0.0
var _motion_tween: Tween = null

func _init() -> void:
	super._init()
	shape_token = M3Shapes.ShapeToken.FULL
	custom_minimum_size = Vector2(64.0, 40.0)

func _ready() -> void:
	super._ready()
	_update_font()
	_update_elevation_and_colors()
	_update_layout()

func set_corner_radii(tl: float, tr: float, br: float, bl: float) -> void:
	corner_top_left = tl
	corner_top_right = tr
	corner_bottom_right = br
	corner_bottom_left = bl
	queue_redraw()

func clear_corner_radii() -> void:
	corner_top_left = -1.0
	corner_top_right = -1.0
	corner_bottom_right = -1.0
	corner_bottom_left = -1.0
	queue_redraw()

func _get_size_height() -> float:
	var base_h: float = 40.0
	match button_size:
		ButtonSize.EXTRA_SMALL: base_h = 32.0
		ButtonSize.SMALL: base_h = 40.0
		ButtonSize.MEDIUM: base_h = 56.0
		ButtonSize.LARGE: base_h = 96.0
		ButtonSize.EXTRA_LARGE: base_h = 136.0
	return get_density_adjusted_height(base_h, 24.0)

func _get_size_font_size() -> int:
	match button_size:
		ButtonSize.EXTRA_SMALL: return 12
		ButtonSize.SMALL: return 14
		ButtonSize.MEDIUM: return 16
		ButtonSize.LARGE: return 24
		ButtonSize.EXTRA_LARGE: return 32
	return 14

func _get_size_square_radius() -> float:
	match button_size:
		ButtonSize.EXTRA_SMALL: return 8.0
		ButtonSize.SMALL: return 12.0
		ButtonSize.MEDIUM: return 16.0
		ButtonSize.LARGE: return 28.0
		ButtonSize.EXTRA_LARGE: return 28.0
	return 12.0

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = _get_size_font_size()

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()
	_update_layout()
	_update_elevation_and_colors()

func _on_state_updated(old_state: ControlState, new_state: ControlState) -> void:
	super._on_state_updated(old_state, new_state)
	_update_elevation_for_state(new_state)
	_animate_state_motion(new_state)

func _animate_state_motion(st: ControlState) -> void:
	var target_hover: float = 1.0 if (st == ControlState.HOVERED or st == ControlState.PRESSED) else 0.0
	var target_press: float = 1.0 if st == ControlState.PRESSED else 0.0
	if not is_inside_tree():
		_hover_progress = target_hover
		_press_progress = target_press
		return
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween()
	if _motion_tween:
		_motion_tween.bind_node(self)
		_motion_tween.set_parallel(true)
		_motion_tween.set_trans(Tween.TRANS_CUBIC)
		_motion_tween.set_ease(Tween.EASE_OUT)
		_motion_tween.tween_property(self, ^"_hover_progress", target_hover, 0.16)
		_motion_tween.tween_property(self, ^"_press_progress", target_press, 0.16)
		_motion_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.16)

func _update_elevation_for_state(st: ControlState) -> void:
	match variant:
		Variant.ELEVATED:
			match st:
				ControlState.NORMAL, ControlState.FOCUSED:
					_set_elevation(1)
				ControlState.HOVERED:
					_set_elevation(2)
				ControlState.PRESSED:
					_set_elevation(1)
				ControlState.DISABLED:
					_set_elevation(0)
		Variant.FILLED, Variant.TONAL:
			match st:
				ControlState.HOVERED:
					_set_elevation(1)
				_:
					_set_elevation(0)
		_:
			_set_elevation(0)

func _set_elevation(target: int) -> void:
	if _target_elevation == target:
		return
	_target_elevation = target
	if not is_inside_tree():
		_current_elevation = target
		return
	if _elevation_tween != null and _elevation_tween.is_valid():
		_elevation_tween.kill()

	_elevation_tween = create_tween()
	if _elevation_tween:
		_elevation_tween.bind_node(self)
		_elevation_tween.set_trans(Tween.TRANS_CUBIC)
		_elevation_tween.set_ease(Tween.EASE_OUT)
		_elevation_tween.tween_property(self, ^"_current_elevation", target, 0.15)
		_elevation_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.15)

func _update_elevation_and_colors() -> void:
	_update_elevation_for_state(current_state)
	_update_ripple_colors()

func _update_ripple_colors() -> void:
	if _ripple == null or not is_instance_valid(_ripple):
		return
	var content_col := _get_content_color()
	_ripple.ripple_color = content_col

func _get_container_color() -> Color:
	var primary_col := custom_primary_color if custom_primary_color.a > 0.0 else get_m3_color(&"primary")
	if disabled:
		match variant:
			Variant.FILLED, Variant.ELEVATED, Variant.TONAL:
				return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
			Variant.OUTLINED, Variant.TEXT:
				return Color.TRANSPARENT

	if toggle_mode and button_pressed:
		match variant:
			Variant.OUTLINED:
				return get_m3_color(&"inverse_surface")
			Variant.TONAL:
				return get_m3_color(&"secondary")
			Variant.ELEVATED:
				return primary_col

	match variant:
		Variant.FILLED:
			return primary_col
		Variant.ELEVATED:
			var base_surf := get_m3_color(&"surface_container_low")
			var tint_col := get_m3_color(&"surface_tint")
			return M3Elevation.get_surface_tinted_color(base_surf, tint_col, _current_elevation)
		Variant.TONAL:
			return get_m3_color(&"secondary_container")
		Variant.OUTLINED, Variant.TEXT:
			return Color.TRANSPARENT
	return primary_col

func _get_content_color() -> Color:
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTENT_OPACITY)

	if toggle_mode and button_pressed:
		match variant:
			Variant.OUTLINED:
				return get_m3_color(&"inverse_on_surface")
			Variant.TONAL:
				return get_m3_color(&"on_secondary")
			Variant.ELEVATED:
				return get_m3_color(&"on_primary")

	match variant:
		Variant.FILLED:
			return get_m3_color(&"on_primary")
		Variant.ELEVATED:
			return custom_primary_color if custom_primary_color.a > 0.0 else get_m3_color(&"primary")
		Variant.TONAL:
			return get_m3_color(&"on_secondary_container")
		Variant.OUTLINED, Variant.TEXT:
			return custom_primary_color if custom_primary_color.a > 0.0 else get_m3_color(&"primary")
	return get_m3_color(&"primary")

func _get_border_color() -> Color:
	if variant != Variant.OUTLINED:
		return Color.TRANSPARENT
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
	if current_state == ControlState.FOCUSED:
		return custom_primary_color if custom_primary_color.a > 0.0 else get_m3_color(&"primary")
	return get_m3_color(&"outline")

func _update_layout() -> void:
	if _font == null:
		_update_font()
	var has_leading: bool = (leading_icon != &"" or leading_icon_texture != null)
	var has_trailing: bool = (trailing_icon != &"" or trailing_icon_texture != null)

	var pad_left: float = 24.0
	var pad_right: float = 24.0
	if variant == Variant.TEXT:
		pad_left = 12.0
		pad_right = 12.0
	if has_leading:
		pad_left = 16.0
	if has_trailing:
		pad_right = 16.0

	var content_w: float = 0.0
	if _font != null and not text.is_empty():
		content_w += _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x

	if has_leading:
		content_w += icon_size + (8.0 if not text.is_empty() else 0.0)
	if has_trailing:
		content_w += icon_size + (8.0 if not text.is_empty() else 0.0)

	var total_h: float = _get_size_height()
	var min_w: float = maxf(64.0, total_h)
	var total_w: float = maxf(content_w + pad_left + pad_right, min_w) + width_bonus
	custom_minimum_size = Vector2(total_w, total_h)
	update_minimum_size()

func _get_minimum_size() -> Vector2:
	return custom_minimum_size

func _on_pressed_action() -> void:
	if toggle_mode:
		button_pressed = not button_pressed
		toggled.emit(button_pressed)
	pressed.emit()

func _resolve_base_radius() -> float:
	if custom_corner_radius >= 0.0:
		return custom_corner_radius
	if button_shape == ButtonShape.SQUARE:
		return _get_size_square_radius()
	var r: float = M3Shapes.get_radius(shape_token)
	if r >= 9000.0:
		return maxf(size.y, _get_size_height()) * 0.5
	return r

func _apply_corners_to_stylebox(sb: StyleBoxFlat, default_r: float) -> void:
	var morphed_r: float = lerpf(default_r, _get_size_square_radius(), _press_progress * 0.35)
	var tl: int = int(corner_top_left if corner_top_left >= 0.0 else morphed_r)
	var tr: int = int(corner_top_right if corner_top_right >= 0.0 else morphed_r)
	var br: int = int(corner_bottom_right if corner_bottom_right >= 0.0 else morphed_r)
	var bl: int = int(corner_bottom_left if corner_bottom_left >= 0.0 else morphed_r)
	sb.corner_radius_top_left = tl
	sb.corner_radius_top_right = tr
	sb.corner_radius_bottom_right = br
	sb.corner_radius_bottom_left = bl

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var radius: float = _resolve_base_radius()

	# 1. Drop shadow for elevation > 0
	if _current_elevation > 0:
		var shadow_props := M3Elevation.get_shadow_props(_current_elevation)
		var offset_y: float = shadow_props.get("offset_y", 1.0)
		var blur: float = shadow_props.get("blur", 3.0)
		var alpha: float = shadow_props.get("alpha", 0.15)
		var shadow_sb := StyleBoxFlat.new()
		shadow_sb.bg_color = Color.TRANSPARENT
		_apply_corners_to_stylebox(shadow_sb, radius)
		shadow_sb.shadow_color = Color(0, 0, 0, alpha)
		shadow_sb.shadow_size = int(blur)
		shadow_sb.shadow_offset = Vector2(0, offset_y)
		draw_style_box(shadow_sb, r)

	# 2. Container Background
	var bg_col := _get_container_color()
	var border_col := _get_border_color()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	_apply_corners_to_stylebox(sb, radius)
	if border_col.a > 0.0:
		sb.set_border_width_all(1)
		sb.border_color = border_col
	draw_style_box(sb, r)

	# 3. Content (Leading Icon, Text, Trailing Icon)
	var content_col := _get_content_color()
	var has_leading: bool = (leading_icon != &"" or leading_icon_texture != null)
	var has_trailing: bool = (trailing_icon != &"" or trailing_icon_texture != null)

	var text_w: float = 0.0
	if _font != null and not text.is_empty():
		text_w = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x

	var total_content_w: float = text_w
	if has_leading:
		total_content_w += icon_size + (8.0 if not text.is_empty() else 0.0)
	if has_trailing:
		total_content_w += icon_size + (8.0 if not text.is_empty() else 0.0)

	var cursor_x: float = (size.x - total_content_w) * 0.5

	# Draw leading icon
	if has_leading:
		var icon_rect := Rect2(cursor_x, (size.y - icon_size) * 0.5, icon_size, icon_size)
		_draw_sub_icon(leading_icon, leading_icon_texture, icon_rect, content_col)
		cursor_x += icon_size + (8.0 if not text.is_empty() else 0.0)

	# Draw text
	if _font != null and not text.is_empty():
		var font_ascent := _font.get_ascent(_font_size)
		var text_y := (size.y - _font.get_height(_font_size)) * 0.5 + font_ascent
		draw_string(_font, Vector2(cursor_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, content_col)
		cursor_x += text_w + (8.0 if has_trailing else 0.0)

	# Draw trailing icon
	if has_trailing:
		var icon_rect := Rect2(cursor_x, (size.y - icon_size) * 0.5, icon_size, icon_size)
		_draw_sub_icon(trailing_icon, trailing_icon_texture, icon_rect, content_col)

func _draw_sub_icon(ic_name: StringName, ic_tex: Texture2D, target_rect: Rect2, color: Color) -> void:
	if ic_tex != null:
		draw_texture_rect(ic_tex, target_rect, false, color)
		return
	if ic_name == &"":
		return

	var center := target_rect.get_center()
	var scale_factor := target_rect.size.x / 24.0
	var sw: float = maxf(1.0, 2.0 * scale_factor)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_factor

	var key := String(ic_name).to_lower().replace("-", "_")
	match key:
		"checkmark", "check":
			var pts := PackedVector2Array([t.call(Vector2(5, 12)), t.call(Vector2(10, 17)), t.call(Vector2(19, 7))])
			draw_polyline(pts, color, sw, true)
		"close", "cross", "clear":
			draw_line(t.call(Vector2(6, 6)), t.call(Vector2(18, 18)), color, sw, true)
			draw_line(t.call(Vector2(18, 6)), t.call(Vector2(6, 18)), color, sw, true)
		"arrow_down", "expand_more", "chevron_down":
			var pts := PackedVector2Array([t.call(Vector2(6, 9)), t.call(Vector2(12, 15)), t.call(Vector2(18, 9))])
			draw_polyline(pts, color, sw, true)
		"arrow_up", "expand_less", "chevron_up":
			var pts := PackedVector2Array([t.call(Vector2(6, 15)), t.call(Vector2(12, 9)), t.call(Vector2(18, 15))])
			draw_polyline(pts, color, sw, true)
		"arrow_right", "chevron_right":
			var pts := PackedVector2Array([t.call(Vector2(9, 6)), t.call(Vector2(15, 12)), t.call(Vector2(9, 18))])
			draw_polyline(pts, color, sw, true)
		"add", "plus":
			draw_line(t.call(Vector2(12, 5)), t.call(Vector2(12, 19)), color, sw, true)
			draw_line(t.call(Vector2(5, 12)), t.call(Vector2(19, 12)), color, sw, true)
		"edit", "pencil":
			var pts := PackedVector2Array([
				t.call(Vector2(5, 19)), t.call(Vector2(9, 18)), t.call(Vector2(18, 9)),
				t.call(Vector2(15, 6)), t.call(Vector2(6, 15)), t.call(Vector2(5, 19))
			])
			draw_polyline(pts, color, sw, true)
		"delete", "trash":
			draw_line(t.call(Vector2(4, 6)), t.call(Vector2(20, 6)), color, sw, true)
			var body := PackedVector2Array([t.call(Vector2(6, 6)), t.call(Vector2(7, 20)), t.call(Vector2(17, 20)), t.call(Vector2(18, 6))])
			draw_polyline(body, color, sw, true)
		"share":
			draw_circle(t.call(Vector2(17, 6)), 2.0 * scale_factor, color)
			draw_circle(t.call(Vector2(7, 12)), 2.0 * scale_factor, color)
			draw_circle(t.call(Vector2(17, 18)), 2.0 * scale_factor, color)
			draw_line(t.call(Vector2(7, 12)), t.call(Vector2(17, 6)), color, sw, true)
			draw_line(t.call(Vector2(7, 12)), t.call(Vector2(17, 18)), color, sw, true)
		_:
			draw_circle(center, 3.0 * scale_factor, color)
