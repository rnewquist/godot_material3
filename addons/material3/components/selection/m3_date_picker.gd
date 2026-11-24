@tool
class_name M3DatePicker
extends M3Control

## Material 3 Date Picker component supporting Docked, Modal, and Modal Input modes,
## single-date and date-range selection, month navigation, and animated transitions.

enum PickerMode {
	DOCKED,
	MODAL,
	INPUT
}

signal date_selected(year: int, month: int, day: int)
signal date_confirmed(year: int, month: int, day: int)
signal year_selected(year: int)
signal cancelled()
signal mode_changed(new_mode: PickerMode)

const MONTH_NAMES: Array[String] = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]
const MONTH_SHORT: Array[String] = [
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
]
const WEEKDAY_SHORT: Array[String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
const WEEKDAY_LETTERS: Array[String] = ["S", "M", "T", "W", "T", "F", "S"]

@export var picker_mode: PickerMode = PickerMode.MODAL:
	set(value):
		if picker_mode != value:
			picker_mode = value
			_sync_child_visibility()
			mode_changed.emit(picker_mode)
			queue_redraw()

@export var mode: PickerMode:
	get:
		return picker_mode
	set(value):
		picker_mode = value

@export var selected_year: int = 2025:
	set(value):
		selected_year = clampi(value, 1900, 2100)
		selected_day = clampi(selected_day, 1, _days_in_month(selected_year, selected_month))
		_sync_input_field_text()
		_refresh_year_grid_selection()
		if _month_year_btn != null:
			_month_year_btn.queue_redraw()
		queue_redraw()

@export var selected_month: int = 5:
	set(value):
		selected_month = clampi(value, 1, 12)
		selected_day = clampi(selected_day, 1, _days_in_month(selected_year, selected_month))
		_sync_input_field_text()
		if _month_year_btn != null:
			_month_year_btn.queue_redraw()
		queue_redraw()

@export var selected_day: int = 15:
	set(value):
		var max_d: int = _days_in_month(selected_year, selected_month)
		selected_day = clampi(value, 1, max_d)
		_sync_input_field_text()
		queue_redraw()

@export var today_day: int = 12:
	set(value):
		today_day = clampi(value, 1, 31)
		queue_redraw()

@export var range_selection: bool = false:
	set(value):
		range_selection = value
		queue_redraw()

@export var range_start_day: int = 10:
	set(value):
		range_start_day = clampi(value, 1, _days_in_month(selected_year, selected_month))
		queue_redraw()

@export var range_end_day: int = 18:
	set(value):
		range_end_day = clampi(value, 1, _days_in_month(selected_year, selected_month))
		queue_redraw()

@export var is_open: bool = true:
	set(value):
		if is_open != value:
			is_open = value
			if is_inside_tree():
				_animate_open(is_open)
			else:
				open_progress = 1.0 if is_open else 0.0
				visible = is_open
			queue_redraw()

var selection_anim_progress: float = 1.0:
	set(value):
		selection_anim_progress = value
		queue_redraw()

var open_progress: float = 1.0:
	set(value):
		open_progress = value
		queue_redraw()

var month_transition_progress: float = 1.0:
	set(value):
		month_transition_progress = value
		queue_redraw()

var year_picker_open: bool = false

var year_picker_progress: float = 0.0:
	set(value):
		year_picker_progress = value
		if _year_grid_container != null:
			_year_grid_container.modulate.a = clampf(value, 0.0, 1.0) if year_picker_open else 1.0
		queue_redraw()

var _selection_tween: Tween = null
var _open_tween: Tween = null
var _month_tween: Tween = null
var _year_tween: Tween = null
var _font: Font = null
var _hovered_day: int = -1
var _updating_input_field: bool = false
var _year_grid_base_year: int = 2025

var _mode_switch_btn: M3IconButton = null
var _month_year_btn: M3Button = null
var _prev_month_btn: M3IconButton = null
var _next_month_btn: M3IconButton = null
var _year_grid_container: GridContainer = null
var _year_buttons: Dictionary = {}
var _date_input_field: M3TextField = null
var _cancel_btn: M3Button = null
var _confirm_btn: M3Button = null

func _init() -> void:
	super._init()
	ripple_enabled = false
	shape_token = M3Shapes.ShapeToken.EXTRA_LARGE
	custom_minimum_size = Vector2(328.0, 420.0)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_font = ThemeDB.fallback_font
	open_progress = 1.0 if is_open else 0.0
	visible = is_open
	_setup_children()
	_layout_children()
	_sync_child_visibility()
	_sync_input_field_text()

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_font = ThemeDB.fallback_font
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_children()

func _setup_children() -> void:
	if _mode_switch_btn == null:
		_mode_switch_btn = get_node_or_null(^"ModeSwitchButton") as M3IconButton
		if _mode_switch_btn == null:
			_mode_switch_btn = M3IconButton.new()
			_mode_switch_btn.name = "ModeSwitchButton"
			add_child(_mode_switch_btn)
		_mode_switch_btn.variant = M3IconButton.Variant.STANDARD
		if not _mode_switch_btn.pressed.is_connected(_on_mode_switch_pressed):
			_mode_switch_btn.pressed.connect(_on_mode_switch_pressed)
		if not _mode_switch_btn.draw.is_connected(_on_mode_btn_draw):
			_mode_switch_btn.draw.connect(_on_mode_btn_draw)

	if _month_year_btn == null:
		_month_year_btn = get_node_or_null(^"MonthYearButton") as M3Button
		if _month_year_btn == null:
			_month_year_btn = M3Button.new()
			_month_year_btn.name = "MonthYearButton"
			add_child(_month_year_btn)
		_month_year_btn.variant = M3Button.Variant.TEXT
		_month_year_btn.text = ""
		_month_year_btn.custom_minimum_size = Vector2(156.0, 36.0)
		if not _month_year_btn.pressed.is_connected(_on_month_year_pressed):
			_month_year_btn.pressed.connect(_on_month_year_pressed)

	if _year_grid_container == null:
		_year_grid_container = get_node_or_null(^"YearGridContainer") as GridContainer
		if _year_grid_container == null:
			_year_grid_container = GridContainer.new()
			_year_grid_container.name = "YearGridContainer"
			_year_grid_container.columns = 3
			_year_grid_container.add_theme_constant_override("h_separation", 12)
			_year_grid_container.add_theme_constant_override("v_separation", 8)
			add_child(_year_grid_container)
		_populate_year_grid(selected_year)
		_year_grid_container.visible = year_picker_open and (picker_mode != PickerMode.INPUT)

	if _prev_month_btn == null:
		_prev_month_btn = get_node_or_null(^"PrevMonthButton") as M3IconButton
		if _prev_month_btn == null:
			_prev_month_btn = M3IconButton.new()
			_prev_month_btn.name = "PrevMonthButton"
			add_child(_prev_month_btn)
		_prev_month_btn.variant = M3IconButton.Variant.STANDARD
		if not _prev_month_btn.pressed.is_connected(_on_prev_month_pressed):
			_prev_month_btn.pressed.connect(_on_prev_month_pressed)
		if not _prev_month_btn.draw.is_connected(_on_prev_btn_draw):
			_prev_month_btn.draw.connect(_on_prev_btn_draw)

	if _next_month_btn == null:
		_next_month_btn = get_node_or_null(^"NextMonthButton") as M3IconButton
		if _next_month_btn == null:
			_next_month_btn = M3IconButton.new()
			_next_month_btn.name = "NextMonthButton"
			add_child(_next_month_btn)
		_next_month_btn.variant = M3IconButton.Variant.STANDARD
		if not _next_month_btn.pressed.is_connected(_on_next_month_pressed):
			_next_month_btn.pressed.connect(_on_next_month_pressed)
		if not _next_month_btn.draw.is_connected(_on_next_btn_draw):
			_next_month_btn.draw.connect(_on_next_btn_draw)

	if _date_input_field == null:
		_date_input_field = get_node_or_null(^"DateInputField") as M3TextField
		if _date_input_field == null:
			_date_input_field = M3TextField.new()
			_date_input_field.name = "DateInputField"
			_date_input_field.variant = M3TextField.Variant.OUTLINED
			_date_input_field.label = "Date"
			_date_input_field.placeholder = "MM/DD/YYYY"
			_date_input_field.helper_text = "MM/DD/YYYY"
			_date_input_field.text = "%02d/%02d/%04d" % [selected_month, selected_day, selected_year]
			add_child(_date_input_field)
		if not _date_input_field.text_changed.is_connected(_on_date_input_text_changed):
			_date_input_field.text_changed.connect(_on_date_input_text_changed)

	if _cancel_btn == null:
		_cancel_btn = get_node_or_null(^"CancelButton") as M3Button
		if _cancel_btn == null:
			_cancel_btn = M3Button.new()
			_cancel_btn.name = "CancelButton"
			add_child(_cancel_btn)
		_cancel_btn.variant = M3Button.Variant.TEXT
		_cancel_btn.text = "Cancel"
		if not _cancel_btn.pressed.is_connected(_on_cancel_pressed):
			_cancel_btn.pressed.connect(_on_cancel_pressed)

	if _confirm_btn == null:
		_confirm_btn = get_node_or_null(^"ConfirmButton") as M3Button
		if _confirm_btn == null:
			_confirm_btn = M3Button.new()
			_confirm_btn.name = "ConfirmButton"
			add_child(_confirm_btn)
		_confirm_btn.variant = M3Button.Variant.TEXT
		_confirm_btn.text = "OK"
		if not _confirm_btn.pressed.is_connected(_on_confirm_pressed):
			_confirm_btn.pressed.connect(_on_confirm_pressed)

func _layout_children() -> void:
	var w: float = maxf(size.x, 328.0)
	var h: float = maxf(size.y, 420.0)
	if _mode_switch_btn != null:
		_mode_switch_btn.position = Vector2(w - 52.0, 48.0)
		_mode_switch_btn.size = Vector2(40.0, 40.0)
	if _month_year_btn != null:
		_month_year_btn.position = Vector2(16.0, 108.0)
		_month_year_btn.size = Vector2(156.0, 36.0)
	if _prev_month_btn != null:
		_prev_month_btn.position = Vector2(w - 96.0, 106.0)
		_prev_month_btn.size = Vector2(40.0, 40.0)
	if _next_month_btn != null:
		_next_month_btn.position = Vector2(w - 52.0, 106.0)
		_next_month_btn.size = Vector2(40.0, 40.0)
	if _year_grid_container != null:
		_year_grid_container.position = Vector2(20.0, 154.0)
		_year_grid_container.size = Vector2(w - 40.0, 206.0)
	if _date_input_field != null:
		_date_input_field.position = Vector2(24.0, 132.0)
		_date_input_field.size = Vector2(w - 48.0, 76.0)
	if _cancel_btn != null:
		_cancel_btn.position = Vector2(w - 160.0, h - 52.0)
		_cancel_btn.size = Vector2(72.0, 40.0)
	if _confirm_btn != null:
		_confirm_btn.position = Vector2(w - 80.0, h - 52.0)
		_confirm_btn.size = Vector2(64.0, 40.0)

func _sync_child_visibility() -> void:
	var is_input: bool = (picker_mode == PickerMode.INPUT)
	if _mode_switch_btn != null:
		_mode_switch_btn.icon_name = &"edit" if not is_input else &""
		_mode_switch_btn.queue_redraw()
	if _month_year_btn != null:
		_month_year_btn.visible = not is_input
	if _prev_month_btn != null:
		_prev_month_btn.visible = (not is_input) and (not year_picker_open)
	if _next_month_btn != null:
		_next_month_btn.visible = (not is_input) and (not year_picker_open)
	if _year_grid_container != null:
		_year_grid_container.visible = (not is_input) and year_picker_open
	if _date_input_field != null:
		_date_input_field.visible = is_input

func _populate_year_grid(center_year: int) -> void:
	if _year_grid_container == null:
		return
	_year_grid_base_year = center_year
	for c in _year_grid_container.get_children():
		_year_grid_container.remove_child(c)
		c.queue_free()
	_year_buttons.clear()

	var start_y: int = center_year - 6
	for i in range(15):
		var y: int = start_y + i
		var y_btn := M3Button.new()
		y_btn.name = "YearBtn_%d" % y
		y_btn.text = str(y)
		y_btn.custom_minimum_size = Vector2(88.0, 34.0)
		y_btn.size = Vector2(88.0, 34.0)
		y_btn.variant = M3Button.Variant.FILLED if y == selected_year else M3Button.Variant.TEXT
		var captured_y: int = y
		y_btn.pressed.connect(func() -> void: select_year(captured_y))
		_year_grid_container.add_child(y_btn)
		_year_buttons[y] = y_btn

func _refresh_year_grid_selection() -> void:
	for y in _year_buttons.keys():
		var btn: M3Button = _year_buttons[y] as M3Button
		if btn != null and is_instance_valid(btn):
			btn.variant = M3Button.Variant.FILLED if int(y) == selected_year else M3Button.Variant.TEXT

func get_year_button(year: int) -> M3Button:
	if _year_buttons.has(year):
		return _year_buttons[year] as M3Button
	return null

func get_month_year_button() -> M3Button:
	return _month_year_btn

func _on_month_year_pressed() -> void:
	set_year_picker_open(not year_picker_open)

func set_year_picker_open(open_state: bool) -> void:
	if year_picker_open == open_state and ((open_state and year_picker_progress >= 0.99) or (not open_state and year_picker_progress <= 0.01)):
		return
	year_picker_open = open_state
	if year_picker_open:
		if not _year_buttons.has(selected_year):
			_populate_year_grid(selected_year)
		else:
			_refresh_year_grid_selection()
	_sync_child_visibility()

	var target: float = 1.0 if year_picker_open else 0.0
	if not is_inside_tree():
		year_picker_progress = target
		queue_redraw()
		return

	year_picker_progress = 0.0 if year_picker_open else 1.0
	if _year_tween != null and _year_tween.is_valid():
		_year_tween.kill()
	_year_tween = create_tween().set_parallel(true)
	if _year_tween:
		_year_tween.bind_node(self)
		_year_tween.set_trans(Tween.TRANS_CUBIC)
		_year_tween.set_ease(Tween.EASE_OUT)
		_year_tween.tween_property(self, ^"year_picker_progress", target, 0.22)
		_year_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.22)

