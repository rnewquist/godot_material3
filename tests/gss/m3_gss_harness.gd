# res://tests/gss/m3_gss_harness.gd
## Shared GSS (Godot Scene Snapshot) verification harness for the Material 3 library.
##
## - Builds isolated 1280x720 SubViewport "stages" so input coordinates, screen rects and screenshots
##   are deterministic in both windowed and headless runs.
## - Injects real InputEvents (hover / press / release / drag / keys / wheel) through
##   Viewport.push_input() so components are exercised exactly as a user would.
## - Wraps GSS.capture() / GSS.record_interaction() with consistent artifact naming:
##     <output_root>/<family>/<spec_id>__<scenario>.{png,gss.json,gss.html}
##     <output_root>/<family>/<spec_id>__<scenario>.{gss.live.json,gss.live.html,filmstrip.png}
##   output_root = res://artifacts/gss (windowed, real GPU renders) or res://artifacts/gss_headless.
## - Provides GSS-backed assertions (snapshot validity, property mutation, multi-frame animation,
##   analysis events, rendered pixel colors) and a coverage ledger keyed by m3_spec_registry ids.
extends RefCounted

const GSSLib := preload("res://addons/gdtest/core/gss.gd")
const Registry := preload("res://tests/gss/m3_spec_registry.gd")

const STAGE_SIZE := Vector2i(1280, 720)
const RENDER_ROOT := "res://artifacts/gss"
const HEADLESS_ROOT := "res://artifacts/gss_headless"
const EVIDENCE_KINDS: Array[String] = ["element", "interaction", "animation"]
const FILMSTRIP_MAX_FRAMES := 12
const FILMSTRIP_THUMB_HEIGHT := 140

static var _ledger: Array[Dictionary] = []

# ==============================================================================
# ENVIRONMENT
# ==============================================================================

## True when a real rendering display server is active (windowed run). Pixel checks need this.
static func is_rendering() -> bool:
	return DisplayServer.get_name() != "headless"

## Root output directory for GSS artifacts in the current run mode.
static func output_root() -> String:
	return RENDER_ROOT if is_rendering() else HEADLESS_ROOT

static func output_dir(family: String) -> String:
	return output_root().path_join(family)

## Canonical artifact base name for a spec id + scenario.
static func artifact_name(spec_id: String, scenario: String) -> String:
	var s: String = scenario.strip_edges().to_lower().replace(" ", "_").replace("/", "_")
	return "%s__%s" % [spec_id, s]

# ==============================================================================
# STAGE
# ==============================================================================

