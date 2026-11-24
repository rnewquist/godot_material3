@tool
class_name M3TextField
extends M3Control

## Material 3 Text Field component with Filled & Outlined variants, animated floating label,
## procedural outlined border notch, helper/error text, and character counter.

enum Variant {
	FILLED,
	OUTLINED
}

enum FieldType {
	FILLED,
	OUTLINED
}

signal text_changed(new_text: String)
signal text_submitted(text: String)
signal trailing_icon_pressed()

@export var variant: Variant = Variant.FILLED:
	set(value):
		variant = value
		queue_redraw()

@export var field_type: FieldType:
	get:
		return variant as int as FieldType
	set(value):
		variant = value as int as Variant

@export var text: String = "":
	set(value):
		if text != value:
			text = value
			if _line_edit != null and _line_edit.text != value:
				_line_edit.text = value
			if _text_edit != null and _text_edit.text != value:
				_text_edit.text = value
			_update_label_floating()
			if multiline:
				_recalculate_target_height(is_inside_tree())
			text_changed.emit(text)
			queue_redraw()

@export var label: String = "Label":
	set(value):
		label = value
		queue_redraw()

@export var label_text: String:
	get:
		return label
	set(value):
		label = value
		queue_redraw()

@export var placeholder: String = "":
	set(value):
		placeholder = value
		if _line_edit != null:
			_line_edit.placeholder_text = value
		_update_label_floating()
		queue_redraw()

@export var helper_text: String = "":
	set(value):
		helper_text = value
		_update_min_size()
		queue_redraw()

@export var supporting_text: String:
	get:
		return helper_text
	set(value):
		helper_text = value

@export var error_text: String = "":
	set(value):
		error_text = value
		_update_min_size()
		queue_redraw()

@export var is_error: bool = false:
	set(value):
		is_error = value
		_apply_line_edit_colors()
		queue_redraw()

@export var leading_icon: StringName = &"":
	set(value):
		leading_icon = value
		_layout_internal_elements()
		queue_redraw()

@export var leading_icon_texture: Texture2D = null:
	set(value):
		leading_icon_texture = value
		_layout_internal_elements()
		queue_redraw()

@export var trailing_icon: StringName = &"":
	set(value):
		trailing_icon = value
		_layout_internal_elements()
		queue_redraw()

@export var trailing_icon_texture: Texture2D = null:
	set(value):
		trailing_icon_texture = value
		_layout_internal_elements()
		queue_redraw()

@export var show_clear_button: bool = false:
	set(value):
		show_clear_button = value
		_layout_internal_elements()
		queue_redraw()

@export var show_password_toggle: bool = false:
	set(value):
		show_password_toggle = value
		_layout_internal_elements()
		queue_redraw()

@export var secret: bool = false:
	set(value):
		secret = value
		if _line_edit != null:
			_line_edit.secret = value
		queue_redraw()

@export var is_password: bool:
	get:
		return secret
	set(value):
		secret = value
		show_password_toggle = value

@export var max_length: int = 0:
	set(value):
		max_length = maxi(0, value)
		if _line_edit != null:
			_line_edit.max_length = max_length
		queue_redraw()

@export var max_characters: int:
	get:
		return max_length
	set(value):
		max_length = value
		show_counter = (value > 0)

@export var show_counter: bool = false:
	set(value):
		show_counter = value
		_update_min_size()
		queue_redraw()

@export var prefix_text: String = "":
	set(value):
		prefix_text = value
		_layout_internal_elements()
		queue_redraw()

@export var suffix_text: String = "":
	set(value):
		suffix_text = value
		_layout_internal_elements()
		queue_redraw()

@export var multiline: bool = false:
	set(value):
		if multiline != value:
			multiline = value
			_sync_multiline_controls()
			_recalculate_target_height(false)
			_update_min_size()
			queue_redraw()

@export var min_lines: int = 3:
	set(value):
		min_lines = maxi(1, value)
		if max_lines < min_lines:
			max_lines = min_lines
		if multiline:
			_recalculate_target_height(false)
			_update_min_size()
			queue_redraw()

