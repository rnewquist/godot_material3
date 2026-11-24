class_name M3PaletteGenerator
extends Object

## Generates Material Design 3 6-tonal palettes and complete Light/Dark 34+ token ColorSchemes.

const PRESET_BASELINE_INDIGO: Color = Color(0.404, 0.314, 0.643, 1.0) # #6750A4
const PRESET_TEAL: Color = Color(0.0, 0.416, 0.376, 1.0)           # #006A60
const PRESET_TERRACOTTA: Color = Color(0.596, 0.251, 0.380, 1.0)     # #984061
const PRESET_EMERALD: Color = Color(0.180, 0.416, 0.220, 1.0)       # #2E6A38
const PRESET_AMBER: Color = Color(0.478, 0.349, 0.0, 1.0)           # #7A5900
const PRESET_CORAL: Color = Color(0.702, 0.149, 0.118, 1.0)         # #B3261E

# Standard tone stops used in M3
const STANDARD_TONES: Array[int] = [
	0, 4, 6, 10, 12, 17, 20, 22, 24, 30, 40, 50, 60, 70, 80, 87, 90, 92, 94, 95, 96, 98, 99, 100
]

## The 9 official Material 3 Dynamic Color scheme generation algorithms.
enum SchemeVariant {
	TONAL_SPOT,
	VIBRANT,
	EXPRESSIVE,
	MONOCHROME,
	NEUTRAL,
	FIDELITY,
	CONTENT,
	RAINBOW,
	FRUIT_SALAD,
}

## Contrast level constants (M3 Dynamic Color accessibility system).
const CONTRAST_STANDARD: float = 0.0
const CONTRAST_MEDIUM: float = 0.5
const CONTRAST_HIGH: float = 1.0

## Parameters defining the 6 tonal palettes derived from a seed color.
class PaletteSpec:
	var primary_hue: float
	var primary_chroma: float
	var secondary_hue: float
	var secondary_chroma: float
	var tertiary_hue: float
	var tertiary_chroma: float
	var neutral_hue: float
	var neutral_chroma: float
	var neutral_variant_hue: float
	var neutral_variant_chroma: float
	var error_hue: float = 25.0
	var error_chroma: float = 0.22

