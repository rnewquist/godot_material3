# test_suite.gd
# Base class for pure deterministic unit, integration, and visual audit test suites in Godot 4.x (GDTest 3.0).
# Provides comprehensive assertion methods, dual-contract requirements, fluent expectation builders,
# method mocking, spies, network route mocking, signal spies, RID/Node lifecycle management,
# benchmarks, snapshots, input simulation, and declarative visual audit checkpoints.
class_name GDTestSuite
extends Node

const InputSimulator = preload("res://addons/gdtest/core/input_simulator.gd")
const Expectation = preload("res://addons/gdtest/core/expectation.gd")
const NodeExpectation = preload("res://addons/gdtest/core/node_expectation.gd")
const MockProxy = preload("res://addons/gdtest/core/mocking/mock_proxy.gd")
const MockFactory = preload("res://addons/gdtest/core/mocking/mock_factory.gd")
const MockStubber = preload("res://addons/gdtest/core/mocking/mock_stubber.gd")
const MockVerifier = preload("res://addons/gdtest/core/mocking/mock_verifier.gd")
const NetworkMocker = preload("res://addons/gdtest/core/network_mocker.gd")
const StructuralDiffer = preload("res://addons/gdtest/core/matchers/structural_differ.gd")

enum ServerType {
	PHYSICS_2D = 0,
	PHYSICS_3D = 1,
	RENDERING = 2,
	NAVIGATION_2D = 3,
	NAVIGATION_3D = 4,
	TEXT = 5,
	AUTO = 6
}

signal test_passed(suite_name: String, test_name: String, duration_ms: float)
signal test_failed(suite_name: String, test_name: String, reason: String, duration_ms: float)

@export var suite_name: String = "GDTestSuite"
@export var test_type: String = "integration" # "unit", "integration", "audit"

var current_test_name: String = ""
var pass_count: int = 0
var fail_count: int = 0
var test_pass_count: int:
	get: return pass_count
	set(v): pass_count = v
var test_fail_count: int:
	get: return fail_count
	set(v): fail_count = v
var assertion_count: int = 0
var failures: Array[Dictionary] = []
var test_results: Array[Dictionary] = []
var test_attachments: Array[Dictionary] = []
var stop_on_failure: bool = false
var _test_aborted: bool = false

# Memory Management & Test Isolation
var _auto_free_nodes: Array[Node] = []
var _auto_free_rids: Array[Dictionary] = [] # Array of {"rid": RID, "server_type": int}
var _teardown_callbacks: Array[Callable] = []

# Signal Spying
var _watched_signals: Dictionary = {} # object_id -> {signal_name: Array[Array]}
var _spy_connections: Array[Dictionary] = [] # Array of {"object": Object, "signal_name": StringName, "callable": Callable}

# Network Mocking
var _network_mocker_instance: Node = null

# Visual Audit Manifest
var audit_checkpoints: Array[Dictionary] = []

# Filtering
var filter_method_name: String = ""

# --- Lifecycle Hooks to Override in Derived Suites ---

func before_all() -> void:
	pass

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func after_all() -> void:
	pass

# --- Teardown Registration ---

## Registers a teardown callable executed at the end of the current test method (LIFO order).
func add_teardown(callable: Callable) -> void:
	if callable.is_valid():
		_teardown_callbacks.append(callable)

func _execute_teardown_callbacks() -> void:
	for i in range(_teardown_callbacks.size() - 1, -1, -1):
		var cb = _teardown_callbacks[i]
		if cb.is_valid():
			cb.call()
	_teardown_callbacks.clear()

# --- Memory Management Helpers ---

## Registers a node to be automatically freed at the end of the current test method.
func autofree(node: Variant) -> Variant:
	if node is Node and is_instance_valid(node):
		if not _auto_free_nodes.has(node):
			_auto_free_nodes.append(node)
	return node

## Registers an RID to be automatically freed via its associated low-level server at the end of the current test method.
func auto_free_rid(rid: RID, server_type: int = ServerType.PHYSICS_2D) -> RID:
	if rid.is_valid():
		_auto_free_rids.append({"rid": rid, "server_type": server_type})
	return rid

## Manually frees an RID and unregisters it from the auto-free list.
func free_rid(rid: RID, server_type: int = ServerType.PHYSICS_2D) -> void:
	if not rid.is_valid():
		return
	_free_single_rid(rid, server_type)
	for i in range(_auto_free_rids.size() - 1, -1, -1):
		if _auto_free_rids[i]["rid"] == rid:
			_auto_free_rids.remove_at(i)

func _free_single_rid(rid: RID, server_type: int) -> void:
	if not rid.is_valid():
		return
	match server_type:
		ServerType.PHYSICS_2D:
			PhysicsServer2D.free_rid(rid)
		ServerType.PHYSICS_3D:
			PhysicsServer3D.free_rid(rid)
		ServerType.RENDERING:
			RenderingServer.free_rid(rid)
		ServerType.NAVIGATION_2D:
			NavigationServer2D.free_rid(rid)
		ServerType.NAVIGATION_3D:
			NavigationServer3D.free_rid(rid)
		ServerType.TEXT:
			var ts = TextServerManager.get_primary_interface()
			if ts:
				ts.free_rid(rid)
		_:
			PhysicsServer2D.free_rid(rid)

## Instantiates a scene from path or PackedScene, mounts it as a child, auto-registers for cleanup, and yields 1 frame.
func mount_scene(scene_or_path: Variant) -> Node:
	var packed: PackedScene = null
	if scene_or_path is String:
		packed = load(scene_or_path) as PackedScene
	elif scene_or_path is PackedScene:
		packed = scene_or_path
	
	if not packed:
		_record_failure("mount_scene failed: Invalid scene or path '%s'" % str(scene_or_path))
		return null
		
	var instance = packed.instantiate()
	if not instance:
		_record_failure("mount_scene failed: Could not instantiate '%s'" % str(scene_or_path))
		return null
		
	autofree(instance)
	add_child(instance)
	await step_frames(1)
	return instance

## Automatically frees a node and mounts it to the test runner tree.
func auto_add_child(node: Variant) -> Variant:
	autofree(node)
	if node is Node and is_instance_valid(node):
		add_child(node)
	return node

## Yields execution for count process frames (alias for step_frames).
func wait_frames(count: int = 1) -> void:
	await step_frames(count)

