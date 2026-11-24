# res://tests/gss/test_gss_inputs.gd
## GSS verification suite for Material 3 Text Inputs, Select, Date Picker, and Time Picker:
##   - inputs.text_field (M3TextField)
##   - inputs.select (M3Select, M3SelectDropdown)
##   - selection.date_picker (M3DatePicker)
##   - selection.time_picker (M3TimePicker)
extends GDTestSuite

const H := preload("res://tests/gss/m3_gss_harness.gd")

const TEXT_FIELD_SCRIPT := "res://addons/material3/components/inputs/m3_text_field.gd"
const SELECT_SCRIPT := "res://addons/material3/components/inputs/m3_select.gd"
const SELECT_DROPDOWN_SCRIPT := "res://addons/material3/components/inputs/m3_select_dropdown.gd"
const DATE_PICKER_SCRIPT := "res://addons/material3/components/selection/m3_date_picker.gd"
const TIME_PICKER_SCRIPT := "res://addons/material3/components/selection/m3_time_picker.gd"

func _init() -> void:
	suite_name = "GSS_Inputs_And_Pickers"
	test_type = "integration"

# ==============================================================================
# 1. inputs.text_field
# ==============================================================================

func test_text_field_variants_and_interaction() -> void:
	var stage = await H.create_stage(self, "inputs", "text_field_variants", false)

	# 1) Filled empty (ready for focus + typing animation)
	var tf_filled := M3TextField.new()
	tf_filled.name = "FilledEmptyField"
	tf_filled.variant = M3TextField.Variant.FILLED
	tf_filled.label = "Username"
	tf_filled.leading_icon = &"person"
	tf_filled.size = Vector2(260, 56)
	stage.add(tf_filled, Vector2(40, 40))

	# 2) Filled with supporting text & clear button
	var tf_clear := M3TextField.new()
	tf_clear.name = "ClearableField"
	tf_clear.variant = M3TextField.Variant.FILLED
	tf_clear.label = "Search query"
	tf_clear.text = "Material 3"
	tf_clear.helper_text = "Click trailing X to clear"
	tf_clear.leading_icon = &"search"
	tf_clear.show_clear_button = true
	tf_clear.size = Vector2(260, 76)
	stage.add(tf_clear, Vector2(340, 40))

	# 3) Outlined with character counter
	var tf_outlined := M3TextField.new()
	tf_outlined.name = "OutlinedCounterField"
	tf_outlined.variant = M3TextField.Variant.OUTLINED
	tf_outlined.label = "Bio"
	tf_outlined.text = "Godot UI developer"
	tf_outlined.helper_text = "Short bio"
	tf_outlined.max_characters = 40
	tf_outlined.size = Vector2(260, 76)
	stage.add(tf_outlined, Vector2(640, 40))

	# 4) Outlined error state
	var tf_error := M3TextField.new()
	tf_error.name = "OutlinedErrorField"
	tf_error.variant = M3TextField.Variant.OUTLINED
	tf_error.label = "Email"
	tf_error.text = "invalid-email"
	tf_error.is_error = true
	tf_error.error_text = "Enter a valid email address"
	tf_error.trailing_icon = &"clear"
	tf_error.size = Vector2(260, 76)
	stage.add(tf_error, Vector2(40, 160))

	# 5) Outlined password field
	var tf_pass := M3TextField.new()
	tf_pass.name = "PasswordField"
	tf_pass.variant = M3TextField.Variant.OUTLINED
	tf_pass.label = "Password"
	tf_pass.text = "hunter2"
	tf_pass.is_password = true
	tf_pass.supporting_text = "Toggle eye icon"
	tf_pass.size = Vector2(260, 76)
	stage.add(tf_pass, Vector2(340, 160))

	# Element snapshot (Light)
	var snap_light: Dictionary = await H.snapshot(stage, "inputs.text_field", "variants_light")
	assert_true(H.assert_snapshot(self, snap_light, [TEXT_FIELD_SCRIPT]), "text_field light snapshot valid")

	var filled_entry: Dictionary = H.node_entry(snap_light, "FilledEmptyField")
	assert_approx(float(filled_entry.get("screen_rect", {}).get("height", 0.0)), 56.0, 1.0, "M3 text field container height = 56dp")

	await H.assert_pixel(
		self, stage, stage.point_of(tf_filled, Vector2(200, 16)),
		M3ThemeSingleton.get_instance().get_color(&"surface_container_highest"),
		0.08, "filled text field container = surface_container_highest"
	)
	H.cover(self, "inputs.text_field", "element", snap_light, "All text field variants in light mode")

	# Live interaction + animation 1: click empty field to focus & float label, then type text
	var changed_texts: Array[String] = []
	tf_filled.text_changed.connect(func(t: String) -> void: changed_texts.append(t))

	var live_type: Dictionary = await H.record(stage, "inputs.text_field", "focus_and_type", func() -> void:
		await stage.click(tf_filled, Vector2(120, 28))
		await stage.wait(14)
		await stage.type_text("Ada")
		await stage.wait(8)
	, 12, tf_filled)
	assert_true(H.assert_recording(self, live_type), "text_field focus_and_type recording valid")
	H.assert_mutated(self, live_type, "FilledEmptyField", "script_variables.text", "Ada")
	H.assert_animated(self, live_type, "FilledEmptyField", "script_variables._label_float_progress", 4)
	H.assert_animated(self, live_type, "FilledEmptyField", "script_variables._focus_progress", 4)
	assert_true(changed_texts.has("Ada"), "text_changed emitted 'Ada'")

	# Live interaction 2: click trailing clear button and password visibility toggle
	var live_trailing: Dictionary = await H.record(stage, "inputs.text_field", "clear_and_password_toggle", func() -> void:
		await stage.click(tf_clear, Vector2(tf_clear.size.x - 24.0, 28.0))
		await stage.wait(8)
		await stage.click(tf_pass, Vector2(tf_pass.size.x - 24.0, 28.0))
		await stage.wait(8)
	, 10, tf_clear)
	assert_true(H.assert_recording(self, live_trailing), "text_field trailing icon recording valid")
	H.assert_mutated(self, live_trailing, "ClearableField", "script_variables.text", "")
	H.assert_mutated(self, live_trailing, "PasswordField", "script_variables.secret", false)

	H.cover(self, "inputs.text_field", "interaction", live_type, "Click focus, keyboard typing, clear & password toggle")
	H.cover(self, "inputs.text_field", "animation", live_type, "Floating label and focus indicator tween")
	stage.dispose()

