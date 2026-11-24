# res://tests/gss/test_gss_actions.gd
## GSS verification suite for the Material Design 3 Actions component family.
## Covers all 8 `actions.*` spec elements (element, interaction, and animation evidence).
extends GDTestSuite

const H := preload("res://tests/gss/m3_gss_harness.gd")

const S_BUTTON := "res://addons/material3/components/buttons/m3_button.gd"
const S_ICON_BUTTON := "res://addons/material3/components/buttons/m3_icon_button.gd"
const S_FAB := "res://addons/material3/components/buttons/m3_fab.gd"
const S_FAB_MENU := "res://addons/material3/components/buttons/m3_fab_menu.gd"
const S_SEG_BUTTON := "res://addons/material3/components/buttons/m3_segmented_button.gd"
const S_SEG_GROUP := "res://addons/material3/components/buttons/m3_segmented_button_group.gd"
const S_BTN_GROUP := "res://addons/material3/components/buttons/m3_button_group.gd"
const S_SPLIT_BUTTON := "res://addons/material3/components/buttons/m3_split_button.gd"

func _init() -> void:
	suite_name = "GSS_Actions_Family"
	test_type = "integration"

# ==============================================================================
# 1. actions.button.common (M3Button)
# ==============================================================================
func test_actions_button_common() -> void:
	var stage = await H.create_stage(self, "actions", "button_common", false)

	# Row 1: 5 core variants + icon + disabled + toggle
	var b_elev := M3Button.new(); b_elev.name = "BtnElevated"; b_elev.variant = M3Button.Variant.ELEVATED; b_elev.text = "Elevated"
	stage.add(b_elev, Vector2(40, 40))

	var b_fill := M3Button.new(); b_fill.name = "BtnFilled"; b_fill.variant = M3Button.Variant.FILLED; b_fill.text = "Filled"
	stage.add(b_fill, Vector2(180, 40))

	var b_tonal := M3Button.new(); b_tonal.name = "BtnTonal"; b_tonal.variant = M3Button.Variant.TONAL; b_tonal.text = "Filled Tonal"
	stage.add(b_tonal, Vector2(300, 40))

	var b_out := M3Button.new(); b_out.name = "BtnOutlined"; b_out.variant = M3Button.Variant.OUTLINED; b_out.text = "Outlined"
	stage.add(b_out, Vector2(450, 40))

	var b_text := M3Button.new(); b_text.name = "BtnText"; b_text.variant = M3Button.Variant.TEXT; b_text.text = "Text"
	stage.add(b_text, Vector2(580, 40))

	var b_icon := M3Button.new(); b_icon.name = "BtnWithIcon"; b_icon.variant = M3Button.Variant.FILLED; b_icon.leading_icon = &"add"; b_icon.text = "Create"
	stage.add(b_icon, Vector2(680, 40))

	var b_dis := M3Button.new(); b_dis.name = "BtnDisabled"; b_dis.variant = M3Button.Variant.FILLED; b_dis.text = "Disabled"; b_dis.disabled = true
	stage.add(b_dis, Vector2(820, 40))

	var b_tog := M3Button.new(); b_tog.name = "BtnToggle"; b_tog.variant = M3Button.Variant.TONAL; b_tog.text = "Bookmark"; b_tog.toggle_mode = true
	stage.add(b_tog, Vector2(960, 40))

	# Row 2: Expressive sizes XS..XL and Round/Square shapes
	var x_cursor: float = 40.0
	var size_names: Array[String] = ["XS", "S", "M", "L", "XL"]
	var size_enums: Array[M3Button.ButtonSize] = [
		M3Button.ButtonSize.EXTRA_SMALL,
		M3Button.ButtonSize.SMALL,
		M3Button.ButtonSize.MEDIUM,
		M3Button.ButtonSize.LARGE,
		M3Button.ButtonSize.EXTRA_LARGE
	]
	for i in range(size_enums.size()):
		var sb := M3Button.new()
		sb.name = "BtnSize_" + size_names[i]
		sb.button_size = size_enums[i]
		sb.button_shape = M3Button.ButtonShape.SQUARE if (i % 2 == 1) else M3Button.ButtonShape.ROUND
		sb.text = size_names[i]
		stage.add(sb, Vector2(x_cursor, 120))
		x_cursor += sb.custom_minimum_size.x + 20.0

	var snap_light: Dictionary = await H.snapshot(stage, "actions.button.common", "variants_light")
	H.assert_snapshot(self, snap_light, [S_BUTTON])
	var fill_node: Dictionary = H.node_entry(snap_light, "BtnFilled")
	assert_approx(float(fill_node.get("screen_rect", {}).get("height", 0.0)), 40.0, 0.5, "Standard M3Button height is 40dp")
	var xl_node: Dictionary = H.node_entry(snap_light, "BtnSize_XL")
	assert_approx(float(xl_node.get("screen_rect", {}).get("height", 0.0)), 136.0, 0.5, "XL M3Button height is 136dp")
	await H.assert_pixel(self, stage, stage.point_of(b_fill, Vector2(10, 20)), M3ThemeSingleton.get_instance().get_color(&"primary"), 0.08, "Filled button container matches primary token")
	H.cover(self, "actions.button.common", "element", snap_light, "All variants, sizes XS..XL, round/square, icon, disabled, toggle (light)")

	# Dark mode snapshot
	M3ThemeSingleton.get_instance().set_dark_mode(true)
	stage.refresh_background()
	var snap_dark: Dictionary = await H.snapshot(stage, "actions.button.common", "variants_dark")
	H.assert_snapshot(self, snap_dark, [S_BUTTON])
	H.cover(self, "actions.button.common", "element", snap_dark, "All variants in dark mode")
	M3ThemeSingleton.get_instance().set_dark_mode(false)
	stage.refresh_background()

	# Live interaction + animation on toggle button and filled button
	var live: Dictionary = await H.record(stage, "actions.button.common", "hover_press_toggle", func() -> void:
		await stage.hover(b_tog)
		await stage.wait(6)
		await stage.press(b_tog)
		await stage.wait(8)
		await stage.release(b_tog)
		await stage.wait(6)
		await stage.leave()
	, 16, b_tog)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "BtnToggle", "script_variables.button_pressed", true)
	H.assert_event(self, live, "script_variable_changed", "BtnToggle", "button_pressed")
	H.assert_animated(self, live, "BtnToggle", "script_variables._hover_progress", 3)
	H.cover(self, "actions.button.common", "interaction", live)
	H.cover(self, "actions.button.common", "animation", live)
	stage.dispose()

