class_name TestM3NavigationFamily
extends GDTestSuite

## Comprehensive unit tests for the Material Design 3 Navigation Family:
## M3TopAppBar, M3BottomAppBar, M3Toolbar, M3SearchBar, M3SearchView,
## M3NavigationBar, M3NavigationRail, M3NavigationDrawer, M3Tabs, and M3AdaptiveNavigation.

func test_top_app_bar_variants_and_scroll_lift() -> void:
	var bar: M3TopAppBar = auto_add_child(M3TopAppBar.new()) as M3TopAppBar
	bar.size = Vector2(600, 64)
	bar.title = "Inbox"
	bar.subtitle = "12 unread"
	bar.variant = M3TopAppBar.BarVariant.SMALL
	var act0: M3IconButton = bar.add_action("search", "Search")
	var act1: M3IconButton = bar.add_action("favorite", "Favorite")
	await wait_frames(2)

	assert_eq(bar.custom_minimum_size.y, 64.0, "Small TopAppBar height is 64dp")
	assert_not_null(bar.get_navigation_button(), "Navigation button created")
	assert_not_null(act0, "First action button created")
	assert_not_null(act1, "Second action button created")

	var nav_hits: Array[int] = [0]
	var act_hits: Array[int] = [-1]
	bar.navigation_pressed.connect(func() -> void: nav_hits[0] += 1)
	bar.action_pressed.connect(func(idx: int) -> void: act_hits[0] = idx)

	bar.get_navigation_button()._on_pressed_action()
	assert_eq(nav_hits[0], 1, "navigation_pressed emitted")

	act1._on_pressed_action()
	assert_eq(act_hits[0], 1, "action_pressed emitted with index 1")

	# Medium and Large variants + scroll collapse
	bar.variant = M3TopAppBar.BarVariant.MEDIUM
	bar.subtitle = ""
	assert_eq(bar.custom_minimum_size.y, 112.0, "Medium TopAppBar expanded height is 112dp")

	bar.variant = M3TopAppBar.BarVariant.LARGE
	assert_eq(bar.custom_minimum_size.y, 152.0, "Large TopAppBar expanded height is 152dp")

	var unscrolled_col: Color = bar.get_container_color()
	bar.set_scrolled(true, false)
	assert_approx(bar.scroll_lift_progress, 1.0, 0.01, "scroll_lift_progress is 1.0 when scrolled")
	assert_approx(bar.collapse_progress, 1.0, 0.01, "collapse_progress is 1.0 when Large bar is scrolled")
	assert_eq(bar.custom_minimum_size.y, 64.0, "Collapsed Large TopAppBar height is 64dp")
	var scrolled_col: Color = bar.get_container_color()
	assert_ne(unscrolled_col, scrolled_col, "Scrolled container color differs from unscrolled surface color")

func test_bottom_app_bar_actions_fab_and_hide_on_scroll() -> void:
	var bar: M3BottomAppBar = auto_add_child(M3BottomAppBar.new()) as M3BottomAppBar
	bar.size = Vector2(600, 80)
	bar.add_action("menu")
	bar.add_action("search")
	bar.add_action("favorite")
	bar.add_action("bookmark")
	bar.add_action("extra_ignored")
	await wait_frames(2)

	assert_eq(bar.custom_minimum_size.y, 80.0, "BottomAppBar height is 80dp")
	assert_eq(bar.get_action_count(), 4, "BottomAppBar caps leading actions at 4 per M3 spec")
	assert_not_null(bar.get_fab(), "Embedded FAB exists")
	assert_true(bar.get_fab().visible, "Embedded FAB visible when show_fab=true")

	var action_idx: Array[int] = [-1]
	var fab_count: Array[int] = [0]
	bar.action_pressed.connect(func(idx: int) -> void: action_idx[0] = idx)
	bar.fab_pressed.connect(func() -> void: fab_count[0] += 1)

	bar.get_action_button(2)._on_pressed_action()
	assert_eq(action_idx[0], 2, "BottomAppBar action 2 emitted action_pressed(2)")

	bar.get_fab()._on_pressed_action()
	assert_eq(fab_count[0], 1, "BottomAppBar embedded FAB emitted fab_pressed")

	bar.set_hidden_on_scroll(true, false)
	assert_approx(bar.visible_progress, 0.0, 0.01, "visible_progress is 0.0 when hidden on scroll")
	assert_approx(bar._vertical_offset, 80.0, 0.1, "_vertical_offset shifts down by 80dp when hidden")

	bar.set_hidden_on_scroll(false, false)
	assert_approx(bar.visible_progress, 1.0, 0.01, "visible_progress restored to 1.0")

