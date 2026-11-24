# res://tests/gss/test_gss_navigation.gd
## GSS verification suite for the Material Design 3 Navigation Family + Window Size Classes:
##   - navigation.app_bar.top
##   - navigation.app_bar.bottom
##   - navigation.toolbar
##   - navigation.bar
##   - navigation.drawer
##   - navigation.rail
##   - navigation.search
##   - navigation.tabs
##   - navigation.adaptive
##   - foundations.layout.window_classes
extends GDTestSuite

const H := preload("res://tests/gss/m3_gss_harness.gd")

const TOP_BAR_SCRIPT := "res://addons/material3/components/navigation/m3_top_app_bar.gd"
const BOTTOM_BAR_SCRIPT := "res://addons/material3/components/navigation/m3_bottom_app_bar.gd"
const TOOLBAR_SCRIPT := "res://addons/material3/components/navigation/m3_toolbar.gd"
const NAV_BAR_SCRIPT := "res://addons/material3/components/navigation/m3_navigation_bar.gd"
const NAV_DRAWER_SCRIPT := "res://addons/material3/components/navigation/m3_navigation_drawer.gd"
const NAV_RAIL_SCRIPT := "res://addons/material3/components/navigation/m3_navigation_rail.gd"
const SEARCH_BAR_SCRIPT := "res://addons/material3/components/navigation/m3_search_bar.gd"
const SEARCH_VIEW_SCRIPT := "res://addons/material3/components/navigation/m3_search_view.gd"
const TABS_SCRIPT := "res://addons/material3/components/navigation/m3_tabs.gd"
const ADAPTIVE_SCRIPT := "res://addons/material3/components/navigation/m3_adaptive_navigation.gd"
const CANONICAL_SCAFFOLD_SCRIPT := "res://addons/material3/components/navigation/m3_canonical_scaffold.gd"

func _init() -> void:
	suite_name = "GSS_Navigation"
	test_type = "integration"

