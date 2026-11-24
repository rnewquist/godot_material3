@tool
class_name M3ListItem
extends M3BaseControl

## Material 3 List Item component (https://m3.material.io/components/lists/overview).
## Supports 1-line (56dp), 2-line (72dp), and 3-line (88dp) heights, leading icon/avatar/control,
## trailing text/icon/control, interactive ripple & hover/press state layer, and selection animation.

signal clicked
signal pressed
signal selected_changed(is_selected: bool)

enum ItemLines {
	ONE_LINE,
	TWO_LINE,
	THREE_LINE
}

enum LeadingType {
	NONE,
	ICON,
	AVATAR,
	CUSTOM
}

enum TrailingType {
	NONE,
	TEXT,
	ICON,
	CUSTOM
}

@export var lines: ItemLines = ItemLines.ONE_LINE:
	set(value):
		lines = value
		_update_height()

@export var headline: String = "List Item":
	set(value):
		headline = value
		queue_redraw()

@export var supporting_text: String = "":
	set(value):
		supporting_text = value
		if not supporting_text.is_empty():
			if supporting_text.contains("\n"):
				lines = ItemLines.THREE_LINE
			elif lines == ItemLines.ONE_LINE:
				lines = ItemLines.TWO_LINE
		_update_height()
		queue_redraw()

@export var overline_text: String = "":
	set(value):
		overline_text = value
		queue_redraw()

@export var trailing_text: String = "":
	set(value):
		trailing_text = value
		queue_redraw()

@export var leading_type: LeadingType = LeadingType.NONE:
	set(value):
		leading_type = value
		_layout_custom_slots()
		queue_redraw()

@export var leading_icon: Texture2D = null:
	set(value):
		leading_icon = value
		queue_redraw()

@export var leading_icon_name: StringName = &"":
	set(value):
		leading_icon_name = value
		if leading_icon_name != &"" and leading_type == LeadingType.NONE:
			leading_type = LeadingType.ICON
		queue_redraw()

@export var trailing_type: TrailingType = TrailingType.NONE:
	set(value):
		trailing_type = value
		_layout_custom_slots()
		queue_redraw()

@export var trailing_icon: Texture2D = null:
	set(value):
		trailing_icon = value
		queue_redraw()

@export var trailing_icon_name: StringName = &"":
	set(value):
		trailing_icon_name = value
		if trailing_icon_name != &"" and trailing_type == TrailingType.NONE:
			trailing_type = TrailingType.ICON
		queue_redraw()

@export var selected: bool = false:
	set(value):
		if selected != value:
			selected = value
			_animate_selection(selected)
			selected_changed.emit(selected)
			queue_redraw()

@export var clickable: bool = true:
	set(value):
		clickable = value
		mouse_filter = MOUSE_FILTER_STOP if clickable else MOUSE_FILTER_PASS

@export var toggle_selection_on_click: bool = false

var _select_progress: float = 0.0:
	set(value):
		_select_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _state_layer_alpha: float = 0.0:
	set(value):
		_state_layer_alpha = value
		queue_redraw()

var _ripple_wave_radius: float = 0.0
var _ripple_wave_alpha: float = 0.0
var _ripple_wave_count: int = 0

var _leading_control: Control = null
var _trailing_control: Control = null
var _select_tween: Tween = null

func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_select_progress = 1.0 if selected else 0.0
	_update_height()

func _ready() -> void:
	super._ready()
	_select_progress = 1.0 if selected else 0.0
	if not resized.is_connected(_on_item_resized):
		resized.connect(_on_item_resized)
	_update_height()
	_layout_custom_slots()

func _on_item_resized() -> void:
	_layout_custom_slots()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func set_leading_control(c: Control) -> void:
	if _leading_control and is_instance_valid(_leading_control) and _leading_control.get_parent() == self:
		remove_child(_leading_control)
	_leading_control = c
	if _leading_control:
		leading_type = LeadingType.CUSTOM
		if _leading_control.get_parent() != self:
			add_child(_leading_control)
	_layout_custom_slots()
	queue_redraw()

