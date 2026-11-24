# res://tests/gss/test_gss_communication.gd
## GSS verification suite for the Material Design 3 Communication family:
##   - communication.badge (M3Badge)
##   - communication.progress.linear (M3LinearProgress)
##   - communication.progress.circular (M3CircularProgress)
##   - communication.loading_indicator (M3LoadingIndicator)
##   - communication.snackbar (M3Snackbar)
##   - communication.tooltip.plain (M3Tooltip Plain)
##   - communication.tooltip.rich (M3Tooltip Rich)
##   - communication.banner (M3Banner)
extends GDTestSuite

const H := preload("res://tests/gss/m3_gss_harness.gd")

const BADGE_SCRIPT := "res://addons/material3/components/info/m3_badge.gd"
const LINEAR_PROGRESS_SCRIPT := "res://addons/material3/components/feedback/m3_linear_progress.gd"
const CIRCULAR_PROGRESS_SCRIPT := "res://addons/material3/components/feedback/m3_circular_progress.gd"
const LOADING_INDICATOR_SCRIPT := "res://addons/material3/components/feedback/m3_loading_indicator.gd"
const SNACKBAR_SCRIPT := "res://addons/material3/components/feedback/m3_snackbar.gd"
const TOOLTIP_SCRIPT := "res://addons/material3/components/info/m3_tooltip.gd"
const BANNER_SCRIPT := "res://addons/material3/components/feedback/m3_banner.gd"

func _init() -> void:
	suite_name = "GSS_Communication"
	test_type = "integration"

# ==============================================================================
# 1. communication.badge
# ==============================================================================

func test_communication_badge() -> void:
	var stage = await H.create_stage(self, "communication", "badge_variants", false)

	var badge_small := M3Badge.new()
	badge_small.name = "BadgeSmall"
	badge_small.badge_size = M3Badge.BadgeSize.SMALL
	badge_small.anchor_to_target = false
	stage.add(badge_small, Vector2(120, 120))

	var badge_count := M3Badge.new()
	badge_count.name = "BadgeCount"
	badge_count.badge_size = M3Badge.BadgeSize.LARGE
	badge_count.count = 5
	badge_count.max_count = 999
	badge_count.anchor_to_target = false
	stage.add(badge_count, Vector2(200, 116))

	var badge_overflow := M3Badge.new()
	badge_overflow.name = "BadgeOverflow"
	badge_overflow.badge_size = M3Badge.BadgeSize.LARGE
	badge_overflow.count = 1250
	badge_overflow.max_count = 999
	badge_overflow.anchor_to_target = false
	stage.add(badge_overflow, Vector2(280, 116))

	var add_btn := M3Button.new()
	add_btn.name = "IncrementBadgeButton"
	add_btn.text = "Add Notification"
	add_btn.pressed.connect(func() -> void: badge_count.increment(1))
	stage.add(add_btn, Vector2(120, 180))

	var clear_btn := M3Button.new()
	clear_btn.name = "ClearBadgeButton"
	clear_btn.text = "Clear"
	clear_btn.variant = M3Button.Variant.OUTLINED
	clear_btn.pressed.connect(func() -> void: badge_count.clear())
	stage.add(clear_btn, Vector2(310, 180))

	var snap: Dictionary = await H.snapshot(stage, "communication.badge", "variants_light")
	H.assert_snapshot(self, snap, [BADGE_SCRIPT])

	var sm_node: Dictionary = H.node_entry(snap, "BadgeSmall")
	assert_approx(float(sm_node.get("screen_rect", {}).get("width", 0.0)), 6.0, 0.5, "small dot badge width = 6dp")
	assert_approx(float(sm_node.get("screen_rect", {}).get("height", 0.0)), 6.0, 0.5, "small dot badge height = 6dp")

	var lg_node: Dictionary = H.node_entry(snap, "BadgeCount")
	assert_approx(float(lg_node.get("screen_rect", {}).get("height", 0.0)), 16.0, 0.5, "large badge height = 16dp")
	assert_eq(str(lg_node.get("script_variables", {}).get("display_text", "")), "5", "large badge displays count 5")

	var ov_node: Dictionary = H.node_entry(snap, "BadgeOverflow")
	assert_eq(str(ov_node.get("script_variables", {}).get("display_text", "")), "999+", "overflow badge displays 999+")

	await H.assert_pixel(self, stage, stage.point_of(badge_small, Vector2(3, 3)), M3ThemeSingleton.get_instance().get_color(&"error"), 0.08, "small badge fill = error")
	H.cover(self, "communication.badge", "element", snap)

	var live: Dictionary = await H.record(stage, "communication.badge", "increment_and_clear", func() -> void:
		await stage.click(add_btn)
		await stage.wait(4)
		await stage.click(add_btn)
		await stage.wait(4)
		await stage.click(clear_btn)
		await stage.wait(4)
	, 8, badge_count)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "BadgeCount", "script_variables.count", 0)
	H.assert_mutated(self, live, "BadgeCount", "script_variables.display_text", "")
	H.cover(self, "communication.badge", "interaction", live)
	stage.dispose()

