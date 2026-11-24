# expectation.gd
# Fluent expectation and assertion engine for GDTest 3.0.
# Supports chained matchers, deep structural diffing, negation (.not_()),
# and integration with GDTestSuite test result recording.
class_name GDTestExpectation
extends RefCounted

const StructuralDiffer = preload("res://addons/gdtest/core/matchers/structural_differ.gd")

var actual: Variant
var _suite_ref: Object = null
var _custom_message: String = ""
var _is_negated: bool = false
var last_passed: bool = true
var last_error: String = ""

func _init(p_actual: Variant, p_suite_ref: Object = null, p_custom_message: String = "") -> void:
	actual = p_actual
	_suite_ref = p_suite_ref
	_custom_message = p_custom_message
	_is_negated = false
	last_passed = true
	last_error = ""

## Inverts the assertion logic for subsequent matcher calls in the chain.
func not_() -> GDTestExpectation:
	_is_negated = not _is_negated
	return self

## Sets a custom failure message prefix for subsequent matcher calls.
func with_message(message: String) -> GDTestExpectation:
	_custom_message = message
	return self

# --- Core Evaluation & Reporting ---

func _evaluate(condition: bool, positive_failure_msg: String, negative_failure_msg: String) -> GDTestExpectation:
	var passed = not condition if _is_negated else condition
	last_passed = passed

	if passed:
		last_error = ""
		if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref.has_method("_record_pass"):
			_suite_ref._record_pass()
	else:
		var raw_msg = negative_failure_msg if _is_negated else positive_failure_msg
		var final_msg = ("[%s] %s" % [_custom_message, raw_msg]) if _custom_message != "" else raw_msg
		last_error = final_msg
		if _suite_ref and is_instance_valid(_suite_ref) and _suite_ref.has_method("_record_failure"):
			_suite_ref._record_failure(final_msg)
		else:
			push_error("Expectation Failed: %s" % final_msg)

	# Reset negation after evaluation so subsequent chained calls start in positive mode unless .not_() is called again
	_is_negated = false
	return self

# --- Matchers ---

## Asserts structural equality between actual and expected values.
## Produces a full unified diff on failure for arrays, dictionaries, and nested objects.
func is_equal_to(expected: Variant, message: String = "") -> GDTestExpectation:
	var diff_result = StructuralDiffer.diff(actual, expected)
	var is_eq = diff_result["equal"]
	var pos_msg = message if message != "" else ("Expected equality, but structural differences were found:\n%s" % diff_result["formatted_diff"])
	var neg_msg = message if message != "" else ("Expected value NOT to equal %s, but they are structurally identical" % StructuralDiffer.format_value(expected))
	return _evaluate(is_eq, pos_msg, neg_msg)

## Asserts exact strict equality (matching type AND identical value or object instance).
func is_strictly_equal_to(expected: Variant, message: String = "") -> GDTestExpectation:
	var strict_eq = (typeof(actual) == typeof(expected)) and (actual == expected)
	var pos_msg = message if message != "" else ("Expected strictly equal '%s' (type %s), got '%s' (type %s)" % [
		str(expected), StructuralDiffer._type_to_name(typeof(expected)),
		str(actual), StructuralDiffer._type_to_name(typeof(actual))
	])
	var neg_msg = message if message != "" else ("Expected value NOT to strictly equal '%s'" % str(expected))
	return _evaluate(strict_eq, pos_msg, neg_msg)

## Asserts that the target is not null and is a valid instance.
func is_not_null(message: String = "") -> GDTestExpectation:
	var valid = (actual != null)
	if valid and actual is Object:
		valid = is_instance_valid(actual)
	var pos_msg = message if message != "" else "Expected non-null value, got null / freed object"
	var neg_msg = message if message != "" else ("Expected null, got %s" % StructuralDiffer.format_value(actual))
	return _evaluate(valid, pos_msg, neg_msg)

## Asserts that the target is null or an invalid/freed object.
func is_null(message: String = "") -> GDTestExpectation:
	var is_nil = (actual == null)
	if not is_nil and actual is Object:
		is_nil = not is_instance_valid(actual)
	var pos_msg = message if message != "" else ("Expected null, got %s" % StructuralDiffer.format_value(actual))
	var neg_msg = message if message != "" else "Expected non-null value, got null"
	return _evaluate(is_nil, pos_msg, neg_msg)