func set_trailing_control(c: Control) -> void:
	if _trailing_control and is_instance_valid(_trailing_control) and _trailing_control.get_parent() == self:
		remove_child(_trailing_control)
	_trailing_control = c
	if _trailing_control:
		trailing_type = TrailingType.CUSTOM
		if _trailing_control.get_parent() != self:
			add_child(_trailing_control)
	_layout_custom_slots()
	queue_redraw()

func _layout_custom_slots() -> void:
	var cy: float = size.y * 0.5
	if _leading_control and is_instance_valid(_leading_control):
		var ls: Vector2 = _leading_control.get_combined_minimum_size()
		if ls == Vector2.ZERO:
			ls = Vector2(24, 24)
		_leading_control.size = ls
		_leading_control.position = Vector2(16.0, cy - ls.y * 0.5)
	if _trailing_control and is_instance_valid(_trailing_control):
		var ts: Vector2 = _trailing_control.get_combined_minimum_size()
		if ts == Vector2.ZERO:
			ts = Vector2(40, 24)
		_trailing_control.size = ts
		_trailing_control.position = Vector2(maxf(16.0, size.x - 16.0 - ts.x), cy - ts.y * 0.5)

func _animate_selection(target_sel: bool) -> void:
	var target: float = 1.0 if target_sel else 0.0
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
	if is_inside_tree():
		_select_tween = create_tween()
		_select_tween.bind_node(self)
		_select_tween.set_trans(Tween.TRANS_CUBIC)
		_select_tween.set_ease(Tween.EASE_OUT)
		_select_tween.tween_property(self, ^"_select_progress", target, 0.18)
	else:
		_select_progress = target

func _update_height() -> void:
	var h: float = 56.0
	match lines:
		ItemLines.ONE_LINE: h = 56.0
		ItemLines.TWO_LINE: h = 72.0
		ItemLines.THREE_LINE: h = 88.0
	custom_minimum_size = Vector2(200, h)
	size = Vector2(maxf(size.x, custom_minimum_size.x), h)
	_layout_custom_slots()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not clickable or disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			is_pressed = true
			if _ripple_effect:
				_ripple_effect.ripple_color = get_scheme().on_surface
				_ripple_effect.start_press(mb.position)
			pressed.emit()
			queue_redraw()
			accept_event()
		else:
			if is_pressed:
				is_pressed = false
				if _ripple_effect:
					_ripple_effect.end_press()
				if toggle_selection_on_click:
					selected = not selected
				clicked.emit()
				queue_redraw()
				accept_event()

func _draw_vector_glyph(glyph_name: StringName, target_rect: Rect2, col: Color) -> void:
	var center := target_rect.get_center()
	var scale_f := target_rect.size.x / 24.0
	var sw: float = maxf(1.5, 2.0 * scale_f)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_f
	var key := String(glyph_name).to_lower().replace("-", "_")
	match key:
		"check", "checkmark":
			draw_polyline(PackedVector2Array([t.call(Vector2(5, 12)), t.call(Vector2(10, 17)), t.call(Vector2(19, 7))]), col, sw, true)
		"chevron_right", "arrow_right":
			draw_polyline(PackedVector2Array([t.call(Vector2(9, 6)), t.call(Vector2(15, 12)), t.call(Vector2(9, 18))]), col, sw, true)
		"star", "favorite":
			draw_circle(center, 5.0 * scale_f, col)
		"person", "account":
			draw_circle(t.call(Vector2(12, 8)), 3.5 * scale_f, col)
			draw_arc(t.call(Vector2(12, 19)), 6.0 * scale_f, PI, TAU, 16, col, sw, true)
		_:
			draw_circle(center, 4.5 * scale_f, col)