func select_year(year: int) -> void:
	selected_year = clampi(year, 1900, 2100)
	_refresh_year_grid_selection()
	year_selected.emit(selected_year)
	set_year_picker_open(false)
	date_selected.emit(selected_year, selected_month, selected_day)

func _sync_input_field_text() -> void:
	if _date_input_field != null:
		var formatted: String = "%02d/%02d/%04d" % [selected_month, selected_day, selected_year]
		if _date_input_field.text != formatted:
			_updating_input_field = true
			_date_input_field.text = formatted
			_updating_input_field = false

func _on_mode_btn_draw() -> void:
	if _mode_switch_btn == null or picker_mode != PickerMode.INPUT:
		return
	var col := get_m3_color(&"on_surface_variant")
	var c := _mode_switch_btn.size * 0.5
	var r := Rect2(c - Vector2(8.0, 7.0), Vector2(16.0, 15.0))
	_mode_switch_btn.draw_rect(r, col, false, 1.8)
	_mode_switch_btn.draw_line(r.position + Vector2(0, 4), r.position + Vector2(r.size.x, 4), col, 1.8)
	_mode_switch_btn.draw_line(r.position + Vector2(4, -2), r.position + Vector2(4, 2), col, 1.8)
	_mode_switch_btn.draw_line(r.position + Vector2(r.size.x - 4, -2), r.position + Vector2(r.size.x - 4, 2), col, 1.8)

