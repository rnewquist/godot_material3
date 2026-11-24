@tool
class_name M3SegmentedButtonGroup
extends HBoxContainer

## Material 3 Segmented Button Group container managing single or multi-selection.

signal selection_changed(indices: Array[int])
signal item_selected(index: int)

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

var _selection_anim_progress: float = 0.0
var _group_tween: Tween = null

func _init() -> void:
	add_theme_constant_override(&"separation", -1)

func _ready() -> void:
	child_entered_tree.connect(_on_child_tree_changed)
	child_exiting_tree.connect(_on_child_tree_changed)
	_update_segment_positions()
	_apply_selection_to_children()

func add_segment(p_text: String, p_icon: StringName = &"") -> M3SegmentedButton:
	var btn := M3SegmentedButton.new()
	btn.name = "Segment_%d" % get_segments().size()
	btn.text = p_text
	btn.icon_name = p_icon
	add_child(btn)
	_update_segment_positions()
	return btn

func select(p_index: int) -> void:
	if not multi_select:
		selected_indices = [p_index]
	else:
		if not selected_indices.has(p_index):
			var arr := selected_indices.duplicate()
			arr.append(p_index)
			selected_indices = arr
	_apply_selection_to_children()
	_animate_group_transition()
	item_selected.emit(p_index)
	selection_changed.emit(selected_indices)

func deselect(p_index: int) -> void:
	if selected_indices.has(p_index):
		var arr := selected_indices.duplicate()
		arr.erase(p_index)
		selected_indices = arr
		_apply_selection_to_children()
		_animate_group_transition()
		selection_changed.emit(selected_indices)

func toggle(p_index: int) -> void:
	if selected_indices.has(p_index):
		if multi_select:
			deselect(p_index)
	else:
		select(p_index)

func clear_selection() -> void:
	selected_indices = []
	_apply_selection_to_children()
	_animate_group_transition()
	selection_changed.emit(selected_indices)

func get_segments() -> Array[M3SegmentedButton]:
	var result: Array[M3SegmentedButton] = []
	for child in get_children():
		if child is M3SegmentedButton:
			result.append(child)
	return result

func _animate_group_transition() -> void:
	if not is_inside_tree():
		_selection_anim_progress = 1.0
		return
	if _group_tween != null and _group_tween.is_valid():
		_group_tween.kill()
	_selection_anim_progress = 0.0
	_group_tween = create_tween()
	if _group_tween:
		_group_tween.bind_node(self)
		_group_tween.set_trans(Tween.TRANS_CUBIC)
		_group_tween.set_ease(Tween.EASE_OUT)
		_group_tween.tween_property(self, ^"_selection_anim_progress", 1.0, 0.2)

func _on_child_tree_changed(_node: Node) -> void:
	_update_segment_positions()

func _update_segment_positions() -> void:
	var segments := get_segments()
	var count: int = segments.size()
	var total_w: float = 0.0
	for i in range(count):
		var btn := segments[i]
		btn.index = i
		btn.is_single = (count == 1)
		btn.is_first = (i == 0 and count > 1)
		btn.is_last = (i == count - 1 and count > 1)
		if not btn.segment_pressed.is_connected(_on_segment_pressed):
			btn.segment_pressed.connect(_on_segment_pressed)
		total_w += btn.get_combined_minimum_size().x
	if count > 0:
		var target_size := Vector2(maxf(total_w - float(maxi(0, count - 1)), 48.0), 40.0)
		custom_minimum_size = target_size
		if size.x < target_size.x or size.y < target_size.y:
			size = target_size

func _apply_selection_to_children() -> void:
	var segments := get_segments()
	for i in range(segments.size()):
		var btn := segments[i]
		var should_select: bool = selected_indices.has(i)
		if btn.selected != should_select:
			btn.selected = should_select
	_update_segment_positions()

func _validate_selection() -> void:
	if not multi_select and selected_indices.size() > 1:
		selected_indices = [selected_indices[0]]
		_apply_selection_to_children()

func _on_segment_pressed(btn: M3SegmentedButton) -> void:
	toggle(btn.index)
