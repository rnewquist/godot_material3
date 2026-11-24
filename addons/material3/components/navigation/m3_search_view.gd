@tool
class_name M3SearchView
extends M3Control

## Material Design 3 Search View component.
## Docked or fullscreen search overlay with header (Back M3IconButton, LineEdit query input,
## Clear M3IconButton), M3Divider, and interactive suggestions list.
## Animates open_progress (0.0..1.0) via Tween on open() / close().

enum ViewMode {
	DOCKED,
	FULLSCREEN
}

signal query_changed(new_query: String)
signal search_submitted(query: String)
signal suggestion_selected(text: String)
signal opened()
signal closed()

@export var view_mode: ViewMode = ViewMode.DOCKED:
	set(value):
		view_mode = value
		_update_dimensions()
		_layout_children()
		queue_redraw()

@export var placeholder_text: String = "Search...":
	set(value):
		placeholder_text = value
		if _line_edit != null and is_instance_valid(_line_edit):
			_line_edit.placeholder_text = placeholder_text

@export var query: String = "":
	set(value):
		if query != value:
			query = value
			if _line_edit != null and is_instance_valid(_line_edit) and _line_edit.text != query:
				_line_edit.text = query
			query_changed.emit(query)
			queue_redraw()

@export var is_open: bool = true:
	set(value):
		is_open = value
		queue_redraw()

var open_progress: float = 1.0:
	set(value):
		open_progress = clampf(value, 0.0, 1.0)
		_apply_open_progress()
		queue_redraw()

var _back_button: M3IconButton = null
var _line_edit: LineEdit = null
var _clear_button: M3IconButton = null
var _divider: M3Divider = null
var _suggestions_box: VBoxContainer = null
var _suggestion_items: Array[Control] = []
var _suggestions_data: Array[Dictionary] = []
var _tween: Tween = null

const HEADER_HEIGHT := 56.0
const SUGGESTION_HEIGHT := 48.0

func _init() -> void:
	super._init()
	ripple_enabled = false
	shape_token = M3Shapes.ShapeToken.EXTRA_LARGE
	custom_minimum_size = Vector2(360.0, 240.0)
	_build_children()
	_update_dimensions()

func _ready() -> void:
	super._ready()
	_build_children()
	_update_dimensions()
	_layout_children()
	_apply_theme_to_input()

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_apply_theme_to_input()
	for item in _suggestion_items:
		if is_instance_valid(item):
			item.queue_redraw()

func _build_children() -> void:
	if _back_button == null or not is_instance_valid(_back_button):
		_back_button = get_node_or_null(^"BackButton") as M3IconButton
		if _back_button == null:
			_back_button = M3IconButton.new()
			_back_button.name = "BackButton"
			_back_button.icon_name = &"arrow_back"
			_back_button.variant = M3IconButton.Variant.STANDARD
			_back_button.pressed.connect(func() -> void: close(true))
			add_child(_back_button)

	if _line_edit == null or not is_instance_valid(_line_edit):
		_line_edit = get_node_or_null(^"SearchInput") as LineEdit
		if _line_edit == null:
			_line_edit = LineEdit.new()
			_line_edit.name = "SearchInput"
			_line_edit.placeholder_text = placeholder_text
			_line_edit.text = query
			_line_edit.flat = true
			_line_edit.context_menu_enabled = false
			_line_edit.text_changed.connect(_on_input_text_changed)
			_line_edit.text_submitted.connect(_on_input_text_submitted)
			add_child(_line_edit)

	if _clear_button == null or not is_instance_valid(_clear_button):
		_clear_button = get_node_or_null(^"ClearButton") as M3IconButton
		if _clear_button == null:
			_clear_button = M3IconButton.new()
			_clear_button.name = "ClearButton"
			_clear_button.icon_name = &"close"
			_clear_button.variant = M3IconButton.Variant.STANDARD
			_clear_button.pressed.connect(clear_query)
			add_child(_clear_button)

	if _divider == null or not is_instance_valid(_divider):
		_divider = get_node_or_null(^"HeaderDivider") as M3Divider
		if _divider == null:
			_divider = M3Divider.new()
			_divider.name = "HeaderDivider"
			add_child(_divider)

	if _suggestions_box == null or not is_instance_valid(_suggestions_box):
		_suggestions_box = get_node_or_null(^"SuggestionsList") as VBoxContainer
		if _suggestions_box == null:
			_suggestions_box = VBoxContainer.new()
			_suggestions_box.name = "SuggestionsList"
			_suggestions_box.add_theme_constant_override("separation", 0)
			add_child(_suggestions_box)

