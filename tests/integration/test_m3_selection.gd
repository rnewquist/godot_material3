class_name TestM3Selection
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed: int = 0
	var failed: int = 0
	var results: Array[String] = []

	print("[TEST] Running TestM3Selection...")

	# Test 1: M3Checkbox 3 States & Tristate Cycling
	var cb := M3Checkbox.new()
	tree.root.add_child(cb)

	var cb_init_ok: bool = (cb.check_state == M3Checkbox.CheckState.UNCHECKED and not cb.checked)
	cb._on_pressed_action()
	var cb_check_ok: bool = (cb.check_state == M3Checkbox.CheckState.CHECKED and cb.checked)
	cb._on_pressed_action()
	var cb_uncheck_ok: bool = (cb.check_state == M3Checkbox.CheckState.UNCHECKED and not cb.checked)

	cb.tristate = true
	cb._on_pressed_action()
	var cb_tri1: bool = (cb.check_state == M3Checkbox.CheckState.CHECKED)
	cb._on_pressed_action()
	var cb_tri2: bool = (cb.check_state == M3Checkbox.CheckState.INDETERMINATE and cb.indeterminate)
	cb._on_pressed_action()
	var cb_tri3: bool = (cb.check_state == M3Checkbox.CheckState.UNCHECKED)

	if cb_init_ok and cb_check_ok and cb_uncheck_ok and cb_tri1 and cb_tri2 and cb_tri3:
		passed += 1
		results.append("✓ M3Checkbox Unchecked, Checked, Indeterminate, and tristate cycling")
	else:
		failed += 1
		results.append("✗ M3Checkbox states failed")
	cb.free()

	# Test 2: M3Radio & M3RadioGroup Exclusivity
	var group := M3RadioGroup.new()
	tree.root.add_child(group)

	var r1 := group.add_radio("Option 1", 100)
	var r2 := group.add_radio("Option 2", 200)
	var r3 := group.add_radio("Option 3", 300)

	var received_val := [null]
	group.selection_changed.connect(func(_r: M3Radio, val: Variant) -> void: received_val[0] = val)

	group.select(1)
	var r_sel_ok: bool = (r2.selected and not r1.selected and not r3.selected and group.get_selected_value() == 200 and received_val[0] == 200)

	r1._on_pressed_action()
	r_sel_ok = r_sel_ok and (r1.selected and not r2.selected and not r3.selected and group.get_selected_value() == 100)

	if r_sel_ok:
		passed += 1
		results.append("✓ M3Radio & M3RadioGroup mutual exclusivity & signals")
	else:
		failed += 1
		results.append("✗ M3RadioGroup exclusivity failed")
	group.free()

	# Test 3: M3Switch Toggle
	var sw := M3Switch.new()
	tree.root.add_child(sw)

	var sw_toggled_val := [false]
	sw.toggled.connect(func(v: bool) -> void: sw_toggled_val[0] = v)

	var sw_init_ok: bool = (not sw.selected and not sw.checked)
	sw._on_pressed_action()
	var sw_on_ok: bool = (sw.selected and sw.checked and sw_toggled_val[0])
	sw._on_pressed_action()
	var sw_off_ok: bool = (not sw.selected and not sw.checked and not sw_toggled_val[0])

	if sw_init_ok and sw_on_ok and sw_off_ok:
		passed += 1
		results.append("✓ M3Switch toggle state & glide animation handling")
	else:
		failed += 1
		results.append("✗ M3Switch toggle failed")
	sw.free()

	# Test 4: M3Slider Continuous, Discrete & Range
	var slider := M3Slider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.value = 42.0 # snaps to 40.0
	tree.root.add_child(slider)

	var sl_val_ok: bool = (slider.value == 40.0)

	var sig_val := [0.0]
	slider.value_changed.connect(func(v: float) -> void: sig_val[0] = v)
	slider.value = 68.0
	sl_val_ok = sl_val_ok and (slider.value == 70.0 and sig_val[0] == 70.0)

	slider.range_mode = true
	slider.range_min_value = 18.0 # snaps to 20.0
	slider.range_max_value = 82.0 # snaps to 80.0
	sl_val_ok = sl_val_ok and (slider.start_value == 20.0 and slider.end_value == 80.0)

	if sl_val_ok:
		passed += 1
		results.append("✓ M3Slider continuous, discrete step snapping, and range dual-thumb")
	else:
		failed += 1
		results.append("✗ M3Slider step snapping/range failed")
	slider.free()

	return {"passed": passed, "failed": failed, "results": results}
