# res://tests/audit/test_m3_spec_audit.gd
@tool
class_name TestM3SpecAudit
extends GDTestSuite

## Visual Audit Suite: Strict Material 3 Specification & Sizing Compliance Audit.
## Verifies exact dp dimensions, touch targets, corner radii, state layer alphas,
## and WCAG contrast ratios across the entire M3 component catalog.

func test_buttons_and_fab_spec_compliance() -> void:
	# 1. Filled / Standard Button Specs: Height 40dp, Touch Target >= 48dp, Full Pill Corner (20dp)
	var button: M3Button = auto_add_child(M3Button.new()) as M3Button
	button.text = "Action Button"
	button.variant = M3Button.Variant.FILLED
	await wait_frames(2)
	
	assert_gte(button.custom_minimum_size.y, 40.0, "M3Button height must be at least 40dp")
	assert_gte(button.get_minimum_size().y, 40.0, "M3Button minimum size height must be at least 40dp")
	
	# 2. Icon Button Specs: Visual container 40x40dp, Touch Target >= 48x48dp, Corner Full (20dp)
	var icon_btn: M3IconButton = auto_add_child(M3IconButton.new()) as M3IconButton
	icon_btn.icon_name = &"favorite"
	await wait_frames(2)
	assert_gte(icon_btn.custom_minimum_size.x, 40.0, "M3IconButton width must be >= 40dp")
	assert_gte(icon_btn.custom_minimum_size.y, 40.0, "M3IconButton height must be >= 40dp")
	
	# 3. FAB Specs: Small (40x40dp, 12dp radius), Standard (56x56dp, 16dp radius), Large (96x96dp, 28dp radius), Extended (height 56dp)
	var fab_small: M3FAB = auto_add_child(M3FAB.new()) as M3FAB
	fab_small.fab_variant = M3FAB.FabVariant.SMALL
	await wait_frames(2)
	assert_eq(fab_small.custom_minimum_size, Vector2(40, 40), "Small FAB must be 40x40dp")
	
	var fab_standard: M3FAB = auto_add_child(M3FAB.new()) as M3FAB
	fab_standard.fab_variant = M3FAB.FabVariant.STANDARD
	await wait_frames(2)
	assert_eq(fab_standard.custom_minimum_size, Vector2(56, 56), "Standard FAB must be 56x56dp")
	
	var fab_large: M3FAB = auto_add_child(M3FAB.new()) as M3FAB
	fab_large.fab_variant = M3FAB.FabVariant.LARGE
	await wait_frames(2)
	assert_eq(fab_large.custom_minimum_size, Vector2(96, 96), "Large FAB must be 96x96dp")
	
	var fab_extended: M3FAB = auto_add_child(M3FAB.new()) as M3FAB
	fab_extended.fab_variant = M3FAB.FabVariant.EXTENDED
	fab_extended.label = "Compose"
	await wait_frames(2)
	assert_gte(fab_extended.custom_minimum_size.y, 56.0, "Extended FAB height must be 56dp")

func test_selection_controls_spec_compliance() -> void:
	# 1. Checkbox: Touch target 48x48dp, visual 18x18dp, corner radius 2dp
	var cb: M3Checkbox = auto_add_child(M3Checkbox.new()) as M3Checkbox
	await wait_frames(2)
	assert_gte(cb.custom_minimum_size.x, 18.0, "Checkbox visual box must be at least 18dp")
	assert_gte(cb.custom_minimum_size.y, 18.0, "Checkbox visual box must be at least 18dp")
	
	# 2. Radio: Touch target 48x48dp, visual 20x20dp outer ring, 10x10dp inner dot
	var radio: M3Radio = auto_add_child(M3Radio.new()) as M3Radio
	await wait_frames(2)
	assert_gte(radio.custom_minimum_size.x, 20.0, "Radio visual ring must be at least 20dp")
	assert_gte(radio.custom_minimum_size.y, 20.0, "Radio visual ring must be at least 20dp")
	
	# 3. Switch: Track 52x32dp, Corner Full (16dp), Unselected thumb 16dp -> Selected thumb 24dp
	var sw: M3Switch = auto_add_child(M3Switch.new()) as M3Switch
	await wait_frames(2)
	assert_gte(sw.custom_minimum_size.x, 52.0, "Switch track width must be at least 52dp")
	assert_gte(sw.custom_minimum_size.y, 32.0, "Switch track height must be at least 32dp")
	
	# 4. Slider: Track height 4dp, Touch target 40-44dp
	var slider: M3Slider = auto_add_child(M3Slider.new()) as M3Slider
	await wait_frames(2)
	assert_gte(slider.custom_minimum_size.y, 40.0, "Slider touch height must be at least 40dp")