## Isolated SubViewport test stage. All coordinates are SubViewport (canvas) coordinates.
class Stage extends RefCounted:
	var viewport: SubViewport = null
	var root: ColorRect = null
	var family: String = ""
	var suite: Node = null
	var mouse_pos: Vector2 = Vector2(-64, -64)
	var _buttons_down: int = 0

	## Adds a control to the stage root at an optional position. Returns the control.
	func add(c: Control, pos: Vector2 = Vector2.INF) -> Control:
		root.add_child(c)
		if pos != Vector2.INF:
			c.position = pos
		return c

	## Point in stage coordinates for a control (center by default, or a local offset).
	func point_of(c: Control, local: Vector2 = Vector2.INF) -> Vector2:
		var gr: Rect2 = c.get_global_rect()
		if local == Vector2.INF:
			return gr.position + gr.size * 0.5
		return gr.position + local

	func wait(frames: int = 1) -> void:
		for _i in range(maxi(1, frames)):
			await suite.get_tree().process_frame

	func wait_sec(seconds: float) -> void:
		await suite.get_tree().create_timer(seconds).timeout

	## Waits for layout + one fully drawn GPU frame (when rendering).
	func settle(frames: int = 3) -> void:
		await wait(frames)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

	## Returns the last rendered stage image (null when headless).
	func capture_image() -> Image:
		if DisplayServer.get_name() == "headless" or viewport == null:
			return null
		var tex: ViewportTexture = viewport.get_texture()
		if tex == null:
			return null
		var img: Image = tex.get_image()
		if img == null or img.is_empty():
			return null
		return img

	## Samples a rendered pixel in stage coordinates (Color(-1,-1,-1,-1) when headless).
	func sample(pos: Vector2) -> Color:
		if DisplayServer.get_name() == "headless":
			return Color(-1, -1, -1, -1)
		await RenderingServer.frame_post_draw
		var img: Image = capture_image()
		if img == null:
			return Color(-1, -1, -1, -1)
		var p := Vector2i(clampi(int(pos.x), 0, img.get_width() - 1), clampi(int(pos.y), 0, img.get_height() - 1))
		return img.get_pixelv(p)

	func refresh_background() -> void:
		if root:
			root.color = M3ThemeSingleton.get_instance().get_color(&"surface")

	# --- Input injection (Viewport.push_input) ---

	func move_to(pos: Vector2, steps: int = 1) -> void:
		var start: Vector2 = mouse_pos
		for i in range(1, maxi(1, steps) + 1):
			var p: Vector2 = start.lerp(pos, float(i) / float(maxi(1, steps)))
			var mm := InputEventMouseMotion.new()
			mm.position = p
			mm.global_position = p
			mm.relative = p - mouse_pos
			mm.button_mask = _buttons_down
			mouse_pos = p
			viewport.push_input(mm)
			await wait(1)

	func hover(c: Control, local: Vector2 = Vector2.INF) -> void:
		await move_to(point_of(c, local))
		await wait(1)

	## Moves the pointer off-stage so hovered controls receive mouse exit.
	func leave() -> void:
		await move_to(Vector2(-64, -64))
		await wait(1)

	func press_at(pos: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
		if mouse_pos != pos:
			await move_to(pos)
		var ev := InputEventMouseButton.new()
		ev.position = pos
		ev.global_position = pos
		ev.button_index = button
		ev.pressed = true
		_buttons_down |= (1 << (int(button) - 1))
		ev.button_mask = _buttons_down
		viewport.push_input(ev)
		await wait(1)

	func release_at(pos: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
		if mouse_pos != pos:
			await move_to(pos)
		var ev := InputEventMouseButton.new()
		ev.position = pos
		ev.global_position = pos
		ev.button_index = button
		ev.pressed = false
		_buttons_down &= ~(1 << (int(button) - 1))
		ev.button_mask = _buttons_down
		viewport.push_input(ev)
		await wait(1)

	func press(c: Control, local: Vector2 = Vector2.INF) -> void:
		await press_at(point_of(c, local))

	func release(c: Control, local: Vector2 = Vector2.INF) -> void:
		await release_at(point_of(c, local))

	## Full click: hover, press, hold `hold_frames`, release.
	func click(c: Control, local: Vector2 = Vector2.INF, hold_frames: int = 3) -> void:
		var p: Vector2 = point_of(c, local)
		await move_to(p)
		await press_at(p)
		await wait(hold_frames)
		await release_at(p)
		await wait(1)

	func click_at(pos: Vector2, hold_frames: int = 3) -> void:
		await move_to(pos)
		await press_at(pos)
		await wait(hold_frames)
		await release_at(pos)
		await wait(1)

	## Press at from, move in `steps` with the button held, release at to (stage coordinates).
	func drag_points(from_pos: Vector2, to_pos: Vector2, steps: int = 12) -> void:
		await move_to(from_pos)
		await press_at(from_pos)
		await move_to(to_pos, steps)
		await release_at(to_pos)
		await wait(1)

	func drag(c: Control, from_local: Vector2, to_local: Vector2, steps: int = 12) -> void:
		await drag_points(point_of(c, from_local), point_of(c, to_local), steps)

	func scroll(c: Control, ticks: int = 1, down: bool = true, local: Vector2 = Vector2.INF) -> void:
		var p: Vector2 = point_of(c, local)
		await move_to(p)
		var btn: MouseButton = MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
		for _i in range(maxi(1, ticks)):
			for pressed in [true, false]:
				var ev := InputEventMouseButton.new()
				ev.position = p
				ev.global_position = p
				ev.button_index = btn
				ev.pressed = pressed
				ev.factor = 1.0
				viewport.push_input(ev)
			await wait(1)

	func key(keycode: Key, pressed: bool = true, shift: bool = false, unicode: int = 0) -> void:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = pressed
		ev.shift_pressed = shift
		ev.unicode = unicode
		viewport.push_input(ev)
		await wait(1)

	func tap_key(keycode: Key, shift: bool = false) -> void:
		await key(keycode, true, shift)
		await key(keycode, false, shift)

	## Types text into the focused control (character events with unicode).
	func type_text(text: String) -> void:
		for ch in text:
			var code: int = ch.unicode_at(0)
			var kc: Key = OS.find_keycode_from_string(ch.to_upper()) if ch.strip_edges() != "" else KEY_SPACE
			await key(kc, true, ch != ch.to_lower(), code)
			await key(kc, false, ch != ch.to_lower(), 0)

	func dispose() -> void:
		if viewport and is_instance_valid(viewport):
			if viewport.get_parent():
				viewport.get_parent().remove_child(viewport)
			viewport.queue_free()

## Creates a stage in `suite` (a GDTestSuite). Sets light/dark mode explicitly.
static func create_stage(suite: Node, family: String, scenario: String, dark: bool = false, size: Vector2i = STAGE_SIZE) -> Stage:
	M3ThemeSingleton.get_instance().set_dark_mode(dark)
	var st := Stage.new()
	st.family = family
	st.suite = suite
	var vp := SubViewport.new()
	vp.name = "GSSStageViewport"
	vp.size = size
	vp.transparent_bg = false
	vp.handle_input_locally = true
	vp.gui_disable_input = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	suite.add_child(vp)
	if suite.has_method("autofree"):
		suite.call("autofree", vp)
	var bg := ColorRect.new()
	bg.name = scenario.to_pascal_case() if scenario != "" else "Stage"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.position = Vector2.ZERO
	bg.size = Vector2(size)
	bg.color = M3ThemeSingleton.get_instance().get_color(&"surface")
	vp.add_child(bg)
	st.viewport = vp
	st.root = bg
	await st.wait(2)
	return st

# ==============================================================================
# GSS CAPTURE & RECORDING
# ==============================================================================

## Captures a static GSS snapshot of the stage (PNG + JSON + interactive HTML).
static func snapshot(stage: Stage, spec_id: String, scenario: String) -> Dictionary:
	await stage.settle()
	var opts: Dictionary = {"output_dir": output_dir(stage.family)}
	var img: Image = stage.capture_image()
	if img != null:
		opts["image"] = img
	return GSSLib.capture(stage.root, artifact_name(spec_id, scenario), opts)

## Records a live GSS session around `interaction` (an async Callable) plus `settle_frames`.
## When rendering, also writes a filmstrip PNG (cropped to `focus` if given) showing the motion.
static func record(stage: Stage, spec_id: String, scenario: String, interaction: Callable, settle_frames: int = 20, focus: Control = null) -> Dictionary:
	await stage.settle()
	var name: String = artifact_name(spec_id, scenario)
	var opts: Dictionary = {"output_dir": output_dir(stage.family), "step_mode": "process"}
	var img: Image = stage.capture_image()
	if img != null:
		opts["image"] = img
	var strip := _FilmstripHook.new()
	strip.stage = stage
	var crop := Rect2(Vector2.ZERO, Vector2(stage.viewport.size))
	if focus != null and is_instance_valid(focus):
		crop = focus.get_global_rect().grow(24.0).intersection(crop)
	strip.crop = crop
	strip.name = "GSSFilmstripHook"
	stage.suite.add_child(strip)
	var res: Dictionary = await GSSLib.record_interaction(stage.root, interaction, settle_frames, name, opts)
	strip.active = false
	if res.get("success", false) and is_rendering():
		var fs_path: String = output_dir(stage.family).path_join(name + ".filmstrip.png")
		if strip.write(ProjectSettings.globalize_path(fs_path)):
			res["filmstrip_path"] = fs_path
		if OS.get_environment("M3_EXPORT_GIF_FRAMES") == "1":
			var frame_dir: String = output_root().path_join("_gif_frames").path_join(stage.family).path_join(name)
			if strip.write_gif_frames(ProjectSettings.globalize_path(frame_dir)):
				res["gif_path"] = output_dir(stage.family).path_join(name + ".gif")
	if strip.get_parent():
		strip.get_parent().remove_child(strip)
	strip.free()
	return res

## Collects stage frames during a recording and composes them into a single filmstrip PNG.
class _FilmstripHook extends Node:
	var stage = null
	var crop: Rect2 = Rect2()
	var active: bool = true
	var frames: Array[Image] = []
	var _tick: int = 0

	func _process(_delta: float) -> void:
		if not active or stage == null or DisplayServer.get_name() == "headless":
			return
		_tick += 1
		if _tick % 2 != 0:
			return
		var img: Image = stage.capture_image()
		if img == null:
			return
		var r := Rect2i(crop)
		if r.size.x <= 0 or r.size.y <= 0:
			return
		frames.append(img.get_region(r))

	func write(global_path: String) -> bool:
		if frames.is_empty():
			return false
		var picks: Array[Image] = []
		var n: int = mini(frames.size(), 12)
		for i in range(n):
			var idx: int = int(round(float(i) * float(frames.size() - 1) / float(maxi(1, n - 1))))
			picks.append(frames[idx])
		var th: int = 140
		var thumbs: Array[Image] = []
		var total_w: int = 0
		for p in picks:
			var t: Image = p.duplicate()
			var tw: int = maxi(1, int(round(float(t.get_width()) * float(th) / float(maxi(1, t.get_height())))))
			t.resize(tw, th, Image.INTERPOLATE_BILINEAR)
			t.convert(Image.FORMAT_RGBA8)
			thumbs.append(t)
			total_w += tw + 4
		var out := Image.create(maxi(1, total_w), th, false, Image.FORMAT_RGBA8)
		out.fill(Color(0.1, 0.1, 0.12, 1.0))
		var x: int = 0
		for t in thumbs:
			out.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(x, 0))
			x += t.get_width() + 4
		return out.save_png(global_path) == OK

	func write_gif_frames(global_dir: String, max_frames: int = 24, max_dim: int = 640) -> bool:
		if frames.is_empty():
			return false
		DirAccess.make_dir_recursive_absolute(global_dir)
		var n: int = mini(frames.size(), max_frames)
		for i in range(n):
			var idx: int = int(round(float(i) * float(frames.size() - 1) / float(maxi(1, n - 1))))
			var img: Image = frames[idx].duplicate()
			var w: int = img.get_width()
			var h: int = img.get_height()
			if w > max_dim or h > max_dim:
				var sc: float = minf(float(max_dim) / float(w), float(max_dim) / float(h))
				img.resize(maxi(1, int(round(float(w) * sc))), maxi(1, int(round(float(h) * sc))), Image.INTERPOLATE_BILINEAR)
			img.convert(Image.FORMAT_RGBA8)
			img.save_png(global_dir.path_join("frame_%03d.png" % i))
		return true

# ==============================================================================
# GSS DATA ACCESS
# ==============================================================================

## Returns the flat node record named `node_name` from a snapshot result (or {}).
static func node_entry(snapshot_res: Dictionary, node_name: String) -> Dictionary:
	var data: Dictionary = snapshot_res.get("data", snapshot_res)
	for n in data.get("flat_nodes", []):
		if str(n.get("name", "")) == node_name:
			return n
	return {}

## Finds the live-analysis trajectory for node `node_name` (or {}).
static func trajectory(rec_res: Dictionary, node_name: String) -> Dictionary:
	var trajs: Dictionary = rec_res.get("analysis", {}).get("node_trajectories", {})
	for p in trajs.keys():
		var tr: Dictionary = trajs[p]
		if str(tr.get("name", "")) == node_name or str(p).ends_with("/" + node_name):
			return tr
	return {}

## Per-frame values of `prop_path` (e.g. "script_variables._progress") for `node_name`.
static func timeline(rec_res: Dictionary, node_name: String, prop_path: String) -> Array:
	var out: Array = []
	for e in GSSLib.get_node_timeline(rec_res, node_name, prop_path):
		out.append(e.get("value"))
	return out

static func distinct_values(values: Array) -> Array:
	var seen: Array = []
	for v in values:
		if v == null:
			continue
		if not seen.has(v):
			seen.append(v)
	return seen

# ==============================================================================
# ASSERTIONS (t = GDTestSuite)
# ==============================================================================

## Validates a GSS snapshot: files written, schema, real render (when windowed) and that every
## script in `expect_scripts` is present, visible and has on-screen bounds.
static func assert_snapshot(t: Node, res: Dictionary, expect_scripts: Array = [], msg: String = "") -> bool:
	var tag: String = msg if msg != "" else str(res.get("snapshot_name", "snapshot"))
	if not t.assert_true(bool(res.get("success", false)), "[GSS] capture succeeded: %s" % tag):
		return false
	var ok: bool = true
	for k in ["global_png_path", "global_json_path", "global_html_path"]:
		ok = t.assert_true(FileAccess.file_exists(str(res.get(k, ""))), "[GSS] %s written for %s" % [k, tag]) and ok
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(res.get("global_json_path", ""))))
	ok = t.assert_true(parsed is Dictionary, "[GSS] JSON parses for %s" % tag) and ok
	if parsed is Dictionary:
		var meta: Dictionary = parsed.get("metadata", {})
		ok = t.assert_eq(str(meta.get("format", "")), "godot_scene_snapshot", "[GSS] format id for %s" % tag) and ok
		ok = t.assert_eq((parsed.get("flat_nodes", []) as Array).size(), int(meta.get("total_nodes", -1)), "[GSS] node count consistent for %s" % tag) and ok
		if is_rendering():
			ok = t.assert_false(bool(meta.get("is_synthetic_preview", true)), "[GSS] real GPU screenshot for %s" % tag) and ok
	var data: Dictionary = res.get("data", {})
	for sp in expect_scripts:
		var found: bool = false
		for n in data.get("flat_nodes", []):
			if str(n.get("script", "")) == str(sp) and bool(n.get("visible", false)):
				var sr: Dictionary = n.get("screen_rect", {})
				if float(sr.get("width", 0.0)) > 0.0 and float(sr.get("height", 0.0)) > 0.0:
					found = true
					break
		ok = t.assert_true(found, "[GSS] %s visible with bounds in %s" % [str(sp).get_file(), tag]) and ok
	return ok