@export var max_lines: int = 6:
	set(value):
		max_lines = maxi(min_lines, value)
		if multiline:
			_recalculate_target_height(false)
			_update_min_size()
			queue_redraw()

var _active_height: float = 56.0:
	set(value):
		_active_height = value
		queue_redraw()

var _line_edit: LineEdit = null
var _text_edit: TextEdit = null
var _label_progress: float = 0.0
var _label_float_progress: float = 0.0
var _focus_progress: float = 0.0
var _label_tween: Tween = null
var _focus_tween: Tween = null
var _height_tween: Tween = null
var _font: Font = null
var _font_size_rest: int = 16
var _font_size_float: int = 12
var _font_size_helper: int = 12
var _is_focused_internal: bool = false

func _init() -> void:
	super._init()
	custom_minimum_size = Vector2(96.0, 56.0)
	size = Vector2(180.0, 56.0)

func _ready() -> void:
	super._ready()
	_update_fonts()
	_setup_internal_line_edit()
	_sync_multiline_controls()
	_recalculate_target_height(false)
	_update_label_floating(false)
	_update_min_size()

func _update_fonts() -> void:
	_font = ThemeDB.fallback_font
	_font_size_rest = 16
	_font_size_float = 12
	_font_size_helper = 12

func _setup_internal_line_edit() -> void:
	if _line_edit == null:
		var found := get_node_or_null(^"M3InternalLineEdit") as LineEdit
		if found != null:
			_line_edit = found
		else:
			_line_edit = LineEdit.new()
			_line_edit.name = "M3InternalLineEdit"
			add_child(_line_edit, false, INTERNAL_MODE_FRONT)

	_line_edit.flat = true
	_line_edit.text = text
	_line_edit.placeholder_text = placeholder
	_line_edit.secret = secret
	_line_edit.max_length = max_length
	_line_edit.context_menu_enabled = true
	_line_edit.mouse_filter = MOUSE_FILTER_STOP

	var empty_sb := StyleBoxEmpty.new()
	_line_edit.add_theme_stylebox_override(&"normal", empty_sb)
	_line_edit.add_theme_stylebox_override(&"focus", empty_sb)
	_line_edit.add_theme_stylebox_override(&"read_only", empty_sb)

	if not _line_edit.text_changed.is_connected(_on_internal_text_changed):
		_line_edit.text_changed.connect(_on_internal_text_changed)
	if not _line_edit.text_submitted.is_connected(_on_internal_text_submitted):
		_line_edit.text_submitted.connect(_on_internal_text_submitted)
	if not _line_edit.focus_entered.is_connected(_on_internal_focus_entered):
		_line_edit.focus_entered.connect(_on_internal_focus_entered)
	if not _line_edit.focus_exited.is_connected(_on_internal_focus_exited):
		_line_edit.focus_exited.connect(_on_internal_focus_exited)

	if _text_edit == null:
		var found_te := get_node_or_null(^"M3InternalTextEdit") as TextEdit
		if found_te != null:
			_text_edit = found_te
		else:
			_text_edit = TextEdit.new()
			_text_edit.name = "M3InternalTextEdit"
			add_child(_text_edit, false, INTERNAL_MODE_FRONT)

	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text_edit.scroll_fit_content_height = false
	_text_edit.text = text
	_text_edit.placeholder_text = placeholder
	_text_edit.context_menu_enabled = true
	_text_edit.mouse_filter = MOUSE_FILTER_STOP
	_text_edit.add_theme_stylebox_override(&"normal", empty_sb)
	_text_edit.add_theme_stylebox_override(&"focus", empty_sb)
	_text_edit.add_theme_stylebox_override(&"read_only", empty_sb)

	if not _text_edit.text_changed.is_connected(_on_internal_text_edit_changed):
		_text_edit.text_changed.connect(_on_internal_text_edit_changed)
	if not _text_edit.focus_entered.is_connected(_on_internal_focus_entered):
		_text_edit.focus_entered.connect(_on_internal_focus_entered)
	if not _text_edit.focus_exited.is_connected(_on_internal_focus_exited):
		_text_edit.focus_exited.connect(_on_internal_focus_exited)

	_sync_multiline_controls()
	_apply_line_edit_colors()
	_layout_internal_elements()