## Computes the PaletteSpec from any seed color in OKLCH space for the given M3 SchemeVariant.
static func create_palette_spec(seed_color: Color, variant: SchemeVariant = SchemeVariant.TONAL_SPOT) -> PaletteSpec:
	var lch: Vector3 = M3Math.color_to_oklch(seed_color)
	var seed_hue: float = lch.z
	var seed_chroma: float = lch.y

	var spec: PaletteSpec = PaletteSpec.new()
	spec.error_hue = 25.0
	spec.error_chroma = 0.22

	match variant:
		SchemeVariant.VIBRANT:
			spec.primary_hue = seed_hue
			spec.primary_chroma = maxf(seed_chroma, 0.24)
			spec.secondary_hue = fposmod(seed_hue + 24.0, 360.0)
			spec.secondary_chroma = 0.08
			spec.tertiary_hue = fposmod(seed_hue + 48.0, 360.0)
			spec.tertiary_chroma = 0.11
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = 0.025
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = 0.045
		SchemeVariant.EXPRESSIVE:
			spec.primary_hue = fposmod(seed_hue + 240.0, 360.0)
			spec.primary_chroma = 0.14
			spec.secondary_hue = fposmod(seed_hue + 45.0, 360.0)
			spec.secondary_chroma = 0.12
			spec.tertiary_hue = fposmod(seed_hue + 120.0, 360.0)
			spec.tertiary_chroma = 0.11
			spec.neutral_hue = fposmod(seed_hue + 15.0, 360.0)
			spec.neutral_chroma = 0.022
			spec.neutral_variant_hue = fposmod(seed_hue + 15.0, 360.0)
			spec.neutral_variant_chroma = 0.045
		SchemeVariant.MONOCHROME:
			spec.primary_hue = seed_hue
			spec.primary_chroma = 0.0
			spec.secondary_hue = seed_hue
			spec.secondary_chroma = 0.0
			spec.tertiary_hue = seed_hue
			spec.tertiary_chroma = 0.0
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = 0.0
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = 0.0
		SchemeVariant.NEUTRAL:
			spec.primary_hue = seed_hue
			spec.primary_chroma = 0.03
			spec.secondary_hue = seed_hue
			spec.secondary_chroma = 0.02
			spec.tertiary_hue = seed_hue
			spec.tertiary_chroma = 0.04
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = 0.008
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = 0.015
		SchemeVariant.FIDELITY:
			spec.primary_hue = seed_hue
			spec.primary_chroma = maxf(seed_chroma, 0.08)
			spec.secondary_hue = seed_hue
			spec.secondary_chroma = maxf(seed_chroma * 0.45, 0.04)
			spec.tertiary_hue = fposmod(360.0 - seed_hue, 360.0)
			spec.tertiary_chroma = maxf(seed_chroma * 0.65, 0.06)
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = seed_chroma * 0.08
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = seed_chroma * 0.16
		SchemeVariant.CONTENT:
			spec.primary_hue = seed_hue
			spec.primary_chroma = maxf(seed_chroma, 0.08)
			spec.secondary_hue = seed_hue
			spec.secondary_chroma = maxf(seed_chroma * 0.33, 0.03)
			spec.tertiary_hue = fposmod(seed_hue + 35.0, 360.0)
			spec.tertiary_chroma = maxf(seed_chroma * 0.66, 0.06)
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = seed_chroma * 0.06
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = seed_chroma * 0.12
		SchemeVariant.RAINBOW:
			spec.primary_hue = seed_hue
			spec.primary_chroma = 0.16
			spec.secondary_hue = seed_hue
			spec.secondary_chroma = 0.06
			spec.tertiary_hue = fposmod(seed_hue + 60.0, 360.0)
			spec.tertiary_chroma = 0.09
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = 0.0
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = 0.0
		SchemeVariant.FRUIT_SALAD:
			spec.primary_hue = fposmod(seed_hue - 50.0, 360.0)
			spec.primary_chroma = 0.16
			spec.secondary_hue = fposmod(seed_hue - 50.0, 360.0)
			spec.secondary_chroma = 0.11
			spec.tertiary_hue = seed_hue
			spec.tertiary_chroma = 0.14
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = 0.025
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = 0.045
		_: # TONAL_SPOT (M3 Baseline default)
			spec.primary_hue = seed_hue
			spec.primary_chroma = maxf(seed_chroma, 0.12)
			spec.secondary_hue = seed_hue
			spec.secondary_chroma = maxf(seed_chroma * 0.35, 0.05)
			spec.tertiary_hue = fposmod(seed_hue + 60.0, 360.0)
			spec.tertiary_chroma = maxf(seed_chroma * 0.55, 0.08)
			spec.neutral_hue = seed_hue
			spec.neutral_chroma = 0.015
			spec.neutral_variant_hue = seed_hue
			spec.neutral_variant_chroma = 0.035

	return spec

## Generates a single tone for a specified palette channel.
static func get_palette_tone(spec: PaletteSpec, channel: StringName, tone: float) -> Color:
	match channel:
		&"primary":
			return M3Math.tone_to_color(spec.primary_hue, spec.primary_chroma, tone)
		&"secondary":
			return M3Math.tone_to_color(spec.secondary_hue, spec.secondary_chroma, tone)
		&"tertiary":
			return M3Math.tone_to_color(spec.tertiary_hue, spec.tertiary_chroma, tone)
		&"neutral":
			return M3Math.tone_to_color(spec.neutral_hue, spec.neutral_chroma, tone)
		&"neutral_variant":
			return M3Math.tone_to_color(spec.neutral_variant_hue, spec.neutral_variant_chroma, tone)
		&"error":
			return M3Math.tone_to_color(spec.error_hue, spec.error_chroma, tone)
		_:
			return Color.MAGENTA

