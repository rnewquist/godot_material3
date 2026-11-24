# expectation.gd
# Fluent assertion builder for GDTest 3.0.
class_name Expectation
extends RefCounted

var actual: Variant
var suite: Node = null
var is_negated: bool = false
var custom_message: String = ""

func _init(p_actual: Variant = null, p_suite: Node = null, p_negated: bool = false, p_msg: String = "") -> void:
	actual = p_actual
	suite = p_suite
	is_negated = p_negated
	custom_message = p_msg

## Returns an inverted Expectation builder.
var not_to:
	get:
		return get_script().new(actual, suite, not is_negated, custom_message)

## Inverts assertion logic via method call.
func not_():
	return get_script().new(actual, suite, not is_negated, custom_message)

## Attaches a custom failure message prefix.
func with_message(message: String):
	custom_message = message
	return self

## Asserts actual equals expected.
func to_equal(expected: Variant, message: String = "") -> bool:
	var cond = (actual == expected)
	var pass_m = "Expected value NOT to equal '%s'" % str(expected)
	var fail_m = message if message != "" else "Expected '%s' (type %s), got '%s' (type %s)" % [
		str(expected), typeof(expected), str(actual), typeof(actual)
	]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual does not equal unexpected.
func to_not_equal(unexpected: Variant, message: String = "") -> bool:
	var cond = (actual != unexpected)
	var pass_m = "Expected value to equal '%s'" % str(unexpected)
	var fail_m = message if message != "" else "Expected value NOT to equal '%s'" % str(unexpected)
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual is null.
func to_be_null(message: String = "") -> bool:
	var cond = (actual == null)
	var pass_m = "Expected value NOT to be null"
	var fail_m = message if message != "" else "Expected null, got '%s'" % str(actual)
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual is not null.
func to_not_be_null(message: String = "") -> bool:
	var cond = (actual != null)
	var pass_m = "Expected value to be null"
	var fail_m = message if message != "" else "Expected non-null value, got null"
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual is boolean true.
func to_be_true(message: String = "") -> bool:
	var cond = (actual == true)
	var pass_m = "Expected value NOT to be true"
	var fail_m = message if message != "" else "Expected true, got false (%s)" % str(actual)
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual is boolean false.
func to_be_false(message: String = "") -> bool:
	var cond = (actual == false)
	var pass_m = "Expected value NOT to be false"
	var fail_m = message if message != "" else "Expected false, got true (%s)" % str(actual)
	return _evaluate(cond, pass_m, fail_m)

## Asserts float or vector approx equality within tolerance.
func to_be_approx(expected: Variant, tolerance: float = 0.001, message: String = "") -> bool:
	var cond = false
	if actual is float or actual is int:
		cond = abs(float(actual) - float(expected)) <= tolerance
	elif actual is Vector2 and expected is Vector2:
		cond = actual.distance_to(expected) <= tolerance
	elif actual is Vector3 and expected is Vector3:
		cond = actual.distance_to(expected) <= tolerance
	elif actual is Vector4 and expected is Vector4:
		cond = actual.distance_to(expected) <= tolerance
	elif actual is Color and expected is Color:
		var diff = abs(actual.r - expected.r) + abs(actual.g - expected.g) + abs(actual.b - expected.b) + abs(actual.a - expected.a)
		cond = diff <= tolerance * 4.0
	elif actual is Transform2D and expected is Transform2D:
		cond = actual.origin.distance_to(expected.origin) <= tolerance
	elif actual is Transform3D and expected is Transform3D:
		cond = actual.origin.distance_to(expected.origin) <= tolerance
		
	var pass_m = "Expected value NOT to approximate '%s'" % str(expected)
	var fail_m = message if message != "" else "Expected '%s' ± %f, got '%s'" % [str(expected), tolerance, str(actual)]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual float is in range [min_val, max_val].
func to_be_in_range(min_val: float, max_val: float, message: String = "") -> bool:
	var num = float(actual)
	var cond = (num >= min_val and num <= max_val)
	var pass_m = "Expected %f NOT to be in range [%f, %f]" % [num, min_val, max_val]
	var fail_m = message if message != "" else "Expected %f to be in range [%f, %f]" % [num, min_val, max_val]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual > expected.
func to_be_greater_than(expected: float, message: String = "") -> bool:
	var cond = (float(actual) > expected)
	var pass_m = "Expected %f NOT > %f" % [float(actual), expected]
	var fail_m = message if message != "" else "Expected %f > %f" % [float(actual), expected]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual >= expected.
func to_be_greater_than_or_equal(expected: float, message: String = "") -> bool:
	var cond = (float(actual) >= expected)
	var pass_m = "Expected %f NOT >= %f" % [float(actual), expected]
	var fail_m = message if message != "" else "Expected %f >= %f" % [float(actual), expected]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual < expected.
func to_be_less_than(expected: float, message: String = "") -> bool:
	var cond = (float(actual) < expected)
	var pass_m = "Expected %f NOT < %f" % [float(actual), expected]
	var fail_m = message if message != "" else "Expected %f < %f" % [float(actual), expected]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual <= expected.
func to_be_less_than_or_equal(expected: float, message: String = "") -> bool:
	var cond = (float(actual) <= expected)
	var pass_m = "Expected %f NOT <= %f" % [float(actual), expected]
	var fail_m = message if message != "" else "Expected %f <= %f" % [float(actual), expected]
	return _evaluate(cond, pass_m, fail_m)

