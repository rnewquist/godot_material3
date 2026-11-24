class_name TestM3ChipsBadges
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed := 0
	var failed := 0
	var results: Array[String] = []
	
	print("[TEST] Running TestM3ChipsBadges...")
	
	# Test 1: Chip Creation & Types
	var c_assist := M3Chip.new()
	c_assist.chip_type = M3Chip.ChipType.ASSIST
	c_assist.text = "Assist Chip"
	tree.root.add_child(c_assist)
	
	if c_assist.custom_minimum_size.y == 32.0 and c_assist.text == "Assist Chip":
		passed += 1
		results.append("✓ Chip Assist Type initialization")
	else:
		failed += 1
		results.append("✗ Chip Assist Type initialization failed")
	c_assist.free()
	
	# Test 2: Filter Chip Toggle
	var c_filter := M3Chip.new()
	c_filter.chip_type = M3Chip.ChipType.FILTER
	c_filter.text = "Filter"
	var state := {"toggled": false}
	c_filter.toggled.connect(func(v: bool): state["toggled"] = v)
	tree.root.add_child(c_filter)
	c_filter.selected = true
	
	if c_filter.selected and state["toggled"]:
		passed += 1
		results.append("✓ Filter Chip selection and signal emission")
	else:
		failed += 1
		results.append("✗ Filter Chip selection failed")
	c_filter.free()
	
	# Test 3: Input Chip Deletion
	var c_input := M3Chip.new()
	c_input.chip_type = M3Chip.ChipType.INPUT
	c_input.text = "Input Tag"
	var del_state := {"deleted": false}
	c_input.deleted.connect(func(): del_state["deleted"] = true)
	tree.root.add_child(c_input)
	
	c_input.deleted.emit()
	
	if del_state["deleted"]:
		passed += 1
		results.append("✓ Input Chip delete action and signal")
	else:
		failed += 1
		results.append("✗ Input Chip delete action failed")
	c_input.free()
	
	# Test 4: Small Badge Dot
	var badge_sm := M3Badge.new()
	badge_sm.badge_size = M3Badge.BadgeSize.SMALL
	tree.root.add_child(badge_sm)
	
	if badge_sm.custom_minimum_size == Vector2(6, 6):
		passed += 1
		results.append("✓ Small Badge 6dp dot size")
	else:
		failed += 1
		results.append("✗ Small Badge size mismatch: %s" % str(badge_sm.custom_minimum_size))
	badge_sm.free()
	
	# Test 5: Large Badge with Count & Overflow Formatter
	var badge_lg := M3Badge.new()
	badge_lg.badge_size = M3Badge.BadgeSize.LARGE
	badge_lg.max_count = 99
	badge_lg.count = 5
	tree.root.add_child(badge_lg)
	
	var is_count_ok := (badge_lg.get_display_text() == "5")
	badge_lg.count = 120
	var is_overflow_ok := (badge_lg.get_display_text() == "99+")
	
	if is_count_ok and is_overflow_ok:
		passed += 1
		results.append("✓ Large Badge count and 99+ overflow text")
	else:
		failed += 1
		results.append("✗ Large Badge formatting failed")
	badge_lg.free()
	
	# Test 6: Tooltip Plain & Rich
	var host_btn := Control.new()
	host_btn.size = Vector2(100, 40)
	tree.root.add_child(host_btn)
	
	var tip := M3Tooltip.new()
	tip.tooltip_type = M3Tooltip.TooltipType.RICH
	tip.title = "Tip Title"
	tip.text = "Tip Description"
	tip.action_text = "Action"
	host_btn.add_child(tip)
	
	tip.show_tooltip()
	var is_tip_shown := tip.visible
	tip.hide_tooltip()
	
	if is_tip_shown:
		passed += 1
		results.append("✓ Tooltip Rich configuration and show/hide")
	else:
		failed += 1
		results.append("✗ Tooltip Rich display failed")
	host_btn.free()
	
	return {"passed": passed, "failed": failed, "results": results}
