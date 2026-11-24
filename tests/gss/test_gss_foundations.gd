extends GDTestSuite

## GSS verification suite for Material Design 3 Foundations:
##   - foundations.color.roles
##   - foundations.color.dynamic
##   - foundations.typography
##   - foundations.shape
##   - foundations.elevation
##   - foundations.motion
##   - foundations.states.layers
##   - foundations.states.ripple
##   - foundations.states.disabled
##   - foundations.accessibility.targets

const H := preload("res://tests/gss/m3_gss_harness.gd")
const SURFACE_SCRIPT := "res://addons/material3/components/base/m3_surface.gd"
const BUTTON_SCRIPT := "res://addons/material3/components/buttons/m3_button.gd"
const ICON_BUTTON_SCRIPT := "res://addons/material3/components/buttons/m3_icon_button.gd"
const CHECKBOX_SCRIPT := "res://addons/material3/components/selection/m3_checkbox.gd"
const SHAPE_MORPH_SCRIPT := "res://addons/material3/components/base/m3_shape_morph.gd"
const TRANSITION_SCRIPT := "res://addons/material3/components/base/m3_transition.gd"

func _init() -> void:
	suite_name = "GSS_Foundations"
	test_type = "integration"

## Helper node for visualizing and animating M3 motion curves in GSS.
class MotionCurveTrack extends Control:
	var curve_name: StringName = M3Motion.CURVE_STANDARD
	var duration_sec: float = M3Motion.DURATION_MEDIUM_2
	var progress: float = 0.0
	var eased_value: float = 0.0
	var puck_x: float = 160.0

	func _init(p_curve: StringName = M3Motion.CURVE_STANDARD, p_dur: float = 0.30) -> void:
		curve_name = p_curve
		duration_sec = p_dur
		custom_minimum_size = Vector2(540, 42)

	func set_normalized_time(t: float) -> void:
		progress = clampf(t, 0.0, 1.0)
		eased_value = M3Motion.evaluate_by_name(curve_name, progress)
		var usable_w: float = maxf(1.0, size.x - 180.0)
		puck_x = 160.0 + eased_value * usable_w
		queue_redraw()

	func start_motion(duration_override: float = -1.0) -> Tween:
		var d: float = duration_override if duration_override > 0.0 else duration_sec
		progress = 0.0
		eased_value = 0.0
		puck_x = 160.0
		var tw: Tween = create_tween()
		tw.bind_node(self)
		tw.tween_method(set_normalized_time, 0.0, 1.0, d)
		return tw

	func _draw() -> void:
		var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()
		var font: Font = ThemeDB.fallback_font
		var label_str: String = "%s (%.0fms)" % [String(curve_name), duration_sec * 1000.0]
		draw_string(font, Vector2(4, 26), label_str, HORIZONTAL_ALIGNMENT_LEFT, 150, 12, scheme.on_surface)

		var track_start: float = 160.0
		var track_end: float = maxf(track_start + 40.0, size.x - 20.0)
		var cy: float = size.y * 0.5
		draw_line(Vector2(track_start, cy), Vector2(track_end, cy), scheme.surface_container_highest, 6.0, true)

		var cur_x: float = track_start + eased_value * (track_end - track_start)
		puck_x = cur_x
		if cur_x > track_start + 1.0:
			draw_line(Vector2(track_start, cy), Vector2(cur_x, cy), scheme.primary, 6.0, true)
		draw_circle(Vector2(cur_x, cy), 10.0, scheme.primary)
		draw_circle(Vector2(cur_x, cy), 4.0, scheme.on_primary)


func _create_swatch(role_name: StringName, text_role: StringName, scheme: M3ColorScheme, min_size: Vector2 = Vector2(142, 48)) -> M3Surface:
	var surf := M3Surface.new()
	surf.name = "Swatch_" + String(role_name)
	surf.surface_role = role_name
	surf.custom_surface_color = scheme.get_color(role_name)
	surf.shape_token = M3Shapes.ShapeToken.SMALL
	surf.custom_minimum_size = min_size
	surf.content_margin_left = 8
	surf.content_margin_right = 8
	surf.content_margin_top = 4
	surf.content_margin_bottom = 4

	var lbl := Label.new()
	lbl.name = "RoleLabel"
	lbl.text = String(role_name)
	M3Typography.apply_to_label(lbl, M3Typography.Role.LABEL_SMALL, scheme.get_color(text_role))
	surf.add_child(lbl)
	return surf