func _apply_theme_to_input() -> void:
	if _line_edit == null or not is_instance_valid(_line_edit):
		return
	var empty_sb := StyleBoxEmpty.new()
	_line_edit.add_theme_stylebox_override("normal", empty_sb)
	_line_edit.add_theme_stylebox_override("focus", empty_sb)
	_line_edit.add_theme_stylebox_override("read_only", empty_sb)
	_line_edit.add_theme_color_override("font_color", get_m3_color(&"on_surface"))
	_line_edit.add_theme_color_override("font_placeholder_color", get_m3_color(&"on_surface_variant"))
	_line_edit.add_theme_color_override("caret_color", get_m3_color(&"primary"))
	_line_edit.add_theme_font_size_override("font_size", 16)

func _on_input_text_changed(new_text: String) -> void:
	query = new_text

func _on_input_text_submitted(submitted_text: String) -> void:
	query = submitted_text
	search_submitted.emit(query)

## Clears the current query text.
func clear_query() -> void:
	if _line_edit != null and is_instance_valid(_line_edit):
		_line_edit.text = ""
	query = ""

## Adds an interactive suggestion row to the suggestions list and returns the row Control.
func add_suggestion(text: String, ic_name: String = "schedule") -> Control:
	_build_children()
	var idx: int = _suggestion_items.size()
	_suggestions_data.append({"text": text, "icon": ic_name})
	var row := M3Control.new()
	row.name = "SuggestionItem_%d" % idx
	row.custom_minimum_size = Vector2(0.0, SUGGESTION_HEIGHT)
	row.size_flags_horizontal = SIZE_EXPAND_FILL
	row.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, row.size)
		if row.current_state == M3Control.ControlState.HOVERED or row.current_state == M3Control.ControlState.PRESSED:
			var hov_sb := StyleBoxFlat.new()
			hov_sb.bg_color = Color(get_m3_color(&"on_surface"), 0.08)
			row.draw_style_box(hov_sb, r)
		var ic_col: Color = get_m3_color(&"on_surface_variant")
		var txt_col: Color = get_m3_color(&"on_surface")
		var cy: float = row.size.y * 0.5
		_draw_suggestion_icon(row, ic_name, Vector2(28.0, cy), ic_col)
		var font: Font = ThemeDB.fallback_font
		if font != null:
			var fy: float = cy + font.get_ascent(14) - font.get_height(14) * 0.5
			row.draw_string(font, Vector2(56.0, fy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, txt_col)
	)
	row.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
				if Rect2(Vector2.ZERO, row.size).has_point(mb.position):
					_select_suggestion(text)
	)
	_suggestions_box.add_child(row)
	_suggestion_items.append(row)
	_update_dimensions()
	_layout_children()
	queue_redraw()
	return row

func _select_suggestion(text: String) -> void:
	query = text
	suggestion_selected.emit(text)
	search_submitted.emit(text)

func clear_suggestions() -> void:
	for item in _suggestion_items:
		if is_instance_valid(item):
			if item.get_parent() == _suggestions_box:
				_suggestions_box.remove_child(item)
			item.queue_free()
	_suggestion_items.clear()
	_suggestions_data.clear()
	_update_dimensions()
	_layout_children()
	queue_redraw()

func get_suggestion_item(index: int) -> Control:
	if index >= 0 and index < _suggestion_items.size():
		return _suggestion_items[index]
	return null

func get_suggestion_count() -> int:
	return _suggestion_items.size()

func get_back_button() -> M3IconButton:
	return _back_button

func get_clear_button() -> M3IconButton:
	return _clear_button

func get_search_input() -> LineEdit:
	return _line_edit

func _get_full_height() -> float:
	if view_mode == ViewMode.FULLSCREEN:
		return maxf(size.y, 360.0)
	var rows_h: float = float(maxi(3, _suggestion_items.size())) * SUGGESTION_HEIGHT
	return HEADER_HEIGHT + 8.0 + rows_h + 12.0

func _update_dimensions() -> void:
	shape_token = M3Shapes.ShapeToken.NONE if view_mode == ViewMode.FULLSCREEN else M3Shapes.ShapeToken.EXTRA_LARGE
	var full_h: float = _get_full_height()
	custom_minimum_size = Vector2(360.0, full_h)
	if size.x < custom_minimum_size.x or size.y < full_h:
		size = Vector2(maxf(size.x, custom_minimum_size.x), full_h)
	update_minimum_size()