func test_top_app_bar() -> void:
	var stage = await H.create_stage(self, "navigation", "top_app_bar", false)

	var bar_center := M3TopAppBar.new()
	bar_center.name = "TopBarCenter"
	bar_center.variant = M3TopAppBar.BarVariant.CENTER_ALIGNED
	bar_center.title = "Center Aligned"
	bar_center.subtitle = "M3 2025 Subtitle"
	bar_center.size = Vector2(560, 64)
	bar_center.add_action("person", "Profile")
	stage.add(bar_center, Vector2(32, 24))

	var bar_small := M3TopAppBar.new()
	bar_small.name = "TopBarSmall"
	bar_small.variant = M3TopAppBar.BarVariant.SMALL
	bar_small.title = "Small App Bar"
	bar_small.size = Vector2(560, 64)
	bar_small.add_action("search", "Search")
	bar_small.add_action("favorite", "Favorite")
	stage.add(bar_small, Vector2(32, 112))

	var bar_scrolled := M3TopAppBar.new()
	bar_scrolled.name = "TopBarScrolled"
	bar_scrolled.variant = M3TopAppBar.BarVariant.SMALL
	bar_scrolled.title = "Scrolled On-Scroll Color"
	bar_scrolled.size = Vector2(560, 64)
	bar_scrolled.set_scrolled(true, false)
	stage.add(bar_scrolled, Vector2(32, 200))

	var bar_medium := M3TopAppBar.new()
	bar_medium.name = "TopBarMedium"
	bar_medium.variant = M3TopAppBar.BarVariant.MEDIUM
	bar_medium.title = "Medium Headline"
	bar_medium.subtitle = "Supporting subtitle"
	bar_medium.size = Vector2(560, 124)
	bar_medium.add_action("edit", "Edit")
	stage.add(bar_medium, Vector2(32, 288))

	var bar_large := M3TopAppBar.new()
	bar_large.name = "TopBarLarge"
	bar_large.variant = M3TopAppBar.BarVariant.LARGE
	bar_large.title = "Large App Bar"
	bar_large.size = Vector2(580, 152)
	bar_large.add_action("search", "Search")
	bar_large.add_action("settings", "Settings")
	stage.add(bar_large, Vector2(640, 24))

	var nav_hits: Array[int] = [0]
	var act_hits: Array[int] = [0]
	bar_large.navigation_pressed.connect(func() -> void: nav_hits[0] += 1)
	bar_large.action_pressed.connect(func(_i: int) -> void: act_hits[0] += 1)

	var snap: Dictionary = await H.snapshot(stage, "navigation.app_bar.top", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [TOP_BAR_SCRIPT]))

	var n_small: Dictionary = H.node_entry(snap, "TopBarSmall")
	assert_approx(float(n_small.get("screen_rect", {}).get("height", 0.0)), 64.0, 1.0, "Small TopAppBar height is 64dp")
	var n_large: Dictionary = H.node_entry(snap, "TopBarLarge")
	assert_approx(float(n_large.get("screen_rect", {}).get("height", 0.0)), 152.0, 1.0, "Large TopAppBar height is 152dp")

	await H.assert_pixel(self, stage, stage.point_of(bar_small, Vector2(420, 16)), M3ThemeSingleton.get_instance().get_color(&"surface"), 0.08, "unscrolled top bar = surface")
	await H.assert_pixel(self, stage, stage.point_of(bar_scrolled, Vector2(420, 16)), M3ThemeSingleton.get_instance().get_color(&"surface_container"), 0.08, "scrolled top bar = surface_container")
	H.cover(self, "navigation.app_bar.top", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.app_bar.top", "scroll_collapse_and_actions", func() -> void:
		await stage.click(bar_large.get_navigation_button())
		await stage.click(bar_large.get_action_button(0))
		await stage.scroll(bar_large, 3, true, Vector2(280, 60))
		await stage.wait(22)
	, 10, bar_large)
	assert_true(H.assert_recording(self, live))
	assert_eq(nav_hits[0], 1, "navigation_pressed emitted via real click")
	assert_eq(act_hits[0], 1, "action_pressed emitted via real click")
	H.assert_mutated(self, live, "TopBarLarge", "script_variables.scrolled", true)
	H.assert_animated(self, live, "TopBarLarge", "script_variables.scroll_lift_progress", 3)
	H.assert_animated(self, live, "TopBarLarge", "script_variables.collapse_progress", 3)
	H.cover(self, "navigation.app_bar.top", "interaction", live)
	H.cover(self, "navigation.app_bar.top", "animation", live)
	stage.dispose()

func test_bottom_app_bar() -> void:
	var stage = await H.create_stage(self, "navigation", "bottom_app_bar", true)

	var bar := M3BottomAppBar.new()
	bar.name = "BottomAppBarMain"
	bar.size = Vector2(640, 80)
	bar.add_action("menu", "Menu")
	bar.add_action("search", "Search")
	bar.add_action("favorite", "Favorite")
	bar.add_action("edit", "Edit")
	bar.show_fab = true
	bar.fab_icon = "add"
	stage.add(bar, Vector2(60, 120))

	var bar_no_fab := M3BottomAppBar.new()
	bar_no_fab.name = "BottomAppBarNoFab"
	bar_no_fab.size = Vector2(640, 80)
	bar_no_fab.add_action("search", "Search")
	bar_no_fab.add_action("delete", "Delete")
	bar_no_fab.show_fab = false
	stage.add(bar_no_fab, Vector2(60, 260))

	var act_hits: Array[int] = [0]
	var fab_hits: Array[int] = [0]
	bar.action_pressed.connect(func(_i: int) -> void: act_hits[0] += 1)
	bar.fab_pressed.connect(func() -> void: fab_hits[0] += 1)

	var snap: Dictionary = await H.snapshot(stage, "navigation.app_bar.bottom", "variants_dark")
	assert_true(H.assert_snapshot(self, snap, [BOTTOM_BAR_SCRIPT]))

	var n_bar: Dictionary = H.node_entry(snap, "BottomAppBarMain")
	assert_approx(float(n_bar.get("screen_rect", {}).get("height", 0.0)), 80.0, 1.0, "BottomAppBar height is 80dp")
	await H.assert_pixel(self, stage, stage.point_of(bar, Vector2(360, 40)), M3ThemeSingleton.get_instance().get_color(&"surface_container"), 0.08, "BottomAppBar container = surface_container")
	H.cover(self, "navigation.app_bar.bottom", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.app_bar.bottom", "actions_fab_and_hide_on_scroll", func() -> void:
		await stage.click(bar.get_action_button(1))
		await stage.click(bar.get_fab())
		await stage.scroll(bar, 2, true, Vector2(320, 40))
		await stage.wait(22)
	, 10, bar)
	assert_true(H.assert_recording(self, live))
	assert_eq(act_hits[0], 1, "BottomAppBar action button clicked")
	assert_eq(fab_hits[0], 1, "BottomAppBar embedded FAB clicked")
	H.assert_mutated(self, live, "BottomAppBarMain", "script_variables.hidden_on_scroll", true)
	H.assert_animated(self, live, "BottomAppBarMain", "script_variables.visible_progress", 3)
	H.cover(self, "navigation.app_bar.bottom", "interaction", live)
	H.cover(self, "navigation.app_bar.bottom", "animation", live)
	stage.dispose()