func _on_prev_btn_draw() -> void:
	if _prev_month_btn == null:
		return
	var col := get_m3_color(&"on_surface_variant")
	var c := _prev_month_btn.size * 0.5
	var pts := PackedVector2Array([c + Vector2(3.0, -6.0), c + Vector2(-3.0, 0.0), c + Vector2(3.0, 6.0)])
	_prev_month_btn.draw_polyline(pts, col, 2.0, true)

func _on_next_btn_draw() -> void:
	if _next_month_btn == null:
		return
	var col := get_m3_color(&"on_surface_variant")
	var c := _next_month_btn.size * 0.5
	var pts := PackedVector2Array([c + Vector2(-3.0, -6.0), c + Vector2(3.0, 0.0), c + Vector2(-3.0, 6.0)])
	_next_month_btn.draw_polyline(pts, col, 2.0, true)

func _on_mode_switch_pressed() -> void:
	if picker_mode == PickerMode.INPUT:
		picker_mode = PickerMode.MODAL
	else:
		picker_mode = PickerMode.INPUT

func _on_prev_month_pressed() -> void:
	if selected_month == 1:
		selected_month = 12
		selected_year -= 1
	else:
		selected_month -= 1
	_animate_month_transition()

func _on_next_month_pressed() -> void:
	if selected_month == 12:
		selected_month = 1
		selected_year += 1
	else:
		selected_month += 1
	_animate_month_transition()