func _sync_multiline_controls() -> void:
	if _line_edit != null:
		_line_edit.visible = not multiline
	if _text_edit != null:
		_text_edit.visible = multiline

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_fonts()
	_apply_line_edit_colors()
	queue_redraw()

func _apply_line_edit_colors() -> void:
	if _line_edit == null:
		return
	var text_col := get_m3_color(&"on_surface")
	if disabled:
		text_col = Color(text_col, M3Color.DISABLED_CONTENT_OPACITY)
	var caret_col := get_m3_color(&"primary") if not is_error else get_m3_color(&"error")
	var sel_col := get_m3_color(&"primary_container")
	_line_edit.add_theme_color_override(&"font_color", text_col)
	_line_edit.add_theme_color_override(&"caret_color", caret_col)
	_line_edit.add_theme_color_override(&"selection_color", sel_col)
	if _text_edit != null:
		_text_edit.add_theme_color_override(&"font_color", text_col)
		_text_edit.add_theme_color_override(&"caret_color", caret_col)
		_text_edit.add_theme_color_override(&"selection_color", sel_col)

func _on_internal_text_changed(new_text: String) -> void:
	if text != new_text:
		text = new_text

func _on_internal_text_edit_changed() -> void:
	if _text_edit != null and text != _text_edit.text:
		text = _text_edit.text

func _on_internal_text_submitted(submitted_text: String) -> void:
	text_submitted.emit(submitted_text)

func _on_focus_entered() -> void:
	super._on_focus_entered()
	if not disabled:
		if multiline and _text_edit != null and not _text_edit.has_focus():
			_text_edit.grab_focus()
		elif not multiline and _line_edit != null and not _line_edit.has_focus():
			_line_edit.grab_focus()
	_on_internal_focus_entered()

func _on_internal_focus_entered() -> void:
	if _is_focused_internal:
		return
	_is_focused_internal = true
	_animate_focus(true)
	_update_label_floating()
	queue_redraw()

func _on_internal_focus_exited() -> void:
	if not _is_focused_internal:
		return
	_is_focused_internal = false
	_animate_focus(false)
	_update_label_floating()
	queue_redraw()

func _animate_focus(focused: bool) -> void:
	var target: float = 1.0 if focused else 0.0
	if not is_inside_tree():
		_focus_progress = target
		queue_redraw()
		return
	if _focus_tween != null and _focus_tween.is_valid():
		_focus_tween.kill()
	_focus_tween = create_tween().set_parallel(true)
	if _focus_tween:
		_focus_tween.bind_node(self)
		_focus_tween.set_trans(Tween.TRANS_CUBIC)
		_focus_tween.set_ease(Tween.EASE_OUT)
		_focus_tween.tween_property(self, ^"_focus_progress", target, 0.2)
		_focus_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)

func _update_label_floating(animate: bool = true) -> void:
	var should_float: bool = _is_focused_internal or not text.is_empty() or not placeholder.is_empty()
	var target: float = 1.0 if should_float else 0.0

	if not animate or not is_inside_tree():
		_label_progress = target
		_label_float_progress = target
		queue_redraw()
		return

	if _label_tween != null and _label_tween.is_valid():
		_label_tween.kill()

	_label_tween = create_tween().set_parallel(true)
	if _label_tween:
		_label_tween.bind_node(self)
		_label_tween.set_trans(Tween.TRANS_CUBIC)
		_label_tween.set_ease(Tween.EASE_OUT)
		_label_tween.tween_property(self, ^"_label_progress", target, 0.2)
		_label_tween.tween_property(self, ^"_label_float_progress", target, 0.2)
		_label_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)

