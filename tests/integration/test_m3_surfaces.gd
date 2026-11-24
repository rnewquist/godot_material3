class_name TestM3Surfaces
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed := 0
	var failed := 0
	var results: Array[String] = []
	
	print("[TEST] Running TestM3Surfaces...")
	
	# Test 1: M3Card Variants & Clickable
	var card := M3Card.new()
	card.card_type = M3Card.CardType.ELEVATED
	card.clickable = true
	var state := {"clicked": false}
	card.clicked.connect(func(): state["clicked"] = true)
	tree.root.add_child(card)
	
	card.clicked.emit()
	
	if state["clicked"]:
		passed += 1
		results.append("✓ M3Card elevated click interaction")
	else:
		failed += 1
		results.append("✗ M3Card click interaction failed")
	card.free()
	
	# Test 2: M3Dialog Setup & Confirm/Cancel
	var dlg := M3Dialog.new()
	dlg.headline = "Confirm Action"
	dlg.body_text = "Are you sure you want to proceed?"
	dlg.confirm_label = "Yes"
	dlg.cancel_label = "No"
	var dlg_state := {"confirmed": false}
	dlg.confirmed.connect(func(): dlg_state["confirmed"] = true)
	tree.root.add_child(dlg)
	
	dlg.show_dialog()
	var is_dlg_open := dlg.visible
	dlg.confirmed.emit()
	
	if is_dlg_open and dlg_state["confirmed"]:
		passed += 1
		results.append("✓ M3Dialog show and confirm signal")
	else:
		failed += 1
		results.append("✗ M3Dialog confirm flow failed")
	dlg.free()
	
	# Test 3: M3BottomSheet Setup & Open/Close
	var sheet := M3BottomSheet.new()
	sheet.sheet_type = M3BottomSheet.SheetType.MODAL
	sheet.sheet_height = 200.0
	tree.root.add_child(sheet)
	
	sheet.open_sheet()
	var is_sheet_open := sheet.is_open and sheet.visible
	sheet.close_sheet()
	
	if is_sheet_open:
		passed += 1
		results.append("✓ M3BottomSheet open and close handling")
	else:
		failed += 1
		results.append("✗ M3BottomSheet open failed")
	sheet.free()
	
	# Test 4: M3ListItem Lines Heights
	var item1 := M3ListItem.new()
	item1.lines = M3ListItem.ItemLines.ONE_LINE
	tree.root.add_child(item1)
	
	var item2 := M3ListItem.new()
	item2.lines = M3ListItem.ItemLines.TWO_LINE
	tree.root.add_child(item2)
	
	var item3 := M3ListItem.new()
	item3.lines = M3ListItem.ItemLines.THREE_LINE
	tree.root.add_child(item3)
	
	if item1.custom_minimum_size.y == 56.0 and item2.custom_minimum_size.y == 72.0 and item3.custom_minimum_size.y == 88.0:
		passed += 1
		results.append("✓ M3ListItem 1-line (56dp), 2-line (72dp), 3-line (88dp) heights")
	else:
		failed += 1
		results.append("✗ M3ListItem height mismatch")
	item1.free()
	item2.free()
	item3.free()
	
	# Test 5: M3Divider Orientations
	var div_h := M3Divider.new()
	div_h.orientation = M3Divider.DividerOrientation.HORIZONTAL
	div_h.thickness = 1.0
	tree.root.add_child(div_h)
	
	var div_v := M3Divider.new()
	div_v.orientation = M3Divider.DividerOrientation.VERTICAL
	div_v.thickness = 2.0
	tree.root.add_child(div_v)
	
	if div_h.custom_minimum_size.y == 1.0 and div_v.custom_minimum_size.x == 2.0:
		passed += 1
		results.append("✓ M3Divider horizontal & vertical configurations")
	else:
		failed += 1
		results.append("✗ M3Divider size configuration failed")
	div_h.free()
	div_v.free()
	
	return {"passed": passed, "failed": failed, "results": results}