func _on_resized() -> void:
	super._on_resized()
	_layout_children()

func _layout_children() -> void:
	var w: float = maxf(size.x, custom_minimum_size.x)
	var full_h: float = maxf(size.y, _get_full_height())
	if _back_button != null and is_instance_valid(_back_button):
		_back_button.size = Vector2(40.0, 40.0)
		_back_button.position = Vector2(8.0, (HEADER_HEIGHT - 40.0) * 0.5)
	if _clear_button != null and is_instance_valid(_clear_button):
		_clear_button.size = Vector2(40.0, 40.0)
		_clear_button.position = Vector2(w - 48.0, (HEADER_HEIGHT - 40.0) * 0.5)
	if _line_edit != null and is_instance_valid(_line_edit):
		_line_edit.position = Vector2(56.0, 8.0)
		_line_edit.size = Vector2(maxf(80.0, w - 112.0), HEADER_HEIGHT - 16.0)
	if _divider != null and is_instance_valid(_divider):
		_divider.position = Vector2(0.0, HEADER_HEIGHT)
		_divider.size = Vector2(w, 1.0)
	if _suggestions_box != null and is_instance_valid(_suggestions_box):
		_suggestions_box.position = Vector2(0.0, HEADER_HEIGHT + 4.0)
		_suggestions_box.size = Vector2(w, maxf(0.0, full_h - HEADER_HEIGHT - 12.0))

func _apply_open_progress() -> void:
	var alpha: float = clampf(open_progress, 0.0, 1.0)
	if _suggestions_box != null and is_instance_valid(_suggestions_box):
		_suggestions_box.modulate.a = alpha
	if _divider != null and is_instance_valid(_divider):
		_divider.modulate.a = alpha

## Opens the search view and animates open_progress (0.0 -> 1.0).
func open(initial_query: String = "", animated: bool = true) -> void:
	visible = true
	is_open = true
	if not initial_query.is_empty():
		query = initial_query
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not animated or not is_inside_tree():
		open_progress = 1.0
		if _line_edit != null and is_instance_valid(_line_edit):
			_line_edit.grab_focus()
		opened.emit()
		return
	open_progress = 0.0
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"open_progress", 1.0, 0.25)
	if _line_edit != null and is_instance_valid(_line_edit):
		_line_edit.grab_focus()
	opened.emit()

## Closes the search view and animates open_progress (1.0 -> 0.0).
func close(animated: bool = true) -> void:
	is_open = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not animated or not is_inside_tree():
		open_progress = 0.0
		closed.emit()
		return
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"open_progress", 0.0, 0.2)
	_tween.tween_callback(func() -> void: closed.emit())

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var min_h: float = HEADER_HEIGHT
	var cur_h: float = lerpf(min_h, size.y, open_progress)
	var draw_r := Rect2(Vector2.ZERO, Vector2(size.x, cur_h))
	var radius: int = 0 if view_mode == ViewMode.FULLSCREEN else 28

	# Elevation shadow
	if view_mode == ViewMode.DOCKED:
		var sh_sb := StyleBoxFlat.new()
		sh_sb.bg_color = Color.TRANSPARENT
		sh_sb.set_corner_radius_all(radius)
		sh_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.2 * maxf(0.2, open_progress))
		sh_sb.shadow_size = 8
		sh_sb.shadow_offset = Vector2(0.0, 3.0)
		draw_style_box(sh_sb, draw_r)

	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = get_m3_color(&"surface_container_high")
	bg_sb.set_corner_radius_all(radius)
	draw_style_box(bg_sb, draw_r)

func _draw_suggestion_icon(canvas: CanvasItem, ic_name: String, center: Vector2, col: Color) -> void:
	var key: String = ic_name.to_lower().replace("-", "_")
	var sw: float = 1.8
	match key:
		"schedule", "clock", "history":
			canvas.draw_arc(center, 7.5, 0.0, TAU, 24, col, sw, true)
			canvas.draw_polyline(PackedVector2Array([
				center + Vector2(0, -4.5), center, center + Vector2(3.5, 2.0)
			]), col, sw, true)
		"search":
			canvas.draw_arc(center + Vector2(-1.5, -1.5), 5.0, 0.0, TAU, 20, col, sw, true)
			canvas.draw_line(center + Vector2(2.2, 2.2), center + Vector2(6.5, 6.5), col, sw, true)
		"star":
			canvas.draw_circle(center, 4.5, col)
		_:
			canvas.draw_circle(center, 4.0, col)