func get_visual_line_count() -> int:
	if text.is_empty():
		return 1
	var raw_lines := text.split("\n")
	var avail_w: float = maxf(80.0, size.x - 32.0)
	var total_lines: int = 0
	for seg in raw_lines:
		if seg.is_empty() or _font == null:
			total_lines += 1
		else:
			var seg_w: float = _font.get_string_size(seg, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_rest).x
			var wrapped: int = maxi(1, int(ceil(seg_w / avail_w)))
			total_lines += wrapped
	return maxi(1, total_lines)

func _compute_target_container_height() -> float:
	if not multiline:
		return 56.0
	var line_cnt: int = clampi(get_visual_line_count(), min_lines, maxi(min_lines, max_lines))
	return maxf(56.0, 36.0 + float(line_cnt) * 22.0)

func _sync_animated_height() -> void:
	var extra_bottom: float = 0.0
	if not helper_text.is_empty() or not error_text.is_empty() or show_counter:
		extra_bottom = 20.0
	custom_minimum_size = Vector2(96.0, _active_height + extra_bottom)
	size.y = maxf(custom_minimum_size.y, _active_height + extra_bottom)
	update_minimum_size()
	_layout_internal_elements()

func _recalculate_target_height(animate: bool = true) -> void:
	var target_h: float = _compute_target_container_height()
	if not animate or not is_inside_tree():
		if _height_tween != null and _height_tween.is_valid():
			_height_tween.kill()
		_active_height = target_h
		_sync_animated_height()
		queue_redraw()
		return

	if absf(target_h - _active_height) <= 0.5:
		_active_height = target_h
		_sync_animated_height()
		return

	if _height_tween != null and _height_tween.is_valid():
		_height_tween.kill()
	_height_tween = create_tween().set_parallel(true)
	if _height_tween:
		_height_tween.bind_node(self)
		_height_tween.set_trans(Tween.TRANS_CUBIC)
		_height_tween.set_ease(Tween.EASE_OUT)
		_height_tween.tween_property(self, ^"_active_height", target_h, 0.2)
		_height_tween.tween_method(func(_v: Variant) -> void:
			_sync_animated_height()
			queue_redraw()
		, 0.0, 1.0, 0.2)

func _update_min_size() -> void:
	var container_h: float = _active_height if multiline else 56.0
	var extra_bottom: float = 0.0
	if not helper_text.is_empty() or not error_text.is_empty() or show_counter:
		extra_bottom = 20.0
	custom_minimum_size = Vector2(96.0, container_h + extra_bottom)
	if multiline and size.y < custom_minimum_size.y:
		size.y = custom_minimum_size.y
	update_minimum_size()
	_layout_internal_elements()

func _get_prefix_offset() -> float:
	if prefix_text.is_empty() or _font == null:
		return 0.0
	return _font.get_string_size(prefix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_rest).x + 6.0

func _get_suffix_offset() -> float:
	if suffix_text.is_empty() or _font == null:
		return 0.0
	return _font.get_string_size(suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_rest).x + 6.0

func _layout_internal_elements() -> void:
	if _line_edit == null:
		return

	var has_leading: bool = (leading_icon != &"" or leading_icon_texture != null)
	var has_trailing: bool = (trailing_icon != &"" or trailing_icon_texture != null or show_clear_button or show_password_toggle)

	var base_left_pad: float = 44.0 if has_leading else 16.0
	var base_right_pad: float = 44.0 if has_trailing else 16.0
	var left_pad: float = base_left_pad + _get_prefix_offset()
	var right_pad: float = base_right_pad + _get_suffix_offset()
	var container_h: float = _active_height if multiline else 56.0

	var edit_top: float = 18.0 if (variant == Variant.FILLED and not label.is_empty()) else 12.0
	var edit_h: float = maxf(28.0, container_h - edit_top - 8.0) if multiline else 28.0

	var edit_w: float = maxf(10.0, size.x - left_pad - right_pad)
	_line_edit.position = Vector2(left_pad, edit_top)
	_line_edit.size = Vector2(edit_w, 28.0)
	if _text_edit != null:
		_text_edit.position = Vector2(left_pad, edit_top)
		_text_edit.size = Vector2(edit_w, edit_h)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_internal_elements()

