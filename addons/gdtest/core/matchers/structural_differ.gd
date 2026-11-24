# structural_differ.gd
# Cyclic-safe deep structural diff engine for Godot 4.x.
# Compares nested Dictionaries, Arrays, Objects, Primitives, Vectors, and PackedArrays.
# Features:
# - Visited pair dictionary to detect and safely handle cyclic/recursive references.
# - Truncation of large collections and long strings to prevent log flooding.
# - Path-addressed mismatch tracking (e.g. root["inventory"][2].item_id).
# - Unified diff text generation with visual +/- markers.
class_name GDTestStructuralDiffer
extends RefCounted

const DEFAULT_MAX_DEPTH: int = 12
const DEFAULT_MAX_COLLECTION_ITEMS: int = 25
const DEFAULT_MAX_STRING_LEN: int = 120
const DEFAULT_FLOAT_TOLERANCE: float = 0.0001

## Compares two Variants deeply and returns a detailed structural diff dictionary.
## Returns {
##   "equal": bool,
##   "differences": Array[Dictionary], # List of {path, actual, expected, reason}
##   "formatted_diff": String
## }
static func diff(actual: Variant, expected: Variant, options: Dictionary = {}) -> Dictionary:
	var max_depth: int = options.get("max_depth", DEFAULT_MAX_DEPTH)
	var max_items: int = options.get("max_items", DEFAULT_MAX_COLLECTION_ITEMS)
	var float_tol: float = options.get("float_tolerance", DEFAULT_FLOAT_TOLERANCE)
	var strict_types: bool = options.get("strict_types", true)
	var ignore_keys: Array = options.get("ignore_keys", [])

	var visited_pairs: Array = []
	var differences: Array[Dictionary] = []

	_compare_recursive(
		actual,
		expected,
		"root",
		0,
		max_depth,
		max_items,
		float_tol,
		strict_types,
		ignore_keys,
		visited_pairs,
		differences
	)

	var is_equal: bool = differences.is_empty()
	var formatted_diff: String = "" if is_equal else _build_unified_diff(actual, expected, differences, max_items)

	return {
		"equal": is_equal,
		"differences": differences,
		"formatted_diff": formatted_diff
	}

## Convenience method returning only whether actual and expected are structurally equal.
static func are_equal(actual: Variant, expected: Variant, options: Dictionary = {}) -> bool:
	return diff(actual, expected, options)["equal"]

# --- Internal Recursive Comparator ---

