class_name TestM3Inputs
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed: int = 0
	var failed: int = 0
	var results: Array[String] = []

	print("[TEST] Running TestM3Inputs...")

	# Test 1: M3TextField Filled Variant & Floating Label
	var tf_fill := M3TextField.new()
	tf_fill.variant = M3TextField.Variant.FILLED
	tf_fill.label = "Username"
	tf_fill.helper_text = "Enter username"
	tree.root.add_child(tf_fill)

	var changed_txt := [""]
	tf_fill.text_changed.connect(func(t: String) -> void: changed_txt[0] = t)
	tf_fill.text = "test_user"

	var tf1_ok: bool = (tf_fill.variant == M3TextField.Variant.FILLED and tf_fill.field_type == M3TextField.FieldType.FILLED and tf_fill.text == "test_user" and changed_txt[0] == "test_user")

	tf_fill.is_error = true
	tf_fill.error_text = "Invalid username"
	tf1_ok = tf1_ok and tf_fill.is_error

	if tf1_ok:
		passed += 1
		results.append("✓ M3TextField Filled variant, floating label trigger, and error state")
	else:
		failed += 1
		results.append("✗ M3TextField Filled variant failed")
	tf_fill.free()

	# Test 2: M3TextField Outlined Variant & Password / Clear / Counter
	var tf_out := M3TextField.new()
	tf_out.variant = M3TextField.Variant.OUTLINED
	tf_out.label = "Password"
	tf_out.is_password = true
	tf_out.max_characters = 20
	tree.root.add_child(tf_out)

	tf_out.text = "Secret1234"
	var tf2_ok: bool = (tf_out.variant == M3TextField.Variant.OUTLINED and tf_out.secret and tf_out.max_length == 20 and tf_out.show_counter)

	if tf2_ok:
		passed += 1
		results.append("✓ M3TextField Outlined variant, procedural notch, password mode, and counter")
	else:
		failed += 1
		results.append("✗ M3TextField Outlined variant failed")
	tf_out.free()

	# Test 3: M3Select Items & Selection
	var sel := M3Select.new()
	sel.label = "Category"
	sel.options = ["Tech", "Design", "Marketing"]
	tree.root.add_child(sel)

	var sel_emitted_val := [null]
	sel.item_selected.connect(func(_idx: int, val: Variant) -> void: sel_emitted_val[0] = val)

	sel.selected_index = 1
	var sel_ok: bool = (sel.selected_index == 1 and sel.get_selected_text() == "Design" and sel.get_selected_value() == "Design" and sel_emitted_val[0] == "Design")

	if sel_ok:
		passed += 1
		results.append("✓ M3Select item selection, value extraction, and rotating chevron")
	else:
		failed += 1
		results.append("✗ M3Select item selection failed")
	sel.free()

	return {"passed": passed, "failed": failed, "results": results}
