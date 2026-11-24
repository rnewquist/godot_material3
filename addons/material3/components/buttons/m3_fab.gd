@tool
class_name M3FAB
extends M3Control

## Material 3 Floating Action Button (FAB) component.
## Supports Small, Standard, Large, and Extended variants across Primary, Surface, Secondary, and Tertiary palettes.

enum FabVariant {
	SMALL,
	STANDARD,
	LARGE,
	EXTENDED
}

enum FabSize {
	SMALL,
	STANDARD,
	LARGE,
	EXTENDED
}

enum FabColorPalette {
	PRIMARY,
	SURFACE,
	SECONDARY,
	TERTIARY
}

signal pressed()
signal extended_changed(is_extended: bool)

var _updating_variant_flag: bool = false

@export var fab_variant: FabVariant = FabVariant.STANDARD:
	set(value):
		fab_variant = value
		if not _updating_variant_flag:
			_updating_variant_flag = true
			extended = (fab_variant == FabVariant.EXTENDED)
			extend_progress = 1.0 if extended else 0.0
			_extend_progress = extend_progress
			_updating_variant_flag = false
		_update_dimensions()
		queue_redraw()

@export var fab_size: FabSize:
	get:
		return fab_variant as int as FabSize
	set(value):
		fab_variant = value as int as FabVariant

@export var extended: bool = false:
	set(value):
		if _updating_variant_flag:
			extended = value
			return
		var changed: bool = (extended != value)
		extended = value
		_on_extended_updated(value, changed)

@export var toggle_extended_on_press: bool = false
@export var collapse_on_scroll: bool = false

@export var color_palette: FabColorPalette = FabColorPalette.PRIMARY:
	set(value):
		color_palette = value
		_update_colors()
		queue_redraw()

@export var icon_name: StringName = &"add":
	set(value):
		icon_name = value
		_update_dimensions()
		queue_redraw()

@export var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		_update_dimensions()
		queue_redraw()

@export var label: String = "":
	set(value):
		label = value
		_update_dimensions()
		queue_redraw()

@export var text: String:
	get:
		return label
	set(value):
		label = value

@export var custom_icon_size: float = -1.0:
	set(value):
		custom_icon_size = value
		queue_redraw()

@export var icon_rotation_deg: float = 0.0:
	set(value):
		icon_rotation_deg = value
		queue_redraw()

var extend_progress: float = 0.0
var _extend_progress: float = 0.0
var _hover_progress: float = 0.0
var _press_progress: float = 0.0
var _current_elevation: int = 3
var _target_elevation: int = 3
var _elevation_tween: Tween = null
var _extend_tween: Tween = null
var _motion_tween: Tween = null
var _font: Font = null
var _font_size: int = 14

func _init() -> void:
	super._init()
	_update_font()
	_update_dimensions()

func _ready() -> void:
	super._ready()
	_update_font()
	_update_dimensions()
	_update_colors()

func set_extended(val: bool) -> void:
	extended = val

func _on_extended_updated(val: bool, changed: bool) -> void:
	_updating_variant_flag = true
	if val:
		fab_variant = FabVariant.EXTENDED
	elif fab_variant == FabVariant.EXTENDED:
		fab_variant = FabVariant.STANDARD
	_updating_variant_flag = false

	var target: float = 1.0 if val else 0.0
	if not is_inside_tree():
		extend_progress = target
		_extend_progress = target
		_update_dimensions()
		if changed:
			extended_changed.emit(extended)
		return

	if _extend_tween != null and _extend_tween.is_valid():
		_extend_tween.kill()

	_extend_tween = create_tween()
	if _extend_tween:
		_extend_tween.bind_node(self)
		_extend_tween.set_trans(Tween.TRANS_CUBIC)
		_extend_tween.set_ease(Tween.EASE_OUT)
		_extend_tween.tween_method(_apply_extend_step, extend_progress, target, 0.22)
	else:
		_apply_extend_step(target)

	if changed:
		extended_changed.emit(extended)

