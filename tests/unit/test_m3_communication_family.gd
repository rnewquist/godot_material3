class_name TestM3CommunicationFamily
extends GDTestSuite

## Unit tests for the Material Design 3 Communication Family:
## M3Badge, M3LinearProgress, M3CircularProgress, M3LoadingIndicator,
## M3Snackbar, M3Tooltip (Plain & Rich), and M3Banner.

func _init() -> void:
	suite_name = "M3_Communication_Family_Unit"
	test_type = "unit"

func test_badge_small_large_and_overflow() -> void:
	var badge := auto_add_child(M3Badge.new()) as M3Badge
	badge.badge_size = M3Badge.BadgeSize.SMALL
	await wait_frames(1)
	assert_eq(badge.custom_minimum_size, Vector2(6, 6), "Small badge is 6x6dp dot")
	assert_eq(badge.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Badge ignores mouse input")

	badge.badge_size = M3Badge.BadgeSize.LARGE
	badge.max_count = 999
	badge.count = 7
	assert_eq(badge.display_text, "7", "Single digit count text")
	assert_eq(badge.custom_minimum_size.y, 16.0, "Large badge height is 16dp")
	assert_gte(badge.custom_minimum_size.x, 16.0, "Large badge min width is 16dp")

	badge.count = 1420
	assert_eq(badge.display_text, "999+", "Counts above max_count format as 999+")
	assert_gt(badge.custom_minimum_size.x, 16.0, "Multi-character badge expands horizontally")

	badge.clear()
	assert_eq(badge.count, 0, "clear() resets count to 0")
	assert_false(badge.visible, "clear() hides badge")

	badge.increment(3)
	assert_eq(badge.count, 3, "increment(3) updates count")
	assert_true(badge.visible, "increment() makes badge visible")

func test_linear_progress_determinate_and_indeterminate() -> void:
	var lin := auto_add_child(M3LinearProgress.new()) as M3LinearProgress
	lin.set_value_immediate(0.4)
	await wait_frames(1)
	assert_approx(lin.displayed_value, 0.4, 0.001, "Immediate determinate value")
	assert_eq(lin.track_height, 4.0, "M3 linear track height is 4dp")
	assert_eq(lin.track_gap, 4.0, "M3 2024/2025 linear track gap is 4dp")
	assert_true(lin.show_stop_indicator, "M3 stop indicator enabled by default")

	lin.set_value_animated(0.85, 0.12)
	await wait_time(0.2)
	assert_approx(lin.displayed_value, 0.85, 0.05, "Animated determinate value reaches target")

	lin.indeterminate = true
	var t0: float = lin._anim_time
	await wait_frames(4)
	assert_gt(lin._anim_time, t0, "Indeterminate linear progress advances _anim_time")

func test_circular_progress_determinate_and_indeterminate() -> void:
	var circ := auto_add_child(M3CircularProgress.new()) as M3CircularProgress
	circ.set_value_immediate(0.25)
	await wait_frames(1)
	assert_eq(circ.custom_minimum_size, Vector2(48, 48), "Circular progress default size is 48x48dp")
	assert_approx(circ.displayed_value, 0.25, 0.001, "Immediate circular value")

	circ.set_value_animated(0.75, 0.12)
	await wait_time(0.2)
	assert_approx(circ.displayed_value, 0.75, 0.05, "Animated circular value reaches target")

	circ.indeterminate = true
	var t0: float = circ._anim_time
	await wait_frames(4)
	assert_gt(circ._anim_time, t0, "Indeterminate circular progress advances _anim_time")

func test_progress_wavy_linear_and_circular() -> void:
	var lin := auto_add_child(M3LinearProgress.new()) as M3LinearProgress
	assert_false(lin.wavy, "Linear progress wavy is false by default")
	lin.set_value_immediate(0.5)
	lin.wavy = true
	await wait_frames(1)
	assert_approx(lin._get_minimum_size().y, 12.0, 0.01, "Wavy linear progress min height >= 12dp")
	var lp0: float = lin._wave_phase
	await wait_frames(4)
	assert_ne(lin._wave_phase, lp0, "Determinate wavy linear progress advances _wave_phase")

	var circ := auto_add_child(M3CircularProgress.new()) as M3CircularProgress
	assert_false(circ.wavy, "Circular progress wavy is false by default")
	circ.set_value_immediate(0.6)
	circ.wavy = true
	var cp0: float = circ._wave_phase
	await wait_frames(4)
	assert_ne(circ._wave_phase, cp0, "Determinate wavy circular progress advances _wave_phase")

func test_loading_indicator_expressive_morph_and_variants() -> void:
	var ind := auto_add_child(M3LoadingIndicator.new()) as M3LoadingIndicator
	await wait_frames(1)
	assert_eq(ind.custom_minimum_size, Vector2(48, 48), "Loading indicator container is 48x48dp")
	assert_eq(ind.indicator_size, 38.0, "Loading indicator shape diameter is 38dp")
	assert_false(ind.contained, "Default loading indicator is uncontained")

	var poly0: PackedVector2Array = ind.build_morph_polygon(Vector2(24, 24), 19.0)
	assert_eq(poly0.size(), M3LoadingIndicator.VERTEX_SAMPLES, "Morph polygon has expected vertex count")

	await wait_frames(6)
	assert_gt(ind.rotation_angle, 0.0, "Active loading indicator rotates every frame")
	assert_gt(ind._elapsed, 0.0, "Active loading indicator advances morph elapsed time")

	ind.contained = true
	ind.set_morph_state(2, 0.5, 0.4)
	assert_eq(ind.shape_index, 2, "set_morph_state sets shape_index")
	assert_approx(ind.morph_phase, 0.5, 0.001, "set_morph_state sets morph_phase")

func test_snackbar_show_action_and_dismiss() -> void:
	var sb := auto_add_child(M3Snackbar.new()) as M3Snackbar
	sb.message = "Photo archived"
	sb.action_label = "Undo"
	sb.show_close_icon = true
	await wait_frames(1)

	assert_true(sb.get_action_button().visible, "Action button visible when action_label set")
	assert_true(sb.get_close_button().visible, "Close button visible when show_close_icon is true")

	var action_hits: Array[int] = [0]
	var dismiss_hits: Array[int] = [0]
	sb.action_pressed.connect(func() -> void: action_hits[0] += 1)
	sb.dismissed.connect(func() -> void: dismiss_hits[0] += 1)

	sb.show_snackbar()
	await wait_time(0.26)
	assert_approx(sb.open_progress, 1.0, 0.05, "Snackbar open_progress reaches 1.0")

	sb.get_action_button().pressed.emit()
	await wait_time(0.22)
	assert_eq(action_hits[0], 1, "Clicking action button emits action_pressed")
	assert_eq(dismiss_hits[0], 1, "Action press dismisses snackbar")
	assert_false(sb.is_open, "Snackbar is_open is false after dismiss")

func test_tooltip_plain_and_rich_action() -> void:
	var tip_plain := auto_add_child(M3Tooltip.new()) as M3Tooltip
	tip_plain.tooltip_type = M3Tooltip.TooltipType.PLAIN
	tip_plain.text = "Plain tip"
	tip_plain.show_tooltip(false)
	assert_true(tip_plain.visible, "Plain tooltip visible after show_tooltip")
	assert_eq(tip_plain.custom_minimum_size.y, 24.0, "Plain tooltip height is 24dp")
	tip_plain.hide_tooltip(false)
	assert_false(tip_plain.visible, "Plain tooltip hidden after hide_tooltip")

	var tip_rich := auto_add_child(M3Tooltip.new()) as M3Tooltip
	tip_rich.variant = M3Tooltip.VariantType.RICH
	tip_rich.title = "Rich Title"
	tip_rich.text = "Supporting rich tooltip explanation text."
	tip_rich.action_text = "Learn more"
	tip_rich.show_tooltip(false)
	await wait_frames(1)

	var act_hits: Array[int] = [0]
	tip_rich.action_pressed.connect(func() -> void: act_hits[0] += 1)
	var click_ev := InputEventMouseButton.new()
	click_ev.button_index = MOUSE_BUTTON_LEFT
	click_ev.pressed = true
	click_ev.position = tip_rich.get_action_local_center()
	tip_rich._gui_input(click_ev)
	assert_eq(act_hits[0], 1, "Rich tooltip action click emits action_pressed")
	assert_false(tip_rich.is_open, "Rich tooltip closes after action click")

func test_banner_actions_and_dismiss() -> void:
	var banner := auto_add_child(M3Banner.new()) as M3Banner
	banner.message = "Your connection was lost."
	banner.show_icon = true
	banner.primary_action_label = "Retry"
	banner.secondary_action_label = "Dismiss"
	await wait_frames(1)

	var primary_hits: Array[int] = [0]
	var secondary_hits: Array[int] = [0]
	var dismissed_hits: Array[int] = [0]
	banner.primary_action_pressed.connect(func() -> void: primary_hits[0] += 1)
	banner.secondary_action_pressed.connect(func() -> void: secondary_hits[0] += 1)
	banner.dismissed.connect(func() -> void: dismissed_hits[0] += 1)

	banner.get_primary_button().pressed.emit()
	assert_eq(primary_hits[0], 1, "Primary action button emits primary_action_pressed")
	assert_true(banner.is_open, "Primary action keeps banner open")

	banner.get_secondary_button().pressed.emit()
	await wait_time(0.22)
	assert_eq(secondary_hits[0], 1, "Secondary action button emits secondary_action_pressed")
	assert_eq(dismissed_hits[0], 1, "Secondary action dismisses banner")
	assert_false(banner.is_open, "Banner is_open is false after dismiss")
