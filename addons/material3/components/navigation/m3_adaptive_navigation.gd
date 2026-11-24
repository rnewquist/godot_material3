@tool
class_name M3AdaptiveNavigation
extends Control

signal destination_selected(index: int)
signal layout_mode_changed(mode: LayoutMode)

enum LayoutMode {
	COMPACT, # < 600px (Bottom Navigation Bar)
	MEDIUM,  # 600 - 839px (Navigation Rail)
	EXPANDED # >= 840px (Navigation Drawer)
}

enum WindowSizeClass {
	COMPACT = 0,
	MEDIUM = 1,
	EXPANDED = 2
}

enum ExtendedWindowSizeClass {
	COMPACT = 0,     # < 600dp
	MEDIUM = 1,      # 600 - 839dp
	EXPANDED = 2,    # 840 - 1199dp
	LARGE = 3,       # 1200 - 1599dp
	EXTRA_LARGE = 4  # >= 1600dp
}

@export var destinations: Array[Dictionary] = [
	{"label": "Buttons", "icon": null, "badge": 0},
	{"label": "Selection", "icon": null, "badge": 0},
	{"label": "Inputs", "icon": null, "badge": 0},
	{"label": "Chips & Badges", "icon": null, "badge": 0},
	{"label": "Surfaces", "icon": null, "badge": 0},
	{"label": "Navigation", "icon": null, "badge": 0},
	{"label": "Progress", "icon": null, "badge": 0},
	{"label": "Responsive", "icon": null, "badge": 0}
]:
	set(value):
		destinations = value
		_sync_nav_destinations()

@export var selected_index: int = 0:
	set(value):
		if selected_index != value and value >= 0 and value < destinations.size():
			selected_index = value
			_sync_selected_index()
			_update_screen_visibility()
			destination_selected.emit(selected_index)

@export var compact_breakpoint: float = 600.0
@export var expanded_breakpoint: float = 840.0
@export var large_breakpoint: float = 1200.0
@export var extra_large_breakpoint: float = 1600.0
@export var enable_extended_size_classes: bool = false:
	set(value):
		enable_extended_size_classes = value
		_update_layout()
@export var width_override: float = -1.0:
	set(value):
		width_override = value
		_update_layout()

var current_mode: LayoutMode = LayoutMode.EXPANDED
var window_size_class: int = WindowSizeClass.EXPANDED
var extended_window_size_class: int = ExtendedWindowSizeClass.EXPANDED
var _content_container: Control
var _nav_bar: M3NavigationBar
var _nav_rail: M3NavigationRail
var _nav_drawer: M3NavigationDrawer
var _h_split: HBoxContainer
var _v_split: VBoxContainer
var _screens: Array[Control] = []

func _init() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

func _ready() -> void:
	_build_layout()
	_update_layout()
	_update_screen_visibility()

static func classify_width(width: float, compact_bp: float = 600.0, expanded_bp: float = 840.0) -> LayoutMode:
	if width < compact_bp:
		return LayoutMode.COMPACT
	elif width < expanded_bp:
		return LayoutMode.MEDIUM
	return LayoutMode.EXPANDED

static func classify_extended_width(
	w: float,
	compact_bp: float = 600.0,
	expanded_bp: float = 840.0,
	large_bp: float = 1200.0,
	extra_large_bp: float = 1600.0
) -> ExtendedWindowSizeClass:
	if w < compact_bp:
		return ExtendedWindowSizeClass.COMPACT
	elif w < expanded_bp:
		return ExtendedWindowSizeClass.MEDIUM
	elif w < large_bp:
		return ExtendedWindowSizeClass.EXPANDED
	elif w < extra_large_bp:
		return ExtendedWindowSizeClass.LARGE
	return ExtendedWindowSizeClass.EXTRA_LARGE

func get_navigation_bar() -> M3NavigationBar:
	return _nav_bar

func get_navigation_rail() -> M3NavigationRail:
	return _nav_rail

func get_navigation_drawer() -> M3NavigationDrawer:
	return _nav_drawer