## Asserts that the target evaluates to boolean true.
func is_true(message: String = "") -> GDTestExpectation:
	var cond = (actual == true)
	var pos_msg = message if message != "" else ("Expected true, got %s" % str(actual))
	var neg_msg = message if message != "" else "Expected false, got true"
	return _evaluate(cond, pos_msg, neg_msg)

## Asserts that the target evaluates to boolean false.
func is_false(message: String = "") -> GDTestExpectation:
	var cond = (actual == false)
	var pos_msg = message if message != "" else ("Expected false, got %s" % str(actual))
	var neg_msg = message if message != "" else "Expected true, got false"
	return _evaluate(cond, pos_msg, neg_msg)

## Asserts that the target numeric or vector value is approximately equal within tolerance.
func is_approx(expected: Variant, tolerance: float = 0.001, message: String = "") -> GDTestExpectation:
	var cond = false
	var actual_type = typeof(actual)
	var expected_type = typeof(expected)

	if (actual_type == TYPE_FLOAT or actual_type == TYPE_INT) and (expected_type == TYPE_FLOAT or expected_type == TYPE_INT):
		cond = abs(float(actual) - float(expected)) <= tolerance
	elif actual_type == TYPE_VECTOR2 and expected_type == TYPE_VECTOR2:
		cond = (actual as Vector2).distance_to(expected as Vector2) <= tolerance
	elif actual_type == TYPE_VECTOR2I and expected_type == TYPE_VECTOR2I:
		cond = (Vector2(actual)).distance_to(Vector2(expected)) <= tolerance
	elif actual_type == TYPE_VECTOR3 and expected_type == TYPE_VECTOR3:
		cond = (actual as Vector3).distance_to(expected as Vector3) <= tolerance
	elif actual_type == TYPE_VECTOR3I and expected_type == TYPE_VECTOR3I:
		cond = (Vector3(actual)).distance_to(Vector3(expected)) <= tolerance
	elif actual_type == TYPE_VECTOR4 and expected_type == TYPE_VECTOR4:
		cond = (actual as Vector4).distance_to(expected as Vector4) <= tolerance
	elif actual_type == TYPE_COLOR and expected_type == TYPE_COLOR:
		var c1 = actual as Color
		var c2 = expected as Color
		cond = (abs(c1.r - c2.r) + abs(c1.g - c2.g) + abs(c1.b - c2.b) + abs(c1.a - c2.a)) <= tolerance * 4.0
	elif actual_type == TYPE_QUATERNION and expected_type == TYPE_QUATERNION:
		var q1 = actual as Quaternion
		var q2 = expected as Quaternion
		cond = (abs(q1.x - q2.x) + abs(q1.y - q2.y) + abs(q1.z - q2.z) + abs(q1.w - q2.w)) <= tolerance * 4.0
	elif actual_type == TYPE_TRANSFORM2D and expected_type == TYPE_TRANSFORM2D:
		var t1 = actual as Transform2D
		var t2 = expected as Transform2D
		cond = t1.origin.distance_to(t2.origin) <= tolerance and t1.x.distance_to(t2.x) <= tolerance and t1.y.distance_to(t2.y) <= tolerance
	elif actual_type == TYPE_TRANSFORM3D and expected_type == TYPE_TRANSFORM3D:
		var t1 = actual as Transform3D
		var t2 = expected as Transform3D
		cond = t1.origin.distance_to(t2.origin) <= tolerance and \
			   t1.basis.x.distance_to(t2.basis.x) <= tolerance and \
			   t1.basis.y.distance_to(t2.basis.y) <= tolerance and \
			   t1.basis.z.distance_to(t2.basis.z) <= tolerance
	else:
		cond = (actual == expected)

	var pos_msg = message if message != "" else ("Expected approx %s ± %f, got %s" % [str(expected), tolerance, str(actual)])
	var neg_msg = message if message != "" else ("Expected value NOT to be approx %s ± %f, got %s" % [str(expected), tolerance, str(actual)])
	return _evaluate(cond, pos_msg, neg_msg)

