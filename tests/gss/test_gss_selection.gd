# res://tests/gss/test_gss_selection.gd
## GSS verification suite for Material Design 3 Selection components:
##   - selection.checkbox (M3Checkbox)
##   - selection.chip     (M3Chip)
##   - selection.menu     (M3Menu, M3MenuItem)
##   - selection.radio    (M3Radio, M3RadioGroup)
##   - selection.slider   (M3Slider)
##   - selection.switch   (M3Switch)
extends GDTestSuite

const H := preload("res://tests/gss/m3_gss_harness.gd")

const CHECKBOX_SCRIPT := "res://addons/material3/components/selection/m3_checkbox.gd"
const CHIP_SCRIPT := "res://addons/material3/components/info/m3_chip.gd"
const MENU_SCRIPT := "res://addons/material3/components/feedback/m3_menu.gd"
const MENU_ITEM_SCRIPT := "res://addons/material3/components/feedback/m3_menu_item.gd"
const RADIO_SCRIPT := "res://addons/material3/components/selection/m3_radio.gd"
const RADIO_GROUP_SCRIPT := "res://addons/material3/components/selection/m3_radio_group.gd"
const SLIDER_SCRIPT := "res://addons/material3/components/selection/m3_slider.gd"
const SWITCH_SCRIPT := "res://addons/material3/components/selection/m3_switch.gd"

func _init() -> void:
	suite_name = "GSS_Selection_Family"
	test_type = "integration"

# ==============================================================================
# 1. selection.checkbox
# ==============================================================================
func test_selection_checkbox() -> void:
	var stage = await H.create_stage(self, "selection", "checkbox_variants", false)

	var cb_unchecked := M3Checkbox.new()
	cb_unchecked.name = "CheckboxUnchecked"
	cb_unchecked.text = "Unchecked"
	cb_unchecked.check_state = M3Checkbox.CheckState.UNCHECKED
	stage.add(cb_unchecked, Vector2(60, 80))

	var cb_checked := M3Checkbox.new()
	cb_checked.name = "CheckboxChecked"
	cb_checked.text = "Checked"
	cb_checked.check_state = M3Checkbox.CheckState.CHECKED
	stage.add(cb_checked, Vector2(260, 80))

	var cb_indet := M3Checkbox.new()
	cb_indet.name = "CheckboxIndeterminate"
	cb_indet.text = "Indeterminate"
	cb_indet.tristate = true
	cb_indet.check_state = M3Checkbox.CheckState.INDETERMINATE
	stage.add(cb_indet, Vector2(460, 80))

	var cb_error := M3Checkbox.new()
	cb_error.name = "CheckboxError"
	cb_error.text = "Error"
	cb_error.check_state = M3Checkbox.CheckState.CHECKED
	cb_error.is_error = true
	stage.add(cb_error, Vector2(680, 80))

	var cb_disabled := M3Checkbox.new()
	cb_disabled.name = "CheckboxDisabled"
	cb_disabled.text = "Disabled"
	cb_disabled.check_state = M3Checkbox.CheckState.CHECKED
	cb_disabled.disabled = true
	stage.add(cb_disabled, Vector2(860, 80))

	var snap: Dictionary = await H.snapshot(stage, "selection.checkbox", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [CHECKBOX_SCRIPT]), "checkbox snapshot valid")

	var n_err: Dictionary = H.node_entry(snap, "CheckboxError")
	assert_eq(bool(n_err.get("script_variables", {}).get("is_error", false)), true, "error variant recorded in GSS")
	var sr: Dictionary = n_err.get("screen_rect", {})
	assert_gte(float(sr.get("height", 0.0)), 48.0, "checkbox touch target height >= 48dp")

	# Pixel checks on checked (primary) and error (error) box fill near top edge of 18x18 box (y = 24 - 7 = 17)
	var theme_mgr := M3ThemeSingleton.get_instance()
	await H.assert_pixel(self, stage, stage.point_of(cb_checked, Vector2(24, 17)), theme_mgr.get_color(&"primary"), 0.08, "checked checkbox box fill = primary")
	await H.assert_pixel(self, stage, stage.point_of(cb_error, Vector2(24, 17)), theme_mgr.get_color(&"error"), 0.08, "error checkbox box fill = error")
	H.cover(self, "selection.checkbox", "element", snap, "Unchecked, checked, indeterminate, error, disabled")

	var toggled_count: Array[int] = [0]
	cb_unchecked.toggled.connect(func(_v: bool) -> void: toggled_count[0] += 1)

	var live: Dictionary = await H.record(stage, "selection.checkbox", "check_morph", func() -> void:
		await stage.click(cb_unchecked, Vector2(24, 24))
		await stage.wait(16)
	, 10, cb_unchecked)
	assert_true(H.assert_recording(self, live), "checkbox recording valid")
	H.assert_mutated(self, live, "CheckboxUnchecked", "script_variables.check_state", M3Checkbox.CheckState.CHECKED)
	H.assert_animated(self, live, "CheckboxUnchecked", "script_variables._anim_progress", 4)
	assert_eq(toggled_count[0], 1, "checkbox toggled signal emitted on click")
	H.cover(self, "selection.checkbox", "interaction", live, "Click toggles unchecked -> checked")
	H.cover(self, "selection.checkbox", "animation", live, "_anim_progress spring tween")
	stage.dispose()