# ==============================================================================
# 2. inputs.select
# ==============================================================================

func test_select_variants_and_dropdown_interaction() -> void:
	var stage = await H.create_stage(self, "inputs", "select_variants", false)

	# 1) Outlined M3Select (closed, initial selection)
	var sel_outlined := M3Select.new()
	sel_outlined.name = "RoleSelect"
	sel_outlined.variant = M3TextField.Variant.OUTLINED
	sel_outlined.label = "Role"
	sel_outlined.options = ["Viewer", "Contributor", "Editor", "Admin"]
	sel_outlined.selected_index = 0
	sel_outlined.size = Vector2(220, 56)
	stage.add(sel_outlined, Vector2(40, 48))

	# 2) Filled M3Select (closed, selected value)
	var sel_filled := M3Select.new()
	sel_filled.name = "TeamSelectFilled"
	sel_filled.variant = M3TextField.Variant.FILLED
	sel_filled.label = "Team"
	sel_filled.options = ["Core Engine", "Design Systems", "Tooling"]
	sel_filled.selected_index = 1
	sel_filled.size = Vector2(220, 56)
	stage.add(sel_filled, Vector2(300, 48))

	# 3) Open M3Select showing in-tree dropdown menu
	var sel_open := M3Select.new()
	sel_open.name = "OpenPresetSelect"
	sel_open.variant = M3TextField.Variant.OUTLINED
	sel_open.label = "Environment"
	sel_open.options = ["Development", "Staging", "Production"]
	sel_open.selected_index = 1
	sel_open.is_open = true
	sel_open.size = Vector2(220, 56)
	stage.add(sel_open, Vector2(560, 48))

	# 4) M3SelectDropdown component
	var sel_drop := M3SelectDropdown.new()
	sel_drop.name = "LegacySelectDropdown"
	sel_drop.label = "Region"
	sel_drop.options = ["us-west", "eu-central", "ap-east"]
	sel_drop.selected_index = 0
	sel_drop.size = Vector2(220, 56)
	stage.add(sel_drop, Vector2(820, 48))

	var snap: Dictionary = await H.snapshot(stage, "inputs.select", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [SELECT_SCRIPT, SELECT_DROPDOWN_SCRIPT]), "select snapshot valid")

	await H.assert_pixel(
		self, stage, stage.point_of(sel_filled, Vector2(180, 16)),
		M3ThemeSingleton.get_instance().get_color(&"surface_container_highest"),
		0.08, "filled select container = surface_container_highest"
	)
	H.cover(self, "inputs.select", "element", snap, "Filled, outlined, open menu, and M3SelectDropdown variants")

	# Close the pre-opened select before recording interaction on RoleSelect
	sel_open.close_dropdown()
	await stage.settle()

	var selected_events: Array = []
	sel_outlined.item_selected.connect(func(idx: int, val: Variant) -> void: selected_events.append([idx, val]))

	# Record opening the select dropdown (chevron rotation + menu open_progress tween)
	var live_open: Dictionary = await H.record(stage, "inputs.select", "open_dropdown", func() -> void:
		await stage.click(sel_outlined)
		await stage.wait(16)
	, 10, sel_outlined)
	assert_true(H.assert_recording(self, live_open), "select open recording valid")
	H.assert_mutated(self, live_open, "RoleSelect", "script_variables.is_open", true)
	H.assert_animated(self, live_open, "RoleSelect", "script_variables.open_progress", 4)
	H.assert_animated(self, live_open, "RoleSelect", "script_variables._chevron_rot", 4)

	# Record clicking item index 2 ("Editor") in the open dropdown panel
	var live_pick: Dictionary = await H.record(stage, "inputs.select", "pick_option", func() -> void:
		var item_pos: Vector2 = sel_outlined.get_item_global_position(2)
		await stage.click_at(item_pos)
		await stage.wait(16)
	, 10, sel_outlined)
	assert_true(H.assert_recording(self, live_pick), "select pick recording valid")
	H.assert_mutated(self, live_pick, "RoleSelect", "script_variables.selected_index", 2)
	H.assert_mutated(self, live_pick, "RoleSelect", "script_variables.is_open", false)
	H.assert_animated(self, live_pick, "RoleSelect", "script_variables.open_progress", 4)
	assert_eq(sel_outlined.get_selected_text(), "Editor", "selected option updated to Editor")
	assert_eq(selected_events.size(), 1, "item_selected signal emitted once")

	H.cover(self, "inputs.select", "interaction", live_pick, "Open dropdown and click option item")
	H.cover(self, "inputs.select", "animation", live_open, "Chevron rotation and menu open_progress animation")
	stage.dispose()