static func _compare_recursive(
	actual: Variant,
	expected: Variant,
	path: String,
	current_depth: int,
	max_depth: int,
	max_items: int,
	float_tol: float,
	strict_types: bool,
	ignore_keys: Array,
	visited_pairs: Array,
	differences: Array[Dictionary]
) -> void:
	if current_depth > max_depth:
		differences.append({
			"path": path,
			"actual": format_value(actual, 40, 5),
			"expected": format_value(expected, 40, 5),
			"reason": "Max comparison depth (%d) exceeded" % max_depth
		})
		return

	# Handle Nulls
	if actual == null and expected == null:
		return
	if actual == null or expected == null:
		differences.append({
			"path": path,
			"actual": format_value(actual),
			"expected": format_value(expected),
			"reason": "Null mismatch: expected %s, got %s" % [format_value(expected), format_value(actual)]
		})
		return

	var actual_type = typeof(actual)
	var expected_type = typeof(expected)

	# Cyclic reference detection for compound reference types
	if _is_compound_type(actual_type) and _is_compound_type(expected_type):
		for pair in visited_pairs:
			if is_same(pair[0], actual) and is_same(pair[1], expected):
				return # Already verified or currently traversing this cycle
		visited_pairs.append([actual, expected])

	# Type mismatch check
	if strict_types and actual_type != expected_type:
		differences.append({
			"path": path,
			"actual": "%s (type %s)" % [format_value(actual), _type_to_name(actual_type)],
			"expected": "%s (type %s)" % [format_value(expected), _type_to_name(expected_type)],
			"reason": "Type mismatch: expected %s (%s), got %s (%s)" % [
				_type_to_name(expected_type), format_value(expected),
				_type_to_name(actual_type), format_value(actual)
			]
		})
		return

	# Type-specific deep matching
	match actual_type:
		TYPE_BOOL:
			if actual != expected:
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Boolean mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_INT, TYPE_FLOAT:
			if not _compare_numbers(actual, expected, float_tol, strict_types):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Numeric mismatch: expected %s, got %s (diff: %s)" % [
						str(expected), str(actual), str(abs(float(actual) - float(expected)))
					]
				})

		TYPE_STRING, TYPE_STRING_NAME:
			if str(actual) != str(expected):
				differences.append({
					"path": path,
					"actual": '"%s"' % str(actual),
					"expected": '"%s"' % str(expected),
					"reason": "String mismatch: expected \"%s\", got \"%s\"" % [str(expected), str(actual)]
				})

		TYPE_VECTOR2, TYPE_VECTOR2I:
			if not _compare_vector2(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Vector2 mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_RECT2, TYPE_RECT2I:
			if not _compare_rect2(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Rect2 mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_VECTOR3, TYPE_VECTOR3I:
			if not _compare_vector3(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Vector3 mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_VECTOR4, TYPE_VECTOR4I:
			if not _compare_vector4(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Vector4 mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_COLOR:
			if not _compare_color(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Color mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_TRANSFORM2D:
			if not _compare_transform2d(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Transform2D mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_TRANSFORM3D:
			if not _compare_transform3d(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Transform3D mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_QUATERNION:
			if not _compare_quaternion(actual, expected, float_tol):
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "Quaternion mismatch: expected %s, got %s" % [str(expected), str(actual)]
				})

		TYPE_PLANE, TYPE_AABB, TYPE_BASIS, TYPE_PROJECTION:
			if actual != expected:
				differences.append({
					"path": path,
					"actual": actual,
					"expected": expected,
					"reason": "%s mismatch: expected %s, got %s" % [_type_to_name(actual_type), str(expected), str(actual)]
				})

		TYPE_ARRAY:
			_compare_arrays(
				actual as Array,
				expected as Array,
				path,
				current_depth,
				max_depth,
				max_items,
				float_tol,
				strict_types,
				ignore_keys,
				visited_pairs,
				differences
			)

		TYPE_DICTIONARY:
			_compare_dictionaries(
				actual as Dictionary,
				expected as Dictionary,
				path,
				current_depth,
				max_depth,
				max_items,
				float_tol,
				strict_types,
				ignore_keys,
				visited_pairs,
				differences
			)

		TYPE_OBJECT:
			_compare_objects(
				actual as Object,
				expected as Object,
				path,
				current_depth,
				max_depth,
				max_items,
				float_tol,
				strict_types,
				ignore_keys,
				visited_pairs,
				differences
			)

		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, \
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY:
			_compare_packed_arrays(
				actual,
				expected,
				path,
				current_depth,
				max_depth,
				max_items,
				float_tol,
				strict_types,
				ignore_keys,
				visited_pairs,
				differences
			)

		_:
			if actual != expected:
				differences.append({
					"path": path,
					"actual": format_value(actual),
					"expected": format_value(expected),
					"reason": "Value mismatch: expected %s, got %s" % [format_value(expected), format_value(actual)]
				})

# --- Container Comparators ---

static func _compare_arrays(
	actual: Array,
	expected: Array,
	path: String,
	current_depth: int,
	max_depth: int,
	max_items: int,
	float_tol: float,
	strict_types: bool,
	ignore_keys: Array,
	visited_pairs: Array,
	differences: Array[Dictionary]
) -> void:
	var actual_sz = actual.size()
	var expected_sz = expected.size()

	if actual_sz != expected_sz:
		differences.append({
			"path": path + ".size()",
			"actual": actual_sz,
			"expected": expected_sz,
			"reason": "Array size mismatch: expected %d items, got %d items" % [expected_sz, actual_sz]
		})

	var check_limit = mini(maxi(actual_sz, expected_sz), max_items)
	for i in range(check_limit):
		var elem_path = "%s[%d]" % [path, i]
		if i >= actual_sz:
			differences.append({
				"path": elem_path,
				"actual": "<missing>",
				"expected": format_value(expected[i]),
				"reason": "Missing array element at index %d" % i
			})
		elif i >= expected_sz:
			differences.append({
				"path": elem_path,
				"actual": format_value(actual[i]),
				"expected": "<extra>",
				"reason": "Unexpected extra array element at index %d" % i
			})
		else:
			_compare_recursive(
				actual[i],
				expected[i],
				elem_path,
				current_depth + 1,
				max_depth,
				max_items,
				float_tol,
				strict_types,
				ignore_keys,
				visited_pairs,
				differences
			)

	if actual_sz > max_items or expected_sz > max_items:
		var extra_count = maxi(actual_sz, expected_sz) - max_items
		if extra_count > 0:
			differences.append({
				"path": path + "[...]",
				"actual": "... (%d items omitted)" % actual_sz,
				"expected": "... (%d items omitted)" % expected_sz,
				"reason": "Array truncated at %d items (%d remaining items skipped)" % [max_items, extra_count]
			})

static func _compare_dictionaries(
	actual: Dictionary,
	expected: Dictionary,
	path: String,
	current_depth: int,
	max_depth: int,
	max_items: int,
	float_tol: float,
	strict_types: bool,
	ignore_keys: Array,
	visited_pairs: Array,
	differences: Array[Dictionary]
) -> void:
	var actual_keys = actual.keys()
	var expected_keys = expected.keys()

	# Sort keys for deterministic output
	actual_keys.sort()
	expected_keys.sort()

	# Missing keys
	for k in expected_keys:
		if ignore_keys.has(k):
			continue
		if not actual.has(k):
			differences.append({
				"path": _dict_path(path, k),
				"actual": "<missing key>",
				"expected": format_value(expected[k]),
				"reason": "Key missing in actual dictionary: '%s'" % str(k)
			})

	# Extra keys
	for k in actual_keys:
		if ignore_keys.has(k):
			continue
		if not expected.has(k):
			differences.append({
				"path": _dict_path(path, k),
				"actual": format_value(actual[k]),
				"expected": "<unexpected key>",
				"reason": "Unexpected extra key in actual dictionary: '%s'" % str(k)
			})

	# Matching keys value comparison
	var count = 0
	for k in expected_keys:
		if ignore_keys.has(k):
			continue
		if actual.has(k):
			count += 1
			if count > max_items:
				differences.append({
					"path": path + ".{...}",
					"actual": "... (%d keys omitted)" % actual.size(),
					"expected": "... (%d keys omitted)" % expected.size(),
					"reason": "Dictionary truncated at %d keys" % max_items
				})
				break
			_compare_recursive(
				actual[k],
				expected[k],
				_dict_path(path, k),
				current_depth + 1,
				max_depth,
				max_items,
				float_tol,
				strict_types,
				ignore_keys,
				visited_pairs,
				differences
			)

static func _compare_objects(
	actual: Object,
	expected: Object,
	path: String,
	current_depth: int,
	max_depth: int,
	max_items: int,
	float_tol: float,
	strict_types: bool,
	ignore_keys: Array,
	visited_pairs: Array,
	differences: Array[Dictionary]
) -> void:
	if not is_instance_valid(actual) and not is_instance_valid(expected):
		return
	if not is_instance_valid(actual) or not is_instance_valid(expected):
		differences.append({
			"path": path,
			"actual": "Valid" if is_instance_valid(actual) else "Freed/Null",
			"expected": "Valid" if is_instance_valid(expected) else "Freed/Null",
			"reason": "Object validity mismatch at %s" % path
		})
		return

	if actual == expected:
		return # Identical instance

	var actual_class = actual.get_class()
	var expected_class = expected.get_class()
	if actual_class != expected_class:
		differences.append({
			"path": path + ".get_class()",
			"actual": actual_class,
			"expected": expected_class,
			"reason": "Object class mismatch: expected %s, got %s" % [expected_class, actual_class]
		})
		return

	# Compare custom / script properties
	var props = actual.get_property_list()
	var compared_count = 0
	for p in props:
		var usage = p.get("usage", 0)
		var p_name = p.get("name", "")
		# Only check exported or script properties, avoid built-in engine internals unless relevant
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or (usage & PROPERTY_USAGE_STORAGE) != 0:
			if p_name.begins_with("_") or p_name.begins_with("script") or ignore_keys.has(p_name):
				continue
			compared_count += 1
			if compared_count > max_items:
				break
			var actual_val = actual.get(p_name)
			var expected_val = expected.get(p_name)
			_compare_recursive(
				actual_val,
				expected_val,
				"%s.%s" % [path, p_name],
				current_depth + 1,
				max_depth,
				max_items,
				float_tol,
				strict_types,
				ignore_keys,
				visited_pairs,
				differences
			)

static func _compare_packed_arrays(
	actual: Variant,
	expected: Variant,
	path: String,
	current_depth: int,
	max_depth: int,
	max_items: int,
	float_tol: float,
	strict_types: bool,
	ignore_keys: Array,
	visited_pairs: Array,
	differences: Array[Dictionary]
) -> void:
	var actual_arr = Array(actual)
	var expected_arr = Array(expected)
	_compare_arrays(
		actual_arr,
		expected_arr,
		path,
		current_depth,
		max_depth,
		max_items,
		float_tol,
		strict_types,
		ignore_keys,
		visited_pairs,
		differences
	)

# --- Math & Equality Helpers ---

static func _compare_numbers(a: Variant, b: Variant, tol: float, strict: bool) -> bool:
	if is_nan(float(a)) and is_nan(float(b)):
		return true
	if is_inf(float(a)) and is_inf(float(b)):
		return (float(a) > 0) == (float(b) > 0)
	if strict and typeof(a) != typeof(b):
		return false
	return abs(float(a) - float(b)) <= tol

static func _compare_vector2(a: Vector2, b: Vector2, tol: float) -> bool:
	return abs(a.x - b.x) <= tol and abs(a.y - b.y) <= tol

static func _compare_rect2(a: Rect2, b: Rect2, tol: float) -> bool:
	return _compare_vector2(a.position, b.position, tol) and _compare_vector2(a.size, b.size, tol)

static func _compare_vector3(a: Vector3, b: Vector3, tol: float) -> bool:
	return abs(a.x - b.x) <= tol and abs(a.y - b.y) <= tol and abs(a.z - b.z) <= tol

static func _compare_vector4(a: Vector4, b: Vector4, tol: float) -> bool:
	return abs(a.x - b.x) <= tol and abs(a.y - b.y) <= tol and abs(a.z - b.z) <= tol and abs(a.w - b.w) <= tol

static func _compare_color(a: Color, b: Color, tol: float) -> bool:
	return abs(a.r - b.r) <= tol and abs(a.g - b.g) <= tol and abs(a.b - b.b) <= tol and abs(a.a - b.a) <= tol

static func _compare_transform2d(a: Transform2D, b: Transform2D, tol: float) -> bool:
	return _compare_vector2(a.x, b.x, tol) and _compare_vector2(a.y, b.y, tol) and _compare_vector2(a.origin, b.origin, tol)

static func _compare_transform3d(a: Transform3D, b: Transform3D, tol: float) -> bool:
	return _compare_vector3(a.basis.x, b.basis.x, tol) and \
		   _compare_vector3(a.basis.y, b.basis.y, tol) and \
		   _compare_vector3(a.basis.z, b.basis.z, tol) and \
		   _compare_vector3(a.origin, b.origin, tol)

static func _compare_quaternion(a: Quaternion, b: Quaternion, tol: float) -> bool:
	return abs(a.x - b.x) <= tol and abs(a.y - b.y) <= tol and abs(a.z - b.z) <= tol and abs(a.w - b.w) <= tol

# --- Formatting & Identity Helpers ---

static func _is_compound_type(vtype: int) -> bool:
	return vtype == TYPE_DICTIONARY or vtype == TYPE_ARRAY or vtype == TYPE_OBJECT

static func _get_identity_key(v: Variant) -> String:
	if v == null:
		return "null"
	var vtype = typeof(v)
	if vtype == TYPE_OBJECT and is_instance_valid(v):
		return "obj_%d" % (v as Object).get_instance_id()
	elif vtype == TYPE_DICTIONARY:
		return "dict_%d" % (v as Dictionary).hash()
	elif vtype == TYPE_ARRAY:
		return "arr_%d" % (v as Array).hash()
	return "%d_%s" % [vtype, str(v)]

static func _dict_path(base_path: String, key: Variant) -> String:
	if key is String or key is StringName:
		return "%s[\"%s\"]" % [base_path, str(key)]
	return "%s[%s]" % [base_path, str(key)]

static func format_value(v: Variant, max_len: int = DEFAULT_MAX_STRING_LEN, max_items: int = 6) -> String:
	if v == null:
		return "null"
	var vtype = typeof(v)
	match vtype:
		TYPE_STRING, TYPE_STRING_NAME:
			var s = str(v)
			if s.length() > max_len:
				return "\"%s...\"" % s.substr(0, max_len)
			return "\"%s\"" % s

		TYPE_ARRAY:
			var arr = v as Array
			if arr.is_empty():
				return "[]"
			var items: Array[String] = []
			var limit = mini(arr.size(), max_items)
			for i in range(limit):
				items.append(format_value(arr[i], 30, 2))
			if arr.size() > max_items:
				items.append("... +%d items" % (arr.size() - max_items))
			return "[%s]" % ", ".join(items)

		TYPE_DICTIONARY:
			var dict = v as Dictionary
			if dict.is_empty():
				return "{}"
			var pairs: Array[String] = []
			var keys = dict.keys()
			var limit = mini(keys.size(), max_items)
			for i in range(limit):
				var k = keys[i]
				pairs.append("%s: %s" % [str(k), format_value(dict[k], 30, 2)])
			if keys.size() > max_items:
				pairs.append("... +%d keys" % (keys.size() - max_items))
			return "{%s}" % ", ".join(pairs)

		TYPE_OBJECT:
			if not is_instance_valid(v):
				return "<freed Object>"
			var obj = v as Object
			if obj is Node:
				return "<Node:%s class=%s id=%d>" % [obj.name, obj.get_class(), obj.get_instance_id()]
			return "<%s id=%d>" % [obj.get_class(), obj.get_instance_id()]

		_:
			var s = str(v)
			if s.length() > max_len:
				return "%s... (%d chars)" % [s.substr(0, max_len), s.length()]
			return s

static func _build_unified_diff(
	actual: Variant,
	expected: Variant,
	differences: Array[Dictionary],
	max_displayed: int = 15
) -> String:
	var lines: Array[String] = []
	lines.append("--- Expected")
	lines.append("+++ Actual")
	lines.append("@@ Structural Differences (%d found) @@" % differences.size())

	var display_limit = mini(differences.size(), max_displayed)
	for i in range(display_limit):
		var d = differences[i]
		lines.append("  Path: %s" % d["path"])
		lines.append("    - Expected: %s" % str(d["expected"]))
		lines.append("    + Actual:   %s" % str(d["actual"]))
		lines.append("    * Reason:   %s" % d["reason"])

	if differences.size() > max_displayed:
		lines.append("  ... and %d more difference(s) omitted." % (differences.size() - max_displayed))

	return "\n".join(lines)

static func _type_to_name(vtype: int) -> String:
	match vtype:
		TYPE_NIL: return "Nil"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_RECT2: return "Rect2"
		TYPE_RECT2I: return "Rect2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_VECTOR4: return "Vector4"
		TYPE_VECTOR4I: return "Vector4i"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_PROJECTION: return "Projection"
		TYPE_COLOR: return "Color"
		TYPE_STRING_NAME: return "StringName"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object"
		TYPE_CALLABLE: return "Callable"
		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
		_: return "Type(%d)" % vtype