# ==============================================================================
# 2. selection.chip
# ==============================================================================
func test_selection_chip() -> void:
	var stage = await H.create_stage(self, "selection", "chip_variants", false)

	var c_assist := M3Chip.new()
	c_assist.name = "AssistChip"
	c_assist.chip_type = M3Chip.ChipType.ASSIST
	c_assist.icon_name = &"schedule"
	c_assist.text = "Set Alarm"
	stage.add(c_assist, Vector2(60, 100))

	var c_filter := M3Chip.new()
	c_filter.name = "FilterChip"
	c_filter.chip_type = M3Chip.ChipType.FILTER
	c_filter.text = "Filter Off"
	c_filter.selected = false
	stage.add(c_filter, Vector2(220, 100))

	var c_filter_sel := M3Chip.new()
	c_filter_sel.name = "FilterChipSelected"
	c_filter_sel.chip_type = M3Chip.ChipType.FILTER
	c_filter_sel.text = "Selected"
	c_filter_sel.selected = true
	stage.add(c_filter_sel, Vector2(360, 100))

	var c_input := M3Chip.new()
	c_input.name = "InputChip"
	c_input.chip_type = M3Chip.ChipType.INPUT
	c_input.avatar_text = "A"
	c_input.text = "Alice"
	stage.add(c_input, Vector2(500, 100))

	var c_suggest := M3Chip.new()
	c_suggest.name = "SuggestionChip"
	c_suggest.chip_type = M3Chip.ChipType.SUGGESTION
	c_suggest.text = "Try Later"
	stage.add(c_suggest, Vector2(650, 100))

	var c_elevated := M3Chip.new()
	c_elevated.name = "ElevatedChip"
	c_elevated.chip_type = M3Chip.ChipType.ASSIST
	c_elevated.elevated = true
	c_elevated.text = "Elevated"
	stage.add(c_elevated, Vector2(800, 100))

	var snap: Dictionary = await H.snapshot(stage, "selection.chip", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [CHIP_SCRIPT]), "chip snapshot valid")

	var n_chip: Dictionary = H.node_entry(snap, "FilterChipSelected")
	assert_approx(float(n_chip.get("screen_rect", {}).get("height", 0.0)), 32.0, 1.0, "chip height = 32dp")
	await H.assert_pixel(self, stage, stage.point_of(c_filter_sel, Vector2(6, 6)), M3ThemeSingleton.get_instance().get_color(&"secondary_container"), 0.08, "selected filter chip bg = secondary_container")
	H.cover(self, "selection.chip", "element", snap, "Assist, filter, input, suggestion, elevated")

	var close_events: Array[int] = [0]
	c_input.close_pressed.connect(func() -> void: close_events[0] += 1)

	var live: Dictionary = await H.record(stage, "selection.chip", "filter_toggle_and_input_close", func() -> void:
		await stage.click(c_filter)
		await stage.wait(16)
		var close_center: Vector2 = c_input.get_close_rect().get_center()
		await stage.click(c_input, close_center)
		await stage.wait(4)
	, 8, c_filter)
	assert_true(H.assert_recording(self, live), "chip recording valid")
	H.assert_mutated(self, live, "FilterChip", "script_variables.selected", true)
	H.assert_animated(self, live, "FilterChip", "script_variables._select_progress", 4)
	assert_eq(close_events[0], 1, "clicking input chip trailing close icon emits close_pressed")
	H.cover(self, "selection.chip", "interaction", live, "Filter chip toggle + Input chip close")
	H.cover(self, "selection.chip", "animation", live, "Filter chip _select_progress & _checkmark_progress tween")
	stage.dispose()

