# node_matcher.gd
# Composable node query builder and auto-action runner for Godot 4.x.
# Provides screen transform resolution, fluent node finding, auto-interaction proxies,
# and chained assertions on scene hierarchies.
class_name GDTestNodeMatcher
extends RefCounted

const InputSimulator = preload("res://addons/gdtest/core/input_simulator.gd")

var root_node: Node = null
var _suite_ref: Object = null

# Query Filters
var _type_filter: Variant = null # String class name or GDScript/Class
var _text_filter: String = ""
var _text_exact: bool = false
var _name_filter: String = ""
var _name_exact: bool = false
var _group_filter: StringName = &""
var _require_visible_in_tree: bool = false
var _property_filters: Dictionary = {} # prop_name -> expected_value
var _custom_predicates: Array[Callable] = []
var _max_search_depth: int = 100

func _init(p_root: Node, p_suite: Object = null) -> void:
	root_node = p_root
	_suite_ref = p_suite

# --- Query Composability Builders ---

## Filters nodes by class name (e.g. "Button") or script/class (e.g. PlayerController).
func with_type(type_name_or_script: Variant) -> GDTestNodeMatcher:
	_type_filter = type_name_or_script
	return self

## Filters nodes containing the given text in 'text', 'placeholder_text', or 'tooltip_text'.
func with_text(text: String, exact: bool = false) -> GDTestNodeMatcher:
	_text_filter = text
	_text_exact = exact
	return self

## Filters nodes by name.
func with_name(name_filter: String, exact: bool = true) -> GDTestNodeMatcher:
	_name_filter = name_filter
	_name_exact = exact
	return self

## Filters nodes belonging to the specified scene group.
func in_group(group_name: StringName) -> GDTestNodeMatcher:
	_group_filter = group_name
	return self

## Filters nodes that are currently visible within the scene tree.
func is_visible_in_tree() -> GDTestNodeMatcher:
	_require_visible_in_tree = true
	return self

## Filters nodes having a specific property equal to the expected value.
func having_property(property_name: StringName, expected_value: Variant) -> GDTestNodeMatcher:
	_property_filters[property_name] = expected_value
	return self

## Appends a custom predicate Callable(node: Node) -> bool.
func custom(predicate: Callable) -> GDTestNodeMatcher:
	if predicate.is_valid():
		_custom_predicates.append(predicate)
	return self

## Limits recursive search depth.
func max_depth(depth: int) -> GDTestNodeMatcher:
	_max_search_depth = depth
	return self

# --- Query Execution ---

## Finds the first node matching all configured filter criteria.
func find() -> Node:
	if not _is_node_valid(root_node):
		return null
	var matches: Array[Node] = []
	_search_recursive(root_node, matches, 0, true)
	return matches[0] if not matches.is_empty() else null

## Finds all nodes matching all configured filter criteria.
func find_all() -> Array[Node]:
	var matches: Array[Node] = []
	if _is_node_valid(root_node):
		_search_recursive(root_node, matches, 0, false)
	return matches

## Returns the count of matching nodes.
func count() -> int:
	return find_all().size()

## Returns true if at least one matching node exists.
func exists() -> bool:
	return find() != null

func _search_recursive(current: Node, results: Array[Node], current_depth: int, stop_at_first: bool) -> void:
	if not _is_node_valid(current):
		return

	if _matches_node(current):
		results.append(current)
		if stop_at_first:
			return

	if current_depth >= _max_search_depth:
		return

	for child in current.get_children():
		_search_recursive(child, results, current_depth + 1, stop_at_first)
		if stop_at_first and not results.is_empty():
			return

func _matches_node(node: Node) -> bool:
	if not _is_node_valid(node):
		return false

	# Type Filter
	if _type_filter != null:
		if _type_filter is String or _type_filter is StringName:
			var t_str = str(_type_filter)
			if node.get_class() != t_str and not node.is_class(t_str):
				return false
		elif _type_filter is Script:
			if node.get_script() != _type_filter and not is_instance_of(node, _type_filter):
				return false
		elif not is_instance_of(node, _type_filter):
			return false

	# Name Filter
	if _name_filter != "":
		if _name_exact:
			if String(node.name) != _name_filter:
				return false
		else:
			if not _name_filter.to_lower() in String(node.name).to_lower():
				return false

	# Group Filter
	if _group_filter != &"":
		if not node.is_in_group(_group_filter):
			return false

	# Visibility Filter
	if _require_visible_in_tree:
		if node is CanvasItem:
			if not (node as CanvasItem).is_visible_in_tree():
				return false
		elif node is Node3D:
			if not (node as Node3D).is_visible_in_tree():
				return false

	# Text Filter
	if _text_filter != "":
		var found_text = _extract_node_text(node)
		if found_text == null:
			return false
		if _text_exact:
			if found_text != _text_filter:
				return false
		else:
			if not _text_filter.to_lower() in found_text.to_lower():
				return false

	# Property Filters
	for prop in _property_filters:
		var prop_val = node.get(prop)
		var exp_val = _property_filters[prop]
		if prop_val != exp_val:
			return false

	# Custom Predicates
	for pred in _custom_predicates:
		if not pred.call(node):
			return false

	return true