func test_foundations_color_roles() -> void:
	var spec_id := "foundations.color.roles"
	var stage: H.Stage = await H.create_stage(self, "foundations", "color_roles", false)
	var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()

	var all_roles: Array[M3Color.Role] = M3Color.get_all_roles()
	assert_gte(all_roles.size(), 49, "M3Color should expose all 49 M3 color roles including fixed accents")

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "ColorRolesGrid"
	root_vbox.position = Vector2(24, 16)
	root_vbox.size = Vector2(1232, 688)
	root_vbox.add_theme_constant_override("separation", 10)
	stage.root.add_child(root_vbox)

	var title := Label.new()
	title.name = "HeaderTitle"
	title.text = "M3 Color Roles — Primary, Secondary, Tertiary, Error, Surface Containers & Fixed Accents"
	M3Typography.apply_to_label(title, M3Typography.Role.TITLE_LARGE, scheme.on_surface)
	root_vbox.add_child(title)

	var role_groups: Array[Array] = [
		[
			[&"primary", &"on_primary"],
			[&"on_primary", &"primary"],
			[&"primary_container", &"on_primary_container"],
			[&"on_primary_container", &"primary_container"],
			[&"inverse_primary", &"on_primary_container"],
		],
		[
			[&"secondary", &"on_secondary"],
			[&"on_secondary", &"secondary"],
			[&"secondary_container", &"on_secondary_container"],
			[&"on_secondary_container", &"secondary_container"],
			[&"tertiary", &"on_tertiary"],
			[&"on_tertiary", &"tertiary"],
			[&"tertiary_container", &"on_tertiary_container"],
			[&"on_tertiary_container", &"tertiary_container"],
		],
		[
			[&"error", &"on_error"],
			[&"on_error", &"error"],
			[&"error_container", &"on_error_container"],
			[&"on_error_container", &"error_container"],
			[&"outline", &"surface"],
			[&"outline_variant", &"on_surface"],
			[&"inverse_surface", &"inverse_on_surface"],
			[&"inverse_on_surface", &"inverse_surface"],
		],
		[
			[&"surface_dim", &"on_surface"],
			[&"surface", &"on_surface"],
			[&"surface_bright", &"on_surface"],
			[&"surface_container_lowest", &"on_surface"],
			[&"surface_container_low", &"on_surface"],
			[&"surface_container", &"on_surface"],
			[&"surface_container_high", &"on_surface"],
			[&"surface_container_highest", &"on_surface"],
		],
		[
			[&"primary_fixed", &"on_primary_fixed"],
			[&"primary_fixed_dim", &"on_primary_fixed"],
			[&"on_primary_fixed", &"primary_fixed"],
			[&"on_primary_fixed_variant", &"primary_fixed"],
			[&"secondary_fixed", &"on_secondary_fixed"],
			[&"secondary_fixed_dim", &"on_secondary_fixed"],
			[&"tertiary_fixed", &"on_tertiary_fixed"],
			[&"tertiary_fixed_dim", &"on_tertiary_fixed"],
		],
	]

	for row_idx in range(role_groups.size()):
		var row := HBoxContainer.new()
		row.name = "RoleRow_%d" % row_idx
		row.add_theme_constant_override("separation", 8)
		root_vbox.add_child(row)
		for pair in role_groups[row_idx]:
			var r_name: StringName = pair[0]
			var t_name: StringName = pair[1]
			var c: Color = scheme.get_color(r_name)
			assert_ne(c, Color.MAGENTA, "Role %s must resolve to a valid M3 color" % String(r_name))
			row.add_child(_create_swatch(r_name, t_name, scheme, Vector2(144, 52)))

	var snap: Dictionary = await H.snapshot(stage, spec_id, "all_roles_light")
	H.assert_snapshot(self, snap, [SURFACE_SCRIPT])
	H.cover(self, spec_id, "element", snap, "All 49 M3 semantic & fixed color roles")
	stage.dispose()


func test_foundations_color_dynamic() -> void:
	var spec_id := "foundations.color.dynamic"
	var stage: H.Stage = await H.create_stage(self, "foundations", "dynamic_color", false)
	var theme_inst: M3ThemeSingleton = M3ThemeSingleton.get_instance()
	theme_inst.set_seed_color(M3PaletteGenerator.PRESET_BASELINE_INDIGO)

	var panel := M3Surface.new()
	panel.name = "DynamicPreviewSurface"
	panel.surface_role = &"surface_container"
	panel.shape_token = M3Shapes.ShapeToken.LARGE
	panel.position = Vector2(40, 40)
	panel.size = Vector2(1200, 640)
	panel.content_margin_left = 32
	panel.content_margin_top = 32
	panel.content_margin_right = 32
	panel.content_margin_bottom = 32
	stage.root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "DynamicControlsBox"
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var title := Label.new()
	title.name = "DynamicHeadline"
	title.text = "Dynamic Color — Seed & Light/Dark Mode"
	M3Typography.apply_to_label(title, M3Typography.Role.HEADLINE_MEDIUM, theme_inst.get_color(&"on_surface"))
	vbox.add_child(title)

	var btn_row := HBoxContainer.new()
	btn_row.name = "SeedButtonsRow"
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var emerald_btn := M3Button.new()
	emerald_btn.name = "SeedEmeraldButton"
	emerald_btn.text = "Apply Emerald Seed"
	emerald_btn.variant = M3Button.Variant.FILLED
	emerald_btn.pressed.connect(func() -> void:
		theme_inst.set_seed_color(M3PaletteGenerator.PRESET_EMERALD)
		stage.refresh_background()
	)
	btn_row.add_child(emerald_btn)

	var coral_btn := M3Button.new()
	coral_btn.name = "SeedCoralButton"
	coral_btn.text = "Apply Coral Seed"
	coral_btn.variant = M3Button.Variant.TONAL
	coral_btn.pressed.connect(func() -> void:
		theme_inst.set_seed_color(M3PaletteGenerator.PRESET_CORAL)
		stage.refresh_background()
	)
	btn_row.add_child(coral_btn)

	var mode_btn := M3Button.new()
	mode_btn.name = "ToggleDarkModeButton"
	mode_btn.text = "Toggle Dark Mode"
	mode_btn.variant = M3Button.Variant.OUTLINED
	mode_btn.pressed.connect(func() -> void:
		theme_inst.toggle_dark_mode()
		stage.refresh_background()
	)
	btn_row.add_child(mode_btn)

	var snap_light: Dictionary = await H.snapshot(stage, spec_id, "indigo_light_scheme")
	H.assert_snapshot(self, snap_light, [SURFACE_SCRIPT, BUTTON_SCRIPT])
	H.cover(self, spec_id, "element", snap_light, "Dynamic color light scheme")

	var before_primary: Color = theme_inst.get_color(&"primary")
	var rec: Dictionary = await H.record(stage, spec_id, "seed_and_dark_mode_switch", func() -> void:
		await stage.click(emerald_btn)
		await stage.wait(4)
		await stage.click(mode_btn)
		await stage.wait(6)
	, 12)
	H.assert_recording(self, rec)
	H.assert_mutated(self, rec, "SeedEmeraldButton", "script_variables.current_state")
	var after_primary: Color = theme_inst.get_color(&"primary")
	assert_gt(H.color_distance(before_primary, after_primary), 0.10, "Primary color should update after seed + dark mode switch")
	assert_true(theme_inst.is_dark_mode, "Theme should have switched to dark mode via button interaction")
	H.cover(self, spec_id, "interaction", rec, "Live seed color + light/dark mode switch")

	theme_inst.set_seed_color(M3PaletteGenerator.PRESET_BASELINE_INDIGO)
	theme_inst.set_dark_mode(false)
	stage.dispose()


