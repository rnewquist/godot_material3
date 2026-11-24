# res://tests/gss/gss_runner.gd
## Material 3 GSS verification runner.
##
## Runs the GSS suites (res://tests/gss/test_gss_*.gd), stamps pass/fail on every piece of GSS
## evidence, and on a full run writes the coverage report and enforces that EVERY entry in
## m3_spec_registry.gd is verified (scripts exist + all required evidence kinds passed).
##
## Usage (windowed run = real GPU screenshots in res://artifacts/gss):
##   Godot --path . --script res://tests/gss/gss_runner.gd
##   Godot --path . --script res://tests/gss/gss_runner.gd -- --suite=res://tests/gss/test_gss_actions.gd
##   Godot --path . --script res://tests/gss/gss_runner.gd -- --suite=... --filter=test_fab
## Headless (synthetic previews, res://artifacts/gss_headless):
##   Godot --headless --path . --script res://tests/gss/gss_runner.gd
extends SceneTree

const H := preload("res://tests/gss/m3_gss_harness.gd")
const GDTestSuiteScript := preload("res://addons/gdtest/core/test_suite.gd")
const GSS_DIR := "res://tests/gss"

var _total_tests: int = 0
var _passed_tests: int = 0
var _failed_tests: int = 0
var _failed_names: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var t0: int = Time.get_ticks_msec()
	var suites: Array[String] = []
	var filter: String = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--suite="):
			for s in arg.trim_prefix("--suite=").split(",", false):
				var sp: String = s.strip_edges()
				if not sp.begins_with("res://"):
					sp = GSS_DIR.path_join(sp)
				if not sp.ends_with(".gd"):
					sp += ".gd"
				suites.append(sp)
		elif arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")
	var full_run: bool = suites.is_empty() and filter == ""
	if suites.is_empty():
		suites = _discover()

	print("\n=== M3 GSS Verification Runner (%s, display=%s, output=%s) ===\n" % ["full" if full_run else "partial", DisplayServer.get_name(), H.output_root()])
	H.clear_ledger()
	for path in suites:
		await _run_suite(path, filter)

	var exit_code: int = 0 if _failed_tests == 0 else 1
	if full_run:
		var cov: Dictionary = H.write_coverage_report()
		var meta: Dictionary = cov["meta"]
		print("\n--- M3 spec coverage: %d/%d verified ---" % [meta["verified"], meta["total"]])
		for it in cov["missing"]:
			print("  ✗ %s (%s) missing kinds=%s scripts=%s" % [it["id"], it["name"], str(it["missing_kinds"]), str(it["missing_scripts"])])
		print("Report: %s" % ProjectSettings.globalize_path(H.output_root().path_join("index.html")))
		if not bool(cov["complete"]):
			exit_code = 1
	print("\nTests: %d total, %d passed, %d failed (%.2fs)" % [_total_tests, _passed_tests, _failed_tests, float(Time.get_ticks_msec() - t0) / 1000.0])
	for n in _failed_names:
		print("  ✗ " + n)
	print("GSS RESULT: %s" % ("PASS" if exit_code == 0 else "FAIL"))
	for _i in range(4):
		await process_frame
	quit(exit_code)

func _discover() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(GSS_DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.begins_with("test_gss_") and f.ends_with(".gd"):
			out.append(GSS_DIR.path_join(f))
	out.sort()
	return out

func _run_suite(raw_path: String, filter: String) -> void:
	var path: String = raw_path
	if not path.ends_with(".gd"):
		path += ".gd"
	if not path.begins_with("res://"):
		if FileAccess.file_exists(GSS_DIR.path_join(path)):
			path = GSS_DIR.path_join(path)
		else:
			path = "res://" + path.trim_prefix("/")
	var script: Variant = load(path)
	if script == null or not (script is GDScript) or not (script as GDScript).can_instantiate():
		printerr("[GSS] could not load suite %s" % path)
		_failed_tests += 1
		_failed_names.append(path + " (load error)")
		return
	var suite_obj: Object = (script as GDScript).new()
	if not (suite_obj is GDTestSuiteScript):
		if suite_obj is Node:
			(suite_obj as Node).free()
		return
	var suite: Node = suite_obj as Node
	root.add_child(suite)
	print("[SUITE] %s" % path)
	var methods: Array[String] = []
	for m in suite.get_method_list():
		var mn: String = str(m["name"])
		if mn.begins_with("test_") and (filter == "" or mn.contains(filter)):
			methods.append(mn)
	methods.sort()
	await suite.before_all()
	for mn in methods:
		_total_tests += 1
		suite.set("current_test_name", mn)
		var fails_before: int = int(suite.get("test_fail_count"))
		var t_start: int = Time.get_ticks_msec()
		await suite.before_each()
		await suite.call(mn)
		await suite.after_each()
		suite.call("cleanup_nodes")
		for _i in range(2):
			await process_frame
		var failed: bool = int(suite.get("test_fail_count")) > fails_before
		H.mark_test_result(path, mn, not failed)
		if failed:
			_failed_tests += 1
			_failed_names.append("%s::%s" % [path.get_file(), mn])
			print("  ✗ %s (%d ms)" % [mn, Time.get_ticks_msec() - t_start])
			for f in suite.get("failures"):
				if f is Dictionary and str(f.get("test", "")) == mn:
					print("      ↳ %s" % str(f.get("message", "")))
		else:
			_passed_tests += 1
			print("  ✓ %s (%d ms)" % [mn, Time.get_ticks_msec() - t_start])
	await suite.after_all()
	root.remove_child(suite)
	suite.free()
	print("")
