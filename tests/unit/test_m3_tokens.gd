class_name TestM3Tokens
extends GDTestSuite

## Unit tests for M3 Typography, Shapes, Elevation, and Motion tokens.

func test_typography_tokens() -> void:
	# Check all 15 font sizes
	assert_eq(M3Typography.get_font_size(M3Typography.Role.DISPLAY_LARGE), 57)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.DISPLAY_MEDIUM), 45)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.DISPLAY_SMALL), 36)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.HEADLINE_LARGE), 32)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.HEADLINE_MEDIUM), 28)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.HEADLINE_SMALL), 24)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.TITLE_LARGE), 22)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.TITLE_MEDIUM), 16)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.TITLE_SMALL), 14)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.BODY_LARGE), 16)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.BODY_MEDIUM), 14)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.BODY_SMALL), 12)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.LABEL_LARGE), 14)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.LABEL_MEDIUM), 12)
	assert_eq(M3Typography.get_font_size(M3Typography.Role.LABEL_SMALL), 11)

	# Check line heights
	assert_eq(M3Typography.get_line_height(M3Typography.Role.DISPLAY_LARGE), 64)
	assert_eq(M3Typography.get_line_height(M3Typography.Role.BODY_MEDIUM), 20)

	# Check label application
	var label: Label = autofree(Label.new()) as Label
	M3Typography.apply_to_label(label, M3Typography.Role.TITLE_LARGE, Color.WHITE)
	assert_eq(label.get_theme_font_size(&"font_size"), 22)

func test_shape_tokens() -> void:
	assert_eq(M3Shapes.NONE, 0)
	assert_eq(M3Shapes.EXTRA_SMALL, 4)
	assert_eq(M3Shapes.SMALL, 8)
	assert_eq(M3Shapes.MEDIUM, 12)
	assert_eq(M3Shapes.LARGE, 16)
	assert_eq(M3Shapes.EXTRA_LARGE, 28)
	assert_eq(M3Shapes.FULL, 9999)

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	M3Shapes.apply_to_stylebox(sb, M3Shapes.MEDIUM)
	assert_eq(sb.corner_radius_top_left, 12)
	assert_eq(sb.corner_radius_top_right, 12)
	assert_eq(sb.corner_radius_bottom_right, 12)
	assert_eq(sb.corner_radius_bottom_left, 12)

	var created: StyleBoxFlat = M3Shapes.create_stylebox(Color.RED, M3Shapes.LARGE, 2, Color.BLUE)
	assert_eq(created.bg_color, Color.RED)
	assert_eq(created.corner_radius_top_left, 16)
	assert_eq(created.border_width_left, 2)
	assert_eq(created.border_color, Color.BLUE)

func test_elevation_tokens() -> void:
	assert_approx(M3Elevation.get_tint_opacity(0), 0.00, 0.001)
	assert_approx(M3Elevation.get_tint_opacity(1), 0.05, 0.001)
	assert_approx(M3Elevation.get_tint_opacity(2), 0.08, 0.001)
	assert_approx(M3Elevation.get_tint_opacity(3), 0.11, 0.001)
	assert_approx(M3Elevation.get_tint_opacity(4), 0.12, 0.001)
	assert_approx(M3Elevation.get_tint_opacity(5), 0.14, 0.001)

	var surface: Color = Color(0.1, 0.1, 0.1, 1.0)
	var tint: Color = Color(0.8, 0.6, 1.0, 1.0)
	var tinted_l0: Color = M3Elevation.get_tinted_surface(surface, tint, 0)
	var tinted_l5: Color = M3Elevation.get_tinted_surface(surface, tint, 5)

	assert_color_approx(tinted_l0, surface, 0.001)
	assert_approx(tinted_l5.r, surface.r + (tint.r - surface.r) * 0.14, 0.01)

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	M3Elevation.apply_elevation(sb, 3, surface, tint, true)
	assert_eq(sb.shadow_size, 8)
	assert_vector2_approx(sb.shadow_offset, Vector2(0, 4))
	assert_gt(sb.shadow_color.a, 0.0)