func test_foundations_typography() -> void:
	var spec_id := "foundations.typography"
	var stage: H.Stage = await H.create_stage(self, "foundations", "typography", false)
	var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()

	var surf := M3Surface.new()
	surf.name = "TypographyCard"
	surf.surface_role = &"surface_container_low"
	surf.shape_token = M3Shapes.ShapeToken.MEDIUM
	surf.position = Vector2(24, 16)
	surf.size = Vector2(1232, 688)
	surf.content_margin_left = 24
	surf.content_margin_top = 16
	surf.content_margin_right = 24
	surf.content_margin_bottom = 16
	stage.root.add_child(surf)

	var cols := HBoxContainer.new()
	cols.name = "TypeScaleColumns"
	cols.add_theme_constant_override("separation", 36)
	surf.add_child(cols)

	var col_left := VBoxContainer.new()
	col_left.name = "DisplayAndHeadlineCol"
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", 8)
	cols.add_child(col_left)

	var col_right := VBoxContainer.new()
	col_right.name = "TitleBodyLabelCol"
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", 10)
	cols.add_child(col_right)

	var left_roles: Array[M3Typography.Role] = [
		M3Typography.Role.DISPLAY_LARGE,
		M3Typography.Role.DISPLAY_MEDIUM,
		M3Typography.Role.DISPLAY_SMALL,
		M3Typography.Role.HEADLINE_LARGE,
		M3Typography.Role.HEADLINE_MEDIUM,
		M3Typography.Role.HEADLINE_SMALL,
	]
	var right_roles: Array[M3Typography.Role] = [
		M3Typography.Role.TITLE_LARGE,
		M3Typography.Role.TITLE_MEDIUM,
		M3Typography.Role.TITLE_SMALL,
		M3Typography.Role.BODY_LARGE,
		M3Typography.Role.BODY_MEDIUM,
		M3Typography.Role.BODY_SMALL,
		M3Typography.Role.LABEL_LARGE,
		M3Typography.Role.LABEL_MEDIUM,
		M3Typography.Role.LABEL_SMALL,
	]

	for role in left_roles:
		var r_name: String = String(M3Typography.ROLE_DATA[role]["name"])
		var f_size: int = M3Typography.get_font_size(role)
		var l_height: int = M3Typography.get_line_height(role)
		var lbl := Label.new()
		lbl.name = "Type_" + r_name
		lbl.text = "%s (%dsp / %dsp)" % [r_name, f_size, l_height]
		M3Typography.apply_to_label(lbl, role, scheme.on_surface)
		col_left.add_child(lbl)

	for role in right_roles:
		var r_name: String = String(M3Typography.ROLE_DATA[role]["name"])
		var f_size: int = M3Typography.get_font_size(role)
		var l_height: int = M3Typography.get_line_height(role)
		var lbl := Label.new()
		lbl.name = "Type_" + r_name
		lbl.text = "%s — %dsp / line %dsp" % [r_name, f_size, l_height]
		M3Typography.apply_to_label(lbl, role, scheme.on_surface)
		col_right.add_child(lbl)

	var snap: Dictionary = await H.snapshot(stage, spec_id, "type_scale_15_roles")
	H.assert_snapshot(self, snap, [SURFACE_SCRIPT])
	assert_not_null(H.node_entry(snap, "Type_display_large").get("name"))
	assert_not_null(H.node_entry(snap, "Type_label_small").get("name"))
	H.cover(self, spec_id, "element", snap, "All 15 M3 type scale roles")
	stage.dispose()


func test_foundations_shape() -> void:
	var spec_id := "foundations.shape"
	var stage: H.Stage = await H.create_stage(self, "foundations", "shape_scale", false)
	var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()

	var grid := HFlowContainer.new()
	grid.name = "ShapeScaleFlow"
	grid.position = Vector2(40, 80)
	grid.size = Vector2(1200, 560)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	stage.root.add_child(grid)

	var shape_entries: Array[Array] = [
		["None", M3Shapes.ShapeToken.NONE, 0.0],
		["ExtraSmall", M3Shapes.ShapeToken.EXTRA_SMALL, 4.0],
		["Small", M3Shapes.ShapeToken.SMALL, 8.0],
		["Medium", M3Shapes.ShapeToken.MEDIUM, 12.0],
		["Large", M3Shapes.ShapeToken.LARGE, 16.0],
		["ExtraLarge", M3Shapes.ShapeToken.EXTRA_LARGE, 28.0],
		["Full", M3Shapes.ShapeToken.FULL, 9999.0],
	]

	for entry in shape_entries:
		var s_name: String = entry[0]
		var s_tok: M3Shapes.ShapeToken = entry[1]
		var expected_r: float = entry[2]
		var surf := M3Surface.new()
		surf.name = "Shape_" + s_name
		surf.surface_role = &"primary_container"
		surf.shape_token = s_tok
		surf.border_width = 2
		surf.border_color = scheme.primary
		surf.custom_minimum_size = Vector2(240, 120)
		surf.content_margin_left = 16
		surf.content_margin_top = 16
		assert_approx(surf.get_effective_corner_radius(), expected_r, 0.01, "Shape %s radius mismatch" % s_name)

		var lbl := Label.new()
		lbl.name = "Label_" + s_name
		lbl.text = "%s (%ddp)" % [s_name, int(expected_r)]
		M3Typography.apply_to_label(lbl, M3Typography.Role.TITLE_MEDIUM, scheme.on_primary_container)
		surf.add_child(lbl)
		grid.add_child(surf)

	var snap: Dictionary = await H.snapshot(stage, spec_id, "shape_scale_7_tokens")
	H.assert_snapshot(self, snap, [SURFACE_SCRIPT])
	H.cover(self, spec_id, "element", snap, "7 M3 corner radius shape scale tokens")
	stage.dispose()


