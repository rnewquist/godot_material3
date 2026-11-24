class_name TestM3Palette
extends GDTestSuite

## Unit tests for M3 Color Math, OKLCH conversion, Tonal Palette Generation, and Contrast Ratios.

func test_oklch_roundtrip_conversions() -> void:
	var test_colors: Array[Color] = [
		Color(1.0, 0.0, 0.0), # Red
		Color(0.0, 1.0, 0.0), # Green
		Color(0.0, 0.0, 1.0), # Blue
		Color(0.404, 0.314, 0.643), # Indigo #6750A4
		Color(1.0, 1.0, 1.0), # White
		Color(0.0, 0.0, 0.0), # Black
		Color(0.5, 0.5, 0.5), # Gray
	]

	for original in test_colors:
		var lch: Vector3 = M3Math.color_to_oklch(original)
		var reconstructed: Color = M3Math.oklch_to_color(lch)
		assert_color_approx(reconstructed, original, 0.02, "OKLCH roundtrip mismatch for %s" % str(original))

func test_tone_gamut_clamping() -> void:
	# Tone 0 should always be pure black, Tone 100 pure white
	var black: Color = M3Math.tone_to_color(180.0, 0.3, 0.0)
	var white: Color = M3Math.tone_to_color(180.0, 0.3, 100.0)

	assert_color_approx(black, Color.BLACK, 0.001, "Tone 0 must be Black")
	assert_color_approx(white, Color.WHITE, 0.001, "Tone 100 must be White")

	# Intermediate tones must have R, G, B strictly within [0.0, 1.0]
	for t in range(0, 101, 10):
		var c: Color = M3Math.tone_to_color(270.0, 0.4, float(t))
		assert_gte(c.r, 0.0, "R >= 0 at tone %d" % t)
		assert_lte(c.r, 1.0, "R <= 1 at tone %d" % t)
		assert_gte(c.g, 0.0, "G >= 0 at tone %d" % t)
		assert_lte(c.g, 1.0, "G <= 1 at tone %d" % t)
		assert_gte(c.b, 0.0, "B >= 0 at tone %d" % t)
		assert_lte(c.b, 1.0, "B <= 1 at tone %d" % t)

func test_six_tonal_palettes_generated() -> void:
	var palettes: Dictionary = M3PaletteGenerator.get_tonal_palettes(M3PaletteGenerator.PRESET_BASELINE_INDIGO)
	var expected_channels: Array[StringName] = [&"primary", &"secondary", &"tertiary", &"neutral", &"neutral_variant", &"error"]

	for ch: StringName in expected_channels:
		assert_true(palettes.has(ch), "Tonal palettes must contain channel: %s" % str(ch))
		var tones: Dictionary = palettes[ch]
		assert_true(tones.has(40), "Channel %s must contain tone 40" % str(ch))
		assert_true(tones.has(80), "Channel %s must contain tone 80" % str(ch))
		assert_true(tones.has(90), "Channel %s must contain tone 90" % str(ch))
		assert_true(tones.has(10), "Channel %s must contain tone 10" % str(ch))

func test_light_scheme_all_roles() -> void:
	var scheme: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(false)
	assert_false(scheme.is_dark, "Scheme must be Light")

	for role in M3Color.get_all_roles():
		var token_name: StringName = M3Color.role_to_name(role)
		var c: Color = scheme.get_color(token_name)
		assert_not_null(c, "Token %s must not be null" % str(token_name))
		assert_ne(c, Color.MAGENTA, "Token %s must not evaluate to fallback MAGENTA" % str(token_name))

func test_dark_scheme_all_roles() -> void:
	var scheme: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(true)
	assert_true(scheme.is_dark, "Scheme must be Dark")

	for role in M3Color.get_all_roles():
		var token_name: StringName = M3Color.role_to_name(role)
		var c: Color = scheme.get_color(token_name)
		assert_not_null(c, "Token %s must not be null" % str(token_name))
		assert_ne(c, Color.MAGENTA, "Token %s must not evaluate to fallback MAGENTA" % str(token_name))

func test_preset_palettes_generation() -> void:
	var teal_light: M3ColorScheme = M3PaletteGenerator.teal_scheme(false)
	var terracotta_dark: M3ColorScheme = M3PaletteGenerator.terracotta_scheme(true)
	var emerald_light: M3ColorScheme = M3PaletteGenerator.emerald_scheme(false)
	var amber_dark: M3ColorScheme = M3PaletteGenerator.amber_scheme(true)
	var coral_light: M3ColorScheme = M3PaletteGenerator.coral_scheme(false)

	assert_false(teal_light.is_dark)
	assert_true(terracotta_dark.is_dark)
	assert_false(emerald_light.is_dark)
	assert_true(amber_dark.is_dark)
	assert_false(coral_light.is_dark)

func test_wcag_contrast_ratios() -> void:
	var light_scheme: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(false)
	var dark_scheme: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(true)

	# Light theme contrast checks (spec requires >= 4.5:1 for body/content contrast)
	var cr_primary_light: float = M3Math.contrast_ratio(light_scheme.on_primary, light_scheme.primary)
	var cr_surface_light: float = M3Math.contrast_ratio(light_scheme.on_surface, light_scheme.surface)
	var cr_error_light: float = M3Math.contrast_ratio(light_scheme.on_error, light_scheme.error)

	assert_gte(cr_primary_light, 4.5, "Light on_primary vs primary contrast must be >= 4.5:1 (was %.2f)" % cr_primary_light)
	assert_gte(cr_surface_light, 4.5, "Light on_surface vs surface contrast must be >= 4.5:1 (was %.2f)" % cr_surface_light)
	assert_gte(cr_error_light, 4.5, "Light on_error vs error contrast must be >= 4.5:1 (was %.2f)" % cr_error_light)

	# Dark theme contrast checks
	var cr_primary_dark: float = M3Math.contrast_ratio(dark_scheme.on_primary, dark_scheme.primary)
	var cr_surface_dark: float = M3Math.contrast_ratio(dark_scheme.on_surface, dark_scheme.surface)
	var cr_error_dark: float = M3Math.contrast_ratio(dark_scheme.on_error, dark_scheme.error)

	assert_gte(cr_primary_dark, 4.5, "Dark on_primary vs primary contrast must be >= 4.5:1 (was %.2f)" % cr_primary_dark)
	assert_gte(cr_surface_dark, 4.5, "Dark on_surface vs surface contrast must be >= 4.5:1 (was %.2f)" % cr_surface_dark)
	assert_gte(cr_error_dark, 4.5, "Dark on_error vs error contrast must be >= 4.5:1 (was %.2f)" % cr_error_dark)

