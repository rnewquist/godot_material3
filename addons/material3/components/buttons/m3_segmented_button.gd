@tool
class_name M3SegmentedButton
extends M3Control

## Single segment button used within an M3SegmentedButtonGroup or standalone multi-segment container.

signal segment_pressed(btn: M3SegmentedButton)
signal item_selected(index: int)
signal selection_changed(indices: Array[int])

@export var text: String = "":
	set(value):
		text = value
		_update_min_size()
		queue_redraw()

@export var icon_name: StringName = &"":
	set(value):
		icon_name = value
		_update_min_size()
		queue_redraw()

@export var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		_update_min_size()
		queue_redraw()

@export var selected: bool = false:
	set(value):
		if selected != value:
			selected = value
			_animate_selection()
			_update_min_size()
			queue_redraw()

@export var show_selected_icon: bool = true:
	set(value):
		show_selected_icon = value
		_update_min_size()
		queue_redraw()

@export var is_first: bool = false:
	set(value):
		is_first = value
		_update_shapes()
		queue_redraw()

@export var is_last: bool = false:
	set(value):
		is_last = value
		_update_shapes()
		queue_redraw()

@export var is_single: bool = false:
	set(value):
		is_single = value
		_update_shapes()
		queue_redraw()

@export var segments: Array = []:
	set(value):
		segments = value
		_rebuild_segments()

@export var labels: Array:
	get:
		return segments
	set(value):
		segments = value

var index: int = 0
var _check_scale: float = 0.0
var _hover_progress: float = 0.0
var _press_progress: float = 0.0
var _check_tween: Tween = null
var _motion_tween: Tween = null
var _font: Font = null
var _font_size: int = 14
var _sub_group: M3SegmentedButtonGroup = null

func _init() -> void:
	super._init()
	size_flags_horizontal = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(48.0, 40.0)

func _ready() -> void:
	super._ready()
	_update_font()
	_check_scale = 1.0 if selected else 0.0
	_update_min_size()
	if not segments.is_empty() and _sub_group == null:
		_rebuild_segments()

func _rebuild_segments() -> void:
	if segments.is_empty():
		if _sub_group != null:
			_sub_group.queue_free()
			_sub_group = null
		return

	if _sub_group == null:
		_sub_group = M3SegmentedButtonGroup.new()
		_sub_group.name = "SegmentGroup"
		_sub_group.selection_changed.connect(func(arr: Array[int]) -> void: selection_changed.emit(arr))
		_sub_group.item_selected.connect(func(idx: int) -> void: item_selected.emit(idx))
		add_child(_sub_group)

	for c in _sub_group.get_children():
		c.queue_free()

	for item in segments:
		var lbl: String = ""
		var ic: StringName = &""
		if item is Dictionary:
			lbl = item.get("label", "")
			ic = item.get("icon", &"")
		elif item is String:
			lbl = item
		_sub_group.add_segment(lbl, ic)

	var ms := _sub_group.get_combined_minimum_size()
	custom_minimum_size = Vector2(maxf(ms.x, 144.0), 40.0)
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = custom_minimum_size

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = 14

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()
	if _ripple != null and is_instance_valid(_ripple):
		_ripple.set("ripple_color", _get_content_color())

func _on_state_updated(old_state: ControlState, new_state: ControlState) -> void:
	super._on_state_updated(old_state, new_state)
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

func _animate_selection() -> void:
	var target: float = 1.0 if selected else 0.0
	if not is_inside_tree():
		_check_scale = target
		return
	if _check_tween != null and _check_tween.is_valid():
		_check_tween.kill()

	_check_tween = create_tween()
	if _check_tween:
		_check_tween.bind_node(self)
		_check_tween.set_trans(Tween.TRANS_BACK)
		_check_tween.set_ease(Tween.EASE_OUT)
		_check_tween.tween_property(self, ^"_check_scale", target, 0.2)
		_check_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)

func _get_container_color() -> Color:
	if disabled:
		if selected:
			return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
		return Color.TRANSPARENT

	if selected:
		return get_m3_color(&"secondary_container")
	return Color.TRANSPARENT

func _get_content_color() -> Color:
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTENT_OPACITY)

	if selected:
		return get_m3_color(&"on_secondary_container")
	return get_m3_color(&"on_surface")