# ==============================================================================
# 3. selection.menu
# ==============================================================================
func test_selection_menu() -> void:
	var stage = await H.create_stage(self, "selection", "menu_variants", false)

	var anchor_btn := M3Button.new()
	anchor_btn.name = "MenuAnchorBtn"
	anchor_btn.text = "Open Menu"
	stage.add(anchor_btn, Vector2(120, 60))

	var menu := M3Menu.new()
	menu.name = "ContextMenu"
	stage.add(menu, Vector2(120, 112))
	var item_cut := menu.add_menu_item("Cut", 10, &"edit", "Ctrl+X")
	item_cut.name = "MenuItemCut"
	var item_copy := menu.add_menu_item("Copy", 20, &"copy", "Ctrl+C")
	item_copy.name = "MenuItemCopy"
	var item_share := menu.add_menu_item("Share", 30, &"share", "", false, &"chevron_right")
	item_share.name = "MenuItemShare"
	var div := menu.add_divider()
	div.name = "MenuDivider"
	var item_dis := menu.add_menu_item("Delete", 40, &"delete", "Del", true)
	item_dis.name = "MenuItemDisabled"

	# 1. Record menu opening animation (scale + fade + open_progress)
	var live_open: Dictionary = await H.record(stage, "selection.menu", "open_transition", func() -> void:
		menu.popup_at_control(anchor_btn)
		await stage.wait(16)
	, 6, menu)
	assert_true(H.assert_recording(self, live_open), "menu open recording valid")
	H.assert_mutated(self, live_open, "ContextMenu", "script_variables.is_open", true)
	H.assert_animated(self, live_open, "ContextMenu", "script_variables.open_progress", 4)
	H.cover(self, "selection.menu", "animation", live_open, "Menu open scale/fade open_progress transition")

	# 2. Capture static element snapshot while menu is open inside stage
	var snap: Dictionary = await H.snapshot(stage, "selection.menu", "variants_open_light")
	assert_true(H.assert_snapshot(self, snap, [MENU_SCRIPT, MENU_ITEM_SCRIPT]), "menu snapshot valid")
	var n_item: Dictionary = H.node_entry(snap, "MenuItemCut")
	assert_approx(float(n_item.get("screen_rect", {}).get("height", 0.0)), 48.0, 1.0, "menu item height = 48dp")
	var n_div: Dictionary = H.node_entry(snap, "MenuDivider")
	assert_approx(float(n_div.get("screen_rect", {}).get("height", 0.0)), 9.0, 1.0, "menu divider height = 9dp")
	await H.assert_pixel(self, stage, stage.point_of(item_cut, Vector2(6, 6)), M3ThemeSingleton.get_instance().get_color(&"surface_container"), 0.08, "menu container bg = surface_container")
	H.cover(self, "selection.menu", "element", snap, "Items with leading/trailing icons, shortcut, divider, disabled item")

	# 3. Record clicking a menu item to select and close
	var selected_ids: Array[int] = []
	menu.id_pressed.connect(func(id: int) -> void: selected_ids.append(id))

	var live_click: Dictionary = await H.record(stage, "selection.menu", "select_item", func() -> void:
		await stage.click(item_copy)
		await stage.wait(12)
	, 6, menu)
	assert_true(H.assert_recording(self, live_click), "menu item click recording valid")
	H.assert_mutated(self, live_click, "ContextMenu", "script_variables.is_open", false)
	assert_eq(selected_ids, [20], "clicking Copy menu item emitted id_pressed(20)")
	H.cover(self, "selection.menu", "interaction", live_click, "Click menu item emits selection and closes menu")
	stage.dispose()

