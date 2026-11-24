@tool
class_name M3RadioGroup
extends VBoxContainer

## Material 3 Radio Group managing single selection across child M3Radio buttons.

signal selection_changed(selected_radio: M3Radio, value: Variant)

@export var selected_index: int = -1:
	set(value):
		if selected_index != value:
			selected_index = value
			if not _is_updating:
				_select_by_index(value)

var _is_updating: bool = false

func _ready() -> void:
	child_entered_tree.connect(_on_child_tree_changed)
	child_exiting_tree.connect(_on_child_tree_changed)
	_wire_radios()
	if selected_index >= 0:
		_select_by_index(selected_index)

func add_radio(p_text: String, p_value: Variant = null) -> M3Radio:
	var r := M3Radio.new()
	r.name = "Radio_%d" % get_radios().size()
	r.text = p_text
	r.value = p_value if p_value != null else p_text
	add_child(r)
	_wire_radios()
	return r

func get_radios() -> Array[M3Radio]:
	var result: Array[M3Radio] = []
	for child in get_children():
		if child is M3Radio:
			result.append(child)
	return result

func get_selected_radio() -> M3Radio:
	for r in get_radios():
		if r.selected:
			return r
	return null

func get_selected_value() -> Variant:
	var sel := get_selected_radio()
	return sel.value if sel != null else null

func select(p_index: int) -> void:
	_select_by_index(p_index)

func _select_by_index(p_index: int) -> void:
	var radios := get_radios()
	if p_index < 0 or p_index >= radios.size():
		_is_updating = true
		selected_index = -1
		for r in radios:
			r.selected = false
		_is_updating = false
		return

	var target_radio := radios[p_index]
	if not target_radio.selected:
		target_radio.selected = true
	else:
		_on_radio_toggled(true, target_radio)

func _on_child_tree_changed(_node: Node) -> void:
	_wire_radios()

func _wire_radios() -> void:
	var radios := get_radios()
	var max_w: float = 48.0
	var total_h: float = 0.0
	var sep: float = float(get_theme_constant(&"separation"))
	for i in range(radios.size()):
		var r := radios[i]
		if not r.has_meta(&"_m3_group_wired"):
			r.set_meta(&"_m3_group_wired", true)
			r.toggled.connect(_on_radio_toggled.bind(r))
		if r.selected and selected_index < 0:
			selected_index = i
		max_w = maxf(max_w, r.custom_minimum_size.x)
		total_h += r.custom_minimum_size.y + (sep if i > 0 else 0.0)
	custom_minimum_size = Vector2(max_w, total_h)
	size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))

func _on_radio_toggled(is_sel: bool, source_radio: M3Radio) -> void:
	if _is_updating or not is_sel:
		return

	_is_updating = true
	var radios := get_radios()
	for i in range(radios.size()):
		var r := radios[i]
		if r != source_radio:
			r.selected = false
		else:
			r.selected = true
			selected_index = i
	_is_updating = false

	selection_changed.emit(source_radio, source_radio.value)
