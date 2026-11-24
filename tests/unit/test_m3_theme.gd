class_name TestM3Theme
extends GDTestSuite

## Unit tests for M3ThemeSingleton, seed color switching, dark mode toggling, and signal emissions.

var theme_node: M3ThemeSingleton

func before_each() -> void:
	theme_node = autofree(M3ThemeSingleton.new()) as M3ThemeSingleton
	auto_add_child(theme_node)

func test_theme_initialization() -> void:
	assert_not_null(theme_node.color_scheme, "Active color scheme should be initialized")
	assert_not_null(theme_node.light_scheme, "Light color scheme should be initialized")
	assert_not_null(theme_node.dark_scheme, "Dark color scheme should be initialized")
	assert_true(theme_node.is_dark_mode, "Default mode should be dark")

func test_seed_color_change_emits_signals() -> void:
	var seed_watcher: GDSignalWatcher = GDSignalWatcher.watch(theme_node, &"seed_color_changed")
	var theme_watcher: GDSignalWatcher = GDSignalWatcher.watch(theme_node, &"theme_changed")

	var new_color: Color = Color(0.180, 0.416, 0.220, 1.0) # Emerald
	theme_node.set_seed_color(new_color)

	assert_true(seed_watcher.is_emitted(), "seed_color_changed should have emitted")
	assert_true(theme_watcher.is_emitted(), "theme_changed should have emitted")
	assert_eq(theme_node.seed_color, new_color)

	# Verify primary color updated to match new seed
	var primary: Color = theme_node.get_color(M3Color.PRIMARY)
	assert_gt(primary.g, primary.b, "Emerald scheme primary should have dominant green")

func test_dark_mode_toggle_emits_signals() -> void:
	theme_node.set_dark_mode(false)
	var mode_watcher: GDSignalWatcher = GDSignalWatcher.watch(theme_node, &"mode_changed")
	var theme_watcher: GDSignalWatcher = GDSignalWatcher.watch(theme_node, &"theme_changed")

	var light_surface: Color = theme_node.get_color(M3Color.SURFACE)

	theme_node.toggle_dark_mode()

	assert_true(mode_watcher.is_emitted(), "mode_changed should have emitted")
	assert_true(theme_watcher.is_emitted(), "theme_changed should have emitted")
	assert_true(theme_node.is_dark_mode, "Theme should now be in dark mode")

	var dark_surface: Color = theme_node.get_color(M3Color.SURFACE)
	assert_lt(dark_surface.r, light_surface.r, "Dark surface should be darker than light surface")

	# Toggle back
	theme_node.toggle_dark_mode()
	assert_false(theme_node.is_dark_mode, "Theme should be back in light mode")

func test_get_color_by_enum_and_string_name() -> void:
	var col_enum: Color = theme_node.get_color(M3Color.Role.PRIMARY)
	var col_str: Color = theme_node.get_color(&"primary")
	var col_string: Color = theme_node.get_color("primary")

	assert_color_approx(col_enum, col_str, 0.001)
	assert_color_approx(col_enum, col_string, 0.001)

func test_custom_scheme_application() -> void:
	var custom_scheme: M3ColorScheme = M3ColorScheme.new()
	custom_scheme.is_dark = true
	custom_scheme.primary = Color.CYAN
	custom_scheme.surface = Color.BLACK

	var theme_watcher: GDSignalWatcher = GDSignalWatcher.watch(theme_node, &"theme_changed")
	theme_node.apply_custom_scheme(custom_scheme)

	assert_true(theme_watcher.is_emitted())
	assert_true(theme_node.is_dark_mode)
	assert_color_approx(theme_node.get_color(M3Color.Role.PRIMARY), Color.CYAN, 0.001)