## Generates the entire 6-tonal palette dictionary for the given seed color.
static func get_tonal_palettes(seed_color: Color) -> Dictionary:
	var spec: PaletteSpec = create_palette_spec(seed_color)
	var channels: Array[StringName] = [&"primary", &"secondary", &"tertiary", &"neutral", &"neutral_variant", &"error"]
	var result: Dictionary = {}

	for ch: StringName in channels:
		var tone_map: Dictionary = {}
		for t: int in STANDARD_TONES:
			tone_map[t] = get_palette_tone(spec, ch, float(t))
		result[ch] = tone_map

	return result

## Generates a complete 49-token M3ColorScheme for the given seed color, dark mode, contrast level, and scheme variant.
static func generate_scheme_from_seed(
	seed_color: Color,
	is_dark: bool = false,
	contrast_level: float = 0.0,
	variant: SchemeVariant = SchemeVariant.TONAL_SPOT
) -> M3ColorScheme:
	var spec: PaletteSpec = create_palette_spec(seed_color, variant)
	var scheme: M3ColorScheme = M3ColorScheme.new()
	scheme.is_dark = is_dark
	var cl: float = clampf(contrast_level, -1.0, 1.0)
	var boost: float = maxf(0.0, cl)

	if not is_dark:
		# --- LIGHT THEME (M3 Spec + Contrast Level adjustment) ---
		var accent_t: float = lerpf(40.0, 20.0, boost)
		var container_t: float = lerpf(90.0, 95.0, boost)
		var on_container_t: float = lerpf(10.0, 0.0, boost)
		var on_surf_var_t: float = lerpf(30.0, 14.0, boost)
		var outline_t: float = lerpf(50.0, 24.0, boost)
		var outline_var_t: float = lerpf(80.0, 50.0, boost)

		scheme.primary = get_palette_tone(spec, &"primary", accent_t)
		scheme.on_primary = get_palette_tone(spec, &"primary", 100.0)
		scheme.primary_container = get_palette_tone(spec, &"primary", container_t)
		scheme.on_primary_container = get_palette_tone(spec, &"primary", on_container_t)
		scheme.inverse_primary = get_palette_tone(spec, &"primary", 80.0)

		scheme.secondary = get_palette_tone(spec, &"secondary", accent_t)
		scheme.on_secondary = get_palette_tone(spec, &"secondary", 100.0)
		scheme.secondary_container = get_palette_tone(spec, &"secondary", container_t)
		scheme.on_secondary_container = get_palette_tone(spec, &"secondary", on_container_t)

		scheme.tertiary = get_palette_tone(spec, &"tertiary", accent_t)
		scheme.on_tertiary = get_palette_tone(spec, &"tertiary", 100.0)
		scheme.tertiary_container = get_palette_tone(spec, &"tertiary", container_t)
		scheme.on_tertiary_container = get_palette_tone(spec, &"tertiary", on_container_t)

		scheme.error = get_palette_tone(spec, &"error", accent_t)
		scheme.on_error = get_palette_tone(spec, &"error", 100.0)
		scheme.error_container = get_palette_tone(spec, &"error", container_t)
		scheme.on_error_container = get_palette_tone(spec, &"error", on_container_t)

		scheme.background = get_palette_tone(spec, &"neutral", 98.0)
		scheme.on_background = get_palette_tone(spec, &"neutral", lerpf(10.0, 0.0, boost))

		scheme.surface = get_palette_tone(spec, &"neutral", 98.0)
		scheme.on_surface = get_palette_tone(spec, &"neutral", lerpf(10.0, 0.0, boost))
		scheme.surface_variant = get_palette_tone(spec, &"neutral_variant", 90.0)
		scheme.on_surface_variant = get_palette_tone(spec, &"neutral_variant", on_surf_var_t)

		scheme.surface_dim = get_palette_tone(spec, &"neutral", 87.0)
		scheme.surface_bright = get_palette_tone(spec, &"neutral", 98.0)
		scheme.surface_container_lowest = get_palette_tone(spec, &"neutral", 100.0)
		scheme.surface_container_low = get_palette_tone(spec, &"neutral", 96.0)
		scheme.surface_container = get_palette_tone(spec, &"neutral", 94.0)
		scheme.surface_container_high = get_palette_tone(spec, &"neutral", 92.0)
		scheme.surface_container_highest = get_palette_tone(spec, &"neutral", 90.0)

		scheme.inverse_surface = get_palette_tone(spec, &"neutral", 20.0)
		scheme.inverse_on_surface = get_palette_tone(spec, &"neutral", 95.0)

		scheme.outline = get_palette_tone(spec, &"neutral_variant", outline_t)
		scheme.outline_variant = get_palette_tone(spec, &"neutral_variant", outline_var_t)

		scheme.scrim = Color(0.0, 0.0, 0.0, 1.0)
		scheme.shadow = Color(0.0, 0.0, 0.0, 1.0)
		scheme.surface_tint = scheme.primary
	else:
		# --- DARK THEME (M3 Spec + Contrast Level adjustment) ---
		var accent_t: float = lerpf(80.0, 95.0, boost)
		var on_accent_t: float = lerpf(20.0, 0.0, boost)
		var container_t: float = lerpf(30.0, 20.0, boost)
		var on_container_t: float = lerpf(90.0, 100.0, boost)
		var on_surf_var_t: float = lerpf(80.0, 96.0, boost)
		var outline_t: float = lerpf(60.0, 86.0, boost)
		var outline_var_t: float = lerpf(30.0, 56.0, boost)

		scheme.primary = get_palette_tone(spec, &"primary", accent_t)
		scheme.on_primary = get_palette_tone(spec, &"primary", on_accent_t)
		scheme.primary_container = get_palette_tone(spec, &"primary", container_t)
		scheme.on_primary_container = get_palette_tone(spec, &"primary", on_container_t)
		scheme.inverse_primary = get_palette_tone(spec, &"primary", 40.0)

		scheme.secondary = get_palette_tone(spec, &"secondary", accent_t)
		scheme.on_secondary = get_palette_tone(spec, &"secondary", on_accent_t)
		scheme.secondary_container = get_palette_tone(spec, &"secondary", container_t)
		scheme.on_secondary_container = get_palette_tone(spec, &"secondary", on_container_t)

		scheme.tertiary = get_palette_tone(spec, &"tertiary", accent_t)
		scheme.on_tertiary = get_palette_tone(spec, &"tertiary", on_accent_t)
		scheme.tertiary_container = get_palette_tone(spec, &"tertiary", container_t)
		scheme.on_tertiary_container = get_palette_tone(spec, &"tertiary", on_container_t)

		scheme.error = get_palette_tone(spec, &"error", accent_t)
		scheme.on_error = get_palette_tone(spec, &"error", on_accent_t)
		scheme.error_container = get_palette_tone(spec, &"error", container_t)
		scheme.on_error_container = get_palette_tone(spec, &"error", on_container_t)

		scheme.background = get_palette_tone(spec, &"neutral", 6.0)
		scheme.on_background = get_palette_tone(spec, &"neutral", lerpf(90.0, 100.0, boost))

		scheme.surface = get_palette_tone(spec, &"neutral", 6.0)
		scheme.on_surface = get_palette_tone(spec, &"neutral", lerpf(90.0, 100.0, boost))
		scheme.surface_variant = get_palette_tone(spec, &"neutral_variant", 30.0)
		scheme.on_surface_variant = get_palette_tone(spec, &"neutral_variant", on_surf_var_t)

		scheme.surface_dim = get_palette_tone(spec, &"neutral", 6.0)
		scheme.surface_bright = get_palette_tone(spec, &"neutral", 24.0)
		scheme.surface_container_lowest = get_palette_tone(spec, &"neutral", 4.0)
		scheme.surface_container_low = get_palette_tone(spec, &"neutral", 10.0)
		scheme.surface_container = get_palette_tone(spec, &"neutral", 12.0)
		scheme.surface_container_high = get_palette_tone(spec, &"neutral", 17.0)
		scheme.surface_container_highest = get_palette_tone(spec, &"neutral", 22.0)

		scheme.inverse_surface = get_palette_tone(spec, &"neutral", 90.0)
		scheme.inverse_on_surface = get_palette_tone(spec, &"neutral", 20.0)

		scheme.outline = get_palette_tone(spec, &"neutral_variant", outline_t)
		scheme.outline_variant = get_palette_tone(spec, &"neutral_variant", outline_var_t)

		scheme.scrim = Color(0.0, 0.0, 0.0, 1.0)
		scheme.shadow = Color(0.0, 0.0, 0.0, 1.0)
		scheme.surface_tint = scheme.primary

	# Fixed Accent Roles (identical across Light & Dark themes per M3 Spec)
	scheme.primary_fixed = get_palette_tone(spec, &"primary", 90.0)
	scheme.primary_fixed_dim = get_palette_tone(spec, &"primary", 80.0)
	scheme.on_primary_fixed = get_palette_tone(spec, &"primary", 10.0)
	scheme.on_primary_fixed_variant = get_palette_tone(spec, &"primary", 30.0)

	scheme.secondary_fixed = get_palette_tone(spec, &"secondary", 90.0)
	scheme.secondary_fixed_dim = get_palette_tone(spec, &"secondary", 80.0)
	scheme.on_secondary_fixed = get_palette_tone(spec, &"secondary", 10.0)
	scheme.on_secondary_fixed_variant = get_palette_tone(spec, &"secondary", 30.0)

	scheme.tertiary_fixed = get_palette_tone(spec, &"tertiary", 90.0)
	scheme.tertiary_fixed_dim = get_palette_tone(spec, &"tertiary", 80.0)
	scheme.on_tertiary_fixed = get_palette_tone(spec, &"tertiary", 10.0)
	scheme.on_tertiary_fixed_variant = get_palette_tone(spec, &"tertiary", 30.0)

	return scheme