func test_toolbar_expressive_variants_and_selection() -> void:
	var tb: M3Toolbar = auto_add_child(M3Toolbar.new()) as M3Toolbar
	tb.toolbar_type = M3Toolbar.ToolbarType.FLOATING
	tb.orientation = M3Toolbar.Orientation.HORIZONTAL
	tb.color_style = M3Toolbar.ColorStyle.STANDARD
	tb.show_fab = true
	tb.add_item("edit", "Edit")
	tb.add_item("share", "Share")
	tb.add_item("bookmark", "Save")
	await wait_frames(2)

	assert_eq(tb.custom_minimum_size.y, 64.0, "Horizontal floating toolbar height is 64dp")
	assert_eq(tb.get_item_count(), 3, "Toolbar has 3 items")
	assert_gt(tb.get_fab_rect().size.x, 0.0, "Floating toolbar with show_fab has adjacent FAB rect")

	var selected: Array[int] = [-1]
	tb.item_selected.connect(func(idx: int) -> void: selected[0] = idx)
	tb.active_index = 2
	assert_eq(selected[0], 2, "Changing active_index emits item_selected(2)")

	var std_bg: Color = tb.get_container_color()
	tb.color_style = M3Toolbar.ColorStyle.VIBRANT
	var vib_bg: Color = tb.get_container_color()
	assert_ne(std_bg, vib_bg, "Vibrant toolbar container color differs from Standard")

	tb.orientation = M3Toolbar.Orientation.VERTICAL
	assert_eq(tb.custom_minimum_size.x, 64.0, "Vertical floating toolbar width is 64dp")

	tb.toolbar_type = M3Toolbar.ToolbarType.DOCKED
	tb.orientation = M3Toolbar.Orientation.HORIZONTAL
	assert_eq(tb.custom_minimum_size.y, 64.0, "Docked toolbar height is 64dp")

func test_search_bar_and_search_view_linking() -> void:
	var sb: M3SearchBar = auto_add_child(M3SearchBar.new()) as M3SearchBar
	sb.size = Vector2(360, 56)
	sb.placeholder_text = "Search docs..."
	sb.badge_count = 3

	var sv: M3SearchView = auto_add_child(M3SearchView.new()) as M3SearchView
	sv.size = Vector2(360, 260)
	sv.close(false)
	var row0: Control = sv.add_suggestion("Material 3 Navigation", "schedule")
	sv.add_suggestion("Expressive Toolbars", "search")

	sb.search_view = sv
	await wait_frames(2)

	assert_eq(sb.custom_minimum_size.y, 56.0, "SearchBar height is 56dp")
	assert_false(sv.is_open, "SearchView starts closed after close(false)")
	assert_not_null(row0, "Suggestion row created")

	var activated: Array[int] = [0]
	sb.search_activated.connect(func() -> void: activated[0] += 1)

	sb._on_pressed_action()
	assert_eq(activated[0], 1, "SearchBar emitted search_activated")
	assert_true(sv.is_open, "Linked SearchView opened when SearchBar activated")

	var submitted: Array[String] = [""]
	sv.search_submitted.connect(func(q: String) -> void: submitted[0] = q)
	sv._select_suggestion("Material 3 Navigation")
	assert_eq(sv.query, "Material 3 Navigation", "SearchView query updated from suggestion")
	assert_eq(sb.query, "Material 3 Navigation", "Linked SearchBar query synced from SearchView")
	assert_eq(submitted[0], "Material 3 Navigation", "search_submitted emitted")

	sv.clear_query()
	assert_eq(sv.query, "", "clear_query emptied SearchView query")