# ==============================================================================
# 2. actions.button.icon (M3IconButton)
# ==============================================================================
func test_actions_button_icon() -> void:
	var stage = await H.create_stage(self, "actions", "button_icon", false)

	var ib_std := M3IconButton.new(); ib_std.name = "IconStandard"; ib_std.variant = M3IconButton.Variant.STANDARD; ib_std.icon_name = &"favorite"; ib_std.selected_icon_name = &"checkmark"; ib_std.toggle_mode = true
	stage.add(ib_std, Vector2(60, 80))

	var ib_fill := M3IconButton.new(); ib_fill.name = "IconFilled"; ib_fill.variant = M3IconButton.Variant.FILLED; ib_fill.icon_name = &"settings"
	stage.add(ib_fill, Vector2(140, 80))

	var ib_tonal := M3IconButton.new(); ib_tonal.name = "IconTonal"; ib_tonal.variant = M3IconButton.Variant.TONAL; ib_tonal.icon_name = &"edit"; ib_tonal.toggle_mode = true
	stage.add(ib_tonal, Vector2(220, 80))

	var ib_out := M3IconButton.new(); ib_out.name = "IconOutlined"; ib_out.variant = M3IconButton.Variant.OUTLINED; ib_out.icon_name = &"add"; ib_out.toggle_mode = true; ib_out.button_pressed = true
	stage.add(ib_out, Vector2(300, 80))

	var ib_dis := M3IconButton.new(); ib_dis.name = "IconDisabled"; ib_dis.variant = M3IconButton.Variant.FILLED; ib_dis.icon_name = &"delete"; ib_dis.disabled = true
	stage.add(ib_dis, Vector2(380, 80))

	var snap: Dictionary = await H.snapshot(stage, "actions.button.icon", "variants_light")
	H.assert_snapshot(self, snap, [S_ICON_BUTTON])
	var std_node: Dictionary = H.node_entry(snap, "IconFilled")
	assert_approx(float(std_node.get("screen_rect", {}).get("width", 0.0)), 40.0, 0.5, "M3IconButton width is 40dp")
	assert_approx(float(std_node.get("screen_rect", {}).get("height", 0.0)), 40.0, 0.5, "M3IconButton height is 40dp")
	await H.assert_pixel(self, stage, stage.point_of(ib_fill, Vector2(6, 20)), M3ThemeSingleton.get_instance().get_color(&"primary"), 0.08, "Filled icon button container = primary")
	H.cover(self, "actions.button.icon", "element", snap)

	var live: Dictionary = await H.record(stage, "actions.button.icon", "toggle_select", func() -> void:
		await stage.hover(ib_tonal)
		await stage.wait(5)
		await stage.press(ib_tonal)
		await stage.wait(8)
		await stage.release(ib_tonal)
		await stage.wait(10)
	, 16, ib_tonal)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "IconTonal", "script_variables.button_pressed", true)
	H.assert_event(self, live, "script_variable_changed", "IconTonal", "button_pressed")
	H.assert_animated(self, live, "IconTonal", "script_variables._selection_progress", 3)
	H.cover(self, "actions.button.icon", "interaction", live)
	H.cover(self, "actions.button.icon", "animation", live)
	stage.dispose()