## Pre-baked standard schemes
static func baseline_indigo_scheme(is_dark: bool = false) -> M3ColorScheme:
	return generate_scheme_from_seed(PRESET_BASELINE_INDIGO, is_dark)

static func teal_scheme(is_dark: bool = false) -> M3ColorScheme:
	return generate_scheme_from_seed(PRESET_TEAL, is_dark)

static func terracotta_scheme(is_dark: bool = false) -> M3ColorScheme:
	return generate_scheme_from_seed(PRESET_TERRACOTTA, is_dark)

static func emerald_scheme(is_dark: bool = false) -> M3ColorScheme:
	return generate_scheme_from_seed(PRESET_EMERALD, is_dark)

static func amber_scheme(is_dark: bool = false) -> M3ColorScheme:
	return generate_scheme_from_seed(PRESET_AMBER, is_dark)

static func coral_scheme(is_dark: bool = false) -> M3ColorScheme:
	return generate_scheme_from_seed(PRESET_CORAL, is_dark)

## M3 Color Harmonization (Blend.harmonize):
## Shifts the hue of `design_color` toward `source_seed` by up to `max_hue_shift` degrees (default 15 deg)
## while preserving the original CIELAB L* tone and OKLCH chroma of `design_color`.
static func harmonize_color(design_color: Color, source_seed: Color, max_hue_shift: float = 15.0) -> Color:
	var design_lch: Vector3 = M3Math.color_to_oklch(design_color)
	var seed_lch: Vector3 = M3Math.color_to_oklch(source_seed)
	var tone: float = M3Math.color_to_lstar(design_color)
	# Shortest signed angular difference from design hue to seed hue in [-180, 180]
	var diff: float = fposmod(seed_lch.z - design_lch.z + 540.0, 360.0) - 180.0
	var shift: float = clampf(diff * 0.5, -max_hue_shift, max_hue_shift)
	var new_hue: float = fposmod(design_lch.z + shift, 360.0)
	var out: Color = M3Math.tone_to_color(new_hue, design_lch.y, tone)
	out.a = design_color.a
	return out
