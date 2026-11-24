class_name M3ColorScheme
extends Resource

## Holds the 34+ semantic color tokens for a Material Design 3 theme (Light or Dark).

@export var is_dark: bool = false

# Primary Palette
@export var primary: Color = Color(0.404, 0.314, 0.643, 1.0)
@export var on_primary: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var primary_container: Color = Color(0.914, 0.886, 1.0, 1.0)
@export var on_primary_container: Color = Color(0.133, 0.0, 0.325, 1.0)
@export var inverse_primary: Color = Color(0.812, 0.749, 1.0, 1.0)

# Secondary Palette
@export var secondary: Color = Color(0.384, 0.357, 0.443, 1.0)
@export var on_secondary: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var secondary_container: Color = Color(0.906, 0.871, 0.969, 1.0)
@export var on_secondary_container: Color = Color(0.118, 0.094, 0.176, 1.0)

# Tertiary Palette
@export var tertiary: Color = Color(0.494, 0.322, 0.384, 1.0)
@export var on_tertiary: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var tertiary_container: Color = Color(1.0, 0.847, 0.902, 1.0)
@export var on_tertiary_container: Color = Color(0.196, 0.043, 0.114, 1.0)

# Error Palette
@export var error: Color = Color(0.702, 0.149, 0.118, 1.0)
@export var on_error: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var error_container: Color = Color(1.0, 0.855, 0.839, 1.0)
@export var on_error_container: Color = Color(0.255, 0.0, 0.012, 1.0)

# Surface & Background Palette
@export var background: Color = Color(0.996, 0.984, 1.0, 1.0)
@export var on_background: Color = Color(0.114, 0.106, 0.129, 1.0)
@export var surface: Color = Color(0.996, 0.984, 1.0, 1.0)
@export var on_surface: Color = Color(0.114, 0.106, 0.129, 1.0)
@export var surface_variant: Color = Color(0.902, 0.882, 0.941, 1.0)
@export var on_surface_variant: Color = Color(0.286, 0.271, 0.318, 1.0)

# Surface Containers (M3 spec)
@export var surface_dim: Color = Color(0.871, 0.855, 0.890, 1.0)
@export var surface_bright: Color = Color(0.996, 0.984, 1.0, 1.0)
@export var surface_container_lowest: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var surface_container_low: Color = Color(0.965, 0.949, 0.988, 1.0)
@export var surface_container: Color = Color(0.949, 0.929, 0.973, 1.0)
@export var surface_container_high: Color = Color(0.933, 0.914, 0.957, 1.0)
@export var surface_container_highest: Color = Color(0.918, 0.894, 0.941, 1.0)

# Inverse Surface
@export var inverse_surface: Color = Color(0.196, 0.184, 0.212, 1.0)
@export var inverse_on_surface: Color = Color(0.961, 0.937, 0.976, 1.0)

# Outline & Elevation / Extras
@export var outline: Color = Color(0.478, 0.459, 0.510, 1.0)
@export var outline_variant: Color = Color(0.796, 0.773, 0.831, 1.0)
@export var scrim: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var shadow: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var surface_tint: Color = Color(0.404, 0.314, 0.643, 1.0)

# Fixed Accent Roles (identical across Light & Dark themes per M3 Spec)
@export var primary_fixed: Color = Color(0.914, 0.886, 1.0, 1.0)
@export var primary_fixed_dim: Color = Color(0.812, 0.749, 1.0, 1.0)
@export var on_primary_fixed: Color = Color(0.133, 0.0, 0.325, 1.0)
@export var on_primary_fixed_variant: Color = Color(0.310, 0.216, 0.545, 1.0)
@export var secondary_fixed: Color = Color(0.906, 0.871, 0.969, 1.0)
@export var secondary_fixed_dim: Color = Color(0.796, 0.761, 0.859, 1.0)
@export var on_secondary_fixed: Color = Color(0.118, 0.094, 0.176, 1.0)
@export var on_secondary_fixed_variant: Color = Color(0.290, 0.267, 0.345, 1.0)
@export var tertiary_fixed: Color = Color(1.0, 0.847, 0.902, 1.0)
@export var tertiary_fixed_dim: Color = Color(0.937, 0.722, 0.784, 1.0)
@export var on_tertiary_fixed: Color = Color(0.196, 0.043, 0.114, 1.0)
@export var on_tertiary_fixed_variant: Color = Color(0.388, 0.231, 0.286, 1.0)