func _extract_node_text(node: Node) -> Variant:
	if "text" in node and str(node.get("text")) != "":
		return str(node.get("text"))
	elif "placeholder_text" in node and str(node.get("placeholder_text")) != "":
		return str(node.get("placeholder_text"))
	elif "tooltip_text" in node and str(node.get("tooltip_text")) != "":
		return str(node.get("tooltip_text"))
	elif "text" in node:
		return str(node.get("text"))
	elif node.has_method("get_text"):
		return str(node.call("get_text"))
	return null

func _is_node_valid(node: Node) -> bool:
	return node != null and is_instance_valid(node) and not node.is_queued_for_deletion()

# --- Screen Transform & Coordinates Resolution ---

## Resolves the exact screen/viewport coordinate for the given node using Canvas/World transforms.
static func get_screen_position(node: Node) -> Vector2:
	if not node or not is_instance_valid(node):
		return Vector2.ZERO

	if node is Control:
		var ctrl = node as Control
		var canvas_xform = ctrl.get_global_transform_with_canvas()
		var center_offset = ctrl.size * 0.5
		return canvas_xform * center_offset

	elif node is Node2D:
		var n2d = node as Node2D
		return n2d.get_global_transform_with_canvas().origin

	elif node is Node3D:
		var n3d = node as Node3D
		var viewport = n3d.get_viewport()
		if viewport:
			var cam = viewport.get_camera_3d()
			if cam:
				return cam.unproject_position(n3d.global_position)
		return Vector2.ZERO

	return Vector2.ZERO

# --- Auto-Actions (Simulated User Inputs) ---

## Simulates a mouse click on the matched node's screen center.
func click(button: MouseButton = MOUSE_BUTTON_LEFT, offset: Vector2 = Vector2.ZERO, duration_sec: float = 0.05) -> GDTestNodeMatcher:
	var target = find()
	if not target:
		_record_failure("click failed: No matching node found for query")
		return self

	var tree = target.get_tree()
	if not tree:
		_record_failure("click failed: Target node is not inside a SceneTree")
		return self

	var screen_pos = get_screen_position(target) + offset
	if target is BaseButton:
		var btn = target as BaseButton
		btn.button_down.emit()
		btn.button_up.emit()
		btn.pressed.emit()
	await InputSimulator.click(tree, screen_pos, button, duration_sec)
	return self

## Simulates a double click on the matched node.
func double_click(button: MouseButton = MOUSE_BUTTON_LEFT, offset: Vector2 = Vector2.ZERO) -> GDTestNodeMatcher:
	var target = find()
	if not target:
		_record_failure("double_click failed: No matching node found for query")
		return self

	var tree = target.get_tree()
	if not tree:
		_record_failure("double_click failed: Target node is not inside a SceneTree")
		return self

	var screen_pos = get_screen_position(target) + offset
	if target is BaseButton:
		var btn = target as BaseButton
		btn.button_down.emit()
		btn.button_up.emit()
		btn.pressed.emit()
	await InputSimulator.double_click(tree, screen_pos, button)
	return self

## Simulates hovering the mouse over the matched node.
func hover(duration_sec: float = 0.05, offset: Vector2 = Vector2.ZERO) -> GDTestNodeMatcher:
	var target = find()
	if not target:
		_record_failure("hover failed: No matching node found for query")
		return self

	var tree = target.get_tree()
	if not tree:
		_record_failure("hover failed: Target node is not inside a SceneTree")
		return self

	var screen_pos = get_screen_position(target) + offset
	var event = InputEventMouseMotion.new()
	event.position = screen_pos
	event.global_position = screen_pos
	Input.parse_input_event(event)
	if duration_sec > 0.0:
		await tree.create_timer(duration_sec).timeout
	return self

## Types text into the matched input control (focuses and optionally clears existing text first).
func type_text(text: String, clear_first: bool = false, char_delay_sec: float = 0.02) -> GDTestNodeMatcher:
	var target = find()
	if not target:
		_record_failure("type_text failed: No matching node found for query")
		return self

	var tree = target.get_tree()
	if not tree:
		_record_failure("type_text failed: Target node is not inside a SceneTree")
		return self

	if target is Control:
		(target as Control).grab_focus()

	if clear_first:
		if "text" in target:
			target.set("text", "")
			if target.has_signal(&"text_changed"):
				target.emit_signal(&"text_changed", "")

	if target is LineEdit:
		var le = target as LineEdit
		le.text += text
		le.text_changed.emit(le.text)
	elif "text" in target:
		target.set("text", str(target.get("text")) + text)
		if target.has_signal(&"text_changed"):
			target.emit_signal(&"text_changed", target.get("text"))

	await InputSimulator.type_string(tree, text, char_delay_sec)
	return self

