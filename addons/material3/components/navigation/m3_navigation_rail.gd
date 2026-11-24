@tool
class_name M3NavigationRail
extends M3BaseControl

enum RailAlignment {
	TOP,
	CENTER,
	BOTTOM
}

signal destination_selected(index: int)
signal fab_clicked
signal menu_pressed

@export var destinations: Array[Dictionary] = [
	{"label": "Explore", "icon": null, "badge": 0},
	{"label": "Favorites", "icon": null, "badge": 3},
	{"label": "Saved", "icon": null, "badge": 0},
	{"label": "Profile", "icon": null, "badge": 0}
]:
	set(value):
		destinations = value
		_update_indicator_instant()
		queue_redraw()

@export var selected_index: int = 0:
	set(value):
		if selected_index != value and value >= 0 and value < destinations.size():
			var old_idx := selected_index
			selected_index = value
			destination_selected.emit(selected_index)
			_animate_indicator(old_idx, selected_index)
			queue_redraw()

@export var has_fab: bool = true:
	set(value):
		has_fab = value
		_update_indicator_instant()
		queue_redraw()

@export var fab_icon: Texture2D = null:
	set(value):
		fab_icon = value
		queue_redraw()

@export var show_menu_button: bool = false:
	set(value):
		show_menu_button = value
		_update_indicator_instant()
		queue_redraw()

@export var alignment: RailAlignment = RailAlignment.TOP:
	set(value):
		alignment = value
		_update_indicator_instant()
		queue_redraw()

@export var expanded: bool = false:
	set(value):
		if expanded != value:
			expanded = value
			_animate_expanded(expanded, is_inside_tree())

var selection_progress: float = 1.0:
	set(value):
		selection_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var expand_progress: float = 0.0:
	set(value):
		expand_progress = clampf(value, 0.0, 1.0)
		var target_w: float = lerpf(80.0, 220.0, expand_progress)
		custom_minimum_size.x = target_w
		if size.x > 0.0:
			size.x = target_w
		queue_redraw()

var _indicator_y: float = 0.0:
	set(value):
		_indicator_y = value
		queue_redraw()

var _indicator_h: float = 32.0
var _indicator_w: float = 56.0
var _item_height: float = 64.0
var _fab_rect: Rect2
var _menu_rect: Rect2
var _fab_hovered: bool = false
var _tween: Tween
var _expand_tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(80, 0)
	size_flags_vertical = SIZE_EXPAND_FILL

func _ready() -> void:
	super._ready()
	_update_indicator_instant()

func set_expanded(val: bool, animated: bool = true) -> void:
	expanded = val
	_animate_expanded(val, animated)

func _animate_expanded(val: bool, animated: bool = true) -> void:
	var target: float = 1.0 if val else 0.0
	if _expand_tween and _expand_tween.is_valid():
		_expand_tween.kill()
	if not animated or not is_inside_tree():
		expand_progress = target
		return
	_expand_tween = create_tween()
	_expand_tween.bind_node(self)
	_expand_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_expand_tween.tween_property(self, ^"expand_progress", target, 0.25)

func _get_header_bottom_y() -> float:
	var y: float = 16.0
	if show_menu_button:
		y += 48.0
	if has_fab:
		y += 72.0
	return maxf(40.0, y)

func _get_items_start_y() -> float:
	var header_end: float = _get_header_bottom_y()
	var total_items_h: float = float(destinations.size()) * _item_height
	match alignment:
		RailAlignment.CENTER:
			var avail_h: float = maxf(total_items_h, size.y - header_end - 16.0)
			return header_end + (avail_h - total_items_h) * 0.5
		RailAlignment.BOTTOM:
			return maxf(header_end, size.y - total_items_h - 16.0)
		_:
			return (96.0 if has_fab else 40.0) + (48.0 if show_menu_button else 0.0)

func get_destination_center(index: int) -> Vector2:
	var start_y := _get_items_start_y()
	return Vector2(size.x * 0.5, start_y + (float(index) + 0.5) * _item_height)

func get_fab_center() -> Vector2:
	var menu_off: float = 48.0 if show_menu_button else 0.0
	return Vector2(size.x * 0.5, 20.0 + menu_off + 28.0)

func _update_indicator_instant() -> void:
	var start_y := _get_items_start_y()
	_indicator_y = start_y + (selected_index * _item_height) + 4.0
	selection_progress = 1.0