# ==============================================================================
# 3. actions.fab (M3FAB: small 40dp, standard 56dp, large 96dp; 4 palettes)
# ==============================================================================
func test_actions_fab() -> void:
	var stage = await H.create_stage(self, "actions", "fab_sizes_palettes", false)

	var fab_sm := M3FAB.new(); fab_sm.name = "FabSmall"; fab_sm.fab_variant = M3FAB.FabVariant.SMALL; fab_sm.color_palette = M3FAB.FabColorPalette.PRIMARY
	stage.add(fab_sm, Vector2(60, 80))

	var fab_std := M3FAB.new(); fab_std.name = "FabStandard"; fab_std.fab_variant = M3FAB.FabVariant.STANDARD; fab_std.color_palette = M3FAB.FabColorPalette.PRIMARY
	stage.add(fab_std, Vector2(140, 80))

	var fab_sec := M3FAB.new(); fab_sec.name = "FabSecondary"; fab_sec.fab_variant = M3FAB.FabVariant.STANDARD; fab_sec.color_palette = M3FAB.FabColorPalette.SECONDARY; fab_sec.icon_name = &"edit"
	stage.add(fab_sec, Vector2(230, 80))

	var fab_tert := M3FAB.new(); fab_tert.name = "FabTertiary"; fab_tert.fab_variant = M3FAB.FabVariant.STANDARD; fab_tert.color_palette = M3FAB.FabColorPalette.TERTIARY; fab_tert.icon_name = &"add"
	stage.add(fab_tert, Vector2(320, 80))

	var fab_surf := M3FAB.new(); fab_surf.name = "FabSurface"; fab_surf.fab_variant = M3FAB.FabVariant.STANDARD; fab_surf.color_palette = M3FAB.FabColorPalette.SURFACE; fab_surf.icon_name = &"add"
	stage.add(fab_surf, Vector2(410, 80))

	var fab_lg := M3FAB.new(); fab_lg.name = "FabLarge"; fab_lg.fab_variant = M3FAB.FabVariant.LARGE; fab_lg.color_palette = M3FAB.FabColorPalette.PRIMARY
	stage.add(fab_lg, Vector2(510, 60))

	var snap: Dictionary = await H.snapshot(stage, "actions.fab", "sizes_and_palettes")
	H.assert_snapshot(self, snap, [S_FAB])
	assert_approx(float(H.node_entry(snap, "FabSmall").get("screen_rect", {}).get("width", 0.0)), 40.0, 0.5, "Small FAB is 40dp")
	assert_approx(float(H.node_entry(snap, "FabStandard").get("screen_rect", {}).get("width", 0.0)), 56.0, 0.5, "Standard FAB is 56dp")
	assert_approx(float(H.node_entry(snap, "FabLarge").get("screen_rect", {}).get("width", 0.0)), 96.0, 0.5, "Large FAB is 96dp")
	await H.assert_pixel(self, stage, stage.point_of(fab_std, Vector2(10, 28)), M3ThemeSingleton.get_instance().get_color(&"primary_container"), 0.08, "Primary FAB container = primary_container")
	H.cover(self, "actions.fab", "element", snap)

	var presses: Array[int] = [0]
	fab_std.pressed.connect(func() -> void: presses[0] += 1)

	var live: Dictionary = await H.record(stage, "actions.fab", "hover_press_elevation", func() -> void:
		await stage.hover(fab_std)
		await stage.wait(6)
		await stage.press(fab_std)
		await stage.wait(8)
		await stage.release(fab_std)
		await stage.wait(6)
		await stage.leave()
	, 16, fab_std)
	H.assert_recording(self, live)
	assert_eq(presses[0], 1, "FAB pressed emitted once")
	H.assert_mutated(self, live, "FabStandard", "script_variables.current_state", M3Control.ControlState.FOCUSED)
	H.assert_event(self, live, "script_variable_changed", "FabStandard", "current_state")
	H.assert_animated(self, live, "FabStandard", "script_variables._hover_progress", 3)
	H.cover(self, "actions.fab", "interaction", live)
	H.cover(self, "actions.fab", "animation", live)
	stage.dispose()

