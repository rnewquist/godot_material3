@tool
class_name M3FabMenu
extends M3Control

## Material 3 Expressive FAB Menu component (https://m3.material.io/components/fab-menu/overview).
## A trigger FAB that morphs/rotates into a close button and expands/collapses a vertical stack
## of pill-shaped menu item buttons.

signal toggled(is_open: bool)
signal item_selected(index: int, label: String)

const TRIGGER_SIZE: float = 56.0
const ITEM_HEIGHT: float = 44.0
const ITEM_GAP: float = 8.0

@export var is_open: bool = false:
	set(value):
		var changed: bool = (is_open != value)
		is_open = value
		_on_open_updated(value, changed)

@export var color_palette: M3FAB.FabColorPalette = M3FAB.FabColorPalette.PRIMARY:
	set(value):
		color_palette = value
		if _trigger_fab != null and is_instance_valid(_trigger_fab):
			_trigger_fab.color_palette = color_palette
		queue_redraw()

@export var trigger_icon: StringName = &"add":
	set(value):
		trigger_icon = value
		_sync_trigger_visuals()

@export var close_icon: StringName = &"close":
	set(value):
		close_icon = value
		_sync_trigger_visuals()

var open_progress: float = 0.0
var _open_progress: float = 0.0
var trigger_rotation_deg: float = 0.0
var selected_index: int = -1
var selected_label: String = ""

var _items: Array[Dictionary] = []
var _item_buttons: Array[M3Button] = []
var _trigger_fab: M3FAB = null
var _open_tween: Tween = null

func _init() -> void:
	super._init()
	clip_contents = false
	ripple_enabled = false
	custom_minimum_size = Vector2(TRIGGER_SIZE, TRIGGER_SIZE)
	size = custom_minimum_size
	_ensure_trigger()

func _ready() -> void:
	super._ready()
	clip_contents = false
	_ensure_trigger()
	_apply_open_progress(1.0 if is_open else 0.0)

func _ensure_trigger() -> void:
	if _trigger_fab != null and is_instance_valid(_trigger_fab):
		return
	var existing := get_node_or_null(^"TriggerFAB") as M3FAB
	if existing != null:
		_trigger_fab = existing
		return
	_trigger_fab = M3FAB.new()
	_trigger_fab.name = "TriggerFAB"
	_trigger_fab.fab_variant = M3FAB.FabVariant.STANDARD
	_trigger_fab.color_palette = color_palette
	_trigger_fab.icon_name = trigger_icon
	_trigger_fab.position = Vector2.ZERO
	_trigger_fab.size = Vector2(TRIGGER_SIZE, TRIGGER_SIZE)
	_trigger_fab.z_index = 5
	_trigger_fab.pressed.connect(_on_trigger_pressed)
	add_child(_trigger_fab)

func get_trigger_button() -> M3FAB:
	_ensure_trigger()
	return _trigger_fab

func add_item(label: String, icon_name: String = "edit") -> M3Button:
	_ensure_trigger()
	var idx: int = _items.size()
	_items.append({"label": label, "icon": icon_name})

	var btn := M3Button.new()
	btn.name = "FabMenuItem_%d" % idx
	btn.variant = M3Button.Variant.TONAL
	btn.text = label
	btn.leading_icon = StringName(icon_name)
	btn.shape_token = M3Shapes.ShapeToken.FULL
	btn.custom_corner_radius = ITEM_HEIGHT * 0.5
	btn.z_index = 4
	btn.pressed.connect(func() -> void: _on_item_button_pressed(idx))
	add_child(btn)
	_item_buttons.append(btn)

	btn._update_layout()
	var min_w: float = maxf(btn.custom_minimum_size.x, 128.0)
	btn.custom_minimum_size = Vector2(min_w, ITEM_HEIGHT)
	btn.size = btn.custom_minimum_size

	_apply_open_progress(open_progress)
	return btn

func clear_items() -> void:
	_items.clear()
	for btn in _item_buttons:
		if is_instance_valid(btn):
			remove_child(btn)
			btn.queue_free()
	_item_buttons.clear()
	_apply_open_progress(open_progress)