func _build_layout() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	# Vertical container for compact mode
	_v_split = VBoxContainer.new()
	_v_split.name = "CompactVBox"
	_v_split.set_anchors_preset(PRESET_FULL_RECT)
	_v_split.size_flags_horizontal = SIZE_EXPAND_FILL
	_v_split.size_flags_vertical = SIZE_EXPAND_FILL
	_v_split.add_theme_constant_override("separation", 0)
	add_child(_v_split)

	# Horizontal container for medium/expanded
	_h_split = HBoxContainer.new()
	_h_split.name = "AdaptiveHBox"
	_h_split.set_anchors_preset(PRESET_FULL_RECT)
	_h_split.size_flags_horizontal = SIZE_EXPAND_FILL
	_h_split.size_flags_vertical = SIZE_EXPAND_FILL
	_h_split.add_theme_constant_override("separation", 0)
	add_child(_h_split)

	# Navigation Rail
	_nav_rail = M3NavigationRail.new()
	_nav_rail.name = "AdaptiveNavRail"
	_nav_rail.destinations = destinations
	_nav_rail.has_fab = false
	_nav_rail.destination_selected.connect(_on_nav_selected)
	_h_split.add_child(_nav_rail)

	# Navigation Drawer
	_nav_drawer = M3NavigationDrawer.new()
	_nav_drawer.name = "AdaptiveNavDrawer"
	_nav_drawer.drawer_type = M3NavigationDrawer.DrawerType.STANDARD
	_nav_drawer.drawer_width = 240.0
	_nav_drawer.destinations = destinations
	_nav_drawer.destination_selected.connect(_on_nav_selected)
	_h_split.add_child(_nav_drawer)

	# Main Content Area
	_content_container = Control.new()
	_content_container.name = "ContentContainer"
	_content_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_content_container.size_flags_vertical = SIZE_EXPAND_FILL
	_h_split.add_child(_content_container)

	# Navigation Bar
	_nav_bar = M3NavigationBar.new()
	_nav_bar.name = "AdaptiveNavBar"
	_nav_bar.destinations = destinations
	_nav_bar.destination_selected.connect(_on_nav_selected)
	_v_split.add_child(_nav_bar)

func add_screen(screen: Control) -> void:
	_screens.append(screen)
	if _content_container:
		screen.set_anchors_preset(PRESET_FULL_RECT)
		screen.size_flags_horizontal = SIZE_EXPAND_FILL
		screen.size_flags_vertical = SIZE_EXPAND_FILL
		_content_container.add_child(screen)
	_update_screen_visibility()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func _update_layout() -> void:
	var w := width_override if width_override > 0.0 else (size.x if size.x > 0.0 else (get_viewport_rect().size.x if is_inside_tree() else 1000.0))

	var new_mode: LayoutMode = classify_width(w, compact_breakpoint, expanded_breakpoint)
	var ext_class: ExtendedWindowSizeClass = classify_extended_width(w, compact_breakpoint, expanded_breakpoint, large_breakpoint, extra_large_breakpoint)
	current_mode = new_mode
	extended_window_size_class = int(ext_class)
	window_size_class = extended_window_size_class if enable_extended_size_classes else int(new_mode)
	_apply_layout_mode()
	layout_mode_changed.emit(current_mode)

func _apply_layout_mode() -> void:
	if not _nav_bar or not _nav_rail or not _nav_drawer:
		return

	match current_mode:
		LayoutMode.COMPACT:
			_v_split.visible = true
			_h_split.visible = false
			_nav_bar.visible = true
			_nav_rail.visible = false
			_nav_drawer.visible = false
			if _content_container and _content_container.get_parent() != _v_split:
				_content_container.get_parent().remove_child(_content_container)
				_v_split.add_child(_content_container)
				_v_split.move_child(_content_container, 0)
		LayoutMode.MEDIUM:
			_v_split.visible = false
			_h_split.visible = true
			_nav_bar.visible = false
			_nav_rail.visible = true
			_nav_drawer.visible = false
			if _content_container and _content_container.get_parent() != _h_split:
				_content_container.get_parent().remove_child(_content_container)
				_h_split.add_child(_content_container)
		LayoutMode.EXPANDED:
			_v_split.visible = false
			_h_split.visible = true
			_nav_bar.visible = false
			_nav_rail.visible = false
			_nav_drawer.visible = true
			if _content_container and _content_container.get_parent() != _h_split:
				_content_container.get_parent().remove_child(_content_container)
				_h_split.add_child(_content_container)

	_sync_selected_index()

func _sync_nav_destinations() -> void:
	if _nav_bar: _nav_bar.destinations = destinations
	if _nav_rail: _nav_rail.destinations = destinations
	if _nav_drawer:
		_nav_drawer.destinations = destinations

func _sync_selected_index() -> void:
	if _nav_bar: _nav_bar.selected_index = selected_index
	if _nav_rail: _nav_rail.selected_index = selected_index
	if _nav_drawer:
		_nav_drawer.selected_index = selected_index
		_nav_drawer._update_items_redraw()

func _on_nav_selected(idx: int) -> void:
	selected_index = idx

func _update_screen_visibility() -> void:
	for i in range(_screens.size()):
		var scr := _screens[i]
		scr.visible = (i == selected_index)
