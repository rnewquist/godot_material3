# snapshot_engine.gd
# Deterministic SceneTree & JSON State Snapshot Engine for GDTest 3.0.
# Features volatile data sanitization (float quantization to 4 decimals, @ID stripping, key sorting)
# and --update-snapshots CLI auto-approval.
class_name SnapshotEngine
extends RefCounted

const DEFAULT_SNAPSHOT_DIR = "res://snapshots/"

## Checks if --update-snapshots or -u was passed via CLI flags.
static func is_update_mode() -> bool:
	var user_args = OS.get_cmdline_user_args()
	for arg in user_args:
		if arg == "--update-snapshots" or arg == "-u" or arg.begins_with("--update-snapshots="):
			return true
	var all_args = OS.get_cmdline_args()
	for arg in all_args:
		if arg == "--update-snapshots" or arg == "-u" or arg.begins_with("--update-snapshots="):
			return true
	return false

## Compares an actual state (Node, Dictionary, Array, or Object) against a golden snapshot JSON file.
## If the golden snapshot does not exist or differs, behavior depends on whether --update-snapshots is active.
static func assert_snapshot(
	actual_data: Variant,
	snapshot_name: String,
	suite_name: String = "",
	custom_path: String = ""
) -> Dictionary:
	var file_path = custom_path
	if file_path == "":
		var base_dir = ProjectSettings.get_setting("gdtest/config/snapshots_directory", DEFAULT_SNAPSHOT_DIR)
		var suite_dir = suite_name.to_lower().replace(" ", "_") if suite_name != "" else "global"
		file_path = base_dir.path_join(suite_dir).path_join(snapshot_name + ".json")
		
	var global_path = ProjectSettings.globalize_path(file_path)
	var parent_dir = file_path.get_base_dir()
	
	# Ensure target directories exist
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(parent_dir):
		dir.make_dir_recursive(parent_dir)
		
	# 1. Sanitize the incoming actual data
	var sanitized_actual = sanitize(actual_data)
	var actual_json_string = JSON.stringify(sanitized_actual, "  ", false)
	
	var file_exists = FileAccess.file_exists(global_path)
	var update_enabled = is_update_mode()
	
	# 2. Handle missing baseline
	if not file_exists:
		if update_enabled:
			_write_snapshot_file(global_path, actual_json_string)
			return {
				"passed": true,
				"is_new": true,
				"is_updated": false,
				"snapshot_path": file_path,
				"message": "Created new golden snapshot baseline at '%s'" % file_path,
				"diff": ""
			}
		else:
			_save_artifact_failure(file_path, snapshot_name, actual_json_string, "Missing golden snapshot baseline.")
			return {
				"passed": false,
				"is_new": true,
				"is_updated": false,
				"snapshot_path": file_path,
				"message": "Snapshot '%s' not found at '%s'. Run test with --update-snapshots to create it." % [snapshot_name, file_path],
				"diff": "Snapshot file missing."
			}
			
	# 3. Read and compare against golden baseline
	var golden_file = FileAccess.open(global_path, FileAccess.READ)
	if not golden_file:
		return {
			"passed": false,
			"is_new": false,
			"is_updated": false,
			"snapshot_path": file_path,
			"message": "Could not read golden snapshot at '%s'" % file_path,
			"diff": "File read error"
		}
		
	var golden_json_string = golden_file.get_as_text()
	golden_file.close()
	
	var parsed_golden = JSON.parse_string(golden_json_string)
	var normalized_golden_string = JSON.stringify(sanitize(parsed_golden), "  ", false)
	
	# Exact string / content match
	if actual_json_string == normalized_golden_string:
		return {
			"passed": true,
			"is_new": false,
			"is_updated": false,
			"snapshot_path": file_path,
			"message": "Snapshot '%s' matches golden baseline." % snapshot_name,
			"diff": ""
		}
		
	# 4. Mismatch detected
	if update_enabled:
		_write_snapshot_file(global_path, actual_json_string)
		return {
			"passed": true,
			"is_new": false,
			"is_updated": true,
			"snapshot_path": file_path,
			"message": "Updated golden snapshot baseline at '%s'" % file_path,
			"diff": ""
		}
		
	var diff_lines = compute_diff(parsed_golden, sanitized_actual)
	var diff_text = "\n".join(diff_lines)
	_save_artifact_failure(file_path, snapshot_name, actual_json_string, diff_text)
	
	return {
		"passed": false,
		"is_new": false,
		"is_updated": false,
		"snapshot_path": file_path,
		"message": "Snapshot '%s' differs from golden baseline (%d diff entries). Run with --update-snapshots to accept changes." % [snapshot_name, diff_lines.size()],
		"diff": diff_text
	}

# --- Volatile Data Sanitization ---

