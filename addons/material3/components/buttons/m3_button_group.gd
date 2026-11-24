@tool
class_name M3ButtonGroup
extends HBoxContainer

## Material 3 Expressive Button Group component (https://m3.material.io/components/button-groups/overview).
## Supports STANDARD and CONNECTED variants with springy press/selection width expansion and corner morphing.

enum GroupVariant {
	STANDARD,
	CONNECTED
}

enum Variant {
	STANDARD,
	CONNECTED
}

signal button_pressed(index: int)
signal selection_changed(selected_indices: Array[int])

@export var group_variant: GroupVariant = GroupVariant.STANDARD:
	set(value):
		group_variant = value
		_update_group_layout()

@export var variant: GroupVariant:
	get:
		return group_variant
	set(value):
		group_variant = value

@export var selectable: bool = true:
	set(value):
		selectable = value
		_update_group_layout()

@export var multi_select: bool = false:
	set(value):
		multi_select = value
		_validate_selection()

@export var selected_indices: Array[int] = []:
	set(value):
		selected_indices = value
		_apply_selection_to_children()

@export var selected_index: int = -1:
	get:
		return selected_indices[0] if not selected_indices.is_empty() else -1
	set(value):
		if value < 0:
			selected_indices = []
		else:
			selected_indices = [value]
		_apply_selection_to_children()

@export var button_variant: M3Button.Variant = M3Button.Variant.TONAL:
	set(value):
		button_variant = value
		for btn in get_buttons():
			btn.variant = button_variant
		_update_group_layout()

@export var expand_width_delta: float = 18.0:
	set(value):
		expand_width_delta = maxf(0.0, value)
		_apply_expand_step(_active_expand_ratio)

var _active_expand_ratio: float = 0.0
var _active_index: int = -1
var _pressed_index: int = -1
var _hovered_index: int = -1
var _expand_tween: Tween = null
var _connected_buttons: Dictionary = {}

func _init() -> void:
	_apply_separation()

func _ready() -> void:
	if not child_entered_tree.is_connected(_on_child_tree_changed):
		child_entered_tree.connect(_on_child_tree_changed)
	if not child_exiting_tree.is_connected(_on_child_tree_changed):
		child_exiting_tree.connect(_on_child_tree_changed)
	_update_group_layout()
	_apply_selection_to_children()

func add_button(p_text: String, p_icon: String = "") -> M3Button:
	var btn := M3Button.new()
	btn.name = "GroupButton_%d" % get_buttons().size()
	btn.text = p_text
	if p_icon != "":
		btn.leading_icon = StringName(p_icon)
	btn.variant = button_variant
	btn.toggle_mode = selectable
	add_child(btn)
	_wire_button(btn)
	_update_group_layout()
	return btn

func get_buttons() -> Array[M3Button]:
	var result: Array[M3Button] = []
	for child in get_children():
		if child is M3Button:
			result.append(child)
	return result

func get_button_count() -> int:
	return get_buttons().size()

func select(p_index: int) -> void:
	var btns := get_buttons()
	if p_index < 0 or p_index >= btns.size():
		return
	if not multi_select:
		selected_indices = [p_index]
	elif not selected_indices.has(p_index):
		var next := selected_indices.duplicate()
		next.append(p_index)
		selected_indices = next
	_active_index = p_index
	_apply_selection_to_children()
	_animate_expand(1.0)
	selection_changed.emit(selected_indices)

func deselect(p_index: int) -> void:
	if selected_indices.has(p_index):
		var next := selected_indices.duplicate()
		next.erase(p_index)
		selected_indices = next
		_apply_selection_to_children()
		if selected_indices.is_empty():
			_animate_expand(0.0)
		selection_changed.emit(selected_indices)

func toggle(p_index: int) -> void:
	if selected_indices.has(p_index):
		if multi_select:
			deselect(p_index)
		else:
			_active_index = p_index
			_animate_expand(1.0)
	else:
		select(p_index)

func clear_selection() -> void:
	selected_indices = []
	_apply_selection_to_children()
	_animate_expand(0.0)
	selection_changed.emit(selected_indices)

func _apply_separation() -> void:
	var sep: int = 2 if group_variant == GroupVariant.CONNECTED else 8
	add_theme_constant_override(&"separation", sep)

func _on_child_tree_changed(node: Node) -> void:
	if node is M3Button:
		_wire_button(node as M3Button)
	_update_group_layout()

func _wire_button(btn: M3Button) -> void:
	var id: int = btn.get_instance_id()
	if _connected_buttons.has(id):
		return
	_connected_buttons[id] = true
	btn.pressed.connect(func() -> void: _on_child_button_pressed(btn))
	btn.state_changed.connect(func(old_st: M3Control.ControlState, new_st: M3Control.ControlState) -> void:
		_on_child_button_state_changed(btn, old_st, new_st)
	)