func _apply_extend_step(p: float) -> void:
	extend_progress = p
	_extend_progress = p
	var target_w: float = lerpf(56.0, _compute_extended_width(), p)
	shape_token = M3Shapes.ShapeToken.LARGE
	custom_minimum_size = Vector2(target_w, 56.0)
	size = custom_minimum_size
	update_minimum_size()
	_update_shapes()
	queue_redraw()

func _compute_extended_width() -> float:
	if _font == null:
		_update_font()
	var w: float = 80.0
	if _font != null and not label.is_empty():
		var text_w: float = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		var ic_s: float = _get_effective_icon_size()
		var has_ic: bool = (icon_name != &"" or icon_texture != null)
		w = (16.0 + ic_s + 12.0 + text_w + 20.0) if has_ic else (24.0 + text_w + 24.0)
	return maxf(w, 80.0)

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = 14

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()
	_update_colors()

func _on_state_updated(old_state: ControlState, new_state: ControlState) -> void:
	super._on_state_updated(old_state, new_state)
	match new_state:
		ControlState.HOVERED:
			_set_elevation(4)
		ControlState.PRESSED:
			_set_elevation(3)
		ControlState.DISABLED:
			_set_elevation(0)
		_:
			_set_elevation(3)
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

func _update_dimensions() -> void:
	if _extend_tween != null and _extend_tween.is_valid() and _extend_tween.is_running():
		return
	match fab_variant:
		FabVariant.SMALL:
			shape_token = M3Shapes.ShapeToken.MEDIUM
			custom_minimum_size = Vector2(40.0, 40.0)
		FabVariant.STANDARD:
			shape_token = M3Shapes.ShapeToken.LARGE
			custom_minimum_size = Vector2(56.0, 56.0)
		FabVariant.LARGE:
			shape_token = M3Shapes.ShapeToken.EXTRA_LARGE
			custom_minimum_size = Vector2(96.0, 96.0)
		FabVariant.EXTENDED:
			shape_token = M3Shapes.ShapeToken.LARGE
			custom_minimum_size = Vector2(_compute_extended_width(), 56.0)
	update_minimum_size()
	_update_shapes()

func _get_minimum_size() -> Vector2:
	return custom_minimum_size

func _get_effective_icon_size() -> float:
	if custom_icon_size > 0.0:
		return custom_icon_size
	match fab_variant:
		FabVariant.SMALL:
			return 24.0
		FabVariant.STANDARD:
			return 24.0
		FabVariant.LARGE:
			return 36.0
		FabVariant.EXTENDED:
			return 24.0
	return 24.0

func _get_container_color() -> Color:
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)

	match color_palette:
		FabColorPalette.PRIMARY:
			return get_m3_color(&"primary_container")
		FabColorPalette.SURFACE:
			var base_surf := get_m3_color(&"surface_container_high")
			var tint_col := get_m3_color(&"surface_tint")
			return M3Elevation.get_surface_tinted_color(base_surf, tint_col, _current_elevation)
		FabColorPalette.SECONDARY:
			return get_m3_color(&"secondary_container")
		FabColorPalette.TERTIARY:
			return get_m3_color(&"tertiary_container")
	return get_m3_color(&"primary_container")

func _get_content_color() -> Color:
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTENT_OPACITY)

	match color_palette:
		FabColorPalette.PRIMARY:
			return get_m3_color(&"on_primary_container")
		FabColorPalette.SURFACE:
			return get_m3_color(&"primary")
		FabColorPalette.SECONDARY:
			return get_m3_color(&"on_secondary_container")
		FabColorPalette.TERTIARY:
			return get_m3_color(&"on_tertiary_container")
	return get_m3_color(&"on_primary_container")

func _update_colors() -> void:
	if _ripple != null and is_instance_valid(_ripple):
		_ripple.set("ripple_color", _get_content_color())

func _gui_input(event: InputEvent) -> void:
	if not disabled and collapse_on_scroll and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and extended:
				set_extended(false)
				accept_event()
				return
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and not extended:
				set_extended(true)
				accept_event()
				return
	super._gui_input(event)

