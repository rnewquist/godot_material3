@tool
class_name M3IconButton
extends M3Control

## Material 3 Icon Button component with Standard, Filled, Tonal, and Outlined variants,
## plus M3 Expressive size tiers (XS..XL), width modes (Narrow/Default/Wide), and shapes (Round/Square).

enum Variant {
	STANDARD,
	FILLED,
	TONAL,
	OUTLINED
}

enum IconBtnType {
	STANDARD,
	FILLED,
	FILLED_TONAL,
	OUTLINED
}

enum ButtonSize {
	EXTRA_SMALL,
	SMALL,
	MEDIUM,
	LARGE,
	EXTRA_LARGE
}

enum WidthMode {
	NARROW,
	DEFAULT,
	WIDE
}

enum ButtonShape {
	ROUND,
	SQUARE
}

signal pressed()
signal toggled(toggled_on: bool)

@export var icon_name: StringName = &"":
	set(value):
		icon_name = value
		queue_redraw()

@export var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		queue_redraw()

@export var selected_icon_name: StringName = &"":
	set(value):
		selected_icon_name = value
		queue_redraw()

@export var selected_icon_texture: Texture2D = null:
	set(value):
		selected_icon_texture = value
		queue_redraw()

@export var variant: Variant = Variant.STANDARD:
	set(value):
		variant = value
		_update_colors()
		queue_redraw()

@export var icon_button_type: IconBtnType:
	get:
		match variant:
			Variant.STANDARD: return IconBtnType.STANDARD
			Variant.FILLED: return IconBtnType.FILLED
			Variant.TONAL: return IconBtnType.FILLED_TONAL
			Variant.OUTLINED: return IconBtnType.OUTLINED
		return IconBtnType.STANDARD
	set(value):
		match value:
			IconBtnType.STANDARD: variant = Variant.STANDARD
			IconBtnType.FILLED: variant = Variant.FILLED
			IconBtnType.FILLED_TONAL: variant = Variant.TONAL
			IconBtnType.OUTLINED: variant = Variant.OUTLINED

@export var toggle_mode: bool = false:
	set(value):
		toggle_mode = value
		_update_colors()
		queue_redraw()

@export var button_pressed: bool = false:
	set(value):
		if button_pressed != value:
			button_pressed = value
			_animate_selection(button_pressed)
			_update_colors()
			_update_active_corner_radius()
			queue_redraw()

@export var button_size: ButtonSize = ButtonSize.SMALL:
	set(value):
		button_size = value
		icon_size = _get_default_icon_size()
		_update_dimensions()
		queue_redraw()

@export var width_mode: WidthMode = WidthMode.DEFAULT:
	set(value):
		width_mode = value
		_update_dimensions()
		queue_redraw()

@export var button_shape: ButtonShape = ButtonShape.ROUND:
	set(value):
		button_shape = value
		_update_active_corner_radius()
		queue_redraw()

@export var icon_size: float = 24.0:
	set(value):
		icon_size = value
		queue_redraw()

var _hover_progress: float = 0.0
var _press_progress: float = 0.0
var _selection_progress: float = 0.0
var _active_corner_radius: float = 20.0
var _motion_tween: Tween = null
var _selection_tween: Tween = null

func _init() -> void:
	super._init()
	shape_token = M3Shapes.ShapeToken.FULL
	_update_dimensions()

func _ready() -> void:
	super._ready()
	_selection_progress = 1.0 if button_pressed else 0.0
	_update_dimensions()
	_update_colors()

func _get_default_icon_size() -> float:
	match button_size:
		ButtonSize.EXTRA_SMALL: return 20.0
		ButtonSize.SMALL: return 24.0
		ButtonSize.MEDIUM: return 24.0
		ButtonSize.LARGE: return 32.0
		ButtonSize.EXTRA_LARGE: return 40.0
	return 24.0

func _get_size_height() -> float:
	match button_size:
		ButtonSize.EXTRA_SMALL: return 32.0
		ButtonSize.SMALL: return 40.0
		ButtonSize.MEDIUM: return 56.0
		ButtonSize.LARGE: return 96.0
		ButtonSize.EXTRA_LARGE: return 136.0
	return 40.0