func test_navigation_bar_rail_drawer_tabs_and_adaptive() -> void:
	# Navigation Bar
	var nav_bar: M3NavigationBar = auto_add_child(M3NavigationBar.new()) as M3NavigationBar
	nav_bar.size = Vector2(400, 80)
	nav_bar.set_badge(2, 15)
	assert_eq(int(nav_bar.destinations[2]["badge"]), 15, "set_badge updated destination badge")

	# Navigation Rail (compact -> expanded)
	var rail: M3NavigationRail = auto_add_child(M3NavigationRail.new()) as M3NavigationRail
	rail.size = Vector2(80, 400)
	rail.show_menu_button = true
	rail.alignment = M3NavigationRail.RailAlignment.CENTER
	rail.set_expanded(true, false)
	assert_approx(rail.expand_progress, 1.0, 0.01, "Expanded rail has expand_progress = 1.0")
	assert_eq(rail.custom_minimum_size.x, 220.0, "Expanded rail width is 220dp")
	rail.set_expanded(false, false)
	assert_eq(rail.custom_minimum_size.x, 80.0, "Compact rail width is 80dp")

	# Navigation Drawer (modal open/close)
	var drawer: M3NavigationDrawer = auto_add_child(M3NavigationDrawer.new()) as M3NavigationDrawer
	drawer.drawer_type = M3NavigationDrawer.DrawerType.MODAL
	await wait_frames(2)
	drawer.close_drawer(false)
	assert_false(drawer.is_open, "Modal drawer closed")
	assert_approx(drawer.open_progress, 0.0, 0.01, "Closed modal drawer open_progress is 0.0")
	drawer.open_drawer(false)
	assert_true(drawer.is_open, "Modal drawer opened")
	assert_approx(drawer.open_progress, 1.0, 0.01, "Opened modal drawer open_progress is 1.0")

	# Tabs
	var tabs: M3Tabs = auto_add_child(M3Tabs.new()) as M3Tabs
	tabs.size = Vector2(360, 48)
	tabs.tab_type = M3Tabs.TabType.SECONDARY
	tabs.selected_index = 2
	assert_eq(tabs.selected_index, 2, "Secondary tabs selected_index updated")

	# Adaptive Navigation & Window Size Classes
	assert_eq(M3AdaptiveNavigation.classify_width(480.0), M3AdaptiveNavigation.LayoutMode.COMPACT)
	assert_eq(M3AdaptiveNavigation.classify_width(700.0), M3AdaptiveNavigation.LayoutMode.MEDIUM)
	assert_eq(M3AdaptiveNavigation.classify_width(960.0), M3AdaptiveNavigation.LayoutMode.EXPANDED)

	var adaptive: M3AdaptiveNavigation = auto_add_child(M3AdaptiveNavigation.new()) as M3AdaptiveNavigation
	await wait_frames(2)
	adaptive.width_override = 500.0
	assert_eq(adaptive.current_mode, M3AdaptiveNavigation.LayoutMode.COMPACT)
	assert_true(adaptive.get_navigation_bar().visible)
	adaptive.width_override = 720.0
	assert_eq(adaptive.current_mode, M3AdaptiveNavigation.LayoutMode.MEDIUM)
	assert_true(adaptive.get_navigation_rail().visible)
	adaptive.width_override = 1024.0
	assert_eq(adaptive.current_mode, M3AdaptiveNavigation.LayoutMode.EXPANDED)
	assert_true(adaptive.get_navigation_drawer().visible)