# ==============================================================================
# 3. selection.date_picker
# ==============================================================================

func test_date_picker_variants_and_interaction() -> void:
	# Light stage: Docked + Modal calendar
	var stage = await H.create_stage(self, "selection", "date_picker_light", false)

	var dp_docked := M3DatePicker.new()
	dp_docked.name = "DockedDatePicker"
	dp_docked.picker_mode = M3DatePicker.PickerMode.DOCKED
	dp_docked.selected_year = 2025
	dp_docked.selected_month = 5
	dp_docked.selected_day = 15
	stage.add(dp_docked, Vector2(40, 120))

	var dp_modal := M3DatePicker.new()
	dp_modal.name = "ModalDatePicker"
	dp_modal.picker_mode = M3DatePicker.PickerMode.MODAL
	dp_modal.selected_year = 2025
	dp_modal.selected_month = 5
	dp_modal.selected_day = 15
	stage.add(dp_modal, Vector2(420, 120))

	var snap_light: Dictionary = await H.snapshot(stage, "selection.date_picker", "docked_and_modal_light")
	assert_true(H.assert_snapshot(self, snap_light, [DATE_PICKER_SCRIPT]), "date_picker light snapshot valid")

	var modal_entry: Dictionary = H.node_entry(snap_light, "ModalDatePicker")
	assert_approx(float(modal_entry.get("screen_rect", {}).get("width", 0.0)), 328.0, 1.0, "date picker width = 328dp")
	assert_approx(float(modal_entry.get("screen_rect", {}).get("height", 0.0)), 420.0, 1.0, "date picker height = 420dp")

	await H.assert_pixel(
		self, stage, stage.point_of(dp_modal, Vector2(200, 24)),
		M3ThemeSingleton.get_instance().get_color(&"surface_container_high"),
		0.08, "date picker container = surface_container_high"
	)
	H.cover(self, "selection.date_picker", "element", snap_light, "Docked and Modal M3DatePicker variants")

	# Live interaction + animation: click day 22, click next month, click OK
	var selected_dates: Array = []
	var confirmed_dates: Array = []
	dp_modal.date_selected.connect(func(y: int, m: int, d: int) -> void: selected_dates.append([y, m, d]))
	dp_modal.date_confirmed.connect(func(y: int, m: int, d: int) -> void: confirmed_dates.append([y, m, d]))

	var live: Dictionary = await H.record(stage, "selection.date_picker", "select_day_and_next_month", func() -> void:
		var day22_local: Vector2 = dp_modal.get_day_cell_position(22)
		await stage.click(dp_modal, day22_local)
		await stage.wait(16)
		await stage.click(dp_modal._next_month_btn)
		await stage.wait(16)
		await stage.click(dp_modal._confirm_btn)
		await stage.wait(4)
	, 10, dp_modal)
	assert_true(H.assert_recording(self, live), "date_picker recording valid")
	H.assert_mutated(self, live, "ModalDatePicker", "script_variables.selected_day", 22)
	H.assert_mutated(self, live, "ModalDatePicker", "script_variables.selected_month", 6)
	H.assert_animated(self, live, "ModalDatePicker", "script_variables.selection_anim_progress", 4)
	H.assert_animated(self, live, "ModalDatePicker", "script_variables.month_transition_progress", 4)
	assert_eq(selected_dates.size(), 1, "date_selected emitted on day click")
	assert_eq(confirmed_dates.size(), 1, "date_confirmed emitted on OK click")

	H.cover(self, "selection.date_picker", "interaction", live, "Day cell selection, month navigation, and confirmation")
	H.cover(self, "selection.date_picker", "animation", live, "Day selection circle and month transition animations")
	stage.dispose()

	# Dark stage: Modal Input + Range selection variants
	var stage_dark = await H.create_stage(self, "selection", "date_picker_dark", true)

	var dp_input := M3DatePicker.new()
	dp_input.name = "InputDatePicker"
	dp_input.picker_mode = M3DatePicker.PickerMode.INPUT
	dp_input.selected_year = 2025
	dp_input.selected_month = 5
	dp_input.selected_day = 15
	stage_dark.add(dp_input, Vector2(40, 120))

	var dp_range := M3DatePicker.new()
	dp_range.name = "RangeDatePicker"
	dp_range.picker_mode = M3DatePicker.PickerMode.MODAL
	dp_range.range_selection = true
	dp_range.range_start_day = 10
	dp_range.range_end_day = 18
	dp_range.selected_day = 18
	stage_dark.add(dp_range, Vector2(420, 120))

	var snap_dark: Dictionary = await H.snapshot(stage_dark, "selection.date_picker", "input_and_range_dark")
	assert_true(H.assert_snapshot(self, snap_dark, [DATE_PICKER_SCRIPT]), "date_picker dark snapshot valid")
	H.cover(self, "selection.date_picker", "element", snap_dark, "Modal input and date range variants in dark mode")
	stage_dark.dispose()