func test_toolbar() -> void:
	var stage = await H.create_stage(self, "navigation", "toolbar", false)

	var tb_float_std := M3Toolbar.new()
	tb_float_std.name = "ToolbarFloatingStd"
	tb_float_std.toolbar_type = M3Toolbar.ToolbarType.FLOATING
	tb_float_std.color_style = M3Toolbar.ColorStyle.STANDARD
	tb_float_std.show_fab = true
	tb_float_std.add_item("edit", "Edit")
	tb_float_std.add_item("share", "Share")
	tb_float_std.add_item("bookmark", "Save")
	tb_float_std.add_item("favorite", "Like")
	stage.add(tb_float_std, Vector2(48, 48))

	var tb_float_vib := M3Toolbar.new()
	tb_float_vib.name = "ToolbarFloatingVibrant"
	tb_float_vib.toolbar_type = M3Toolbar.ToolbarType.FLOATING
	tb_float_vib.color_style = M3Toolbar.ColorStyle.VIBRANT
	tb_float_vib.add_item("search", "Search")
	tb_float_vib.add_item("tune", "Filter")
	tb_float_vib.add_item("undo", "Undo")
	tb_float_vib.add_item("delete", "Delete")
	stage.add(tb_float_vib, Vector2(48, 148))

	var tb_docked := M3Toolbar.new()
	tb_docked.name = "ToolbarDocked"
	tb_docked.toolbar_type = M3Toolbar.ToolbarType.DOCKED
	tb_docked.color_style = M3Toolbar.ColorStyle.STANDARD
	tb_docked.size = Vector2(560, 64)
	tb_docked.add_item("edit", "Edit")
	tb_docked.add_item("share", "Share")
	tb_docked.add_item("bookmark", "Bookmark")
	stage.add(tb_docked, Vector2(48, 252))

	var tb_vert := M3Toolbar.new()
	tb_vert.name = "ToolbarVertical"
	tb_vert.toolbar_type = M3Toolbar.ToolbarType.FLOATING
	tb_vert.orientation = M3Toolbar.Orientation.VERTICAL
	tb_vert.color_style = M3Toolbar.ColorStyle.VIBRANT
	tb_vert.add_item("edit", "Edit")
	tb_vert.add_item("share", "Share")
	tb_vert.add_item("favorite", "Favorite")
	stage.add(tb_vert, Vector2(720, 48))

	var snap: Dictionary = await H.snapshot(stage, "navigation.toolbar", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [TOOLBAR_SCRIPT]))

	var n_std: Dictionary = H.node_entry(snap, "ToolbarFloatingStd")
	assert_approx(float(n_std.get("screen_rect", {}).get("height", 0.0)), 64.0, 1.0, "Floating horizontal toolbar height is 64dp")
	var n_vert: Dictionary = H.node_entry(snap, "ToolbarVertical")
	assert_approx(float(n_vert.get("screen_rect", {}).get("width", 0.0)), 64.0, 1.0, "Floating vertical toolbar width is 64dp")
	H.cover(self, "navigation.toolbar", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.toolbar", "select_tool_item", func() -> void:
		await stage.click(tb_float_std, tb_float_std.get_item_center(2))
		await stage.wait(20)
	, 10, tb_float_std)
	assert_true(H.assert_recording(self, live))
	H.assert_mutated(self, live, "ToolbarFloatingStd", "script_variables.active_index", 2)
	H.assert_animated(self, live, "ToolbarFloatingStd", "script_variables.selection_progress", 3)
	H.cover(self, "navigation.toolbar", "interaction", live)
	H.cover(self, "navigation.toolbar", "animation", live)
	stage.dispose()