func _on_date_input_text_changed(new_text: String) -> void:
	if _updating_input_field:
		return
	var parts := new_text.split("/")
	if parts.size() == 3 and parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int():
		var m: int = parts[0].to_int()
		var d: int = parts[1].to_int()
		var y: int = parts[2].to_int()
		if y >= 1900 and y <= 2100 and m >= 1 and m <= 12:
			var max_d: int = _days_in_month(y, m)
			if d >= 1 and d <= max_d:
				selected_year = y
				selected_month = m
				selected_day = d
				date_selected.emit(selected_year, selected_month, selected_day)

func _on_cancel_pressed() -> void:
	cancelled.emit()
	close()

func _on_confirm_pressed() -> void:
	date_confirmed.emit(selected_year, selected_month, selected_day)

func open() -> void:
	is_open = true

func close() -> void:
	is_open = false

func _animate_open(opening: bool) -> void:
	visible = true
	var target: float = 1.0 if opening else 0.0
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true)
	if _open_tween:
		_open_tween.bind_node(self)
		_open_tween.set_trans(Tween.TRANS_CUBIC)
		_open_tween.set_ease(Tween.EASE_OUT)
		_open_tween.tween_property(self, ^"open_progress", target, 0.22)
		_open_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.22)

func _animate_selection() -> void:
	selection_anim_progress = 0.0
	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()
	_selection_tween = create_tween().set_parallel(true)
	if _selection_tween:
		_selection_tween.bind_node(self)
		_selection_tween.set_trans(Tween.TRANS_BACK)
		_selection_tween.set_ease(Tween.EASE_OUT)
		_selection_tween.tween_property(self, ^"selection_anim_progress", 1.0, 0.22)
		_selection_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.22)