# ==============================================================================
# 4. selection.time_picker
# ==============================================================================

func test_time_picker_variants_and_interaction() -> void:
	var stage = await H.create_stage(self, "selection", "time_picker_variants", false)

	# 1) Dial mode (Hour selection, AM)
	var tp_dial := M3TimePicker.new()
	tp_dial.name = "DialTimePicker"
	tp_dial.time_mode = M3TimePicker.TimeMode.DIAL
	tp_dial.selected_hour = 7
	tp_dial.selected_minute = 30
	tp_dial.is_pm = false
	tp_dial.selecting_minutes = false
	stage.add(tp_dial, Vector2(32, 120))

	# 2) Dial mode (Minute selection, PM)
	var tp_min := M3TimePicker.new()
	tp_min.name = "MinuteDialTimePicker"
	tp_min.time_mode = M3TimePicker.TimeMode.DIAL
	tp_min.selected_hour = 10
	tp_min.selected_minute = 45
	tp_min.is_pm = true
	tp_min.selecting_minutes = true
	stage.add(tp_min, Vector2(392, 120))

	# 3) Input mode
	var tp_input := M3TimePicker.new()
	tp_input.name = "InputTimePicker"
	tp_input.time_mode = M3TimePicker.TimeMode.INPUT
	tp_input.selected_hour = 9
	tp_input.selected_minute = 15
	tp_input.is_pm = false
	stage.add(tp_input, Vector2(752, 120))

	var snap: Dictionary = await H.snapshot(stage, "selection.time_picker", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [TIME_PICKER_SCRIPT]), "time_picker snapshot valid")

	var dial_entry: Dictionary = H.node_entry(snap, "DialTimePicker")
	assert_approx(float(dial_entry.get("screen_rect", {}).get("width", 0.0)), 328.0, 1.0, "time picker width = 328dp")
	assert_approx(float(dial_entry.get("screen_rect", {}).get("height", 0.0)), 420.0, 1.0, "time picker height = 420dp")

	await H.assert_pixel(
		self, stage, stage.point_of(tp_dial, Vector2(200, 20)),
		M3ThemeSingleton.get_instance().get_color(&"surface_container_high"),
		0.08, "time picker container = surface_container_high"
	)
	H.cover(self, "selection.time_picker", "element", snap, "Dial hour, dial minute, AM/PM, and input time picker variants")

	# Live interaction + animation: click hour 3 on dial, toggle PM, switch to minutes, click OK
	var changed_times: Array = []
	var confirmed_times: Array = []
	tp_dial.time_changed.connect(func(h: int, m: int, pm: bool) -> void: changed_times.append([h, m, pm]))
	tp_dial.time_confirmed.connect(func(h: int, m: int, pm: bool) -> void: confirmed_times.append([h, m, pm]))

	var live: Dictionary = await H.record(stage, "selection.time_picker", "dial_select_and_confirm", func() -> void:
		await stage.click(tp_dial, tp_dial.get_dial_hour_position(3))
		await stage.wait(16)
		await stage.click(tp_dial, M3TimePicker.PM_RECT.get_center())
		await stage.wait(6)
		await stage.click(tp_dial, M3TimePicker.MINUTE_BOX_RECT.get_center())
		await stage.wait(16)
		await stage.click(tp_dial._confirm_btn)
		await stage.wait(4)
	, 10, tp_dial)
	assert_true(H.assert_recording(self, live), "time_picker recording valid")
	H.assert_mutated(self, live, "DialTimePicker", "script_variables.selected_hour", 3)
	H.assert_mutated(self, live, "DialTimePicker", "script_variables.is_pm", true)
	H.assert_mutated(self, live, "DialTimePicker", "script_variables.selecting_minutes", true)
	H.assert_animated(self, live, "DialTimePicker", "script_variables.dial_angle", 4)
	assert_true(changed_times.size() >= 2, "time_changed emitted on dial & PM click")
	assert_eq(confirmed_times.size(), 1, "time_confirmed emitted on OK click")

	H.cover(self, "selection.time_picker", "interaction", live, "Clock dial hour click, AM/PM toggle, minute chip, and OK confirm")
	H.cover(self, "selection.time_picker", "animation", live, "Animated clock hand dial_angle tween")
	stage.dispose()

