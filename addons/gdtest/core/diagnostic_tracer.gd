# diagnostic_tracer.gd
# Zero-Cost Failure Diagnostic Bundler for GDTest 3.0.
# Exclusively triggered when a test fails to capture a complete diagnostic package:
# - scene_tree_dump.json
# - engine_log.txt
# - failure_frame.png
# - test_metadata.json
class_name DiagnosticTracer
extends RefCounted

## Captures a complete failure diagnostic bundle for a failed test.
## Zero cost during passing tests; invoked strictly on failure.
static func capture_failure(
	suite: Object,
	test_name: String,
	failure_messages: Array,
	target_viewport: Viewport = null
) -> Dictionary:
	var suite_name = "GlobalSuite"
	if suite and suite.get("suite_name") != null:
		suite_name = str(suite.get("suite_name"))
		
	var safe_suite = suite_name.to_lower().replace(" ", "_").replace("/", "_")
	var safe_test = test_name.to_lower().replace(" ", "_").replace("/", "_")
	
	var base_art_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts")
	var diag_dir = base_art_dir.path_join("diagnostics").path_join(safe_suite).path_join(safe_test)
	
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(diag_dir):
		dir.make_dir_recursive(diag_dir)
		
	var global_diag_dir = ProjectSettings.globalize_path(diag_dir)
	var generated_files: Dictionary = {}
	
	# 1. Capture Viewport Failure Frame (failure_frame.png)
	var frame_path = diag_dir.path_join("failure_frame.png")
	var frame_captured = _capture_viewport_screenshot(target_viewport, frame_path)
	if frame_captured:
		generated_files["failure_frame"] = frame_path
		
	# 2. Dump SceneTree Hierarchy (scene_tree_dump.json)
	var tree_root: Node = null
	if suite is Node:
		tree_root = suite.get_tree().root if suite.get_tree() else suite
	elif target_viewport:
		tree_root = target_viewport
		
	var tree_dump = dump_scene_tree(tree_root)
	var tree_dump_path = diag_dir.path_join("scene_tree_dump.json")
	_write_text_file(ProjectSettings.globalize_path(tree_dump_path), JSON.stringify(tree_dump, "  ", false))
	generated_files["scene_tree_dump"] = tree_dump_path
	
	# 3. Generate Engine & Diagnostic Log (engine_log.txt)
	var stack_info = _extract_stack_trace()
	var log_text = _format_engine_log(suite_name, test_name, failure_messages, stack_info)
	var log_path = diag_dir.path_join("engine_log.txt")
	_write_text_file(ProjectSettings.globalize_path(log_path), log_text)
	generated_files["engine_log"] = log_path
	
	# 4. Generate Machine-Readable Diagnostic Metadata (test_metadata.json)
	var metadata = _generate_metadata(suite_name, test_name, failure_messages, stack_info, generated_files)
	var meta_path = diag_dir.path_join("test_metadata.json")
	_write_text_file(ProjectSettings.globalize_path(meta_path), JSON.stringify(metadata, "  ", false))
	generated_files["test_metadata"] = meta_path
	
	print("  📦 [DIAGNOSTIC BUNDLE WRITTEN] -> %s" % diag_dir)
	return {
		"directory": diag_dir,
		"files": generated_files,
		"metadata": metadata
	}

# --- Scene Tree Dump ---

