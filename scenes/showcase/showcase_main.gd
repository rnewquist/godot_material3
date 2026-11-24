@tool
class_name ShowcaseMain
extends Control

var _adaptive_nav: M3AdaptiveNavigation
var _top_bar: PanelContainer
var _theme_mode_btn: M3Button
var _seed_dropdown: M3SelectDropdown
var _screens_container: Control

func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	_apply_styling()
	if get_viewport() and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func _setup_theme_listener() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and not mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.connect(_on_theme_changed)

func _exit_tree() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.disconnect(_on_theme_changed)
	if get_viewport() and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)

func _on_theme_changed() -> void:
	_apply_styling()
	queue_redraw()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func _on_viewport_size_changed() -> void:
	queue_redraw()

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()
		
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)
	
	# Top App Bar (64dp height)
	_top_bar = PanelContainer.new()
	_top_bar.custom_minimum_size = Vector2(0, 64)
	root_vbox.add_child(_top_bar)
	
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_right", 24)
	top_margin.add_theme_constant_override("margin_top", 8)
	top_margin.add_theme_constant_override("margin_bottom", 8)
	_top_bar.add_child(top_margin)
	
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 16)
	top_margin.add_child(top_hbox)
	
	# App Title
	var title_lbl := Label.new()
	title_lbl.text = "Material 3 Godot"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	title_lbl.name = "AppTitle"
	top_hbox.add_child(title_lbl)
	
	# Seed Color Selector Dropdown
	_seed_dropdown = M3SelectDropdown.new()
	_seed_dropdown.label = "Theme Seed"
	_seed_dropdown.options = ["Indigo", "Teal", "Terracotta", "Emerald", "Amber", "Coral"]
	_seed_dropdown.custom_minimum_size = Vector2(160, 48)
	_seed_dropdown.item_selected.connect(_on_seed_selected)
	top_hbox.add_child(_seed_dropdown)
	
	# Dark/Light Mode Button
	_theme_mode_btn = M3Button.new()
	_theme_mode_btn.variant = M3Button.Variant.OUTLINED
	_theme_mode_btn.text = "Dark Mode"
	_theme_mode_btn.custom_minimum_size = Vector2(120, 40)
	_theme_mode_btn.pressed.connect(_toggle_theme_mode)
	top_hbox.add_child(_theme_mode_btn)
	
	# Adaptive Navigation Container
	var nav_container := Control.new()
	nav_container.size_flags_horizontal = SIZE_EXPAND_FILL
	nav_container.size_flags_vertical = SIZE_EXPAND_FILL
	root_vbox.add_child(nav_container)
	
	_adaptive_nav = M3AdaptiveNavigation.new()
	_adaptive_nav.destinations = [
		{"label": "Buttons", "icon": null, "badge": 0},
		{"label": "Selection", "icon": null, "badge": 0},
		{"label": "Inputs", "icon": null, "badge": 0},
		{"label": "Chips & Badges", "icon": null, "badge": 0},
		{"label": "Surfaces", "icon": null, "badge": 0},
		{"label": "Navigation", "icon": null, "badge": 0},
		{"label": "Progress", "icon": null, "badge": 0},
		{"label": "Responsive", "icon": null, "badge": 0}
	]
	nav_container.add_child(_adaptive_nav)
	_adaptive_nav.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	# Add Screens
	var scr_buttons := ShowcaseButtonsScreen.new()
	_adaptive_nav.add_screen(scr_buttons)
	
	var scr_selection := ShowcaseSelectionScreen.new()
	_adaptive_nav.add_screen(scr_selection)
	
	var scr_inputs := ShowcaseInputsScreen.new()
	_adaptive_nav.add_screen(scr_inputs)
	
	var scr_chips := ShowcaseChipsBadgesScreen.new()
	_adaptive_nav.add_screen(scr_chips)
	
	var scr_surfaces := ShowcaseSurfacesScreen.new()
	_adaptive_nav.add_screen(scr_surfaces)
	
	var scr_navigation := ShowcaseNavigationScreen.new()
	_adaptive_nav.add_screen(scr_navigation)
	
	var scr_progress := ShowcaseProgressScreen.new()
	_adaptive_nav.add_screen(scr_progress)
	
	var scr_responsive := ShowcaseResponsiveDemoScreen.new()
	_adaptive_nav.add_screen(scr_responsive)

func _on_seed_selected(idx: int, _val: String) -> void:
	var mgr := M3ThemeManager.get_instance()
	mgr.set_seed_preset(idx as M3ThemeManager.SeedPreset)

func _toggle_theme_mode() -> void:
	var mgr := M3ThemeManager.get_instance()
	mgr.toggle_dark_mode()
	if _theme_mode_btn:
		_theme_mode_btn.text = "Light Mode" if mgr.is_dark else "Dark Mode"

func _apply_styling() -> void:
	var s := get_scheme()
	if _top_bar:
		var sb := StyleBoxFlat.new()
		sb.bg_color = s.surface_container
		sb.border_width_bottom = 1
		sb.border_color = s.outline_variant
		_top_bar.add_theme_stylebox_override("panel", sb)
		
		if _top_bar.has_node("%AppTitle") or _top_bar.find_child("AppTitle"):
			var t := _top_bar.find_child("AppTitle") as Label
			if t: t.add_theme_color_override("font_color", s.on_surface)

func _draw() -> void:
	var s := get_scheme()
	draw_rect(Rect2(Vector2.ZERO, size), s.surface)