func append_line(line_text: String) -> void:
	if text.is_empty():
		text = line_text
	else:
		text = text + "\n" + line_text

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var container_h: float = _active_height if multiline else 56.0
			var has_trailing: bool = (trailing_icon != &"" or trailing_icon_texture != null or show_clear_button or show_password_toggle)
			var trailing_rect := Rect2(size.x - 48.0, 0.0, 48.0, minf(56.0, container_h))
			if has_trailing and trailing_rect.has_point(mb.position):
				if (show_clear_button or trailing_icon == &"clear" or trailing_icon == &"close") and not text.is_empty():
					text = ""
					trailing_icon_pressed.emit()
					accept_event()
					return
				elif show_password_toggle:
					secret = not secret
					trailing_icon_pressed.emit()
					accept_event()
					return
				else:
					trailing_icon_pressed.emit()
					accept_event()
					return

			if multiline and _text_edit != null:
				_text_edit.grab_focus()
				accept_event()
			elif _line_edit != null:
				_line_edit.grab_focus()
				accept_event()

func _draw() -> void:
	var container_h: float = _active_height if multiline else 56.0
	var container_rect := Rect2(0, 0, size.x, container_h)

	var primary_col := get_m3_color(&"primary")
	var error_col := get_m3_color(&"error")
	var outline_col := get_m3_color(&"outline")
	var surf_highest := get_m3_color(&"surface_container_highest")
	var on_surf_var := get_m3_color(&"on_surface_variant")
	var on_surf_col := get_m3_color(&"on_surface")

	var active_color: Color = error_col if is_error else (primary_col if _is_focused_internal else on_surf_var)
	if disabled:
		active_color = Color(on_surf_col, M3Color.DISABLED_CONTAINER_OPACITY)

	var has_leading: bool = (leading_icon != &"" or leading_icon_texture != null)
	var label_start_x: float = 44.0 if has_leading else 16.0

	# 1. Background & Borders
	if variant == Variant.FILLED:
		var sb := StyleBoxFlat.new()
		sb.bg_color = surf_highest if not disabled else Color(on_surf_col, M3Color.DISABLED_CONTAINER_OPACITY * 0.5)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 0
		sb.corner_radius_bottom_right = 0
		draw_style_box(sb, container_rect)

		var line_h: float = 2.0 if _is_focused_internal else 1.0
		var line_color: Color = active_color if (_is_focused_internal or is_error) else on_surf_var
		if disabled:
			line_color = Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
		draw_line(Vector2(0, container_h - line_h * 0.5), Vector2(size.x, container_h - line_h * 0.5), line_color, line_h)

	else: # OUTLINED
		var border_w: float = 2.0 if _is_focused_internal else 1.0
		var border_c: Color = active_color if (_is_focused_internal or is_error) else outline_col
		if disabled:
			border_c = Color(on_surf_col, M3Color.DISABLED_CONTAINER_OPACITY)

		var radius: float = 4.0

		if not label.is_empty() and _label_progress > 0.01 and _font != null:
			var label_str_w: float = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_float).x
			var notch_start: float = label_start_x - 4.0
			var notch_end: float = label_start_x + label_str_w + 4.0

			if notch_start > radius:
				draw_line(Vector2(radius, 0), Vector2(notch_start, 0), border_c, border_w)
			if size.x - radius > notch_end:
				draw_line(Vector2(notch_end, 0), Vector2(size.x - radius, 0), border_c, border_w)

			draw_line(Vector2(size.x, radius), Vector2(size.x, container_h - radius), border_c, border_w)
			draw_line(Vector2(size.x - radius, container_h), Vector2(radius, container_h), border_c, border_w)
			draw_line(Vector2(0, container_h - radius), Vector2(0, radius), border_c, border_w)

			draw_arc(Vector2(radius, radius), radius, PI, 1.5 * PI, 8, border_c, border_w)
			draw_arc(Vector2(size.x - radius, radius), radius, 1.5 * PI, TAU, 8, border_c, border_w)
			draw_arc(Vector2(size.x - radius, container_h - radius), radius, 0, 0.5 * PI, 8, border_c, border_w)
			draw_arc(Vector2(radius, container_h - radius), radius, 0.5 * PI, PI, 8, border_c, border_w)
		else:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color.TRANSPARENT
			sb.border_color = border_c
			sb.set_border_width_all(int(border_w))
			sb.set_corner_radius_all(int(radius))
			draw_style_box(sb, container_rect)

	# 2. Floating Label
	if not label.is_empty() and _font != null:
		var rest_box_h: float = 56.0 if multiline else container_h
		var rest_y: float = (rest_box_h - _font.get_height(_font_size_rest)) * 0.5 + _font.get_ascent(_font_size_rest)
		var float_y: float = (16.0 if variant == Variant.FILLED else 0.0) + _font.get_ascent(_font_size_float) * 0.5
		if variant == Variant.OUTLINED:
			float_y = _font.get_ascent(_font_size_float) * 0.5 - 2.0

		var cur_y: float = lerpf(rest_y, float_y, _label_progress)
		var cur_size: int = int(round(lerpf(float(_font_size_rest), float(_font_size_float), _label_progress)))
		var cur_label_color: Color = active_color if _is_focused_internal or is_error else on_surf_var
		if disabled:
			cur_label_color = Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)

		draw_string(_font, Vector2(label_start_x, cur_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, cur_size, cur_label_color)

	# 2b. Prefix & Suffix Affixes (shown when focused or non-empty, faded by _label_float_progress)
	var has_trailing: bool = (trailing_icon != &"" or trailing_icon_texture != null or show_clear_button or show_password_toggle)
	if (not prefix_text.is_empty() or not suffix_text.is_empty()) and _label_float_progress > 0.01 and _font != null:
		var edit_top: float = 18.0 if (variant == Variant.FILLED and not label.is_empty()) else 12.0
		var affix_y: float = edit_top + (28.0 - _font.get_height(_font_size_rest)) * 0.5 + _font.get_ascent(_font_size_rest)
		var affix_base_col: Color = on_surf_var if not disabled else Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
		var affix_col := Color(affix_base_col, affix_base_col.a * clampf(_label_float_progress, 0.0, 1.0))

		if not prefix_text.is_empty():
			draw_string(_font, Vector2(label_start_x, affix_y), prefix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_rest, affix_col)

		if not suffix_text.is_empty():
			var base_right_pad: float = 44.0 if has_trailing else 16.0
			var suf_w: float = _font.get_string_size(suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_rest).x
			draw_string(_font, Vector2(size.x - base_right_pad - suf_w, affix_y), suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_rest, affix_col)

	# 3. Leading Icon
	if has_leading:
		var ic_y: float = 16.0 if multiline else (container_h - 24.0) * 0.5
		var ic_rect := Rect2(12.0, ic_y, 24.0, 24.0)
		_draw_input_icon(leading_icon, leading_icon_texture, ic_rect, on_surf_var if not disabled else Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY))

	# 4. Trailing Icon / Actions
	if has_trailing:
		var ic_y: float = 16.0 if multiline else (container_h - 24.0) * 0.5
		var ic_rect := Rect2(size.x - 36.0, ic_y, 24.0, 24.0)
		var icon_col := on_surf_var if not disabled else Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
		if is_error:
			icon_col = error_col

		if show_clear_button and not text.is_empty():
			_draw_vector_path("clear", ic_rect.get_center(), 24.0, icon_col)
		elif show_password_toggle:
			_draw_vector_path("visibility_off" if secret else "visibility", ic_rect.get_center(), 24.0, icon_col)
		elif trailing_icon_texture != null:
			draw_texture_rect(trailing_icon_texture, ic_rect, false, icon_col)
		elif trailing_icon != &"":
			_draw_vector_path(String(trailing_icon), ic_rect.get_center(), 24.0, icon_col)

	# 5. Supporting Text / Error Text & Counter
	var support_y: float = container_h + 14.0
	if _font != null:
		var show_err: bool = is_error and not error_text.is_empty()
		var msg_text: String = error_text if show_err else helper_text
		if not msg_text.is_empty():
			var msg_col := error_col if show_err else on_surf_var
			if disabled:
				msg_col = Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
			draw_string(_font, Vector2(16.0, support_y), msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_helper, msg_col)

		if show_counter:
			var counter_str: String = str(text.length()) + (" / " + str(max_length) if max_length > 0 else "")
			var counter_w := _font.get_string_size(counter_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, _font_size_helper).x
			var count_col := error_col if (max_length > 0 and text.length() > max_length) else on_surf_var
			if disabled:
				count_col = Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
			draw_string(_font, Vector2(size.x - 16.0 - counter_w, support_y), counter_str, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size_helper, count_col)

