class_name TestM3SelectionFamily
extends GDTestSuite

## Unit tests for the Material Design 3 Selection Family:
## M3Checkbox, M3Chip, M3Menu/M3MenuItem, M3Radio/M3RadioGroup, M3Slider, and M3Switch.

func test_checkbox_states_and_error() -> void:
	var cb: M3Checkbox = auto_add_child(M3Checkbox.new()) as M3Checkbox
	assert_eq(cb.check_state, M3Checkbox.CheckState.UNCHECKED)
	assert_false(cb.checked)
	assert_false(cb.is_error)

	var toggled_states: Array[bool] = []
	cb.toggled.connect(func(v: bool) -> void: toggled_states.append(v))

	cb.checked = true
	assert_eq(cb.check_state, M3Checkbox.CheckState.CHECKED)
	assert_eq(toggled_states, [true])

	cb.indeterminate = true
	assert_eq(cb.check_state, M3Checkbox.CheckState.INDETERMINATE)
	assert_true(cb.indeterminate)

	cb.is_error = true
	assert_true(cb.is_error)
	assert_true(cb.error)

	cb.tristate = true
	cb._on_pressed_action() # INDETERMINATE -> UNCHECKED
	assert_eq(cb.check_state, M3Checkbox.CheckState.UNCHECKED)
	cb._on_pressed_action() # UNCHECKED -> CHECKED
	assert_eq(cb.check_state, M3Checkbox.CheckState.CHECKED)
	cb._on_pressed_action() # CHECKED -> INDETERMINATE
	assert_eq(cb.check_state, M3Checkbox.CheckState.INDETERMINATE)

func test_chip_variants_toggle_and_close() -> void:
	var filter_chip: M3Chip = auto_add_child(M3Chip.new()) as M3Chip
	filter_chip.chip_type = M3Chip.ChipType.FILTER
	filter_chip.text = "Vegetarian"
	assert_false(filter_chip.selected)

	var toggled_vals: Array[bool] = []
	filter_chip.toggled.connect(func(v: bool) -> void: toggled_vals.append(v))
	filter_chip.selected = true
	assert_true(filter_chip.selected)
	assert_eq(toggled_vals, [true])

	var input_chip: M3Chip = auto_add_child(M3Chip.new()) as M3Chip
	input_chip.chip_type = M3Chip.ChipType.INPUT
	input_chip.avatar_text = "R"
	input_chip.text = "Reviewer"
	var closed: Array[int] = [0, 0]
	input_chip.close_pressed.connect(func() -> void: closed[0] += 1)
	input_chip.deleted.connect(func() -> void: closed[1] += 1)
	input_chip.remove_chip()
	assert_eq(closed[0], 1, "close_pressed emitted")
	assert_eq(closed[1], 1, "deleted emitted")

func test_menu_open_items_and_selection() -> void:
	var menu: M3Menu = auto_add_child(M3Menu.new()) as M3Menu
	var it1 := menu.add_menu_item("Rename", 1, &"edit", "F2")
	menu.add_divider()
	var it2 := menu.add_menu_item("Delete", 2, &"delete", "Del", true)
	assert_eq(menu.get_item_count(), 3)
	assert_eq(menu.get_item_control(0), it1)
	assert_true(it2.disabled)

	menu.open(Vector2(40, 40))
	assert_true(menu.visible)
	assert_true(menu.is_open)

	var selected_id: Array[int] = [-1]
	var selected_lbl: Array[String] = [""]
	menu.id_pressed.connect(func(id: int) -> void: selected_id[0] = id)
	menu.item_selected.connect(func(_id: int, lbl: String) -> void: selected_lbl[0] = lbl)

	menu._on_item_clicked(it1.id, it1.label)
	assert_eq(selected_id[0], 1)
	assert_eq(selected_lbl[0], "Rename")
	assert_false(menu.is_open)

func test_radio_and_radio_group_exclusivity() -> void:
	var group: M3RadioGroup = auto_add_child(M3RadioGroup.new()) as M3RadioGroup
	var r0 := group.add_radio("Small", "S")
	var r1 := group.add_radio("Medium", "M")
	var r2 := group.add_radio("Large", "L")

	var events: Array = []
	group.selection_changed.connect(func(_r: M3Radio, val: Variant) -> void: events.append(val))

	group.select(1)
	assert_false(r0.selected)
	assert_true(r1.selected)
	assert_false(r2.selected)
	assert_eq(group.selected_index, 1)
	assert_eq(group.get_selected_value(), "M")
	assert_eq(events, ["M"])

	r2.selected = true
	assert_false(r1.selected)
	assert_true(r2.selected)
	assert_eq(group.selected_index, 2)
	assert_eq(group.get_selected_value(), "L")

func test_slider_continuous_discrete_and_range() -> void:
	var sl: M3Slider = auto_add_child(M3Slider.new()) as M3Slider
	sl.min_value = 0.0
	sl.max_value = 100.0
	sl.is_discrete = true
	sl.step = 10.0
	sl.show_ticks = true
	sl.value = 34.0
	assert_approx(sl.value, 30.0, 0.01, "Discrete slider snaps 34 -> 30")

	sl.range_mode = true
	sl.start_value = 16.0
	sl.end_value = 84.0
	assert_approx(sl.start_value, 20.0, 0.01)
	assert_approx(sl.end_value, 80.0, 0.01)

func test_switch_toggle_and_icons() -> void:
	var sw: M3Switch = auto_add_child(M3Switch.new()) as M3Switch
	sw.show_icons = true
	assert_false(sw.selected)
	sw._on_pressed_action()
	assert_true(sw.selected)
	assert_true(sw.checked)
	sw._on_pressed_action()
	assert_false(sw.selected)

func test_slider_expressive_vertical_and_centered_zero() -> void:
	var sl: M3Slider = auto_add_child(M3Slider.new()) as M3Slider
	sl.min_value = -100.0
	sl.max_value = 100.0
	sl.centered_zero = true
	sl.slider_size = M3Slider.SliderSize.LARGE
	sl.value = -40.0
	assert_approx(sl.value, -40.0, 0.01)
	assert_approx(sl._get_track_thickness(), 40.0, 0.01)

	sl.orientation = M3Slider.Orientation.VERTICAL
	assert_eq(sl.orientation, M3Slider.Orientation.VERTICAL)
	assert_gte(sl.custom_minimum_size.y, 200.0)

func test_menu_cascading_submenu_and_grouped() -> void:
	var sub: M3Menu = auto_add_child(M3Menu.new()) as M3Menu
	sub.add_menu_item("Sub Action", 101)

	var root_menu: M3Menu = auto_add_child(M3Menu.new()) as M3Menu
	root_menu.add_menu_item("First", 1)
	root_menu.add_submenu_item(2, "More", sub, &"share")
	root_menu.add_group_break()
	root_menu.add_menu_item("Second Group", 3)

	assert_true(root_menu.expressive_grouped)
	assert_eq(root_menu.get_group_count(), 2)
	root_menu.show_immediate(Vector2(50, 50))
	root_menu.open_submenu_for_item(2)
	assert_eq(root_menu.active_submenu, sub)
	assert_true(sub.is_open)