func _on_pressed_action() -> void:
	if toggle_extended_on_press:
		set_extended(not extended)
	pressed.emit()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var radius: float = get_effective_corner_radius()

	# Drop shadow
	if _current_elevation > 0:
		var shadow_props := M3Elevation.get_shadow_props(_current_elevation)
		var offset_y: float = shadow_props.get("offset_y", 4.0)
		var blur: float = shadow_props.get("blur", 8.0)
		var alpha: float = shadow_props.get("alpha", 0.18)
		var shadow_sb := StyleBoxFlat.new()
		shadow_sb.bg_color = Color.TRANSPARENT
		shadow_sb.set_corner_radius_all(int(radius))
		shadow_sb.shadow_color = Color(0, 0, 0, alpha)
		shadow_sb.shadow_size = int(blur)
		shadow_sb.shadow_offset = Vector2(0, offset_y)
		draw_style_box(shadow_sb, r)

	# Container
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = _get_container_color()
	bg_sb.set_corner_radius_all(int(radius))
	draw_style_box(bg_sb, r)

	# Icon / Content
	var content_col := _get_content_color()
	var ic_s := _get_effective_icon_size()
	var has_ic: bool = (icon_name != &"" or icon_texture != null)

	if fab_variant == FabVariant.EXTENDED or extend_progress > 0.01:
		var text_w: float = 0.0
		if _font != null and not label.is_empty():
			text_w = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x * extend_progress

		var gap_w: float = (12.0 * extend_progress) if (has_ic and not label.is_empty()) else 0.0
		var total_content_w: float = (ic_s if has_ic else 0.0) + gap_w + text_w
		var cur_x: float = (size.x - total_content_w) * 0.5

		if has_ic:
			var ic_r := Rect2(cur_x, (size.y - ic_s) * 0.5, ic_s, ic_s)
			_draw_fab_icon(ic_r, content_col)
			cur_x += ic_s + gap_w

		if _font != null and not label.is_empty() and extend_progress > 0.15:
			var label_alpha: float = clampf((extend_progress - 0.15) / 0.85, 0.0, 1.0)
			var text_col := Color(content_col.r, content_col.g, content_col.b, content_col.a * label_alpha)
			var font_ascent := _font.get_ascent(_font_size)
			var text_y := (size.y - _font.get_height(_font_size)) * 0.5 + font_ascent
			var avail_w: float = maxf(1.0, size.x - cur_x - 12.0)
			draw_string(_font, Vector2(cur_x, text_y), label, HORIZONTAL_ALIGNMENT_LEFT, avail_w, _font_size, text_col)
	else:
		var ic_r := Rect2((size.x - ic_s) * 0.5, (size.y - ic_s) * 0.5, ic_s, ic_s)
		_draw_fab_icon(ic_r, content_col)

func _draw_fab_icon(target_rect: Rect2, color: Color) -> void:
	if icon_texture != null:
		draw_texture_rect(icon_texture, target_rect, false, color)
		return
	if icon_name == &"":
		return

	var center := target_rect.get_center()
	var scale_factor := target_rect.size.x / 24.0
	var sw: float = maxf(1.5, 2.5 * scale_factor)
	var rot_rad: float = deg_to_rad(icon_rotation_deg)
	var t := func(p: Vector2) -> Vector2:
		var offset: Vector2 = (p - Vector2(12.0, 12.0)) * scale_factor
		if not is_zero_approx(rot_rad):
			offset = offset.rotated(rot_rad)
		return center + offset

	var key := String(icon_name).to_lower().replace("-", "_")
	match key:
		"add", "plus":
			draw_line(t.call(Vector2(12, 5)), t.call(Vector2(12, 19)), color, sw, true)
			draw_line(t.call(Vector2(5, 12)), t.call(Vector2(19, 12)), color, sw, true)
		"close", "cross", "clear":
			draw_line(t.call(Vector2(6, 6)), t.call(Vector2(18, 18)), color, sw, true)
			draw_line(t.call(Vector2(18, 6)), t.call(Vector2(6, 18)), color, sw, true)
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
			var body := PackedVector2Array([t.call(Vector2(6, 6)), t.call(Vector2(7, 20)), t.call(Vector2(17, 20)), t.call(Vector2(18, 6))])
			draw_polyline(body, color, sw, true)
		_:
			draw_circle(center, 4.0 * scale_factor, color)