## Validates a live GSS recording result (files + schema + at least one delta frame).
static func assert_recording(t: Node, res: Dictionary, msg: String = "") -> bool:
	var tag: String = msg if msg != "" else str(res.get("recording_name", "recording"))
	if not t.assert_true(bool(res.get("success", false)), "[GSS] recording succeeded: %s" % tag):
		return false
	var ok: bool = true
	for k in ["global_json_path", "global_html_path"]:
		ok = t.assert_true(FileAccess.file_exists(str(res.get(k, ""))), "[GSS] %s written for %s" % [k, tag]) and ok
	var data: Dictionary = res.get("data", {})
	ok = t.assert_eq(str(data.get("format", "")), "godot_scene_snapshot_live", "[GSS] live format id for %s" % tag) and ok
	ok = t.assert_gt(float(res.get("delta_frames", 0)), 0.0, "[GSS] recorded delta frames for %s" % tag) and ok
	return ok

## Asserts GSS analysis saw `prop_path` change on `node_name`; optionally checks the final value.
static func assert_mutated(t: Node, rec_res: Dictionary, node_name: String, prop_path: String, expected_final: Variant = null, msg: String = "") -> bool:
	var tr: Dictionary = trajectory(rec_res, node_name)
	var muts: Dictionary = tr.get("mutated_properties", {})
	var tag: String = msg if msg != "" else "%s.%s" % [node_name, prop_path]
	if not t.assert_true(muts.has(prop_path), "[GSS] %s mutated (seen: %s)" % [tag, str(muts.keys())]):
		return false
	if expected_final == null:
		return true
	var fin: Variant = muts[prop_path].get("final")
	if (expected_final is float or expected_final is int) and (fin is float or fin is int):
		return t.assert_approx(float(fin), float(expected_final), 0.01, "[GSS] %s final value" % tag)
	return t.assert_eq(fin, expected_final, "[GSS] %s final value" % tag)