# ==============================================================================
# 4. selection.radio
# ==============================================================================
func test_selection_radio() -> void:
	var stage = await H.create_stage(self, "selection", "radio_variants", false)

	var group := M3RadioGroup.new()
	group.name = "PriorityRadioGroup"
	stage.add(group, Vector2(80, 80))

	var r1 := group.add_radio("High Priority", "high")
	r1.name = "RadioHigh"
	var r2 := group.add_radio("Normal Priority", "normal")
	r2.name = "RadioNormal"
	var r3 := group.add_radio("Low Priority (Disabled)", "low")
	r3.name = "RadioDisabled"
	r3.disabled = true
	group.select(0)

	var snap: Dictionary = await H.snapshot(stage, "selection.radio", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [RADIO_SCRIPT, RADIO_GROUP_SCRIPT]), "radio snapshot valid")
	await H.assert_pixel(self, stage, stage.point_of(r1, Vector2(24, 24)), M3ThemeSingleton.get_instance().get_color(&"primary"), 0.08, "selected radio inner dot = primary")
	H.cover(self, "selection.radio", "element", snap, "Selected, unselected, disabled, group")

	var changed_values: Array = []
	group.selection_changed.connect(func(_r: M3Radio, val: Variant) -> void: changed_values.append(val))

	var live: Dictionary = await H.record(stage, "selection.radio", "group_select_second", func() -> void:
		await stage.click(r2, Vector2(24, 24))
		await stage.wait(16)
	, 10, group)
	assert_true(H.assert_recording(self, live), "radio recording valid")
	H.assert_mutated(self, live, "RadioNormal", "script_variables.selected", true)
	H.assert_mutated(self, live, "RadioHigh", "script_variables.selected", false)
	H.assert_animated(self, live, "RadioNormal", "script_variables._dot_scale", 4)
	assert_eq(changed_values, ["normal"], "M3RadioGroup selection_changed emitted with new value")
	H.cover(self, "selection.radio", "interaction", live, "Click unselected radio selects it and deselects previous")
	H.cover(self, "selection.radio", "animation", live, "Inner dot _dot_scale tween")
	stage.dispose()

# ==============================================================================
# 5. selection.slider
# ==============================================================================
func test_selection_slider() -> void:
	var stage = await H.create_stage(self, "selection", "slider_variants", false)

	var sl_cont := M3Slider.new()
	sl_cont.name = "SliderContinuous"
	sl_cont.slider_type = M3Slider.SliderType.CONTINUOUS
	sl_cont.step = 0.0
	sl_cont.value = 30.0
	sl_cont.size = Vector2(280, 44)
	stage.add(sl_cont, Vector2(80, 100))

	var sl_disc := M3Slider.new()
	sl_disc.name = "SliderDiscrete"
	sl_disc.slider_type = M3Slider.SliderType.DISCRETE
	sl_disc.step = 20.0
	sl_disc.show_ticks = true
	sl_disc.value = 40.0
	sl_disc.size = Vector2(280, 44)
	stage.add(sl_disc, Vector2(80, 190))

	var sl_range := M3Slider.new()
	sl_range.name = "SliderRange"
	sl_range.slider_type = M3Slider.SliderType.RANGE
	sl_range.start_value = 20.0
	sl_range.end_value = 80.0
	sl_range.size = Vector2(280, 44)
	stage.add(sl_range, Vector2(80, 280))

	var snap: Dictionary = await H.snapshot(stage, "selection.slider", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [SLIDER_SCRIPT]), "slider snapshot valid")
	await H.assert_pixel(self, stage, stage.point_of(sl_cont, Vector2(30, 22)), M3ThemeSingleton.get_instance().get_color(&"primary"), 0.08, "slider active track = primary")
	H.cover(self, "selection.slider", "element", snap, "Continuous, discrete with ticks, range")

	var emitted_values: Array[float] = []
	sl_disc.value_changed.connect(func(v: float) -> void: emitted_values.append(v))

	var live: Dictionary = await H.record(stage, "selection.slider", "drag_discrete_with_bubble", func() -> void:
		await stage.drag(sl_disc, Vector2(120, 22), Vector2(230, 22), 12)
		await stage.wait(12)
	, 10, sl_disc)
	assert_true(H.assert_recording(self, live), "slider recording valid")
	H.assert_mutated(self, live, "SliderDiscrete", "script_variables.value", 80.0)
	H.assert_animated(self, live, "SliderDiscrete", "script_variables._indicator_scale", 4)
	assert_gt(float(emitted_values.size()), 0.0, "slider value_changed emitted during drag")
	H.cover(self, "selection.slider", "interaction", live, "Drag discrete slider snaps to step 80")
	H.cover(self, "selection.slider", "animation", live, "Value indicator _indicator_scale & _active_progress tween")
	stage.dispose()

