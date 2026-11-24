class_name TestShowcaseApp
extends RefCounted

func run_all_tests(tree: SceneTree) -> Dictionary:
	var passed := 0
	var failed := 0
	var results: Array[String] = []
	
	print("[TEST] Running TestShowcaseApp...")
	
	var showcase := ShowcaseMain.new()
	tree.root.add_child(showcase)
	
	# Test 1: Showcase App Initialization
	if showcase._adaptive_nav != null and showcase._adaptive_nav._screens.size() == 8:
		passed += 1
		results.append("✓ ShowcaseApp initialization with 8 registered screens")
	else:
		failed += 1
		results.append("✗ ShowcaseApp initialization failed")
		
	# Test 2: Cycle Through All Screens
	var all_screens_ok := true
	for i in range(8):
		showcase._adaptive_nav.selected_index = i
		if not showcase._adaptive_nav._screens[i].visible:
			all_screens_ok = false
			break
			
	if all_screens_ok:
		passed += 1
		results.append("✓ ShowcaseApp cycling all 8 interactive screens")
	else:
		failed += 1
		results.append("✗ ShowcaseApp screen switching failed")
		
	# Test 3: Theme Toggle & Scheme Propagation
	var theme_inst: M3ThemeSingleton = M3ThemeSingleton.get_instance()
	if theme_inst:
		var prev_is_dark: bool = theme_inst.is_dark_mode
		showcase._toggle_theme_mode()
		var dark_toggled: bool = (theme_inst.is_dark_mode != prev_is_dark)
		showcase._toggle_theme_mode() # Revert
		
		if dark_toggled:
			passed += 1
			results.append("✓ ShowcaseApp dark/light mode toggle")
		else:
			failed += 1
			results.append("✗ ShowcaseApp dark/light mode toggle failed")
	else:
		failed += 1
		results.append("✗ ShowcaseApp theme instance not found")
		
	# Test 4: Seed Preset Cycling
	var seeds_ok := true
	if theme_inst:
		for preset in [M3ThemeManager.SeedPreset.INDIGO, M3ThemeManager.SeedPreset.TEAL, M3ThemeManager.SeedPreset.TERRACOTTA, M3ThemeManager.SeedPreset.EMERALD, M3ThemeManager.SeedPreset.AMBER, M3ThemeManager.SeedPreset.CORAL]:
			M3ThemeManager.get_instance().set_seed_preset(preset)
			if theme_inst.seed_color != M3ThemeManager.SEED_COLORS[preset]:
				seeds_ok = false
				break
				
	if seeds_ok:
		passed += 1
		results.append("✓ ShowcaseApp 6 seed preset color palettes")
	else:
		failed += 1
		results.append("✗ ShowcaseApp seed color preset switching failed")
		
	tree.root.remove_child(showcase)
	showcase.free()
	
	return {"passed": passed, "failed": failed, "results": results}
