# mock_verifier.gd
# Verification engine for method invocations, call counts, and argument payloads on GDTest 3.0 mocks and spies.
class_name MockVerifier
extends RefCounted

const SENTINEL_ARG: String = "__GDTEST_UNSPECIFIED_ARG_SENTINEL__"

var proxy: RefCounted = null
var target_method: StringName = &""
var suite_ref: Node = null

## Asserts that the target method was called exactly expected_count times.
func times(expected_count: int, message: String = "") -> bool:
	var actual_count = 0
	if proxy and proxy.has_method("get_call_count"):
		actual_count = proxy.get_call_count(target_method)
		
	var passed = (actual_count == expected_count)
	var err_msg = message if message != "" else "Expected method '%s' to be called %d times, but was called %d times" % [
		target_method,
		expected_count,
		actual_count
	]
	return _record_assertion(passed, err_msg)

## Asserts that the target method was never called (0 times).
func never(message: String = "") -> bool:
	return times(0, message if message != "" else "Expected method '%s' never to be called" % target_method)

## Asserts that the target method was called at least once.
func was_called(message: String = "") -> bool:
	var actual_count = 0
	if proxy and proxy.has_method("get_call_count"):
		actual_count = proxy.get_call_count(target_method)
		
	var passed = (actual_count > 0)
	var err_msg = message if message != "" else "Expected method '%s' to have been called at least once, but call count was 0" % target_method
	return _record_assertion(passed, err_msg)

## Asserts that the target method was called at least min_times.
func at_least(min_times: int, message: String = "") -> bool:
	var actual_count = 0
	if proxy and proxy.has_method("get_call_count"):
		actual_count = proxy.get_call_count(target_method)
		
	var passed = (actual_count >= min_times)
	var err_msg = message if message != "" else "Expected method '%s' to be called at least %d times, but was called %d times" % [
		target_method,
		min_times,
		actual_count
	]
	return _record_assertion(passed, err_msg)

## Asserts that the target method was called at most max_times.
func at_most(max_times: int, message: String = "") -> bool:
	var actual_count = 0
	if proxy and proxy.has_method("get_call_count"):
		actual_count = proxy.get_call_count(target_method)
		
	var passed = (actual_count <= max_times)
	var err_msg = message if message != "" else "Expected method '%s' to be called at most %d times, but was called %d times" % [
		target_method,
		max_times,
		actual_count
	]
	return _record_assertion(passed, err_msg)

## Asserts that the target method was invoked at least once with the specified positional arguments.
func was_called_with(
	arg0: Variant = SENTINEL_ARG,
	arg1: Variant = SENTINEL_ARG,
	arg2: Variant = SENTINEL_ARG,
	arg3: Variant = SENTINEL_ARG,
	arg4: Variant = SENTINEL_ARG,
	arg5: Variant = SENTINEL_ARG,
	arg6: Variant = SENTINEL_ARG,
	arg7: Variant = SENTINEL_ARG
) -> bool:
	var args_to_match = _extract_varargs([arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7])
	return was_called_with_args(args_to_match)

## Asserts that the target method was invoked at least once with the exact array of arguments.
func was_called_with_args(expected_args: Array, message: String = "") -> bool:
	var matched = false
	if proxy and proxy.has_method("has_call_with_args"):
		matched = proxy.has_call_with_args(target_method, expected_args)
		
	var err_msg = message if message != "" else "Expected method '%s' to have been called with arguments %s" % [
		target_method,
		str(expected_args)
	]
	return _record_assertion(matched, err_msg)

## Asserts that the target method was NEVER invoked with the specified positional arguments.
func never_called_with(
	arg0: Variant = SENTINEL_ARG,
	arg1: Variant = SENTINEL_ARG,
	arg2: Variant = SENTINEL_ARG,
	arg3: Variant = SENTINEL_ARG,
	arg4: Variant = SENTINEL_ARG,
	arg5: Variant = SENTINEL_ARG,
	arg6: Variant = SENTINEL_ARG,
	arg7: Variant = SENTINEL_ARG
) -> bool:
	var args_to_match = _extract_varargs([arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7])
	return never_called_with_args(args_to_match)

## Asserts that the target method was NEVER invoked with the exact array of arguments.
func never_called_with_args(unexpected_args: Array, message: String = "") -> bool:
	var matched = false
	if proxy and proxy.has_method("has_call_with_args"):
		matched = proxy.has_call_with_args(target_method, unexpected_args)
		
	var passed = not matched
	var err_msg = message if message != "" else "Expected method '%s' NEVER to have been called with arguments %s" % [
		target_method,
		str(unexpected_args)
	]
	return _record_assertion(passed, err_msg)

func _extract_varargs(args_list: Array) -> Array:
	var result: Array = []
	for arg in args_list:
		if typeof(arg) == TYPE_STRING and arg == SENTINEL_ARG:
			break
		result.append(arg)
	return result

func _record_assertion(passed: bool, failure_message: String) -> bool:
	if suite_ref and is_instance_valid(suite_ref):
		if passed:
			if suite_ref.has_method("_record_pass"):
				suite_ref._record_pass()
		else:
			if suite_ref.has_method("_record_failure"):
				suite_ref._record_failure(failure_message)
	return passed