func test_navigation_bar() -> void:
	var stage = await H.create_stage(self, "navigation", "navigation_bar", false)

	var bar3 := M3NavigationBar.new()
	bar3.name = "NavBar3Dest"
	bar3.size = Vector2(480, 80)
	bar3.destinations = [
		{"label": "Home", "icon": null, "badge": 0},
		{"label": "Browse", "icon": null, "badge": -1},
		{"label": "Library", "icon": null, "badge": 0}
	]
	stage.add(bar3, Vector2(48, 60))

	var bar5 := M3NavigationBar.new()
	bar5.name = "NavBar5Dest"
	bar5.size = Vector2(640, 80)
	bar5.destinations = [
		{"label": "Explore", "icon": null, "badge": 0},
		{"label": "Flights", "icon": null, "badge": 4},
		{"label": "Hotels", "icon": null, "badge": 0},
		{"label": "Saved", "icon": null, "badge": 1200},
		{"label": "Profile", "icon": null, "badge": 0}
	]
	stage.add(bar5, Vector2(48, 190))

	var snap: Dictionary = await H.snapshot(stage, "navigation.bar", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [NAV_BAR_SCRIPT]))

	var n_bar5: Dictionary = H.node_entry(snap, "NavBar5Dest")
	assert_approx(float(n_bar5.get("screen_rect", {}).get("height", 0.0)), 80.0, 1.0, "NavigationBar height is 80dp")
	await H.assert_pixel(self, stage, stage.point_of(bar5, Vector2(10, 40)), M3ThemeSingleton.get_instance().get_color(&"surface_container"), 0.08, "NavigationBar container = surface_container")
	H.cover(self, "navigation.bar", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.bar", "select_destination", func() -> void:
		await stage.click(bar5, bar5.get_destination_center(2))
		await stage.wait(22)
	, 10, bar5)
	assert_true(H.assert_recording(self, live))
	H.assert_mutated(self, live, "NavBar5Dest", "script_variables.selected_index", 2)
	H.assert_animated(self, live, "NavBar5Dest", "script_variables._indicator_x", 3)
	H.cover(self, "navigation.bar", "interaction", live)
	H.cover(self, "navigation.bar", "animation", live)
	stage.dispose()

func test_navigation_drawer() -> void:
	var stage = await H.create_stage(self, "navigation", "navigation_drawer", false)

	var drawer_std := M3NavigationDrawer.new()
	drawer_std.name = "DrawerStandard"
	drawer_std.drawer_type = M3NavigationDrawer.DrawerType.STANDARD
	drawer_std.drawer_width = 320.0
	drawer_std.size = Vector2(320, 480)
	stage.add(drawer_std, Vector2(32, 32))

	var drawer_modal := M3NavigationDrawer.new()
	drawer_modal.name = "DrawerModal"
	drawer_modal.drawer_type = M3NavigationDrawer.DrawerType.MODAL
	drawer_modal.drawer_width = 320.0
	drawer_modal.size = Vector2(540, 480)
	stage.add(drawer_modal, Vector2(400, 32))

	var snap: Dictionary = await H.snapshot(stage, "navigation.drawer", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [NAV_DRAWER_SCRIPT]))

	var n_std: Dictionary = H.node_entry(snap, "DrawerStandard")
	assert_approx(float(n_std.get("screen_rect", {}).get("width", 0.0)), 320.0, 1.0, "Standard NavigationDrawer width is 320dp")
	H.cover(self, "navigation.drawer", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.drawer", "select_and_modal_close", func() -> void:
		await stage.click(drawer_std.get_item_button(1))
		await stage.wait(12)
		await stage.click(drawer_modal, Vector2(460, 240))
		await stage.wait(20)
	, 10, drawer_modal)
	assert_true(H.assert_recording(self, live))
	H.assert_mutated(self, live, "DrawerStandard", "script_variables.selected_index", 1)
	H.assert_mutated(self, live, "DrawerModal", "script_variables.is_open", false)
	H.assert_animated(self, live, "DrawerModal", "script_variables.open_progress", 3)
	H.cover(self, "navigation.drawer", "interaction", live)
	H.cover(self, "navigation.drawer", "animation", live)
	stage.dispose()

