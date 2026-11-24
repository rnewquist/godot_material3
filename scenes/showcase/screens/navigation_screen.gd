@tool
class_name ShowcaseNavigationScreen
extends ScrollContainer

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build_ui()

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 32)
	pad.add_theme_constant_override("margin_right", 32)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_bottom", 48)
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pad.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "Navigation Components"
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)

	# Section 0: Top App Bar & Bottom App Bar
	var sec_app_bars := _create_section(vbox, "App Bars (Top & Bottom)", "Center-aligned, small, medium, and large top app bars with scroll lift + 80dp bottom app bar with embedded FAB.")

	var top_small := M3TopAppBar.new()
	top_small.variant = M3TopAppBar.BarVariant.SMALL
	top_small.title = "Inbox"
	top_small.subtitle = "24 unread messages"
	top_small.add_action("search", "Search")
	top_small.add_action("favorite", "Favorites")
	top_small.add_action("settings", "Settings")
	sec_app_bars.add_child(top_small)

	var top_medium := M3TopAppBar.new()
	top_medium.variant = M3TopAppBar.BarVariant.MEDIUM
	top_medium.title = "Material 3 Expressive"
	top_medium.subtitle = "Collapsible medium app bar"
	top_medium.add_action("edit", "Edit")
	sec_app_bars.add_child(top_medium)

	var bottom_bar := M3BottomAppBar.new()
	bottom_bar.add_action("menu", "Menu")
	bottom_bar.add_action("search", "Search")
	bottom_bar.add_action("favorite", "Favorite")
	bottom_bar.show_fab = true
	bottom_bar.fab_icon = "add"
	sec_app_bars.add_child(bottom_bar)

	# Section 0b: Expressive Toolbars
	var sec_toolbars := _create_section(vbox, "Expressive Toolbars (Docked & Floating)", "Standard and vibrant pill-shaped floating toolbars and full-width docked toolbars.")

	var toolbar_row := HBoxContainer.new()
	toolbar_row.add_theme_constant_override("separation", 16)
	sec_toolbars.add_child(toolbar_row)

	var tb_floating := M3Toolbar.new()
	tb_floating.toolbar_type = M3Toolbar.ToolbarType.FLOATING
	tb_floating.color_style = M3Toolbar.ColorStyle.STANDARD
	tb_floating.show_fab = true
	tb_floating.add_item("edit", "Edit")
	tb_floating.add_item("share", "Share")
	tb_floating.add_item("bookmark", "Bookmark")
	tb_floating.add_item("favorite", "Favorite")
	toolbar_row.add_child(tb_floating)

	var tb_vibrant := M3Toolbar.new()
	tb_vibrant.toolbar_type = M3Toolbar.ToolbarType.FLOATING
	tb_vibrant.color_style = M3Toolbar.ColorStyle.VIBRANT
	tb_vibrant.add_item("search", "Search")
	tb_vibrant.add_item("tune", "Filter")
	tb_vibrant.add_item("undo", "Undo")
	toolbar_row.add_child(tb_vibrant)

	var tb_docked := M3Toolbar.new()
	tb_docked.toolbar_type = M3Toolbar.ToolbarType.DOCKED
	tb_docked.color_style = M3Toolbar.ColorStyle.STANDARD
	tb_docked.add_item("edit", "Edit")
	tb_docked.add_item("share", "Share")
	tb_docked.add_item("bookmark", "Save")
	tb_docked.add_item("delete", "Delete")
	sec_toolbars.add_child(tb_docked)

	# Section 0c: Search Bar & Search View
	var sec_search := _create_section(vbox, "Search Bar & Search View", "56dp pill search bar linked to an expandable search view with suggestions.")
	var search_bar := M3SearchBar.new()
	search_bar.placeholder_text = "Search Material 3 components..."
	sec_search.add_child(search_bar)

	var search_view := M3SearchView.new()
	search_view.placeholder_text = "Type a query..."
	search_view.add_suggestion("Navigation Bar", "schedule")
	search_view.add_suggestion("Top App Bar", "search")
	search_view.add_suggestion("Expressive Toolbar", "star")
	search_bar.search_view = search_view
	sec_search.add_child(search_view)

	# Section 1: Tabs
	var sec1 := _create_section(vbox, "Tabs", "Primary (pill underline indicator) and Secondary (full-width underline) tabs.")

	var t_lbl1 := Label.new()
	t_lbl1.text = "Primary Tabs:"
	sec1.add_child(t_lbl1)

	var tabs1 := M3Tabs.new()
	tabs1.tab_type = M3Tabs.TabType.PRIMARY
	tabs1.tabs = [{"label": "Explore"}, {"label": "Flights"}, {"label": "Hotels"}, {"label": "Car Rental"}]
	sec1.add_child(tabs1)

	var t_lbl2 := Label.new()
	t_lbl2.text = "Secondary Tabs:"
	sec1.add_child(t_lbl2)

	var tabs2 := M3Tabs.new()
	tabs2.tab_type = M3Tabs.TabType.SECONDARY
	tabs2.tabs = [{"label": "Description"}, {"label": "Specifications"}, {"label": "Reviews (42)"}]
	sec1.add_child(tabs2)

	var t_lbl3 := Label.new()
	t_lbl3.text = "Scrollable Tabs (52dp leading edge offset):"
	sec1.add_child(t_lbl3)

	var tabs_scroll := M3Tabs.new()
	tabs_scroll.tab_type = M3Tabs.TabType.PRIMARY
	tabs_scroll.scrollable = true
	tabs_scroll.leading_edge_offset = 52.0
	tabs_scroll.tabs = [
		{"label": "For You"},
		{"label": "Top Charts"},
		{"label": "New Releases"},
		{"label": "Editor's Choice"},
		{"label": "Categories"},
		{"label": "Family & Kids"}
	]
	sec1.add_child(tabs_scroll)

	# Section 2: Bottom Navigation Bar Preview
	var sec2 := _create_section(vbox, "Navigation Bar Preview", "Standard 80dp bottom navigation bar with active pill indicator.")
	var nav_bar := M3NavigationBar.new()
	nav_bar.destinations = [
		{"label": "Mail", "icon": null, "badge": 4},
		{"label": "Chat", "icon": null, "badge": 0},
		{"label": "Spaces", "icon": null, "badge": 12},
		{"label": "Meet", "icon": null, "badge": 0}
	]
	sec2.add_child(nav_bar)

	# Section 3: Navigation Rail & Drawer Previews
	var sec3 := _create_section(vbox, "Navigation Rail & Navigation Drawer", "80dp side rail and 320dp side drawer previews.")
	var split_row := HBoxContainer.new()
	split_row.add_theme_constant_override("separation", 24)
	sec3.add_child(split_row)

	# Rail container
	var rail_box := PanelContainer.new()
	rail_box.custom_minimum_size = Vector2(100, 360)
	var rail := M3NavigationRail.new()
	rail.destinations = [
		{"label": "Inbox", "icon": null, "badge": 5},
		{"label": "Starred", "icon": null, "badge": 0},
		{"label": "Sent", "icon": null, "badge": 0}
	]
	rail_box.add_child(rail)
	split_row.add_child(rail_box)

	# Drawer container
	var drawer_box := PanelContainer.new()
	drawer_box.custom_minimum_size = Vector2(300, 360)
	drawer_box.size_flags_horizontal = SIZE_EXPAND_FILL
	var drawer := M3NavigationDrawer.new()
	drawer.drawer_type = M3NavigationDrawer.DrawerType.STANDARD
	drawer.drawer_width = 280.0
	drawer.destinations = [
		{"label": "Inbox", "icon": null, "badge": 12, "section": "Primary"},
		{"label": "Starred", "icon": null, "badge": 0, "section": "Primary"},
		{"label": "Snoozed", "icon": null, "badge": 0, "section": "Primary"},
		{"label": "Spam", "icon": null, "badge": 99, "section": "Labels"},
		{"label": "Trash", "icon": null, "badge": 0, "section": "Labels"}
	]
	drawer_box.add_child(drawer)
	split_row.add_child(drawer_box)

	# Section 4: Canonical Multi-Pane Scaffolds & Pane Expansion Splitter
	var sec4 := _create_section(vbox, "Canonical Multi-Pane Scaffolds", "List-Detail, Supporting-Pane, and Feed scaffolds with draggable 4x48dp Pane Expansion splitter.")
	var scaffold_demo := M3CanonicalScaffold.new()
	scaffold_demo.custom_minimum_size = Vector2(520, 240)
	scaffold_demo.scaffold_type = M3CanonicalScaffold.ScaffoldType.LIST_DETAIL
	scaffold_demo.split_ratio = 0.40
	sec4.add_child(scaffold_demo)

func _create_section(parent: VBoxContainer, title: String, desc: String) -> VBoxContainer:
	var sec_card := M3Card.new()
	sec_card.card_type = M3Card.CardType.OUTLINED
	parent.add_child(sec_card)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	sec_card.add_child(inner)

	var head := Label.new()
	head.text = title
	head.add_theme_font_size_override("font_size", 18)
	inner.add_child(head)

	var d := Label.new()
	d.text = desc
	d.add_theme_font_size_override("font_size", 13)
	inner.add_child(d)

	var div := M3Divider.new()
	inner.add_child(div)

	return inner