# ==============================================================================
# 2. communication.progress.linear
# ==============================================================================

func test_communication_progress_linear() -> void:
	var stage = await H.create_stage(self, "communication", "linear_progress", false)

	var lin_det := M3LinearProgress.new()
	lin_det.name = "LinearDeterminate"
	lin_det.size = Vector2(280, 4)
	lin_det.set_value_immediate(0.5)
	stage.add(lin_det, Vector2(120, 140))

	var lin_indet := M3LinearProgress.new()
	lin_indet.name = "LinearIndeterminate"
	lin_indet.size = Vector2(280, 4)
	lin_indet.indeterminate = true
	stage.add(lin_indet, Vector2(120, 200))

	var snap: Dictionary = await H.snapshot(stage, "communication.progress.linear", "variants_light")
	H.assert_snapshot(self, snap, [LINEAR_PROGRESS_SCRIPT])

	var det_node: Dictionary = H.node_entry(snap, "LinearDeterminate")
	assert_approx(float(det_node.get("screen_rect", {}).get("height", 0.0)), 4.0, 0.5, "linear progress height = 4dp")

	var primary_col: Color = M3ThemeSingleton.get_instance().get_color(&"primary")
	var track_col: Color = M3ThemeSingleton.get_instance().get_color(&"surface_container_highest")
	await H.assert_pixel(self, stage, stage.point_of(lin_det, Vector2(40, 2)), primary_col, 0.08, "linear active indicator = primary")
	await H.assert_pixel(self, stage, stage.point_of(lin_det, Vector2(200, 2)), track_col, 0.08, "linear inactive track = surface_container_highest")
	await H.assert_pixel(self, stage, stage.point_of(lin_det, Vector2(278, 2)), primary_col, 0.12, "linear stop indicator dot = primary")
	H.cover(self, "communication.progress.linear", "element", snap)

	var live: Dictionary = await H.record(stage, "communication.progress.linear", "animate_progress", func() -> void:
		lin_det.set_value_animated(0.9, 0.22)
		await stage.wait(18)
	, 10, lin_det)
	H.assert_recording(self, live)
	H.assert_animated(self, live, "LinearDeterminate", "script_variables.displayed_value", 4)
	H.assert_animated(self, live, "LinearIndeterminate", "script_variables._anim_time", 6)
	H.cover(self, "communication.progress.linear", "animation", live)
	stage.dispose()

# ==============================================================================
# 3. communication.progress.circular
# ==============================================================================

func test_communication_progress_circular() -> void:
	var stage = await H.create_stage(self, "communication", "circular_progress", true)

	var circ_det := M3CircularProgress.new()
	circ_det.name = "CircularDeterminate"
	circ_det.size = Vector2(48, 48)
	circ_det.show_track = true
	circ_det.set_value_immediate(0.65)
	stage.add(circ_det, Vector2(160, 160))

	var circ_indet := M3CircularProgress.new()
	circ_indet.name = "CircularIndeterminate"
	circ_indet.size = Vector2(48, 48)
	circ_indet.indeterminate = true
	stage.add(circ_indet, Vector2(260, 160))

	var snap: Dictionary = await H.snapshot(stage, "communication.progress.circular", "variants_dark")
	H.assert_snapshot(self, snap, [CIRCULAR_PROGRESS_SCRIPT])

	var det_node: Dictionary = H.node_entry(snap, "CircularDeterminate")
	assert_approx(float(det_node.get("screen_rect", {}).get("width", 0.0)), 48.0, 0.5, "circular progress width = 48dp")
	assert_approx(float(det_node.get("screen_rect", {}).get("height", 0.0)), 48.0, 0.5, "circular progress height = 48dp")

	await H.assert_pixel(self, stage, stage.point_of(circ_det, Vector2(46, 24)), M3ThemeSingleton.get_instance().get_color(&"primary"), 0.12, "circular active arc at 3 o'clock = primary")
	H.cover(self, "communication.progress.circular", "element", snap)

	var live: Dictionary = await H.record(stage, "communication.progress.circular", "animate_progress", func() -> void:
		circ_det.set_value_animated(0.95, 0.22)
		await stage.wait(18)
	, 10, circ_det)
	H.assert_recording(self, live)
	H.assert_animated(self, live, "CircularDeterminate", "script_variables.displayed_value", 4)
	H.assert_animated(self, live, "CircularIndeterminate", "script_variables._anim_time", 6)
	H.cover(self, "communication.progress.circular", "animation", live)
	stage.dispose()