func test_scrollable_tabs_and_canonical_scaffolds() -> void:
	# Scrollable Tabs (52dp leading edge offset)
	var stabs: M3Tabs = auto_add_child(M3Tabs.new()) as M3Tabs
	stabs.size = Vector2(420, 48)
	stabs.scrollable = true
	stabs.leading_edge_offset = 52.0
	stabs.min_tab_width = 120.0
	stabs.tabs = [
		{"label": "Tab One"},
		{"label": "Tab Two"},
		{"label": "Tab Three"},
		{"label": "Tab Four"},
		{"label": "Tab Five"}
	]
	await wait_frames(2)

	assert_true(stabs.clip_contents, "Scrollable tabs enable clip_contents")
	assert_gt(stabs.max_scroll_offset, 100.0, "Scrollable tabs compute positive max_scroll_offset")
	stabs.scroll_to_tab(3, false)
	assert_gt(stabs.scroll_offset, 0.0, "scroll_to_tab(3, false) scrolls offset > 0")

	# Extended Window Size Classes (5 tiers)
	assert_eq(M3AdaptiveNavigation.classify_extended_width(480.0), M3AdaptiveNavigation.ExtendedWindowSizeClass.COMPACT)
	assert_eq(M3AdaptiveNavigation.classify_extended_width(720.0), M3AdaptiveNavigation.ExtendedWindowSizeClass.MEDIUM)
	assert_eq(M3AdaptiveNavigation.classify_extended_width(1024.0), M3AdaptiveNavigation.ExtendedWindowSizeClass.EXPANDED)
	assert_eq(M3AdaptiveNavigation.classify_extended_width(1440.0), M3AdaptiveNavigation.ExtendedWindowSizeClass.LARGE)
	assert_eq(M3AdaptiveNavigation.classify_extended_width(1920.0), M3AdaptiveNavigation.ExtendedWindowSizeClass.EXTRA_LARGE)

	# Canonical Multi-Pane Scaffold & Pane Expansion Splitter
	var scaffold: M3CanonicalScaffold = auto_add_child(M3CanonicalScaffold.new()) as M3CanonicalScaffold
	scaffold.size = Vector2(800, 400)
	scaffold.width_override = 960.0
	await wait_frames(2)

	assert_not_null(scaffold.get_primary_pane(), "PrimaryPane exists")
	assert_not_null(scaffold.get_secondary_pane(), "SecondaryPane exists")
	assert_not_null(scaffold.get_tertiary_pane(), "TertiaryPane exists")
	assert_true(scaffold.get_primary_pane().visible, "PrimaryPane visible in EXPANDED")
	assert_true(scaffold.get_secondary_pane().visible, "SecondaryPane visible in EXPANDED")
	assert_false(scaffold.get_tertiary_pane().visible, "TertiaryPane hidden in EXPANDED (<1200)")

	var old_handle_x: float = scaffold.handle_x
	scaffold.set_split_ratio(0.60, false)
	assert_approx(scaffold.split_ratio, 0.60, 0.01, "split_ratio updated to 0.60")
	assert_gt(scaffold.handle_x, old_handle_x, "handle_x shifted right with larger split_ratio")

	scaffold.width_override = 1400.0
	assert_eq(scaffold.active_size_class, M3AdaptiveNavigation.ExtendedWindowSizeClass.LARGE)
	assert_true(scaffold.get_tertiary_pane().visible, "TertiaryPane visible in LARGE (>=1200)")

	scaffold.width_override = 480.0
	assert_eq(scaffold.active_size_class, M3AdaptiveNavigation.ExtendedWindowSizeClass.COMPACT)
	assert_true(scaffold.get_primary_pane().visible, "Compact starts on PrimaryPane")
	assert_false(scaffold.get_secondary_pane().visible, "SecondaryPane hidden initially in Compact")
	scaffold.show_detail_pane(true, false)
	assert_true(scaffold.showing_detail_in_compact, "showing_detail_in_compact is true")
	assert_true(scaffold.get_secondary_pane().visible, "SecondaryPane visible when showing detail in Compact")
