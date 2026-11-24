@tool
class_name M3List
extends VBoxContainer

## Material 3 List container (https://m3.material.io/components/lists/overview).
## Manages M3ListItem children, optional inter-item M3Dividers, and single-selection state.

signal item_selected(index: int)
signal item_clicked(index: int)

@export var with_dividers: bool = false:
	set(value):
		with_dividers = value
		if is_inside_tree():
			_rebuild_dividers.call_deferred()

@export var selectable: bool = false

@export var selected_index: int = -1:
	set(value):
		if selected_index != value:
			selected_index = value
			_sync_selection()
			if selected_index >= 0:
				item_selected.emit(selected_index)

var _rebuilding_dividers: bool = false

func _init() -> void:
	add_theme_constant_override("separation", 0)
	if not child_entered_tree.is_connected(_on_child_entered):
		child_entered_tree.connect(_on_child_entered)

func _ready() -> void:
	add_theme_constant_override("separation", 0)
	_wire_items()
	if with_dividers:
		_rebuild_dividers()
	_sync_selection()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func add_item(item: M3ListItem) -> M3ListItem:
	add_child(item)
	return item

func get_items() -> Array[M3ListItem]:
	var out: Array[M3ListItem] = []
	for child in get_children():
		if child is M3ListItem and not child.is_queued_for_deletion():
			out.append(child as M3ListItem)
	return out

func select_item(index: int) -> void:
	selected_index = index

func _on_child_entered(node: Node) -> void:
	if _rebuilding_dividers:
		return
	if node is M3ListItem:
		var item := node as M3ListItem
		if not item.clicked.is_connected(_on_item_clicked.bind(item)):
			item.clicked.connect(_on_item_clicked.bind(item))
		if with_dividers and is_inside_tree():
			_rebuild_dividers.call_deferred()

func _wire_items() -> void:
	for item in get_items():
		if not item.clicked.is_connected(_on_item_clicked.bind(item)):
			item.clicked.connect(_on_item_clicked.bind(item))

func _on_item_clicked(item: M3ListItem) -> void:
	var items := get_items()
	var idx: int = items.find(item)
	if idx < 0:
		return
	item_clicked.emit(idx)
	if selectable:
		selected_index = idx

func _sync_selection() -> void:
	var items := get_items()
	for i in range(items.size()):
		items[i].selected = (i == selected_index)

func _rebuild_dividers() -> void:
	if _rebuilding_dividers:
		return
	_rebuilding_dividers = true
	for child in get_children():
		if child is M3Divider:
			remove_child(child)
			child.queue_free()

	if with_dividers:
		var items := get_items()
		for i in range(items.size() - 1):
			var div := M3Divider.new()
			var item_idx: int = items[i].get_index()
			add_child(div)
			move_child(div, item_idx + 1)
	_rebuilding_dividers = false
