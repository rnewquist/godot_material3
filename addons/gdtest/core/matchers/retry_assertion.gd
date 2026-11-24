# retry_assertion.gd
# Auto-retrying async assertion engine for Godot 4.x.
# Polls scene tree conditions deterministically across frames with strict is_instance_valid guards,
# timeout handling, and seamless integration with GDTestSuite.
class_name GDTestRetryAssertion
extends RefCounted

var _target_provider: Variant # Node, Callable, NodePath, GDTestNodeMatcher
var _suite_ref: Object = null
var _tree_provider: SceneTree = null
var _timeout_seconds: float = 2.0
var _poll_interval_frames: int = 1
var _custom_message: String = ""
var _is_negated: bool = false

func _init(target: Variant, suite_ref: Object = null, tree: SceneTree = null, timeout_sec: float = 2.0) -> void:
	_target_provider = target
	_suite_ref = suite_ref
	_tree_provider = tree
	_timeout_seconds = timeout_sec
	_poll_interval_frames = 1
	_custom_message = ""
	_is_negated = false

# --- Configuration Builders ---

## Sets the maximum timeout duration in seconds.
func within(seconds: float) -> GDTestRetryAssertion:
	_timeout_seconds = maxf(0.001, seconds)
	return self

## Sets how many frames to wait between poll checks.
func poll_every(frames: int) -> GDTestRetryAssertion:
	_poll_interval_frames = maxi(1, frames)
	return self

## Sets a custom failure message prefix.
func with_message(msg: String) -> GDTestRetryAssertion:
	_custom_message = msg
	return self

## Inverts the assertion logic.
func not_() -> GDTestRetryAssertion:
	_is_negated = not _is_negated
	return self

# --- Target Resolution & Tree Access ---

func _get_tree() -> SceneTree:
	if _tree_provider and is_instance_valid(_tree_provider):
		return _tree_provider
	if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref is Node:
		var st = (_suite_ref as Node).get_tree()
		if st:
			return st
	if _target_provider is Node and is_instance_valid(_target_provider):
		var st = (_target_provider as Node).get_tree()
		if st:
			return st
	if Engine.get_main_loop() is SceneTree:
		return Engine.get_main_loop() as SceneTree
	return null

func _resolve_target() -> Variant:
	if _target_provider is Callable:
		if (_target_provider as Callable).is_valid():
			return (_target_provider as Callable).call()
		return null
	elif typeof(_target_provider) == TYPE_OBJECT:
		if is_instance_valid(_target_provider):
			if _target_provider is Node and (_target_provider as Node).is_queued_for_deletion():
				return null
			if _target_provider.has_method("find"):
				return _target_provider.call("find")
			return _target_provider
		return null
	elif _target_provider is NodePath or _target_provider is String:
		var p_str = NodePath(str(_target_provider))
		if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref is Node:
			return (_suite_ref as Node).get_node_or_null(p_str)
		var tree = _get_tree()
		if tree and tree.root:
			return tree.root.get_node_or_null(p_str)
		return null
	return _target_provider

# --- Core Async Polling Engine ---

func _poll_condition(condition_evaluator: Callable, positive_desc: String, negative_desc: String) -> bool:
	var tree = _get_tree()
	if not tree:
		_record_failure("retry_assertion failed: No active SceneTree found for polling")
		return false

	var start_time_ms = Time.get_ticks_msec()
	var timeout_ms = int(_timeout_seconds * 1000.0)
	var matched = false

	while true:
		var target = _resolve_target()
		var cond_raw = bool(condition_evaluator.call(target))
		var cond_met = not cond_raw if _is_negated else cond_raw

		if cond_met:
			matched = true
			break

		var elapsed_ms = Time.get_ticks_msec() - start_time_ms
		if elapsed_ms >= timeout_ms:
			break

		# Yield specified frames
		for f in range(_poll_interval_frames):
			await tree.process_frame

	# Final check after loop
	if not matched:
		var target = _resolve_target()
		var cond_raw = bool(condition_evaluator.call(target))
		matched = not cond_raw if _is_negated else cond_raw

	var target_label = "target"
	if is_instance_valid(_target_provider):
		if _target_provider is Node:
			target_label = (_target_provider as Node).name
		else:
			target_label = str(_target_provider)

	if matched:
		_record_pass()
		return true
	else:
		var base_msg = negative_desc if _is_negated else positive_desc
		var formatted = "Timed out after %.2fs waiting for %s: %s" % [_timeout_seconds, target_label, base_msg]
		var final_msg = ("[%s] %s" % [_custom_message, formatted]) if _custom_message != "" else formatted
		_record_failure(final_msg)
		return false

# --- Matcher Methods ---

## Awaits until the target node exists and is inside the SceneTree.
func to_exist() -> bool:
	return await _poll_condition(
		func(target):
			return target != null and is_instance_valid(target) and (target is not Node or (target as Node).is_inside_tree()),
		"to exist and enter the SceneTree",
		"to NOT exist or be removed from tree"
	)

## Awaits until the target node is freed, deleted, or null.
func to_be_freed() -> bool:
	return await _poll_condition(
		func(target):
			if target == null:
				return true
			if not is_instance_valid(target):
				return true
			if target is Node:
				return (target as Node).is_queued_for_deletion() or not (target as Node).is_inside_tree()
			return false,
		"to be freed or removed from tree",
		"to NOT be freed"
	)