func test_motion_tokens() -> void:
	assert_approx(M3Motion.DURATION_SHORT_1, 0.05, 0.001)
	assert_approx(M3Motion.DURATION_SHORT_4, 0.20, 0.001)
	assert_approx(M3Motion.DURATION_MEDIUM_1, 0.25, 0.001)
	assert_approx(M3Motion.DURATION_MEDIUM_4, 0.40, 0.001)
	assert_approx(M3Motion.DURATION_LONG_1, 0.45, 0.001)
	assert_approx(M3Motion.DURATION_LONG_4, 0.60, 0.001)

	# Bezier evaluation bounds
	assert_approx(M3Motion.evaluate(M3Motion.EASING_STANDARD, 0.0), 0.0, 0.001)
	assert_approx(M3Motion.evaluate(M3Motion.EASING_STANDARD, 1.0), 1.0, 0.001)

	var mid_linear: float = M3Motion.evaluate(M3Motion.EASING_LINEAR, 0.5)
	assert_approx(mid_linear, 0.5, 0.01)

	var mid_standard: float = M3Motion.evaluate(M3Motion.EASING_STANDARD, 0.5)
	assert_gt(mid_standard, 0.5, "Standard easing starts fast and decelerates, so progress at 0.5 is > 0.5")

func test_emphasized_typography_and_expressive_shapes_and_springs() -> void:
	# 1. 15 Emphasized typography roles
	assert_eq(M3Typography.EMPHASIZED_ROLES.size(), 15)
	for i in range(15):
		var base_r := M3Typography.BASELINE_ROLES[i]
		var emp_r := M3Typography.EMPHASIZED_ROLES[i]
		assert_true(M3Typography.is_emphasized(emp_r))
		assert_false(M3Typography.is_emphasized(base_r))
		assert_eq(M3Typography.to_emphasized(base_r), emp_r)
		assert_gt(M3Typography.get_weight(emp_r), M3Typography.get_weight(base_r))

	# 2. 35 Expressive shapes, extended corner tokens & cut corners
	assert_eq(M3Shapes.EXTRA_LARGE_INCREASED, 32)
	assert_eq(M3Shapes.EXTRA_EXTRA_LARGE, 48)
	var all_shapes := M3Shapes.get_all_expressive_shapes()
	assert_eq(all_shapes.size(), 35)
	var cut_poly := M3Shapes.get_cut_corner_polygon(Rect2(0, 0, 100, 60), 12.0)
	assert_eq(cut_poly.size(), 8)
	var morphed := M3Shapes.morph_polygons(M3Shapes.MaterialShape.COOKIE_4, M3Shapes.MaterialShape.HEART, 0.5, Vector2(50, 50), 40.0, 0.0, 48)
	assert_eq(morphed.size(), 48)

	# 3. Spatial vs Effects Springs
	assert_approx(M3Motion.evaluate_spring(M3Motion.SpringType.SPATIAL, M3Motion.SpringSpeed.DEFAULT, 0.0), 0.0, 0.001)
	assert_approx(M3Motion.evaluate_spring(M3Motion.SpringType.SPATIAL, M3Motion.SpringSpeed.DEFAULT, 1.0), 1.0, 0.001)
	var peak_spatial: float = 0.0
	var peak_effects: float = 0.0
	for s in range(1, 50):
		var t: float = float(s) / 50.0
		peak_spatial = maxf(peak_spatial, M3Motion.evaluate_spring(M3Motion.SpringType.SPATIAL, M3Motion.SpringSpeed.FAST, t))
		peak_effects = maxf(peak_effects, M3Motion.evaluate_spring(M3Motion.SpringType.EFFECTS, M3Motion.SpringSpeed.FAST, t))
	assert_gt(peak_spatial, 1.005, "Spatial spring exhibits underdamped overshoot")
	assert_lte(peak_effects, 1.0001, "Effects spring is critically damped with zero overshoot")
