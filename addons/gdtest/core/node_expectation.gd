# node_expectation.gd
# Fluent node assertion builder for GDTest 3.0.
class_name NodeExpectation
extends RefCounted

var target_node: Node = null
var suite: Node = null
var is_negated: bool = false

func _init(p_node: Variant = null, p_suite: Node = null, p_negated: bool = false) -> void:
	if p_node is Node:
		target_node = p_node
	suite = p_suite
	is_negated = p_negated

## Returns an inverted NodeExpectation builder.
var not_to:
	get:
		return get_script().new(target_node, suite, not is_negated)

## Asserts node exists and is valid.
func to_exist(message: String = "") -> bool:
	var cond = (target_node != null and is_instance_valid(target_node))
	var pass_m = "Expected node NOT to exist"
	var fail_m = message if message != "" else "Expected node to exist, but got null or invalid instance"
	return _evaluate(cond, pass_m, fail_m)

## Asserts node is inside scene tree.
func to_be_inside_tree(message: String = "") -> bool:
	var cond = (target_node != null and is_instance_valid(target_node) and target_node.is_inside_tree())
	var pass_m = "Expected node '%s' NOT to be inside tree" % str(target_node.name if target_node else "null")
	var fail_m = message if message != "" else "Expected node '%s' to be inside tree" % str(target_node.name if target_node else "null")
	return _evaluate(cond, pass_m, fail_m)

## Asserts CanvasItem/Node3D is visible.
func to_be_visible(message: String = "") -> bool:
	var cond = false
	if target_node != null and is_instance_valid(target_node):
		if target_node is CanvasItem:
			cond = target_node.is_visible_in_tree()
		elif target_node is Node3D:
			cond = target_node.is_visible_in_tree()
		elif "visible" in target_node:
			cond = bool(target_node.get("visible"))
	var pass_m = "Expected node '%s' NOT to be visible" % str(target_node.name if target_node else "null")
	var fail_m = message if message != "" else "Expected node '%s' to be visible" % str(target_node.name if target_node else "null")
	return _evaluate(cond, pass_m, fail_m)

## Asserts CanvasItem/Node3D is hidden (not visible).
func to_be_hidden(message: String = "") -> bool:
	var cond = false
	if target_node != null and is_instance_valid(target_node):
		if target_node is CanvasItem:
			cond = not target_node.is_visible_in_tree()
		elif target_node is Node3D:
			cond = not target_node.is_visible_in_tree()
		elif "visible" in target_node:
			cond = not bool(target_node.get("visible"))
	var pass_m = "Expected node '%s' to be visible" % str(target_node.name if target_node else "null")
	var fail_m = message if message != "" else "Expected node '%s' to be hidden" % str(target_node.name if target_node else "null")
	return _evaluate(cond, pass_m, fail_m)

## Asserts node local position matches expected.
func to_have_position(expected_pos: Variant, tolerance: float = 0.001, message: String = "") -> bool:
	var cond = false
	var actual_pos = null
	if target_node != null and is_instance_valid(target_node) and "position" in target_node:
		actual_pos = target_node.get("position")
		if actual_pos is Vector2 and expected_pos is Vector2:
			cond = actual_pos.distance_to(expected_pos) <= tolerance
		elif actual_pos is Vector3 and expected_pos is Vector3:
			cond = actual_pos.distance_to(expected_pos) <= tolerance
			
	var pass_m = "Expected node '%s' position NOT to equal %s" % [str(target_node.name if target_node else "null"), str(expected_pos)]
	var fail_m = message if message != "" else "Expected node '%s' position %s ± %f, got %s" % [
		str(target_node.name if target_node else "null"), str(expected_pos), tolerance, str(actual_pos)
	]
	return _evaluate(cond, pass_m, fail_m)

## Asserts node global position matches expected.
func to_have_global_position(expected_pos: Variant, tolerance: float = 0.001, message: String = "") -> bool:
	var cond = false
	var actual_pos = null
	if target_node != null and is_instance_valid(target_node) and "global_position" in target_node:
		actual_pos = target_node.get("global_position")
		if actual_pos is Vector2 and expected_pos is Vector2:
			cond = actual_pos.distance_to(expected_pos) <= tolerance
		elif actual_pos is Vector3 and expected_pos is Vector3:
			cond = actual_pos.distance_to(expected_pos) <= tolerance
			
	var pass_m = "Expected node '%s' global position NOT to equal %s" % [str(target_node.name if target_node else "null"), str(expected_pos)]
	var fail_m = message if message != "" else "Expected node '%s' global position %s ± %f, got %s" % [
		str(target_node.name if target_node else "null"), str(expected_pos), tolerance, str(actual_pos)
	]
	return _evaluate(cond, pass_m, fail_m)

