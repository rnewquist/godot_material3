# M3 GSS Verification Suites

Every Material 3 spec element in [`m3_spec_registry.gd`](m3_spec_registry.gd) must be **implemented** by the
library and **verified** with GSS (Godot Scene Snapshot, `res://addons/gdtest/core/gss.gd`) evidence produced by
a passing test in `res://tests/gss/test_gss_*.gd`.

## Run

```bash
G=/Applications/Godot.app/Contents/MacOS/Godot
# Windowed = real GPU screenshots -> res://artifacts/gss (authoritative evidence)
$G --path . --script res://tests/gss/gss_runner.gd
# One suite / one test
$G --path . --script res://tests/gss/gss_runner.gd -- --suite=res://tests/gss/test_gss_actions.gd --filter=test_fab
# Headless (synthetic previews, pixel checks skipped) -> res://artifacts/gss_headless
$G --headless --path . --script res://tests/gss/gss_runner.gd
```

A **full** run (no `--suite`/`--filter`) writes `index.html`, `M3_GSS_COVERAGE.md` and `coverage.json` to the
output root and FAILS unless every registry entry has all of its required evidence kinds from passing tests and
all of its `scripts` exist.

After adding a new `class_name` script, refresh the Godot global class cache:

```bash
$G --headless --path . --import
```

## Writing a suite (see `test_gss_harness.gd` for a complete example)

```gdscript
extends GDTestSuite
const H := preload("res://tests/gss/m3_gss_harness.gd")

func test_switch_toggle() -> void:
	var stage = await H.create_stage(self, "selection", "switch_toggle", false)   # family dir, scenario, dark?
	var sw := M3Switch.new(); sw.name = "WifiSwitch"
	stage.add(sw, Vector2(200, 200))

	# 1. element evidence: static snapshot of all variants
	var snap := await H.snapshot(stage, "selection.switch", "variants_light")
	H.assert_snapshot(self, snap, ["res://addons/material3/components/selection/m3_switch.gd"])
	await H.assert_pixel(self, stage, stage.point_of(sw, Vector2(10, 16)), M3ThemeSingleton.get_instance().get_color(&"outline"), 0.1, "unselected track outline")
	H.cover(self, "selection.switch", "element", snap)

	# 2/3. interaction + animation evidence: live recording driven by REAL input
	var live := await H.record(stage, "selection.switch", "toggle_on", func() -> void:
		await stage.click(sw)
		await stage.wait(20)
	, 10, sw)                                   # settle frames, focus control for filmstrip crop
	H.assert_recording(self, live)
	H.assert_mutated(self, live, "WifiSwitch", "script_variables.selected", true)
	H.assert_animated(self, live, "WifiSwitch", "script_variables._progress", 4)
	H.cover(self, "selection.switch", "interaction", live)
	H.cover(self, "selection.switch", "animation", live)
	stage.dispose()
```

### Stage API (`H.create_stage(...)` returns a `Stage`)
`add(control, pos)`, `point_of(control, local=center)`, `hover(c)`, `leave()`, `press(c)`, `release(c)`,
`click(c, local, hold_frames)`, `click_at(pos)`, `drag(c, from_local, to_local, steps)`, `drag_points(a, b)`,
`scroll(c, ticks, down)`, `key(keycode, pressed)`, `tap_key(keycode)`, `type_text("abc")` (focused control),
`wait(frames)`, `wait_sec(s)`, `settle()`, `sample(pos)->Color`, `refresh_background()`, `dispose()`.
All input is pushed through `SubViewport.push_input()`; coordinates are stage pixels (1280x720).

### Assertions / data
`assert_snapshot`, `assert_recording`, `assert_mutated(t, live, node_name, "category.prop", expected_final)`,
`assert_animated(t, live, node_name, "script_variables._prop", min_distinct)`, `assert_event(t, live, type, node, prop)`,
`assert_pixel(t, stage, pos, color, tol)` (skipped when headless), `assert_color_near`, `node_entry(snap, name)`,
`trajectory(live, name)`, `timeline(live, name, prop_path)`, `cover(t, spec_id(s), kind, res)`.

GSS observes: every script variable (including `_private` ones), `ui_and_content`, `visibility`, `transforms`
and `screen_rect` of every node under the stage root. Internal children (`add_child(..., INTERNAL_MODE_*)`) and
nodes outside the stage are NOT observed, so popups/overlays must be parented under the component's own viewport
(`get_viewport()`), never `get_tree().root`. Expose animation progress as script variables (e.g. `_progress`).

## Rules
* Drive interactions with real input via the stage, not private methods.
* Snapshots must cover every `variants` entry of the spec item; include at least one dark-mode snapshot per family.
* Assert spec geometry from GSS `screen_rect` (heights/widths/radii per m3.material.io) and key token colors via `assert_pixel`.
* Never weaken an assertion to make it pass: fix the component.