## Asserts `prop_path` on `node_name` took at least `min_distinct` distinct values across recorded
## frames, i.e. it was animated (tweened through intermediate frames) rather than jumping.
static func assert_animated(t: Node, rec_res: Dictionary, node_name: String, prop_path: String, min_distinct: int = 4, msg: String = "") -> Array:
	var values: Array = timeline(rec_res, node_name, prop_path)
	var d: Array = distinct_values(values)
	var tag: String = msg if msg != "" else "%s.%s" % [node_name, prop_path]
	t.assert_gte(float(d.size()), float(min_distinct), "[GSS] %s animated over frames (%d distinct values: %s)" % [tag, d.size(), str(d.slice(0, 8))])
	return values

## Asserts the GSS analysis contains an event of `type` (optionally for node / property).
static func assert_event(t: Node, rec_res: Dictionary, type: String, node_name: String = "", property: String = "", msg: String = "") -> bool:
	for e in rec_res.get("analysis", {}).get("events", []):
		if str(e.get("type", "")) != type:
			continue
		if node_name != "" and str(e.get("node_name", "")) != node_name and not str(e.get("node_path", "")).ends_with("/" + node_name):
			continue
		if property != "" and str(e.get("property", "")) != property:
			continue
		return t.assert_true(true, msg)
	return t.assert_true(false, "[GSS] event %s %s %s %s" % [type, node_name, property, msg])