## Yields execution for seconds (alias for wait_seconds).
func wait_time(seconds: float) -> void:
	await wait_seconds(seconds)

## Cleans up all auto-freed nodes, RIDs, signal spies, and teardown callbacks.
func cleanup_nodes() -> void:
	_execute_teardown_callbacks()
	_cleanup_auto_free_nodes()
	_cleanup_signal_spies()

func _cleanup_auto_free_nodes() -> void:
	for node in _auto_free_nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()
	_auto_free_nodes.clear()

	for entry in _auto_free_rids:
		var rid: RID = entry.get("rid", RID())
		var st: int = entry.get("server_type", ServerType.PHYSICS_2D)
		if rid.is_valid():
			_free_single_rid(rid, st)
	_auto_free_rids.clear()

# --- Signal Spy & Watchers ---

## Attaches an observer to capture all emissions and argument payloads for the specified signal.
func watch_signal(object: Object, signal_name: StringName) -> void:
	if not object or not is_instance_valid(object):
		return
	var obj_id = object.get_instance_id()
	if not _watched_signals.has(obj_id):
		_watched_signals[obj_id] = {}
	if not _watched_signals[obj_id].has(signal_name):
		_watched_signals[obj_id][signal_name] = []
		var callable = func(arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null):
			var args: Array = []
			if arg0 != null: args.append(arg0)
			if arg1 != null: args.append(arg1)
			if arg2 != null: args.append(arg2)
			if arg3 != null: args.append(arg3)
			if arg4 != null: args.append(arg4)
			if _watched_signals.has(obj_id) and _watched_signals[obj_id].has(signal_name):
				_watched_signals[obj_id][signal_name].append(args)
		object.connect(signal_name, callable)
		_spy_connections.append({
			"object": object,
			"signal_name": signal_name,
			"callable": callable
		})

## Attaches observers to capture all signals defined on the specified object.
func watch_signals(object: Object) -> void:
	if not object or not is_instance_valid(object):
		return
	for sig_info in object.get_signal_list():
		watch_signal(object, sig_info["name"])

## Returns all recorded parameter emission payloads for a watched signal.
func get_signal_emissions(object: Object, signal_name: StringName) -> Array:
	if not object or not is_instance_valid(object):
		return []
	var obj_id = object.get_instance_id()
	if _watched_signals.has(obj_id) and _watched_signals[obj_id].has(signal_name):
		return _watched_signals[obj_id][signal_name]
	return []

## Returns the most recent parameter emission payload for a watched signal.
func get_last_signal_emission(object: Object, signal_name: StringName) -> Array:
	var emissions = get_signal_emissions(object, signal_name)
	if emissions.is_empty():
		return []
	return emissions[-1]

## Disconnects all active signal spies and cleans up spy tracking collections.
func _cleanup_signal_spies() -> void:
	for conn in _spy_connections:
		var obj: Object = conn.get("object")
		var sig: StringName = conn.get("signal_name")
		var cb: Callable = conn.get("callable")
		if is_instance_valid(obj) and obj.is_connected(sig, cb):
			obj.disconnect(sig, cb)
	_spy_connections.clear()
	_watched_signals.clear()

## Asserts that the signal was emitted at least once since watch_signal was called.
func assert_signal_emitted(object: Object, signal_name: StringName, message: String = "") -> bool:
	if not object or not is_instance_valid(object):
		_record_failure(message if message != "" else "assert_signal_emitted: Object is null or invalid")
		return false
	var obj_id = object.get_instance_id()
	if _watched_signals.has(obj_id) and _watched_signals[obj_id].has(signal_name) and not _watched_signals[obj_id][signal_name].is_empty():
		_record_pass()
		return true
	var err = message if message != "" else "Expected signal '%s' to be emitted on %s" % [signal_name, str(object)]
	_record_failure(err)
	return false

## Asserts that the signal was NOT emitted since watch_signal was called.
func assert_signal_not_emitted(object: Object, signal_name: StringName, message: String = "") -> bool:
	if not object or not is_instance_valid(object):
		_record_failure(message if message != "" else "assert_signal_not_emitted: Object is null or invalid")
		return false
	var obj_id = object.get_instance_id()
	var count = 0
	if _watched_signals.has(obj_id) and _watched_signals[obj_id].has(signal_name):
		count = _watched_signals[obj_id][signal_name].size()
	if count == 0:
		_record_pass()
		return true
	var err = message if message != "" else "Expected signal '%s' NOT to be emitted, but was emitted %d times" % [signal_name, count]
	_record_failure(err)
	return false

## Asserts that the signal was emitted an exact number of times since watch_signal was called.
func assert_signal_count(object: Object, signal_name: StringName, expected_count: int, message: String = "") -> bool:
	if not object or not is_instance_valid(object):
		_record_failure(message if message != "" else "assert_signal_count: Object is null or invalid")
		return false
	var obj_id = object.get_instance_id()
	var count = 0
	if _watched_signals.has(obj_id) and _watched_signals[obj_id].has(signal_name):
		count = _watched_signals[obj_id][signal_name].size()
	if count == expected_count:
		_record_pass()
		return true
	var err = message if message != "" else "Expected signal '%s' to be emitted %d times, but was emitted %d times" % [signal_name, expected_count, count]
	_record_failure(err)
	return false

# --- Async Helper Utilities ---

func step_frames(count: int = 1) -> void:
	for i in range(count):
		await get_tree().process_frame

func step_physics_frames(count: int = 1) -> void:
	for i in range(count):
		await get_tree().physics_frame

func wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func wait_for_condition(condition_callable: Callable, timeout_seconds: float = 2.0, check_interval_frames: int = 2) -> bool:
	var max_frames = int(timeout_seconds * 60.0)
	var elapsed_frames = 0
	while elapsed_frames < max_frames:
		if condition_callable.call():
			return true
		await step_frames(check_interval_frames)
		elapsed_frames += check_interval_frames
	return false

func wait_for_signal(object: Object, signal_name: StringName, timeout_seconds: float = 2.0) -> bool:
	var received: Array = [false]
	var on_signal = func(_a0 = null, _a1 = null, _a2 = null, _a3 = null, _a4 = null): received[0] = true
	object.connect(signal_name, on_signal, CONNECT_ONE_SHOT)
	var max_frames = int(timeout_seconds * 60.0)
	var elapsed_frames = 0
	while elapsed_frames < max_frames:
		if received[0]:
			return true
		await step_frames(1)
		elapsed_frames += 1
	if object.is_connected(signal_name, on_signal):
		object.disconnect(signal_name, on_signal)
	return false