func _animate_month_transition() -> void:
	month_transition_progress = 0.0
	if _month_tween != null and _month_tween.is_valid():
		_month_tween.kill()
	_month_tween = create_tween().set_parallel(true)
	if _month_tween:
		_month_tween.bind_node(self)
		_month_tween.set_trans(Tween.TRANS_CUBIC)
		_month_tween.set_ease(Tween.EASE_OUT)
		_month_tween.tween_property(self, ^"month_transition_progress", 1.0, 0.22)
		_month_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.22)

static func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

static func _days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if _is_leap_year(year) else 28
	return 30

## Sakamoto's algorithm: 0 = Sunday .. 6 = Saturday
static func _weekday_of(year: int, month: int, day: int) -> int:
	var t: Array[int] = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	var y: int = year
	if month < 3:
		y -= 1
	return (y + int(y / 4) - int(y / 100) + int(y / 400) + t[month - 1] + day) % 7

func get_formatted_headline() -> String:
	var m_idx: int = clampi(selected_month - 1, 0, 11)
	if range_selection:
		return "%s %d – %s %d" % [MONTH_SHORT[m_idx], range_start_day, MONTH_SHORT[m_idx], range_end_day]
	var wd: int = _weekday_of(selected_year, selected_month, selected_day)
	return "%s, %s %d" % [WEEKDAY_SHORT[wd], MONTH_SHORT[m_idx], selected_day]

