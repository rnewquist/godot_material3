extends SceneTree

## Captures 21 additional high-resolution GPU frame sequences under res://docs/gifs/_frames/<name>/
## to be encoded into looping animated GIFs by tools/encode_gss_gifs.swift:
##   Hero & IDE Reels (3):
##     1. hero_expressive_gallery
##     2. hero_ide_live_tweaking
##     3. hero_showcase_tour
##   Foundations (7):
##     4. foundations_color_palettes_cycle
##     5. foundations_9_scheme_variants
##     6. foundations_shape_radius_sweep
##     7. foundations_35_shapes_morph_loop
##     8. foundations_elevation_lift_0_to_5
##     9. foundations_spatial_vs_effects_springs
##    10. foundations_typography_baseline_vs_emphasized
##   Component Category Reels (11):
##    11. actions_all_buttons_dark_wave
##    12. actions_fab_menu_and_split_dark
##    13. communication_wavy_and_loaders_dark
##    14. communication_snackbar_banner_tooltip_flow
##    15. containment_carousel_hero_and_cards_dark
##    16. containment_sheets_and_dialogs_flow
##    17. containment_divider_modes_cycle
##    18. navigation_responsive_breakpoints_resize
##    19. navigation_app_bars_and_toolbars_dark
##    20. selection_controls_symphony_dark
##    21. selection_24h_time_and_year_date_pickers

const FRAMES_ROOT := "res://docs/gifs/_gif_frames/showcase"
const ShowcaseScene := preload("res://scenes/showcase/showcase_main.tscn")

func _init() -> void:
	_run.call_deferred()

func _make_vp(sz: Vector2i) -> Dictionary:
	var vp := SubViewport.new()
	vp.size = sz
	vp.transparent_bg = false
	vp.handle_input_locally = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var bg := ColorRect.new()
	bg.size = Vector2(sz)
	bg.color = M3ThemeSingleton.get_instance().get_color(&"surface")
	vp.add_child(bg)
	return {"vp": vp, "bg": bg}

func _snap_frame(vp: SubViewport, dir_global: String, idx: int, max_dim: int = 640) -> void:
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	if img == null or img.is_empty():
		return
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w > max_dim or h > max_dim:
		var sc: float = minf(float(max_dim) / float(w), float(max_dim) / float(h))
		img.resize(maxi(1, int(round(float(w) * sc))), maxi(1, int(round(float(h) * sc))), Image.INTERPOLATE_BILINEAR)
	img.convert(Image.FORMAT_RGBA8)
	img.save_png(dir_global.path_join("frame_%03d.png" % idx))

func _capture_sequence(seq_name: String, sz: Vector2i, dark: bool, runner: Callable, max_dim: int = 640) -> void:
	M3ThemeSingleton.get_instance().set_seed_color(M3PaletteGenerator.PRESET_BASELINE_INDIGO)
	M3ThemeSingleton.get_instance().set_contrast_level(0.0)
	M3ThemeSingleton.get_instance().set_scheme_variant(M3PaletteGenerator.SchemeVariant.TONAL_SPOT)
	M3ThemeSingleton.get_instance().set_visual_density(0)
	M3ThemeSingleton.get_instance().set_dark_mode(dark)

	var dir_global: String = ProjectSettings.globalize_path(FRAMES_ROOT.path_join(seq_name))
	DirAccess.make_dir_recursive_absolute(dir_global)

	var bundle := _make_vp(sz)
	var vp: SubViewport = bundle["vp"]
	var bg: ColorRect = bundle["bg"]
	await process_frame
	await process_frame

	await runner.call(vp, bg, dir_global, max_dim)

	vp.queue_free()
	await process_frame
	print("Captured GIF sequence: ", seq_name)

func _run() -> void:
	await _capture_sequence("hero_expressive_gallery", Vector2i(800, 480), false, _seq_hero_expressive, 640)
	await _capture_sequence("hero_ide_live_tweaking", Vector2i(800, 500), false, _seq_hero_ide_live, 640)
	await _capture_sequence("hero_showcase_tour", Vector2i(960, 600), true, _seq_hero_showcase_tour, 640)
	await _capture_sequence("foundations_color_palettes_cycle", Vector2i(760, 400), false, _seq_color_palettes_cycle, 600)
	await _capture_sequence("foundations_9_scheme_variants", Vector2i(760, 380), false, _seq_9_scheme_variants, 600)
	await _capture_sequence("foundations_shape_radius_sweep", Vector2i(640, 340), false, _seq_shape_radius_sweep, 560)
	await _capture_sequence("foundations_35_shapes_morph_loop", Vector2i(640, 360), true, _seq_35_shapes_morph_loop, 560)
	await _capture_sequence("foundations_elevation_lift_0_to_5", Vector2i(640, 340), false, _seq_elevation_lift, 560)
	await _capture_sequence("foundations_spatial_vs_effects_springs", Vector2i(720, 380), false, _seq_spatial_vs_effects, 600)
	await _capture_sequence("foundations_typography_baseline_vs_emphasized", Vector2i(720, 380), false, _seq_typography_toggle, 600)
	await _capture_sequence("actions_all_buttons_dark_wave", Vector2i(760, 400), true, _seq_actions_buttons_dark, 600)
	await _capture_sequence("actions_fab_menu_and_split_dark", Vector2i(720, 440), true, _seq_actions_fab_split_dark, 600)
	await _capture_sequence("communication_wavy_and_loaders_dark", Vector2i(720, 380), true, _seq_comm_wavy_dark, 600)
	await _capture_sequence("communication_snackbar_banner_tooltip_flow", Vector2i(760, 420), false, _seq_comm_overlays_flow, 600)
	await _capture_sequence("containment_carousel_hero_and_cards_dark", Vector2i(760, 420), true, _seq_containment_carousel_dark, 600)
	await _capture_sequence("containment_sheets_and_dialogs_flow", Vector2i(760, 440), false, _seq_containment_sheets_flow, 600)
	await _capture_sequence("containment_divider_modes_cycle", Vector2i(640, 320), false, _seq_containment_divider_cycle, 560)
	await _capture_sequence("navigation_responsive_breakpoints_resize", Vector2i(840, 460), false, _seq_nav_responsive_resize, 640)
	await _capture_sequence("navigation_app_bars_and_toolbars_dark", Vector2i(760, 420), true, _seq_nav_bars_toolbars_dark, 600)
	await _capture_sequence("selection_controls_symphony_dark", Vector2i(760, 420), true, _seq_selection_symphony_dark, 600)
	await _capture_sequence("selection_24h_time_and_year_date_pickers", Vector2i(760, 460), false, _seq_pickers_24h_year, 600)
	quit(0)