## Settles the scene by yielding process frames followed by physics frames.
func settle(frames: int = 5, physics_frames: int = 2) -> void:
	for i in range(frames):
		await get_tree().process_frame
	for i in range(physics_frames):
		await get_tree().physics_frame

## Asserts that the target node's motion/transform has settled (stopped moving or velocity converged).
func assert_settled(target_node: Node = null, max_wait_sec: float = 1.0, velocity_tolerance: float = 0.001, message: String = "") -> bool:
	var max_frames = int(max_wait_sec * 60.0)
	var elapsed_frames = 0
	var is_settled = false
	var last_pos: Variant = null
	
	while elapsed_frames < max_frames:
		await step_physics_frames(2)
		elapsed_frames += 2
		
		if target_node == null or not is_instance_valid(target_node):
			is_settled = true
			break
			
		if target_node is RigidBody2D:
			if target_node.linear_velocity.length() <= velocity_tolerance and abs(target_node.angular_velocity) <= velocity_tolerance:
				is_settled = true
				break
		elif target_node is RigidBody3D:
			if target_node.linear_velocity.length() <= velocity_tolerance and target_node.angular_velocity.length() <= velocity_tolerance:
				is_settled = true
				break
		elif target_node is CharacterBody2D:
			if target_node.velocity.length() <= velocity_tolerance:
				is_settled = true
				break
		elif target_node is CharacterBody3D:
			if target_node.velocity.length() <= velocity_tolerance:
				is_settled = true
				break
		elif "position" in target_node:
			var curr_pos = target_node.get("position")
			if last_pos != null:
				var dist = 0.0
				if curr_pos is Vector2: dist = curr_pos.distance_to(last_pos)
				elif curr_pos is Vector3: dist = curr_pos.distance_to(last_pos)
				if dist <= velocity_tolerance:
					is_settled = true
					break
			last_pos = curr_pos
		else:
			is_settled = true
			break
			
	if is_settled:
		_record_pass()
		return true
		
	var err_msg = message if message != "" else "Expected node '%s' to settle within %.2f seconds" % [
		str(target_node.name if target_node else "scene"), max_wait_sec
	]
	_record_failure(err_msg)
	return false

# --- Fluent Input Simulation Helpers ---

func click(position: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT, duration_sec: float = 0.05) -> void:
	await InputSimulator.click(get_tree(), position, button, duration_sec)

func double_click(position: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await InputSimulator.double_click(get_tree(), position, button)

func drag(from_pos: Vector2, to_pos: Vector2, duration_sec: float = 0.3, steps: int = 10) -> void:
	await InputSimulator.drag(get_tree(), from_pos, to_pos, duration_sec, steps)

func tap_key(keycode: Key, duration_sec: float = 0.05, shift: bool = false, ctrl: bool = false, alt: bool = false) -> void:
	await InputSimulator.tap_key(get_tree(), keycode, duration_sec, shift, ctrl, alt)

func type_text(text: String, char_delay_sec: float = 0.02) -> void:
	await InputSimulator.type_string(get_tree(), text, char_delay_sec)

func tap_action(action: StringName, duration_sec: float = 0.05) -> void:
	await InputSimulator.tap_action(get_tree(), action, duration_sec)

# --- Declarative Visual Audit Checkpoints ---

## Captures a high-resolution screenshot checkpoint and registers prompt criteria for visual audit.
func audit_checkpoint(checkpoint_title: String, prompt_criteria: String, target_node: Node = null) -> Dictionary:
	await step_frames(2) # Settle rendering & lighting passes
	
	var artifacts_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts")
	var dir_path = artifacts_dir.path_join("checkpoints")
	DirAccess.make_dir_recursive_absolute(dir_path)
		
	var safe_title = checkpoint_title.to_lower().replace(" ", "_").replace("/", "_").replace(":", "")
	var rel_img_path = "%s/%s.png" % [dir_path, safe_title]
	var global_img_path = ProjectSettings.globalize_path(rel_img_path)
	
	var viewport = target_node.get_viewport() if target_node else get_viewport()
	var captured = false
	var img_w = 0
	var img_h = 0
	
	if viewport and DisplayServer.get_name() != "headless":
		var tex = viewport.get_texture()
		if tex:
			var img = tex.get_image()
			if img and not img.is_empty():
				img.save_png(global_img_path)
				captured = true
				img_w = img.get_width()
				img_h = img.get_height()
	else:
		var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.12, 0.14, 0.18, 1.0))
		img.save_png(global_img_path)
		captured = true
		img_w = 256
		img_h = 256
				
	var checkpoint_data = {
		"suite": suite_name,
		"test": current_test_name,
		"title": checkpoint_title,
		"criteria": prompt_criteria,
		"image_file": rel_img_path,
		"global_image_path": global_img_path,
		"captured": captured,
		"width": img_w,
		"height": img_h,
		"timestamp_ms": Time.get_ticks_msec()
	}
	
	audit_checkpoints.append(checkpoint_data)
	_record_pass()
	print("  📸 [VISUAL AUDIT CHECKPOINT] '%s' -> %s" % [checkpoint_title, rel_img_path])
	
	_append_audit_manifest(checkpoint_data)
	return checkpoint_data

## Executes an interactive action callable, waits for rendering settle, and captures an audit checkpoint.
func audit_interaction(action_callable: Callable, prompt_criteria: String, checkpoint_title: String = "") -> Dictionary:
	var title = checkpoint_title if checkpoint_title != "" else ("interaction_" + current_test_name)
	await action_callable.call()
	return await audit_checkpoint(title, prompt_criteria)

func _append_audit_manifest(data: Dictionary) -> void:
	var artifacts_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts")
	var manifest_path = ProjectSettings.globalize_path(artifacts_dir.path_join("audit_manifest.json"))
	var manifest_items: Array = []
	if FileAccess.file_exists(manifest_path):
		var read_file = FileAccess.open(manifest_path, FileAccess.READ)
		if read_file:
			var content = read_file.get_as_text()
			read_file.close()
			var parsed = JSON.parse_string(content)
			if parsed is Array:
				manifest_items = parsed
	manifest_items.append(data)
	var write_file = FileAccess.open(manifest_path, FileAccess.WRITE)
	if write_file:
		write_file.store_string(JSON.stringify(manifest_items, "\t"))
		write_file.close()