## Returns the local center coordinates of `day` (1..days_in_month) in the calendar grid.
func get_day_cell_position(day: int) -> Vector2:
	var w: float = maxf(size.x, 328.0)
	var col_w: float = (w - 24.0) / 7.0
	var first_wd: int = _weekday_of(selected_year, selected_month, 1)
	var slot: int = first_wd + (day - 1)
	var row: int = int(slot / 7)
	var col: int = slot % 7
	return Vector2(12.0 + float(col) * col_w + col_w * 0.5, 180.0 + float(row) * 30.0 + 15.0)

func _get_day_at_position(pos: Vector2) -> int:
	if picker_mode == PickerMode.INPUT or year_picker_open:
		return -1
	var w: float = maxf(size.x, 328.0)
	if pos.x < 12.0 or pos.x > w - 12.0 or pos.y < 180.0 or pos.y > 360.0:
		return -1
	var col_w: float = (w - 24.0) / 7.0
	var col: int = clampi(int(floor((pos.x - 12.0) / col_w)), 0, 6)
	var row: int = clampi(int(floor((pos.y - 180.0) / 30.0)), 0, 5)
	var first_wd: int = _weekday_of(selected_year, selected_month, 1)
	var day: int = (row * 7 + col) - first_wd + 1
	var max_d: int = _days_in_month(selected_year, selected_month)
	if day < 1 or day > max_d:
		return -1
	return day