# ==============================================================================
# 6. selection.switch (light + dark mode snapshots)
# ==============================================================================
func test_selection_switch() -> void:
	var stage = await H.create_stage(self, "selection", "switch_variants", false)

	var sw_off := M3Switch.new()
	sw_off.name = "SwitchOff"
	sw_off.text = "Off"
	sw_off.selected = false
	stage.add(sw_off, Vector2(80, 100))

	var sw_on := M3Switch.new()
	sw_on.name = "SwitchOn"
	sw_on.text = "On"
	sw_on.selected = true
	stage.add(sw_on, Vector2(240, 100))

	var sw_icons := M3Switch.new()
	sw_icons.name = "SwitchIcons"
	sw_icons.text = "With Icons"
	sw_icons.show_icons = true
	sw_icons.selected = true
	stage.add(sw_icons, Vector2(400, 100))

	var sw_disabled := M3Switch.new()
	sw_disabled.name = "SwitchDisabled"
	sw_disabled.text = "Disabled"
	sw_disabled.disabled = true
	sw_disabled.selected = false
	stage.add(sw_disabled, Vector2(600, 100))

	var snap: Dictionary = await H.snapshot(stage, "selection.switch", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [SWITCH_SCRIPT]), "switch light snapshot valid")
	var theme_mgr := M3ThemeSingleton.get_instance()
	await H.assert_pixel(self, stage, stage.point_of(sw_off, Vector2(16, 24)), theme_mgr.get_color(&"outline"), 0.08, "unselected switch thumb = outline")
	await H.assert_pixel(self, stage, stage.point_of(sw_on, Vector2(14, 24)), theme_mgr.get_color(&"primary"), 0.08, "selected switch track = primary")
	H.cover(self, "selection.switch", "element", snap, "Off, on, with icons, disabled (light)")

	var live: Dictionary = await H.record(stage, "selection.switch", "toggle_on_glide", func() -> void:
		await stage.click(sw_off, Vector2(26, 24))
		await stage.wait(16)
	, 10, sw_off)
	assert_true(H.assert_recording(self, live), "switch recording valid")
	H.assert_mutated(self, live, "SwitchOff", "script_variables.selected", true)
	H.assert_animated(self, live, "SwitchOff", "script_variables._progress", 4)
	H.assert_animated(self, live, "SwitchOff", "script_variables._thumb_size", 4)
	H.cover(self, "selection.switch", "interaction", live, "Click switch toggles selected -> true")
	H.cover(self, "selection.switch", "animation", live, "Thumb glide _progress & _thumb_size morph")
	stage.dispose()

	# Dark mode family snapshot
	var dark_stage = await H.create_stage(self, "selection", "switch_variants_dark", true)
	var sw_dark_on := M3Switch.new()
	sw_dark_on.name = "SwitchDarkOn"
	sw_dark_on.text = "Dark Mode On"
	sw_dark_on.show_icons = true
	sw_dark_on.selected = true
	dark_stage.add(sw_dark_on, Vector2(80, 100))

	var snap_dark: Dictionary = await H.snapshot(dark_stage, "selection.switch", "variants_dark")
	assert_true(H.assert_snapshot(self, snap_dark, [SWITCH_SCRIPT]), "switch dark snapshot valid")
	H.cover(self, "selection.switch", "element", snap_dark, "Dark mode switch snapshot")
	dark_stage.dispose()
	M3ThemeSingleton.get_instance().set_dark_mode(false)