## Sanitizes arbitrary GDScript variants into clean, deterministic, sorted, quantized JSON structures.
static func sanitize(data: Variant) -> Variant:
	if data == null:
		return null
		
	var t = typeof(data)
	match t:
		TYPE_BOOL:
			return data
		TYPE_INT:
			return data
		TYPE_FLOAT:
			return _quantize_float(data)
		TYPE_STRING, TYPE_STRING_NAME:
			return _sanitize_string(str(data))
		TYPE_VECTOR2:
			return {"x": _quantize_float(data.x), "y": _quantize_float(data.y)}
		TYPE_VECTOR2I:
			return {"x": data.x, "y": data.y}
		TYPE_VECTOR3:
			return {"x": _quantize_float(data.x), "y": _quantize_float(data.y), "z": _quantize_float(data.z)}
		TYPE_VECTOR3I:
			return {"x": data.x, "y": data.y, "z": data.z}
		TYPE_VECTOR4:
			return {"x": _quantize_float(data.x), "y": _quantize_float(data.y), "z": _quantize_float(data.z), "w": _quantize_float(data.w)}
		TYPE_VECTOR4I:
			return {"x": data.x, "y": data.y, "z": data.z, "w": data.w}
		TYPE_QUATERNION:
			return {"x": _quantize_float(data.x), "y": _quantize_float(data.y), "z": _quantize_float(data.z), "w": _quantize_float(data.w)}
		TYPE_COLOR:
			return {"r": _quantize_float(data.r), "g": _quantize_float(data.g), "b": _quantize_float(data.b), "a": _quantize_float(data.a)}
		TYPE_RECT2:
			return {"position": sanitize(data.position), "size": sanitize(data.size)}
		TYPE_RECT2I:
			return {"position": {"x": data.position.x, "y": data.position.y}, "size": {"x": data.size.x, "y": data.size.y}}
		TYPE_TRANSFORM2D:
			return {"origin": sanitize(data.origin), "x": sanitize(data.x), "y": sanitize(data.y)}
		TYPE_TRANSFORM3D:
			return {
				"origin": sanitize(data.origin),
				"basis_x": sanitize(data.basis.x),
				"basis_y": sanitize(data.basis.y),
				"basis_z": sanitize(data.basis.z)
			}
		TYPE_AABB:
			return {"position": sanitize(data.position), "size": sanitize(data.size)}
		TYPE_DICTIONARY:
			var dict_res: Dictionary = {}
			var sorted_keys: Array = data.keys()
			sorted_keys.sort_custom(func(a, b): return str(a) < str(b))
			for k in sorted_keys:
				var clean_key = _sanitize_string(str(k))
				dict_res[clean_key] = sanitize(data[k])
			return dict_res
		TYPE_ARRAY:
			var arr_res: Array = []
			for item in data:
				arr_res.append(sanitize(item))
			return arr_res
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, \
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_VECTOR4_ARRAY:
			var p_arr: Array = []
			for item in data:
				p_arr.append(sanitize(item))
			return p_arr
		TYPE_OBJECT:
			if data is Node:
				return serialize_node(data)
			elif data is RefCounted or data is Resource:
				return serialize_object(data)
			else:
				return "<Object:%s>" % data.get_class()
		_:
			return str(data)

## Quantizes float numbers to 4 decimal places, avoiding -0.0 artifacts.
static func _quantize_float(val: float) -> float:
	if abs(val) < 0.00005:
		return 0.0
	return snappedf(val, 0.0001)

## Sanitizes strings, stripping volatile @ID numbering and memory pointers.
static func _sanitize_string(s: String) -> String:
	# Strip @Node@1234 -> @Node
	var stripped = s
	var at_pos = stripped.rfind("@")
	if at_pos > 0:
		var suffix = stripped.substr(at_pos + 1)
		if suffix.is_valid_int():
			stripped = stripped.substr(0, at_pos)
			
	# Strip pointer addresses: <Object#12345> -> <Object>
	if stripped.begins_with("<") and stripped.contains("#") and stripped.ends_with(">"):
		var hash_pos = stripped.find("#")
		stripped = stripped.substr(0, hash_pos) + ">"
		
	return stripped

# --- SceneTree & Node Serialization ---

