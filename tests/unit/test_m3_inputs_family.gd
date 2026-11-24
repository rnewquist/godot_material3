class_name TestM3InputsFamily
extends GDTestSuite

## Unit tests for M3TextField, M3Select, M3SelectDropdown, M3DatePicker, and M3TimePicker.

func test_text_field_properties_and_signals() -> void:
	var tf := autofree(M3TextField.new()) as M3TextField
	auto_add_child(tf)

	assert_eq(tf.variant, M3TextField.Variant.FILLED)
	tf.field_type = M3TextField.FieldType.OUTLINED
	assert_eq(tf.variant, M3TextField.Variant.OUTLINED)

	var watcher := GDSignalWatcher.watch(tf, &"text_changed")
	tf.text = "Hello M3"
	assert_true(watcher.is_emitted(), "text_changed should emit when text is modified")
	assert_eq(tf.text, "Hello M3")

	tf.supporting_text = "Helper"
	assert_eq(tf.helper_text, "Helper")
	tf.max_characters = 25
	assert_eq(tf.max_length, 25)
	assert_true(tf.show_counter)

	tf.is_password = true
	assert_true(tf.secret)
	assert_true(tf.show_password_toggle)

func test_select_and_select_dropdown() -> void:
	var sel := autofree(M3Select.new()) as M3Select
	auto_add_child(sel)

	sel.add_item("Alpha", "a")
	sel.add_item("Beta", "b")
	sel.add_item("Gamma", "g")
	assert_eq(sel.items.size(), 3)

	var watcher := GDSignalWatcher.watch(sel, &"item_selected")
	sel.selected_index = 1
	assert_true(watcher.is_emitted())
	assert_eq(sel.get_selected_text(), "Beta")
	assert_eq(str(sel.get_selected_value()), "b")

	sel.open_dropdown()
	assert_true(sel.is_open)
	assert_not_null(sel.get_dropdown_panel())
	sel.close_dropdown()
	assert_false(sel.is_open)

	var drop := autofree(M3SelectDropdown.new()) as M3SelectDropdown
	auto_add_child(drop)
	drop.options = ["One", "Two", "Three"]
	drop.selected_index = 2
	assert_eq(drop.get_selected_value(), "Three")

func test_date_picker_formatting_and_selection() -> void:
	var dp := autofree(M3DatePicker.new()) as M3DatePicker
	auto_add_child(dp)

	assert_eq(dp.selected_year, 2025)
	assert_eq(dp.selected_month, 5)
	assert_eq(dp.selected_day, 15)
	assert_eq(dp.get_formatted_headline(), "Thu, May 15")

	var sel_watcher := GDSignalWatcher.watch(dp, &"date_selected")
	dp.select_day(24)
	assert_true(sel_watcher.is_emitted())
	assert_eq(dp.selected_day, 24)
	assert_eq(dp.get_formatted_headline(), "Sat, May 24")

	dp.range_selection = true
	dp.range_start_day = 10
	dp.range_end_day = 18
	assert_eq(dp.get_formatted_headline(), "May 10 – May 18")

	var mode_watcher := GDSignalWatcher.watch(dp, &"mode_changed")
	dp.picker_mode = M3DatePicker.PickerMode.INPUT
	assert_true(mode_watcher.is_emitted())
	assert_eq(dp.mode, M3DatePicker.PickerMode.INPUT)

func test_time_picker_modes_and_angles() -> void:
	var tp := autofree(M3TimePicker.new()) as M3TimePicker
	auto_add_child(tp)

	assert_eq(tp.selected_hour, 7)
	assert_eq(tp.selected_minute, 30)
	assert_false(tp.is_pm)
	assert_false(tp.selecting_minutes)

	var pos_3 := tp.get_dial_hour_position(3)
	assert_gt(pos_3.x, M3TimePicker.DIAL_CENTER.x, "3 o'clock is to the right of dial center")

	var pos_12 := tp.get_dial_hour_position(12)
	assert_lt(pos_12.y, M3TimePicker.DIAL_CENTER.y, "12 o'clock is above dial center")

	var mode_watcher := GDSignalWatcher.watch(tp, &"mode_changed")
	tp.time_mode = M3TimePicker.TimeMode.INPUT
	assert_true(mode_watcher.is_emitted())
	assert_eq(tp.mode, M3TimePicker.TimeMode.INPUT)

func test_pickers_24_hour_dual_ring_and_year_grid() -> void:
	var tp := autofree(M3TimePicker.new()) as M3TimePicker
	auto_add_child(tp)
	tp.use_24_hour = true
	tp.selected_hour = 6
	assert_false(tp.is_inner_ring)
	tp.selected_hour = 18
	assert_true(tp.is_inner_ring)
	var p6 := tp.get_dial_hour_position(6)
	var p18 := tp.get_dial_hour_position(18)
	assert_gt(p6.distance_to(M3TimePicker.DIAL_CENTER), p18.distance_to(M3TimePicker.DIAL_CENTER), "outer ring radius > inner ring radius")

	var dp := autofree(M3DatePicker.new()) as M3DatePicker
	auto_add_child(dp)
	dp.set_year_picker_open(true)
	assert_true(dp.year_picker_open)
	assert_not_null(dp.get_year_button(2028))
	var yr_watcher := GDSignalWatcher.watch(dp, &"year_selected")
	dp.select_year(2028)
	assert_true(yr_watcher.is_emitted())
	assert_eq(dp.selected_year, 2028)
	assert_false(dp.year_picker_open)

func test_text_field_multiline_and_affixes() -> void:
	var tf := autofree(M3TextField.new()) as M3TextField
	auto_add_child(tf)
	tf.prefix_text = "$"
	tf.suffix_text = "USD"
	assert_gt(tf._get_prefix_offset(), 0.0)
	assert_gt(tf._get_suffix_offset(), 0.0)

	tf.multiline = true
	tf.min_lines = 3
	tf.max_lines = 6
	assert_approx(tf._active_height, 102.0, 0.5)
	tf.text = "L1\nL2\nL3\nL4\nL5"
	assert_eq(tf.get_visual_line_count(), 5)