# State Layer Alphas
const STATE_HOVER_OPACITY: float = 0.08
const STATE_FOCUS_OPACITY: float = 0.12
const STATE_PRESSED_OPACITY: float = 0.12
const STATE_DRAGGED_OPACITY: float = 0.16
const STATE_DISABLED_CONTAINER_OPACITY: float = 0.12
const STATE_DISABLED_CONTENT_OPACITY: float = 0.38

## Factory helper to generate a scheme from a seed color.
static func from_seed(seed_color: Color, dark: bool = false) -> M3ColorScheme:
	return M3PaletteGenerator.generate_scheme_from_seed(seed_color, dark)

func get_color(token: Variant) -> Color:
	var role_name: StringName = &""
	if token is M3Color.Role:
		role_name = M3Color.role_to_name(token)
	elif token is StringName:
		role_name = token
	elif token is String:
		role_name = StringName(token)
	
	match role_name:
		M3Color.PRIMARY: return primary
		M3Color.ON_PRIMARY: return on_primary
		M3Color.PRIMARY_CONTAINER: return primary_container
		M3Color.ON_PRIMARY_CONTAINER: return on_primary_container
		M3Color.INVERSE_PRIMARY: return inverse_primary
		M3Color.SECONDARY: return secondary
		M3Color.ON_SECONDARY: return on_secondary
		M3Color.SECONDARY_CONTAINER: secondary_container = secondary_container; return secondary_container
		M3Color.ON_SECONDARY_CONTAINER: return on_secondary_container
		M3Color.TERTIARY: return tertiary
		M3Color.ON_TERTIARY: return on_tertiary
		M3Color.TERTIARY_CONTAINER: return tertiary_container
		M3Color.ON_TERTIARY_CONTAINER: return on_tertiary_container
		M3Color.ERROR: return error
		M3Color.ON_ERROR: return on_error
		M3Color.ERROR_CONTAINER: return error_container
		M3Color.ON_ERROR_CONTAINER: return on_error_container
		M3Color.BACKGROUND: return background
		M3Color.ON_BACKGROUND: return on_background
		M3Color.SURFACE: return surface
		M3Color.ON_SURFACE: return on_surface
		M3Color.SURFACE_VARIANT: return surface_variant
		M3Color.ON_SURFACE_VARIANT: return on_surface_variant
		M3Color.SURFACE_DIM: return surface_dim
		M3Color.SURFACE_BRIGHT: return surface_bright
		M3Color.SURFACE_CONTAINER_LOWEST: return surface_container_lowest
		M3Color.SURFACE_CONTAINER_LOW: return surface_container_low
		M3Color.SURFACE_CONTAINER: return surface_container
		M3Color.SURFACE_CONTAINER_HIGH: return surface_container_high
		M3Color.SURFACE_CONTAINER_HIGHEST: return surface_container_highest
		M3Color.INVERSE_SURFACE: return inverse_surface
		M3Color.INVERSE_ON_SURFACE: return inverse_on_surface
		M3Color.OUTLINE: return outline
		M3Color.OUTLINE_VARIANT: return outline_variant
		M3Color.SCRIM: return scrim
		M3Color.SHADOW: return shadow
		M3Color.SURFACE_TINT: return surface_tint
		M3Color.PRIMARY_FIXED: return primary_fixed
		M3Color.PRIMARY_FIXED_DIM: return primary_fixed_dim
		M3Color.ON_PRIMARY_FIXED: return on_primary_fixed
		M3Color.ON_PRIMARY_FIXED_VARIANT: return on_primary_fixed_variant
		M3Color.SECONDARY_FIXED: return secondary_fixed
		M3Color.SECONDARY_FIXED_DIM: return secondary_fixed_dim
		M3Color.ON_SECONDARY_FIXED: return on_secondary_fixed
		M3Color.ON_SECONDARY_FIXED_VARIANT: return on_secondary_fixed_variant
		M3Color.TERTIARY_FIXED: return tertiary_fixed
		M3Color.TERTIARY_FIXED_DIM: return tertiary_fixed_dim
		M3Color.ON_TERTIARY_FIXED: return on_tertiary_fixed
		M3Color.ON_TERTIARY_FIXED_VARIANT: return on_tertiary_fixed_variant
		_:
			push_warning("Unknown M3 Color token: %s" % str(token))
			return Color.MAGENTA