func test_foundations_elevation() -> void:
	var spec_id := "foundations.elevation"
	var stage: H.Stage = await H.create_stage(self, "foundations", "elevation_levels", false)
	var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()

	var row := HBoxContainer.new()
	row.name = "ElevationRow"
	row.position = Vector2(40, 180)
	row.size = Vector2(1200, 260)
	row.add_theme_constant_override("separation", 24)
	stage.root.add_child(row)

	var prev_tint: float = -1.0
	for level in range(6):
		var surf := M3Surface.new()
		surf.name = "Elevation_Level_%d" % level
		surf.elevation_level = level
		surf.shape_token = M3Shapes.ShapeToken.MEDIUM
		surf.custom_minimum_size = Vector2(176, 200)
		surf.content_margin_left = 16
		surf.content_margin_top = 16

		var tint_op: float = M3Elevation.get_tint_opacity(level)
		assert_gt(tint_op, prev_tint, "Elevation level %d tint opacity must increase" % level)
		prev_tint = tint_op

		var lbl := Label.new()
		lbl.name = "ElevationLabel_%d" % level
		lbl.text = "Level %d\n%.0fdp\nTint %d%%" % [level, M3Elevation.HEIGHTS[level], int(round(tint_op * 100.0))]
		M3Typography.apply_to_label(lbl, M3Typography.Role.TITLE_MEDIUM, scheme.on_surface)
		surf.add_child(lbl)
		row.add_child(surf)

	var snap: Dictionary = await H.snapshot(stage, spec_id, "elevation_levels_0_to_5")
	H.assert_snapshot(self, snap, [SURFACE_SCRIPT])
	H.cover(self, spec_id, "element", snap, "Elevation levels 0..5 with tonal tinting and shadows")
	stage.dispose()


func test_foundations_motion() -> void:
	var spec_id := "foundations.motion"
	var stage: H.Stage = await H.create_stage(self, "foundations", "motion_curves", false)

	var vbox := VBoxContainer.new()
	vbox.name = "MotionTracksContainer"
	vbox.position = Vector2(48, 48)
	vbox.size = Vector2(1180, 600)
	vbox.add_theme_constant_override("separation", 18)
	stage.root.add_child(vbox)

	var specs: Array[Array] = [
		[M3Motion.CURVE_STANDARD, M3Motion.DURATION_SHORT_4],
		[M3Motion.CURVE_STANDARD_DECELERATE, M3Motion.DURATION_MEDIUM_1],
		[M3Motion.CURVE_STANDARD_ACCELERATE, M3Motion.DURATION_MEDIUM_2],
		[M3Motion.CURVE_EMPHASIZED, M3Motion.DURATION_MEDIUM_4],
		[M3Motion.CURVE_EMPHASIZED_DECELERATE, M3Motion.DURATION_LONG_1],
		[M3Motion.CURVE_EMPHASIZED_ACCELERATE, M3Motion.DURATION_EXTRA_LONG_1],
	]

	var tracks: Array[MotionCurveTrack] = []
	for item in specs:
		var tr := MotionCurveTrack.new(item[0], item[1])
		tr.name = "MotionTrack_" + String(item[0])
		vbox.add_child(tr)
		tracks.append(tr)

	await stage.wait(2)
	var snap: Dictionary = await H.snapshot(stage, spec_id, "motion_curves_rest")
	H.assert_snapshot(self, snap, [])
	H.cover(self, spec_id, "element", snap, "6 M3 easing curves & duration tokens")

	var rec: Dictionary = await H.record(stage, spec_id, "motion_curves_active", func() -> void:
		for tr in tracks:
			tr.start_motion(0.28)
		await stage.wait(20)
	, 16, vbox)
	H.assert_recording(self, rec)
	H.assert_animated(self, rec, "MotionTrack_standard", "script_variables.eased_value", 3)
	H.assert_animated(self, rec, "MotionTrack_emphasized_decelerate", "script_variables.puck_x", 3)
	H.cover(self, spec_id, "animation", rec, "Live easing curve evaluation across frames")
	stage.dispose()


func test_foundations_states_layers_and_ripple() -> void:
	var layers_id := "foundations.states.layers"
	var ripple_id := "foundations.states.ripple"
	var stage: H.Stage = await H.create_stage(self, "foundations", "states_layers_ripple", false)

	var row := HBoxContainer.new()
	row.name = "StateLayersRow"
	row.position = Vector2(60, 120)
	row.size = Vector2(1160, 120)
	row.add_theme_constant_override("separation", 28)
	stage.root.add_child(row)

	var btn_hover := M3Button.new()
	btn_hover.name = "StateBtn_Hover"
	btn_hover.text = "Hover (8%)"
	btn_hover.variant = M3Button.Variant.OUTLINED
	row.add_child(btn_hover)

	var btn_focus := M3Button.new()
	btn_focus.name = "StateBtn_Focus"
	btn_focus.text = "Focus (10%)"
	btn_focus.variant = M3Button.Variant.TONAL
	row.add_child(btn_focus)

	var btn_press := M3Button.new()
	btn_press.name = "StateBtn_Pressed"
	btn_press.text = "Pressed (10%)"
	btn_press.variant = M3Button.Variant.FILLED
	row.add_child(btn_press)

	var btn_drag := M3Button.new()
	btn_drag.name = "StateBtn_Dragged"
	btn_drag.text = "Dragged (16%)"
	btn_drag.variant = M3Button.Variant.ELEVATED
	row.add_child(btn_drag)

	await stage.wait(2)
	if btn_hover._ripple:
		btn_hover._ripple.call("set_hovered", true)
	if btn_focus._ripple:
		btn_focus._ripple.call("set_focused", true)
	if btn_drag._ripple:
		btn_drag._ripple.call("set_dragged", true)
	await stage.wait(12)

	var snap: Dictionary = await H.snapshot(stage, layers_id, "state_layers_overview")
	H.assert_snapshot(self, snap, [BUTTON_SCRIPT])
	H.cover(self, layers_id, "element", snap, "Hover, focus, pressed, and dragged state layer opacities")

	var rec: Dictionary = await H.record(stage, ripple_id, "press_ripple_and_state_layer", func() -> void:
		await stage.hover(btn_press)
		await stage.wait(6)
		await stage.press(btn_press)
		await stage.wait(12)
		await stage.release(btn_press)
		await stage.wait(10)
		await stage.leave()
	, 16, btn_press)
	H.assert_recording(self, rec)
	H.assert_mutated(self, rec, "StateBtn_Pressed", "script_variables.current_state")
	H.assert_animated(self, rec, "StateBtn_Pressed", "script_variables._state_layer_alpha", 2)
	H.assert_animated(self, rec, "StateBtn_Pressed", "script_variables._ripple_wave_radius", 3)

	H.cover(self, [layers_id, ripple_id], "interaction", rec, "Hover, press, and release state layer & ripple")
	H.cover(self, [layers_id, ripple_id], "animation", rec, "State layer alpha tween and ripple wave radius expansion")
	stage.dispose()


