extends SceneTree

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("==================================================")
	print("  MATERIAL 3 GODOT - INTEGRATION TEST SUITE RUNNER")
	print("==================================================")
	
	var total_passed := 0
	var total_failed := 0
	var all_details: Array[String] = []
	
	var suites: Array = [
		TestM3Buttons.new(),
		TestM3Inputs.new(),
		TestM3Selection.new(),
		TestM3ChipsBadges.new(),
		TestM3Surfaces.new(),
		TestM3Navigation.new(),
		TestM3Progress.new(),
		TestM3Adaptive.new(),
		TestShowcaseApp.new()
	]
	
	for suite in suites:
		var res: Dictionary = suite.run_all_tests(self)
		total_passed += res.get("passed", 0)
		total_failed += res.get("failed", 0)
		for r in res.get("results", []):
			all_details.append(r)
			print("  " + r)
		print("--------------------------------------------------")
	
	suites.clear()
	# Allow queued node frees to complete
	for _i in range(5):
		await process_frame
	
	if M3ThemeSingleton._instance != null:
		M3ThemeSingleton._instance.free()
		M3ThemeSingleton._instance = null
	if M3ThemeManager._instance != null:
		M3ThemeManager._instance.free()
		M3ThemeManager._instance = null
	
	for _i in range(5):
		await process_frame
			
	print("==================================================")
	print("TEST RESULTS SUMMARY:")
	print("  TOTAL PASSED: %d" % total_passed)
	print("  TOTAL FAILED: %d" % total_failed)
	print("==================================================")
	
	if total_failed == 0:
		print(">> ALL INTEGRATION TESTS PASSED SUCCESSFULLY! <<")
		quit(0)
	else:
		printerr(">> SOME TESTS FAILED! <<")
		quit(1)