func test_navigation_rail() -> void:
	var stage = await H.create_stage(self, "navigation", "navigation_rail", false)

	var rail_fab := M3NavigationRail.new()
	rail_fab.name = "RailWithFab"
	rail_fab.has_fab = true
	rail_fab.show_menu_button = true
	rail_fab.size = Vector2(80, 480)
	stage.add(rail_fab, Vector2(60, 40))

	var rail_centered := M3NavigationRail.new()
	rail_centered.name = "RailCentered"
	rail_centered.has_fab = false
	rail_centered.alignment = M3NavigationRail.RailAlignment.CENTER
	rail_centered.size = Vector2(80, 480)
	stage.add(rail_centered, Vector2(200, 40))

	var fab_clicks: Array[int] = [0]
	rail_fab.fab_clicked.connect(func() -> void: fab_clicks[0] += 1)

	var snap: Dictionary = await H.snapshot(stage, "navigation.rail", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [NAV_RAIL_SCRIPT]))

	var n_rail: Dictionary = H.node_entry(snap, "RailWithFab")
	assert_approx(float(n_rail.get("screen_rect", {}).get("width", 0.0)), 80.0, 1.0, "NavigationRail compact width is 80dp")
	H.cover(self, "navigation.rail", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.rail", "select_destination_and_fab", func() -> void:
		await stage.click(rail_fab, rail_fab.get_fab_center())
		await stage.click(rail_fab, rail_fab.get_destination_center(2))
		await stage.wait(22)
	, 10, rail_fab)
	assert_true(H.assert_recording(self, live))
	assert_eq(fab_clicks[0], 1, "NavigationRail FAB clicked")
	H.assert_mutated(self, live, "RailWithFab", "script_variables.selected_index", 2)
	H.assert_animated(self, live, "RailWithFab", "script_variables._indicator_y", 3)
	H.cover(self, "navigation.rail", "interaction", live)
	H.cover(self, "navigation.rail", "animation", live)
	stage.dispose()

func test_search_bar_and_view() -> void:
	var stage = await H.create_stage(self, "navigation", "search", false)

	var search_bar := M3SearchBar.new()
	search_bar.name = "SearchBarMain"
	search_bar.placeholder_text = "Search Material 3..."
	search_bar.badge_count = 3
	search_bar.size = Vector2(440, 56)
	stage.add(search_bar, Vector2(60, 36))

	var search_view := M3SearchView.new()
	search_view.name = "SearchViewMain"
	search_view.placeholder_text = "Search components..."
	search_view.size = Vector2(440, 240)
	search_view.add_suggestion("Material 3 Components", "schedule")
	search_view.add_suggestion("Expressive Toolbars", "search")
	search_view.add_suggestion("Adaptive Navigation", "star")
	search_bar.search_view = search_view
	stage.add(search_view, Vector2(60, 116))

	var snap: Dictionary = await H.snapshot(stage, "navigation.search", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [SEARCH_BAR_SCRIPT, SEARCH_VIEW_SCRIPT]))

	var n_sb: Dictionary = H.node_entry(snap, "SearchBarMain")
	assert_approx(float(n_sb.get("screen_rect", {}).get("height", 0.0)), 56.0, 1.0, "SearchBar height is 56dp")
	await H.assert_pixel(self, stage, stage.point_of(search_bar, Vector2(220, 10)), M3ThemeSingleton.get_instance().get_color(&"surface_container_high"), 0.08, "SearchBar container = surface_container_high")
	H.cover(self, "navigation.search", "element", snap)

	# Prepare closed state so clicking SearchBar animates SearchView open
	search_view.close(false)
	await stage.settle()

	var live: Dictionary = await H.record(stage, "navigation.search", "activate_and_select_suggestion", func() -> void:
		await stage.click(search_bar, Vector2(180, 28))
		await stage.wait(22)
		await stage.click(search_view.get_suggestion_item(0))
		await stage.wait(6)
	, 10, search_view)
	assert_true(H.assert_recording(self, live))
	H.assert_mutated(self, live, "SearchViewMain", "script_variables.is_open", true)
	H.assert_animated(self, live, "SearchViewMain", "script_variables.open_progress", 3)
	H.assert_mutated(self, live, "SearchBarMain", "script_variables.query", "Material 3 Components")
	H.cover(self, "navigation.search", "interaction", live)
	H.cover(self, "navigation.search", "animation", live)
	stage.dispose()

