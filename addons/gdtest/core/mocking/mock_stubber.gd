# mock_stubber.gd
# Fluent stub configuration builder and executor for GDTest 3.0 mocking.
class_name MockStubber
extends RefCounted

const SENTINEL_DEFAULT: String = "__GDTEST_DEFAULT_ARG_SENTINEL__"

var target_method: StringName = &""
var return_value: Variant = null
var has_custom_return: bool = false

var return_values_sequence: Array = []
var sequence_index: int = 0
var has_sequence: bool = false

var custom_callable: Callable = Callable()
var has_custom_callable: bool = false

var side_effect_callable: Callable = Callable()
var has_side_effect: bool = false

var expected_args: Array = []
var match_args: bool = false

## Configures the stub to return a fixed value when invoked.
func to_return(value: Variant) -> MockStubber:
	return_value = value
	has_custom_return = true
	has_sequence = false
	has_custom_callable = false
	return self

## Configures the stub to return sequential values from an array across subsequent invocations.
func to_return_values(values: Array) -> MockStubber:
	return_values_sequence = values.duplicate()
	sequence_index = 0
	has_sequence = true
	has_custom_return = false
	has_custom_callable = false
	return self

## Configures the stub to invoke a custom Callable and return its result.
func to_call(callable: Callable) -> MockStubber:
	custom_callable = callable
	has_custom_callable = true
	has_custom_return = false
	has_sequence = false
	return self

## Attaches a side-effect Callable executed upon invocation without overriding the return value.
func and_do(callable: Callable) -> MockStubber:
	side_effect_callable = callable
	has_side_effect = true
	return self

## Restricts this stub to only match calls made with the exact arguments provided.
func with_args(args: Array) -> MockStubber:
	expected_args = args
	match_args = true
	return self

## Checks whether this stub matches the specified method name and runtime arguments.
func matches_invocation(method: StringName, args: Array) -> bool:
	if target_method != &"" and target_method != method:
		return false
	if match_args:
		if expected_args.size() != args.size():
			return false
		for i in range(expected_args.size()):
			if expected_args[i] != args[i]:
				return false
	return true

## Executes the stub logic given the passed call arguments and returns the result.
func execute(args: Array) -> Variant:
	if has_side_effect and side_effect_callable.is_valid():
		side_effect_callable.callv(args)
		
	if has_custom_callable and custom_callable.is_valid():
		return custom_callable.callv(args)
		
	if has_sequence and not return_values_sequence.is_empty():
		var idx = mini(sequence_index, return_values_sequence.size() - 1)
		var val = return_values_sequence[idx]
		sequence_index += 1
		return val
		
	if has_custom_return:
		return return_value
		
	return null