# ==============================================================================
# 7. selection.slider.expressive
# ==============================================================================
func test_selection_slider_expressive() -> void:
	var stage = await H.create_stage(self, "selection", "slider_expressive_variants", false)

	var sl_exp := M3Slider.new()
	sl_exp.name = "SliderExpressiveMedium"
	sl_exp.slider_size = M3Slider.SliderSize.MEDIUM
	sl_exp.value = 65.0
	sl_exp.size = Vector2(280, 48)
	stage.add(sl_exp, Vector2(60, 80))

	var sl_zero := M3Slider.new()
	sl_zero.name = "SliderCenteredZero"
	sl_zero.slider_size = M3Slider.SliderSize.SMALL
	sl_zero.centered_zero = true
	sl_zero.min_value = -100.0
	sl_zero.max_value = 100.0
	sl_zero.step = 10.0
	sl_zero.value = 40.0
	sl_zero.size = Vector2(280, 48)
	stage.add(sl_zero, Vector2(60, 170))

	var sl_large := M3Slider.new()
	sl_large.name = "SliderExpressiveLarge"
	sl_large.slider_size = M3Slider.SliderSize.LARGE
	sl_large.value = 50.0
	sl_large.size = Vector2(280, 60)
	stage.add(sl_large, Vector2(60, 260))

	var sl_vert := M3Slider.new()
	sl_vert.name = "SliderVertical"
	sl_vert.orientation = M3Slider.Orientation.VERTICAL
	sl_vert.slider_size = M3Slider.SliderSize.MEDIUM
	sl_vert.min_value = 0.0
	sl_vert.max_value = 100.0
	sl_vert.step = 5.0
	sl_vert.value = 25.0
	sl_vert.size = Vector2(56, 220)
	stage.add(sl_vert, Vector2(440, 80))

	var snap: Dictionary = await H.snapshot(stage, "selection.slider.expressive", "expressive_vertical_centered_light")
	assert_true(H.assert_snapshot(self, snap, [SLIDER_SCRIPT]), "expressive slider snapshot valid")
	var vert_entry: Dictionary = H.node_entry(snap, "SliderVertical")
	assert_gte(float(vert_entry.get("screen_rect", {}).get("height", 0.0)), 200.0, "vertical slider height >= 200dp")
	H.cover(self, "selection.slider.expressive", "element", snap, "Expressive thick tracks, centered-zero bidirectional, and vertical slider")

	var vert_changes: Array[float] = []
	sl_vert.value_changed.connect(func(v: float) -> void: vert_changes.append(v))

	var live: Dictionary = await H.record(stage, "selection.slider.expressive", "drag_vertical_and_centered", func() -> void:
		await stage.drag(sl_vert, Vector2(28, 170), Vector2(28, 50), 12)
		await stage.wait(10)
		await stage.click(sl_zero, Vector2(60, 24))
		await stage.wait(10)
	, 10, sl_vert)
	assert_true(H.assert_recording(self, live), "expressive slider recording valid")
	H.assert_mutated(self, live, "SliderVertical", "script_variables.value")
	H.assert_animated(self, live, "SliderVertical", "script_variables._active_progress", 4)
	assert_gt(sl_vert.value, 65.0, "dragging vertical slider upward increased value toward top max_value")
	assert_lt(sl_zero.value, 0.0, "clicking left of center on centered_zero slider set negative value")
	assert_gt(float(vert_changes.size()), 0.0, "vertical slider emitted value_changed")
	H.cover(self, "selection.slider.expressive", "interaction", live, "Vertical upward drag and centered-zero negative selection")
	H.cover(self, "selection.slider.expressive", "animation", live, "Vertical handle active progress and indicator scale tween")
	stage.dispose()