## Serializes a Node hierarchy into a deterministic, sorted dictionary representation.
static func serialize_node(node: Node, include_children: bool = true) -> Dictionary:
	if not node or not is_instance_valid(node):
		return {}
		
	var clean_name = _sanitize_string(node.name)
	var node_dict: Dictionary = {
		"name": clean_name,
		"type": node.get_class()
	}
	
	# Transform & Visibility Properties
	if node is CanvasItem:
		var ci = node as CanvasItem
		node_dict["visible"] = ci.visible
		node_dict["modulate"] = sanitize(ci.modulate)
		if node is Node2D:
			var n2d = node as Node2D
			node_dict["position"] = sanitize(n2d.position)
			node_dict["rotation"] = _quantize_float(n2d.rotation)
			node_dict["scale"] = sanitize(n2d.scale)
		elif node is Control:
			var ctrl = node as Control
			node_dict["position"] = sanitize(ctrl.position)
			node_dict["size"] = sanitize(ctrl.size)
			node_dict["rotation"] = _quantize_float(ctrl.rotation)
			node_dict["scale"] = sanitize(ctrl.scale)
	elif node is Node3D:
		var n3d = node as Node3D
		node_dict["visible"] = n3d.visible
		node_dict["position"] = sanitize(n3d.position)
		node_dict["rotation"] = sanitize(n3d.rotation)
		node_dict["scale"] = sanitize(n3d.scale)
		
	# Physics states
	if node is RigidBody2D:
		var rb2d = node as RigidBody2D
		node_dict["sleeping"] = rb2d.sleeping
		node_dict["mass"] = _quantize_float(rb2d.mass)
	elif node is RigidBody3D:
		var rb3d = node as RigidBody3D
		node_dict["sleeping"] = rb3d.sleeping
		node_dict["mass"] = _quantize_float(rb3d.mass)

	# Exported Script Properties
	var script = node.get_script()
	if script:
		var custom_props: Dictionary = {}
		for prop in node.get_property_list():
			var usage = prop.get("usage", 0)
			var p_name: String = prop.get("name", "")
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and not p_name.begins_with("_"):
				custom_props[p_name] = sanitize(node.get(p_name))
		if not custom_props.is_empty():
			node_dict["properties"] = custom_props

	# Children
	if include_children:
		var children_arr: Array = []
		for child in node.get_children():
			children_arr.append(serialize_node(child, true))
		if not children_arr.is_empty():
			node_dict["children"] = children_arr
			
	return node_dict

## Serializes a generic Object / Resource.
static func serialize_object(obj: Object) -> Dictionary:
	var result: Dictionary = {
		"type": obj.get_class()
	}
	var script = obj.get_script()
	if script:
		var custom_props: Dictionary = {}
		for prop in obj.get_property_list():
			var usage = prop.get("usage", 0)
			var p_name: String = prop.get("name", "")
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and not p_name.begins_with("_"):
				custom_props[p_name] = sanitize(obj.get(p_name))
		if not custom_props.is_empty():
			result["properties"] = custom_props
	return result

# --- Structural JSON Diff Calculation ---

## Computes human-readable structured line-by-line diffs between golden and actual states.
static func compute_diff(expected: Variant, actual: Variant, path: String = "root") -> Array[String]:
	var diffs: Array[String] = []
	_compute_diff_recursive(expected, actual, path, diffs)
	return diffs

static func _compute_diff_recursive(exp_val: Variant, act_val: Variant, curr_path: String, diffs: Array[String]) -> void:
	if typeof(exp_val) != typeof(act_val):
		diffs.append("- %s: %s (type %d)\n+ %s: %s (type %d)" % [
			curr_path, str(exp_val), typeof(exp_val),
			curr_path, str(act_val), typeof(act_val)
		])
		return
		
	if exp_val is Dictionary:
		var exp_keys = exp_val.keys()
		var act_keys = act_val.keys()
		
		# Missing keys
		for k in exp_keys:
			var p = "%s.%s" % [curr_path, str(k)]
			if not act_val.has(k):
				diffs.append("- %s: %s (missing in actual)" % [p, str(exp_val[k])])
			else:
				_compute_diff_recursive(exp_val[k], act_val[k], p, diffs)
				
		# Extra keys
		for k in act_keys:
			if not exp_val.has(k):
				var p = "%s.%s" % [curr_path, str(k)]
				diffs.append("+ %s: %s (extra in actual)" % [p, str(act_val[k])])
	elif exp_val is Array:
		var exp_sz = exp_val.size()
		var act_sz = act_val.size()
		var max_sz = maxi(exp_sz, act_sz)
		
		for i in range(max_sz):
			var p = "%s[%d]" % [curr_path, i]
			if i >= exp_sz:
				diffs.append("+ %s: %s (extra in actual)" % [p, str(act_val[i])])
			elif i >= act_sz:
				diffs.append("- %s: %s (missing in actual)" % [p, str(exp_val[i])])
			else:
				_compute_diff_recursive(exp_val[i], act_val[i], p, diffs)
	else:
		if exp_val != act_val:
			diffs.append("- %s: %s\n+ %s: %s" % [curr_path, str(exp_val), curr_path, str(act_val)])

# --- File Writing & Artifact Recording ---

static func _write_snapshot_file(path: String, content: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()

static func _save_artifact_failure(snapshot_path: String, snapshot_name: String, actual_content: String, diff_content: String) -> void:
	var art_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts").path_join("snapshots")
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(art_dir):
		dir.make_dir_recursive(art_dir)
		
	var actual_file_path = art_dir.path_join(snapshot_name + ".actual.json")
	var diff_file_path = art_dir.path_join(snapshot_name + ".diff.txt")
	
	_write_snapshot_file(ProjectSettings.globalize_path(actual_file_path), actual_content)
	_write_snapshot_file(ProjectSettings.globalize_path(diff_file_path), diff_content)