func test_foundations_states_disabled_and_accessibility_targets() -> void:
	var disabled_id := "foundations.states.disabled"
	var targets_id := "foundations.accessibility.targets"
	var stage: H.Stage = await H.create_stage(self, "foundations", "disabled_and_targets", false)

	assert_approx(M3Color.STATE_DISABLED_CONTENT_OPACITY, 0.38, 0.001, "Disabled content opacity must be 38%")
	assert_approx(M3Color.STATE_DISABLED_CONTAINER_OPACITY, 0.12, 0.001, "Disabled container opacity must be 12%")

	var row := HBoxContainer.new()
	row.name = "DisabledAndTargetsRow"
	row.position = Vector2(60, 120)
	row.add_theme_constant_override("separation", 24)
	stage.root.add_child(row)

	var disabled_btn := M3Button.new()
	disabled_btn.name = "DisabledFilledButton"
	disabled_btn.text = "Disabled Action"
	disabled_btn.variant = M3Button.Variant.FILLED
	disabled_btn.disabled = true
	var press_counter: Array[int] = [0]
	disabled_btn.pressed.connect(func() -> void: press_counter[0] += 1)
	row.add_child(disabled_btn)

	var enable_toggle_btn := M3Button.new()
	enable_toggle_btn.name = "EnableToggleButton"
	enable_toggle_btn.text = "Unlock Disabled Button"
	enable_toggle_btn.variant = M3Button.Variant.TONAL
	enable_toggle_btn.pressed.connect(func() -> void: disabled_btn.disabled = false)
	row.add_child(enable_toggle_btn)

	var icon_btn := M3IconButton.new()
	icon_btn.name = "CompactIconTarget"
	icon_btn.icon_name = "favorite"
	row.add_child(icon_btn)

	var chk := M3Checkbox.new()
	chk.name = "CompactCheckboxTarget"
	row.add_child(chk)

	await stage.wait(2)
	var icon_target: Rect2 = icon_btn.get_touch_target_rect()
	var chk_target: Rect2 = chk.get_touch_target_rect()
	assert_gte(icon_target.size.x, 48.0, "IconButton touch target width must be >= 48dp")
	assert_gte(icon_target.size.y, 48.0, "IconButton touch target height must be >= 48dp")
	assert_gte(chk_target.size.x, 48.0, "Checkbox touch target width must be >= 48dp")
	assert_gte(chk_target.size.y, 48.0, "Checkbox touch target height must be >= 48dp")
	assert_true(icon_btn._has_point(Vector2(-2.0, 20.0)), "40dp IconButton must accept hits within its 48dp touch target margin")

	var snap: Dictionary = await H.snapshot(stage, disabled_id, "disabled_and_48dp_targets")
	H.assert_snapshot(self, snap, [BUTTON_SCRIPT, ICON_BUTTON_SCRIPT, CHECKBOX_SCRIPT])
	H.cover(self, [disabled_id, targets_id], "element", snap, "Disabled 38%/12% opacities and >=48x48dp touch targets")

	var rec: Dictionary = await H.record(stage, disabled_id, "disabled_rejects_then_unlocks", func() -> void:
		await stage.click(disabled_btn)
		assert_eq(press_counter[0], 0, "Disabled button must ignore click")
		await stage.click(enable_toggle_btn)
		await stage.wait(2)
		await stage.click(disabled_btn)
	, 12)
	assert_eq(press_counter[0], 1, "Unlocked button should fire pressed once")
	H.assert_recording(self, rec)
	H.assert_mutated(self, rec, "DisabledFilledButton", "script_variables.disabled", false)
	H.cover(self, disabled_id, "interaction", rec, "Disabled button blocks click until unlocked")
	stage.dispose()