func set_color(token: Variant, color: Color) -> void:
	var role_name: StringName = &""
	if token is M3Color.Role:
		role_name = M3Color.role_to_name(token)
	elif token is StringName:
		role_name = token
	elif token is String:
		role_name = StringName(token)

	match role_name:
		M3Color.PRIMARY: primary = color
		M3Color.ON_PRIMARY: on_primary = color
		M3Color.PRIMARY_CONTAINER: primary_container = color
		M3Color.ON_PRIMARY_CONTAINER: on_primary_container = color
		M3Color.INVERSE_PRIMARY: inverse_primary = color
		M3Color.SECONDARY: secondary = color
		M3Color.ON_SECONDARY: on_secondary = color
		M3Color.SECONDARY_CONTAINER: secondary_container = color
		M3Color.ON_SECONDARY_CONTAINER: on_secondary_container = color
		M3Color.TERTIARY: tertiary = color
		M3Color.ON_TERTIARY: on_tertiary = color
		M3Color.TERTIARY_CONTAINER: tertiary_container = color
		M3Color.ON_TERTIARY_CONTAINER: on_tertiary_container = color
		M3Color.ERROR: error = color
		M3Color.ON_ERROR: on_error = color
		M3Color.ERROR_CONTAINER: error_container = color
		M3Color.ON_ERROR_CONTAINER: on_error_container = color
		M3Color.BACKGROUND: background = color
		M3Color.ON_BACKGROUND: on_background = color
		M3Color.SURFACE: surface = color
		M3Color.ON_SURFACE: on_surface = color
		M3Color.SURFACE_VARIANT: surface_variant = color
		M3Color.ON_SURFACE_VARIANT: on_surface_variant = color
		M3Color.SURFACE_DIM: surface_dim = color
		M3Color.SURFACE_BRIGHT: surface_bright = color
		M3Color.SURFACE_CONTAINER_LOWEST: surface_container_lowest = color
		M3Color.SURFACE_CONTAINER_LOW: surface_container_low = color
		M3Color.SURFACE_CONTAINER: surface_container = color
		M3Color.SURFACE_CONTAINER_HIGH: surface_container_high = color
		M3Color.SURFACE_CONTAINER_HIGHEST: surface_container_highest = color
		M3Color.INVERSE_SURFACE: inverse_surface = color
		M3Color.INVERSE_ON_SURFACE: inverse_on_surface = color
		M3Color.OUTLINE: outline = color
		M3Color.OUTLINE_VARIANT: outline_variant = color
		M3Color.SCRIM: scrim = color
		M3Color.SHADOW: shadow = color
		M3Color.SURFACE_TINT: surface_tint = color
		M3Color.PRIMARY_FIXED: primary_fixed = color
		M3Color.PRIMARY_FIXED_DIM: primary_fixed_dim = color
		M3Color.ON_PRIMARY_FIXED: on_primary_fixed = color
		M3Color.ON_PRIMARY_FIXED_VARIANT: on_primary_fixed_variant = color
		M3Color.SECONDARY_FIXED: secondary_fixed = color
		M3Color.SECONDARY_FIXED_DIM: secondary_fixed_dim = color
		M3Color.ON_SECONDARY_FIXED: on_secondary_fixed = color
		M3Color.ON_SECONDARY_FIXED_VARIANT: on_secondary_fixed_variant = color
		M3Color.TERTIARY_FIXED: tertiary_fixed = color
		M3Color.TERTIARY_FIXED_DIM: tertiary_fixed_dim = color
		M3Color.ON_TERTIARY_FIXED: on_tertiary_fixed = color
		M3Color.ON_TERTIARY_FIXED_VARIANT: on_tertiary_fixed_variant = color
		_:
			push_warning("Unknown M3 Color token to set: %s" % str(token))

func duplicate_scheme() -> M3ColorScheme:
	var copy: M3ColorScheme = M3ColorScheme.new()
	copy.is_dark = is_dark
	for role: M3Color.Role in M3Color.ALL_ROLES:
		var token_name: StringName = M3Color.role_to_name(role)
		copy.set_color(token_name, get_color(token_name))
	return copy

func to_dictionary() -> Dictionary:
	var dict: Dictionary = {
		"is_dark": is_dark
	}
	for role: M3Color.Role in M3Color.ALL_ROLES:
		var token_name: StringName = M3Color.role_to_name(role)
		dict[String(token_name)] = get_color(token_name).to_html(true)
	return dict

static func from_dictionary(dict: Dictionary) -> M3ColorScheme:
	var scheme: M3ColorScheme = M3ColorScheme.new()
	scheme.is_dark = dict.get("is_dark", false)
	for role: M3Color.Role in M3Color.ALL_ROLES:
		var token_name: StringName = M3Color.role_to_name(role)
		var key: String = String(token_name)
		if dict.has(key):
			var val: Variant = dict[key]
			if val is Color:
				scheme.set_color(token_name, val)
			elif val is String:
				scheme.set_color(token_name, Color.from_string(val, Color.WHITE))
	return scheme