## Recursively serializes the active SceneTree hierarchy with physics and script state.
static func dump_scene_tree(node: Node) -> Dictionary:
	if not node or not is_instance_valid(node):
		return {"error": "Invalid or null node root"}
		
	var dict: Dictionary = {
		"name": str(node.name),
		"type": node.get_class(),
		"path": str(node.get_path()) if node.is_inside_tree() else "unmounted",
		"instance_id": node.get_instance_id()
	}
	
	# CanvasItem (2D)
	if node is CanvasItem:
		var ci = node as CanvasItem
		dict["visible"] = ci.visible
		dict["modulate"] = {"r": snappedf(ci.modulate.r, 0.001), "g": snappedf(ci.modulate.g, 0.001), "b": snappedf(ci.modulate.b, 0.001), "a": snappedf(ci.modulate.a, 0.001)}
		if node is Node2D:
			var n2d = node as Node2D
			dict["position"] = {"x": snappedf(n2d.position.x, 0.01), "y": snappedf(n2d.position.y, 0.01)}
			dict["rotation_deg"] = snappedf(rad_to_deg(n2d.rotation), 0.01)
			dict["scale"] = {"x": snappedf(n2d.scale.x, 0.01), "y": snappedf(n2d.scale.y, 0.01)}
		elif node is Control:
			var ctrl = node as Control
			dict["position"] = {"x": snappedf(ctrl.position.x, 0.01), "y": snappedf(ctrl.position.y, 0.01)}
			dict["size"] = {"x": snappedf(ctrl.size.x, 0.01), "y": snappedf(ctrl.size.y, 0.01)}
	# Node3D
	elif node is Node3D:
		var n3d = node as Node3D
		dict["visible"] = n3d.visible
		dict["position"] = {"x": snappedf(n3d.position.x, 0.01), "y": snappedf(n3d.position.y, 0.01), "z": snappedf(n3d.position.z, 0.01)}
		dict["rotation_deg"] = {"x": snappedf(rad_to_deg(n3d.rotation.x), 0.01), "y": snappedf(rad_to_deg(n3d.rotation.y), 0.01), "z": snappedf(rad_to_deg(n3d.rotation.z), 0.01)}
		dict["scale"] = {"x": snappedf(n3d.scale.x, 0.01), "y": snappedf(n3d.scale.y, 0.01), "z": snappedf(n3d.scale.z, 0.01)}

	# Physics Bodies
	if node is RigidBody2D:
		var rb2d = node as RigidBody2D
		dict["physics_state"] = {
			"sleeping": rb2d.sleeping,
			"linear_velocity": {"x": snappedf(rb2d.linear_velocity.x, 0.01), "y": snappedf(rb2d.linear_velocity.y, 0.01)},
			"angular_velocity": snappedf(rb2d.angular_velocity, 0.01)
		}
	elif node is RigidBody3D:
		var rb3d = node as RigidBody3D
		dict["physics_state"] = {
			"sleeping": rb3d.sleeping,
			"linear_velocity": {"x": snappedf(rb3d.linear_velocity.x, 0.01), "y": snappedf(rb3d.linear_velocity.y, 0.01), "z": snappedf(rb3d.linear_velocity.z, 0.01)},
			"angular_velocity": {"x": snappedf(rb3d.angular_velocity.x, 0.01), "y": snappedf(rb3d.angular_velocity.y, 0.01), "z": snappedf(rb3d.angular_velocity.z, 0.01)}
		}
	elif node is CharacterBody2D:
		var cb2d = node as CharacterBody2D
		dict["physics_state"] = {
			"velocity": {"x": snappedf(cb2d.velocity.x, 0.01), "y": snappedf(cb2d.velocity.y, 0.01)},
			"is_on_floor": cb2d.is_on_floor()
		}
	elif node is CharacterBody3D:
		var cb3d = node as CharacterBody3D
		dict["physics_state"] = {
			"velocity": {"x": snappedf(cb3d.velocity.x, 0.01), "y": snappedf(cb3d.velocity.y, 0.01), "z": snappedf(cb3d.velocity.z, 0.01)},
			"is_on_floor": cb3d.is_on_floor()
		}

	# Script Variables
	var script = node.get_script()
	if script:
		var custom_vars: Dictionary = {}
		for prop in node.get_property_list():
			var usage = prop.get("usage", 0)
			var p_name: String = prop.get("name", "")
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and not p_name.begins_with("_"):
				var val = node.get(p_name)
				if val is Object:
					custom_vars[p_name] = "<Object:%s>" % (val.get_class() if is_instance_valid(val) else "freed")
				else:
					custom_vars[p_name] = str(val)
		if not custom_vars.is_empty():
			dict["script_variables"] = custom_vars

	# Children
	var children = node.get_children()
	dict["children_count"] = children.size()
	if not children.is_empty():
		var child_dumps: Array[Dictionary] = []
		for c in children:
			child_dumps.append(dump_scene_tree(c))
		dict["children"] = child_dumps
		
	return dict