func _animate_indicator(old_idx: int, new_idx: int) -> void:
	var start_y := _get_items_start_y()
	var from_y := start_y + (old_idx * _item_height) + 4.0
	var target_y := start_y + (new_idx * _item_height) + 4.0

	if not is_inside_tree():
		_indicator_y = target_y
		selection_progress = 1.0
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	_indicator_y = from_y
	selection_progress = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.bind_node(self)
	_tween.tween_property(self, ^"_indicator_y", target_y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"selection_progress", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_RESIZED:
		if _tween == null or not _tween.is_running():
			_update_indicator_instant()

func _gui_input(event: InputEvent) -> void:
	super._gui_input(event)
	if disabled:
		return

	if event is InputEventMouseMotion:
		if has_fab:
			var was_fab := _fab_hovered
			_fab_hovered = _fab_rect.has_point(event.position)
			if was_fab != _fab_hovered:
				queue_redraw()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if show_menu_button and _menu_rect.has_point(event.position):
			menu_pressed.emit()
			return
		if has_fab and _fab_rect.has_point(event.position):
			fab_clicked.emit()
			return

		var start_y := _get_items_start_y()
		if event.position.y >= start_y:
			var rel_y: float = event.position.y - start_y
			var clicked_idx: int = int(rel_y / _item_height)
			if clicked_idx >= 0 and clicked_idx < destinations.size():
				selected_index = clicked_idx

func _draw() -> void:
	var s := get_scheme()
	var rect := Rect2(Vector2.ZERO, size)

	if _tween == null or not _tween.is_running():
		_indicator_y = _get_items_start_y() + (selected_index * _item_height) + 4.0

	# Background
	var sb := create_stylebox(s.surface, 0)
	draw_style_box(sb, rect)

	# Right divider line
	draw_line(Vector2(size.x - 1, 0), Vector2(size.x - 1, size.y), s.outline_variant, 1.0)

	var menu_off: float = 0.0
	if show_menu_button:
		_menu_rect = Rect2(Vector2((80.0 - 40.0) * 0.5, 16.0), Vector2(40.0, 40.0))
		var mc := _menu_rect.get_center()
		draw_line(mc + Vector2(-9, -5), mc + Vector2(9, -5), s.on_surface_variant, 2.0, true)
		draw_line(mc + Vector2(-9, 0), mc + Vector2(9, 0), s.on_surface_variant, 2.0, true)
		draw_line(mc + Vector2(-9, 5), mc + Vector2(9, 5), s.on_surface_variant, 2.0, true)
		menu_off = 48.0

	# Top FAB if enabled
	if has_fab:
		var fab_sz := Vector2(56, 56)
		var fab_x: float = 12.0 if expand_progress > 0.1 else (size.x - fab_sz.x) * 0.5
		_fab_rect = Rect2(Vector2(fab_x, 20.0 + menu_off), fab_sz)
		draw_m3_shadow(self, _fab_rect, 16.0, 3 if _fab_hovered else 2)
		var fab_sb := create_stylebox(s.primary_container, 16.0)
		draw_style_box(fab_sb, _fab_rect)

		# FAB Icon
		var fab_center := _fab_rect.position + (_fab_rect.size * 0.5)
		if fab_icon:
			draw_texture_rect(fab_icon, Rect2(fab_center - Vector2(12, 12), Vector2(24, 24)), false, s.on_primary_container)
		else:
			var arm: float = 7.0
			draw_line(Vector2(fab_center.x - arm, fab_center.y), Vector2(fab_center.x + arm, fab_center.y), s.on_primary_container, 2.5, true)
			draw_line(Vector2(fab_center.x, fab_center.y - arm), Vector2(fab_center.x, fab_center.y + arm), s.on_primary_container, 2.5, true)

	if destinations.is_empty():
		return

	var start_y := _get_items_start_y()

	# Active indicator pill (56x32dp compact, or wide pill when expanded)
	var cur_pill_w: float = lerpf(_indicator_w, maxf(_indicator_w, size.x - 24.0), expand_progress)
	var pill_x: float = lerpf((size.x - _indicator_w) * 0.5, 12.0, expand_progress)
	var pill_rect := Rect2(Vector2(pill_x, _indicator_y), Vector2(cur_pill_w, _indicator_h))
	var pill_sb := create_stylebox(s.secondary_container, 16.0)
	draw_style_box(pill_sb, pill_rect)

	var font := get_theme_default_font()

	for i in range(destinations.size()):
		var item: Dictionary = destinations[i]
		var item_y := start_y + (i * _item_height)
		var center_x := lerpf(size.x * 0.5, 40.0, expand_progress)
		var is_sel: bool = (i == selected_index)

		var icon_col := s.on_secondary_container if is_sel else s.on_surface_variant
		var text_col := s.on_surface if is_sel else s.on_surface_variant

		var icon_center_y := item_y + 20.0
		var ic_val = item.get("icon")
		if ic_val is Texture2D:
			var tex: Texture2D = ic_val
			draw_texture_rect(tex, Rect2(Vector2(center_x - 12.0, icon_center_y - 12.0), Vector2(24, 24)), false, icon_col)
		else:
			draw_circle(Vector2(center_x, icon_center_y), 6.0, icon_col)

		# Badge
		var badge_count: int = int(item.get("badge", 0))
		if badge_count > 0:
			var badge_pos := Vector2(center_x + 12.0, icon_center_y - 10.0)
			var badge_txt := str(badge_count) if badge_count <= 999 else "999+"
			var b_font_sz := 10
			if font:
				var b_sz := font.get_string_size(badge_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, b_font_sz)
				var b_rect := Rect2(Vector2(badge_pos.x - 4, badge_pos.y - 8), Vector2(maxf(16.0, b_sz.x + 8.0), 16.0))
				var b_sb := create_stylebox(s.error, 8.0)
				draw_style_box(b_sb, b_rect)
				draw_string(font, Vector2(b_rect.position.x + (b_rect.size.x - b_sz.x) * 0.5, b_rect.position.y + 12), badge_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, b_font_sz, s.on_error)

		# Label
		var label_str: String = str(item.get("label", item.get("title", "")))
		if label_str != "" and font:
			var font_sz := 12
			var lbl_sz := font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
			if expand_progress > 0.5:
				draw_string(font, Vector2(68.0, icon_center_y + 5.0), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_col)
			else:
				var lbl_pos := Vector2(center_x - (lbl_sz.x * 0.5), item_y + 48.0)
				draw_string(font, lbl_pos, label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, text_col)