func select_day(day: int) -> void:
	var max_d: int = _days_in_month(selected_year, selected_month)
	var clamped: int = clampi(day, 1, max_d)
	selected_day = clamped
	if range_selection:
		if clamped < range_start_day:
			range_start_day = clamped
		else:
			range_end_day = clamped
	_animate_selection()
	date_selected.emit(selected_year, selected_month, selected_day)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var d: int = _get_day_at_position(mm.position)
		if d != _hovered_day:
			_hovered_day = d
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var d: int = _get_day_at_position(mb.position)
			if d >= 1:
				select_day(d)
				accept_event()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var surf_high := get_m3_color(&"surface_container_high")
	var on_surf := get_m3_color(&"on_surface")
	var on_surf_var := get_m3_color(&"on_surface_variant")
	var primary_col := get_m3_color(&"primary")
	var on_primary_col := get_m3_color(&"on_primary")
	var sec_container := get_m3_color(&"secondary_container")
	var on_sec_container := get_m3_color(&"on_secondary_container")
	var outline_var := get_m3_color(&"outline_variant")

	# 1. Container surface (28dp corner radius per M3 Date Picker spec)
	var sb := StyleBoxFlat.new()
	sb.bg_color = surf_high
	var rad: int = 16 if picker_mode == PickerMode.DOCKED else 28
	sb.set_corner_radius_all(rad)
	if picker_mode == PickerMode.DOCKED:
		sb.border_color = outline_var
		sb.set_border_width_all(1)
	else:
		sb.shadow_color = Color(0, 0, 0, 0.22 * open_progress)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 3)
	draw_style_box(sb, r)

	if _font == null:
		return

	# 2. Header (overline + selected date headline + divider)
	var overline_str: String = "Select range" if range_selection else "Select date"
	draw_string(_font, Vector2(24.0, 28.0), overline_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, on_surf_var)

	var headline_str: String = get_formatted_headline()
	var headline_size: int = 22 if range_selection else 26
	draw_string(_font, Vector2(24.0, 74.0), headline_str, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 84.0), headline_size, on_surf)

	draw_line(Vector2(0.0, 100.0), Vector2(size.x, 100.0), outline_var, 1.0)

	if picker_mode == PickerMode.INPUT:
		return

	# 3. Month / Year Navigation bar
	var m_idx: int = clampi(selected_month - 1, 0, 11)
	var month_year_str: String = "%s %d" % [MONTH_NAMES[m_idx], selected_year]
	draw_string(_font, Vector2(24.0, 131.0), month_year_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, on_surf_var)
	var my_w: float = _font.get_string_size(month_year_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var tri_center := Vector2(24.0 + my_w + 14.0, 126.0)
	var tri_pts: PackedVector2Array
	if year_picker_open:
		tri_pts = PackedVector2Array([
			tri_center + Vector2(-4.0, 2.5),
			tri_center + Vector2(4.0, 2.5),
			tri_center + Vector2(0.0, -2.5)
		])
	else:
		tri_pts = PackedVector2Array([
			tri_center + Vector2(-4.0, -2.0),
			tri_center + Vector2(4.0, -2.0),
			tri_center + Vector2(0.0, 3.0)
		])
	draw_colored_polygon(tri_pts, on_surf_var)

	if year_picker_open:
		draw_line(Vector2(0.0, 148.0), Vector2(size.x, 148.0), outline_var, 1.0)
		draw_line(Vector2(0.0, 364.0), Vector2(size.x, 364.0), outline_var, 1.0)
		return

	# 4. Weekday header (S M T W T F S)
	var col_w: float = (size.x - 24.0) / 7.0
	for c in range(7):
		var cx: float = 12.0 + float(c) * col_w + col_w * 0.5
		var lw: float = _font.get_string_size(WEEKDAY_LETTERS[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(_font, Vector2(cx - lw * 0.5, 168.0), WEEKDAY_LETTERS[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, on_surf_var)

	# 5. Calendar grid days
	var max_d: int = _days_in_month(selected_year, selected_month)
	var cell_r: float = 14.0

	# Draw range highlight strip first
	if range_selection and range_end_day >= range_start_day:
		for d in range(range_start_day, mini(range_end_day, max_d) + 1):
			var cpos := get_day_cell_position(d)
			var bar_rect := Rect2(cpos.x - col_w * 0.5, cpos.y - cell_r, col_w, cell_r * 2.0)
			if d == range_start_day:
				bar_rect.position.x = cpos.x
				bar_rect.size.x = col_w * 0.5
			elif d == range_end_day:
				bar_rect.size.x = col_w * 0.5
			draw_rect(bar_rect, sec_container)

	for d in range(1, max_d + 1):
		var cpos := get_day_cell_position(d)
		var is_sel: bool = (d == selected_day) or (range_selection and (d == range_start_day or d == range_end_day))
		var is_in_range: bool = range_selection and d > range_start_day and d < range_end_day
		var is_today: bool = (d == today_day)

		var text_col: Color = on_surf
		if is_sel:
			var anim_r: float = cell_r * lerpf(0.65, 1.0, clampf(selection_anim_progress, 0.0, 1.0))
			draw_circle(cpos, anim_r, primary_col)
			text_col = on_primary_col
		elif is_in_range:
			text_col = on_sec_container
		elif is_today:
			draw_arc(cpos, cell_r, 0.0, TAU, 24, primary_col, 1.5, true)
			text_col = primary_col
		elif d == _hovered_day:
			draw_circle(cpos, cell_r, Color(on_surf, 0.08))

		var d_str: String = str(d)
		var dw: float = _font.get_string_size(d_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var dy: float = cpos.y - _font.get_height(12) * 0.5 + _font.get_ascent(12)
		draw_string(_font, Vector2(cpos.x - dw * 0.5, dy), d_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_col)