# ==============================================================================
# 4. communication.loading_indicator
# ==============================================================================

func test_communication_loading_indicator() -> void:
	var stage = await H.create_stage(self, "communication", "loading_indicator", false)

	var ind_uncontained := M3LoadingIndicator.new()
	ind_uncontained.name = "LoadingUncontained"
	ind_uncontained.contained = false
	ind_uncontained.active = true
	stage.add(ind_uncontained, Vector2(120, 140))

	var ind_contained := M3LoadingIndicator.new()
	ind_contained.name = "LoadingContained"
	ind_contained.contained = true
	ind_contained.active = true
	stage.add(ind_contained, Vector2(200, 140))

	# Static shape morph sequence showcase (all 5 expressive shapes)
	for i in range(M3LoadingIndicator.SHAPE_COUNT):
		var step := M3LoadingIndicator.new()
		step.name = "MorphStep%d" % i
		step.contained = (i % 2 == 1)
		step.active = false
		step.set_morph_state(i, 0.0, 0.0)
		stage.add(step, Vector2(120 + i * 64, 230))

	var snap: Dictionary = await H.snapshot(stage, "communication.loading_indicator", "variants_and_morph_sequence")
	H.assert_snapshot(self, snap, [LOADING_INDICATOR_SCRIPT])

	var unc_node: Dictionary = H.node_entry(snap, "LoadingUncontained")
	assert_approx(float(unc_node.get("screen_rect", {}).get("width", 0.0)), 48.0, 0.5, "uncontained loading indicator width = 48dp")
	assert_approx(float(unc_node.get("screen_rect", {}).get("height", 0.0)), 48.0, 0.5, "uncontained loading indicator height = 48dp")

	var cnt_node: Dictionary = H.node_entry(snap, "LoadingContained")
	assert_approx(float(cnt_node.get("screen_rect", {}).get("width", 0.0)), 48.0, 0.5, "contained loading indicator width = 48dp")

	await H.assert_pixel(self, stage, stage.point_of(ind_uncontained, Vector2(24, 24)), M3ThemeSingleton.get_instance().get_color(&"primary"), 0.08, "uncontained indicator center = primary")
	await H.assert_pixel(self, stage, stage.point_of(ind_contained, Vector2(24, 24)), M3ThemeSingleton.get_instance().get_color(&"on_primary_container"), 0.08, "contained indicator center = on_primary_container")
	await H.assert_pixel(self, stage, stage.point_of(ind_contained, Vector2(24, 3)), M3ThemeSingleton.get_instance().get_color(&"primary_container"), 0.08, "contained outer circle = primary_container")
	H.cover(self, "communication.loading_indicator", "element", snap)

	var live: Dictionary = await H.record(stage, "communication.loading_indicator", "morph_and_rotate", func() -> void:
		await stage.wait(24)
	, 8, ind_contained)
	H.assert_recording(self, live)
	H.assert_animated(self, live, "LoadingUncontained", "script_variables.morph_phase", 6)
	H.assert_animated(self, live, "LoadingUncontained", "script_variables.rotation_angle", 6)
	H.assert_animated(self, live, "LoadingContained", "script_variables.morph_phase", 6)
	H.cover(self, "communication.loading_indicator", "animation", live)
	stage.dispose()

# ==============================================================================
# 5. communication.snackbar
# ==============================================================================