static func color_distance(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))

static func assert_color_near(t: Node, actual: Color, expected: Color, tol: float = 0.06, msg: String = "") -> bool:
	return t.assert_lte(color_distance(actual, expected), tol, "%s (actual %s, expected %s)" % [msg, actual.to_html(false), expected.to_html(false)])

## Samples the rendered stage at `pos` and compares to `expected`. Skips (passes) when headless.
static func assert_pixel(t: Node, stage: Stage, pos: Vector2, expected: Color, tol: float = 0.08, msg: String = "") -> bool:
	if not is_rendering():
		return true
	var c: Color = await stage.sample(pos)
	return assert_color_near(t, c, expected, tol, "[GSS pixel] " + msg)

# ==============================================================================
# COVERAGE LEDGER
# ==============================================================================

## Records that GSS result `res` is `kind` evidence for spec id(s). Call after asserting `res`.
static func cover(t: Node, spec_ids: Variant, kind: String, res: Dictionary, note: String = "") -> void:
	var ids: Array = spec_ids if spec_ids is Array else [spec_ids]
	t.assert_true(EVIDENCE_KINDS.has(kind), "[GSS] valid evidence kind '%s'" % kind)
	for sid in ids:
		t.assert_true(Registry.has_id(str(sid)), "[GSS] spec id '%s' exists in m3_spec_registry" % str(sid))
		_ledger.append({
			"spec_id": str(sid),
			"kind": kind,
			"suite": str(t.get_script().resource_path) if t.get_script() else str(t.name),
			"test": str(t.get("current_test_name")),
			"name": str(res.get("snapshot_name", res.get("recording_name", ""))),
			"png": str(res.get("png_path", "")),
			"json": str(res.get("json_path", "")),
			"html": str(res.get("html_path", "")),
			"filmstrip": str(res.get("filmstrip_path", "")),
			"note": note,
			"passed": null
		})