## Alias for to_be_freed().
func to_not_exist() -> bool:
	return await to_be_freed()

## Awaits until the target node is visible in the scene tree.
func to_be_visible() -> bool:
	return await _poll_condition(
		func(target):
			if not target or not is_instance_valid(target):
				return false
			if target is CanvasItem:
				return (target as CanvasItem).is_visible_in_tree()
			elif target is Node3D:
				return (target as Node3D).is_visible_in_tree()
			return true,
		"to become visible in scene tree",
		"to become hidden / invisible"
	)

## Awaits until the target node is hidden or invisible in the scene tree.
func to_be_hidden() -> bool:
	return await _poll_condition(
		func(target):
			if not target or not is_instance_valid(target):
				return true
			if target is CanvasItem:
				return not (target as CanvasItem).is_visible_in_tree()
			elif target is Node3D:
				return not (target as Node3D).is_visible_in_tree()
			return false,
		"to become hidden / invisible",
		"to become visible"
	)

## Awaits until the target node's text matches expected_text.
func to_have_text(expected_text: String) -> bool:
	return await _poll_condition(
		func(target):
			if not target or not is_instance_valid(target):
				return false
			var txt = _get_node_text(target)
			return txt != null and str(txt) == expected_text,
		"to have text '%s'" % expected_text,
		"to NOT have text '%s'" % expected_text
	)

## Awaits until the target node's text contains the given substring.
func to_contain_text(substring: String) -> bool:
	return await _poll_condition(
		func(target):
			if not target or not is_instance_valid(target):
				return false
			var txt = _get_node_text(target)
			return txt != null and str(txt).contains(substring),
		"to contain text '%s'" % substring,
		"to NOT contain text '%s'" % substring
	)

## Awaits until the target object's property equals expected_value.
func to_have_property(property_name: StringName, expected_value: Variant, approx: bool = false, tolerance: float = 0.001) -> bool:
	return await _poll_condition(
		func(target):
			if not target or not is_instance_valid(target):
				return false
			var current_val = target.get(property_name)
			if approx and (current_val is float or current_val is Vector2 or current_val is Vector3):
				if current_val is float:
					return abs(float(current_val) - float(expected_value)) <= tolerance
				elif current_val is Vector2:
					return (current_val as Vector2).distance_to(expected_value as Vector2) <= tolerance
				elif current_val is Vector3:
					return (current_val as Vector3).distance_to(expected_value as Vector3) <= tolerance
			return current_val == expected_value,
		"to have property '%s' == %s" % [property_name, str(expected_value)],
		"to NOT have property '%s' == %s" % [property_name, str(expected_value)]
	)

## Awaits until the target satisfies a custom predicate Callable(node: Node) -> bool.
func to_satisfy(predicate: Callable, predicate_name: String = "custom condition") -> bool:
	return await _poll_condition(
		func(target):
			if not target or not is_instance_valid(target):
				return false
			return bool(predicate.call(target)),
		"to satisfy %s" % predicate_name,
		"to NOT satisfy %s" % predicate_name
	)

## Awaits until the target node is added to the specified group.
func to_be_in_group(group_name: StringName) -> bool:
	return await _poll_condition(
		func(target):
			if not target or not is_instance_valid(target) or target is not Node:
				return false
			return (target as Node).is_in_group(group_name),
		"to be in group '%s'" % group_name,
		"to NOT be in group '%s'" % group_name
	)

## Awaits until the target object emits the specified signal.
func to_emit_signal(signal_name: StringName, timeout_sec: float = -1.0) -> bool:
	if timeout_sec > 0.0:
		_timeout_seconds = timeout_sec

	var emitted = [false]
	var target = _resolve_target()
	if not target or not is_instance_valid(target) or target is not Object:
		_record_failure("to_emit_signal failed: Target object is null or invalid")
		return false

	var obj = target as Object
	var on_emitted = func(_a0 = null, _a1 = null, _a2 = null, _a3 = null, _a4 = null):
		emitted[0] = true

	if not obj.has_signal(signal_name):
		_record_failure("to_emit_signal failed: Object %s has no signal '%s'" % [str(obj), signal_name])
		return false

	obj.connect(signal_name, on_emitted, CONNECT_ONE_SHOT)

	var result = await _poll_condition(
		func(_t): return emitted[0],
		"to emit signal '%s'" % signal_name,
		"to NOT emit signal '%s'" % signal_name
	)

	if obj and is_instance_valid(obj) and obj.is_connected(signal_name, on_emitted):
		obj.disconnect(signal_name, on_emitted)

	return result

# --- Helper Methods ---

func _get_node_text(node: Variant) -> Variant:
	if node == null or not is_instance_valid(node):
		return null
	if "text" in node:
		return node.get("text")
	elif "placeholder_text" in node and str(node.get("placeholder_text")) != "":
		return node.get("placeholder_text")
	elif node.has_method("get_text"):
		return node.call("get_text")
	return null

func _record_pass() -> void:
	if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref.has_method("_record_pass"):
		_suite_ref._record_pass()

func _record_failure(message: String) -> void:
	if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref.has_method("_record_failure"):
		_suite_ref._record_failure(message)
	else:
		push_error("RetryAssertion Failure: %s" % message)