# ==============================================================================
# 4. actions.fab.extended (M3FAB extended: icon + label, label only, collapse/expand)
# ==============================================================================
func test_actions_fab_extended() -> void:
	var stage = await H.create_stage(self, "actions", "fab_extended", false)

	var fab_ic_lbl := M3FAB.new()
	fab_ic_lbl.name = "ExtendedFabIconLabel"
	fab_ic_lbl.fab_variant = M3FAB.FabVariant.EXTENDED
	fab_ic_lbl.icon_name = &"edit"
	fab_ic_lbl.label = "Compose"
	fab_ic_lbl.toggle_extended_on_press = true
	stage.add(fab_ic_lbl, Vector2(80, 100))

	var fab_lbl_only := M3FAB.new()
	fab_lbl_only.name = "ExtendedFabLabelOnly"
	fab_lbl_only.fab_variant = M3FAB.FabVariant.EXTENDED
	fab_lbl_only.icon_name = &""
	fab_lbl_only.label = "New Message"
	stage.add(fab_lbl_only, Vector2(260, 100))

	var snap: Dictionary = await H.snapshot(stage, "actions.fab.extended", "variants_light")
	H.assert_snapshot(self, snap, [S_FAB])
	var sr: Dictionary = H.node_entry(snap, "ExtendedFabIconLabel").get("screen_rect", {})
	assert_approx(float(sr.get("height", 0.0)), 56.0, 0.5, "Extended FAB height is 56dp")
	assert_gte(float(sr.get("width", 0.0)), 80.0, "Extended FAB width >= 80dp")
	H.cover(self, "actions.fab.extended", "element", snap)

	# Click the extended FAB (with toggle_extended_on_press=true) to collapse, then click again to expand
	var live: Dictionary = await H.record(stage, "actions.fab.extended", "collapse_and_expand", func() -> void:
		await stage.click(fab_ic_lbl, Vector2(28, 28), 3)
		await stage.wait(16)
		await stage.click(fab_ic_lbl, Vector2(28, 28), 3)
		await stage.wait(16)
	, 16, fab_ic_lbl)
	H.assert_recording(self, live)
	H.assert_event(self, live, "script_variable_changed", "ExtendedFabIconLabel", "extended")
	H.assert_animated(self, live, "ExtendedFabIconLabel", "script_variables.extend_progress", 4)
	H.cover(self, "actions.fab.extended", "interaction", live)
	H.cover(self, "actions.fab.extended", "animation", live)
	stage.dispose()