## Checks or unchecks a BaseButton / CheckBox / CheckButton.
func check(checked: bool = true) -> GDTestNodeMatcher:
	var target = find()
	if not target:
		_record_failure("check failed: No matching node found for query")
		return self

	if target is BaseButton:
		var btn = target as BaseButton
		if btn.button_pressed != checked:
			btn.button_pressed = checked
			if not btn.toggle_mode:
				btn.toggled.emit(checked)
			btn.pressed.emit()
	else:
		_record_failure("check failed: Matched node '%s' is not a BaseButton" % target.name)

	return self

## Drags from the matched node to the specified destination position or destination Node.
func drag_to(destination: Variant, duration_sec: float = 0.3, steps: int = 10) -> GDTestNodeMatcher:
	var target = find()
	if not target:
		_record_failure("drag_to failed: No matching source node found for query")
		return self

	var tree = target.get_tree()
	if not tree:
		_record_failure("drag_to failed: Source node is not inside a SceneTree")
		return self

	var from_pos = get_screen_position(target)
	var to_pos = Vector2.ZERO
	if destination is Vector2:
		to_pos = destination
	elif destination is Node and is_instance_valid(destination):
		to_pos = get_screen_position(destination)
	else:
		_record_failure("drag_to failed: Invalid destination '%s'" % str(destination))
		return self

	await InputSimulator.drag(tree, from_pos, to_pos, duration_sec, steps)
	return self

# --- Assertions on Node Queries ---

## Asserts that at least one node matches the query.
func assert_exists(message: String = "") -> GDTestNodeMatcher:
	var node = find()
	if node != null:
		_record_pass()
	else:
		var msg = message if message != "" else "Expected node matching query to exist, but none was found"
		_record_failure(msg)
	return self

## Asserts that NO node matches the query.
func assert_not_exists(message: String = "") -> GDTestNodeMatcher:
	var node = find()
	if node == null:
		_record_pass()
	else:
		var msg = message if message != "" else ("Expected no node matching query to exist, but found '%s'" % node.name)
		_record_failure(msg)
	return self

## Asserts that exactly expected_count nodes match the query.
func assert_count(expected_count: int, message: String = "") -> GDTestNodeMatcher:
	var cnt = count()
	if cnt == expected_count:
		_record_pass()
	else:
		var msg = message if message != "" else ("Expected %d matching nodes, but found %d" % [expected_count, cnt])
		_record_failure(msg)
	return self

## Asserts that the matched node is visible in the scene tree.
func assert_visible(message: String = "") -> GDTestNodeMatcher:
	var node = find()
	if not node:
		_record_failure(message if message != "" else "assert_visible failed: Node not found")
		return self

	var is_vis = false
	if node is CanvasItem:
		is_vis = (node as CanvasItem).is_visible_in_tree()
	elif node is Node3D:
		is_vis = (node as Node3D).is_visible_in_tree()
	else:
		is_vis = true

	if is_vis:
		_record_pass()
	else:
		_record_failure(message if message != "" else ("Expected node '%s' to be visible in tree" % node.name))
	return self

## Asserts that the matched node's text matches expected_text.
func assert_text_equals(expected_text: String, message: String = "") -> GDTestNodeMatcher:
	var node = find()
	if not node:
		_record_failure(message if message != "" else "assert_text_equals failed: Node not found")
		return self

	var txt = _extract_node_text(node)
	if txt != null and str(txt) == expected_text:
		_record_pass()
	else:
		var msg = message if message != "" else ("Expected node '%s' text to be '%s', got '%s'" % [node.name, expected_text, str(txt)])
		_record_failure(msg)
	return self

## Asserts that the matched node's text contains expected_substring.
func assert_text_contains(expected_substring: String, message: String = "") -> GDTestNodeMatcher:
	var node = find()
	if not node:
		_record_failure(message if message != "" else "assert_text_contains failed: Node not found")
		return self

	var txt = _extract_node_text(node)
	if txt != null and str(txt).contains(expected_substring):
		_record_pass()
	else:
		var msg = message if message != "" else ("Expected node '%s' text '%s' to contain '%s'" % [node.name, str(txt), expected_substring])
		_record_failure(msg)
	return self

## Asserts that the matched node is disabled (for BaseButton or Control).
func assert_disabled(expected_disabled: bool = true, message: String = "") -> GDTestNodeMatcher:
	var node = find()
	if not node:
		_record_failure(message if message != "" else "assert_disabled failed: Node not found")
		return self

	var is_dis = false
	if "disabled" in node:
		is_dis = bool(node.get("disabled"))

	if is_dis == expected_disabled:
		_record_pass()
	else:
		var msg = message if message != "" else ("Expected node '%s' disabled state to be %s, got %s" % [node.name, str(expected_disabled), str(is_dis)])
		_record_failure(msg)
	return self

# --- Internal Reporting Helpers ---

func _record_pass() -> void:
	if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref.has_method("_record_pass"):
		_suite_ref._record_pass()

func _record_failure(message: String) -> void:
	if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref.has_method("_record_failure"):
		_suite_ref._record_failure(message)
	else:
		push_error("NodeMatcher Failure: %s" % message)
