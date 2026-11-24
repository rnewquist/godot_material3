class_name TestM3Adaptive
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed := 0
	var failed := 0
	var results: Array[String] = []
	
	print("[TEST] Running TestM3Adaptive...")
	
	var adaptive := M3AdaptiveNavigation.new()
	adaptive.destinations = [
		{"label": "Screen 1"},
		{"label": "Screen 2"},
		{"label": "Screen 3"}
	]
	
	tree.root.add_child(adaptive)
	
	var scr1 := Control.new()
	var scr2 := Control.new()
	var scr3 := Control.new()
	adaptive.add_screen(scr1)
	adaptive.add_screen(scr2)
	adaptive.add_screen(scr3)
	
	# Test 1: Expanded Mode (>840px)
	adaptive.width_override = 1000.0
	
	var is_expanded_ok := (adaptive.current_mode == M3AdaptiveNavigation.LayoutMode.EXPANDED and adaptive._nav_drawer != null and adaptive._nav_drawer.visible and not adaptive._nav_bar.visible)
	if is_expanded_ok:
		passed += 1
		results.append("✓ M3AdaptiveNavigation Expanded layout (>840px)")
	else:
		failed += 1
		results.append("✗ M3AdaptiveNavigation Expanded layout failed")
		
	# Test 2: Medium Mode (600px - 840px)
	adaptive.width_override = 700.0
	
	var is_medium_ok := (adaptive.current_mode == M3AdaptiveNavigation.LayoutMode.MEDIUM and adaptive._nav_rail != null and adaptive._nav_rail.visible and not adaptive._nav_drawer.visible)
	if is_medium_ok:
		passed += 1
		results.append("✓ M3AdaptiveNavigation Medium layout (600 - 840px)")
	else:
		failed += 1
		results.append("✗ M3AdaptiveNavigation Medium layout failed")
		
	# Test 3: Compact Mode (<600px)
	adaptive.width_override = 400.0
	
	var is_compact_ok := (adaptive.current_mode == M3AdaptiveNavigation.LayoutMode.COMPACT and adaptive._nav_bar != null and adaptive._nav_bar.visible and not adaptive._nav_rail.visible)
	if is_compact_ok:
		passed += 1
		results.append("✓ M3AdaptiveNavigation Compact layout (<600px)")
	else:
		failed += 1
		results.append("✗ M3AdaptiveNavigation Compact layout failed")
		
	# Test 4: Destination Preservation Across Resizes
	adaptive.selected_index = 2
	adaptive.width_override = 1200.0
	
	var is_sel_preserved := (adaptive.selected_index == 2 and adaptive._nav_drawer != null and adaptive._nav_drawer.selected_index == 2 and scr3.visible and not scr1.visible)
	if is_sel_preserved:
		passed += 1
		results.append("✓ M3AdaptiveNavigation destination and screen preservation across resizes")
	else:
		failed += 1
		results.append("✗ M3AdaptiveNavigation destination preservation failed")
		
	adaptive.free()
	
	return {"passed": passed, "failed": failed, "results": results}