static func get_ledger() -> Array[Dictionary]:
	return _ledger

static func clear_ledger() -> void:
	_ledger.clear()

## Called by the GSS runner after each test to stamp pass/fail on that test's evidence.
static func mark_test_result(suite_path: String, test_name: String, passed: bool) -> void:
	for e in _ledger:
		if e["suite"] == suite_path and e["test"] == test_name and e["passed"] == null:
			e["passed"] = passed

## Computes per-spec coverage from the ledger. Returns {complete, items:[...], missing:[...]}.
static func compute_coverage() -> Dictionary:
	var items: Array = []
	var missing: Array = []
	for entry in Registry.get_entries():
		var sid: String = str(entry["id"])
		var have: Dictionary = {}
		var evidence: Array = []
		for e in _ledger:
			if e["spec_id"] == sid:
				evidence.append(e)
				if e["passed"] == true:
					have[e["kind"]] = true
		var missing_scripts: Array = []
		for sp in entry["scripts"]:
			if not FileAccess.file_exists(str(sp)):
				missing_scripts.append(str(sp))
		var missing_kinds: Array = []
		for k in entry["requires"]:
			if not have.has(k):
				missing_kinds.append(k)
		var ok: bool = missing_kinds.is_empty() and missing_scripts.is_empty()
		var item: Dictionary = {
			"id": sid, "category": entry["category"], "name": entry["name"], "spec": entry["spec"],
			"variants": entry["variants"], "requires": entry["requires"], "verified": ok,
			"missing_kinds": missing_kinds, "missing_scripts": missing_scripts, "evidence": evidence
		}
		items.append(item)
		if not ok:
			missing.append(item)
	return {"complete": missing.is_empty(), "items": items, "missing": missing}

