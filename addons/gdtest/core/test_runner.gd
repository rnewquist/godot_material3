# test_runner.gd
# Universal engine-native test runner for executing GDTestSuite batches.
# Features automatic recursive test suite discovery in res://tests/ and CLI filter arguments.
class_name GDTestRunner
extends Node

const GDTestSuite = preload("res://addons/gdtest/core/test_suite.gd")
const MockFactory = preload("res://addons/gdtest/core/mocking/mock_factory.gd")

@export var exit_on_finish: bool = true
@export var output_json_path: String = "res://artifacts/test_results.json"
@export var output_junit_path: String = "res://artifacts/junit_report.xml"
@export var output_manifest_path: String = "res://artifacts/audit_manifest.json"
@export var tests_directory: String = "res://tests/"

var suite_classes_or_scenes: Array = []
var run_start_time: int = 0
var total_suites: int = 0
var passed_suites: int = 0
var failed_suites: int = 0
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var total_assertions: int = 0
var suite_results: Array[Dictionary] = []
var all_checkpoints: Array[Dictionary] = []
var _is_shutting_down: bool = false

# Filtering
var filter_suite_name: String = ""
var filter_test_method: String = ""
var filter_test_type: String = "" # "unit", "integration", "audit"

func _ready() -> void:
	var conf_tests_dir = ProjectSettings.get_setting("gdtest/config/tests_directory", "res://tests/")
	if conf_tests_dir != "":
		tests_directory = conf_tests_dir
		
	var conf_artifacts_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts")
	if conf_artifacts_dir != "":
		output_json_path = conf_artifacts_dir.path_join("test_results.json")
		output_junit_path = conf_artifacts_dir.path_join("junit_report.xml")
		output_manifest_path = conf_artifacts_dir.path_join("audit_manifest.json")
		
	DirAccess.make_dir_recursive_absolute(conf_artifacts_dir)
	DirAccess.make_dir_recursive_absolute(conf_artifacts_dir.path_join("checkpoints"))
		
	_parse_cli_arguments()
	call_deferred("discover_and_run")

func _parse_cli_arguments() -> void:
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--suite="):
			filter_suite_name = arg.trim_prefix("--suite=").strip_edges()
		elif arg.begins_with("--test=") or arg.begins_with("--method="):
			filter_test_method = arg.trim_prefix("--test=").trim_prefix("--method=").strip_edges()
		elif arg.begins_with("--type=") or arg.begins_with("--tier="):
			filter_test_type = arg.trim_prefix("--type=").trim_prefix("--tier=").strip_edges().to_lower()
		elif arg.begins_with("--dir="):
			tests_directory = arg.trim_prefix("--dir=").strip_edges()

func register_suite(suite_ref: Variant) -> void:
	suite_classes_or_scenes.append(suite_ref)