func _get_border_color() -> Color:
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
	return get_m3_color(&"outline")

func _update_min_size() -> void:
	if not segments.is_empty():
		return
	if _font == null:
		_update_font()
	var w: float = 28.0
	if _font != null and not text.is_empty():
		w += _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	if icon_name != &"" or icon_texture != null or (selected and show_selected_icon):
		w += 24.0
	custom_minimum_size = Vector2(maxf(w, 64.0), 40.0)
	update_minimum_size()

func _get_minimum_size() -> Vector2:
	return custom_minimum_size

func _on_pressed_action() -> void:
	segment_pressed.emit(self)

func _draw() -> void:
	if not segments.is_empty():
		return

	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var radius: float = 20.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = _get_container_color()
	sb.border_color = _get_border_color()
	sb.set_border_width_all(1)

	if is_single:
		sb.set_corner_radius_all(int(radius))
	elif is_first:
		sb.corner_radius_top_left = int(radius)
		sb.corner_radius_bottom_left = int(radius)
		sb.corner_radius_top_right = 0
		sb.corner_radius_bottom_right = 0
	elif is_last:
		sb.corner_radius_top_left = 0
		sb.corner_radius_bottom_left = 0
		sb.corner_radius_top_right = int(radius)
		sb.corner_radius_bottom_right = int(radius)
	else:
		sb.set_corner_radius_all(0)

	draw_style_box(sb, r)

	# Content layout
	var content_col := _get_content_color()
	var has_selected_check: bool = (show_selected_icon and _check_scale > 0.01)
	var has_custom_ic: bool = (icon_name != &"" or icon_texture != null)
	var ic_s: float = 18.0

	var text_w: float = 0.0
	if _font != null and not text.is_empty():
		text_w = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x

	var ic_width_total: float = 0.0
	if has_selected_check:
		ic_width_total = (ic_s + 6.0) * _check_scale
	elif has_custom_ic:
		ic_width_total = ic_s + 6.0

	var total_w: float = ic_width_total + text_w
	var cur_x: float = (size.x - total_w) * 0.5

	# Draw checkmark or custom icon
	if has_selected_check:
		var check_rect := Rect2(cur_x, (size.y - ic_s) * 0.5, ic_s * _check_scale, ic_s * _check_scale)
		_draw_check(check_rect.get_center(), ic_s * _check_scale, content_col)
		cur_x += ic_width_total
	elif has_custom_ic:
		var ic_rect := Rect2(cur_x, (size.y - ic_s) * 0.5, ic_s, ic_s)
		if icon_texture != null:
			draw_texture_rect(icon_texture, ic_rect, false, content_col)
		else:
			_draw_custom_icon(icon_name, ic_rect, content_col)
		cur_x += ic_width_total

	# Draw text
	if _font != null and not text.is_empty():
		var font_ascent := _font.get_ascent(_font_size)
		var text_y := (size.y - _font.get_height(_font_size)) * 0.5 + font_ascent
		draw_string(_font, Vector2(cur_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, content_col)

func _draw_check(center: Vector2, s: float, col: Color) -> void:
	var scale_factor := s / 24.0
	var sw: float = maxf(1.0, 2.0 * scale_factor)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_factor
	var pts := PackedVector2Array([t.call(Vector2(5, 12)), t.call(Vector2(10, 17)), t.call(Vector2(19, 7))])
	draw_polyline(pts, col, sw, true)

func _draw_custom_icon(ic_name: StringName, target_rect: Rect2, col: Color) -> void:
	var center := target_rect.get_center()
	var scale_factor := target_rect.size.x / 24.0
	var sw: float = maxf(1.0, 2.0 * scale_factor)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_factor
	var key := String(ic_name).to_lower().replace("-", "_")
	match key:
		"star":
			var pts: PackedVector2Array = []
			for i in range(10):
				var angle := -PI * 0.5 + float(i) * (TAU / 10.0)
				var r_pt := (9.0 if (i % 2 == 0) else 4.2)
				pts.append(t.call(Vector2(12, 12) + Vector2(cos(angle), sin(angle)) * r_pt))
			draw_colored_polygon(pts, col)
		"favorite", "heart":
			draw_circle(center, 4.0 * scale_factor, col)
		_:
			draw_circle(center, 3.0 * scale_factor, col)