## Writes coverage.json, M3_GSS_COVERAGE.md and index.html into the output root.
static func write_coverage_report() -> Dictionary:
	var cov: Dictionary = compute_coverage()
	var root: String = output_root()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
	var meta: Dictionary = {
		"generated": Time.get_datetime_string_from_system(true),
		"rendering": is_rendering(),
		"display_server": DisplayServer.get_name(),
		"engine": str(Engine.get_version_info().get("string", "")),
		"total": (cov["items"] as Array).size(),
		"verified": (cov["items"] as Array).size() - (cov["missing"] as Array).size()
	}
	cov["meta"] = meta
	_write(root.path_join("coverage.json"), JSON.stringify(cov, "  ", false))
	_write(root.path_join("M3_GSS_COVERAGE.md"), _coverage_markdown(cov))
	_write(root.path_join("index.html"), _coverage_html(cov))
	return cov

static func _write(res_path: String, text: String) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(res_path), FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()

static func _rel(res_path: String) -> String:
	var prefix: String = output_root() + "/"
	return res_path.substr(prefix.length()) if res_path.begins_with(prefix) else res_path

static func _coverage_markdown(cov: Dictionary) -> String:
	var meta: Dictionary = cov["meta"]
	var lines: PackedStringArray = []
	lines.append("# Material 3 GSS Verification Coverage")
	lines.append("")
	lines.append("Generated %s · %s · rendering=%s · **%d/%d spec elements verified**" % [meta["generated"], meta["engine"], str(meta["rendering"]), meta["verified"], meta["total"]])
	lines.append("")
	for cat in Registry.get_categories():
		lines.append("## " + cat)
		lines.append("")
		lines.append("| Spec element | Status | Evidence | Missing |")
		lines.append("|---|---|---|---|")
		for it in cov["items"]:
			if it["category"] != cat:
				continue
			var kinds: Dictionary = {}
			for e in it["evidence"]:
				if e["passed"] == true:
					kinds[e["kind"]] = int(kinds.get(e["kind"], 0)) + 1
			var ev: PackedStringArray = []
			for k in kinds.keys():
				ev.append("%s×%d" % [k, kinds[k]])
			var miss: Array = (it["missing_kinds"] as Array) + (it["missing_scripts"] as Array)
			lines.append("| [%s](%s) `%s` | %s | %s | %s |" % [it["name"], it["spec"], it["id"], "✅" if it["verified"] else "❌", ", ".join(ev), ", ".join(PackedStringArray(miss))])
		lines.append("")
	return "\n".join(lines)

