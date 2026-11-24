class_name TestM3ActionsFamily
extends GDTestSuite

## Unit tests for Material Design 3 Actions family components:
## M3Button (sizes/shapes), M3IconButton, M3FAB (extended transition),
## M3SegmentedButtonGroup, M3ButtonGroup, M3SplitButton, and M3FabMenu.

func test_m3_button_sizes_and_shapes() -> void:
	var btn := auto_add_child(M3Button.new()) as M3Button
	btn.text = "Expressive"

	var expected_heights: Dictionary = {
		M3Button.ButtonSize.EXTRA_SMALL: 32.0,
		M3Button.ButtonSize.SMALL: 40.0,
		M3Button.ButtonSize.MEDIUM: 56.0,
		M3Button.ButtonSize.LARGE: 96.0,
		M3Button.ButtonSize.EXTRA_LARGE: 136.0
	}
	for sz in expected_heights.keys():
		btn.button_size = sz
		assert_approx(btn.custom_minimum_size.y, float(expected_heights[sz]), 0.01, "ButtonSize %d height" % sz)

	btn.button_size = M3Button.ButtonSize.SMALL
	btn.button_shape = M3Button.ButtonShape.SQUARE
	assert_approx(btn._resolve_base_radius(), 12.0, 0.01, "Square small button radius = 12dp")
	btn.button_shape = M3Button.ButtonShape.ROUND
	assert_approx(btn._resolve_base_radius(), 20.0, 0.01, "Round small button radius = 20dp")

func test_m3_icon_button_expressive_sizes_widths_shapes() -> void:
	var ib := auto_add_child(M3IconButton.new()) as M3IconButton
	assert_eq(ib.button_size, M3IconButton.ButtonSize.SMALL, "Default icon button size is SMALL")
	assert_eq(ib.width_mode, M3IconButton.WidthMode.DEFAULT, "Default icon button width_mode is DEFAULT")
	assert_eq(ib.button_shape, M3IconButton.ButtonShape.ROUND, "Default icon button shape is ROUND")
	assert_eq(ib.custom_minimum_size, Vector2(40.0, 40.0), "Default SMALL icon button is 40x40dp")
	assert_approx(ib.icon_size, 24.0, 0.01, "Default SMALL icon size is 24dp")
	assert_approx(ib._active_corner_radius, 20.0, 0.01, "Default SMALL ROUND corner radius is 20dp")

	ib.button_size = M3IconButton.ButtonSize.EXTRA_SMALL
	assert_eq(ib.custom_minimum_size, Vector2(32.0, 32.0), "XS default dims 32x32")
	assert_approx(ib.icon_size, 20.0, 0.01, "XS icon size 20dp")
	ib.width_mode = M3IconButton.WidthMode.NARROW
	assert_eq(ib.custom_minimum_size, Vector2(28.0, 32.0), "XS narrow dims 28x32")
	ib.width_mode = M3IconButton.WidthMode.WIDE
	assert_eq(ib.custom_minimum_size, Vector2(40.0, 32.0), "XS wide dims 40x32")

	ib.button_size = M3IconButton.ButtonSize.LARGE
	ib.width_mode = M3IconButton.WidthMode.NARROW
	assert_eq(ib.custom_minimum_size, Vector2(64.0, 96.0), "L narrow dims 64x96")
	assert_approx(ib.icon_size, 32.0, 0.01, "L icon size 32dp")
	ib.width_mode = M3IconButton.WidthMode.WIDE
	assert_eq(ib.custom_minimum_size, Vector2(128.0, 96.0), "L wide dims 128x96")

	ib.button_size = M3IconButton.ButtonSize.EXTRA_LARGE
	ib.width_mode = M3IconButton.WidthMode.DEFAULT
	assert_eq(ib.custom_minimum_size, Vector2(136.0, 136.0), "XL default dims 136x136")
	assert_approx(ib.icon_size, 40.0, 0.01, "XL icon size 40dp")
	ib.button_shape = M3IconButton.ButtonShape.SQUARE
	assert_approx(ib._active_corner_radius, 28.0, 0.01, "XL square resting radius is 28dp")

func test_m3_fab_extended_toggle_and_tween() -> void:
	var fab := auto_add_child(M3FAB.new()) as M3FAB
	fab.label = "Compose Email"
	fab.icon_name = &"edit"
	await wait_frames(2)

	assert_false(fab.extended, "FAB starts collapsed")
	assert_approx(fab.extend_progress, 0.0, 0.01, "Collapsed extend_progress == 0.0")
	assert_approx(fab.custom_minimum_size.x, 56.0, 0.01, "Standard FAB width == 56dp")

	var ext_events: Array[bool] = []
	fab.extended_changed.connect(func(v: bool) -> void: ext_events.append(v))

	fab.set_extended(true)
	assert_true(fab.extended, "FAB extended property updated to true")
	assert_eq(fab.fab_variant, M3FAB.FabVariant.EXTENDED, "FAB variant switched to EXTENDED")
	assert_eq(ext_events.size(), 1, "extended_changed emitted")
	assert_true(ext_events[0], "extended_changed emitted true")

	await wait_time(0.26)
	assert_approx(fab.extend_progress, 1.0, 0.05, "extend_progress animated to 1.0")
	assert_gt(fab.custom_minimum_size.x, 100.0, "Extended FAB width expanded past 100dp")

	fab.set_extended(false)
	await wait_time(0.26)
	assert_false(fab.extended, "FAB collapsed back")
	assert_approx(fab.extend_progress, 0.0, 0.05, "extend_progress animated back to 0.0")
	assert_approx(fab.custom_minimum_size.x, 56.0, 0.5, "Collapsed FAB width returned to 56dp")