func test_foundations_color_contrast_variants_and_harmonization() -> void:
	var spec_id := "foundations.color.contrast_variants"
	var stage: H.Stage = await H.create_stage(self, "foundations", "contrast_variants_harmonization", false)
	var theme_inst: M3ThemeSingleton = M3ThemeSingleton.get_instance()
	theme_inst.set_seed_color(M3PaletteGenerator.PRESET_BASELINE_INDIGO)
	theme_inst.set_contrast_level(0.0)
	theme_inst.set_scheme_variant(M3PaletteGenerator.SchemeVariant.TONAL_SPOT)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "ContrastVariantsRoot"
	root_vbox.position = Vector2(24, 16)
	root_vbox.size = Vector2(1232, 688)
	root_vbox.add_theme_constant_override("separation", 14)
	stage.root.add_child(root_vbox)

	# 1. Verify all 9 DynamicScheme variants generate distinct valid schemes
	var variant_row := HBoxContainer.new()
	variant_row.name = "NineSchemeVariantsRow"
	variant_row.add_theme_constant_override("separation", 8)
	root_vbox.add_child(variant_row)

	var variant_names: Array[String] = [
		"TonalSpot", "Vibrant", "Expressive", "Monochrome", "Neutral",
		"Fidelity", "Content", "Rainbow", "FruitSalad"
	]
	for i in range(9):
		var v_enum := i as M3PaletteGenerator.SchemeVariant
		var v_scheme: M3ColorScheme = M3PaletteGenerator.generate_scheme_from_seed(
			M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 0.0, v_enum
		)
		var card := M3Surface.new()
		card.name = "VariantCard_" + variant_names[i]
		card.custom_surface_color = v_scheme.primary_container
		card.border_width = 2
		card.border_color = v_scheme.primary
		card.shape_token = M3Shapes.ShapeToken.MEDIUM
		card.custom_minimum_size = Vector2(128, 86)
		card.content_margin_left = 8
		card.content_margin_top = 8
		var lbl := Label.new()
		lbl.text = "%s\n#%s" % [variant_names[i], v_scheme.primary.to_html(false)]
		M3Typography.apply_to_label(lbl, M3Typography.Role.LABEL_MEDIUM, v_scheme.on_primary_container)
		card.add_child(lbl)
		variant_row.add_child(card)

	# 2. Contrast levels (Standard 0.0, Medium +0.5, High +1.0) & Color Harmonization
	var contrast_row := HBoxContainer.new()
	contrast_row.name = "ContrastAndHarmonizeRow"
	contrast_row.add_theme_constant_override("separation", 16)
	root_vbox.add_child(contrast_row)

	var std_scheme := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 0.0)
	var med_scheme := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 0.5)
	var high_scheme := M3PaletteGenerator.generate_scheme_from_seed(M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, 1.0)
	var cr_std: float = M3Math.contrast_ratio(std_scheme.on_primary_container, std_scheme.primary_container)
	var cr_med: float = M3Math.contrast_ratio(med_scheme.on_primary_container, med_scheme.primary_container)
	var cr_high: float = M3Math.contrast_ratio(high_scheme.on_primary_container, high_scheme.primary_container)
	assert_gt(cr_med, cr_std, "Medium contrast (+0.5) must exceed Standard contrast (0.0)")
	assert_gt(cr_high, cr_med, "High contrast (+1.0) must exceed Medium contrast (+0.5)")

	var raw_warning := Color(0.95, 0.55, 0.05)
	var harmonized_warning: Color = M3PaletteGenerator.harmonize_color(raw_warning, M3PaletteGenerator.PRESET_BASELINE_INDIGO)
	assert_gt(H.color_distance(raw_warning, harmonized_warning), 0.01, "Harmonized color must shift hue toward seed")

	for pair in [["Standard (0.0)", std_scheme], ["Medium (+0.5)", med_scheme], ["High (+1.0)", high_scheme]]:
		var c_surf := M3Surface.new()
		c_surf.name = "ContrastCard_" + String(pair[0]).split(" ")[0]
		var sc: M3ColorScheme = pair[1]
		c_surf.custom_surface_color = sc.primary
		c_surf.shape_token = M3Shapes.ShapeToken.MEDIUM
		c_surf.custom_minimum_size = Vector2(220, 76)
		c_surf.content_margin_left = 12
		c_surf.content_margin_top = 12
		var clbl := Label.new()
		clbl.text = "Contrast: %s" % pair[0]
		M3Typography.apply_to_label(clbl, M3Typography.Role.TITLE_MEDIUM, sc.on_primary)
		c_surf.add_child(clbl)
		contrast_row.add_child(c_surf)

	var harm_surf := M3Surface.new()
	harm_surf.name = "HarmonizedColorSwatch"
	harm_surf.custom_surface_color = harmonized_warning
	harm_surf.shape_token = M3Shapes.ShapeToken.MEDIUM
	harm_surf.custom_minimum_size = Vector2(240, 76)
	harm_surf.content_margin_left = 12
	harm_surf.content_margin_top = 12
	var hlbl := Label.new()
	hlbl.text = "Harmonized Accent\n#%s" % harmonized_warning.to_html(false)
	M3Typography.apply_to_label(hlbl, M3Typography.Role.TITLE_SMALL, Color.BLACK)
	harm_surf.add_child(hlbl)
	contrast_row.add_child(harm_surf)

	# Interactive buttons to switch contrast level and scheme variant live
	var ctrl_row := HBoxContainer.new()
	ctrl_row.name = "ContrastVariantInteractiveRow"
	ctrl_row.add_theme_constant_override("separation", 16)
	root_vbox.add_child(ctrl_row)

	var btn_high_contrast := M3Button.new()
	btn_high_contrast.name = "ApplyHighContrastBtn"
	btn_high_contrast.text = "High Contrast (+1.0)"
	btn_high_contrast.pressed.connect(func() -> void:
		theme_inst.set_contrast_level(1.0)
	)
	ctrl_row.add_child(btn_high_contrast)

	var btn_vibrant := M3Button.new()
	btn_vibrant.name = "ApplyExpressiveVariantBtn"
	btn_vibrant.text = "Expressive Scheme Variant"
	btn_vibrant.variant = M3Button.Variant.TONAL
	btn_vibrant.pressed.connect(func() -> void:
		theme_inst.set_scheme_variant(M3PaletteGenerator.SchemeVariant.EXPRESSIVE)
	)
	ctrl_row.add_child(btn_vibrant)

	var snap: Dictionary = await H.snapshot(stage, spec_id, "nine_variants_and_contrast_levels")
	H.assert_snapshot(self, snap, [SURFACE_SCRIPT, BUTTON_SCRIPT])
	H.cover(self, spec_id, "element", snap, "9 DynamicScheme variants, 3 contrast levels, and color harmonization")

	var rec: Dictionary = await H.record(stage, spec_id, "switch_contrast_and_variant", func() -> void:
		await stage.click(btn_high_contrast)
		await stage.wait(4)
		await stage.click(btn_vibrant)
		await stage.wait(4)
	, 10)
	H.assert_recording(self, rec)
	H.assert_mutated(self, rec, "ApplyHighContrastBtn", "script_variables.current_state")
	assert_approx(theme_inst.contrast_level, 1.0, 0.01, "Theme contrast_level updated to 1.0")
	assert_eq(int(theme_inst.scheme_variant), int(M3PaletteGenerator.SchemeVariant.EXPRESSIVE), "Theme scheme_variant updated to EXPRESSIVE")
	H.cover(self, spec_id, "interaction", rec, "Interactive contrast level and scheme variant switching")

	theme_inst.set_contrast_level(0.0)
	theme_inst.set_scheme_variant(M3PaletteGenerator.SchemeVariant.TONAL_SPOT)
	stage.dispose()