static func _coverage_html(cov: Dictionary) -> String:
	var meta: Dictionary = cov["meta"]
	var h: PackedStringArray = []
	h.append("<!doctype html><html><head><meta charset='utf-8'><title>M3 GSS Coverage</title><style>")
	h.append("body{font-family:system-ui,-apple-system,sans-serif;background:#141218;color:#e6e0e9;margin:0;padding:24px}")
	h.append("h1{font-weight:500}h2{margin-top:32px;color:#d0bcff;font-weight:500}.sum{color:#cac4d0}")
	h.append(".grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:16px}")
	h.append(".card{background:#1d1b20;border:1px solid #49454f;border-radius:16px;padding:16px}")
	h.append(".ok{color:#7ee2a8}.bad{color:#ffb4ab}.k{display:inline-block;padding:2px 8px;border-radius:8px;background:#4a4458;margin:2px;font-size:12px}")
	h.append("img{max-width:100%;border-radius:8px;margin-top:8px;border:1px solid #49454f}a{color:#d0bcff}ul{padding-left:18px;font-size:13px}")
	h.append("</style></head><body>")
	h.append("<h1>Material 3 · GSS Verification</h1><div class='sum'>%s · %s · rendering=%s · <b>%d/%d</b> spec elements verified</div>" % [meta["generated"], meta["engine"], str(meta["rendering"]), meta["verified"], meta["total"]])
	for cat in Registry.get_categories():
		h.append("<h2>%s</h2><div class='grid'>" % cat)
		for it in cov["items"]:
			if it["category"] != cat:
				continue
			h.append("<div class='card'><div><b>%s</b> <span class='%s'>%s</span></div>" % [it["name"], "ok" if it["verified"] else "bad", "✔ verified" if it["verified"] else "✘ incomplete"])
			h.append("<div><a href='%s' target='_blank'>spec</a> · <code>%s</code></div><div>" % [it["spec"], it["id"]])
			for k in it["requires"]:
				h.append("<span class='k'>%s%s</span>" % [k, "" if (it["missing_kinds"] as Array).has(k) else " ✔"])
			h.append("</div>")
			var thumb_done: bool = false
			h.append("<ul>")
			for e in it["evidence"]:
				var link: String = _rel(str(e["html"]))
				h.append("<li>%s <a href='%s' target='_blank'>%s</a> %s</li>" % [e["kind"], link, e["name"], "" if e["passed"] == true else "<span class='bad'>(failed)</span>"])
			h.append("</ul>")
			for e in it["evidence"]:
				if e["passed"] == true and e["kind"] == "element" and str(e["png"]) != "" and not thumb_done:
					h.append("<img loading='lazy' src='%s'>" % _rel(str(e["png"])))
					thumb_done = true
			for e in it["evidence"]:
				if e["passed"] == true and str(e["filmstrip"]) != "":
					h.append("<img loading='lazy' title='%s' src='%s'>" % [e["name"], _rel(str(e["filmstrip"]))])
					break
			if not (it["missing_scripts"] as Array).is_empty():
				h.append("<div class='bad'>missing scripts: %s</div>" % ", ".join(PackedStringArray(it["missing_scripts"])))
			h.append("</div>")
		h.append("</div>")
	h.append("</body></html>")
	return "\n".join(h)