## Asserts that the container contains the given item, substring, or dictionary key/value.
func contains(expected_item: Variant, message: String = "") -> GDTestExpectation:
	var cond = false
	if actual is String or actual is StringName:
		cond = String(actual).contains(str(expected_item))
	elif actual is Array:
		cond = (actual as Array).has(expected_item)
	elif actual is Dictionary:
		var dict = actual as Dictionary
		cond = dict.has(expected_item) or dict.values().has(expected_item)
	elif actual is PackedByteArray or actual is PackedInt32Array or actual is PackedInt64Array or \
		 actual is PackedFloat32Array or actual is PackedFloat64Array or actual is PackedStringArray or \
		 actual is PackedVector2Array or actual is PackedVector3Array or actual is PackedColorArray:
		cond = Array(actual).has(expected_item)

	var pos_msg = message if message != "" else ("Expected container %s to contain '%s'" % [StructuralDiffer.format_value(actual), str(expected_item)])
	var neg_msg = message if message != "" else ("Expected container %s NOT to contain '%s'" % [StructuralDiffer.format_value(actual), str(expected_item)])
	return _evaluate(cond, pos_msg, neg_msg)

## Inverse of contains().
func does_not_contain(expected_item: Variant, message: String = "") -> GDTestExpectation:
	return not_().contains(expected_item, message)

## Asserts that the container or string has the expected element size or character length.
func has_size(expected_size: int, message: String = "") -> GDTestExpectation:
	var actual_sz = -1
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or \
	   actual is PackedByteArray or actual is PackedInt32Array or actual is PackedInt64Array or \
	   actual is PackedFloat32Array or actual is PackedFloat64Array or actual is PackedStringArray or \
	   actual is PackedVector2Array or actual is PackedVector3Array or actual is PackedColorArray:
		actual_sz = actual.size()

	var cond = (actual_sz == expected_size)
	var pos_msg = message if message != "" else ("Expected size %d, got size %d on %s" % [expected_size, actual_sz, StructuralDiffer.format_value(actual)])
	var neg_msg = message if message != "" else ("Expected size NOT to be %d on %s" % [expected_size, StructuralDiffer.format_value(actual)])
	return _evaluate(cond, pos_msg, neg_msg)

## Asserts that the container or string is empty (size == 0).
func is_empty(message: String = "") -> GDTestExpectation:
	var is_emp = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or \
	   actual is PackedByteArray or actual is PackedInt32Array or actual is PackedInt64Array or \
	   actual is PackedFloat32Array or actual is PackedFloat64Array or actual is PackedStringArray or \
	   actual is PackedVector2Array or actual is PackedVector3Array or actual is PackedColorArray:
		is_emp = actual.is_empty()

	var pos_msg = message if message != "" else ("Expected empty container, got %s" % StructuralDiffer.format_value(actual))
	var neg_msg = message if message != "" else "Expected non-empty container, got empty"
	return _evaluate(is_emp, pos_msg, neg_msg)

## Asserts that the container or string is not empty.
func is_not_empty(message: String = "") -> GDTestExpectation:
	var is_emp = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or \
	   actual is PackedByteArray or actual is PackedInt32Array or actual is PackedInt64Array or \
	   actual is PackedFloat32Array or actual is PackedFloat64Array or actual is PackedStringArray or \
	   actual is PackedVector2Array or actual is PackedVector3Array or actual is PackedColorArray:
		is_emp = actual.is_empty()

	var cond = not is_emp
	var pos_msg = message if message != "" else "Expected non-empty container, got empty"
	var neg_msg = message if message != "" else ("Expected empty container, got %s" % StructuralDiffer.format_value(actual))
	return _evaluate(cond, pos_msg, neg_msg)

## Asserts that the target Node is in the specified group.
func is_in_group(group_name: StringName, message: String = "") -> GDTestExpectation:
	var in_grp = false
	if actual is Node and is_instance_valid(actual):
		in_grp = (actual as Node).is_in_group(group_name)

	var node_name = actual.name if (actual is Node and is_instance_valid(actual)) else str(actual)
	var pos_msg = message if message != "" else ("Expected Node '%s' to be in group '%s'" % [node_name, group_name])
	var neg_msg = message if message != "" else ("Expected Node '%s' NOT to be in group '%s'" % [node_name, group_name])
	return _evaluate(in_grp, pos_msg, neg_msg)