func _draw_input_icon(ic_name: StringName, ic_tex: Texture2D, target_rect: Rect2, col: Color) -> void:
	if ic_tex != null:
		draw_texture_rect(ic_tex, target_rect, false, col)
	elif ic_name != &"":
		_draw_vector_path(String(ic_name), target_rect.get_center(), target_rect.size.x, col)

func _draw_vector_path(name_str: String, center: Vector2, s: float, col: Color) -> void:
	var scale_factor := s / 24.0
	var sw: float = maxf(1.0, 2.0 * scale_factor)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_factor

	var key := name_str.to_lower().replace("-", "_")
	match key:
		"clear", "close", "cross":
			draw_line(t.call(Vector2(6, 6)), t.call(Vector2(18, 18)), col, sw, true)
			draw_line(t.call(Vector2(18, 6)), t.call(Vector2(6, 18)), col, sw, true)
		"search":
			draw_arc(t.call(Vector2(10.5, 10.5)), 5.5 * scale_factor, 0, TAU, 20, col, sw, true)
			draw_line(t.call(Vector2(14.5, 14.5)), t.call(Vector2(19.5, 19.5)), col, sw, true)
		"visibility", "eye":
			var pts_top: PackedVector2Array = []
			var pts_bot: PackedVector2Array = []
			for i in range(11):
				var px: float = 3.0 + float(i) * 1.8
				var nx: float = (px - 12.0) / 9.0
				var ny: float = (1.0 - nx * nx) * 5.0
				pts_top.append(t.call(Vector2(px, 12.0 - ny)))
				pts_bot.append(t.call(Vector2(px, 12.0 + ny)))
			draw_polyline(pts_top, col, sw, true)
			draw_polyline(pts_bot, col, sw, true)
			draw_circle(t.call(Vector2(12, 12)), 2.8 * scale_factor, col)
		"visibility_off", "eye_off":
			var pts_top: PackedVector2Array = []
			var pts_bot: PackedVector2Array = []
			for i in range(11):
				var px: float = 3.0 + float(i) * 1.8
				var nx: float = (px - 12.0) / 9.0
				var ny: float = (1.0 - nx * nx) * 5.0
				pts_top.append(t.call(Vector2(px, 12.0 - ny)))
				pts_bot.append(t.call(Vector2(px, 12.0 + ny)))
			draw_polyline(pts_top, col, sw, true)
			draw_polyline(pts_bot, col, sw, true)
			draw_line(t.call(Vector2(4, 4)), t.call(Vector2(20, 20)), col, sw, true)
		"person", "account":
			draw_circle(t.call(Vector2(12, 8)), 4.0 * scale_factor, col)
			draw_arc(t.call(Vector2(12, 21)), 7.0 * scale_factor, PI, TAU, 16, col, sw, true)
		_:
			draw_circle(center, 3.0 * scale_factor, col)