func _index_of_button(btn: M3Button) -> int:
	var btns := get_buttons()
	return btns.find(btn)

func _on_child_button_pressed(btn: M3Button) -> void:
	var idx: int = _index_of_button(btn)
	if idx < 0:
		return
	_active_index = idx
	if selectable:
		if multi_select:
			if selected_indices.has(idx):
				var next := selected_indices.duplicate()
				next.erase(idx)
				selected_indices = next
			else:
				var next := selected_indices.duplicate()
				next.append(idx)
				selected_indices = next
		else:
			selected_indices = [idx]
		_apply_selection_to_children()
		selection_changed.emit(selected_indices)
	_animate_expand(1.0)
	button_pressed.emit(idx)

func _on_child_button_state_changed(btn: M3Button, _old_st: M3Control.ControlState, new_st: M3Control.ControlState) -> void:
	var idx: int = _index_of_button(btn)
	if idx < 0:
		return
	match new_st:
		M3Control.ControlState.PRESSED:
			_pressed_index = idx
			_active_index = idx
			_animate_expand(1.0)
		M3Control.ControlState.HOVERED:
			_hovered_index = idx
			if _pressed_index < 0:
				_active_index = idx
				_animate_expand(0.6)
		_:
			if _pressed_index == idx:
				_pressed_index = -1
			if _hovered_index == idx:
				_hovered_index = -1
			if _pressed_index < 0 and _hovered_index < 0:
				if not selected_indices.is_empty():
					_active_index = selected_indices[selected_indices.size() - 1]
					_animate_expand(0.75)
				else:
					_animate_expand(0.0)

func _animate_expand(target: float) -> void:
	if not is_inside_tree():
		_apply_expand_step(target)
		return
	if _expand_tween != null and _expand_tween.is_valid():
		_expand_tween.kill()
	_expand_tween = create_tween()
	if _expand_tween:
		_expand_tween.bind_node(self)
		_expand_tween.set_trans(Tween.TRANS_BACK)
		_expand_tween.set_ease(Tween.EASE_OUT)
		var start_val: float = _active_expand_ratio
		if is_equal_approx(start_val, target):
			start_val = maxf(0.0, target - 0.5)
		_expand_tween.tween_method(_apply_expand_step, start_val, target, 0.22)
	else:
		_apply_expand_step(target)

func _apply_expand_step(val: float) -> void:
	_active_expand_ratio = val
	_update_group_layout()

func _update_group_layout() -> void:
	_apply_separation()
	var btns := get_buttons()
	var count: int = btns.size()
	var sep: float = 2.0 if group_variant == GroupVariant.CONNECTED else 8.0
	var total_w: float = 0.0
	var max_h: float = 40.0

	for i in range(count):
		var btn := btns[i]
		_wire_button(btn)
		btn.toggle_mode = selectable
		var is_active: bool = (i == _active_index)
		var bonus: float = (expand_width_delta * _active_expand_ratio) if is_active else 0.0
		btn.width_bonus = bonus

		var h: float = maxf(40.0, btn.custom_minimum_size.y)
		var pill_r: float = h * 0.5
		if group_variant == GroupVariant.CONNECTED and count > 1:
			var inner_r: float = lerpf(8.0, 4.0, _active_expand_ratio if is_active else 0.0)
			if selected_indices.has(i):
				inner_r = lerpf(12.0, pill_r, 0.4)
			var left_r: float = pill_r if i == 0 else inner_r
			var right_r: float = pill_r if i == count - 1 else inner_r
			btn.set_corner_radii(left_r, right_r, right_r, left_r)
			btn.custom_corner_radius = inner_r
		else:
			btn.clear_corner_radii()
			var r_target: float = lerpf(pill_r, 12.0, (_active_expand_ratio * 0.5) if is_active else 0.0)
			btn.custom_corner_radius = r_target

		total_w += btn.custom_minimum_size.x
		max_h = maxf(max_h, btn.custom_minimum_size.y)

	if count > 0:
		total_w += sep * float(count - 1)
		custom_minimum_size = Vector2(total_w, max_h)
		size = Vector2(maxf(size.x, total_w), maxf(size.y, max_h))
		queue_sort()

func _apply_selection_to_children() -> void:
	var btns := get_buttons()
	for i in range(btns.size()):
		var btn := btns[i]
		var sel: bool = selected_indices.has(i)
		if btn.button_pressed != sel:
			btn.button_pressed = sel
	_update_group_layout()

func _validate_selection() -> void:
	if not multi_select and selected_indices.size() > 1:
		selected_indices = [selected_indices[0]]
		_apply_selection_to_children()
