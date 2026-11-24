class_name TestM3Progress
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed := 0
	var failed := 0
	var results: Array[String] = []
	
	print("[TEST] Running TestM3Progress...")
	
	# Test 1: Linear Progress Determinate & Indeterminate
	var lin := M3LinearProgress.new()
	tree.root.add_child(lin)
	
	lin.value = 0.75
	var val_ok := is_equal_approx(lin.value, 0.75)
	lin.indeterminate = true
	var indet_ok := lin.indeterminate
	
	if val_ok and indet_ok:
		passed += 1
		results.append("✓ M3LinearProgress determinate & indeterminate modes")
	else:
		failed += 1
		results.append("✗ M3LinearProgress configuration failed")
	lin.free()
	
	# Test 2: Circular Progress Determinate & Indeterminate
	var circ := M3CircularProgress.new()
	tree.root.add_child(circ)
	
	circ.value = 0.5
	var circ_val_ok := is_equal_approx(circ.value, 0.5)
	circ.indeterminate = true
	var circ_indet_ok := circ.indeterminate
	
	if circ_val_ok and circ_indet_ok:
		passed += 1
		results.append("✓ M3CircularProgress determinate & indeterminate modes")
	else:
		failed += 1
		results.append("✗ M3CircularProgress configuration failed")
	circ.free()
	
	# Test 3: Snackbar Show and Action
	var snack := M3Snackbar.new()
	snack.message = "File Saved"
	snack.action_label = "Undo"
	var state := {"action": false}
	snack.action_pressed.connect(func(): state["action"] = true)
	tree.root.add_child(snack)
	
	snack.action_pressed.emit()
	if state["action"]:
		passed += 1
		results.append("✓ M3Snackbar message and action callback")
	else:
		failed += 1
		results.append("✗ M3Snackbar action failed")
	snack.free()
	
	# Test 4: Banner Actions & Dismiss
	var banner := M3Banner.new()
	banner.text = "Update Available"
	banner.action_1_label = "Update"
	banner.action_2_label = "Dismiss"
	var banner_state := {"a1": false, "dismissed": false}
	banner.action_1_pressed.connect(func(): banner_state["a1"] = true)
	banner.dismissed.connect(func(): banner_state["dismissed"] = true)
	tree.root.add_child(banner)
	
	banner.action_1_pressed.emit()
	banner.dismissed.emit()
	
	if banner_state["a1"] and banner_state["dismissed"]:
		passed += 1
		results.append("✓ M3Banner action triggers and dismiss")
	else:
		failed += 1
		results.append("✗ M3Banner actions failed")
	banner.free()
	
	# Test 5: Menu & MenuItem
	var menu := M3Menu.new()
	var menu_state := {"sel_id": -1}
	menu.item_selected.connect(func(id: int, _lbl: String): menu_state["sel_id"] = id)
	tree.root.add_child(menu)
	
	var item := menu.add_menu_item("Save", 42)
	menu._on_item_clicked(item.id, item.label)
	
	if menu_state["sel_id"] == 42:
		passed += 1
		results.append("✓ M3Menu and M3MenuItem click selection")
	else:
		failed += 1
		results.append("✗ M3Menu selection failed")
	menu.free()
	
	return {"passed": passed, "failed": failed, "results": results}