func test_foundations_typography_emphasized() -> void:
	var spec_id := "foundations.typography.emphasized"
	var stage: H.Stage = await H.create_stage(self, "foundations", "typography_emphasized", false)
	var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()

	var surf := M3Surface.new()
	surf.name = "EmphasizedTypographyCard"
	surf.surface_role = &"surface_container_low"
	surf.shape_token = M3Shapes.ShapeToken.LARGE
	surf.position = Vector2(24, 16)
	surf.size = Vector2(1232, 688)
	surf.content_margin_left = 24
	surf.content_margin_top = 16
	surf.content_margin_right = 24
	surf.content_margin_bottom = 16
	stage.root.add_child(surf)

	var cols := HBoxContainer.new()
	cols.name = "EmphasizedTypeColumns"
	cols.add_theme_constant_override("separation", 36)
	surf.add_child(cols)

	var col_left := VBoxContainer.new()
	col_left.name = "EmphasizedDisplayHeadlineCol"
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", 8)
	cols.add_child(col_left)

	var col_right := VBoxContainer.new()
	col_right.name = "EmphasizedTitleBodyLabelCol"
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", 10)
	cols.add_child(col_right)

	for i in range(M3Typography.EMPHASIZED_ROLES.size()):
		var role: M3Typography.Role = M3Typography.EMPHASIZED_ROLES[i]
		var base_role: M3Typography.Role = M3Typography.BASELINE_ROLES[i]
		assert_true(M3Typography.is_emphasized(role), "Role must be marked emphasized")
		assert_gt(M3Typography.get_weight(role), M3Typography.get_weight(base_role), "Emphasized weight must exceed baseline weight")
		var r_name: String = String(M3Typography.ROLE_DATA[role]["name"])
		var lbl := Label.new()
		lbl.name = "Type_" + r_name
		lbl.text = "%s (%dsp · w%d)" % [r_name, M3Typography.get_font_size(role), M3Typography.get_weight(role)]
		M3Typography.apply_to_label(lbl, role, scheme.on_surface)
		if i < 6:
			col_left.add_child(lbl)
		else:
			col_right.add_child(lbl)

	var snap: Dictionary = await H.snapshot(stage, spec_id, "emphasized_type_scale_15_roles")
	H.assert_snapshot(self, snap, [SURFACE_SCRIPT])
	H.cover(self, spec_id, "element", snap, "All 15 M3 Expressive Emphasized type scale roles")
	stage.dispose()


func test_foundations_shape_expressive_morph() -> void:
	var spec_id := "foundations.shape.expressive_morph"
	var stage: H.Stage = await H.create_stage(self, "foundations", "shape_expressive_morph", false)

	var all_shapes: Array[M3Shapes.MaterialShape] = M3Shapes.get_all_expressive_shapes()
	assert_eq(all_shapes.size(), 35, "M3Shapes must provide all 35 M3 Expressive MaterialShapes")
	assert_eq(M3Shapes.EXTRA_LARGE_INCREASED, 32)
	assert_eq(M3Shapes.EXTRA_EXTRA_LARGE, 48)

	# Grid of all 35 M3 Expressive shapes + Cut-corner family + Hero morphing polygon
	var grid := GridContainer.new()
	grid.name = "ExpressiveShapesGrid"
	grid.columns = 9
	grid.position = Vector2(24, 20)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	stage.root.add_child(grid)

	var hero_morph: M3ShapeMorph = null
	for i in range(all_shapes.size()):
		var sm := M3ShapeMorph.new()
		sm.name = "ExpressiveShape_%d" % i
		sm.custom_minimum_size = Vector2(82, 82)
		sm.size = Vector2(82, 82)
		sm.from_shape = all_shapes[i]
		sm.to_shape = all_shapes[(i + 7) % all_shapes.size()]
		sm.morph_progress = 0.0
		sm.label_text = "#%d" % (i + 1)
		grid.add_child(sm)
		if i == 16: # COOKIE_4 -> SUNNY hero morpher
			hero_morph = sm

	# Add a CornerFamily.CUT chamfered badge next to the 35 shapes
	var cut_node := M3ShapeMorph.new()
	cut_node.name = "CutCornerShapeNode"
	cut_node.corner_family = M3Shapes.CornerFamily.CUT
	cut_node.cut_corner_size = 18.0
	cut_node.custom_minimum_size = Vector2(82, 82)
	cut_node.size = Vector2(82, 82)
	cut_node.label_text = "CUT"
	grid.add_child(cut_node)

	await stage.wait(2)
	var snap: Dictionary = await H.snapshot(stage, spec_id, "all_35_expressive_shapes_and_cut")
	H.assert_snapshot(self, snap, [SHAPE_MORPH_SCRIPT])
	H.cover(self, spec_id, "element", snap, "35 M3 Expressive MaterialShapes, 32/48dp tokens, and Cut corner family")

	var rec: Dictionary = await H.record(stage, spec_id, "polygon_vertex_morph", func() -> void:
		hero_morph.morph_to(M3Shapes.MaterialShape.VERY_SUNNY, 0.30, 0.55)
		await stage.wait(20)
	, 14, hero_morph)
	H.assert_recording(self, rec)
	H.assert_animated(self, rec, hero_morph.name, "script_variables.morph_progress", 3)
	H.assert_animated(self, rec, hero_morph.name, "script_variables.rotation_angle", 3)
	H.cover(self, spec_id, "animation", rec, "Live polygon vertex morphing across frames")
	stage.dispose()