## Asserts container contains element or string contains substring.
func to_contain(element: Variant, message: String = "") -> bool:
	var cond = false
	if actual is String or actual is StringName:
		cond = str(actual).contains(str(element))
	elif actual is Array:
		cond = actual.has(element)
	elif actual is Dictionary:
		cond = actual.has(element)
	elif _is_packed_array(actual):
		cond = actual.has(element)
		
	var pass_m = "Expected container NOT to contain '%s'" % str(element)
	var fail_m = message if message != "" else "Expected container %s to contain '%s'" % [str(actual), str(element)]
	return _evaluate(cond, pass_m, fail_m)

## Asserts container does NOT contain element.
func to_not_contain(element: Variant, message: String = "") -> bool:
	var cond = false
	if actual is String or actual is StringName:
		cond = not str(actual).contains(str(element))
	elif actual is Array:
		cond = not actual.has(element)
	elif actual is Dictionary:
		cond = not actual.has(element)
	elif _is_packed_array(actual):
		cond = not actual.has(element)
		
	var pass_m = "Expected container to contain '%s'" % str(element)
	var fail_m = message if message != "" else "Expected container %s NOT to contain '%s'" % [str(actual), str(element)]
	return _evaluate(cond, pass_m, fail_m)

## Asserts container or string is empty.
func to_be_empty(message: String = "") -> bool:
	var cond = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or _is_packed_array(actual):
		cond = actual.is_empty()
	var pass_m = "Expected container NOT to be empty"
	var fail_m = message if message != "" else "Expected empty container, got %s" % str(actual)
	return _evaluate(cond, pass_m, fail_m)

## Asserts container or string is NOT empty.
func to_not_be_empty(message: String = "") -> bool:
	var cond = false
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or _is_packed_array(actual):
		cond = not actual.is_empty()
	var pass_m = "Expected container to be empty"
	var fail_m = message if message != "" else "Expected non-empty container, got empty"
	return _evaluate(cond, pass_m, fail_m)

## Asserts container or string has exact size.
func to_have_size(expected_size: int, message: String = "") -> bool:
	var sz = 0
	if actual is Array or actual is Dictionary or actual is String or actual is StringName or _is_packed_array(actual):
		sz = actual.size()
	var cond = (sz == expected_size)
	var pass_m = "Expected size NOT to equal %d" % expected_size
	var fail_m = message if message != "" else "Expected size %d, got %d" % [expected_size, sz]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual typeof equals expected Variant.Type.
func to_be_of_type(expected_type: int, message: String = "") -> bool:
	var cond = (typeof(actual) == expected_type)
	var pass_m = "Expected type NOT to equal %d" % expected_type
	var fail_m = message if message != "" else "Expected type %d, got %d" % [expected_type, typeof(actual)]
	return _evaluate(cond, pass_m, fail_m)

## Asserts actual is instance of class.
func to_be_instance_of(expected_class: Variant, message: String = "") -> bool:
	var cond = false
	if actual is Object and is_instance_valid(actual):
		cond = is_instance_of(actual, expected_class)
	var pass_m = "Expected object NOT to be instance of %s" % str(expected_class)
	var fail_m = message if message != "" else "Expected object %s to be instance of %s" % [str(actual), str(expected_class)]
	return _evaluate(cond, pass_m, fail_m)

## Asserts string begins with prefix.
func to_begin_with(prefix: String, message: String = "") -> bool:
	var cond = str(actual).begins_with(prefix)
	var pass_m = "Expected string NOT to begin with '%s'" % prefix
	var fail_m = message if message != "" else "Expected string '%s' to begin with '%s'" % [str(actual), prefix]
	return _evaluate(cond, pass_m, fail_m)

## Asserts string ends with suffix.
func to_end_with(suffix: String, message: String = "") -> bool:
	var cond = str(actual).ends_with(suffix)
	var pass_m = "Expected string NOT to end with '%s'" % suffix
	var fail_m = message if message != "" else "Expected string '%s' to end with '%s'" % [str(actual), suffix]
	return _evaluate(cond, pass_m, fail_m)

## Asserts string matches regex pattern.
func to_match_regex(pattern: String, message: String = "") -> bool:
	var regex = RegEx.new()
	var err = regex.compile(pattern)
	var cond = false
	if err == OK:
		var res = regex.search(str(actual))
		cond = (res != null)
	var pass_m = "Expected string NOT to match regex '%s'" % pattern
	var fail_m = message if message != "" else "Expected string '%s' to match regex '%s'" % [str(actual), pattern]
	return _evaluate(cond, pass_m, fail_m)

func _is_packed_array(val: Variant) -> bool:
	return val is PackedByteArray or val is PackedInt32Array or val is PackedInt64Array or \
		val is PackedFloat32Array or val is PackedFloat64Array or val is PackedStringArray or \
		val is PackedVector2Array or val is PackedVector3Array or val is PackedVector4Array or \
		val is PackedColorArray

func _evaluate(cond: bool, pass_msg: String, fail_msg: String) -> bool:
	var passed = not cond if is_negated else cond
	var base_msg = pass_msg if is_negated else fail_msg
	var err = ("[%s] %s" % [custom_message, base_msg]) if custom_message != "" else base_msg
	
	if suite and is_instance_valid(suite):
		if passed:
			if suite.has_method("_record_pass"):
				suite._record_pass()
		else:
			if suite.has_method("_record_failure"):
				suite._record_failure(err)
	return passed