## Asserts that the target string matches a regular expression pattern.
func matches_regex(pattern_or_regex: Variant, message: String = "") -> GDTestExpectation:
	var reg: RegEx = null
	if pattern_or_regex is RegEx:
		reg = pattern_or_regex
	elif pattern_or_regex is String:
		reg = RegEx.new()
		var err = reg.compile(pattern_or_regex)
		if err != OK:
			var fail_compile = "matches_regex: Invalid regex pattern '%s' (error code: %d)" % [pattern_or_regex, err]
			return _evaluate(false, fail_compile, fail_compile)
	else:
		return _evaluate(false, "matches_regex: Pattern must be String or RegEx", "matches_regex: Pattern must be String or RegEx")

	var matched = false
	if actual is String or actual is StringName:
		var result = reg.search(str(actual))
		matched = (result != null)

	var pos_msg = message if message != "" else ("Expected string '%s' to match regex '%s'" % [str(actual), reg.get_pattern()])
	var neg_msg = message if message != "" else ("Expected string '%s' NOT to match regex '%s'" % [str(actual), reg.get_pattern()])
	return _evaluate(matched, pos_msg, neg_msg)

# --- Numeric Comparison Matchers ---

func is_greater_than(expected: Variant, message: String = "") -> GDTestExpectation:
	var cond = actual > expected
	var pos_msg = message if message != "" else ("Expected %s > %s" % [str(actual), str(expected)])
	var neg_msg = message if message != "" else ("Expected %s <= %s" % [str(actual), str(expected)])
	return _evaluate(cond, pos_msg, neg_msg)