# --- Screenshot Capture ---

static func _capture_viewport_screenshot(viewport: Viewport, out_path: String) -> bool:
	var global_path = ProjectSettings.globalize_path(out_path)
	var img: Image = null
	
	if viewport and DisplayServer.get_name() != "headless":
		var tex = viewport.get_texture()
		if tex:
			img = tex.get_image()
			
	if not img or img.is_empty():
		# Fallback image
		img = Image.create(320, 240, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.18, 0.04, 0.04, 1.0)) # Dark red diagnostic fallback
		
	var err = img.save_png(global_path)
	return err == OK

# --- Engine Log Formatting ---

static func _format_engine_log(suite_name: String, test_name: String, failure_messages: Array, stack_info: Array) -> String:
	var lines: Array[String] = []
	lines.append("================================================================================")
	lines.append("🔥 GDTEST 3.0 FAILURE DIAGNOSTIC LOG")
	lines.append("================================================================================")
	lines.append("Suite:        %s" % suite_name)
	lines.append("Test:         %s" % test_name)
	lines.append("Timestamp:    %s (Ticks: %d ms)" % [Time.get_datetime_string_from_system(true), Time.get_ticks_msec()])
	lines.append("Engine:       Godot %s" % Engine.get_version_info()["string"])
	lines.append("Platform:     %s (%s) | DisplayServer: %s" % [OS.get_name(), OS.get_model_name(), DisplayServer.get_name()])
	lines.append("Memory:       Static: %d bytes (Peak: %d bytes)" % [OS.get_static_memory_usage(), OS.get_static_memory_peak_usage()])
	lines.append("Perf Counts:  Nodes: %d | Objects: %d | FPS: %.1f" % [
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		Performance.get_monitor(Performance.TIME_FPS)
	])
	lines.append("--------------------------------------------------------------------------------")
	lines.append("❌ FAILURE REASONS (%d):" % failure_messages.size())
	for i in range(failure_messages.size()):
		lines.append("  [%d] %s" % [i + 1, str(failure_messages[i])])
	lines.append("--------------------------------------------------------------------------------")
	lines.append("📍 CALLSTACK / EXECUTION FRAMES:")
	if stack_info.is_empty():
		lines.append("  (No GDScript stack frames available)")
	else:
		for frame in stack_info:
			lines.append("  -> %s:%d in function '%s()'" % [
				frame.get("source", "unknown"),
				frame.get("line", 0),
				frame.get("function", "unknown")
			])
	lines.append("================================================================================")
	return "\n".join(lines)

static func _extract_stack_trace() -> Array:
	# In GDScript, get_stack() returns Array[Dictionary]
	# When called from a static function, get_stack() returns the caller chain
	return get_stack()

# --- Metadata Generation ---

static func _generate_metadata(
	suite_name: String,
	test_name: String,
	failure_messages: Array,
	stack_info: Array,
	generated_files: Dictionary
) -> Dictionary:
	return {
		"suite": suite_name,
		"test": test_name,
		"timestamp_iso": Time.get_datetime_string_from_system(true),
		"timestamp_ticks_ms": Time.get_ticks_msec(),
		"engine_version": Engine.get_version_info()["string"],
		"os_name": OS.get_name(),
		"os_model": OS.get_model_name(),
		"display_server": DisplayServer.get_name(),
		"memory_static_bytes": OS.get_static_memory_usage(),
		"memory_peak_bytes": OS.get_static_memory_peak_usage(),
		"object_node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_frames": Engine.get_process_frames(),
		"physics_frames": Engine.get_physics_frames(),
		"failure_count": failure_messages.size(),
		"failure_messages": failure_messages,
		"stack_trace": stack_info,
		"artifacts": generated_files
	}

static func _write_text_file(path: String, text: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(text)
		file.close()