func get_item_count() -> int:
	return _item_buttons.size()

func get_item_button(index: int) -> M3Button:
	if index < 0 or index >= _item_buttons.size():
		return null
	return _item_buttons[index]

func get_item_buttons() -> Array[M3Button]:
	return _item_buttons

func toggle_open() -> void:
	set_open(not is_open)

func set_open(val: bool) -> void:
	is_open = val

func _on_open_updated(val: bool, changed: bool) -> void:
	_ensure_trigger()
	var target: float = 1.0 if val else 0.0
	if val:
		for btn in _item_buttons:
			if is_instance_valid(btn):
				btn.visible = true

	if not is_inside_tree():
		_apply_open_progress(target)
		if changed:
			toggled.emit(is_open)
		return

	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()

	_open_tween = create_tween()
	if _open_tween:
		_open_tween.bind_node(self)
		_open_tween.set_trans(Tween.TRANS_CUBIC)
		_open_tween.set_ease(Tween.EASE_OUT)
		_open_tween.tween_method(_apply_open_progress, open_progress, target, 0.24)
	else:
		_apply_open_progress(target)

	if changed:
		toggled.emit(is_open)

func _on_trigger_pressed() -> void:
	toggle_open()

func _on_pressed_action() -> void:
	toggle_open()

func _on_item_button_pressed(idx: int) -> void:
	if idx < 0 or idx >= _items.size():
		return
	var lbl: String = str(_items[idx].get("label", ""))
	selected_index = idx
	selected_label = lbl
	item_selected.emit(idx, lbl)
	set_open(false)

func _sync_trigger_visuals() -> void:
	if _trigger_fab == null or not is_instance_valid(_trigger_fab):
		return
	_trigger_fab.icon_name = close_icon if open_progress >= 0.5 else trigger_icon
	var rot: float = (open_progress * 45.0) if open_progress < 0.5 else ((open_progress - 1.0) * 45.0)
	_trigger_fab.icon_rotation_deg = rot
	trigger_rotation_deg = open_progress * 45.0
	_trigger_fab.custom_corner_radius = lerpf(16.0, TRIGGER_SIZE * 0.5, open_progress)
	_trigger_fab.queue_redraw()

func _apply_open_progress(p: float) -> void:
	open_progress = p
	_open_progress = p
	_sync_trigger_visuals()

	var count: int = _item_buttons.size()
	var max_w: float = TRIGGER_SIZE
	for i in range(count):
		var btn: M3Button = _item_buttons[i]
		if not is_instance_valid(btn):
			continue
		var stagger: float = float(i) * 0.08 if count <= 6 else (float(i) / float(count)) * 0.4
		var denom: float = maxf(0.1, 1.0 - stagger)
		var item_p: float = clampf((p - stagger) / denom, 0.0, 1.0)

		btn.visible = (p > 0.01)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP if (p > 0.5) else Control.MOUSE_FILTER_IGNORE
		btn.modulate = Color(1.0, 1.0, 1.0, item_p)
		var sc: float = lerpf(0.75, 1.0, item_p)
		btn.scale = Vector2(sc, sc)
		var target_y: float = TRIGGER_SIZE + ITEM_GAP + float(i) * (ITEM_HEIGHT + ITEM_GAP)
		btn.position = Vector2(0.0, lerpf(4.0, target_y, item_p))
		max_w = maxf(max_w, btn.size.x)

	var expanded_h: float = TRIGGER_SIZE
	if count > 0:
		expanded_h = TRIGGER_SIZE + ITEM_GAP + float(count) * (ITEM_HEIGHT + ITEM_GAP)
	var cur_h: float = lerpf(TRIGGER_SIZE, expanded_h, p)
	custom_minimum_size = Vector2(maxf(TRIGGER_SIZE, max_w * p), cur_h)
	size = Vector2(maxf(TRIGGER_SIZE, max_w), maxf(TRIGGER_SIZE, cur_h))
	update_minimum_size()
	queue_redraw()

func _get_minimum_size() -> Vector2:
	return custom_minimum_size