# ==============================================================================
# 8. selection.menu.cascading_grouped
# ==============================================================================
func test_selection_menu_cascading_grouped() -> void:
	var stage = await H.create_stage(self, "selection", "menu_cascading_grouped", false)

	var submenu := M3Menu.new()
	submenu.name = "ShareSubmenu"
	submenu.expressive_grouped = true
	var sub_email := submenu.add_menu_item("Email Link", 301, &"share")
	sub_email.name = "SubItemEmail"
	var sub_copy := submenu.add_menu_item("Copy URL", 302, &"copy")
	sub_copy.name = "SubItemCopyUrl"

	var menu := M3Menu.new()
	menu.name = "GroupedRootMenu"
	menu.expressive_grouped = true
	stage.add(menu, Vector2(100, 80))

	var it_edit := menu.add_menu_item("Edit Document", 10, &"edit", "Ctrl+E")
	it_edit.name = "GroupItemEdit"
	var it_share := menu.add_submenu_item(30, "Share With", submenu, &"share")
	it_share.name = "GroupItemShareTrigger"
	menu.add_group_break()
	var it_del := menu.add_menu_item("Delete File", 40, &"delete", "Del")
	it_del.name = "GroupItemDelete"

	menu.show_immediate(Vector2(100, 80))
	await stage.settle()
	assert_eq(menu.get_group_count(), 2, "expressive grouped menu has 2 item groups")

	var opened_submenus: Array[int] = []
	menu.submenu_opened.connect(func(item_id: int, _sub: M3Menu) -> void: opened_submenus.append(item_id))

	# 1. Record opening the cascading submenu via click/hover on the submenu trigger item
	var live_cascade: Dictionary = await H.record(stage, "selection.menu.cascading_grouped", "open_cascading_submenu", func() -> void:
		await stage.click(it_share)
		await stage.wait(16)
	, 8, menu)
	assert_true(H.assert_recording(self, live_cascade), "cascading submenu open recording valid")
	H.assert_mutated(self, live_cascade, "ShareSubmenu", "script_variables.is_open", true)
	H.assert_animated(self, live_cascade, "GroupedRootMenu", "script_variables.submenu_open_progress", 4)
	H.assert_animated(self, live_cascade, "ShareSubmenu", "script_variables.open_progress", 4)
	assert_eq(menu.active_submenu, submenu, "active_submenu set to ShareSubmenu")
	assert_eq(opened_submenus, [30], "submenu_opened emitted for item 30")
	assert_gte(submenu.position.x, menu.position.x + menu.size.x, "submenu positioned adjacent to right edge of parent menu")
	H.cover(self, "selection.menu.cascading_grouped", "animation", live_cascade, "Cascading submenu scale/fade and submenu_open_progress tween")

	# 2. Capture static snapshot with both grouped parent menu and cascading submenu open
	var snap: Dictionary = await H.snapshot(stage, "selection.menu.cascading_grouped", "grouped_and_submenu_open_light")
	assert_true(H.assert_snapshot(self, snap, [MENU_SCRIPT, MENU_ITEM_SCRIPT]), "cascading grouped menu snapshot valid")
	H.cover(self, "selection.menu.cascading_grouped", "element", snap, "Expressive grouped menu containers and open cascading submenu")

	# 3. Record selecting an item inside the cascading submenu
	var picked_ids: Array[int] = []
	menu.id_pressed.connect(func(id: int) -> void: picked_ids.append(id))

	var live_pick: Dictionary = await H.record(stage, "selection.menu.cascading_grouped", "select_submenu_item", func() -> void:
		await stage.click(sub_copy)
		await stage.wait(14)
	, 8, submenu)
	assert_true(H.assert_recording(self, live_pick), "submenu item click recording valid")
	H.assert_mutated(self, live_pick, "ShareSubmenu", "script_variables.is_open", false)
	assert_true(picked_ids.has(302), "clicking submenu item emitted id_pressed(302)")
	H.cover(self, "selection.menu.cascading_grouped", "interaction", live_pick, "Click cascading submenu item selects action and closes hierarchy")
	stage.dispose()