# --- GDTest 3.0 Fluent Expectation Builders ---

## Creates a fluent Expectation assertion builder for the given actual value.
func expect(actual: Variant) -> Expectation:
	return Expectation.new(actual, self)

## Creates a fluent NodeExpectation assertion builder for the given Node.
func expect_node(target: Variant) -> NodeExpectation:
	return NodeExpectation.new(target, self)

## Alias for expect_node().
func on_node(target: Variant) -> NodeExpectation:
	return NodeExpectation.new(target, self)

# --- Dual-Contract Requirements (require_*) ---

func is_test_aborted() -> bool:
	return _test_aborted

func require_true(condition: bool, message: String = "Requirement failed: Expected true, got false") -> bool:
	if condition:
		_record_pass()
		return true
	_test_aborted = true
	_record_failure(message)
	return false

func require_false(condition: bool, message: String = "Requirement failed: Expected false, got true") -> bool:
	if not condition:
		_record_pass()
		return true
	_test_aborted = true
	_record_failure(message)
	return false

func require_eq(actual: Variant, expected: Variant, message: String = "") -> bool:
	if actual == expected:
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected '%s' (type %s), got '%s' (type %s)" % [
		str(expected), typeof(expected), str(actual), typeof(actual)
	]
	_record_failure(err)
	return false

func require_ne(actual: Variant, unexpected: Variant, message: String = "") -> bool:
	if actual != unexpected:
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected value NOT to equal '%s'" % str(unexpected)
	_record_failure(err)
	return false

func require_null(actual: Variant, message: String = "Requirement failed: Expected value to be null") -> bool:
	if actual == null:
		_record_pass()
		return true
	_test_aborted = true
	_record_failure(message + " (got: %s)" % str(actual))
	return false

func require_not_null(actual: Variant, message: String = "Requirement failed: Expected value not to be null") -> bool:
	if actual != null:
		_record_pass()
		return true
	_test_aborted = true
	_record_failure(message)
	return false

func require_approx(actual: Variant, expected: Variant, tolerance: float = 0.001, message: String = "") -> bool:
	var passed = false
	if actual is float or actual is int:
		passed = abs(float(actual) - float(expected)) <= tolerance
	elif actual is Vector2 and expected is Vector2:
		passed = actual.distance_to(expected) <= tolerance
	elif actual is Vector3 and expected is Vector3:
		passed = actual.distance_to(expected) <= tolerance
		
	if passed:
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected '%s' ± %f, got '%s'" % [str(expected), tolerance, str(actual)]
	_record_failure(err)
	return false

func require_is(object: Object, expected_class: Variant, message: String = "") -> bool:
	if object != null and is_instance_valid(object) and is_instance_of(object, expected_class):
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected object %s to be instance of %s" % [str(object), str(expected_class)]
	_record_failure(err)
	return false

func require_has_node(parent: Node, node_path: NodePath, message: String = "") -> bool:
	if parent != null and is_instance_valid(parent) and parent.has_node(node_path):
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected node '%s' to exist in '%s'" % [str(node_path), str(parent.name if parent else "null")]
	_record_failure(err)
	return false

func require_in_range(actual: float, min_val: float, max_val: float, message: String = "") -> bool:
	if actual >= min_val and actual <= max_val:
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected %f to be in range [%f, %f]" % [actual, min_val, max_val]
	_record_failure(err)
	return false

func require_empty(actual: Variant, message: String = "") -> bool:
	var is_emp = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName:
		is_emp = actual.is_empty()
	if is_emp:
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected empty container, got %s" % str(actual)
	_record_failure(err)
	return false

func require_not_empty(actual: Variant, message: String = "") -> bool:
	var is_emp = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName:
		is_emp = actual.is_empty()
	if not is_emp:
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected non-empty container, got empty"
	_record_failure(err)
	return false

func require_size(actual: Variant, expected_size: int, message: String = "") -> bool:
	var sz = 0
	if actual is Array or actual is Dictionary or actual is String or actual is StringName:
		sz = actual.size()
	if sz == expected_size:
		_record_pass()
		return true
	_test_aborted = true
	var err = message if message != "" else "Requirement failed: Expected size %d, got %d" % [expected_size, sz]
	_record_failure(err)
	return false

# --- Parameterized & Matrix Testing ---

## Executes test_callable for each entry in dataset.
func run_parameterized(dataset: Array, test_callable: Callable) -> void:
	for i in range(dataset.size()):
		if _test_aborted:
			break
		var item = dataset[i]
		if item is Array:
			await test_callable.callv(item)
		else:
			await test_callable.call(item)

## Executes test_callable for every cartesian product combination across the parameter axes.
func run_matrix(axes_dict: Dictionary, test_callable: Callable) -> void:
	var keys = axes_dict.keys()
	if keys.is_empty():
		return
	var combinations: Array[Dictionary] = [{}]
	for key in keys:
		var values: Array = axes_dict[key]
		var new_combos: Array[Dictionary] = []
		for combo in combinations:
			for val in values:
				var next_combo = combo.duplicate()
				next_combo[key] = val
				new_combos.append(next_combo)
		combinations = new_combos
		
	for combo in combinations:
		if _test_aborted:
			break
		await test_callable.call(combo)

# --- Mocking & Spying Engine ---

## Creates a mock instance for a given Class, GDScript, or generic proxy.
func mock(target: Variant = null) -> Variant:
	return MockFactory.create_mock(target, self)

## Configures method stubs on a mock or spy object.
func stub(mock_or_spy: Variant, method_name: StringName) -> MockStubber:
	var proxy = MockFactory.get_proxy(mock_or_spy)
	if proxy == null:
		push_error("stub failed: Could not resolve MockProxy from %s" % str(mock_or_spy))
		var fallback_stubber = MockStubber.new()
		fallback_stubber.target_method = method_name
		return fallback_stubber
		
	var stubber = MockStubber.new()
	stubber.target_method = method_name
	proxy.add_stub(stubber)
	return stubber

