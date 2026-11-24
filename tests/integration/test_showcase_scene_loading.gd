extends SceneTree

func _init() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("==================================================")
	print("  SHOWCASE MAIN SCENE EMPIRICAL VERIFICATION")
	print("==================================================")

	var scene_res: PackedScene = load("res://scenes/showcase/showcase_main.tscn")
	if scene_res == null:
		printerr("FAIL: Could not load showcase_main.tscn")
		quit(1)
		return

	var showcase := scene_res.instantiate() as ShowcaseMain
	if showcase == null:
		printerr("FAIL: Could not instantiate showcase_main.tscn")
		quit(1)
		return

	root.add_child(showcase)
	await process_frame
	await process_frame

	print("✓ Scene loaded & instantiated successfully")

	# Verify Top App Bar
	var title_node := showcase.find_child("AppTitle", true, false) as Label
	if title_node != null and title_node.text == "Material 3 Godot":
		print("✓ Top App Bar present with title 'Material 3 Godot'")
	else:
		printerr("FAIL: Top App Bar title not found")
		quit(1)
		return

	# Verify Adaptive Navigation & 8 Screens
	var nav: M3AdaptiveNavigation = showcase._adaptive_nav
	if nav == null or nav._screens.size() != 8:
		printerr("FAIL: Expected 8 registered screens in adaptive navigation")
		quit(1)
		return
	print("✓ Adaptive Navigation initialized with 8 screens")

	# Screen names check
	var expected_screens: Array[String] = [
		"Buttons", "Selection", "Inputs", "Chips & Badges",
		"Surfaces", "Navigation", "Progress", "Responsive"
	]
	for i in range(8):
		nav.selected_index = i
		var scr := nav._screens[i]
		if not scr.visible:
			printerr("FAIL: Screen %d (%s) not visible when selected" % [i, expected_screens[i]])
			quit(1)
			return
		print("  ✓ Screen %d: %s (Type: %s) verified visible" % [i, expected_screens[i], scr.get_class()])

	# Verify Responsive Breakpoints on Scene
	print("\n--- Responsive Layout Mode Verification ---")
	nav.width_override = 1280.0
	await process_frame
	if nav.current_mode == M3AdaptiveNavigation.LayoutMode.EXPANDED and nav._nav_drawer.visible and not nav._nav_rail.visible and not nav._nav_bar.visible:
		print("✓ Expanded Mode (1280px): Navigation Drawer visible, Rail & Bar hidden")
	else:
		printerr("FAIL: Expanded mode verification failed")
		quit(1)
		return

	nav.width_override = 720.0
	await process_frame
	if nav.current_mode == M3AdaptiveNavigation.LayoutMode.MEDIUM and nav._nav_rail.visible and not nav._nav_drawer.visible and not nav._nav_bar.visible:
		print("✓ Medium Mode (720px): Navigation Rail visible, Drawer & Bar hidden")
	else:
		printerr("FAIL: Medium mode verification failed")
		quit(1)
		return

	nav.width_override = 400.0
	await process_frame
	if nav.current_mode == M3AdaptiveNavigation.LayoutMode.COMPACT and nav._nav_bar.visible and not nav._nav_rail.visible and not nav._nav_drawer.visible:
		print("✓ Compact Mode (400px): Bottom Navigation Bar visible, Drawer & Rail hidden")
	else:
		printerr("FAIL: Compact mode verification failed")
		quit(1)
		return

	# Reset override
	nav.width_override = -1.0

	# Verify Theme Manager & Seed Switching
	print("\n--- Dynamic Theming & Seed Palette Verification ---")
	var theme_mgr := M3ThemeManager.get_instance()
	var theme_inst := M3ThemeSingleton.get_instance()
	for preset in [M3ThemeManager.SeedPreset.INDIGO, M3ThemeManager.SeedPreset.TEAL, M3ThemeManager.SeedPreset.TERRACOTTA, M3ThemeManager.SeedPreset.EMERALD, M3ThemeManager.SeedPreset.AMBER, M3ThemeManager.SeedPreset.CORAL]:
		theme_mgr.set_seed_preset(preset)
		var expected_col: Color = M3ThemeManager.SEED_COLORS[preset]
		if theme_inst.seed_color != expected_col:
			printerr("FAIL: Preset %s did not apply expected seed color %s" % [M3ThemeManager.SEED_NAMES[preset], str(expected_col)])
			quit(1)
			return
		print("✓ Seed Palette Preset %s (%s) verified" % [M3ThemeManager.SEED_NAMES[preset], str(expected_col)])

	# Verify Dark / Light Mode Toggle
	var initial_mode: bool = theme_inst.is_dark_mode
	showcase._toggle_theme_mode()
	if theme_inst.is_dark_mode == initial_mode:
		printerr("FAIL: Theme toggle failed")
		quit(1)
		return
	print("✓ Dark/Light mode toggle state change verified (%s -> %s)" % ["Dark" if initial_mode else "Light", "Dark" if theme_inst.is_dark_mode else "Light"])
	showcase._toggle_theme_mode() # Revert

	# Clean Teardown
	root.remove_child(showcase)
	showcase.free()
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

	print("\n==================================================")
	print(">> SHOWCASE SCENE VERIFICATION PASSED 100%! <<")
	print("==================================================")
	quit(0)
