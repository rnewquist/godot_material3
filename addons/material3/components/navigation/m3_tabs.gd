@tool
class_name M3Tabs
extends M3BaseControl

signal tab_selected(index: int)

enum TabType {
	PRIMARY,
	SECONDARY
}

@export var tab_type: TabType = TabType.PRIMARY:
	set(value):
		tab_type = value
		_update_indicator_instant()
		queue_redraw()

@export var tabs: Array[Dictionary] = [
	{"label": "Overview", "icon": null},
	{"label": "Specifications", "icon": null},
	{"label": "Reviews", "icon": null}
]:
	set(value):
		tabs = value
		_update_indicator_instant()
		queue_redraw()

@export var selected_index: int = 0:
	set(value):
		if selected_index != value and value >= 0 and value < tabs.size():
			var old_idx := selected_index
			selected_index = value
			tab_selected.emit(selected_index)
			_animate_indicator(old_idx, selected_index)
			queue_redraw()

var selected_tab: int:
	get:
		return selected_index
	set(value):
		selected_index = value

@export var scrollable: bool = false:
	set(value):
		scrollable = value
		clip_contents = scrollable
		_recalculate_tab_metrics()
		if not scrollable:
			scroll_offset = 0.0
		else:
			scroll_offset = clampf(scroll_offset, 0.0, max_scroll_offset)
		_update_indicator_instant()
		queue_redraw()

@export var leading_edge_offset: float = 52.0:
	set(value):
		leading_edge_offset = maxf(0.0, value)
		_recalculate_tab_metrics()
		_update_indicator_instant()
		queue_redraw()

@export var min_tab_width: float = 120.0:
	set(value):
		min_tab_width = maxf(48.0, value)
		_recalculate_tab_metrics()
		_update_indicator_instant()
		queue_redraw()

var scroll_offset: float = 0.0:
	set(value):
		scroll_offset = clampf(value, 0.0, maxf(0.0, max_scroll_offset))
		queue_redraw()

var max_scroll_offset: float = 0.0
var total_tabs_width: float = 0.0
var _tab_rects: Array[Rect2] = []
var _press_pos: Vector2 = Vector2.ZERO
var _press_scroll: float = 0.0
var _is_dragging: bool = false

var selection_progress: float = 1.0:
	set(value):
		selection_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _indicator_x: float = 0.0:
	set(value):
		_indicator_x = value
		queue_redraw()

var _indicator_width: float = 0.0:
	set(value):
		_indicator_width = value
		queue_redraw()

var _tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(0, 48)
	size_flags_horizontal = SIZE_EXPAND_FILL

func _ready() -> void:
	super._ready()
	clip_contents = scrollable
	_recalculate_tab_metrics()
	_update_indicator_instant()

func _recalculate_tab_metrics() -> void:
	_tab_rects.clear()
	if tabs.is_empty():
		total_tabs_width = 0.0
		max_scroll_offset = 0.0
		return
	if not scrollable:
		var item_w: float = size.x / maxf(1.0, float(tabs.size()))
		for i in range(tabs.size()):
			_tab_rects.append(Rect2(float(i) * item_w, 0.0, item_w, size.y))
		total_tabs_width = size.x
		max_scroll_offset = 0.0
		return

	var font := get_theme_default_font()
	var cur_x: float = leading_edge_offset
	for i in range(tabs.size()):
		var item: Dictionary = tabs[i]
		var label_str: String = str(item.get("label", ""))
		var txt_w: float = float(label_str.length()) * 8.0
		if font and label_str != "":
			txt_w = font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
		var icon_val: Variant = item.get("icon", null)
		var has_icon: bool = icon_val != null and str(icon_val) != ""
		var icon_w: float = 26.0 if has_icon else 0.0
		var tab_w: float = maxf(min_tab_width, txt_w + icon_w + 32.0)
		_tab_rects.append(Rect2(cur_x, 0.0, tab_w, size.y))
		cur_x += tab_w
	total_tabs_width = cur_x
	max_scroll_offset = maxf(0.0, total_tabs_width - size.x)