func test_tabs() -> void:
	var stage = await H.create_stage(self, "navigation", "tabs", false)

	var tabs_pri := M3Tabs.new()
	tabs_pri.name = "TabsPrimary"
	tabs_pri.tab_type = M3Tabs.TabType.PRIMARY
	tabs_pri.size = Vector2(540, 48)
	tabs_pri.tabs = [
		{"label": "Overview"},
		{"label": "Specifications"},
		{"label": "Reviews"}
	]
	stage.add(tabs_pri, Vector2(60, 60))

	var tabs_sec := M3Tabs.new()
	tabs_sec.name = "TabsSecondary"
	tabs_sec.tab_type = M3Tabs.TabType.SECONDARY
	tabs_sec.size = Vector2(540, 48)
	tabs_sec.tabs = [
		{"label": "All"},
		{"label": "Unread"},
		{"label": "Archived"}
	]
	stage.add(tabs_sec, Vector2(60, 150))

	var snap: Dictionary = await H.snapshot(stage, "navigation.tabs", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [TABS_SCRIPT]))

	var n_pri: Dictionary = H.node_entry(snap, "TabsPrimary")
	assert_approx(float(n_pri.get("screen_rect", {}).get("height", 0.0)), 48.0, 1.0, "Primary Tabs height is 48dp")
	H.cover(self, "navigation.tabs", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.tabs", "indicator_slide", func() -> void:
		await stage.click(tabs_pri, tabs_pri.get_tab_center(2))
		await stage.wait(22)
	, 10, tabs_pri)
	assert_true(H.assert_recording(self, live))
	H.assert_mutated(self, live, "TabsPrimary", "script_variables.selected_index", 2)
	H.assert_animated(self, live, "TabsPrimary", "script_variables._indicator_x", 3)
	H.cover(self, "navigation.tabs", "interaction", live)
	H.cover(self, "navigation.tabs", "animation", live)
	stage.dispose()

func test_adaptive_navigation_and_window_classes() -> void:
	var stage = await H.create_stage(self, "navigation", "adaptive_window_classes", false)

	var dests: Array[Dictionary] = [
		{"label": "Home", "icon": null, "badge": 0},
		{"label": "Browse", "icon": null, "badge": 2},
		{"label": "Saved", "icon": null, "badge": 0}
	]

	var ad_compact := M3AdaptiveNavigation.new()
	ad_compact.name = "AdaptiveCompact"
	ad_compact.destinations = dests
	ad_compact.width_override = 480.0
	ad_compact.size = Vector2(360, 320)
	stage.add(ad_compact, Vector2(20, 40))

	var ad_medium := M3AdaptiveNavigation.new()
	ad_medium.name = "AdaptiveMedium"
	ad_medium.destinations = dests
	ad_medium.width_override = 720.0
	ad_medium.size = Vector2(360, 320)
	stage.add(ad_medium, Vector2(400, 40))

	var ad_expanded := M3AdaptiveNavigation.new()
	ad_expanded.name = "AdaptiveExpanded"
	ad_expanded.destinations = dests
	ad_expanded.width_override = 1024.0
	ad_expanded.size = Vector2(460, 320)
	stage.add(ad_expanded, Vector2(780, 40))

	var snap: Dictionary = await H.snapshot(stage, "navigation.adaptive", "compact_medium_expanded")
	assert_true(H.assert_snapshot(self, snap, [ADAPTIVE_SCRIPT]))

	assert_eq(ad_compact.current_mode, M3AdaptiveNavigation.LayoutMode.COMPACT, "width < 600 -> COMPACT")
	assert_eq(ad_medium.current_mode, M3AdaptiveNavigation.LayoutMode.MEDIUM, "600..839 -> MEDIUM")
	assert_eq(ad_expanded.current_mode, M3AdaptiveNavigation.LayoutMode.EXPANDED, ">= 840 -> EXPANDED")
	H.cover(self, ["navigation.adaptive", "foundations.layout.window_classes"], "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.adaptive", "navigate_and_breakpoint_switch", func() -> void:
		var bar := ad_compact.get_navigation_bar()
		await stage.click(bar, bar.get_destination_center(1))
		await stage.wait(8)
		ad_compact.width_override = 720.0
		await stage.wait(4)
		ad_compact.width_override = 960.0
		await stage.wait(6)
	, 8, ad_compact)
	assert_true(H.assert_recording(self, live))
	H.assert_mutated(self, live, "AdaptiveCompact", "script_variables.selected_index", 1)
	H.assert_mutated(self, live, "AdaptiveCompact", "script_variables.current_mode", M3AdaptiveNavigation.LayoutMode.EXPANDED)
	H.assert_mutated(self, live, "AdaptiveCompact", "script_variables.window_size_class", M3AdaptiveNavigation.WindowSizeClass.EXPANDED)
	H.cover(self, ["navigation.adaptive", "foundations.layout.window_classes"], "interaction", live)
	stage.dispose()

