# res://tests/gss/test_gss_harness.gd
## Self-test for the M3 GSS harness. Doubles as the reference example for GSS suite authors:
##   1. build a stage, 2. snapshot + assert_snapshot, 3. record a real input interaction,
##   4. assert GSS-observed mutations / animations / pixels, 5. cover() spec ids.
extends GDTestSuite

const H := preload("res://tests/gss/m3_gss_harness.gd")
const BUTTON_SCRIPT := "res://addons/material3/components/buttons/m3_button.gd"

func _init() -> void:
	suite_name = "GSS_Harness_SelfTest"
	test_type = "integration"

func test_artifact_name_is_stable() -> void:
	assert_eq(H.artifact_name("actions.button.common", "All Variants"), "actions.button.common__all_variants")
	assert_eq(H.artifact_name("x.y", "a/b"), "x.y__a_b")

func test_distinct_values_ignores_nulls_and_duplicates() -> void:
	assert_eq(H.distinct_values([null, 1, 1, 2, null, 3, 2]), [1, 2, 3])
	assert_eq(H.distinct_values([]), [])

func test_color_distance_is_max_channel_delta() -> void:
	assert_approx(H.color_distance(Color(0.1, 0.5, 0.9), Color(0.2, 0.5, 0.6)), 0.3, 0.0001)

func test_ledger_marks_and_computes_coverage() -> void:
	var saved: Array[Dictionary] = H.get_ledger().duplicate(true)
	H.clear_ledger()
	H.cover(self, "foundations.shape", "element", {"snapshot_name": "unit", "html_path": "res://x.html"})
	H.mark_test_result(get_script().resource_path, current_test_name, true)
	var cov: Dictionary = H.compute_coverage()
	var shape_item: Dictionary = {}
	for it in cov["items"]:
		if it["id"] == "foundations.shape":
			shape_item = it
	assert_true(bool(shape_item.get("verified", false)), "foundations.shape verified by passing element evidence")
	assert_false(bool(cov["complete"]), "registry is not complete from a single evidence entry")
	H.clear_ledger()
	for e in saved:
		H.get_ledger().append(e)

func test_stage_input_snapshot_and_live_recording_on_button() -> void:
	var stage = await H.create_stage(self, "harness", "harness_button", false)
	var btn := M3Button.new()
	btn.name = "ProbeButton"
	btn.text = "Probe"
	stage.add(btn, Vector2(200, 160))
	var presses: Array[int] = [0]
	btn.pressed.connect(func() -> void: presses[0] += 1)

	var snap: Dictionary = await H.snapshot(stage, "harness.self_test", "button_rest")
	assert_true(H.assert_snapshot(self, snap, [BUTTON_SCRIPT]), "snapshot valid")
	var rec_node: Dictionary = H.node_entry(snap, "ProbeButton")
	assert_eq(int(rec_node.get("script_variables", {}).get("current_state", -1)), M3Control.ControlState.NORMAL)

	# Rendered container must be the M3 primary color (regression: native get_theme_color shadowing).
	await H.assert_pixel(self, stage, stage.point_of(btn, Vector2(8, 20)), M3ThemeSingleton.get_instance().get_color(&"primary"), 0.08, "filled button container = primary")

	var live: Dictionary = await H.record(stage, "harness.self_test", "button_hover_press_release", func() -> void:
		await stage.hover(btn)
		await stage.wait(6)
		await stage.press(btn)
		await stage.wait(8)
		await stage.release(btn)
		await stage.wait(4)
		await stage.leave()
	, 20, btn)
	assert_true(H.assert_recording(self, live), "recording valid")
	# Click grants keyboard focus, so after the pointer leaves the button rests in FOCUSED.
	H.assert_mutated(self, live, "ProbeButton", "script_variables.current_state", M3Control.ControlState.FOCUSED)
	H.assert_event(self, live, "script_variable_changed", "ProbeButton", "current_state")
	H.assert_animated(self, live, "ProbeButton", "script_variables._current_elevation", 2)
	assert_eq(presses[0], 1, "pressed emitted exactly once for a click on an offset button (hit-test regression)")
	if H.is_rendering():
		assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(str(live.get("filmstrip_path", "")))), "filmstrip written")
	stage.dispose()