func test_communication_snackbar() -> void:
	var stage = await H.create_stage(self, "communication", "snackbar_variants", false)

	var sb_single := M3Snackbar.new()
	sb_single.name = "SnackbarSingleLine"
	sb_single.message = "Photo archived to library"
	sb_single.action_label = ""
	sb_single.show_close_icon = false
	stage.add(sb_single, Vector2(100, 100))

	var sb_action := M3Snackbar.new()
	sb_action.name = "SnackbarWithAction"
	sb_action.message = "Message moved to trash"
	sb_action.action_label = "Undo"
	sb_action.show_close_icon = false
	stage.add(sb_action, Vector2(100, 180))

	var sb_close := M3Snackbar.new()
	sb_close.name = "SnackbarWithClose"
	sb_close.message = "Connection restored"
	sb_close.action_label = "Retry"
	sb_close.show_close_icon = true
	stage.add(sb_close, Vector2(100, 260))

	var snap: Dictionary = await H.snapshot(stage, "communication.snackbar", "variants_light")
	H.assert_snapshot(self, snap, [SNACKBAR_SCRIPT])

	var s1_node: Dictionary = H.node_entry(snap, "SnackbarSingleLine")
	assert_gte(float(s1_node.get("screen_rect", {}).get("height", 0.0)), 48.0, "snackbar single-line height >= 48dp")

	await H.assert_pixel(self, stage, stage.point_of(sb_single, Vector2(10, 10)), M3ThemeSingleton.get_instance().get_color(&"inverse_surface"), 0.08, "snackbar container = inverse_surface")
	H.cover(self, "communication.snackbar", "element", snap)

	var live: Dictionary = await H.record(stage, "communication.snackbar", "enter_action_and_dismiss", func() -> void:
		sb_action.show_snackbar()
		await stage.wait(16)
		await stage.click(sb_action.get_action_button())
		await stage.wait(14)
		await stage.click(sb_close.get_close_button())
		await stage.wait(14)
	, 6, sb_action)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "SnackbarWithAction", "script_variables.action_click_count", 1)
	H.assert_mutated(self, live, "SnackbarWithAction", "script_variables.is_open", false)
	H.assert_mutated(self, live, "SnackbarWithClose", "script_variables.is_open", false)
	H.assert_animated(self, live, "SnackbarWithAction", "script_variables.open_progress", 4)
	H.cover(self, "communication.snackbar", "interaction", live)
	H.cover(self, "communication.snackbar", "animation", live)
	stage.dispose()

# ==============================================================================
# 6. communication.tooltip.plain
# ==============================================================================

func test_communication_tooltip_plain() -> void:
	var stage = await H.create_stage(self, "communication", "tooltip_plain", false)

	var target_btn := M3Button.new()
	target_btn.name = "PlainTooltipTarget"
	target_btn.text = "Hover Target"
	stage.add(target_btn, Vector2(200, 160))

	var tip_plain := M3Tooltip.new()
	tip_plain.name = "PlainTooltip"
	tip_plain.tooltip_type = M3Tooltip.TooltipType.PLAIN
	tip_plain.text = "Save to bookmarks"
	tip_plain.enter_delay = 0.03
	tip_plain.set_target(target_btn)
	stage.add(tip_plain, Vector2(200, 210))
	tip_plain.show_tooltip(false)

	var snap: Dictionary = await H.snapshot(stage, "communication.tooltip.plain", "plain_variant")
	H.assert_snapshot(self, snap, [TOOLTIP_SCRIPT])

	var p_node: Dictionary = H.node_entry(snap, "PlainTooltip")
	assert_approx(float(p_node.get("screen_rect", {}).get("height", 0.0)), 24.0, 0.5, "plain tooltip height = 24dp")
	await H.assert_pixel(self, stage, stage.point_of(tip_plain, Vector2(6, 6)), M3ThemeSingleton.get_instance().get_color(&"inverse_surface"), 0.08, "plain tooltip container = inverse_surface")
	H.cover(self, "communication.tooltip.plain", "element", snap)

	tip_plain.hide_tooltip(false)
	await stage.settle()

	var live: Dictionary = await H.record(stage, "communication.tooltip.plain", "hover_fade_in_and_out", func() -> void:
		await stage.hover(target_btn)
		await stage.wait(16)
		await stage.leave()
		await stage.wait(12)
	, 6, tip_plain)
	H.assert_recording(self, live)
	H.assert_animated(self, live, "PlainTooltip", "script_variables.open_progress", 4)
	H.assert_event(self, live, "script_variable_changed", "PlainTooltip", "is_open")
	H.cover(self, "communication.tooltip.plain", "interaction", live)
	H.cover(self, "communication.tooltip.plain", "animation", live)
	stage.dispose()