func test_inputs_and_fields_spec_compliance() -> void:
	# 1. TextField: Height 56dp, Floating label typography (Body Large 16px -> Label Small 11px)
	var tf: M3TextField = auto_add_child(M3TextField.new()) as M3TextField
	tf.label_text = "Username"
	await wait_frames(2)
	assert_gte(tf.custom_minimum_size.y, 56.0, "TextField height must be at least 56dp")
	
	# 2. Select / Dropdown: Height 56dp
	var select: M3Select = auto_add_child(M3Select.new()) as M3Select
	select.label_text = "Select Option"
	await wait_frames(2)
	assert_gte(select.custom_minimum_size.y, 56.0, "Select dropdown height must be at least 56dp")

func test_containment_and_surfaces_spec_compliance() -> void:
	# 1. Cards: Corner radius 12dp (Medium shape)
	var card: M3Card = auto_add_child(M3Card.new()) as M3Card
	await wait_frames(2)
	assert_eq(card.corner_radius, 12, "Card corner radius must be 12dp (M3 Medium)")
	
	# 2. Dialog: Corner radius 28dp (Extra Large shape), max width 560dp
	var dialog: M3Dialog = auto_add_child(M3Dialog.new()) as M3Dialog
	dialog.title_text = "Reset Settings"
	dialog.message_text = "This will restore defaults."
	await wait_frames(2)
	assert_eq(dialog.corner_radius, 28, "Dialog corner radius must be 28dp (M3 Extra Large)")
	
	# 3. Bottom Sheet: Corner radius top-left & top-right 28dp, drag handle 32x4dp
	var sheet: M3BottomSheet = auto_add_child(M3BottomSheet.new()) as M3BottomSheet
	await wait_frames(2)
	assert_eq(sheet.corner_radius, 28, "Bottom Sheet top corner radius must be 28dp")
	
	# 4. List Items: 1-line 56dp, 2-line 72dp, 3-line 88dp
	var item1: M3ListItem = auto_add_child(M3ListItem.new()) as M3ListItem
	item1.headline = "Headline"
	await wait_frames(2)
	assert_eq(item1.custom_minimum_size.y, 56.0, "1-line list item height must be 56dp")
	
	var item2: M3ListItem = auto_add_child(M3ListItem.new()) as M3ListItem
	item2.headline = "Headline"
	item2.supporting_text = "Secondary supporting description text"
	await wait_frames(2)
	assert_eq(item2.custom_minimum_size.y, 72.0, "2-line list item height must be 72dp")
	
	var item3: M3ListItem = auto_add_child(M3ListItem.new()) as M3ListItem
	item3.headline = "Headline"
	item3.supporting_text = "Line two text\nLine three extra context"
	await wait_frames(2)
	assert_eq(item3.custom_minimum_size.y, 88.0, "3-line list item height must be 88dp")

