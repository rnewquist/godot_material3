@tool
class_name M3BottomAppBar
extends M3Control

## Material Design 3 Bottom App Bar.
## 80dp height surface_container bar with up to 4 leading M3IconButton actions
## and an embedded trailing M3FAB (0dp elevation inside the bar).
## Supports hide-on-scroll transition animating visible_progress (0.0..1.0) and vertical offset.

const MAX_ACTIONS := 4

signal action_pressed(index: int)
signal fab_pressed()
signal visibility_progress_changed(progress: float)

@export var show_fab: bool = true:
	set(value):
		show_fab = value
		_sync_fab()
		_layout_children()
		queue_redraw()

@export var fab_icon: String = "add":
	set(value):
		fab_icon = value
		_sync_fab()
		queue_redraw()

@export var hidden_on_scroll: bool = false:
	set(value):
		if hidden_on_scroll != value:
			hidden_on_scroll = value
			_animate_hidden_on_scroll(hidden_on_scroll, is_inside_tree())

var visible_progress: float = 1.0:
	set(value):
		visible_progress = clampf(value, 0.0, 1.0)
		_vertical_offset = (1.0 - visible_progress) * 80.0
		_layout_children()
		visibility_progress_changed.emit(visible_progress)
		queue_redraw()

var _vertical_offset: float = 0.0
var _action_buttons: Array[M3IconButton] = []
var _fab: M3FAB = null
var _tween: Tween = null

func _init() -> void:
	super._init()
	ripple_enabled = false
	custom_minimum_size = Vector2(320.0, 80.0)
	size_flags_horizontal = SIZE_EXPAND_FILL
	_ensure_fab()

func _ready() -> void:
	super._ready()
	_ensure_fab()
	_sync_fab()
	_layout_children()

func _ensure_fab() -> void:
	if _fab != null and is_instance_valid(_fab):
		return
	var existing := get_node_or_null(^"EmbeddedFAB") as M3FAB
	if existing != null:
		_fab = existing
	else:
		_fab = M3FAB.new()
		_fab.name = "EmbeddedFAB"
		_fab.fab_variant = M3FAB.FabVariant.STANDARD
		_fab.color_palette = M3FAB.FabColorPalette.SECONDARY
		_fab._current_elevation = 0
		_fab._target_elevation = 0
		_fab.pressed.connect(func() -> void: fab_pressed.emit())
		add_child(_fab)
	_sync_fab()

func _sync_fab() -> void:
	if _fab == null or not is_instance_valid(_fab):
		return
	_fab.visible = show_fab
	_fab.icon_name = StringName(fab_icon)
	_fab._current_elevation = 0

## Adds a leading M3IconButton action (up to 4 per M3 spec) and returns it.
func add_action(ic_name: String, tooltip: String = "") -> M3IconButton:
	if _action_buttons.size() >= MAX_ACTIONS:
		return _action_buttons[_action_buttons.size() - 1]
	var idx: int = _action_buttons.size()
	var btn := M3IconButton.new()
	btn.name = "ActionButton_%d" % idx
	btn.icon_name = StringName(ic_name)
	btn.tooltip_text = tooltip
	btn.variant = M3IconButton.Variant.STANDARD
	btn.pressed.connect(func() -> void: action_pressed.emit(idx))
	add_child(btn)
	_action_buttons.append(btn)
	_layout_children()
	queue_redraw()
	return btn

func clear_actions() -> void:
	for btn in _action_buttons:
		if is_instance_valid(btn):
			if btn.get_parent() == self:
				remove_child(btn)
			btn.queue_free()
	_action_buttons.clear()
	_layout_children()
	queue_redraw()

func get_action_button(index: int) -> M3IconButton:
	if index >= 0 and index < _action_buttons.size():
		return _action_buttons[index]
	return null

func get_action_count() -> int:
	return _action_buttons.size()

func get_fab() -> M3FAB:
	return _fab

func _on_resized() -> void:
	super._on_resized()
	_layout_children()

func _layout_children() -> void:
	var bar_h: float = maxf(size.y, 80.0)
	var bar_w: float = maxf(size.x, custom_minimum_size.x)
	var x_cursor: float = 12.0
	var btn_y: float = (bar_h - 40.0) * 0.5 + _vertical_offset
	for btn in _action_buttons:
		if btn != null and is_instance_valid(btn):
			btn.size = Vector2(40.0, 40.0)
			btn.position = Vector2(x_cursor, btn_y)
			btn.modulate.a = visible_progress
			x_cursor += 48.0
	if _fab != null and is_instance_valid(_fab):
		_fab.size = Vector2(56.0, 56.0)
		_fab.position = Vector2(bar_w - 16.0 - 56.0, (bar_h - 56.0) * 0.5 + _vertical_offset)
		_fab.modulate.a = visible_progress

func set_hidden_on_scroll(hidden: bool, animated: bool = true) -> void:
	hidden_on_scroll = hidden
	_animate_hidden_on_scroll(hidden, animated)

func _animate_hidden_on_scroll(hidden: bool, animated: bool = true) -> void:
	var target: float = 0.0 if hidden else 1.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not animated or not is_inside_tree():
		visible_progress = target
		return
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"visible_progress", target, 0.25)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				set_hidden_on_scroll(true, true)
				accept_event()
				return
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_hidden_on_scroll(false, true)
				accept_event()
				return
	super._gui_input(event)

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0 or visible_progress <= 0.001:
		return
	var r := Rect2(Vector2(0.0, _vertical_offset), Vector2(size.x, size.y))
	var bg_col: Color = get_m3_color(&"surface_container")
	bg_col.a *= visible_progress
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	draw_style_box(sb, r)