func test_scrollable_tabs() -> void:
	var stage = await H.create_stage(self, "navigation", "scrollable_tabs", false)

	var tabs_pri := M3Tabs.new()
	tabs_pri.name = "ScrollableTabsPrimary"
	tabs_pri.tab_type = M3Tabs.TabType.PRIMARY
	tabs_pri.scrollable = true
	tabs_pri.leading_edge_offset = 52.0
	tabs_pri.min_tab_width = 120.0
	tabs_pri.size = Vector2(520, 48)
	tabs_pri.tabs = [
		{"label": "For You"},
		{"label": "Top Charts"},
		{"label": "New Releases"},
		{"label": "Editor's Choice"},
		{"label": "Categories"},
		{"label": "Family & Kids"}
	]
	stage.add(tabs_pri, Vector2(60, 60))

	var tabs_sec := M3Tabs.new()
	tabs_sec.name = "ScrollableTabsSecondary"
	tabs_sec.tab_type = M3Tabs.TabType.SECONDARY
	tabs_sec.scrollable = true
	tabs_sec.leading_edge_offset = 52.0
	tabs_sec.min_tab_width = 120.0
	tabs_sec.size = Vector2(520, 48)
	tabs_sec.tabs = [
		{"label": "All Media"},
		{"label": "Podcasts"},
		{"label": "Audiobooks"},
		{"label": "Live Radio"},
		{"label": "Downloaded"}
	]
	stage.add(tabs_sec, Vector2(60, 150))

	var snap: Dictionary = await H.snapshot(stage, "navigation.tabs.scrollable", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [TABS_SCRIPT]))
	assert_true(tabs_pri.clip_contents, "Scrollable tabs enable clip_contents")
	assert_approx(tabs_pri.leading_edge_offset, 52.0, 0.1, "52dp leading edge offset")
	assert_gt(tabs_pri.max_scroll_offset, 100.0, "Scrollable tabs overflow container width")
	H.cover(self, "navigation.tabs.scrollable", "element", snap)

	var live: Dictionary = await H.record(stage, "navigation.tabs.scrollable", "select_and_auto_scroll", func() -> void:
		await stage.click(tabs_pri, tabs_pri.get_tab_center(2))
		await stage.wait(22)
	, 10, tabs_pri)
	assert_true(H.assert_recording(self, live))
	H.assert_mutated(self, live, "ScrollableTabsPrimary", "script_variables.selected_index", 2)
	H.assert_animated(self, live, "ScrollableTabsPrimary", "script_variables.scroll_offset", 3)
	H.assert_animated(self, live, "ScrollableTabsPrimary", "script_variables._indicator_x", 3)
	H.cover(self, "navigation.tabs.scrollable", "interaction", live)
	H.cover(self, "navigation.tabs.scrollable", "animation", live)
	stage.dispose()