# ==============================================================================
# 5. actions.fab.menu (M3FabMenu: closed, open with items, close button morph)
# ==============================================================================
func test_actions_fab_menu() -> void:
	var stage = await H.create_stage(self, "actions", "fab_menu", false)

	var fm_closed := M3FabMenu.new()
	fm_closed.name = "FabMenuClosed"
	fm_closed.add_item("Edit", "edit")
	fm_closed.add_item("Share", "share")
	stage.add(fm_closed, Vector2(80, 60))

	var fm_active := M3FabMenu.new()
	fm_active.name = "FabMenuInteractive"
	fm_active.add_item("Document", "edit")
	fm_active.add_item("Spreadsheet", "add")
	fm_active.add_item("Presentation", "share")
	stage.add(fm_active, Vector2(280, 60))

	var snap_closed: Dictionary = await H.snapshot(stage, "actions.fab.menu", "closed_state")
	H.assert_snapshot(self, snap_closed, [S_FAB_MENU])
	H.cover(self, "actions.fab.menu", "element", snap_closed, "Closed state")

	var live_open: Dictionary = await H.record(stage, "actions.fab.menu", "expand_and_select", func() -> void:
		await stage.click(fm_active.get_trigger_button())
		await stage.wait(18)
	, 14, fm_active)
	H.assert_recording(self, live_open)
	H.assert_mutated(self, live_open, "FabMenuInteractive", "script_variables.is_open", true)
	H.assert_animated(self, live_open, "FabMenuInteractive", "script_variables.open_progress", 4)
	H.cover(self, "actions.fab.menu", "interaction", live_open)
	H.cover(self, "actions.fab.menu", "animation", live_open)

	# Snapshot while open with 3 items + morphed close trigger button
	var snap_open: Dictionary = await H.snapshot(stage, "actions.fab.menu", "open_with_items")
	H.assert_snapshot(self, snap_open, [S_FAB_MENU])
	H.cover(self, "actions.fab.menu", "element", snap_open, "Open state with 3 items and close button morph")

	# Click an item to select and collapse
	var live_select: Dictionary = await H.record(stage, "actions.fab.menu", "select_item_collapse", func() -> void:
		await stage.click(fm_active.get_item_button(1))
		await stage.wait(18)
	, 14, fm_active)
	H.assert_recording(self, live_select)
	H.assert_mutated(self, live_select, "FabMenuInteractive", "script_variables.is_open", false)
	H.assert_mutated(self, live_select, "FabMenuInteractive", "script_variables.selected_index", 1)
	stage.dispose()

# ==============================================================================
# 6. actions.button.segmented (M3SegmentedButton & M3SegmentedButtonGroup)
# ==============================================================================
func test_actions_button_segmented() -> void:
	var stage = await H.create_stage(self, "actions", "button_segmented", false)

	# Single-select group (3 segments)
	var grp_single := M3SegmentedButtonGroup.new()
	grp_single.name = "SegGroupSingle"
	grp_single.multi_select = false
	var s0 := grp_single.add_segment("Day", &"star")
	s0.name = "SegDay"
	var s1 := grp_single.add_segment("Week")
	s1.name = "SegWeek"
	var s2 := grp_single.add_segment("Month")
	s2.name = "SegMonth"
	grp_single.selected_index = 0
	stage.add(grp_single, Vector2(60, 80))

	# Multi-select group (4 segments)
	var grp_multi := M3SegmentedButtonGroup.new()
	grp_multi.name = "SegGroupMulti"
	grp_multi.multi_select = true
	grp_multi.add_segment("XS")
	grp_multi.add_segment("S")
	grp_multi.add_segment("M")
	grp_multi.add_segment("L")
	grp_multi.selected_indices = [1, 2]
	stage.add(grp_multi, Vector2(60, 160))

	var snap: Dictionary = await H.snapshot(stage, "actions.button.segmented", "single_and_multi")
	H.assert_snapshot(self, snap, [S_SEG_BUTTON, S_SEG_GROUP])
	assert_approx(float(H.node_entry(snap, "SegDay").get("screen_rect", {}).get("height", 0.0)), 40.0, 0.5, "Segmented button height is 40dp")
	H.cover(self, "actions.button.segmented", "element", snap)

	var live: Dictionary = await H.record(stage, "actions.button.segmented", "select_segment_checkmark", func() -> void:
		await stage.click(s1)
		await stage.wait(16)
	, 14, grp_single)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "SegWeek", "script_variables.selected", true)
	H.assert_animated(self, live, "SegWeek", "script_variables._check_scale", 4)
	H.cover(self, "actions.button.segmented", "interaction", live)
	H.cover(self, "actions.button.segmented", "animation", live)
	stage.dispose()