func discover_test_suites(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = dir_path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with(".") and file_name != "artifacts" and file_name != "addons":
				discover_test_suites(full_path)
		elif file_name.ends_with(".gd") and file_name.begins_with("test_"):
			var script_res = load(full_path)
			if script_res:
				suite_classes_or_scenes.append(script_res)
		file_name = dir.get_next()
	dir.list_dir_end()

func discover_and_run() -> void:
	if suite_classes_or_scenes.is_empty():
		discover_test_suites(tests_directory)
	run_all_suites()

func run_all_suites() -> void:
	run_start_time = Time.get_ticks_msec()
	print("\n========================================================")
	print("🚀 STARTING UNIVERSAL GODOT TEST RUNNER (Engine v%s)" % Engine.get_version_info()["string"])
	if filter_suite_name != "":
		print("  Filter Suite:  %s" % filter_suite_name)
	if filter_test_method != "":
		print("  Filter Method: %s" % filter_test_method)
	if filter_test_type != "":
		print("  Filter Type:   %s" % filter_test_type.to_upper())
	var args = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for arg in args:
		if arg == "--update-snapshots" or arg == "-u" or arg.begins_with("--update-snapshots="):
			print("  📸 Snapshots:  Auto-update mode ACTIVE (--update-snapshots)")
			break
	print("========================================================\n")
	
	for suite_ref in suite_classes_or_scenes:
		var suite_instance: Node = null
		
		if suite_ref is GDScript:
			if suite_ref.can_instantiate():
				suite_instance = suite_ref.new()
			else:
				push_error("Cannot instantiate GDScript test suite: %s" % str(suite_ref.resource_path))
				continue
		elif suite_ref is Object and suite_ref.has_method("new"):
			suite_instance = suite_ref.new()
		elif suite_ref is PackedScene:
			suite_instance = suite_ref.instantiate()
		elif suite_ref is Node:
			suite_instance = suite_ref
			
		if suite_instance == null:
			continue
			
		# Filter by Test Type / Tier
		if filter_test_type != "":
			var suite_type = "integration"
			if suite_instance.get("test_type") != null:
				suite_type = str(suite_instance.get("test_type")).to_lower()
			if suite_type != filter_test_type:
				suite_instance.free()
				continue
			
		# Filter by Suite Name
		if filter_suite_name != "" and suite_instance.get("suite_name") != null:
			if not (filter_suite_name.to_lower() in str(suite_instance.get("suite_name")).to_lower()):
				suite_instance.free()
				continue
				
		# Filter by Method Name
		if filter_test_method != "":
			suite_instance.set("filter_method_name", filter_test_method)
			if suite_instance.has_method("get_test_methods") and suite_instance.get_test_methods().is_empty():
				suite_instance.free()
				continue
			
		add_child(suite_instance)
		total_suites += 1
		
		var result: Dictionary = await suite_instance.run_suite()
		suite_results.append(result)
		
		if result.has("checkpoints") and result["checkpoints"] is Array:
			all_checkpoints.append_array(result["checkpoints"])
		
		total_tests += result["tests_total"]
		passed_tests += result["tests_passed"]
		failed_tests += result["failures_total"]
		total_assertions += result["assertions_total"]
		
		if result["passed"]:
			passed_suites += 1
		else:
			failed_suites += 1
			
		suite_instance.queue_free()
		await get_tree().process_frame
		
	var total_duration = Time.get_ticks_msec() - run_start_time
	_print_summary(total_duration)
	_export_json_report(total_duration)
	_export_junit_xml(total_duration)
	_export_audit_manifest()
	
	if exit_on_finish:
		var exit_code = 0 if (failed_tests == 0 and total_tests > 0) else (0 if total_tests == 0 else 1)
		print("\n🏁 Test execution complete. Exiting with code: %d\n" % exit_code)
		await _graceful_shutdown(exit_code)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_graceful_shutdown(0)

func graceful_shutdown(exit_code: int = 0) -> void:
	await _graceful_shutdown(exit_code)

func _graceful_shutdown(exit_code: int = 0) -> void:
	# Stage 0: Guard against re-entrant shutdown
	if _is_shutting_down:
		return
	_is_shutting_down = true
	
	# Stage 1: Traverse immediate child nodes; if valid and not queued for deletion, unparent and queue_free()
	for child in get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			if child.get_parent():
				child.get_parent().remove_child(child)
			child.queue_free()
			
	# Stage 2: Clear all mock spies
	MockFactory.clear_spies()
	
	# Stage 3: Settle engine lifecycle (3 cycles of process_frame and physics_frame)
	if get_tree():
		for i in range(3):
			await get_tree().process_frame
			await get_tree().physics_frame
			
	# Stage 4: 1 final process_frame to flush FileAccess / logs
	if get_tree():
		await get_tree().process_frame
		
	# Stage 5: Terminate engine with exit code
	if get_tree():
		get_tree().quit(exit_code)

func _print_summary(total_duration_ms: int) -> void:
	print("\n========================================================")
	print("📊 TEST EXECUTION SUMMARY")
	print("========================================================")
	print("  Suites:      %d passed, %d failed, %d total" % [passed_suites, failed_suites, total_suites])
	print("  Tests:       %d passed, %d failed, %d total" % [passed_tests, failed_tests, total_tests])
	print("  Assertions:  %d total" % total_assertions)
	print("  Checkpoints: %d visual audit checkpoints" % all_checkpoints.size())
	print("  Duration:    %.2f seconds" % (float(total_duration_ms) / 1000.0))
	if failed_tests == 0 and total_tests > 0:
		print("  STATUS:      ✅ ALL TESTS PASSED")
	elif total_tests == 0:
		print("  STATUS:      ⚠️ NO TESTS MATCHED FILTER")
	else:
		print("  STATUS:      ❌ TEST FAILURES DETECTED")
	print("========================================================\n")

func _export_json_report(total_duration_ms: int) -> void:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"engine_version": Engine.get_version_info()["string"],
		"summary": {
			"total_suites": total_suites,
			"passed_suites": passed_suites,
			"failed_suites": failed_suites,
			"total_tests": total_tests,
			"passed_tests": passed_tests,
			"failed_tests": failed_tests,
			"total_assertions": total_assertions,
			"total_checkpoints": all_checkpoints.size(),
			"total_duration_ms": total_duration_ms,
			"all_passed": (failed_tests == 0 and total_tests > 0)
		},
		"suites": suite_results,
		"checkpoints": all_checkpoints
	}
	
	var global_path = ProjectSettings.globalize_path(output_json_path)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var file = FileAccess.open(global_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("Saved JSON test report to: %s" % global_path)

func _export_junit_xml(total_duration_ms: int) -> void:
	var xml_lines: Array[String] = []
	xml_lines.append('<?xml version="1.0" encoding="UTF-8"?>')
	xml_lines.append('<testsuites name="GodotIntegrationTests" tests="%d" failures="%d" time="%.3f">' % [
		total_tests, failed_tests, float(total_duration_ms) / 1000.0
	])
	
	for suite in suite_results:
		xml_lines.append('  <testsuite name="%s" tests="%d" failures="%d" time="%.3f">' % [
			suite["suite_name"], suite["tests_total"], suite["failures_total"], float(suite["duration_ms"]) / 1000.0
		])
		for test in suite["tests"]:
			var test_name = test["name"]
			var test_time = float(test["duration_ms"]) / 1000.0
			if test["passed"]:
				xml_lines.append('    <testcase name="%s" classname="%s" time="%.3f"/>' % [
					test_name, suite["suite_name"], test_time
				])
			else:
				xml_lines.append('    <testcase name="%s" classname="%s" time="%.3f">' % [
					test_name, suite["suite_name"], test_time
				])
				for fail_msg in test["failures"]:
					xml_lines.append('      <failure message="%s">%s</failure>' % [
						fail_msg.xml_escape(), fail_msg.xml_escape()
					])
				xml_lines.append('    </testcase>')
		xml_lines.append('  </testsuite>')
	xml_lines.append('</testsuites>')
	
	var global_path = ProjectSettings.globalize_path(output_junit_path)
	var file = FileAccess.open(global_path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(xml_lines))
		file.close()
		print("Saved JUnit XML report to: %s" % global_path)

func _export_audit_manifest() -> void:
	if all_checkpoints.is_empty():
		return
	var global_path = ProjectSettings.globalize_path(output_manifest_path)
	var file = FileAccess.open(global_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(all_checkpoints, "\t"))
		file.close()
		print("Saved Visual Audit Manifest to: %s" % global_path)