func test_canonical_scaffolds_and_pane_splitter() -> void:
	var stage = await H.create_stage(self, "navigation", "canonical_scaffolds", false)

	var sc_list := M3CanonicalScaffold.new()
	sc_list.name = "ScaffoldListDetail"
	sc_list.scaffold_type = M3CanonicalScaffold.ScaffoldType.LIST_DETAIL
	sc_list.width_override = 960.0
	sc_list.split_ratio = 0.40
	sc_list.size = Vector2(580, 260)
	stage.add(sc_list, Vector2(32, 32))

	var sc_support := M3CanonicalScaffold.new()
	sc_support.name = "ScaffoldSupportingLarge"
	sc_support.scaffold_type = M3CanonicalScaffold.ScaffoldType.SUPPORTING_PANE
	sc_support.width_override = 1440.0
	sc_support.split_ratio = 0.55
	sc_support.size = Vector2(580, 260)
	stage.add(sc_support, Vector2(648, 32))

	var sc_feed := M3CanonicalScaffold.new()
	sc_feed.name = "ScaffoldFeed"
	sc_feed.scaffold_type = M3CanonicalScaffold.ScaffoldType.FEED
	sc_feed.width_override = 1280.0
	sc_feed.size = Vector2(580, 220)
	stage.add(sc_feed, Vector2(32, 324))

	var sc_compact := M3CanonicalScaffold.new()
	sc_compact.name = "ScaffoldCompact"
	sc_compact.scaffold_type = M3CanonicalScaffold.ScaffoldType.LIST_DETAIL
	sc_compact.width_override = 480.0
	sc_compact.size = Vector2(320, 220)
	stage.add(sc_compact, Vector2(648, 324))

	var ad_xl := M3AdaptiveNavigation.new()
	ad_xl.name = "AdaptiveExtraLarge"
	ad_xl.enable_extended_size_classes = true
	ad_xl.width_override = 1680.0
	ad_xl.size = Vector2(240, 220)
	stage.add(ad_xl, Vector2(988, 324))

	var ratio_signals: Array[int] = [0]
	sc_list.split_ratio_changed.connect(func(_r: float) -> void: ratio_signals[0] += 1)

	var snap: Dictionary = await H.snapshot(stage, "foundations.layout.canonical_scaffolds", "variants_light")
	assert_true(H.assert_snapshot(self, snap, [CANONICAL_SCAFFOLD_SCRIPT, ADAPTIVE_SCRIPT]))
	assert_eq(sc_list.active_size_class, M3AdaptiveNavigation.ExtendedWindowSizeClass.EXPANDED)
	assert_eq(sc_support.active_size_class, M3AdaptiveNavigation.ExtendedWindowSizeClass.LARGE)
	assert_true(sc_support.get_tertiary_pane().visible, "TertiaryPane visible in LARGE size class")
	assert_eq(ad_xl.window_size_class, M3AdaptiveNavigation.ExtendedWindowSizeClass.EXTRA_LARGE)
	H.cover(self, "foundations.layout.canonical_scaffolds", "element", snap)

	var live: Dictionary = await H.record(stage, "foundations.layout.canonical_scaffolds", "drag_splitter_and_compact_transition", func() -> void:
		var h_center: Vector2 = sc_list.get_handle_local_center()
		await stage.drag(sc_list, h_center, h_center + Vector2(110.0, 0.0), 10)
		sc_compact.show_detail_pane(true, true)
		await stage.wait(20)
	, 10, sc_list)
	assert_true(H.assert_recording(self, live))
	assert_gt(ratio_signals[0], 0, "split_ratio_changed emitted during handle drag")
	H.assert_mutated(self, live, "ScaffoldListDetail", "script_variables.split_ratio")
	H.assert_animated(self, live, "ScaffoldListDetail", "script_variables.split_ratio", 3)
	H.assert_animated(self, live, "ScaffoldListDetail", "script_variables.handle_x", 3)
	H.assert_mutated(self, live, "ScaffoldCompact", "script_variables.showing_detail_in_compact", true)
	H.assert_animated(self, live, "ScaffoldCompact", "script_variables.pane_transition_progress", 3)
	H.cover(self, "foundations.layout.canonical_scaffolds", "interaction", live)
	H.cover(self, "foundations.layout.canonical_scaffolds", "animation", live)
	stage.dispose()