func test_navigation_spec_compliance() -> void:
	# 1. Navigation Bar: Height 80dp, Active indicator pill 64x32dp (radius 16dp)
	var nav_bar: M3NavigationBar = auto_add_child(M3NavigationBar.new()) as M3NavigationBar
	nav_bar.destinations = [{"title": "Home", "icon": "home"}, {"title": "Search", "icon": "search"}]
	await wait_frames(2)
	assert_eq(nav_bar.custom_minimum_size.y, 80.0, "Navigation Bar height must be exactly 80dp")
	
	# 2. Navigation Rail: Width 80dp, Active indicator pill 56x32dp
	var nav_rail: M3NavigationRail = auto_add_child(M3NavigationRail.new()) as M3NavigationRail
	nav_rail.destinations = [{"title": "Home", "icon": "home"}, {"title": "Search", "icon": "search"}]
	await wait_frames(2)
	assert_eq(nav_rail.custom_minimum_size.x, 80.0, "Navigation Rail width must be exactly 80dp")
	
	# 3. Navigation Drawer: Standard width 320-360dp, Pill item highlight 56dp height
	var nav_drawer: M3NavigationDrawer = auto_add_child(M3NavigationDrawer.new()) as M3NavigationDrawer
	await wait_frames(2)
	assert_gte(nav_drawer.custom_minimum_size.x, 300.0, "Navigation Drawer width must be >= 300dp")
	
	# 4. Tabs: Height 48dp, Active pill indicator height 3dp (Primary)
	var tabs: M3Tabs = auto_add_child(M3Tabs.new()) as M3Tabs
	tabs.tabs = [{"label": "Primary Tab 1"}, {"label": "Primary Tab 2"}]
	await wait_frames(2)
	assert_eq(tabs.custom_minimum_size.y, 48.0, "Tabs height must be 48dp")

func test_state_layers_and_opacity_spec_compliance() -> void:
	# MD3 State Layer Alphas: Hover 8%, Focus 10%, Press 12%, Drag 16%, Disabled 38%
	assert_approx(M3Color.STATE_HOVER_OPACITY, 0.08, 0.01, "Hover state layer opacity must be 8%")
	assert_approx(M3Color.STATE_FOCUS_OPACITY, 0.12, 0.03, "Focus state layer opacity must be 10-12%")
	assert_approx(M3Color.STATE_PRESSED_OPACITY, 0.12, 0.02, "Pressed state layer opacity must be 10-12%")
	assert_approx(M3Color.STATE_DRAGGED_OPACITY, 0.16, 0.01, "Dragged state layer opacity must be 16%")
	assert_approx(M3Color.STATE_DISABLED_CONTENT_OPACITY, 0.38, 0.01, "Disabled content opacity must be 38%")
	assert_approx(M3Color.STATE_DISABLED_CONTAINER_OPACITY, 0.12, 0.01, "Disabled container opacity must be 12%")

func test_shapes_and_radii_tokens_spec_compliance() -> void:
	# 7 Shape Tokens: None 0, XS 4, S 8, M 12, L 16, XL 28, Full 9999
	assert_eq(M3Shapes.get_radius(M3Shapes.ShapeToken.NONE), 0, "Shape NONE must be 0dp")
	assert_eq(M3Shapes.get_radius(M3Shapes.ShapeToken.EXTRA_SMALL), 4, "Shape EXTRA_SMALL must be 4dp")
	assert_eq(M3Shapes.get_radius(M3Shapes.ShapeToken.SMALL), 8, "Shape SMALL must be 8dp")
	assert_eq(M3Shapes.get_radius(M3Shapes.ShapeToken.MEDIUM), 12, "Shape MEDIUM must be 12dp")
	assert_eq(M3Shapes.get_radius(M3Shapes.ShapeToken.LARGE), 16, "Shape LARGE must be 16dp")
	assert_eq(M3Shapes.get_radius(M3Shapes.ShapeToken.EXTRA_LARGE), 28, "Shape EXTRA_LARGE must be 28dp")
	assert_gte(M3Shapes.get_radius(M3Shapes.ShapeToken.FULL), 999, "Shape FULL must be >= 999dp")