func _get_target_dimensions() -> Vector2:
	var h: float = _get_size_height()
	var w: float = h
	match width_mode:
		WidthMode.NARROW:
			match button_size:
				ButtonSize.EXTRA_SMALL: w = 28.0
				ButtonSize.SMALL: w = 32.0
				ButtonSize.MEDIUM: w = 48.0
				ButtonSize.LARGE: w = 64.0
				ButtonSize.EXTRA_LARGE: w = 104.0
		WidthMode.WIDE:
			match button_size:
				ButtonSize.EXTRA_SMALL: w = 40.0
				ButtonSize.SMALL: w = 52.0
				ButtonSize.MEDIUM: w = 72.0
				ButtonSize.LARGE: w = 128.0
				ButtonSize.EXTRA_LARGE: w = 184.0
		WidthMode.DEFAULT:
			w = h
	return Vector2(w, h)

func _get_square_radius() -> float:
	match button_size:
		ButtonSize.EXTRA_SMALL: return 8.0
		ButtonSize.SMALL: return 12.0
		ButtonSize.MEDIUM: return 16.0
		ButtonSize.LARGE: return 28.0
		ButtonSize.EXTRA_LARGE: return 28.0
	return 12.0

func _resolve_base_radius() -> float:
	if custom_corner_radius >= 0.0:
		return custom_corner_radius
	var dims := Vector2(
		size.x if size.x > 0.0 else custom_minimum_size.x,
		size.y if size.y > 0.0 else custom_minimum_size.y
	)
	var round_r: float = minf(dims.x, dims.y) * 0.5
	var square_r: float = _get_square_radius()
	if button_shape == ButtonShape.SQUARE:
		return square_r
	return lerpf(round_r, square_r, _selection_progress)

func _update_active_corner_radius() -> void:
	var resting_r: float = _resolve_base_radius()
	var square_r: float = _get_square_radius()
	var pressed_r: float = maxf(4.0, square_r * 0.65)
	var morph_t: float = clampf(_hover_progress * 0.15 + _press_progress * 0.85, 0.0, 1.0)
	_active_corner_radius = lerpf(resting_r, pressed_r, morph_t)

func _update_dimensions() -> void:
	var dims := _get_target_dimensions()
	custom_minimum_size = dims
	size = dims
	update_minimum_size()
	_update_active_corner_radius()

func _get_minimum_size() -> Vector2:
	return custom_minimum_size

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_colors()

func _on_state_updated(old_state: ControlState, new_state: ControlState) -> void:
	super._on_state_updated(old_state, new_state)
	_update_colors()
	_animate_state_motion(new_state)

func _animate_state_motion(st: ControlState) -> void:
	var target_hover: float = 1.0 if (st == ControlState.HOVERED or st == ControlState.PRESSED) else 0.0
	var target_press: float = 1.0 if st == ControlState.PRESSED else 0.0
	if not is_inside_tree():
		_hover_progress = target_hover
		_press_progress = target_press
		_update_active_corner_radius()
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
		_motion_tween.tween_method(func(_val: Variant) -> void:
			_update_active_corner_radius()
			queue_redraw()
		, 0.0, 1.0, 0.16)

func _animate_selection(sel: bool) -> void:
	var target: float = 1.0 if sel else 0.0
	if not is_inside_tree():
		_selection_progress = target
		_update_active_corner_radius()
		return
	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()
	_selection_tween = create_tween()
	if _selection_tween:
		_selection_tween.bind_node(self)
		_selection_tween.set_trans(Tween.TRANS_CUBIC)
		_selection_tween.set_ease(Tween.EASE_OUT)
		_selection_tween.tween_property(self, ^"_selection_progress", target, 0.18)
		_selection_tween.tween_method(func(_val: Variant) -> void:
			_update_active_corner_radius()
			queue_redraw()
		, 0.0, 1.0, 0.18)

func _update_colors() -> void:
	if _ripple != null and is_instance_valid(_ripple):
		_ripple.ripple_color = _get_content_color()

func _is_filled_active() -> bool:
	return button_pressed if toggle_mode else true

func _get_container_color() -> Color:
	if disabled:
		match variant:
			Variant.FILLED, Variant.TONAL:
				return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
			Variant.OUTLINED:
				if button_pressed:
					return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
				return Color.TRANSPARENT
			Variant.STANDARD:
				return Color.TRANSPARENT

	match variant:
		Variant.STANDARD:
			return Color.TRANSPARENT
		Variant.FILLED:
			return get_m3_color(&"primary") if _is_filled_active() else get_m3_color(&"surface_container_highest")
		Variant.TONAL:
			return get_m3_color(&"secondary_container") if _is_filled_active() else get_m3_color(&"surface_container_highest")
		Variant.OUTLINED:
			return get_m3_color(&"inverse_surface") if button_pressed else Color.TRANSPARENT
	return Color.TRANSPARENT