# ==============================================================================
# 5. selection.pickers.extended (24-Hour Dual-Ring Time Picker & Multi-Year Date Picker)
# ==============================================================================

func test_pickers_extended_24h_and_year_grid() -> void:
	var stage = await H.create_stage(self, "selection", "pickers_extended_24h_and_year", false)

	var tp_24 := M3TimePicker.new()
	tp_24.name = "DualRing24hTimePicker"
	tp_24.time_mode = M3TimePicker.TimeMode.DIAL
	tp_24.use_24_hour = true
	tp_24.selected_hour = 8
	tp_24.selected_minute = 15
	tp_24.selecting_minutes = false
	stage.add(tp_24, Vector2(40, 120))

	var dp_year := M3DatePicker.new()
	dp_year.name = "MultiYearDatePicker"
	dp_year.picker_mode = M3DatePicker.PickerMode.MODAL
	dp_year.selected_year = 2025
	dp_year.selected_month = 5
	dp_year.selected_day = 15
	stage.add(dp_year, Vector2(420, 120))

	assert_false(tp_24.is_inner_ring, "hour 8 starts on outer ring")
	assert_approx(tp_24.dial_hand_length, M3TimePicker.NUMBER_RADIUS, 0.5, "outer ring hand length = 96dp")

	# 1. Record selecting inner-ring hour 15 on 24h dial + opening Multi-Year Grid on DatePicker
	var live_open: Dictionary = await H.record(stage, "selection.pickers.extended", "select_inner_ring_and_open_year_grid", func() -> void:
		await stage.click(tp_24, tp_24.get_dial_hour_position(15))
		await stage.wait(16)
		await stage.click(dp_year.get_month_year_button())
		await stage.wait(16)
	, 10, tp_24)
	assert_true(H.assert_recording(self, live_open), "pickers extended recording valid")
	H.assert_mutated(self, live_open, "DualRing24hTimePicker", "script_variables.selected_hour", 15)
	H.assert_mutated(self, live_open, "DualRing24hTimePicker", "script_variables.is_inner_ring", true)
	H.assert_animated(self, live_open, "DualRing24hTimePicker", "script_variables.dial_hand_length", 4)
	H.assert_animated(self, live_open, "DualRing24hTimePicker", "script_variables.dial_angle", 4)
	H.assert_mutated(self, live_open, "MultiYearDatePicker", "script_variables.year_picker_open", true)
	H.assert_animated(self, live_open, "MultiYearDatePicker", "script_variables.year_picker_progress", 4)
	assert_approx(tp_24.dial_hand_length, M3TimePicker.INNER_NUMBER_RADIUS, 0.5, "inner ring hand length shortened to 62dp")
	H.cover(self, "selection.pickers.extended", "animation", live_open, "24h inner-ring dial_hand_length tween and year_picker_progress transition")

	# 2. Static snapshot showing 24h dual-ring dial (with inner ring selected) and open 3x5 Multi-Year Grid
	var snap: Dictionary = await H.snapshot(stage, "selection.pickers.extended", "dual_ring_24h_and_year_grid_light")
	assert_true(H.assert_snapshot(self, snap, [TIME_PICKER_SCRIPT, DATE_PICKER_SCRIPT]), "pickers extended snapshot valid")
	var y_grid_entry: Dictionary = H.node_entry(snap, "YearGridContainer")
	assert_eq(bool(y_grid_entry.get("visible", false)), true, "YearGridContainer visible in snapshot")
	H.cover(self, "selection.pickers.extended", "element", snap, "24-hour concentric dual-ring clock face and 3x5 Multi-Year Grid")

	# 3. Record clicking a year pill button (YearBtn_2028) to select year and return to calendar grid
	var picked_years: Array[int] = []
	dp_year.year_selected.connect(func(y: int) -> void: picked_years.append(y))

	var btn_2028: M3Button = dp_year.get_year_button(2028)
	assert_not_null(btn_2028, "YearBtn_2028 exists in YearGridContainer")

	var live_year_pick: Dictionary = await H.record(stage, "selection.pickers.extended", "pick_year_pill", func() -> void:
		await stage.click(btn_2028)
		await stage.wait(16)
	, 8, dp_year)
	assert_true(H.assert_recording(self, live_year_pick), "year pill click recording valid")
	H.assert_mutated(self, live_year_pick, "MultiYearDatePicker", "script_variables.selected_year", 2028)
	H.assert_mutated(self, live_year_pick, "MultiYearDatePicker", "script_variables.year_picker_open", false)
	assert_eq(picked_years, [2028], "year_selected signal emitted 2028")
	H.cover(self, "selection.pickers.extended", "interaction", live_year_pick, "24h inner/outer ring selection and multi-year pill click")
	stage.dispose()

