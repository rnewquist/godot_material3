@tool
class_name M3ThemeSingleton
extends Node

## Central Material Design 3 Theme Singleton (Autoload M3Theme).
## Coordinates active dynamic color schemes, dark mode state, seed color transitions, and theme change signals.

signal theme_changed
signal mode_changed(is_dark: bool)
signal seed_color_changed(color: Color)
signal contrast_level_changed(level: float)
signal scheme_variant_changed(variant: int)
signal density_changed(density: int)

static var _instance: M3ThemeSingleton = null

@export var seed_color: Color = M3PaletteGenerator.PRESET_BASELINE_INDIGO:
	set(value):
		if seed_color != value:
			seed_color = value
			regenerate_schemes()
			seed_color_changed.emit(seed_color)
			theme_changed.emit()

@export var is_dark_mode: bool = true:
	set(value):
		if is_dark_mode != value:
			is_dark_mode = value
			_update_active_scheme()
			mode_changed.emit(is_dark_mode)
			theme_changed.emit()

@export_range(-1.0, 1.0, 0.5) var contrast_level: float = 0.0:
	set(value):
		var cl: float = clampf(value, -1.0, 1.0)
		if not is_equal_approx(contrast_level, cl):
			contrast_level = cl
			regenerate_schemes()
			contrast_level_changed.emit(contrast_level)
			theme_changed.emit()

@export var scheme_variant: M3PaletteGenerator.SchemeVariant = M3PaletteGenerator.SchemeVariant.TONAL_SPOT:
	set(value):
		if scheme_variant != value:
			scheme_variant = value
			regenerate_schemes()
			scheme_variant_changed.emit(int(scheme_variant))
			theme_changed.emit()

@export_range(-3, 0, 1) var visual_density: int = 0:
	set(value):
		var d: int = clampi(value, -3, 0)
		if visual_density != d:
			visual_density = d
			density_changed.emit(visual_density)
			theme_changed.emit()

var color_scheme: M3ColorScheme
var light_scheme: M3ColorScheme
var dark_scheme: M3ColorScheme
var default_theme: Theme = null

func _init() -> void:
	if _instance == null:
		_instance = self
	if light_scheme == null or dark_scheme == null:
		regenerate_schemes()
	_build_default_theme()

func _enter_tree() -> void:
	if _instance == null:
		_instance = self
	if light_scheme == null or dark_scheme == null:
		regenerate_schemes()
	_build_default_theme()

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

func _ready() -> void:
	if light_scheme == null or dark_scheme == null:
		regenerate_schemes()

## Static instance accessor
static func get_instance() -> M3ThemeSingleton:
	if _instance == null:
		_instance = M3ThemeSingleton.new()
	return _instance

## Static helper to get currently active scheme
static func get_scheme() -> M3ColorScheme:
	return get_instance().get_current_scheme()

## Static helper to check if dark mode is active
static func is_dark() -> bool:
	var inst := get_instance()
	return inst.is_dark_mode if inst != null else false

## Regenerates both light and dark color schemes from the current seed_color, contrast_level, and scheme_variant.
func regenerate_schemes() -> void:
	light_scheme = M3PaletteGenerator.generate_scheme_from_seed(seed_color, false, contrast_level, scheme_variant)
	dark_scheme = M3PaletteGenerator.generate_scheme_from_seed(seed_color, true, contrast_level, scheme_variant)
	_update_active_scheme()

func set_contrast_level(level: float) -> void:
	self.contrast_level = level

func set_scheme_variant(v: M3PaletteGenerator.SchemeVariant) -> void:
	self.scheme_variant = v

func set_visual_density(d: int) -> void:
	self.visual_density = d

## Returns the M3 height delta in dp for the current visual_density (0 -> 0dp, -1 -> -4dp, -2 -> -8dp, -3 -> -12dp).
func get_density_offset() -> float:
	return float(clampi(visual_density, -3, 0)) * 4.0

## Harmonizes a custom semantic/brand color toward the active seed_color hue.
func harmonize_color(design_color: Color, max_hue_shift: float = 15.0) -> Color:
	return M3PaletteGenerator.harmonize_color(design_color, seed_color, max_hue_shift)

func _update_active_scheme() -> void:
	if is_dark_mode:
		color_scheme = dark_scheme
	else:
		color_scheme = light_scheme