# ==============================================================================
# 7. actions.button.group (M3ButtonGroup: standard, connected, press width morph)
# ==============================================================================
func test_actions_button_group() -> void:
	var stage = await H.create_stage(self, "actions", "button_group", false)

	var bg_std := M3ButtonGroup.new()
	bg_std.name = "ButtonGroupStandard"
	bg_std.group_variant = M3ButtonGroup.GroupVariant.STANDARD
	bg_std.add_button("Cut")
	bg_std.add_button("Copy")
	bg_std.add_button("Paste")
	stage.add(bg_std, Vector2(60, 80))

	var bg_conn := M3ButtonGroup.new()
	bg_conn.name = "ButtonGroupConnected"
	bg_conn.group_variant = M3ButtonGroup.GroupVariant.CONNECTED
	var cb0 := bg_conn.add_button("Reply", "edit")
	cb0.name = "ConnBtnReply"
	var cb1 := bg_conn.add_button("Forward", "share")
	cb1.name = "ConnBtnForward"
	var cb2 := bg_conn.add_button("Done", "check")
	cb2.name = "ConnBtnDone"
	stage.add(bg_conn, Vector2(60, 160))

	var snap: Dictionary = await H.snapshot(stage, "actions.button.group", "standard_and_connected")
	H.assert_snapshot(self, snap, [S_BTN_GROUP, S_BUTTON])
	H.cover(self, "actions.button.group", "element", snap)

	var live: Dictionary = await H.record(stage, "actions.button.group", "connected_press_width_morph", func() -> void:
		await stage.hover(cb1)
		await stage.wait(5)
		await stage.press(cb1)
		await stage.wait(8)
		await stage.release(cb1)
		await stage.wait(14)
	, 14, bg_conn)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "ConnBtnForward", "script_variables.button_pressed", true)
	H.assert_animated(self, live, "ButtonGroupConnected", "script_variables._active_expand_ratio", 4)
	H.cover(self, "actions.button.group", "interaction", live)
	H.cover(self, "actions.button.group", "animation", live)
	stage.dispose()