## Asserts node scale matches expected.
func to_have_scale(expected_scale: Variant, tolerance: float = 0.001, message: String = "") -> bool:
	var cond = false
	var actual_scale = null
	if target_node != null and is_instance_valid(target_node) and "scale" in target_node:
		actual_scale = target_node.get("scale")
		if actual_scale is Vector2 and expected_scale is Vector2:
			cond = actual_scale.distance_to(expected_scale) <= tolerance
		elif actual_scale is Vector3 and expected_scale is Vector3:
			cond = actual_scale.distance_to(expected_scale) <= tolerance
			
	var pass_m = "Expected node '%s' scale NOT to equal %s" % [str(target_node.name if target_node else "null"), str(expected_scale)]
	var fail_m = message if message != "" else "Expected node '%s' scale %s ± %f, got %s" % [
		str(target_node.name if target_node else "null"), str(expected_scale), tolerance, str(actual_scale)
	]
	return _evaluate(cond, pass_m, fail_m)

## Asserts node has child by name.
func to_have_child(child_name: String, message: String = "") -> bool:
	var cond = (target_node != null and is_instance_valid(target_node) and target_node.has_node(child_name))
	var pass_m = "Expected node '%s' NOT to have child '%s'" % [str(target_node.name if target_node else "null"), child_name]
	var fail_m = message if message != "" else "Expected node '%s' to have child '%s'" % [str(target_node.name if target_node else "null"), child_name]
	return _evaluate(cond, pass_m, fail_m)

## Asserts node child count matches expected.
func to_have_child_count(expected_count: int, message: String = "") -> bool:
	var actual_count = target_node.get_child_count() if (target_node != null and is_instance_valid(target_node)) else -1
	var cond = (actual_count == expected_count)
	var pass_m = "Expected node '%s' child count NOT to equal %d" % [str(target_node.name if target_node else "null"), expected_count]
	var fail_m = message if message != "" else "Expected node '%s' child count %d, got %d" % [
		str(target_node.name if target_node else "null"), expected_count, actual_count
	]
	return _evaluate(cond, pass_m, fail_m)

## Asserts node has property, optionally checking value.
func to_have_property(prop_name: StringName, expected_val: Variant = null, message: String = "") -> bool:
	var has_p = (target_node != null and is_instance_valid(target_node) and prop_name in target_node)
	var val_matches = true
	var actual_val = null
	if has_p:
		actual_val = target_node.get(prop_name)
		if expected_val != null:
			val_matches = (actual_val == expected_val)
	var cond = has_p and val_matches
	var pass_m = "Expected node '%s' NOT to have property '%s'" % [str(target_node.name if target_node else "null"), prop_name]
	var fail_m = message if message != "" else "Expected node '%s' property '%s' = %s (got %s)" % [
		str(target_node.name if target_node else "null"), prop_name, str(expected_val), str(actual_val)
	]
	return _evaluate(cond, pass_m, fail_m)

## Asserts node has signal registered.
func to_have_signal(signal_name: StringName, message: String = "") -> bool:
	var cond = (target_node != null and is_instance_valid(target_node) and target_node.has_signal(signal_name))
	var pass_m = "Expected node '%s' NOT to have signal '%s'" % [str(target_node.name if target_node else "null"), signal_name]
	var fail_m = message if message != "" else "Expected node '%s' to have signal '%s'" % [str(target_node.name if target_node else "null"), signal_name]
	return _evaluate(cond, pass_m, fail_m)

## Asserts node is processing.
func to_process(message: String = "") -> bool:
	var cond = (target_node != null and is_instance_valid(target_node) and target_node.is_processing())
	var pass_m = "Expected node '%s' NOT to be processing" % str(target_node.name if target_node else "null")
	var fail_m = message if message != "" else "Expected node '%s' to be processing" % str(target_node.name if target_node else "null")
	return _evaluate(cond, pass_m, fail_m)

## Asserts node is not processing.
func to_not_process(message: String = "") -> bool:
	var cond = (target_node != null and is_instance_valid(target_node) and not target_node.is_processing())
	var pass_m = "Expected node '%s' to be processing" % str(target_node.name if target_node else "null")
	var fail_m = message if message != "" else "Expected node '%s' NOT to be processing" % str(target_node.name if target_node else "null")
	return _evaluate(cond, pass_m, fail_m)

func _evaluate(cond: bool, pass_msg: String, fail_msg: String) -> bool:
	var passed = not cond if is_negated else cond
	var err = pass_msg if is_negated else fail_msg
	
	if suite and is_instance_valid(suite):
		if passed:
			if suite.has_method("_record_pass"):
				suite._record_pass()
		else:
			if suite.has_method("_record_failure"):
				suite._record_failure(err)
	return passed