## Updates seed color and regenerates theme schemes.
func set_seed_color(new_seed: Color) -> void:
	self.seed_color = new_seed

## Sets dark mode state (true = dark, false = light).
func set_dark_mode(dark: bool) -> void:
	self.is_dark_mode = dark

## Toggles between light and dark modes.
func toggle_dark_mode() -> void:
	self.is_dark_mode = not is_dark_mode

## Returns a color by M3 token name or role from the currently active color scheme.
func get_color(token: Variant) -> Color:
	if color_scheme == null:
		regenerate_schemes()
	return color_scheme.get_color(token)

## Returns the currently active M3ColorScheme (Light or Dark).
func get_current_scheme() -> M3ColorScheme:
	if color_scheme == null:
		regenerate_schemes()
	return color_scheme

## Returns the generated Light M3ColorScheme.
func get_light_scheme() -> M3ColorScheme:
	if light_scheme == null:
		regenerate_schemes()
	return light_scheme

## Returns the generated Dark M3ColorScheme.
func get_dark_scheme() -> M3ColorScheme:
	if dark_scheme == null:
		regenerate_schemes()
	return dark_scheme

## Explicitly applies a custom scheme as the active scheme.
func apply_custom_scheme(scheme: M3ColorScheme) -> void:
	if scheme != null:
		if scheme.is_dark:
			dark_scheme = scheme
		else:
			light_scheme = scheme
		set_block_signals(true)
		is_dark_mode = scheme.is_dark
		set_block_signals(false)
		color_scheme = scheme
		theme_changed.emit()

## Builds the default Dark Obsidian Glass Theme for Material 3 UI controls.
func _build_default_theme() -> Theme:
	var theme := Theme.new()
	var bg_obsidian := Color("#0F131C", 0.85)
	var glass_border := Color(0.0, 0.8235, 1.0, 0.35)
	var text_primary := Color("#FFFFFF")
	var text_secondary := Color("#E2E8F0")
	var text_muted := Color("#94A3B8")

	# Panel / PanelContainer glass stylebox
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = bg_obsidian
	panel_sb.border_color = glass_border
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(12)
	panel_sb.content_margin_left = 12.0
	panel_sb.content_margin_top = 8.0
	panel_sb.content_margin_right = 12.0
	panel_sb.content_margin_bottom = 8.0
	theme.set_stylebox(&"panel", &"Panel", panel_sb)
	theme.set_stylebox(&"panel", &"PanelContainer", panel_sb)

	# Label styling
	theme.set_color(&"font_color", &"Label", text_primary)
	theme.set_color(&"font_shadow_color", &"Label", Color(0.0, 0.0, 0.0, 0.6))
	theme.set_constant(&"shadow_offset_x", &"Label", 1)
	theme.set_constant(&"shadow_offset_y", &"Label", 1)

	# Button styling
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color("#161D2B", 0.80)
	btn_normal.border_color = glass_border
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(8)
	btn_normal.content_margin_left = 12.0
	btn_normal.content_margin_right = 12.0
	btn_normal.content_margin_top = 6.0
	btn_normal.content_margin_bottom = 6.0

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color("#1E293B", 0.90)
	btn_hover.border_color = Color(0.0, 0.9, 1.0, 0.6)

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color("#0A0D14", 0.95)
	btn_pressed.border_color = Color(0.0, 1.0, 1.0, 0.8)

	var btn_disabled := btn_normal.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = Color("#0F131C", 0.40)
	btn_disabled.border_color = Color(0.0, 0.8235, 1.0, 0.15)

	theme.set_stylebox(&"normal", &"Button", btn_normal)
	theme.set_stylebox(&"hover", &"Button", btn_hover)
	theme.set_stylebox(&"pressed", &"Button", btn_pressed)
	theme.set_stylebox(&"disabled", &"Button", btn_disabled)
	theme.set_color(&"font_color", &"Button", text_primary)
	theme.set_color(&"font_hover_color", &"Button", text_primary)
	theme.set_color(&"font_pressed_color", &"Button", text_secondary)
	theme.set_color(&"font_disabled_color", &"Button", text_muted)

	default_theme = theme
	return theme

## Returns the cached default theme.
func get_default_theme() -> Theme:
	if default_theme == null:
		return _build_default_theme()
	return default_theme