func test_foundations_motion_springs_and_transitions() -> void:
	var spec_id := "foundations.motion.springs_transitions"
	var stage: H.Stage = await H.create_stage(self, "foundations", "motion_springs_transitions", false)

	# Verify Spatial spring overshoots > 1.0 whereas Effects spring is critically damped <= 1.0
	var max_spatial: float = 0.0
	var max_effects: float = 0.0
	for step_i in range(1, 40):
		var nt: float = float(step_i) / 40.0
		max_spatial = maxf(max_spatial, M3Motion.evaluate_spring(M3Motion.SpringType.SPATIAL, M3Motion.SpringSpeed.FAST, nt))
		max_effects = maxf(max_effects, M3Motion.evaluate_spring(M3Motion.SpringType.EFFECTS, M3Motion.SpringSpeed.FAST, nt))
	assert_gt(max_spatial, 1.005, "Spatial spring (zeta=0.72) must naturally overshoot > 1.0")
	assert_lte(max_effects, 1.0001, "Effects spring (zeta=1.0) must never overshoot > 1.0")

	var grid := GridContainer.new()
	grid.name = "TransitionPatternsGrid"
	grid.columns = 2
	grid.position = Vector2(48, 40)
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 24)
	stage.root.add_child(grid)

	var pattern_configs: Array[Array] = [
		["ContainerTransform", M3Motion.TransitionPattern.CONTAINER_TRANSFORM, "Card Stub", "Expanded Detail"],
		["SharedAxisX", M3Motion.TransitionPattern.SHARED_AXIS_X, "Step 1", "Step 2 (Axis X)"],
		["FadeThrough", M3Motion.TransitionPattern.FADE_THROUGH, "Tab A", "Tab B (FadeThrough)"],
		["Fade", M3Motion.TransitionPattern.FADE, "Closed", "Modal Dialog (Fade)"],
	]

	var controllers: Array[M3Transition] = []
	for cfg in pattern_configs:
		var tc := M3Transition.new()
		tc.name = "Transition_" + String(cfg[0])
		tc.pattern = cfg[1]
		tc.outgoing_label = cfg[2]
		tc.incoming_label = cfg[3]
		tc.custom_minimum_size = Vector2(540, 160)
		tc.size = Vector2(540, 160)
		tc.expanded_rect = Rect2(16, 14, 500, 130)
		grid.add_child(tc)
		controllers.append(tc)

	await stage.wait(2)
	var snap: Dictionary = await H.snapshot(stage, spec_id, "four_transition_patterns_rest")
	H.assert_snapshot(self, snap, [TRANSITION_SCRIPT])
	H.cover(self, spec_id, "element", snap, "Spatial/Effects springs & 4 M3 transition patterns")

	var rec: Dictionary = await H.record(stage, spec_id, "springs_and_transitions_active", func() -> void:
		for tc in controllers:
			tc.play_transition(true, 0.32)
		await stage.wait(22)
	, 14, controllers[0])
	H.assert_recording(self, rec)
	H.assert_animated(self, rec, "Transition_ContainerTransform", "script_variables.spatial_spring_val", 3)
	H.assert_animated(self, rec, "Transition_FadeThrough", "script_variables.effects_spring_val", 3)
	H.cover(self, spec_id, "animation", rec, "Live Spatial & Effects spring transition playback")
	stage.dispose()


func test_foundations_layout_density() -> void:
	var spec_id := "foundations.layout.density"
	var stage: H.Stage = await H.create_stage(self, "foundations", "layout_density", false)
	var theme_inst: M3ThemeSingleton = M3ThemeSingleton.get_instance()
	theme_inst.set_visual_density(0)

	var vbox := VBoxContainer.new()
	vbox.name = "DensityComparisonCol"
	vbox.position = Vector2(60, 48)
	vbox.add_theme_constant_override("separation", 18)
	stage.root.add_child(vbox)

	var sample_buttons: Array[M3Button] = []
	for d in [0, -1, -2, -3]:
		var btn := M3Button.new()
		btn.name = "DensityBtn_%d" % absi(d)
		btn.density_override = d
		var adj_h: float = btn.get_density_adjusted_height(40.0)
		btn.text = "Density %d (Height %.0fdp)" % [d, adj_h]
		vbox.add_child(btn)
		sample_buttons.append(btn)

	var interactive_btn := M3Button.new()
	interactive_btn.name = "CycleDensityButton"
	interactive_btn.text = "Apply Compact Density (-2)"
	interactive_btn.variant = M3Button.Variant.TONAL
	interactive_btn.pressed.connect(func() -> void:
		theme_inst.set_visual_density(-2)
	)
	vbox.add_child(interactive_btn)

	await stage.wait(2)
	assert_approx(sample_buttons[0].size.y, 40.0, 0.1)
	assert_approx(sample_buttons[1].size.y, 36.0, 0.1)
	assert_approx(sample_buttons[2].size.y, 32.0, 0.1)
	assert_approx(sample_buttons[3].size.y, 28.0, 0.1)

	var snap: Dictionary = await H.snapshot(stage, spec_id, "density_scale_0_to_minus3")
	H.assert_snapshot(self, snap, [BUTTON_SCRIPT])
	H.cover(self, spec_id, "element", snap, "Visual density scale 0 (40dp), -1 (36dp), -2 (32dp), -3 (28dp)")

	var rec: Dictionary = await H.record(stage, spec_id, "apply_compact_density", func() -> void:
		await stage.click(interactive_btn)
		await stage.wait(4)
	, 10, interactive_btn)
	H.assert_recording(self, rec)
	assert_eq(theme_inst.visual_density, -2)
	assert_approx(interactive_btn.size.y, 32.0, 0.1)
	H.cover(self, spec_id, "interaction", rec, "Live visual density step change")

	theme_inst.set_visual_density(0)
	stage.dispose()
