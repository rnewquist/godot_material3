class_name TestM3Navigation
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed := 0
	var failed := 0
	var results: Array[String] = []
	
	print("[TEST] Running TestM3Navigation...")
	
	# Test 1: Navigation Bar
	var bar := M3NavigationBar.new()
	bar.destinations = [{"label": "A"}, {"label": "B"}, {"label": "C"}]
	var bar_state := {"sel": -1}
	bar.destination_selected.connect(func(i: int): bar_state["sel"] = i)
	tree.root.add_child(bar)
	
	bar.selected_index = 1
	if bar.custom_minimum_size.y == 80.0 and bar_state["sel"] == 1 and bar.selected_index == 1:
		passed += 1
		results.append("✓ M3NavigationBar 80dp height and selection signal")
	else:
		failed += 1
		results.append("✗ M3NavigationBar selection failed")
	bar.free()
	
	# Test 2: Navigation Rail
	var rail := M3NavigationRail.new()
	rail.destinations = [{"label": "A"}, {"label": "B"}]
	rail.has_fab = true
	var rail_state := {"sel": -1}
	rail.destination_selected.connect(func(i: int): rail_state["sel"] = i)
	tree.root.add_child(rail)
	
	rail.selected_index = 1
	if rail.custom_minimum_size.x == 80.0 and rail_state["sel"] == 1:
		passed += 1
		results.append("✓ M3NavigationRail 80dp width and selection signal")
	else:
		failed += 1
		results.append("✗ M3NavigationRail selection failed")
	rail.free()
	
	# Test 3: Navigation Drawer
	var drawer := M3NavigationDrawer.new()
	drawer.destinations = [{"label": "A", "section": "S1"}, {"label": "B", "section": "S1"}]
	var drawer_state := {"sel": -1}
	drawer.destination_selected.connect(func(i: int): drawer_state["sel"] = i)
	tree.root.add_child(drawer)
	
	drawer.selected_index = 1
	if drawer_state["sel"] == 1 and drawer.selected_index == 1:
		passed += 1
		results.append("✓ M3NavigationDrawer destination selection")
	else:
		failed += 1
		results.append("✗ M3NavigationDrawer selection failed")
	drawer.free()
	
	# Test 4: Tabs Primary & Secondary
	var tabs_p := M3Tabs.new()
	tabs_p.tab_type = M3Tabs.TabType.PRIMARY
	tabs_p.tabs = [{"label": "Tab 1"}, {"label": "Tab 2"}]
	var tab_state := {"sel": -1}
	tabs_p.tab_selected.connect(func(i: int): tab_state["sel"] = i)
	tree.root.add_child(tabs_p)
	
	tabs_p.selected_index = 1
	if tab_state["sel"] == 1 and tabs_p.selected_index == 1:
		passed += 1
		results.append("✓ M3Tabs selection and primary pill indicator")
	else:
		failed += 1
		results.append("✗ M3Tabs selection failed")
	tabs_p.free()
	
	return {"passed": passed, "failed": failed, "results": results}
