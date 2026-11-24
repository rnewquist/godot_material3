@tool
class_name M3SelectDropdown
extends M3BaseControl

signal item_selected(index: int, value: String)

@export var label: String = "Select Option":
	set(v):
		label = v
		queue_redraw()

@export var options: Array[String] = ["Option 1", "Option 2", "Option 3"]:
	set(v):
		options = v
		if selected_index >= options.size():
			selected_index = 0
		queue_redraw()

@export var selected_index: int = 0:
	set(v):
		if v >= 0 and v < options.size():
			selected_index = v
			item_selected.emit(selected_index, get_selected_value())
			queue_redraw()

@export var is_open: bool = false:
	set(v):
		if is_open != v:
			is_open = v
			_animate_open(is_open)
			queue_redraw()

var open_progress: float = 0.0:
	set(v):
		open_progress = v
		queue_redraw()

var _menu: M3Menu
var _open_tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(200, 56)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_menu = M3Menu.new()
	_menu.name = "DropdownM3Menu"
	_menu.top_level = true
	_menu.item_selected.connect(_on_menu_item_selected)
	_menu.dismissed.connect(_on_menu_dismissed)
	add_child(_menu)

func get_selected_value() -> String:
	if selected_index >= 0 and selected_index < options.size():
		return options[selected_index]
	return ""

func _on_menu_item_selected(id: int, _lbl: String) -> void:
	selected_index = id
	is_open = false

func _on_menu_dismissed() -> void:
	is_open = false

func _animate_open(opening: bool) -> void:
	var target: float = 1.0 if opening else 0.0
	if not is_inside_tree():
		open_progress = target
		return
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true)
	if _open_tween:
		_open_tween.bind_node(self)
		_open_tween.set_trans(Tween.TRANS_CUBIC)
		_open_tween.set_ease(Tween.EASE_OUT)
		_open_tween.tween_property(self, ^"open_progress", target, 0.2)
		_open_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)

func _gui_input(event: InputEvent) -> void:
	super._gui_input(event)
	if disabled or options.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_show_dropdown()

func _show_dropdown() -> void:
	if not _menu:
		return
	_menu._items.clear()
	if _menu._vbox:
		for c in _menu._vbox.get_children():
			c.queue_free()

	for i in range(options.size()):
		_menu.add_menu_item(options[i], i)

	is_open = true
	_menu.popup_at_control(self)

func _draw() -> void:
	var s := get_scheme()
	var rect := Rect2(Vector2.ZERO, size)
	var corner_rad: float = 4.0

	# Outlined box
	var sb := create_stylebox(Color.TRANSPARENT, corner_rad, 1, s.primary if is_open else s.outline_variant)
	sb.draw(get_canvas_item(), rect)

	var font := get_theme_default_font()
	if font:
		# Floating Label
		var lbl_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_rect(Rect2(Vector2(12, -2), Vector2(lbl_w + 8, 4)), s.surface)
		draw_string(font, Vector2(16, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, s.primary if is_open else s.on_surface_variant)

		# Selected Value
		var val := get_selected_value()
		draw_string(font, Vector2(16, 36), val, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 48), 14, s.on_surface)

	# Trailing Arrow
	var arrow_x := size.x - 24.0
	var arrow_y := 28.0
	var rot: float = PI * open_progress
	var center := Vector2(arrow_x, arrow_y)
	var p1 := Vector2(-5, -2).rotated(rot) + center
	var p2 := Vector2(0, 3).rotated(rot) + center
	var p3 := Vector2(5, -2).rotated(rot) + center
	draw_line(p1, p2, s.on_surface_variant, 2.0, true)
	draw_line(p2, p3, s.on_surface_variant, 2.0, true)