func _get_tab_rect(index: int) -> Rect2:
	if _tab_rects.size() != tabs.size():
		_recalculate_tab_metrics()
	if index < 0 or index >= _tab_rects.size():
		return Rect2(0.0, 0.0, min_tab_width, size.y)
	return _tab_rects[index]

func _compute_target_scroll_offset(idx: int) -> float:
	if not scrollable or tabs.is_empty() or idx < 0 or idx >= tabs.size():
		return 0.0
	_recalculate_tab_metrics()
	if idx == 0:
		return 0.0
	var r: Rect2 = _get_tab_rect(idx)
	return clampf(r.position.x - leading_edge_offset, 0.0, max_scroll_offset)

func scroll_to_tab(index: int, animated: bool = true) -> void:
	if tabs.is_empty() or index < 0 or index >= tabs.size():
		return
	_recalculate_tab_metrics()
	if not scrollable:
		scroll_offset = 0.0
		return
	var target_scroll: float = _compute_target_scroll_offset(index)
	if not animated or not is_inside_tree():
		scroll_offset = target_scroll
		queue_redraw()
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.bind_node(self)
	_tween.tween_property(self, ^"scroll_offset", target_scroll, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func get_tab_center(index: int) -> Vector2:
	if tabs.is_empty():
		return size * 0.5
	if not scrollable:
		var item_w: float = size.x / maxf(1.0, float(tabs.size()))
		return Vector2((float(index) + 0.5) * item_w, size.y * 0.5)
	_recalculate_tab_metrics()
	var r: Rect2 = _get_tab_rect(index)
	return Vector2(r.position.x + r.size.x * 0.5 - scroll_offset, size.y * 0.5)

func _compute_target_indicator(idx: int) -> Vector2:
	if tabs.is_empty() or idx < 0 or idx >= tabs.size():
		return Vector2(0.0, 40.0)
	_recalculate_tab_metrics()
	var r: Rect2 = _get_tab_rect(idx)
	var item_x: float = r.position.x
	var item_w: float = r.size.x
	if tab_type == TabType.PRIMARY:
		var font := get_theme_default_font()
		var label_str: String = str(tabs[idx].get("label", ""))
		var txt_w: float = 40.0
		if font and label_str != "":
			txt_w = font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
		var w: float = maxf(24.0, txt_w)
		var x: float = item_x + (item_w - w) * 0.5
		return Vector2(x, w)
	return Vector2(item_x, item_w)

func _update_indicator_instant() -> void:
	_recalculate_tab_metrics()
	if tabs.is_empty():
		return
	var target: Vector2 = _compute_target_indicator(selected_index)
	_indicator_x = target.x
	_indicator_width = target.y
	if scrollable:
		scroll_offset = clampf(scroll_offset, 0.0, max_scroll_offset)
	selection_progress = 1.0

func _animate_indicator(old_idx: int, new_idx: int) -> void:
	if tabs.is_empty():
		return
	_recalculate_tab_metrics()
	var start_ind: Vector2 = _compute_target_indicator(old_idx)
	var target_ind: Vector2 = _compute_target_indicator(new_idx)
	var target_scroll: float = _compute_target_scroll_offset(new_idx)

	if not is_inside_tree():
		_indicator_x = target_ind.x
		_indicator_width = target_ind.y
		if scrollable:
			scroll_offset = target_scroll
		selection_progress = 1.0
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	_indicator_x = start_ind.x
	_indicator_width = start_ind.y
	selection_progress = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.bind_node(self)
	_tween.tween_property(self, ^"_indicator_x", target_ind.x, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"_indicator_width", target_ind.y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"selection_progress", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if scrollable:
		_tween.tween_property(self, ^"scroll_offset", target_scroll, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_RESIZED:
		_recalculate_tab_metrics()
		if _tween == null or not _tween.is_running():
			_update_indicator_instant()

func _hit_test_tab(local_x: float) -> int:
	if tabs.is_empty():
		return -1
	if not scrollable:
		var item_w: float = size.x / float(tabs.size())
		var idx: int = int(local_x / item_w)
		return idx if (idx >= 0 and idx < tabs.size()) else -1
	_recalculate_tab_metrics()
	var content_x: float = local_x + scroll_offset
	for i in range(_tab_rects.size()):
		var r: Rect2 = _tab_rects[i]
		if content_x >= r.position.x and content_x <= r.position.x + r.size.x:
			return i
	return -1

func _gui_input(event: InputEvent) -> void:
	super._gui_input(event)
	if disabled or tabs.is_empty():
		return
	if not scrollable:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked_idx: int = _hit_test_tab(event.position.x)
			if clicked_idx >= 0:
				selected_index = clicked_idx
		return

	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT] and event.pressed:
			_recalculate_tab_metrics()
			if _tween and _tween.is_valid():
				_tween.kill()
			scroll_offset = clampf(scroll_offset + 48.0 * maxf(1.0, event.factor), 0.0, max_scroll_offset)
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT] and event.pressed:
			_recalculate_tab_metrics()
			if _tween and _tween.is_valid():
				_tween.kill()
			scroll_offset = clampf(scroll_offset - 48.0 * maxf(1.0, event.factor), 0.0, max_scroll_offset)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_pos = event.position
				_press_scroll = scroll_offset
				_is_dragging = false
			else:
				if not _is_dragging:
					var clicked_idx: int = _hit_test_tab(event.position.x)
					if clicked_idx >= 0:
						selected_index = clicked_idx
				_is_dragging = false
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var dx: float = event.position.x - _press_pos.x
		if absf(dx) > 4.0:
			_is_dragging = true
		if _is_dragging:
			_recalculate_tab_metrics()
			if _tween and _tween.is_valid():
				_tween.kill()
			scroll_offset = clampf(_press_scroll - dx, 0.0, max_scroll_offset)

func _draw() -> void:
	var s := get_scheme()
	var rect := Rect2(Vector2.ZERO, size)
	_recalculate_tab_metrics()

	if _tween == null or not _tween.is_running():
		if not tabs.is_empty():
			var t_sync: Vector2 = _compute_target_indicator(selected_index)
			if absf(_indicator_x - t_sync.x) > 0.01:
				_indicator_x = t_sync.x
			if absf(_indicator_width - t_sync.y) > 0.01:
				_indicator_width = t_sync.y

	var bg_color := s.surface if tab_type == TabType.PRIMARY else s.surface_container_low
	draw_rect(rect, bg_color)

	draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), s.outline_variant, 1.0)

	if tabs.is_empty():
		return

	var count: int = tabs.size()
	var font := get_theme_default_font()
	var center_y: float = size.y * 0.5
	var draw_scroll: float = scroll_offset if scrollable else 0.0

	for i in range(count):
		var item: Dictionary = tabs[i]
		var r: Rect2 = _get_tab_rect(i)
		var item_center_x: float = r.position.x + (r.size.x * 0.5) - draw_scroll
		var is_sel: bool = (i == selected_index)
		var text_col := s.primary if is_sel else s.on_surface_variant

		var label_str: String = str(item.get("label", ""))
		if label_str != "" and font:
			var font_sz := 14
			var lbl_sz := font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
			var lbl_pos := Vector2(item_center_x - (lbl_sz.x * 0.5), center_y + lbl_sz.y * 0.35)
			draw_string(font, lbl_pos, label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, text_col)

	# Draw Active Indicator
	var ind_draw_x: float = _indicator_x - draw_scroll
	if tab_type == TabType.PRIMARY:
		var ind_h: float = 3.0
		var ind_rect := Rect2(Vector2(ind_draw_x, size.y - ind_h), Vector2(_indicator_width, ind_h))
		var sb := create_stylebox(s.primary, 3.0)
		sb.corner_radius_top_left = 3
		sb.corner_radius_top_right = 3
		sb.corner_radius_bottom_left = 0
		sb.corner_radius_bottom_right = 0
		draw_style_box(sb, ind_rect)
	else:
		var ind_h: float = 2.0
		var ind_rect := Rect2(Vector2(ind_draw_x, size.y - ind_h), Vector2(_indicator_width, ind_h))
		draw_rect(ind_rect, s.primary)
