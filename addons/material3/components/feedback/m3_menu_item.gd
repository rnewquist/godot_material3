@tool
class_name M3MenuItem
extends M3BaseControl

signal clicked(id: int, label: String)

@export var id: int = 0
@export var label: String = "Menu Item":
	set(value):
		label = value
		_update_size()

@export var icon: Texture2D = null:
	set(value):
		icon = value
		_update_size()

@export var icon_name: StringName = &"":
	set(value):
		icon_name = value
		_update_size()

@export var trailing_icon: Texture2D = null:
	set(value):
		trailing_icon = value
		_update_size()

@export var trailing_icon_name: StringName = &"":
	set(value):
		trailing_icon_name = value
		_update_size()

@export var shortcut_text: String = "":
	set(value):
		shortcut_text = value
		_update_size()

@export var is_divider: bool = false:
	set(value):
		is_divider = value
		_update_size()

@export var is_group_break: bool = false:
	set(value):
		is_group_break = value
		_update_size()

var submenu: Control = null

func _init() -> void:
	_update_size()

func _ready() -> void:
	super._ready()
	_update_size()

func _update_size() -> void:
	if is_group_break:
		custom_minimum_size = Vector2(200, 6)
		mouse_filter = MOUSE_FILTER_IGNORE
	elif is_divider:
		custom_minimum_size = Vector2(200, 9)
		mouse_filter = MOUSE_FILTER_IGNORE
	else:
		var font := ThemeDB.fallback_font
		var lbl_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x if font else 80.0
		var sc_w: float = (font.get_string_size(shortcut_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12).x + 24.0) if (font and shortcut_text != "") else 0.0
		var lead_w: float = 36.0 if (icon != null or icon_name != &"") else 0.0
		var trail_w: float = 32.0 if (trailing_icon != null or trailing_icon_name != &"") else 0.0
		var min_w: float = clampf(16.0 + lead_w + lbl_w + sc_w + trail_w + 16.0, 200.0, 280.0)
		custom_minimum_size = Vector2(min_w, 48)
		mouse_filter = MOUSE_FILTER_STOP
	size = Vector2(maxf(size.x, custom_minimum_size.x), custom_minimum_size.y)
	update_minimum_size()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if disabled or is_divider:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			if _ripple_effect and _ripple_effect.has_method("start_press"):
				_ripple_effect.start_press(event.position)
			queue_redraw()
			accept_event()
		else:
			if is_pressed:
				is_pressed = false
				if _ripple_effect and _ripple_effect.has_method("end_press"):
					_ripple_effect.end_press()
				if Rect2(Vector2.ZERO, size).has_point(event.position):
					clicked.emit(id, label)
				queue_redraw()
				accept_event()

func _draw() -> void:
	var s := get_scheme()
	var rect := Rect2(Vector2.ZERO, size)

	if is_group_break:
		return

	if is_divider:
		draw_line(Vector2(0, 4), Vector2(size.x, 4), s.outline_variant, 1.0)
		return

	# Hover/Pressed overlay
	if not disabled:
		if is_hovered:
			var ov := s.on_surface
			ov.a = 0.08
			draw_rect(rect, ov)
		if is_pressed:
			var ov := s.on_surface
			ov.a = 0.12
			draw_rect(rect, ov)

	var x_cursor: float = 12.0
	var center_y: float = size.y * 0.5
	var font := ThemeDB.fallback_font
	var text_col := s.on_surface if not disabled else Color(s.on_surface, M3Color.DISABLED_CONTENT_OPACITY)
	var icon_col := s.on_surface_variant if not disabled else Color(s.on_surface_variant, M3Color.DISABLED_CONTENT_OPACITY)

	# Leading Icon
	if icon != null:
		var icon_sz := Vector2(20, 20)
		draw_texture_rect(icon, Rect2(Vector2(x_cursor, center_y - 10.0), icon_sz), false, icon_col)
		x_cursor += 32.0
	elif icon_name != &"":
		_draw_glyph(icon_name, Vector2(x_cursor + 10.0, center_y), 20.0, icon_col)
		x_cursor += 32.0

	# Trailing Icon or Shortcut
	if trailing_icon != null:
		var t_sz := Vector2(20, 20)
		draw_texture_rect(trailing_icon, Rect2(Vector2(size.x - 12.0 - t_sz.x, center_y - 10.0), t_sz), false, icon_col)
	elif trailing_icon_name != &"":
		_draw_glyph(trailing_icon_name, Vector2(size.x - 22.0, center_y), 20.0, icon_col)
	elif shortcut_text != "" and font:
		var sc_sz := font.get_string_size(shortcut_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12)
		var sc_pos := Vector2(size.x - 12.0 - sc_sz.x, center_y + sc_sz.y * 0.35)
		draw_string(font, sc_pos, shortcut_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, icon_col)

	# Label
	if label != "" and font:
		var lbl_pos := Vector2(x_cursor, center_y + 5.0)
		draw_string(font, lbl_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_col)

func _draw_glyph(glyph_name: StringName, center: Vector2, glyph_size: float, col: Color) -> void:
	var scale_f: float = glyph_size / 24.0
	var sw: float = maxf(1.4, 2.0 * scale_f)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_f
	var key := String(glyph_name).to_lower().replace("-", "_")
	match key:
		"check", "checkmark":
			draw_polyline(PackedVector2Array([t.call(Vector2(5, 12)), t.call(Vector2(10, 17)), t.call(Vector2(19, 7))]), col, sw, true)
		"chevron_right", "arrow_right":
			draw_polyline(PackedVector2Array([t.call(Vector2(9, 6)), t.call(Vector2(15, 12)), t.call(Vector2(9, 18))]), col, sw, true)
		"edit", "pencil":
			draw_polyline(PackedVector2Array([t.call(Vector2(5, 19)), t.call(Vector2(9, 18)), t.call(Vector2(18, 9)), t.call(Vector2(15, 6)), t.call(Vector2(6, 15)), t.call(Vector2(5, 19))]), col, sw, true)
		"delete", "trash":
			draw_line(t.call(Vector2(4, 6)), t.call(Vector2(20, 6)), col, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(6, 6)), t.call(Vector2(7, 20)), t.call(Vector2(17, 20)), t.call(Vector2(18, 6))]), col, sw, true)
		"copy", "content_copy":
			draw_rect(Rect2(t.call(Vector2(8, 8)), Vector2(11, 12) * scale_f), col, false, sw)
			draw_polyline(PackedVector2Array([t.call(Vector2(16, 5)), t.call(Vector2(5, 5)), t.call(Vector2(5, 17))]), col, sw, true)
		"share":
			draw_circle(t.call(Vector2(17, 6)), 2.2 * scale_f, col)
			draw_circle(t.call(Vector2(7, 12)), 2.2 * scale_f, col)
			draw_circle(t.call(Vector2(17, 18)), 2.2 * scale_f, col)
			draw_line(t.call(Vector2(7, 12)), t.call(Vector2(17, 6)), col, sw, true)
			draw_line(t.call(Vector2(7, 12)), t.call(Vector2(17, 18)), col, sw, true)
		_:
			draw_arc(center, 6.0 * scale_f, 0, TAU, 20, col, sw, true)
