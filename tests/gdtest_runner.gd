extends SceneTree

## Headless CLI test runner for GDTest 3.0.
## Discovers all test suites in res://tests/, executes test methods, tracks assertions, and reports results.

const GDTestSuiteScript = preload("res://addons/gdtest/core/test_suite.gd")

const COLOR_RESET: String = "\u001b[0m"
const COLOR_RED: String = "\u001b[31m"
const COLOR_GREEN: String = "\u001b[32m"
const COLOR_YELLOW: String = "\u001b[33m"
const COLOR_CYAN: String = "\u001b[36m"
const COLOR_BOLD: String = "\u001b[1m"

var total_suites: int = 0
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var total_assertions: int = 0

func _init() -> void:
	_run_all_tests.call_deferred()

func _run_all_tests() -> void:
	var start_time: int = Time.get_ticks_msec()
	print("\n%s%s==================================================%s" % [COLOR_CYAN, COLOR_BOLD, COLOR_RESET])
	print("%s%s  GDTest 3.0 Test Runner (Headless CLI)%s" % [COLOR_CYAN, COLOR_BOLD, COLOR_RESET])
	print("%s%s==================================================%s\n" % [COLOR_CYAN, COLOR_BOLD, COLOR_RESET])

	var test_files: Array[String] = _discover_test_files("res://tests")

	if test_files.is_empty():
		print("%sWarning: No test files found in res://tests%s\n" % [COLOR_YELLOW, COLOR_RESET])
		quit(0)
		return

	for file_path in test_files:
		await _run_test_file(file_path)

	var elapsed_ms: int = Time.get_ticks_msec() - start_time
	_print_summary(elapsed_ms)

	var exit_code: int = 0 if failed_tests == 0 else 1
	quit(exit_code)

func _discover_test_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return files

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with(".") and file_name != "gss":
			var sub_files: Array[String] = _discover_test_files(dir_path.path_join(file_name))
			files.append_array(sub_files)
		elif file_name.ends_with(".gd"):
			var base: String = file_name.get_basename()
			# Exclude runner itself
			if file_name != "gdtest_runner.gd" and file_name != "test_runner.gd" and (base.begins_with("test_") or base.ends_with("_test")):
				files.append(dir_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files

func _run_test_file(file_path: String) -> void:
	var script_res = load(file_path)
	if script_res == null or not (script_res is GDScript) or not script_res.can_instantiate():
		return

	var suite_obj: Object = script_res.new()
	if not (suite_obj is GDTestSuiteScript):
		if suite_obj is Node:
			suite_obj.free()
		return

	total_suites += 1
	print("%s%s[SUITE] %s%s" % [COLOR_CYAN, COLOR_BOLD, file_path, COLOR_RESET])

	var suite: Node = suite_obj as Node
	root.add_child(suite)

	# Discover test methods
	var test_methods: Array[String] = []
	for method_info: Dictionary in suite.get_method_list():
		var m_name: String = method_info["name"]
		if m_name.begins_with("test_"):
			test_methods.append(m_name)
	test_methods.sort()

	# Hook before_all
	await suite.before_all()

	for m_name in test_methods:
		total_tests += 1
		suite.set("current_test_name", m_name)
		var prev_fails: int = suite.get("test_fail_count")
		var prev_passes: int = suite.get("test_pass_count")

		# Hook before_each
		await suite.before_each()

		# Run test method
		var test_start: int = Time.get_ticks_msec()
		await suite.call(m_name)
		var test_duration: int = Time.get_ticks_msec() - test_start

		# Hook after_each
		await suite.after_each()

		suite.call("cleanup_nodes")

		var current_fails: int = suite.get("test_fail_count")
		var current_passes: int = suite.get("test_pass_count")
		var test_had_fail: bool = current_fails > prev_fails
		var assertions_in_test: int = (current_passes - prev_passes) + (current_fails - prev_fails)
		total_assertions += assertions_in_test

		if test_had_fail:
			failed_tests += 1
			print("  %s✗ %s (%d ms)%s" % [COLOR_RED, m_name, test_duration, COLOR_RESET])
			var failures_arr: Array = suite.get("failures")
			for f in failures_arr:
				if f is Dictionary and f.get("test", "") == m_name:
					print("    %s↳ %s%s" % [COLOR_RED, f.get("message", ""), COLOR_RESET])
		else:
			passed_tests += 1
			print("  %s✓ %s (%d ms)%s" % [COLOR_GREEN, m_name, test_duration, COLOR_RESET])

	# Hook after_all
	await suite.after_all()

	root.remove_child(suite)
	suite.free()
	print("")

func _is_async(val: Variant) -> bool:
	return val is Signal

func _print_summary(elapsed_ms: int) -> void:
	print("%s--------------------------------------------------%s" % [COLOR_BOLD, COLOR_RESET])
	print("%sSummary:%s" % [COLOR_BOLD, COLOR_RESET])
	print("  Suites:     %d" % total_suites)
	print("  Tests:      %d total, %s%d passed%s, %s%d failed%s" % [
		total_tests,
		COLOR_GREEN if passed_tests > 0 else "", passed_tests, COLOR_RESET,
		COLOR_RED if failed_tests > 0 else "", failed_tests, COLOR_RESET
	])
	print("  Assertions: %d" % total_assertions)
	print("  Duration:   %.2f seconds" % (float(elapsed_ms) / 1000.0))

	if failed_tests == 0:
		print("\n%s%s🎉 ALL TESTS PASSED!%s\n" % [COLOR_GREEN, COLOR_BOLD, COLOR_RESET])
	else:
		print("\n%s%s❌ SOME TESTS FAILED.%s\n" % [COLOR_RED, COLOR_BOLD, COLOR_RESET])