# ==============================================================================
# 7. communication.tooltip.rich
# ==============================================================================

func test_communication_tooltip_rich() -> void:
	var stage = await H.create_stage(self, "communication", "tooltip_rich", false)

	var tip_body_only := M3Tooltip.new()
	tip_body_only.name = "RichTooltipTitleBody"
	tip_body_only.tooltip_type = M3Tooltip.TooltipType.RICH
	tip_body_only.title = "End-to-end encryption"
	tip_body_only.text = "Messages in this thread are protected with an encryption key."
	tip_body_only.action_text = ""
	stage.add(tip_body_only, Vector2(100, 120))
	tip_body_only.show_tooltip(false)

	var rich_target := M3Button.new()
	rich_target.name = "RichTooltipTarget"
	rich_target.text = "Cloud Backup"
	rich_target.variant = M3Button.Variant.TONAL
	stage.add(rich_target, Vector2(460, 120))

	var tip_action := M3Tooltip.new()
	tip_action.name = "RichTooltipWithAction"
	tip_action.tooltip_type = M3Tooltip.TooltipType.RICH
	tip_action.title = "Automatic Backup"
	tip_action.text = "Photos and videos are synced when connected to Wi-Fi."
	tip_action.action_text = "Manage settings"
	tip_action.enter_delay = 0.03
	tip_action.set_target(rich_target)
	stage.add(tip_action, Vector2(460, 174))
	tip_action.show_tooltip(false)

	var snap: Dictionary = await H.snapshot(stage, "communication.tooltip.rich", "variants_light")
	H.assert_snapshot(self, snap, [TOOLTIP_SCRIPT])

	var r_node: Dictionary = H.node_entry(snap, "RichTooltipWithAction")
	assert_gte(float(r_node.get("screen_rect", {}).get("width", 0.0)), 180.0, "rich tooltip width >= 180dp")
	assert_gte(float(r_node.get("screen_rect", {}).get("height", 0.0)), 80.0, "rich tooltip with action height >= 80dp")
	await H.assert_pixel(self, stage, stage.point_of(tip_body_only, Vector2(10, 10)), M3ThemeSingleton.get_instance().get_color(&"surface_container"), 0.08, "rich tooltip container = surface_container")
	H.cover(self, "communication.tooltip.rich", "element", snap)

	tip_action.hide_tooltip(false)
	await stage.settle()

	var live: Dictionary = await H.record(stage, "communication.tooltip.rich", "hover_open_and_click_action", func() -> void:
		await stage.hover(rich_target)
		await stage.wait(16)
		await stage.click(tip_action, tip_action.get_action_local_center())
		await stage.wait(12)
	, 6, tip_action)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "RichTooltipWithAction", "script_variables.action_click_count", 1)
	H.assert_mutated(self, live, "RichTooltipWithAction", "script_variables.is_open", false)
	H.assert_animated(self, live, "RichTooltipWithAction", "script_variables.open_progress", 4)
	H.cover(self, "communication.tooltip.rich", "interaction", live)
	H.cover(self, "communication.tooltip.rich", "animation", live)
	stage.dispose()

# ==============================================================================
# 8. communication.banner
# ==============================================================================