# ==============================================================================
# 8. actions.button.split (M3SplitButton: 4 variants, trailing menu open/closed)
# ==============================================================================
func test_actions_button_split() -> void:
	var stage = await H.create_stage(self, "actions", "button_split", false)

	var sb_fill := M3SplitButton.new()
	sb_fill.name = "SplitFilled"
	sb_fill.variant = M3SplitButton.VariantType.FILLED
	sb_fill.text = "Send"
	sb_fill.leading_icon = &"send"
	sb_fill.add_menu_item("Send now")
	sb_fill.add_menu_item("Schedule send")
	sb_fill.add_menu_item("Save draft")
	stage.add(sb_fill, Vector2(60, 60))

	var sb_tonal := M3SplitButton.new()
	sb_tonal.name = "SplitTonal"
	sb_tonal.variant = M3SplitButton.VariantType.TONAL
	sb_tonal.text = "Edit"
	sb_tonal.leading_icon = &"edit"
	sb_tonal.add_menu_item("Rename")
	sb_tonal.add_menu_item("Duplicate")
	stage.add(sb_tonal, Vector2(240, 60))

	var sb_elev := M3SplitButton.new()
	sb_elev.name = "SplitElevated"
	sb_elev.variant = M3SplitButton.VariantType.ELEVATED
	sb_elev.text = "Share"
	sb_elev.add_menu_item("Copy link")
	stage.add(sb_elev, Vector2(410, 60))

	var sb_out := M3SplitButton.new()
	sb_out.name = "SplitOutlined"
	sb_out.variant = M3SplitButton.VariantType.OUTLINED
	sb_out.text = "Export"
	sb_out.add_menu_item("Export PDF")
	stage.add(sb_out, Vector2(580, 60))

	var snap_closed: Dictionary = await H.snapshot(stage, "actions.button.split", "variants_closed")
	H.assert_snapshot(self, snap_closed, [S_SPLIT_BUTTON])
	assert_approx(float(H.node_entry(snap_closed, "SplitFilled").get("screen_rect", {}).get("height", 0.0)), 40.0, 0.5, "M3SplitButton bar height is 40dp")
	H.cover(self, "actions.button.split", "element", snap_closed, "Filled, Tonal, Elevated, Outlined split buttons (closed)")

	# Click leading half (primary action), then click trailing half to open menu and rotate chevron
	var live_open: Dictionary = await H.record(stage, "actions.button.split", "primary_and_menu_open", func() -> void:
		await stage.click(sb_fill, sb_fill.get_leading_local_center(), 3)
		await stage.wait(4)
		await stage.click(sb_fill, sb_fill.get_trailing_local_center(), 3)
		await stage.wait(16)
	, 14, sb_fill)
	H.assert_recording(self, live_open)
	H.assert_mutated(self, live_open, "SplitFilled", "script_variables.primary_press_count", 1)
	H.assert_mutated(self, live_open, "SplitFilled", "script_variables.menu_open", true)
	H.assert_animated(self, live_open, "SplitFilled", "script_variables.menu_open_progress", 4)
	H.assert_animated(self, live_open, "SplitFilled", "script_variables.chevron_rotation", 4)
	H.cover(self, "actions.button.split", "interaction", live_open)
	H.cover(self, "actions.button.split", "animation", live_open)

	# Snapshot with menu open
	var snap_open: Dictionary = await H.snapshot(stage, "actions.button.split", "menu_open")
	H.assert_snapshot(self, snap_open, [S_SPLIT_BUTTON])
	H.cover(self, "actions.button.split", "element", snap_open, "Split button with trailing popup menu open")

	# Click a menu item inside the open popup
	var item_btn := sb_fill.get_menu_item_buttons()[1]
	var live_pick: Dictionary = await H.record(stage, "actions.button.split", "select_menu_item", func() -> void:
		await stage.click(item_btn)
		await stage.wait(16)
	, 14, sb_fill)
	H.assert_recording(self, live_pick)
	H.assert_mutated(self, live_pick, "SplitFilled", "script_variables.selected_item_index", 1)
	H.assert_mutated(self, live_pick, "SplitFilled", "script_variables.menu_open", false)
	stage.dispose()