func test_scheme_serialization() -> void:
	var scheme: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(false)
	var dict: Dictionary = scheme.to_dictionary()
	var reconstructed: M3ColorScheme = M3ColorScheme.from_dictionary(dict)

	assert_eq(reconstructed.is_dark, scheme.is_dark)
	assert_color_approx(reconstructed.primary, scheme.primary, 0.01)
	assert_color_approx(reconstructed.surface, scheme.surface, 0.01)
	assert_color_approx(reconstructed.error, scheme.error, 0.01)

func test_tone_is_cielab_lstar_across_hues() -> void:
	# M3 tones are CIELAB L*; generated colors must land on the requested tone (gamut-mapped).
	for hue in [0.0, 25.0, 90.0, 145.0, 210.0, 290.0]:
		for tone in [4.0, 6.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 80.0, 90.0, 95.0, 98.0]:
			var c: Color = M3Math.tone_to_color(hue, 0.12, tone)
			assert_approx(M3Math.color_to_lstar(c), tone, 0.5, "hue %.0f tone %.0f lands on L*" % [hue, tone])

func test_lstar_luminance_roundtrip() -> void:
	for l in [0.0, 1.0, 6.0, 40.0, 72.5, 100.0]:
		assert_approx(M3Math.y_to_lstar(M3Math.lstar_to_y(l)), l, 0.01, "L* %.1f roundtrip" % l)
	assert_approx(M3Math.lstar_to_y(50.0), 0.1842, 0.001, "L*50 -> Y 0.184")

func test_baseline_scheme_matches_m3_reference_tones() -> void:
	var light: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(false)
	var dark: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(true)
	# #6750A4 is itself tone ~40, so the light primary must stay close to the seed.
	assert_color_approx(light.primary, M3PaletteGenerator.PRESET_BASELINE_INDIGO, 0.05, "light primary ~ #6750A4")
	assert_approx(M3Math.color_to_lstar(dark.surface), 6.0, 0.5, "dark surface is tone 6 (~#141218), not black")
	assert_approx(M3Math.color_to_lstar(light.surface), 98.0, 0.5, "light surface is tone 98")
	assert_approx(M3Math.color_to_lstar(dark.primary), 80.0, 0.5, "dark primary is tone 80")
	assert_gt(dark.surface.r + dark.surface.g + dark.surface.b, 0.15, "dark surface visibly above black")

func test_role_pair_contrast_guarantees() -> void:
	for dark in [false, true]:
		var s: M3ColorScheme = M3PaletteGenerator.baseline_indigo_scheme(dark)
		var pairs: Array = [
			[s.on_primary_container, s.primary_container], [s.on_secondary, s.secondary],
			[s.on_secondary_container, s.secondary_container], [s.on_tertiary, s.tertiary],
			[s.on_tertiary_container, s.tertiary_container], [s.on_error_container, s.error_container],
			[s.on_surface_variant, s.surface], [s.inverse_on_surface, s.inverse_surface],
			[s.on_surface, s.surface_container_highest]]
		for p in pairs:
			assert_gte(M3Math.contrast_ratio(p[0], p[1]), 4.5, "content/container contrast >= 4.5 (dark=%s)" % str(dark))
		assert_gte(M3Math.contrast_ratio(s.outline, s.surface), 3.0, "outline vs surface >= 3:1 (dark=%s)" % str(dark))

func test_nine_scheme_variants_and_contrast_levels() -> void:
	for i in range(9):
		var v := i as M3PaletteGenerator.SchemeVariant
		var light_v := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 0.0, v)
		var dark_v := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, true, 0.0, v)
		assert_not_null(light_v)
		assert_not_null(dark_v)
		if v == M3PaletteGenerator.SchemeVariant.MONOCHROME:
			assert_approx(light_v.primary.r, light_v.primary.g, 0.01, "Monochrome primary is achromatic")
			assert_approx(light_v.primary.g, light_v.primary.b, 0.01, "Monochrome primary is achromatic")

	var std_s := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 0.0)
	var med_s := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 0.5)
	var high_s := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 1.0)
	assert_gt(M3Math.contrast_ratio(high_s.on_primary, high_s.primary), M3Math.contrast_ratio(med_s.on_primary, med_s.primary))
	assert_gt(M3Math.contrast_ratio(med_s.on_primary, med_s.primary), M3Math.contrast_ratio(std_s.on_primary, std_s.primary))

func test_color_harmonization() -> void:
	var orange := Color(0.95, 0.50, 0.05)
	var harmonized := M3PaletteGenerator.harmonize_color(orange, M3PaletteGenerator.PRESET_BASELINE_INDIGO, 15.0)
	assert_approx(M3Math.color_to_lstar(harmonized), M3Math.color_to_lstar(orange), 1.0, "Harmonization preserves L* tone")
	assert_ne(harmonized, orange, "Harmonization shifts hue toward seed")