func _draw() -> void:
	var s := get_scheme()
	var rect := Rect2(Vector2.ZERO, size)

	# Base surface background
	draw_rect(rect, s.surface, true)

	# Selected container background (animated via _select_progress)
	if selected or _select_progress > 0.001:
		var sel_col := s.secondary_container
		sel_col.a = _select_progress if not selected else maxf(0.2, _select_progress)
		draw_rect(rect, sel_col, true)

	# Hover/Press state layer
	if clickable and not disabled:
		var alpha: float = _state_layer_alpha
		if is_pressed:
			alpha = maxf(alpha, 0.12)
		elif is_hovered:
			alpha = maxf(alpha, 0.08)
		if alpha > 0.001:
			var ov := s.on_surface
			ov.a = alpha
			draw_rect(rect, ov, true)

	var x_cursor: float = 16.0
	var center_y: float = size.y * 0.5
	var font := get_theme_default_font()

	# Leading Slot
	if leading_type == LeadingType.ICON:
		var icon_rect := Rect2(Vector2(x_cursor, center_y - 12.0), Vector2(24, 24))
		if leading_icon:
			draw_texture_rect(leading_icon, icon_rect, false, s.on_surface_variant)
		else:
			_draw_vector_glyph(leading_icon_name if leading_icon_name != &"" else &"person", icon_rect, s.on_surface_variant)
		x_cursor += 40.0
	elif leading_type == LeadingType.AVATAR:
		var avatar_pos := Vector2(x_cursor + 20.0, center_y)
		draw_circle(avatar_pos, 20.0, s.primary_container)
		if leading_icon:
			draw_texture_rect(leading_icon, Rect2(Vector2(x_cursor + 8.0, center_y - 12.0), Vector2(24, 24)), false, s.on_primary_container)
		elif font and headline != "":
			var initial := headline.left(1).to_upper()
			var init_sz := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
			draw_string(font, Vector2(avatar_pos.x - init_sz.x * 0.5, avatar_pos.y + init_sz.y * 0.35), initial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, s.on_primary_container)
		x_cursor += 56.0
	elif leading_type == LeadingType.CUSTOM and _leading_control:
		x_cursor += _leading_control.size.x + 16.0

	# Trailing width calculation
	var trailing_w: float = 0.0
	if trailing_type == TrailingType.TEXT and trailing_text != "" and font:
		var t_sz := font.get_string_size(trailing_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12)
		trailing_w = t_sz.x + 16.0
		var t_pos := Vector2(size.x - 16.0 - t_sz.x, center_y + t_sz.y * 0.35)
		draw_string(font, t_pos, trailing_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, s.on_surface_variant)
	elif trailing_type == TrailingType.ICON:
		trailing_w = 40.0
		var icon_rect := Rect2(Vector2(size.x - 40.0, center_y - 12.0), Vector2(24, 24))
		if trailing_icon:
			draw_texture_rect(trailing_icon, icon_rect, false, s.on_surface_variant)
		else:
			_draw_vector_glyph(trailing_icon_name if trailing_icon_name != &"" else &"chevron_right", icon_rect, s.on_surface_variant)
	elif trailing_type == TrailingType.CUSTOM and _trailing_control:
		trailing_w = _trailing_control.size.x + 16.0

	# Middle Content (Overline, Headline, Supporting Text)
	var content_w: float = maxf(24.0, size.x - x_cursor - trailing_w - 16.0)
	if font:
		var hl_col := s.on_secondary_container if selected else s.on_surface
		if lines == ItemLines.ONE_LINE:
			var hl_sz := font.get_string_size(headline, HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 16)
			var hl_pos := Vector2(x_cursor, center_y + hl_sz.y * 0.35)
			draw_string(font, hl_pos, headline, HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 16, hl_col)
		elif lines == ItemLines.TWO_LINE:
			draw_string(font, Vector2(x_cursor, center_y - 4.0), headline, HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 16, hl_col)
			draw_string(font, Vector2(x_cursor, center_y + 16.0), supporting_text, HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 14, s.on_surface_variant)
		elif lines == ItemLines.THREE_LINE:
			var y_pos: float = 24.0
			if overline_text != "":
				draw_string(font, Vector2(x_cursor, y_pos), overline_text, HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 12, s.on_surface_variant)
				y_pos += 20.0
			draw_string(font, Vector2(x_cursor, y_pos), headline, HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 16, hl_col)
			y_pos += 20.0
			var supp_lines := supporting_text.split("\n", false)
			if supp_lines.size() > 1:
				draw_string(font, Vector2(x_cursor, y_pos), supp_lines[0], HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 14, s.on_surface_variant)
				draw_string(font, Vector2(x_cursor, y_pos + 18.0), supp_lines[1], HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 14, s.on_surface_variant)
			else:
				draw_string(font, Vector2(x_cursor, y_pos), supporting_text, HORIZONTAL_ALIGNMENT_LEFT, int(content_w), 14, s.on_surface_variant)