func is_gt(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_greater_than(expected, message)

func is_greater_than_or_equal_to(expected: Variant, message: String = "") -> GDTestExpectation:
	var cond = actual >= expected
	var pos_msg = message if message != "" else ("Expected %s >= %s" % [str(actual), str(expected)])
	var neg_msg = message if message != "" else ("Expected %s < %s" % [str(actual), str(expected)])
	return _evaluate(cond, pos_msg, neg_msg)

func is_gte(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_greater_than_or_equal_to(expected, message)

func is_less_than(expected: Variant, message: String = "") -> GDTestExpectation:
	var cond = actual < expected
	var pos_msg = message if message != "" else ("Expected %s < %s" % [str(actual), str(expected)])
	var neg_msg = message if message != "" else ("Expected %s >= %s" % [str(actual), str(expected)])
	return _evaluate(cond, pos_msg, neg_msg)

func is_lt(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_less_than(expected, message)

func is_less_than_or_equal_to(expected: Variant, message: String = "") -> GDTestExpectation:
	var cond = actual <= expected
	var pos_msg = message if message != "" else ("Expected %s <= %s" % [str(actual), str(expected)])
	var neg_msg = message if message != "" else ("Expected %s > %s" % [str(actual), str(expected)])
	return _evaluate(cond, pos_msg, neg_msg)

func is_lte(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_less_than_or_equal_to(expected, message)

func is_between(min_val: Variant, max_val: Variant, inclusive: bool = true, message: String = "") -> GDTestExpectation:
	var cond = (actual >= min_val and actual <= max_val) if inclusive else (actual > min_val and actual < max_val)
	var pos_msg = message if message != "" else ("Expected %s to be in range [%s, %s]" % [str(actual), str(min_val), str(max_val)])
	var neg_msg = message if message != "" else ("Expected %s NOT to be in range [%s, %s]" % [str(actual), str(min_val), str(max_val)])
	return _evaluate(cond, pos_msg, neg_msg)

# --- Type & Object Introspection Matchers ---

func to_be_instance_of(expected_class: Variant, message: String = "") -> GDTestExpectation:
	var cond = false
	if actual != null:
		cond = is_instance_of(actual, expected_class)
	var pos_msg = message if message != "" else ("Expected %s to be an instance of %s" % [StructuralDiffer.format_value(actual), str(expected_class)])
	var neg_msg = message if message != "" else ("Expected %s NOT to be an instance of %s" % [StructuralDiffer.format_value(actual), str(expected_class)])
	return _evaluate(cond, pos_msg, neg_msg)

func is_instance_of_class(expected_class: Variant, message: String = "") -> GDTestExpectation:
	return to_be_instance_of(expected_class, message)

func is_instance(expected_class: Variant, message: String = "") -> GDTestExpectation:
	return to_be_instance_of(expected_class, message)

func is_type(expected_type: int, message: String = "") -> GDTestExpectation:
	var cond = (typeof(actual) == expected_type)
	var pos_msg = message if message != "" else ("Expected type %s (%d), got type %s (%d)" % [
		StructuralDiffer._type_to_name(expected_type), expected_type,
		StructuralDiffer._type_to_name(typeof(actual)), typeof(actual)
	])
	var neg_msg = message if message != "" else ("Expected type NOT to be %s" % StructuralDiffer._type_to_name(expected_type))
	return _evaluate(cond, pos_msg, neg_msg)

func to_have_method(method_name: StringName, message: String = "") -> GDTestExpectation:
	var cond = (actual != null and actual is Object and is_instance_valid(actual) and (actual as Object).has_method(method_name))
	var pos_msg = message if message != "" else ("Expected object %s to have method '%s'" % [StructuralDiffer.format_value(actual), method_name])
	var neg_msg = message if message != "" else ("Expected object %s NOT to have method '%s'" % [StructuralDiffer.format_value(actual), method_name])
	return _evaluate(cond, pos_msg, neg_msg)

func to_have_signal(signal_name: StringName, message: String = "") -> GDTestExpectation:
	var cond = (actual != null and actual is Object and is_instance_valid(actual) and (actual as Object).has_signal(signal_name))
	var pos_msg = message if message != "" else ("Expected object %s to have signal '%s'" % [StructuralDiffer.format_value(actual), signal_name])
	var neg_msg = message if message != "" else ("Expected object %s NOT to have signal '%s'" % [StructuralDiffer.format_value(actual), signal_name])
	return _evaluate(cond, pos_msg, neg_msg)

func satisfies(predicate: Callable, message: String = "") -> GDTestExpectation:
	var cond = false
	if predicate.is_valid():
		cond = bool(predicate.call(actual))
	var pos_msg = message if message != "" else ("Expected value %s to satisfy custom predicate" % StructuralDiffer.format_value(actual))
	var neg_msg = message if message != "" else ("Expected value %s NOT to satisfy custom predicate" % StructuralDiffer.format_value(actual))
	return _evaluate(cond, pos_msg, neg_msg)

# --- BDD Aliases & Compatibility Helpers ---

var not_to: GDTestExpectation:
	get:
		return not_()

func to_equal(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_equal_to(expected, message)

func to_not_equal(unexpected: Variant, message: String = "") -> GDTestExpectation:
	return not_().is_equal_to(unexpected, message)

func to_be_null(message: String = "") -> GDTestExpectation:
	return is_null(message)

func to_not_be_null(message: String = "") -> GDTestExpectation:
	return is_not_null(message)

func to_be_true(message: String = "") -> GDTestExpectation:
	return is_true(message)

func to_be_false(message: String = "") -> GDTestExpectation:
	return is_false(message)

func to_be_approx(expected: Variant, tolerance: float = 0.001, message: String = "") -> GDTestExpectation:
	return is_approx(expected, tolerance, message)

func to_contain(element: Variant, message: String = "") -> GDTestExpectation:
	return contains(element, message)

func to_not_contain(element: Variant, message: String = "") -> GDTestExpectation:
	return does_not_contain(element, message)

func to_have_size(expected_size: int, message: String = "") -> GDTestExpectation:
	return has_size(expected_size, message)

func to_be_empty(message: String = "") -> GDTestExpectation:
	return is_empty(message)

func to_not_be_empty(message: String = "") -> GDTestExpectation:
	return is_not_empty(message)

func to_be_in_group(group_name: StringName, message: String = "") -> GDTestExpectation:
	return is_in_group(group_name, message)

func to_match_regex(pattern_or_regex: Variant, message: String = "") -> GDTestExpectation:
	return matches_regex(pattern_or_regex, message)

func to_be_greater_than(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_greater_than(expected, message)

func to_be_greater_than_or_equal(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_greater_than_or_equal_to(expected, message)

func to_be_less_than(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_less_than(expected, message)

func to_be_less_than_or_equal(expected: Variant, message: String = "") -> GDTestExpectation:
	return is_less_than_or_equal_to(expected, message)

func to_be_in_range(min_val: Variant, max_val: Variant, message: String = "") -> GDTestExpectation:
	return is_between(min_val, max_val, true, message)

func to_be_of_type(expected_type: int, message: String = "") -> GDTestExpectation:
	return is_type(expected_type, message)