func test_communication_banner() -> void:
	var stage = await H.create_stage(self, "communication", "banner_variants", false)

	var banner_one := M3Banner.new()
	banner_one.name = "BannerOneAction"
	banner_one.message = "You are currently offline. Changes will sync when reconnected."
	banner_one.primary_action_label = "Retry now"
	banner_one.secondary_action_label = ""
	banner_one.show_icon = false
	stage.add(banner_one, Vector2(100, 90))

	var banner_two := M3Banner.new()
	banner_two.name = "BannerTwoActions"
	banner_two.message = "Your cloud storage is 92% full. Upgrade your plan or free up space."
	banner_two.primary_action_label = "Upgrade plan"
	banner_two.secondary_action_label = "Dismiss"
	banner_two.show_icon = true
	stage.add(banner_two, Vector2(100, 210))

	var snap: Dictionary = await H.snapshot(stage, "communication.banner", "variants_light")
	H.assert_snapshot(self, snap, [BANNER_SCRIPT])

	var b2_node: Dictionary = H.node_entry(snap, "BannerTwoActions")
	assert_gte(float(b2_node.get("screen_rect", {}).get("width", 0.0)), 400.0, "banner width >= 400dp")
	assert_gte(float(b2_node.get("screen_rect", {}).get("height", 0.0)), 72.0, "banner height >= 72dp")
	await H.assert_pixel(self, stage, stage.point_of(banner_one, Vector2(12, 12)), M3ThemeSingleton.get_instance().get_color(&"surface_container"), 0.08, "banner container = surface_container")
	H.cover(self, "communication.banner", "element", snap)

	var live: Dictionary = await H.record(stage, "communication.banner", "click_primary_and_dismiss", func() -> void:
		await stage.click(banner_two.get_primary_button())
		await stage.wait(6)
		await stage.click(banner_two.get_secondary_button())
		await stage.wait(14)
	, 6, banner_two)
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "BannerTwoActions", "script_variables.primary_click_count", 1)
	H.assert_mutated(self, live, "BannerTwoActions", "script_variables.secondary_click_count", 1)
	H.assert_mutated(self, live, "BannerTwoActions", "script_variables.is_open", false)
	H.assert_animated(self, live, "BannerTwoActions", "script_variables.open_progress", 4)
	H.cover(self, "communication.banner", "interaction", live)
	H.cover(self, "communication.banner", "animation", live)
	stage.dispose()

# ==============================================================================
# 9. communication.progress.wavy (Expressive Wavy Linear & Circular Progress)
# ==============================================================================

func test_communication_progress_wavy() -> void:
	var stage = await H.create_stage(self, "communication", "progress_wavy", false)

	var lin_wavy_det := M3LinearProgress.new()
	lin_wavy_det.name = "LinearWavyDeterminate"
	lin_wavy_det.wavy = true
	lin_wavy_det.size = Vector2(280, 12)
	lin_wavy_det.set_value_immediate(0.6)
	stage.add(lin_wavy_det, Vector2(100, 100))

	var lin_wavy_indet := M3LinearProgress.new()
	lin_wavy_indet.name = "LinearWavyIndeterminate"
	lin_wavy_indet.wavy = true
	lin_wavy_indet.indeterminate = true
	lin_wavy_indet.size = Vector2(280, 12)
	stage.add(lin_wavy_indet, Vector2(100, 160))

	var circ_wavy_det := M3CircularProgress.new()
	circ_wavy_det.name = "CircularWavyDeterminate"
	circ_wavy_det.wavy = true
	circ_wavy_det.size = Vector2(48, 48)
	circ_wavy_det.set_value_immediate(0.7)
	stage.add(circ_wavy_det, Vector2(100, 220))

	var circ_wavy_indet := M3CircularProgress.new()
	circ_wavy_indet.name = "CircularWavyIndeterminate"
	circ_wavy_indet.wavy = true
	circ_wavy_indet.indeterminate = true
	circ_wavy_indet.size = Vector2(48, 48)
	stage.add(circ_wavy_indet, Vector2(180, 220))

	var snap: Dictionary = await H.snapshot(stage, "communication.progress.wavy", "linear_and_circular_wavy")
	H.assert_snapshot(self, snap, [LINEAR_PROGRESS_SCRIPT, CIRCULAR_PROGRESS_SCRIPT])

	var lw_node: Dictionary = H.node_entry(snap, "LinearWavyDeterminate")
	assert_gte(float(lw_node.get("screen_rect", {}).get("height", 0.0)), 12.0, "wavy linear progress height >= 12dp")

	var cw_node: Dictionary = H.node_entry(snap, "CircularWavyDeterminate")
	assert_approx(float(cw_node.get("screen_rect", {}).get("width", 0.0)), 48.0, 0.5, "wavy circular progress width = 48dp")
	H.cover(self, "communication.progress.wavy", "element", snap)

	var live: Dictionary = await H.record(stage, "communication.progress.wavy", "animate_wave_phase", func() -> void:
		lin_wavy_det.set_value_animated(0.85, 0.2)
		await stage.wait(18)
	, 10, lin_wavy_det)
	H.assert_recording(self, live)
	H.assert_animated(self, live, "LinearWavyDeterminate", "script_variables._wave_phase", 6)
	H.assert_animated(self, live, "CircularWavyDeterminate", "script_variables._wave_phase", 6)
	H.cover(self, "communication.progress.wavy", "animation", live)
	stage.dispose()