# ==============================================================================
# 9. actions.button.icon.expressive (M3IconButton: 5 sizes, 3 widths, Round/Square)
# ==============================================================================
func test_actions_button_icon_expressive() -> void:
	var stage = await H.create_stage(self, "actions", "button_icon_expressive", false)

	var sizes: Array[M3IconButton.ButtonSize] = [
		M3IconButton.ButtonSize.EXTRA_SMALL,
		M3IconButton.ButtonSize.SMALL,
		M3IconButton.ButtonSize.MEDIUM,
		M3IconButton.ButtonSize.LARGE,
		M3IconButton.ButtonSize.EXTRA_LARGE
	]
	var size_labels: Array[String] = ["XS", "S", "M", "L", "XL"]

	# Row 1: 5 size tiers (Default width, Round vs Square alternating)
	var x_pos: float = 40.0
	for i in range(sizes.size()):
		var ib := M3IconButton.new()
		ib.name = "IconSize_" + size_labels[i]
		ib.variant = M3IconButton.Variant.FILLED if (i % 2 == 0) else M3IconButton.Variant.TONAL
		ib.button_size = sizes[i]
		ib.width_mode = M3IconButton.WidthMode.DEFAULT
		ib.button_shape = M3IconButton.ButtonShape.SQUARE if (i % 2 == 1) else M3IconButton.ButtonShape.ROUND
		ib.icon_name = &"favorite"
		stage.add(ib, Vector2(x_pos, 40.0))
		x_pos += ib.custom_minimum_size.x + 24.0

	# Row 2: 3 width modes (Narrow, Default, Wide) at Medium (56dp) + toggleable interactive button
	var ib_narrow := M3IconButton.new()
	ib_narrow.name = "IconMediumNarrow"
	ib_narrow.variant = M3IconButton.Variant.TONAL
	ib_narrow.button_size = M3IconButton.ButtonSize.MEDIUM
	ib_narrow.width_mode = M3IconButton.WidthMode.NARROW
	ib_narrow.icon_name = &"edit"
	stage.add(ib_narrow, Vector2(40.0, 210.0))

	var ib_default := M3IconButton.new()
	ib_default.name = "IconMediumDefault"
	ib_default.variant = M3IconButton.Variant.FILLED
	ib_default.button_size = M3IconButton.ButtonSize.MEDIUM
	ib_default.width_mode = M3IconButton.WidthMode.DEFAULT
	ib_default.button_shape = M3IconButton.ButtonShape.ROUND
	ib_default.toggle_mode = true
	ib_default.icon_name = &"favorite"
	ib_default.selected_icon_name = &"checkmark"
	stage.add(ib_default, Vector2(120.0, 210.0))

	var ib_wide := M3IconButton.new()
	ib_wide.name = "IconMediumWide"
	ib_wide.variant = M3IconButton.Variant.OUTLINED
	ib_wide.button_size = M3IconButton.ButtonSize.MEDIUM
	ib_wide.width_mode = M3IconButton.WidthMode.WIDE
	ib_wide.button_shape = M3IconButton.ButtonShape.SQUARE
	ib_wide.icon_name = &"settings"
	stage.add(ib_wide, Vector2(210.0, 210.0))

	var snap: Dictionary = await H.snapshot(stage, "actions.button.icon.expressive", "sizes_widths_shapes")
	H.assert_snapshot(self, snap, [S_ICON_BUTTON])

	var xs_rect: Dictionary = H.node_entry(snap, "IconSize_XS").get("screen_rect", {})
	assert_approx(float(xs_rect.get("width", 0.0)), 32.0, 0.5, "XS icon button width is 32dp")
	assert_approx(float(xs_rect.get("height", 0.0)), 32.0, 0.5, "XS icon button height is 32dp")

	var xl_rect: Dictionary = H.node_entry(snap, "IconSize_XL").get("screen_rect", {})
	assert_approx(float(xl_rect.get("width", 0.0)), 136.0, 0.5, "XL icon button width is 136dp")
	assert_approx(float(xl_rect.get("height", 0.0)), 136.0, 0.5, "XL icon button height is 136dp")

	var nar_rect: Dictionary = H.node_entry(snap, "IconMediumNarrow").get("screen_rect", {})
	assert_approx(float(nar_rect.get("width", 0.0)), 48.0, 0.5, "Medium Narrow icon button width is 48dp")
	assert_approx(float(nar_rect.get("height", 0.0)), 56.0, 0.5, "Medium Narrow icon button height is 56dp")

	var wide_rect: Dictionary = H.node_entry(snap, "IconMediumWide").get("screen_rect", {})
	assert_approx(float(wide_rect.get("width", 0.0)), 72.0, 0.5, "Medium Wide icon button width is 72dp")
	assert_approx(float(wide_rect.get("height", 0.0)), 56.0, 0.5, "Medium Wide icon button height is 56dp")

	H.cover(self, "actions.button.icon.expressive", "element", snap, "5 sizes XS..XL, 3 width modes, Round and Square shapes")

	var live: Dictionary = await H.record(stage, "actions.button.icon.expressive", "press_morph_and_toggle", func() -> void:
		await stage.hover(ib_default)
		await stage.wait(5)
		await stage.press(ib_default)
		await stage.wait(8)
		await stage.release(ib_default)
		await stage.wait(12)
	, 16, ib_default)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "IconMediumDefault", "script_variables.button_pressed", true)
	H.assert_animated(self, live, "IconMediumDefault", "script_variables._active_corner_radius", 4)
	H.assert_animated(self, live, "IconMediumDefault", "script_variables._selection_progress", 3)
	H.cover(self, "actions.button.icon.expressive", "interaction", live)
	H.cover(self, "actions.button.icon.expressive", "animation", live)
	stage.dispose()
