@tool
class_name M3SearchBar
extends M3Control

## Material Design 3 Search Bar component.
## 56dp height pill (surface_container_high), leading "search" or "menu" icon,
## placeholder/query text, optional trailing icon ("mic" / "close") and avatar/badge.
## Clicking or focusing M3SearchBar emits search_activated and opens linked M3SearchView.

signal search_activated()
signal leading_icon_pressed()
signal trailing_icon_pressed()
signal avatar_pressed()
signal query_changed(new_query: String)

@export var placeholder_text: String = "Search...":
	set(value):
		placeholder_text = value
		queue_redraw()

@export var query: String = "":
	set(value):
		if query != value:
			query = value
			query_changed.emit(query)
			queue_redraw()

@export var text: String:
	get:
		return query
	set(value):
		query = value

@export var leading_icon: String = "search":
	set(value):
		leading_icon = value
		queue_redraw()

@export var trailing_icon: String = "mic":
	set(value):
		trailing_icon = value
		queue_redraw()

@export var show_avatar: bool = true:
	set(value):
		show_avatar = value
		queue_redraw()

@export var avatar_initials: String = "M":
	set(value):
		avatar_initials = value
		queue_redraw()

@export var badge_count: int = 0:
	set(value):
		badge_count = value
		queue_redraw()

var search_view: M3SearchView = null:
	set(value):
		if search_view != null and is_instance_valid(search_view):
			if search_view.suggestion_selected.is_connected(_on_search_view_suggestion):
				search_view.suggestion_selected.disconnect(_on_search_view_suggestion)
			if search_view.search_submitted.is_connected(_on_search_view_submitted):
				search_view.search_submitted.disconnect(_on_search_view_submitted)
		search_view = value
		if search_view != null and is_instance_valid(search_view):
			if not search_view.suggestion_selected.is_connected(_on_search_view_suggestion):
				search_view.suggestion_selected.connect(_on_search_view_suggestion)
			if not search_view.search_submitted.is_connected(_on_search_view_submitted):
				search_view.search_submitted.connect(_on_search_view_submitted)

var activated_count: int = 0
var _last_press_pos: Vector2 = Vector2.ZERO

func _init() -> void:
	super._init()
	shape_token = M3Shapes.ShapeToken.FULL
	custom_minimum_size = Vector2(320.0, 56.0)
	size_flags_horizontal = SIZE_EXPAND_FILL

func _on_search_view_suggestion(selected_text: String) -> void:
	query = selected_text

func _on_search_view_submitted(submitted_text: String) -> void:
	query = submitted_text

func get_leading_icon_rect() -> Rect2:
	return Rect2(Vector2(8.0, (size.y - 40.0) * 0.5), Vector2(40.0, 40.0))

func get_avatar_rect() -> Rect2:
	if not show_avatar:
		return Rect2()
	return Rect2(Vector2(size.x - 44.0, (size.y - 30.0) * 0.5), Vector2(30.0, 30.0))

func get_trailing_icon_rect() -> Rect2:
	if trailing_icon.is_empty():
		return Rect2()
	var right_x: float = (size.x - 52.0) if show_avatar else (size.x - 8.0)
	return Rect2(Vector2(right_x - 40.0, (size.y - 40.0) * 0.5), Vector2(40.0, 40.0))

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_last_press_pos = mb.position
	super._gui_input(event)

func _on_pressed_action() -> void:
	var av_r: Rect2 = get_avatar_rect()
	if av_r.size.x > 0.0 and av_r.has_point(_last_press_pos):
		avatar_pressed.emit()
		return
	var tr_r: Rect2 = get_trailing_icon_rect()
	if tr_r.size.x > 0.0 and tr_r.has_point(_last_press_pos):
		if trailing_icon == "close" or trailing_icon == "clear":
			query = ""
		trailing_icon_pressed.emit()
		return
	activated_count += 1
	search_activated.emit()
	if search_view != null and is_instance_valid(search_view):
		search_view.open(query, true)

func get_container_color() -> Color:
	return get_m3_color(&"surface_container_high")

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return

	var radius: int = int(minf(size.x, size.y) * 0.5)
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = get_container_color()
	bg_sb.set_corner_radius_all(radius)
	draw_style_box(bg_sb, r)

	var cy: float = size.y * 0.5
	var icon_col: Color = get_m3_color(&"on_surface")
	var sub_icon_col: Color = get_m3_color(&"on_surface_variant")

	# Leading icon
	if not leading_icon.is_empty():
		_draw_bar_icon(leading_icon, Vector2(28.0, cy), icon_col)

	# Query or Placeholder text
	var font: Font = ThemeDB.fallback_font
	if font != null:
		var display_str: String = query if not query.is_empty() else placeholder_text
		var text_col: Color = get_m3_color(&"on_surface") if not query.is_empty() else get_m3_color(&"on_surface_variant")
		var f_sz: int = 16
		var ty: float = cy + font.get_ascent(f_sz) - font.get_height(f_sz) * 0.5
		draw_string(font, Vector2(56.0, ty), display_str, HORIZONTAL_ALIGNMENT_LEFT, maxf(40.0, size.x - 140.0), f_sz, text_col)

	# Trailing icon
	var tr_r: Rect2 = get_trailing_icon_rect()
	if tr_r.size.x > 0.0:
		_draw_bar_icon(trailing_icon, tr_r.get_center(), sub_icon_col)

	# Avatar & optional badge
	var av_r: Rect2 = get_avatar_rect()
	if av_r.size.x > 0.0:
		var av_center: Vector2 = av_r.get_center()
		draw_circle(av_center, 15.0, get_m3_color(&"primary_container"))
		if font != null and not avatar_initials.is_empty():
			var init_str: String = avatar_initials.substr(0, 2).to_upper()
			var init_sz: Vector2 = font.get_string_size(init_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
			var iy: float = av_center.y + font.get_ascent(12) - font.get_height(12) * 0.5
			draw_string(font, Vector2(av_center.x - init_sz.x * 0.5, iy), init_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, get_m3_color(&"on_primary_container"))
		if badge_count > 0:
			var b_pos: Vector2 = av_center + Vector2(10.0, -10.0)
			draw_circle(b_pos, 5.0, get_m3_color(&"error"))

func _draw_bar_icon(ic_name: String, center: Vector2, col: Color) -> void:
	var key: String = ic_name.to_lower().replace("-", "_")
	var sw: float = 2.0
	match key:
		"search":
			draw_arc(center + Vector2(-1.5, -1.5), 5.5, 0.0, TAU, 24, col, sw, true)
			draw_line(center + Vector2(2.5, 2.5), center + Vector2(7.5, 7.5), col, sw, true)
		"menu", "hamburger":
			draw_line(center + Vector2(-8, -5), center + Vector2(8, -5), col, sw, true)
			draw_line(center + Vector2(-8, 0), center + Vector2(8, 0), col, sw, true)
			draw_line(center + Vector2(-8, 5), center + Vector2(8, 5), col, sw, true)
		"mic", "microphone":
			draw_line(center + Vector2(0, -6), center + Vector2(0, 1), col, sw * 2.0, true)
			draw_arc(center + Vector2(0, 0), 4.5, 0.0, PI, 16, col, sw, true)
			draw_line(center + Vector2(0, 4.5), center + Vector2(0, 8), col, sw, true)
		"close", "clear":
			draw_line(center + Vector2(-6, -6), center + Vector2(6, 6), col, sw, true)
			draw_line(center + Vector2(6, -6), center + Vector2(-6, 6), col, sw, true)
		_:
			draw_circle(center, 4.5, col)