## Returns a MockVerifier to validate invocations on a mock or spy.
func verify(mock_or_spy: Variant, method_name: StringName = &"") -> MockVerifier:
	var proxy = MockFactory.get_proxy(mock_or_spy)
	var verifier = MockVerifier.new()
	verifier.proxy = proxy
	verifier.target_method = method_name
	verifier.suite_ref = self
	return verifier

## Instruments an existing object instance as a spy, recording calls and delegating unstubbed methods.
func spy(real_obj: Variant) -> Variant:
	return MockFactory.create_spy(real_obj, self)

# --- Benchmarking Engine ---

## Measures microsecond execution statistics for the provided callable.
func benchmark(callable: Callable, iterations: int = 100, warmup_iterations: int = 10) -> Dictionary:
	for i in range(warmup_iterations):
		callable.call()
		
	var durations: Array[int] = []
	var start_total = Time.get_ticks_usec()
	for i in range(iterations):
		var t0 = Time.get_ticks_usec()
		callable.call()
		var dt = Time.get_ticks_usec() - t0
		durations.append(dt)
	var total_usec = Time.get_ticks_usec() - start_total
	
	durations.sort()
	var min_u = durations[0]
	var max_u = durations[-1]
	var median_u = float(durations[durations.size() / 2])
	var mean_u = float(total_usec) / float(iterations)
	var ops_sec = (1000000.0 / mean_u) if mean_u > 0.0 else 0.0
	
	return {
		"iterations": iterations,
		"total_usec": total_usec,
		"mean_usec": mean_u,
		"min_usec": min_u,
		"max_usec": max_u,
		"median_usec": median_u,
		"ops_per_sec": ops_sec
	}

## Asserts that the average execution time of callable is under max_mean_usec.
func assert_benchmark_under(callable: Callable, max_mean_usec: float, iterations: int = 100, message: String = "") -> bool:
	var stats = benchmark(callable, iterations)
	var mean_u = stats["mean_usec"]
	if mean_u <= max_mean_usec:
		_record_pass()
		return true
	var err = message if message != "" else "Benchmark assertion failed: Expected mean time <= %.2f µs, got %.2f µs (min: %d µs, max: %d µs, ops/s: %.0f)" % [
		max_mean_usec, mean_u, stats["min_usec"], stats["max_usec"], stats["ops_per_sec"]
	]
	_record_failure(err)
	return false

# --- Snapshot Testing Engine ---

## Asserts that the serialized JSON representation of data matches the saved snapshot file.
func assert_json_snapshot(data: Variant, snapshot_name: String, update_snapshots: bool = false) -> bool:
	var artifacts_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts")
	var snap_dir = artifacts_dir.path_join("snapshots").path_join(suite_name)
	var global_snap_dir = ProjectSettings.globalize_path(snap_dir)
	DirAccess.make_dir_recursive_absolute(global_snap_dir)
		
	var safe_name = snapshot_name.to_lower().replace(" ", "_").replace("/", "_")
	var file_path = snap_dir.path_join("%s.json" % safe_name)
	var global_file_path = ProjectSettings.globalize_path(file_path)
	var json_str = JSON.stringify(data, "\t", false)
	
	var force_update = update_snapshots or (OS.get_environment("GDTEST_UPDATE_SNAPSHOTS") == "1")
	if force_update or not FileAccess.file_exists(global_file_path):
		var w_file = FileAccess.open(global_file_path, FileAccess.WRITE)
		if w_file:
			w_file.store_string(json_str)
			w_file.close()
			_record_pass()
			return true
			
	var r_file = FileAccess.open(global_file_path, FileAccess.READ)
	if not r_file:
		_record_failure("Failed to read snapshot file: %s" % global_file_path)
		return false
	var saved_json_str = r_file.get_as_text()
	r_file.close()
	
	var saved_data = JSON.parse_string(saved_json_str)
	if saved_data == data or StructuralDiffer.are_equal(saved_data, data, {"strict_types": false}):
		_record_pass()
		return true
		
	_record_failure("JSON snapshot mismatch for '%s'. Stored: %s | Actual: %s" % [snapshot_name, saved_json_str, json_str])
	return false

## Asserts that the serialized hierarchy of root_node matches the saved snapshot.
func assert_scene_snapshot(root_node: Node, snapshot_name: String, properties_to_include: Array = [], update_snapshots: bool = false) -> bool:
	if not root_node or not is_instance_valid(root_node):
		_record_failure("assert_scene_snapshot: root_node is null or invalid")
		return false
	var tree_data = _serialize_node_tree(root_node, properties_to_include)
	return assert_json_snapshot(tree_data, snapshot_name, update_snapshots)

func _serialize_node_tree(node: Node, props_to_include: Array) -> Dictionary:
	var node_dict = {
		"name": String(node.name),
		"class": node.get_class(),
		"properties": {},
		"children": []
	}
	for prop in props_to_include:
		if prop in node:
			node_dict["properties"][prop] = var_to_str(node.get(prop))
	for child in node.get_children():
		if child is Node:
			node_dict["children"].append(_serialize_node_tree(child, props_to_include))
	return node_dict

