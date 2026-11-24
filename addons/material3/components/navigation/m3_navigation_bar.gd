@tool
class_name M3NavigationBar
extends M3BaseControl

signal destination_selected(index: int)

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

var selection_progress: float = 1.0:
	set(value):
		selection_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _indicator_x: float = 0.0:
	set(value):
		_indicator_x = value
		queue_redraw()

var _indicator_width: float = 64.0
var _tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(0, 80)
	size_flags_horizontal = SIZE_EXPAND_FILL

func _ready() -> void:
	super._ready()
	_update_indicator_instant()

func add_destination(label: String, icon: Variant = null, badge: int = 0) -> int:
	var idx: int = destinations.size()
	destinations.append({"label": label, "icon": icon, "badge": badge})
	_update_indicator_instant()
	queue_redraw()
	return idx

func set_badge(index: int, badge: int) -> void:
	if index >= 0 and index < destinations.size():
		destinations[index]["badge"] = badge
		queue_redraw()

func get_destination_center(index: int) -> Vector2:
	if destinations.is_empty():
		return size * 0.5
	var item_w: float = size.x / maxf(1.0, float(destinations.size()))
	return Vector2((float(index) + 0.5) * item_w, size.y * 0.5)

func _update_indicator_instant() -> void:
	if destinations.is_empty():
		return
	var item_w: float = size.x / maxf(1.0, float(destinations.size()))
	_indicator_x = (selected_index * item_w) + (item_w - _indicator_width) * 0.5
	selection_progress = 1.0

func _animate_indicator(old_idx: int, new_idx: int) -> void:
	if destinations.is_empty():
		return
	var item_w: float = size.x / maxf(1.0, float(destinations.size()))
	var start_x: float = (old_idx * item_w) + (item_w - _indicator_width) * 0.5
	var target_x: float = (new_idx * item_w) + (item_w - _indicator_width) * 0.5

	if not is_inside_tree():
		_indicator_x = target_x
		selection_progress = 1.0
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	_indicator_x = start_x
	selection_progress = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.bind_node(self)
	_tween.tween_property(self, ^"_indicator_x", target_x, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"selection_progress", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_RESIZED:
		if _tween == null or not _tween.is_running():
			_update_indicator_instant()

func _gui_input(event: InputEvent) -> void:
	super._gui_input(event)
	if disabled or destinations.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var item_w: float = size.x / float(destinations.size())
		var clicked_idx: int = int(event.position.x / item_w)
		if clicked_idx >= 0 and clicked_idx < destinations.size():
			selected_index = clicked_idx

func _draw() -> void:
	var s := get_scheme()
	var rect := Rect2(Vector2.ZERO, size)

	if _tween == null or not _tween.is_running():
		if not destinations.is_empty():
			var item_w_sync: float = size.x / maxf(1.0, float(destinations.size()))
			_indicator_x = (selected_index * item_w_sync) + (item_w_sync - _indicator_width) * 0.5

	# Background
	var sb := create_stylebox(s.surface_container, 0)
	draw_style_box(sb, rect)

	if destinations.is_empty():
		return

	var count: int = destinations.size()
	var item_w: float = size.x / float(count)

	# Active indicator pill (64x32dp, corner radius 16)
	var pill_h: float = 32.0
	var pill_y: float = 12.0
	var cur_w: float = _indicator_width * lerpf(0.6, 1.0, selection_progress)
	var pill_rect := Rect2(Vector2(_indicator_x + (_indicator_width - cur_w) * 0.5, pill_y), Vector2(cur_w, pill_h))
	var pill_sb := create_stylebox(s.secondary_container, 16.0)
	draw_style_box(pill_sb, pill_rect)

	var font := get_theme_default_font()

	for i in range(count):
		var item: Dictionary = destinations[i]
		var item_center_x: float = (i * item_w) + (item_w * 0.5)
		var is_sel: bool = (i == selected_index)
		var icon_col := s.on_secondary_container if is_sel else s.on_surface_variant
		var text_col := s.on_surface if is_sel else s.on_surface_variant

		# Icon
		var icon_y: float = pill_y + (pill_h * 0.5)
		var ic_val = item.get("icon")
		if ic_val is Texture2D:
			var tex: Texture2D = ic_val
			var tex_sz := Vector2(24, 24)
			draw_texture_rect(tex, Rect2(Vector2(item_center_x - 12.0, icon_y - 12.0), tex_sz), false, icon_col)
		else:
			draw_circle(Vector2(item_center_x, icon_y), 6.0, icon_col)

		# Badge
		var badge_count: int = int(item.get("badge", 0))
		if badge_count < 0:
			draw_circle(Vector2(item_center_x + 8.0, icon_y - 8.0), 3.0, s.error)
		elif badge_count > 0:
			var badge_pos := Vector2(item_center_x + 10.0, icon_y - 10.0)
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
			var lbl_pos := Vector2(item_center_x - (lbl_sz.x * 0.5), pill_y + pill_h + 18.0)
			draw_string(font, lbl_pos, label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, text_col)