func test_m3_button_group_standard_and_connected() -> void:
	var grp := auto_add_child(M3ButtonGroup.new()) as M3ButtonGroup
	grp.group_variant = M3ButtonGroup.GroupVariant.CONNECTED
	var b0 := grp.add_button("Left", "edit")
	var b1 := grp.add_button("Center", "share")
	var b2 := grp.add_button("Right", "check")
	await wait_frames(2)

	assert_eq(grp.get_button_count(), 3, "Group has 3 buttons")
	# Outer corners in CONNECTED mode are full pill (20dp), inner adjacent corners are small (8dp)
	assert_approx(b0.corner_top_left, 20.0, 0.1, "First button outer left corner is pill")
	assert_approx(b0.corner_top_right, 8.0, 0.1, "First button inner right corner is 8dp")
	assert_approx(b1.corner_top_left, 8.0, 0.1, "Middle button inner left corner is 8dp")
	assert_approx(b1.corner_top_right, 8.0, 0.1, "Middle button inner right corner is 8dp")
	assert_approx(b2.corner_top_right, 20.0, 0.1, "Last button outer right corner is pill")

	var pressed_indices: Array[int] = []
	var last_selection: Array[int] = []
	grp.button_pressed.connect(func(idx: int) -> void: pressed_indices.append(idx))
	grp.selection_changed.connect(func(sel: Array[int]) -> void: last_selection.assign(sel))

	b1._on_pressed_action()
	await wait_time(0.25)

	assert_eq(pressed_indices, [1], "button_pressed emitted index 1")
	assert_eq(last_selection, [1], "selection_changed emitted [1]")
	assert_gt(grp._active_expand_ratio, 0.5, "Active button width expansion animated")
	assert_gt(b1.width_bonus, 0.0, "Pressed button received width_bonus")

func test_m3_split_button_primary_and_menu() -> void:
	var sb := auto_add_child(M3SplitButton.new()) as M3SplitButton
	sb.variant = M3SplitButton.VariantType.TONAL
	sb.text = "Publish"
	sb.leading_icon = &"send"
	sb.add_menu_item("Publish now")
	sb.add_menu_item("Schedule")
	sb.add_menu_item("Save draft")
	await wait_frames(2)

	assert_eq(sb.get_menu_item_buttons().size(), 3, "3 menu items created")
	assert_false(sb.menu_open, "Menu initially closed")
	assert_approx(sb.chevron_rotation, 0.0, 0.01, "Chevron unrotated when closed")

	var primary_hits: Array[int] = [0]
	var toggle_states: Array[bool] = []
	var selected_items: Array[int] = []
	sb.primary_pressed.connect(func() -> void: primary_hits[0] += 1)
	sb.menu_toggled.connect(func(open: bool) -> void: toggle_states.append(open))
	sb.item_selected.connect(func(idx: int) -> void: selected_items.append(idx))

	sb.press_primary()
	assert_eq(primary_hits[0], 1, "primary_pressed emitted")

	sb.toggle_menu()
	assert_true(sb.menu_open, "menu_open is true after toggle_menu")
	assert_eq(toggle_states, [true], "menu_toggled(true) emitted")
	await wait_time(0.24)
	assert_approx(sb.menu_open_progress, 1.0, 0.05, "menu_open_progress reached 1.0")
	assert_approx(sb.chevron_rotation, PI, 0.08, "chevron_rotation reached PI")

	var item_btn := sb.get_menu_item_buttons()[2]
	item_btn._on_pressed_action()
	assert_eq(selected_items, [2], "item_selected emitted index 2")
	assert_false(sb.menu_open, "Selecting an item closes the menu")

func test_m3_fab_menu_expand_select_and_collapse() -> void:
	var fm := auto_add_child(M3FabMenu.new()) as M3FabMenu
	fm.add_item("Camera", "add")
	fm.add_item("Note", "edit")
	fm.add_item("Share", "share")
	await wait_frames(2)

	assert_eq(fm.get_item_count(), 3, "FAB Menu has 3 items")
	assert_false(fm.is_open, "FAB Menu starts closed")
	assert_false(fm.get_item_button(0).visible, "Items hidden when closed")

	var toggles: Array[bool] = []
	var picks: Array[String] = []
	fm.toggled.connect(func(open: bool) -> void: toggles.append(open))
	fm.item_selected.connect(func(idx: int, lbl: String) -> void: picks.append("%d:%s" % [idx, lbl]))

	fm.set_open(true)
	assert_true(fm.is_open, "is_open is true")
	assert_eq(toggles, [true], "toggled(true) emitted")
	await wait_time(0.28)
	assert_approx(fm.open_progress, 1.0, 0.05, "open_progress animated to 1.0")
	assert_true(fm.get_item_button(0).visible, "Menu item 0 visible when open")
	assert_eq(fm.get_trigger_button().icon_name, &"close", "Trigger FAB morphed to close icon")

	fm.get_item_button(1)._on_pressed_action()
	assert_eq(picks, ["1:Note"], "item_selected emitted (1, Note)")
	assert_false(fm.is_open, "FAB menu closes after item selection")
	await wait_time(0.28)
	assert_approx(fm.open_progress, 0.0, 0.05, "open_progress animated back to 0.0")
	assert_false(fm.get_item_button(0).visible, "Menu items hidden after collapse")