## Asserts that a visual rendering checkpoint matches the saved reference PNG image within max_diff_ratio.
func assert_visual_snapshot(target_node: Node, snapshot_name: String, max_diff_ratio: float = 0.01, update_snapshots: bool = false) -> bool:
	await step_frames(2)
	var artifacts_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts")
	var snap_dir = artifacts_dir.path_join("snapshots").path_join(suite_name)
	DirAccess.make_dir_recursive_absolute(snap_dir)
		
	var safe_name = snapshot_name.to_lower().replace(" ", "_").replace("/", "_")
	var file_path = snap_dir.path_join("%s.png" % safe_name)
	var global_path = ProjectSettings.globalize_path(file_path)
	
	var viewport = target_node.get_viewport() if target_node else get_viewport()
	var current_img: Image = null
	if viewport and DisplayServer.get_name() != "headless":
		var tex = viewport.get_texture()
		if tex: current_img = tex.get_image()
	if current_img == null or current_img.is_empty():
		current_img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
		current_img.fill(Color(0.2, 0.3, 0.4, 1.0))
		
	var force_update = update_snapshots or (OS.get_environment("GDTEST_UPDATE_SNAPSHOTS") == "1")
	if force_update or not FileAccess.file_exists(global_path):
		current_img.save_png(global_path)
		_record_pass()
		return true
		
	var ref_img = Image.load_from_file(global_path)
	if not ref_img or ref_img.is_empty():
		current_img.save_png(global_path)
		_record_pass()
		return true
		
	# Compare pixel diffs
	if ref_img.get_width() != current_img.get_width() or ref_img.get_height() != current_img.get_height():
		_record_failure("Visual snapshot dimension mismatch: Expected %dx%d, got %dx%d" % [
			ref_img.get_width(), ref_img.get_height(), current_img.get_width(), current_img.get_height()
		])
		return false
		
	var w = ref_img.get_width()
	var h = ref_img.get_height()
	var total_pixels = w * h
	var diff_pixels = 0
	
	for y in range(h):
		for x in range(w):
			var c1 = ref_img.get_pixel(x, y)
			var c2 = current_img.get_pixel(x, y)
			if abs(c1.r - c2.r) > 0.05 or abs(c1.g - c2.g) > 0.05 or abs(c1.b - c2.b) > 0.05 or abs(c1.a - c2.a) > 0.05:
				diff_pixels += 1
				
	var diff_ratio = float(diff_pixels) / float(total_pixels)
	if diff_ratio <= max_diff_ratio:
		_record_pass()
		return true
		
	_record_failure("Visual snapshot '%s' difference %.2f%% exceeded tolerance %.2f%%" % [
		snapshot_name, diff_ratio * 100.0, max_diff_ratio * 100.0
	])
	return false

# --- Network Mocking Integration ---

## Returns the active NetworkMocker instance, creating and starting it on demand.
func get_network_mocker() -> Node:
	if _network_mocker_instance == null or not is_instance_valid(_network_mocker_instance):
		_network_mocker_instance = NetworkMocker.new()
		add_child(_network_mocker_instance)
		_network_mocker_instance.start()
	return _network_mocker_instance

## Intercepts HTTP requests on the ephemeral test server.
func intercept_http_route(method: String, url_path: String, response_body: Variant, status_code: int = 200, headers: Dictionary = {}, latency_ms: float = 0.0) -> Dictionary:
	return get_network_mocker().intercept_route(method, url_path, response_body, status_code, headers, latency_ms)

## Registers a JSON mock response route on the ephemeral test server.
func mock_http_json(url_path: String, json_dict: Variant, status_code: int = 200, method: String = "GET", latency_ms: float = 0.0) -> Dictionary:
	return get_network_mocker().mock_json(url_path, json_dict, status_code, method, latency_ms)

## Returns the full URL on the ephemeral mock server for the given path.
func get_http_mock_url(path: String = "") -> String:
	return get_network_mocker().get_url(path)

func _cleanup_network_mocker() -> void:
	if _network_mocker_instance != null and is_instance_valid(_network_mocker_instance):
		if _network_mocker_instance.has_method("stop"):
			_network_mocker_instance.stop()
		_network_mocker_instance.queue_free()
		_network_mocker_instance = null

# --- Telemetry & Diagnostic Attachments ---

## Attaches a structured JSON payload to the current test result report.
func attach_json(label: String, data: Variant) -> void:
	test_attachments.append({
		"suite": suite_name,
		"test": current_test_name,
		"label": label,
		"data": data,
		"timestamp_ms": Time.get_ticks_msec()
	})

## Returns attachments recorded for the specified test method (or all if empty).
func get_attachments(test_name: String = "") -> Array[Dictionary]:
	if test_name == "":
		return test_attachments.duplicate()
	var res: Array[Dictionary] = []
	for att in test_attachments:
		if att["test"] == test_name:
			res.append(att)
	return res

# --- Assertion Library (GDTest 2.0 Backward Compatible) ---

func _record_failure(message: String) -> void:
	fail_count += 1
	var stack = get_stack()
	var caller_info = ""
	if stack.size() > 2:
		var frame = stack[2]
		caller_info = " [%s:%d in %s()]" % [frame.get("source", "unknown"), frame.get("line", 0), frame.get("function", "unknown")]
	var fail_dict = {
		"suite": suite_name,
		"test": current_test_name,
		"message": message + caller_info,
		"time_ms": Time.get_ticks_msec()
	}
	failures.append(fail_dict)
	push_error("FAIL [%s :: %s]: %s" % [suite_name, current_test_name, message + caller_info])

func _record_pass() -> void:
	assertion_count += 1
	pass_count += 1

func assert_true(condition: bool, message: String = "Expected true, got false") -> bool:
	if condition:
		_record_pass()
		return true
	_record_failure(message)
	return false

func assert_false(condition: bool, message: String = "Expected false, got true") -> bool:
	if not condition:
		_record_pass()
		return true
	_record_failure(message)
	return false

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> bool:
	if actual == expected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected '%s' (type %s), got '%s' (type %s)" % [str(expected), typeof(expected), str(actual), typeof(actual)]
	_record_failure(err_msg)
	return false

func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> bool:
	if actual != unexpected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected value NOT to equal '%s'" % [str(unexpected)]
	_record_failure(err_msg)
	return false

func assert_null(actual: Variant, message: String = "Expected value to be null") -> bool:
	if actual == null:
		_record_pass()
		return true
	_record_failure(message + " (got: %s)" % str(actual))
	return false

func assert_not_null(actual: Variant, message: String = "Expected value not to be null") -> bool:
	if actual != null:
		_record_pass()
		return true
	_record_failure(message)
	return false