func _get_content_color() -> Color:
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTENT_OPACITY)

	match variant:
		Variant.STANDARD:
			return get_m3_color(&"primary") if button_pressed else get_m3_color(&"on_surface_variant")
		Variant.FILLED:
			return get_m3_color(&"on_primary") if _is_filled_active() else get_m3_color(&"primary")
		Variant.TONAL:
			return get_m3_color(&"on_secondary_container") if _is_filled_active() else get_m3_color(&"on_surface_variant")
		Variant.OUTLINED:
			return get_m3_color(&"inverse_on_surface") if button_pressed else get_m3_color(&"on_surface_variant")
	return get_m3_color(&"on_surface_variant")

func _get_border_color() -> Color:
	if variant != Variant.OUTLINED or button_pressed:
		return Color.TRANSPARENT
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
	return get_m3_color(&"outline")

func _on_pressed_action() -> void:
	if toggle_mode:
		button_pressed = not button_pressed
		toggled.emit(button_pressed)
	pressed.emit()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	_update_active_corner_radius()
	var radius: float = _active_corner_radius
	var bg_col := _get_container_color()
	var border_col := _get_border_color()

	# Draw background & border
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_corner_radius_all(int(round(radius)))
	if border_col.a > 0.0:
		sb.set_border_width_all(1)
		sb.border_color = border_col
	draw_style_box(sb, r)

	# Draw icon
	var content_col := _get_content_color()
	var active_name := icon_name
	var active_tex := icon_texture
	if button_pressed:
		if selected_icon_name != &"":
			active_name = selected_icon_name
		if selected_icon_texture != null:
			active_tex = selected_icon_texture

	var icon_rect := Rect2((size.x - icon_size) * 0.5, (size.y - icon_size) * 0.5, icon_size, icon_size)
	if active_tex != null:
		draw_texture_rect(active_tex, icon_rect, false, content_col)
	elif active_name != &"":
		_draw_vector_icon(active_name, icon_rect, content_col)

func _draw_vector_icon(ic_name: StringName, target_rect: Rect2, color: Color) -> void:
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
		"settings":
			draw_arc(t.call(Vector2(12, 12)), 4.0 * scale_factor, 0, TAU, 20, color, sw, true)
			for i in range(8):
				var angle := i * (TAU / 8.0)
				var dir := Vector2(cos(angle), sin(angle))
				draw_line(t.call(Vector2(12, 12) + dir * 6.0), t.call(Vector2(12, 12) + dir * 9.0), color, sw * 1.3, true)
		"favorite", "heart":
			var pts: PackedVector2Array = []
			for i in range(24):
				var angle: float = (float(i) / 24.0) * TAU
				var hx: float = 16.0 * pow(sin(angle), 3)
				var hy: float = -(13.0 * cos(angle) - 5.0 * cos(2.0 * angle) - 2.0 * cos(3.0 * angle) - cos(4.0 * angle))
				pts.append(t.call(Vector2(12.0 + (hx / 17.0) * 8.0, 12.5 + (hy / 17.0) * 8.0)))
			draw_colored_polygon(pts, color)
		"menu", "hamburger":
			draw_line(t.call(Vector2(4, 7)), t.call(Vector2(20, 7)), color, sw, true)
			draw_line(t.call(Vector2(4, 12)), t.call(Vector2(20, 12)), color, sw, true)
			draw_line(t.call(Vector2(4, 17)), t.call(Vector2(20, 17)), color, sw, true)
		"add", "plus":
			draw_line(t.call(Vector2(12, 5)), t.call(Vector2(12, 19)), color, sw, true)
			draw_line(t.call(Vector2(5, 12)), t.call(Vector2(19, 12)), color, sw, true)
		"edit", "pencil":
			var pts := PackedVector2Array([
				t.call(Vector2(5, 19)),
				t.call(Vector2(9, 18)),
				t.call(Vector2(18, 9)),
				t.call(Vector2(15, 6)),
				t.call(Vector2(6, 15)),
				t.call(Vector2(5, 19))
			])
			draw_polyline(pts, color, sw, true)
		"delete", "trash":
			draw_line(t.call(Vector2(4, 6)), t.call(Vector2(20, 6)), color, sw, true)
			draw_line(t.call(Vector2(9, 4)), t.call(Vector2(15, 4)), color, sw, true)
			var body := PackedVector2Array([t.call(Vector2(6, 6)), t.call(Vector2(7, 20)), t.call(Vector2(17, 20)), t.call(Vector2(18, 6))])
			draw_polyline(body, color, sw, true)
		_:
			draw_circle(center, 4.0 * scale_factor, color)