# ==============================================================================
# 6. inputs.text_field.extended (Multiline Textarea & Prefix/Suffix Affixes)
# ==============================================================================

func test_text_field_extended_multiline_and_affixes() -> void:
	var stage = await H.create_stage(self, "inputs", "text_field_extended_variants", false)

	var tf_affix := M3TextField.new()
	tf_affix.name = "AffixCurrencyField"
	tf_affix.variant = M3TextField.Variant.OUTLINED
	tf_affix.label = "Amount"
	tf_affix.prefix_text = "$"
	tf_affix.suffix_text = "USD"
	tf_affix.size = Vector2(260, 56)
	stage.add(tf_affix, Vector2(40, 48))

	var tf_weight := M3TextField.new()
	tf_weight.name = "AffixWeightField"
	tf_weight.variant = M3TextField.Variant.FILLED
	tf_weight.label = "Package Weight"
	tf_weight.text = "14.5"
	tf_weight.suffix_text = "kg"
	tf_weight.helper_text = "Metric weight"
	tf_weight.size = Vector2(260, 76)
	stage.add(tf_weight, Vector2(340, 48))

	var tf_multi := M3TextField.new()
	tf_multi.name = "MultilineNotesField"
	tf_multi.variant = M3TextField.Variant.OUTLINED
	tf_multi.label = "Release Notes"
	tf_multi.multiline = true
	tf_multi.min_lines = 3
	tf_multi.max_lines = 6
	tf_multi.text = "Line 1\nLine 2\nLine 3"
	tf_multi.helper_text = "Auto-growing 3..6 lines"
	tf_multi.show_counter = true
	tf_multi.size = Vector2(320, 122)
	stage.add(tf_multi, Vector2(640, 48))

	var snap: Dictionary = await H.snapshot(stage, "inputs.text_field.extended", "affixes_and_multiline_light")
	assert_true(H.assert_snapshot(self, snap, [TEXT_FIELD_SCRIPT]), "extended text_field snapshot valid")
	var multi_entry: Dictionary = H.node_entry(snap, "MultilineNotesField")
	assert_gte(float(multi_entry.get("screen_rect", {}).get("height", 0.0)), 102.0, "multiline text field min_lines=3 height >= 102dp")
	H.cover(self, "inputs.text_field.extended", "element", snap, "Prefix/suffix affixes and multiline auto-expanding textarea")

	var live: Dictionary = await H.record(stage, "inputs.text_field.extended", "focus_affix_and_expand_multiline", func() -> void:
		await stage.click(tf_affix, Vector2(120, 28))
		await stage.wait(12)
		await stage.type_text("250")
		await stage.wait(6)
		tf_multi.append_line("Line 4")
		tf_multi.append_line("Line 5")
		await stage.wait(16)
	, 10, tf_multi)
	assert_true(H.assert_recording(self, live), "extended text_field recording valid")
	H.assert_mutated(self, live, "AffixCurrencyField", "script_variables.text", "250")
	H.assert_animated(self, live, "AffixCurrencyField", "script_variables._label_float_progress", 4)
	H.assert_animated(self, live, "MultilineNotesField", "script_variables._active_height", 4)
	assert_gt(tf_multi._active_height, 130.0, "multiline _active_height expanded from 102dp to 146dp for 5 lines")
	H.cover(self, "inputs.text_field.extended", "interaction", live, "Focus/type into prefix/suffix field and add lines to multiline field")
	H.cover(self, "inputs.text_field.extended", "animation", live, "Affix fade-in with _label_float_progress and multiline _active_height growth tween")
	stage.dispose()