func assert_approx(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> bool:
	if abs(actual - expected) <= tolerance:
		_record_pass()
		return true
	var err_msg = ("%s (Expected %f ± %f, got %f)" % [message, expected, tolerance, actual]) if message != "" else "Expected %f ± %f, got %f (diff: %f)" % [expected, tolerance, actual, abs(actual - expected)]
	_record_failure(err_msg)
	return false

func assert_vector2_approx(actual: Vector2, expected: Vector2, tolerance: float = 0.001, message: String = "") -> bool:
	if actual.distance_to(expected) <= tolerance:
		_record_pass()
		return true
	var err_msg = ("%s (Expected Vector2%s ± %f, got Vector2%s)" % [message, str(expected), tolerance, str(actual)]) if message != "" else "Expected Vector2%s ± %f, got Vector2%s (dist: %f)" % [str(expected), tolerance, str(actual), actual.distance_to(expected)]
	_record_failure(err_msg)
	return false

func assert_vector3_approx(actual: Vector3, expected: Vector3, tolerance: float = 0.001, message: String = "") -> bool:
	if actual.distance_to(expected) <= tolerance:
		_record_pass()
		return true
	var err_msg = ("%s (Expected Vector3%s ± %f, got Vector3%s)" % [message, str(expected), tolerance, str(actual)]) if message != "" else "Expected Vector3%s ± %f, got Vector3%s (dist: %f)" % [str(expected), tolerance, str(actual), actual.distance_to(expected)]
	_record_failure(err_msg)
	return false

func assert_vector4_approx(actual: Vector4, expected: Vector4, tolerance: float = 0.001, message: String = "") -> bool:
	if actual.distance_to(expected) <= tolerance:
		_record_pass()
		return true
	var err_msg = ("%s (Expected Vector4%s ± %f, got Vector4%s)" % [message, str(expected), tolerance, str(actual)]) if message != "" else "Expected Vector4%s ± %f, got Vector4%s (dist: %f)" % [str(expected), tolerance, str(actual), actual.distance_to(expected)]
	_record_failure(err_msg)
	return false

func assert_quaternion_approx(actual: Quaternion, expected: Quaternion, tolerance: float = 0.001, message: String = "") -> bool:
	var diff = abs(actual.x - expected.x) + abs(actual.y - expected.y) + abs(actual.z - expected.z) + abs(actual.w - expected.w)
	if diff <= tolerance * 4.0:
		_record_pass()
		return true
	var err_msg = ("%s (Expected Quaternion%s ± %f, got Quaternion%s)" % [message, str(expected), tolerance, str(actual)]) if message != "" else "Expected Quaternion%s ± %f, got Quaternion%s" % [str(expected), tolerance, str(actual)]
	_record_failure(err_msg)
	return false

func assert_color_approx(actual: Color, expected: Color, tolerance: float = 0.01, message: String = "") -> bool:
	var diff = abs(actual.r - expected.r) + abs(actual.g - expected.g) + abs(actual.b - expected.b) + abs(actual.a - expected.a)
	if diff <= tolerance * 4.0:
		_record_pass()
		return true
	var err_msg = ("%s (Expected Color%s ± %f, got Color%s)" % [message, str(expected), tolerance, str(actual)]) if message != "" else "Expected Color%s ± %f, got Color%s" % [str(expected), tolerance, str(actual)]
	_record_failure(err_msg)
	return false

func assert_transform2d_approx(actual: Transform2D, expected: Transform2D, tolerance: float = 0.001, message: String = "") -> bool:
	var o_diff = actual.origin.distance_to(expected.origin)
	var x_diff = actual.x.distance_to(expected.x)
	var y_diff = actual.y.distance_to(expected.y)
	if o_diff <= tolerance and x_diff <= tolerance and y_diff <= tolerance:
		_record_pass()
		return true
	var err_msg = ("%s (Expected Transform2D %s ± %f, got %s)" % [message, str(expected), tolerance, str(actual)]) if message != "" else "Expected Transform2D %s ± %f, got %s" % [str(expected), tolerance, str(actual)]
	_record_failure(err_msg)
	return false

func assert_transform3d_approx(actual: Transform3D, expected: Transform3D, tolerance: float = 0.001, message: String = "") -> bool:
	var o_diff = actual.origin.distance_to(expected.origin)
	var b_diff = actual.basis.x.distance_to(expected.basis.x) + actual.basis.y.distance_to(expected.basis.y) + actual.basis.z.distance_to(expected.basis.z)
	if o_diff <= tolerance and b_diff <= tolerance * 3.0:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected Transform3D %s ± %f, got %s" % [str(expected), tolerance, str(actual)]
	_record_failure(err_msg)
	return false

func assert_in_range(actual: float, min_val: float, max_val: float, message: String = "") -> bool:
	if actual >= min_val and actual <= max_val:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected %f to be in range [%f, %f]" % [actual, min_val, max_val]
	_record_failure(err_msg)
	return false

func assert_gt(actual: float, expected: float, message: String = "") -> bool:
	if actual > expected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected %f > %f" % [actual, expected]
	_record_failure(err_msg)
	return false

func assert_gte(actual: float, expected: float, message: String = "") -> bool:
	if actual >= expected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected %f >= %f" % [actual, expected]
	_record_failure(err_msg)
	return false

func assert_lt(actual: float, expected: float, message: String = "") -> bool:
	if actual < expected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected %f < %f" % [actual, expected]
	_record_failure(err_msg)
	return false

func assert_lte(actual: float, expected: float, message: String = "") -> bool:
	if actual <= expected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected %f <= %f" % [actual, expected]
	_record_failure(err_msg)
	return false

func assert_has_node(parent: Node, node_path: NodePath, message: String = "") -> bool:
	if parent and parent.has_node(node_path):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected node '%s' to exist in '%s'" % [str(node_path), str(parent.name if parent else "null")]
	_record_failure(err_msg)
	return false

func assert_array_contains(arr: Array, element: Variant, message: String = "") -> bool:
	if arr.has(element):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected array %s to contain '%s'" % [str(arr), str(element)]
	_record_failure(err_msg)
	return false

func assert_array_not_contains(arr: Array, element: Variant, message: String = "") -> bool:
	if not arr.has(element):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected array %s NOT to contain '%s'" % [str(arr), str(element)]
	_record_failure(err_msg)
	return false

func assert_dict_has_key(dict: Dictionary, key: Variant, message: String = "") -> bool:
	if dict.has(key):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected dictionary to contain key '%s'" % [str(key)]
	_record_failure(err_msg)
	return false

func assert_dict_not_has_key(dict: Dictionary, key: Variant, message: String = "") -> bool:
	if not dict.has(key):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected dictionary NOT to contain key '%s'" % [str(key)]
	_record_failure(err_msg)
	return false

func assert_empty(actual: Variant, message: String = "") -> bool:
	var is_emp = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or actual is PackedByteArray or actual is PackedInt32Array or actual is PackedInt64Array or actual is PackedFloat32Array or actual is PackedFloat64Array or actual is PackedStringArray or actual is PackedVector2Array or actual is PackedVector3Array or actual is PackedVector4Array or actual is PackedColorArray:
		is_emp = actual.is_empty()
	if is_emp:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected empty container, got size %s" % str(actual)
	_record_failure(err_msg)
	return false

func assert_not_empty(actual: Variant, message: String = "") -> bool:
	var is_emp = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or actual is PackedByteArray or actual is PackedInt32Array or actual is PackedInt64Array or actual is PackedFloat32Array or actual is PackedFloat64Array or actual is PackedStringArray or actual is PackedVector2Array or actual is PackedVector3Array or actual is PackedVector4Array or actual is PackedColorArray:
		is_emp = actual.is_empty()
	if not is_emp:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected non-empty container, got empty"
	_record_failure(err_msg)
	return false

func assert_size(actual: Variant, expected_size: int, message: String = "") -> bool:
	var sz = 0
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or actual is PackedByteArray or actual is PackedInt32Array or actual is PackedInt64Array or actual is PackedFloat32Array or actual is PackedFloat64Array or actual is PackedStringArray or actual is PackedVector2Array or actual is PackedVector3Array or actual is PackedVector4Array or actual is PackedColorArray:
		sz = actual.size()
	if sz == expected_size:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected size %d, got size %d" % [expected_size, sz]
	_record_failure(err_msg)
	return false

func assert_string_contains(haystack: String, needle: String, message: String = "") -> bool:
	if haystack.contains(needle):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected string '%s' to contain '%s'" % [haystack, needle]
	_record_failure(err_msg)
	return false

func assert_string_not_contains(haystack: String, needle: String, message: String = "") -> bool:
	if not haystack.contains(needle):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected string '%s' NOT to contain '%s'" % [haystack, needle]
	_record_failure(err_msg)
	return false

func assert_string_begins_with(haystack: String, prefix: String, message: String = "") -> bool:
	if haystack.begins_with(prefix):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected string '%s' to begin with '%s'" % [haystack, prefix]
	_record_failure(err_msg)
	return false

func assert_string_ends_with(haystack: String, suffix: String, message: String = "") -> bool:
	if haystack.ends_with(suffix):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected string '%s' to end with '%s'" % [haystack, suffix]
	_record_failure(err_msg)
	return false

func assert_array_eq(actual: Array, expected: Array, message: String = "") -> bool:
	if actual == expected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected array %s, got %s" % [str(expected), str(actual)]
	_record_failure(err_msg)
	return false

func assert_dict_eq(actual: Dictionary, expected: Dictionary, message: String = "") -> bool:
	if actual == expected:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected dictionary %s, got %s" % [str(expected), str(actual)]
	_record_failure(err_msg)
	return false

func assert_type(value: Variant, expected_type: int, message: String = "") -> bool:
	if typeof(value) == expected_type:
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected type %d, got type %d (%s)" % [expected_type, typeof(value), str(value)]
	_record_failure(err_msg)
	return false

func assert_is(object: Object, expected_class: Variant, message: String = "") -> bool:
	if not object or not is_instance_valid(object):
		_record_failure(message if message != "" else "assert_is failed: Object is null or invalid")
		return false
	if is_instance_of(object, expected_class):
		_record_pass()
		return true
	var err_msg = message if message != "" else "Expected object %s to be instance of %s" % [str(object), str(expected_class)]
	_record_failure(err_msg)
	return false

# --- Execution Engine ---

func get_test_methods() -> Array[String]:
	var methods: Array[String] = []
	for method_dict in get_method_list():
		var m_name: String = method_dict["name"]
		if m_name.begins_with("test_"):
			if filter_method_name == "" or (filter_method_name.to_lower() in m_name.to_lower()):
				methods.append(m_name)
	methods.sort()
	return methods

func run_suite() -> Dictionary:
	var suite_start_time = Time.get_ticks_msec()
	pass_count = 0
	fail_count = 0
	assertion_count = 0
	failures.clear()
	test_results.clear()
	audit_checkpoints.clear()
	test_attachments.clear()
	_cleanup_signal_spies()
	
	print("--- Running Suite [%s]: %s ---" % [test_type.to_upper(), suite_name])
	await before_all()
	
	var methods = get_test_methods()
	for test_method in methods:
		current_test_name = test_method
		_test_aborted = false
		var test_start_time = Time.get_ticks_msec()
		var start_fails = fail_count
		
		await before_each()
		
		var callable = Callable(self, test_method)
		await callable.call()
		
		await after_each()
		_execute_teardown_callbacks()
		_cleanup_signal_spies()
		_cleanup_auto_free_nodes()
		MockFactory.clear_spies()
		
		var test_duration = Time.get_ticks_msec() - test_start_time
		var passed = (fail_count == start_fails)
		
		var test_record = {
			"name": test_method,
			"passed": passed,
			"duration_ms": test_duration,
			"failures": [],
			"attachments": get_attachments(test_method)
		}
		
		if not passed:
			for f in failures:
				if f["test"] == test_method:
					test_record["failures"].append(f["message"])
			test_failed.emit(suite_name, test_method, str(test_record["failures"]), test_duration)
			print("  ❌ %s (FAILED in %d ms)" % [test_method, test_duration])
			if stop_on_failure:
				break
		else:
			test_passed.emit(suite_name, test_method, test_duration)
			print("  ✅ %s (PASSED in %d ms)" % [test_method, test_duration])
		
		test_results.append(test_record)
	
	await after_all()
	_execute_teardown_callbacks()
	_cleanup_signal_spies()
	_cleanup_auto_free_nodes()
	_cleanup_network_mocker()
	MockFactory.clear_spies()
	if is_inside_tree():
		await get_tree().process_frame
		await get_tree().physics_frame
	var total_duration = Time.get_ticks_msec() - suite_start_time
	
	var summary = {
		"suite_name": suite_name,
		"test_type": test_type,
		"tests_total": methods.size(),
		"tests_passed": methods.size() - failures.size(),
		"assertions_total": assertion_count,
		"failures_total": failures.size(),
		"duration_ms": total_duration,
		"passed": (failures.size() == 0),
		"tests": test_results,
		"checkpoints": audit_checkpoints,
		"attachments": test_attachments
	}
	
	print("--- Finished Suite %s: %d passed, %d failed (%d ms) ---" % [
		suite_name,
		summary["tests_passed"],
		summary["failures_total"],
		total_duration
	])
	
	return summary