# 1. Hero M3 Expressive Gallery
func _seq_hero_expressive(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var scheme := M3ThemeSingleton.get_scheme()
	var title := Label.new()
	title.text = "Material 3 Expressive (2025) — Live Motion Showcase"
	title.position = Vector2(24, 14)
	M3Typography.apply_to_label(title, M3Typography.Role.TITLE_LARGE_EMPHASIZED, scheme.on_surface)
	bg.add_child(title)

	var wavy_l := M3LinearProgress.new()
	wavy_l.wavy = true
	wavy_l.set_value_immediate(0.72)
	wavy_l.position = Vector2(24, 62)
	wavy_l.size = Vector2(360, 18)
	bg.add_child(wavy_l)

	var wavy_c := M3CircularProgress.new()
	wavy_c.wavy = true
	wavy_c.set_value_immediate(0.78)
	wavy_c.position = Vector2(408, 46)
	bg.add_child(wavy_c)

	var loader1 := M3LoadingIndicator.new()
	loader1.contained = true
	loader1.position = Vector2(484, 46)
	bg.add_child(loader1)

	var loader2 := M3LoadingIndicator.new()
	loader2.contained = false
	loader2.position = Vector2(548, 46)
	bg.add_child(loader2)

	var morph := M3ShapeMorph.new()
	morph.from_shape = M3Shapes.MaterialShape.COOKIE_4
	morph.to_shape = M3Shapes.MaterialShape.VERY_SUNNY
	morph.label_text = "MORPH"
	morph.position = Vector2(640, 32)
	morph.size = Vector2(124, 124)
	bg.add_child(morph)

	var split := M3SplitButton.new()
	split.text = "Expressive"
	split.leading_icon = &"send"
	split.add_menu_item("Spatial Spring")
	split.add_menu_item("Wavy Track")
	split.add_menu_item("35 Shapes")
	split.position = Vector2(24, 114)
	bg.add_child(split)

	var trans := M3Transition.new()
	trans.pattern = M3Motion.TransitionPattern.CONTAINER_TRANSFORM
	trans.outgoing_label = "Card"
	trans.incoming_label = "Spatial Spring Transform"
	trans.position = Vector2(24, 240)
	trans.size = Vector2(360, 160)
	trans.expanded_rect = Rect2(14, 14, 330, 130)
	bg.add_child(trans)

	var v_slider := M3Slider.new()
	v_slider.orientation = M3Slider.Orientation.VERTICAL
	v_slider.centered_zero = true
	v_slider.min_value = -100.0
	v_slider.max_value = 100.0
	v_slider.value = -50.0
	v_slider.slider_size = M3Slider.SliderSize.LARGE
	v_slider.position = Vector2(416, 174)
	v_slider.size = Vector2(56, 226)
	bg.add_child(v_slider)

	var carousel := M3Carousel.new()
	carousel.carousel_style = M3Carousel.CarouselStyle.MULTI_BROWSE
	carousel.add_item("Springs", "Spatial & Effects", scheme.primary_container)
	carousel.add_item("Shapes", "35 Polygons", scheme.tertiary_container)
	carousel.add_item("Wavy", "Sine Track", scheme.secondary_container)
	carousel.position = Vector2(492, 184)
	carousel.size = Vector2(284, 216)
	bg.add_child(carousel)

	for i in range(24):
		if i == 3:
			morph.morph_to(M3Shapes.MaterialShape.VERY_SUNNY, 0.35, 0.6)
			trans.play_transition(true, 0.45)
			split.set_menu_open(true)
			carousel.scroll_to_index(1, true)
		elif i == 12:
			morph.morph_to(M3Shapes.MaterialShape.HEART, 0.35, 0.6)
			carousel.scroll_to_index(2, true)
		elif i == 18:
			split.set_menu_open(false)
			trans.play_transition(false, 0.35)
		v_slider.value = lerpf(-75.0, 85.0, float(i) / 23.0)
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 2. Hero IDE Live Tweaking
func _seq_hero_ide_live(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	bg.color = Color("#1D2229")
	var canvas_panel := Panel.new()
	canvas_panel.position = Vector2(18, 48)
	canvas_panel.size = Vector2(480, 434)
	bg.add_child(canvas_panel)

	var top_bar := Label.new()
	top_bar.position = Vector2(20, 14)
	top_bar.text = "Godot 4.x Editor · 2D @tool Live Viewport  |  Inspector Live Theme & Variant Tweaking"
	top_bar.add_theme_color_override(&"font_color", Color("#8EEF97"))
	bg.add_child(top_bar)

	var insp_box := VBoxContainer.new()
	insp_box.position = Vector2(514, 52)
	insp_box.size = Vector2(268, 420)
	insp_box.add_theme_constant_override("separation", 10)
	bg.add_child(insp_box)

	var insp_hdr := Label.new()
	insp_hdr.text = "Inspector — Live @export Updates"
	insp_hdr.add_theme_color_override(&"font_color", Color("#478CBF"))
	insp_box.add_child(insp_hdr)

	var insp_status := Label.new()
	insp_status.add_theme_font_size_override(&"font_size", 13)
	insp_status.add_theme_color_override(&"font_color", Color("#E0E5EC"))
	insp_box.add_child(insp_status)

	var card := M3Card.new()
	card.card_type = M3Card.CardType.ELEVATED
	card.position = Vector2(24, 24)
	card.size = Vector2(432, 386)
	canvas_panel.add_child(card)

	var inner := Control.new()
	inner.size = Vector2(400, 354)
	card.add_child(inner)

	var btn := M3Button.new()
	btn.text = "Live @tool Button"
	btn.leading_icon = &"send"
	btn.button_size = M3Button.ButtonSize.MEDIUM
	btn.position = Vector2(16, 20)
	inner.add_child(btn)

	var gizmo := ReferenceRect.new()
	gizmo.editor_only = false
	gizmo.border_color = Color("#FF8426")
	gizmo.border_width = 2.0
	gizmo.position = Vector2(12, 16)
	gizmo.size = Vector2(226, 64)
	inner.add_child(gizmo)

	var tf := M3TextField.new()
	tf.variant = M3TextField.Variant.OUTLINED
	tf.label_text = "Project Title"
	tf.text = "Material 3 Godot"
	tf.position = Vector2(16, 108)
	tf.size = Vector2(360, 56)
	inner.add_child(tf)

	var sw := M3Switch.new()
	sw.selected = true
	sw.show_icons = true
	sw.position = Vector2(16, 196)
	inner.add_child(sw)

	var sl := M3Slider.new()
	sl.slider_size = M3Slider.SliderSize.MEDIUM
	sl.value = 65.0
	sl.position = Vector2(96, 196)
	sl.size = Vector2(280, 44)
	inner.add_child(sl)

	var wavy := M3LinearProgress.new()
	wavy.wavy = true
	wavy.set_value_immediate(0.70)
	wavy.position = Vector2(16, 272)
	wavy.size = Vector2(360, 18)
	inner.add_child(wavy)

	var steps: Array[Array] = [
		[M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, M3Button.Variant.FILLED, "Indigo · Light · Filled"],
		[M3PaletteGenerator.PRESET_BASELINE_INDIGO, false, M3Button.Variant.TONAL, "Indigo · Light · Tonal"],
		[M3PaletteGenerator.PRESET_EMERALD, false, M3Button.Variant.FILLED, "Emerald · Light · Filled"],
		[M3PaletteGenerator.PRESET_EMERALD, true, M3Button.Variant.FILLED, "Emerald · Dark · Filled"],
		[M3PaletteGenerator.PRESET_CORAL, true, M3Button.Variant.OUTLINED, "Coral · Dark · Outlined"],
		[M3PaletteGenerator.PRESET_TEAL, true, M3Button.Variant.ELEVATED, "Teal · Dark · Elevated"],
	]
	var f_idx: int = 0
	for st in steps:
		M3ThemeSingleton.get_instance().set_seed_color(st[0])
		M3ThemeSingleton.get_instance().set_dark_mode(st[1])
		btn.variant = st[2]
		var sb := StyleBoxFlat.new()
		sb.bg_color = M3ThemeSingleton.get_scheme().surface
		sb.set_corner_radius_all(10)
		canvas_panel.add_theme_stylebox_override(&"panel", sb)
		insp_status.text = "seed_color / mode / variant:\n\n  %s\n\n  ripple_enabled = true\n  button_size = Medium (56dp)\n  wavy = true" % st[3]
		for _k in range(3):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 3. Hero Showcase Tour
func _seq_hero_showcase_tour(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var app: Control = ShowcaseScene.instantiate() as Control
	bg.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	var nav := app.get("_adaptive_nav") as M3AdaptiveNavigation
	var presets := [
		[true, M3PaletteGenerator.PRESET_BASELINE_INDIGO, 0],
		[false, M3PaletteGenerator.PRESET_BASELINE_INDIGO, 0],
		[false, M3PaletteGenerator.PRESET_EMERALD, 1],
		[true, M3PaletteGenerator.PRESET_EMERALD, 2],
		[true, M3PaletteGenerator.PRESET_CORAL, 4],
		[false, M3PaletteGenerator.PRESET_TEAL, 6],
	]
	var f_idx: int = 0
	for p in presets:
		M3ThemeSingleton.get_instance().set_dark_mode(p[0])
		M3ThemeSingleton.get_instance().set_seed_color(p[1])
		if nav != null:
			nav.selected_index = p[2]
		for _k in range(3):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 4. Foundations Color Palettes Cycle
func _seq_color_palettes_cycle(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var lbl := Label.new()
	lbl.position = Vector2(24, 16)
	bg.add_child(lbl)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(24, 58)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	bg.add_child(grid)

	var roles: Array[StringName] = [
		&"primary", &"primary_container", &"secondary", &"secondary_container",
		&"tertiary", &"tertiary_container", &"error", &"error_container",
		&"surface_container_low", &"surface_container_high", &"primary_fixed", &"inverse_surface"
	]
	var swatches: Array[M3Surface] = []
	for r in roles:
		var s := M3Surface.new()
		s.surface_role = r
		s.shape_token = M3Shapes.ShapeToken.MEDIUM
		s.custom_minimum_size = Vector2(168, 92)
		s.content_margin_left = 10
		s.content_margin_top = 10
		var rl := Label.new()
		rl.text = String(r)
		s.add_child(rl)
		grid.add_child(s)
		swatches.append(s)

	var configs := [
		["Baseline Indigo (Light)", M3PaletteGenerator.PRESET_BASELINE_INDIGO, false],
		["Baseline Indigo (Dark)", M3PaletteGenerator.PRESET_BASELINE_INDIGO, true],
		["Emerald Seed (Light)", M3PaletteGenerator.PRESET_EMERALD, false],
		["Emerald Seed (Dark)", M3PaletteGenerator.PRESET_EMERALD, true],
		["Coral Seed (Light)", M3PaletteGenerator.PRESET_CORAL, false],
		["Teal Seed (Dark)", M3PaletteGenerator.PRESET_TEAL, true],
	]
	var f_idx: int = 0
	for cfg in configs:
		M3ThemeSingleton.get_instance().set_seed_color(cfg[1])
		M3ThemeSingleton.get_instance().set_dark_mode(cfg[2])
		var sc := M3ThemeSingleton.get_scheme()
		bg.color = sc.surface
		lbl.text = "Dynamic Color Roles — %s" % cfg[0]
		M3Typography.apply_to_label(lbl, M3Typography.Role.TITLE_LARGE_EMPHASIZED, sc.on_surface)
		for i in range(swatches.size()):
			var r_col: Color = sc.get_color(roles[i])
			swatches[i].custom_surface_color = r_col
			var t_col: Color = Color.WHITE if M3Math.color_to_lstar(r_col) < 55.0 else Color.BLACK
			M3Typography.apply_to_label(swatches[i].get_child(0) as Label, M3Typography.Role.LABEL_MEDIUM, t_col)
		for _k in range(3):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 5. Foundations 9 Scheme Variants
func _seq_9_scheme_variants(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var lbl := Label.new()
	lbl.position = Vector2(24, 18)
	bg.add_child(lbl)

	var row := HBoxContainer.new()
	row.position = Vector2(24, 68)
	row.add_theme_constant_override("separation", 14)
	bg.add_child(row)

	var roles: Array[StringName] = [&"primary", &"primary_container", &"secondary", &"tertiary", &"surface_container_highest"]
	var boxes: Array[M3Surface] = []
	for r in roles:
		var s := M3Surface.new()
		s.shape_token = M3Shapes.ShapeToken.LARGE
		s.custom_minimum_size = Vector2(130, 180)
		s.content_margin_left = 10
		s.content_margin_top = 12
		var tl := Label.new()
		tl.text = String(r)
		s.add_child(tl)
		row.add_child(s)
		boxes.append(s)

	var names := ["TonalSpot", "Vibrant", "Expressive", "Monochrome", "Neutral", "Fidelity", "Content", "Rainbow", "FruitSalad"]
	var f_idx: int = 0
	for i in range(9):
		M3ThemeSingleton.get_instance().set_scheme_variant(i as M3PaletteGenerator.SchemeVariant)
		var sc := M3ThemeSingleton.get_scheme()
		bg.color = sc.surface
		lbl.text = "M3 DynamicScheme Variant (%d/9): %s" % [i + 1, names[i]]
		M3Typography.apply_to_label(lbl, M3Typography.Role.HEADLINE_SMALL, sc.on_surface)
		for j in range(boxes.size()):
			var col: Color = sc.get_color(roles[j])
			boxes[j].custom_surface_color = col
			var tc: Color = Color.WHITE if M3Math.color_to_lstar(col) < 55.0 else Color.BLACK
			M3Typography.apply_to_label(boxes[j].get_child(0) as Label, M3Typography.Role.LABEL_MEDIUM, tc)
		for _k in range(2):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 6. Foundations Shape Radius Sweep
func _seq_shape_radius_sweep(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var sc := M3ThemeSingleton.get_scheme()
	var surf := M3Surface.new()
	surf.surface_role = &"primary_container"
	surf.border_width = 3
	surf.border_color = sc.primary
	surf.position = Vector2(120, 70)
	surf.size = Vector2(400, 180)
	surf.content_margin_left = 24
	surf.content_margin_top = 70
	bg.add_child(surf)

	var lbl := Label.new()
	M3Typography.apply_to_label(lbl, M3Typography.Role.HEADLINE_SMALL, sc.on_primary_container)
	surf.add_child(lbl)

	var tokens := [
		["None (0dp)", 0.0], ["Extra Small (4dp)", 4.0], ["Small (8dp)", 8.0],
		["Medium (12dp)", 12.0], ["Large (16dp)", 16.0], ["Extra Large (28dp)", 28.0],
		["XL Increased (32dp)", 32.0], ["XXL (48dp)", 48.0], ["Full Pill (90dp)", 90.0]
	]
	var f_idx: int = 0
	for tok in tokens:
		surf.corner_radius_override = tok[1]
		lbl.text = "Shape Token: " + tok[0]
		for _k in range(2):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 7. Foundations 35 Shapes Morph Loop
func _seq_35_shapes_morph_loop(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var sc := M3ThemeSingleton.get_scheme()
	var lbl := Label.new()
	lbl.position = Vector2(24, 16)
	M3Typography.apply_to_label(lbl, M3Typography.Role.TITLE_LARGE_EMPHASIZED, sc.on_surface)
	bg.add_child(lbl)

	var shapes := [
		M3Shapes.MaterialShape.COOKIE_4,
		M3Shapes.MaterialShape.CLOVER_4,
		M3Shapes.MaterialShape.VERY_SUNNY,
		M3Shapes.MaterialShape.BURST,
		M3Shapes.MaterialShape.HEART,
		M3Shapes.MaterialShape.PIXEL_CIRCLE,
	]
	var names := ["COOKIE_4", "CLOVER_4", "VERY_SUNNY", "BURST", "HEART", "PIXEL_CIRCLE"]
	var morph := M3ShapeMorph.new()
	morph.position = Vector2(210, 68)
	morph.size = Vector2(220, 220)
	morph.from_shape = shapes[0]
	morph.to_shape = shapes[1]
	bg.add_child(morph)

	var f_idx: int = 0
	for s_i in range(shapes.size()):
		var nxt: int = (s_i + 1) % shapes.size()
		morph.from_shape = shapes[s_i]
		morph.to_shape = shapes[nxt]
		lbl.text = "M3 Expressive Vertex Morph: %s -> %s" % [names[s_i], names[nxt]]
		for step in range(4):
			morph.morph_progress = float(step) / 3.0
			morph.rotation_angle = float(f_idx) * 0.14
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 8. Foundations Elevation Lift 0..5
func _seq_elevation_lift(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var sc := M3ThemeSingleton.get_scheme()
	var surf := M3Surface.new()
	surf.shape_token = M3Shapes.ShapeToken.LARGE
	surf.position = Vector2(140, 76)
	surf.size = Vector2(360, 180)
	surf.content_margin_left = 28
	surf.content_margin_top = 60
	bg.add_child(surf)

	var lbl := Label.new()
	M3Typography.apply_to_label(lbl, M3Typography.Role.HEADLINE_SMALL, sc.on_surface)
	surf.add_child(lbl)

	var seq := [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0]
	var f_idx: int = 0
	for lvl in seq:
		surf.elevation_level = lvl
		surf.position.y = 76.0 - float(lvl) * 4.0
		lbl.text = "Elevation Level %d (%.0fdp · %d%% Tint)" % [lvl, M3Elevation.HEIGHTS[lvl], int(round(M3Elevation.get_tint_opacity(lvl) * 100.0))]
		for _k in range(2):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 9. Foundations Spatial vs Effects Springs
func _seq_spatial_vs_effects(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var t1 := M3Transition.new()
	t1.pattern = M3Motion.TransitionPattern.CONTAINER_TRANSFORM
	t1.outgoing_label = "Card"
	t1.incoming_label = "Container Transform (Spatial)"
	t1.position = Vector2(24, 24)
	t1.size = Vector2(320, 156)
	t1.expanded_rect = Rect2(14, 14, 290, 128)
	bg.add_child(t1)

	var t2 := M3Transition.new()
	t2.pattern = M3Motion.TransitionPattern.SHARED_AXIS_X
	t2.outgoing_label = "Step 1"
	t2.incoming_label = "Shared Axis X"
	t2.position = Vector2(376, 24)
	t2.size = Vector2(320, 156)
	t2.expanded_rect = Rect2(14, 14, 290, 128)
	bg.add_child(t2)

	var t3 := M3Transition.new()
	t3.pattern = M3Motion.TransitionPattern.FADE_THROUGH
	t3.outgoing_label = "Tab A"
	t3.incoming_label = "Fade Through (Effects)"
	t3.position = Vector2(24, 200)
	t3.size = Vector2(320, 156)
	t3.expanded_rect = Rect2(14, 14, 290, 128)
	bg.add_child(t3)

	var t4 := M3Transition.new()
	t4.pattern = M3Motion.TransitionPattern.SHARED_AXIS_Z
	t4.outgoing_label = "Parent"
	t4.incoming_label = "Shared Axis Z"
	t4.position = Vector2(376, 200)
	t4.size = Vector2(320, 156)
	t4.expanded_rect = Rect2(14, 14, 290, 128)
	bg.add_child(t4)

	for i in range(20):
		var prog: float = float(i) / 14.0 if i <= 14 else 1.0
		for tc in [t1, t2, t3, t4]:
			tc.set_progress(prog)
		await _snap_frame(vp, dir, i, max_dim)

# 10. Foundations Typography Baseline vs Emphasized
func _seq_typography_toggle(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(32, 24)
	vbox.add_theme_constant_override("separation", 14)
	bg.add_child(vbox)

	var hdr := Label.new()
	vbox.add_child(hdr)
	var sample_roles := [
		M3Typography.Role.DISPLAY_SMALL,
		M3Typography.Role.HEADLINE_MEDIUM,
		M3Typography.Role.TITLE_LARGE,
		M3Typography.Role.BODY_LARGE,
		M3Typography.Role.LABEL_LARGE,
	]
	var labels: Array[Label] = []
	for _r in sample_roles:
		var l := Label.new()
		vbox.add_child(l)
		labels.append(l)

	var modes := [[false, false, "Baseline Scale · Light"], [true, false, "Emphasized Scale · Light"], [false, true, "Baseline Scale · Dark"], [true, true, "Emphasized Scale · Dark"]]
	var f_idx: int = 0
	for m in modes:
		M3ThemeSingleton.get_instance().set_dark_mode(m[1])
		var sc := M3ThemeSingleton.get_scheme()
		bg.color = sc.surface
		hdr.text = "M3 Type Scale — " + m[2]
		M3Typography.apply_to_label(hdr, M3Typography.Role.TITLE_MEDIUM_EMPHASIZED, sc.primary)
		for i in range(sample_roles.size()):
			var r: M3Typography.Role = M3Typography.to_emphasized(sample_roles[i]) if m[0] else sample_roles[i]
			labels[i].text = "%s (%dsp · w%d)" % [String(M3Typography.ROLE_DATA[r]["name"]), M3Typography.get_font_size(r), M3Typography.get_weight(r)]
			M3Typography.apply_to_label(labels[i], r, sc.on_surface)
		for _k in range(4):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 11. Actions All Buttons Dark Wave
func _seq_actions_buttons_dark(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(32, 64)
	row.add_theme_constant_override("separation", 16)
	bg.add_child(row)

	var btns: Array[M3Button] = []
	for pair in [["Elevated", M3Button.Variant.ELEVATED], ["Filled", M3Button.Variant.FILLED], ["Tonal", M3Button.Variant.TONAL], ["Outlined", M3Button.Variant.OUTLINED], ["Text", M3Button.Variant.TEXT]]:
		var b := M3Button.new()
		b.text = pair[0]
		b.variant = pair[1]
		b.button_size = M3Button.ButtonSize.MEDIUM
		row.add_child(b)
		btns.append(b)

	var grp := M3ButtonGroup.new()
	grp.group_variant = M3ButtonGroup.GroupVariant.CONNECTED
	grp.position = Vector2(32, 168)
	grp.add_button("Reply", "undo")
	grp.add_button("Forward", "send")
	grp.add_button("Archive", "bookmark")
	bg.add_child(grp)

	var seg := M3SegmentedButtonGroup.new()
	for lbl in ["Day", "Week", "Month", "Year"]:
		seg.add_segment(lbl)
	seg.position = Vector2(32, 260)
	bg.add_child(seg)

	for i in range(20):
		var b_i: int = (i / 4) % btns.size()
		if i % 4 == 0:
			btns[b_i]._set_state(M3Control.ControlState.PRESSED)
			if btns[b_i]._ripple:
				btns[b_i]._ripple.call("start_press", btns[b_i].size * 0.5)
			seg.select(b_i % 4)
		elif i % 4 == 2:
			btns[b_i]._set_state(M3Control.ControlState.NORMAL)
			if btns[b_i]._ripple:
				btns[b_i]._ripple.call("end_press")
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 12. Actions FAB Menu & Split Button Dark
func _seq_actions_fab_split_dark(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var split := M3SplitButton.new()
	split.text = "Deploy"
	split.leading_icon = &"send"
	split.variant = M3SplitButton.VariantType.FILLED
	split.add_menu_item("Deploy Staging")
	split.add_menu_item("Deploy Production")
	split.add_menu_item("Schedule Rollout")
	split.position = Vector2(48, 48)
	bg.add_child(split)

	var ext_fab := M3FAB.new()
	ext_fab.icon_name = &"edit"
	ext_fab.label = "Compose"
	ext_fab.position = Vector2(48, 280)
	bg.add_child(ext_fab)

	var fm := M3FabMenu.new()
	fm.add_item("New Document", "edit")
	fm.add_item("Upload Image", "image")
	fm.add_item("Share Link", "share")
	fm.position = Vector2(440, 320)
	bg.add_child(fm)

	for i in range(20):
		if i == 2:
			split.set_menu_open(true)
			fm.set_open(true)
			ext_fab.set_extended(true)
		elif i == 12:
			split.set_menu_open(false)
			fm.set_open(false)
			ext_fab.set_extended(false)
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 13. Communication Wavy & Loaders Dark
func _seq_comm_wavy_dark(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var w1 := M3LinearProgress.new()
	w1.wavy = true
	w1.set_value_immediate(0.65)
	w1.position = Vector2(40, 60)
	w1.size = Vector2(640, 20)
	bg.add_child(w1)

	var w2 := M3LinearProgress.new()
	w2.wavy = true
	w2.indeterminate = true
	w2.position = Vector2(40, 120)
	w2.size = Vector2(640, 20)
	bg.add_child(w2)

	var c1 := M3CircularProgress.new()
	c1.wavy = true
	c1.set_value_immediate(0.75)
	c1.position = Vector2(80, 200)
	bg.add_child(c1)

	var c2 := M3CircularProgress.new()
	c2.wavy = true
	c2.indeterminate = true
	c2.position = Vector2(210, 200)
	bg.add_child(c2)

	var l1 := M3LoadingIndicator.new()
	l1.contained = true
	l1.position = Vector2(360, 200)
	bg.add_child(l1)

	var l2 := M3LoadingIndicator.new()
	l2.contained = false
	l2.position = Vector2(480, 200)
	bg.add_child(l2)

	for i in range(22):
		await process_frame
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 14. Communication Overlays Flow
func _seq_comm_overlays_flow(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var banner := M3Banner.new()
	banner.message = "Your connection was restored. Sync pending edits now?"
	banner.primary_action_label = "Sync Now"
	banner.secondary_action_label = "Dismiss"
	banner.position = Vector2(20, 20)
	banner.size = Vector2(720, 84)
	bg.add_child(banner)

	var tip := M3Tooltip.new()
	tip.tooltip_type = M3Tooltip.TooltipType.RICH
	tip.title = "Material 3 Tooltip"
	tip.text = "Rich tooltips provide contextual documentation and an action link."
	tip.action_text = "Docs"
	tip.position = Vector2(40, 130)
	bg.add_child(tip)

	var sb := M3Snackbar.new()
	sb.message = "Changes published to production"
	sb.action_text = "Undo"
	sb.show_close_icon = true
	sb.position = Vector2(180, 330)
	bg.add_child(sb)

	for i in range(20):
		if i == 1:
			banner.show_banner()
		elif i == 5:
			tip.show_tooltip()
		elif i == 10:
			sb.show_snackbar()
		elif i == 16:
			banner.dismiss()
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 15. Containment Carousel & Cards Dark
func _seq_containment_carousel_dark(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var sc := M3ThemeSingleton.get_scheme()
	var car := M3Carousel.new()
	car.carousel_style = M3Carousel.CarouselStyle.MULTI_BROWSE
	car.position = Vector2(24, 24)
	car.size = Vector2(712, 210)
	car.add_item("Alpine Peaks", "Mountain expedition", sc.primary_container)
	car.add_item("Coastal Breeze", "Pacific shoreline", sc.tertiary_container)
	car.add_item("Desert Dunes", "Golden horizon", sc.secondary_container)
	car.add_item("Forest Canopy", "Redwood trail", sc.surface_container_highest)
	bg.add_child(car)

	var row := HBoxContainer.new()
	row.position = Vector2(24, 260)
	row.add_theme_constant_override("separation", 20)
	bg.add_child(row)
	for ct in [M3Card.CardType.ELEVATED, M3Card.CardType.FILLED, M3Card.CardType.OUTLINED]:
		var c := M3Card.new()
		c.card_type = ct
		c.clickable = true
		c.custom_minimum_size = Vector2(220, 120)
		var l := Label.new()
		l.text = ["Elevated Card", "Filled Card", "Outlined Card"][int(ct)]
		c.add_child(l)
		row.add_child(c)

	for i in range(20):
		if i == 3:
			car.scroll_to_index(1, true)
		elif i == 9:
			car.scroll_to_index(2, true)
		elif i == 15:
			car.scroll_to_index(0, true)
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 16. Containment Sheets & Dialogs Flow
func _seq_containment_sheets_flow(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var bs := M3BottomSheet.new()
	bs.sheet_type = M3BottomSheet.SheetType.MODAL
	bs.size = bg.size
	bg.add_child(bs)

	var ss := M3SideSheet.new()
	ss.sheet_type = M3SideSheet.SheetType.MODAL
	ss.title = "Inspector Filters"
	ss.size = bg.size
	bg.add_child(ss)

	for i in range(20):
		if i == 1:
			bs.open()
		elif i == 9:
			bs.close()
			ss.open()
		elif i == 17:
			ss.close()
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 17. Containment Divider Modes Cycle
func _seq_containment_divider_cycle(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var sc := M3ThemeSingleton.get_scheme()
	var lbl := Label.new()
	lbl.position = Vector2(32, 24)
	M3Typography.apply_to_label(lbl, M3Typography.Role.TITLE_LARGE_EMPHASIZED, sc.on_surface)
	bg.add_child(lbl)

	var div := M3Divider.new()
	div.position = Vector2(32, 160)
	div.size = Vector2(576, 8)
	bg.add_child(div)

	var modes := [
		["Full-Width Horizontal Divider", M3Divider.InsetMode.FULL_WIDTH],
		["Inset Horizontal Divider (16dp)", M3Divider.InsetMode.INSET],
		["Middle-Inset Horizontal Divider", M3Divider.InsetMode.MIDDLE_INSET],
	]
	var f_idx: int = 0
	for m in modes:
		lbl.text = m[0]
		div.inset_mode = m[1]
		for _k in range(5):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 18. Navigation Responsive Breakpoints Resize
func _seq_nav_responsive_resize(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var sc := M3ThemeSingleton.get_scheme()
	var hdr := Label.new()
	hdr.position = Vector2(20, 12)
	M3Typography.apply_to_label(hdr, M3Typography.Role.TITLE_MEDIUM_EMPHASIZED, sc.primary)
	bg.add_child(hdr)

	var adaptive := M3AdaptiveNavigation.new()
	adaptive.position = Vector2(20, 48)
	adaptive.size = Vector2(460, 392)
	bg.add_child(adaptive)

	var widths := [[460.0, "Compact (<600dp) -> Bottom Navigation Bar"], [680.0, "Medium (600-839dp) -> Navigation Rail"], [800.0, "Expanded (>=840dp) -> Navigation Drawer"]]
	var f_idx: int = 0
	for w in widths:
		adaptive.size = Vector2(w[0], 392)
		adaptive.width_override = w[0]
		hdr.text = w[1]
		for _k in range(5):
			await process_frame
			await _snap_frame(vp, dir, f_idx, max_dim)
			f_idx += 1

# 19. Navigation App Bars & Toolbars Dark
func _seq_nav_bars_toolbars_dark(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var top := M3TopAppBar.new()
	top.bar_variant = M3TopAppBar.BarVariant.LARGE
	top.title = "Material 3 Navigation"
	top.subtitle = "Collapsing App Bar & Floating Toolbar"
	top.position = Vector2(20, 16)
	top.size = Vector2(720, 152)
	top.add_action("search")
	top.add_action("settings")
	bg.add_child(top)

	var tabs := M3Tabs.new()
	tabs.scrollable = true
	var tab_items: Array[Dictionary] = []
	for lbl in ["Overview", "Foundations", "Actions", "Communication", "Containment", "Navigation", "Selection"]:
		tab_items.append({"label": lbl, "icon": null})
	tabs.tabs = tab_items
	tabs.position = Vector2(20, 192)
	tabs.size = Vector2(720, 48)
	bg.add_child(tabs)

	var tb := M3Toolbar.new()
	tb.toolbar_type = M3Toolbar.ToolbarType.FLOATING
	tb.color_style = M3Toolbar.ColorStyle.VIBRANT
	tb.add_item("edit", "Edit")
	tb.add_item("share", "Share")
	tb.add_item("bookmark", "Save")
	tb.add_item("settings", "Config")
	tb.position = Vector2(210, 290)
	bg.add_child(tb)

	for i in range(20):
		if i == 3:
			top.set_scrolled(true)
			tabs.selected_tab = 4
			tb.active_index = 2
		elif i == 12:
			top.set_scrolled(false)
			tabs.selected_tab = 1
			tb.active_index = 0
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 20. Selection Controls Symphony Dark
func _seq_selection_symphony_dark(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var cb := M3Checkbox.new()
	cb.position = Vector2(40, 48)
	bg.add_child(cb)

	var sw := M3Switch.new()
	sw.show_icons = true
	sw.position = Vector2(120, 56)
	bg.add_child(sw)

	var rg := M3RadioGroup.new()
	rg.position = Vector2(210, 48)
	var r1 := M3Radio.new()
	var r2 := M3Radio.new()
	r2.position = Vector2(60, 0)
	rg.add_child(r1)
	rg.add_child(r2)
	bg.add_child(rg)

	var chip := M3Chip.new()
	chip.chip_type = M3Chip.ChipType.FILTER
	chip.text = "Expressive Filter"
	chip.position = Vector2(360, 56)
	bg.add_child(chip)

	var s_horiz := M3Slider.new()
	s_horiz.slider_size = M3Slider.SliderSize.LARGE
	s_horiz.centered_zero = true
	s_horiz.min_value = -100.0
	s_horiz.max_value = 100.0
	s_horiz.value = -60.0
	s_horiz.position = Vector2(40, 170)
	s_horiz.size = Vector2(480, 56)
	bg.add_child(s_horiz)

	var s_vert := M3Slider.new()
	s_vert.orientation = M3Slider.Orientation.VERTICAL
	s_vert.slider_size = M3Slider.SliderSize.MEDIUM
	s_vert.value = 20.0
	s_vert.position = Vector2(580, 80)
	s_vert.size = Vector2(48, 260)
	bg.add_child(s_vert)

	for i in range(20):
		if i == 3:
			cb.check_state = M3Checkbox.CheckState.CHECKED
			sw.selected = true
			r2.selected = true
			chip.selected = true
		elif i == 11:
			cb.check_state = M3Checkbox.CheckState.INDETERMINATE
			sw.selected = false
			r1.selected = true
			chip.selected = false
		s_horiz.value = lerpf(-80.0, 85.0, float(i) / 19.0)
		s_vert.value = lerpf(15.0, 95.0, float(i) / 19.0)
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)

# 21. Selection 24h Dual-Ring Time Picker & Year-Grid Date Picker
func _seq_pickers_24h_year(vp: SubViewport, bg: ColorRect, dir: String, max_dim: int) -> void:
	var tp := M3TimePicker.new()
	tp.use_24_hour = true
	tp.selected_hour = 3
	tp.selected_minute = 30
	tp.position = Vector2(24, 18)
	bg.add_child(tp)

	var dp := M3DatePicker.new()
	dp.picker_mode = M3DatePicker.PickerMode.DOCKED
	dp.selected_year = 2025
	dp.selected_month = 5
	dp.selected_day = 15
	dp.position = Vector2(396, 18)
	bg.add_child(dp)

	for i in range(20):
		if i == 3:
			tp.selected_hour = 14
			dp.set_year_picker_open(true)
		elif i == 9:
			tp.selected_hour = 21
			dp.select_year(2028)
		elif i == 15:
			tp.selected_hour = 8
			dp.set_year_picker_open(false)
		await process_frame
		await _snap_frame(vp, dir, i, max_dim)
