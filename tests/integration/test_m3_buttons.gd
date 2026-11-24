class_name TestM3Buttons
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed: int = 0
	var failed: int = 0
	var results: Array[String] = []

	print("[TEST] Running TestM3Buttons...")

	# Test 1: Button Variants & Properties
	var btn := M3Button.new()
	btn.variant = M3Button.Variant.FILLED
	btn.text = "Filled Button"
	btn.leading_icon = &"add"
	btn.trailing_icon = &"arrow_right"
	tree.root.add_child(btn)

	var v_ok: bool = (btn.variant == M3Button.Variant.FILLED and btn.button_type == M3Button.ButtonType.FILLED and btn.leading_icon == &"add")
	btn.variant = M3Button.Variant.ELEVATED
	v_ok = v_ok and (btn.variant == M3Button.Variant.ELEVATED and btn.button_type == M3Button.ButtonType.ELEVATED)
	btn.variant = M3Button.Variant.TONAL
	v_ok = v_ok and (btn.variant == M3Button.Variant.TONAL and btn.button_type == M3Button.ButtonType.FILLED_TONAL)
	btn.variant = M3Button.Variant.OUTLINED
	v_ok = v_ok and (btn.variant == M3Button.Variant.OUTLINED and btn.button_type == M3Button.ButtonType.OUTLINED)
	btn.variant = M3Button.Variant.TEXT
	v_ok = v_ok and (btn.variant == M3Button.Variant.TEXT and btn.button_type == M3Button.ButtonType.TEXT)

	if v_ok:
		passed += 1
		results.append("✓ M3Button variants (Filled, Elevated, Tonal, Outlined, Text) and icon slots")
	else:
		failed += 1
		results.append("✗ M3Button variant initialization failed")

	# Test 2: Button Click, Toggle & Disabled State
	var click_count := [0]
	btn.pressed.connect(func() -> void: click_count[0] += 1)
	btn.toggle_mode = true
	var toggle_state := [false]
	btn.toggled.connect(func(v: bool) -> void: toggle_state[0] = v)

	btn._on_pressed_action()
	var toggle_ok: bool = (click_count[0] == 1 and btn.button_pressed and toggle_state[0])
	btn._on_pressed_action()
	toggle_ok = toggle_ok and (click_count[0] == 2 and not btn.button_pressed and not toggle_state[0])

	btn.disabled = true
	var dis_ok: bool = (btn.current_state == M3Control.ControlState.DISABLED)
	btn.disabled = false
	dis_ok = dis_ok and (btn.current_state == M3Control.ControlState.NORMAL)

	if toggle_ok and dis_ok:
		passed += 1
		results.append("✓ M3Button click, toggle mode, and disabled state machine")
	else:
		failed += 1
		results.append("✗ M3Button click/toggle/disabled state failed")
	btn.free()

	# Test 3: M3IconButton Variants & Toggle
	var ibtn := M3IconButton.new()
	ibtn.variant = M3IconButton.Variant.STANDARD
	ibtn.icon_name = &"favorite"
	ibtn.selected_icon_name = &"checkmark"
	ibtn.toggle_mode = true
	tree.root.add_child(ibtn)

	var icon_clicked := [false]
	ibtn.toggled.connect(func(v: bool) -> void: icon_clicked[0] = v)
	ibtn._on_pressed_action()

	var ibtn_ok: bool = (ibtn.button_pressed and icon_clicked[0])
	ibtn.variant = M3IconButton.Variant.FILLED
	ibtn_ok = ibtn_ok and (ibtn.icon_button_type == M3IconButton.IconBtnType.FILLED)
	ibtn.variant = M3IconButton.Variant.TONAL
	ibtn_ok = ibtn_ok and (ibtn.icon_button_type == M3IconButton.IconBtnType.FILLED_TONAL)

	if ibtn_ok:
		passed += 1
		results.append("✓ M3IconButton variants, icon toggle, and states")
	else:
		failed += 1
		results.append("✗ M3IconButton test failed")
	ibtn.free()

	# Test 4: M3FAB Variants & Sizes
	var fab := M3FAB.new()
	fab.fab_variant = M3FAB.FabVariant.SMALL
	tree.root.add_child(fab)

	var fab_ok: bool = (fab.custom_minimum_size == Vector2(40, 40) and fab.fab_size == M3FAB.FabSize.SMALL)
	fab.fab_variant = M3FAB.FabVariant.STANDARD
	fab_ok = fab_ok and (fab.custom_minimum_size == Vector2(56, 56) and fab.fab_size == M3FAB.FabSize.STANDARD)
	fab.fab_variant = M3FAB.FabVariant.LARGE
	fab_ok = fab_ok and (fab.custom_minimum_size == Vector2(96, 96) and fab.fab_size == M3FAB.FabSize.LARGE)
	fab.fab_variant = M3FAB.FabVariant.EXTENDED
	fab.label = "Extended Action"
	fab_ok = fab_ok and (fab.custom_minimum_size.x >= 80.0 and fab.custom_minimum_size.y == 56.0)

	var fab_pressed := [false]
	fab.pressed.connect(func() -> void: fab_pressed[0] = true)
	fab._on_pressed_action()
	fab_ok = fab_ok and fab_pressed[0]

	if fab_ok:
		passed += 1
		results.append("✓ M3FAB sizes (Small 40dp, Standard 56dp, Large 96dp, Extended) & elevation")
	else:
		failed += 1
		results.append("✗ M3FAB sizing/variants failed")
	fab.free()

	# Test 5: M3SegmentedButtonGroup & M3SegmentedButton
	var group := M3SegmentedButtonGroup.new()
	tree.root.add_child(group)

	var seg1 := group.add_segment("First", &"star")
	var seg2 := group.add_segment("Second")
	var seg3 := group.add_segment("Third")

	group._update_segment_positions()
	var seg_ok: bool = (seg1.is_first and seg3.is_last and not seg2.is_first and not seg2.is_last)

	var sel_item := [-1]
	group.item_selected.connect(func(idx: int) -> void: sel_item[0] = idx)
	group.select(1)

	seg_ok = seg_ok and (group.selected_index == 1 and seg2.selected and not seg1.selected and sel_item[0] == 1)

	group.multi_select = true
	group.select(0)
	seg_ok = seg_ok and (group.selected_indices.has(0) and group.selected_indices.has(1))

	if seg_ok:
		passed += 1
		results.append("✓ M3SegmentedButtonGroup single/multi select & dynamic corner styling")
	else:
		failed += 1
		results.append("✗ M3SegmentedButtonGroup selection failed")
	group.free()

	return {"passed": passed, "failed": failed, "results": results}
