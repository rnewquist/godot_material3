# parameterized_runner.gd
# Parameterized test execution engine for GDTest 3.0.
# Provides table-driven (run_table) and Cartesian product matrix (run_matrix) runners
# with isolated sub-case execution, per-case reporting, and memory safety.
class_name GDTestParameterizedRunner
extends RefCounted

## Runs a table of test cases against a test callable.
## table_data can be:
## 1. Array[Dictionary]: [ {"input": 1, "expected": 2, "name": "case 1"}, ... ]
## 2. Array[Array]: [ ["header1", "header2"], [val1, val2], [val3, val4] ] or [ [1, 2], [3, 4] ]
## options:
## - "suite": GDTestSuite reference (for assertion tracking and auto-cleanup)
## - "stop_on_failure": bool (default false)
## - "before_case": Callable(params) (optional hook)
## - "after_case": Callable(params) (optional hook)
## - "name_prefix": String (optional subcase name prefix)
static func run_table(table_data: Variant, test_callable: Callable, options: Dictionary = {}) -> Dictionary:
	var suite: Object = options.get("suite", null)
	var stop_on_fail: bool = options.get("stop_on_failure", false)
	var before_case: Callable = options.get("before_case", Callable())
	var after_case: Callable = options.get("after_case", Callable())
	var name_prefix: String = options.get("name_prefix", "")

	var rows = _normalize_table_data(table_data)
	var total_cases = rows.size()
	var passed_cases = 0
	var failed_cases = 0
	var case_results: Array[Dictionary] = []

	var start_suite_fails = 0
	if suite and "fail_count" in suite:
		start_suite_fails = suite.fail_count

	for i in range(total_cases):
		var row_params = rows[i]
		var case_name = _build_case_name(row_params, i, name_prefix)
		var case_start_ms = Time.get_ticks_msec()
		var case_start_fails = 0
		if suite and "fail_count" in suite:
			case_start_fails = suite.fail_count

		# Run before hook
		if before_case.is_valid():
			await before_case.call(row_params)

		# Execute the test callable
		var call_error = ""
		var case_passed = true

		if test_callable.is_valid():
			var arg_count = test_callable.get_argument_count()
			if arg_count == 1 or arg_count == -1:
				await test_callable.call(row_params)
			elif arg_count > 1 and row_params is Array:
				await test_callable.callv(row_params)
			elif arg_count > 1 and row_params is Dictionary:
				var vals = (row_params as Dictionary).values()
				await test_callable.callv(vals)
			else:
				await test_callable.call(row_params)
		else:
			call_error = "Invalid test callable provided to run_table"
			if suite and suite.has_method("_record_failure"):
				suite._record_failure(call_error)

		# Run after hook
		if after_case.is_valid():
			await after_case.call(row_params)

		# Check failure status
		if suite and "fail_count" in suite:
			case_passed = (suite.fail_count == case_start_fails) and (call_error == "")
		else:
			case_passed = (call_error == "")

		# Cleanup per subcase if suite provides cleanup
		if suite:
			if suite.has_method("_cleanup_auto_free_nodes"):
				suite._cleanup_auto_free_nodes()
			if "teardown_stack" in suite and suite.teardown_stack != null:
				if suite.teardown_stack.has_method("execute_all"):
					await suite.teardown_stack.execute_all()

		var duration = Time.get_ticks_msec() - case_start_ms
		if case_passed:
			passed_cases += 1
			print("    🔹 [SUBCASE %d/%d] '%s' PASSED (%d ms)" % [i + 1, total_cases, case_name, duration])
		else:
			failed_cases += 1
			print("    ❌ [SUBCASE %d/%d] '%s' FAILED (%d ms)" % [i + 1, total_cases, case_name, duration])

		case_results.append({
			"index": i,
			"name": case_name,
			"params": row_params,
			"passed": case_passed,
			"duration_ms": duration,
			"error": call_error
		})

		if not case_passed and stop_on_fail:
			break

	var summary = {
		"total_cases": total_cases,
		"passed_cases": passed_cases,
		"failed_cases": failed_cases,
		"all_passed": (failed_cases == 0),
		"cases": case_results
	}

	return summary

## Runs a Cartesian product matrix of parameters against a test callable.
## dimensions is a Dictionary where each key maps to an Array of values.
## Example:
##   dimensions = {
##     "weapon": ["sword", "bow"],
##     "tier": [1, 2],
##     "enchanted": [true, false]
##   }
## Generates 2 * 2 * 2 = 8 combinations and runs each as an isolated sub-case.
static func run_matrix(dimensions: Dictionary, test_callable: Callable, options: Dictionary = {}) -> Dictionary:
	var combinations = cartesian_product(dimensions)
	return await run_table(combinations, test_callable, options)

## Generates an Array of Dictionaries representing all Cartesian product combinations of dimensions.
static func cartesian_product(dimensions: Dictionary) -> Array[Dictionary]:
	var keys = dimensions.keys()
	if keys.is_empty():
		return []

	var results: Array[Dictionary] = [{}]

	for key in keys:
		var raw_values = dimensions[key]
		var values: Array = []
		if raw_values is Array:
			values = raw_values
		else:
			values = [raw_values]

		var next_results: Array[Dictionary] = []
		for existing_dict in results:
			for val in values:
				var new_dict = existing_dict.duplicate()
				new_dict[key] = val
				next_results.append(new_dict)
		results = next_results

	return results

# --- Internal Helper Methods ---

static func _normalize_table_data(data: Variant) -> Array:
	if data == null:
		return []

	if data is Array:
		var arr = data as Array
		if arr.is_empty():
			return []

		# Check if table format with headers: first element is Array of Strings
		if arr[0] is Array and arr.size() > 1:
			var first_row = arr[0] as Array
			var is_header = true
			for item in first_row:
				if item is not String and item is not StringName:
					is_header = false
					break

			if is_header:
				var headers = first_row
				var dict_rows: Array[Dictionary] = []
				for r_idx in range(1, arr.size()):
					var row_data = arr[r_idx]
					var row_dict: Dictionary = {}
					if row_data is Array:
						for c_idx in range(headers.size()):
							var h = str(headers[c_idx])
							var v = row_data[c_idx] if c_idx < row_data.size() else null
							row_dict[h] = v
					else:
						row_dict[str(headers[0])] = row_data
					dict_rows.append(row_dict)
				return dict_rows

		return arr

	return [data]

static func _build_case_name(params: Variant, index: int, prefix: String) -> String:
	var name_str = ""
	if params is Dictionary:
		var dict = params as Dictionary
		if dict.has("name"):
			name_str = str(dict["name"])
		elif dict.has("case_name"):
			name_str = str(dict["case_name"])
		elif dict.has("description"):
			name_str = str(dict["description"])
		elif dict.has("title"):
			name_str = str(dict["title"])
		elif dict.has("id"):
			name_str = "id=%s" % str(dict["id"])
		else:
			var parts: Array[String] = []
			for k in dict.keys():
				parts.append("%s=%s" % [str(k), _short_str(dict[k])])
			name_str = ", ".join(parts)
	elif params is Array:
		var parts: Array[String] = []
		for item in params:
			parts.append(_short_str(item))
		name_str = "[%s]" % ", ".join(parts)
	else:
		name_str = _short_str(params)

	var case_label = ("%s[%d]: %s" % [prefix, index, name_str]) if prefix != "" else ("case_%d (%s)" % [index, name_str])
	return case_label

static func _short_str(v: Variant) -> String:
	if v == null:
		return "null"
	var s = str(v)
	if s.length() > 30:
		return s.substr(0, 27) + "..."
	return s
