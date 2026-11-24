# mock_proxy.gd
# Core interception and tracking engine for GDTest 3.0 mocks and spies.
class_name MockProxy
extends RefCounted

const MockStubber = preload("res://addons/gdtest/core/mocking/mock_stubber.gd")

var target_instance: Object = null
var target_class_name: String = ""
var is_spy: bool = false
var call_history: Array[Dictionary] = []
var stubs: Array = []
var suite_ref: Node = null

## Dispatches an intercepted method call, matching stubs or delegating to the spied instance.
func dispatch_call(method: StringName, args: Array = []) -> Variant:
	# 1. Check specific argument-matching stubs first (last defined takes precedence)
	for i in range(stubs.size() - 1, -1, -1):
		var stub = stubs[i]
		if stub.match_args and stub.matches_invocation(method, args):
			var res = stub.execute(args)
			_record_call(method, args, res)
			return res

	# 2. Check general (no argument filter) stubs next (last defined takes precedence)
	for i in range(stubs.size() - 1, -1, -1):
		var stub = stubs[i]
		if not stub.match_args and stub.matches_invocation(method, args):
			var res = stub.execute(args)
			_record_call(method, args, res)
			return res
			
	# If this proxy is spying on a real instance, delegate call to real object
	if is_spy and target_instance and is_instance_valid(target_instance):
		var res = null
		if target_instance.has_method(method):
			res = target_instance.callv(method, args)
		_record_call(method, args, res)
		return res
		
	# Default mock fallback
	_record_call(method, args, null)
	return null

## Registers a stub configuration with this mock proxy.
func add_stub(stub: RefCounted) -> void:
	stubs.append(stub)

## Returns the total number of calls matching method name, or all calls if method is empty.
func get_call_count(method: StringName = &"") -> int:
	if method == &"":
		return call_history.size()
	var count = 0
	for entry in call_history:
		if entry["method"] == method:
			count += 1
	return count

## Returns all call records matching the method name (or all calls if method is empty).
func get_calls(method: StringName = &"") -> Array[Dictionary]:
	if method == &"":
		return call_history.duplicate()
	var result: Array[Dictionary] = []
	for entry in call_history:
		if entry["method"] == method:
			result.append(entry)
	return result

## Returns the most recent call record for the specified method, or empty dictionary.
func get_last_call(method: StringName = &"") -> Dictionary:
	var matching = get_calls(method)
	if matching.is_empty():
		return {}
	return matching[-1]

## Checks whether the specified method was invoked with the exact arguments provided.
func has_call_with_args(method: StringName, expected_args: Array) -> bool:
	for entry in call_history:
		if entry["method"] == method:
			var actual_args: Array = entry["args"]
			if _arrays_equal(actual_args, expected_args):
				return true
	return false

## Clears the recorded invocation history while preserving registered stubs.
func clear_history() -> void:
	call_history.clear()

## Clears both recorded invocation history and all registered stubs.
func reset_mock() -> void:
	call_history.clear()
	stubs.clear()

func _record_call(method: StringName, args: Array, return_val: Variant) -> void:
	call_history.append({
		"method": method,
		"args": args.duplicate(),
		"return_value": return_val,
		"timestamp_usec": Time.get_ticks_usec()
	})

func _arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true
