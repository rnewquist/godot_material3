# res://tests/gss/test_gss_containment.gd
## GSS verification suite for the Material 3 Containment family:
##   - containment.bottom_sheet
##   - containment.card
##   - containment.carousel
##   - containment.dialog.basic
##   - containment.dialog.fullscreen
##   - containment.divider
##   - containment.list
##   - containment.side_sheet
extends GDTestSuite

const H := preload("res://tests/gss/m3_gss_harness.gd")

const BOTTOM_SHEET_SCRIPT := "res://addons/material3/components/containment/m3_bottom_sheet.gd"
const CARD_SCRIPT := "res://addons/material3/components/containment/m3_card.gd"
const CAROUSEL_SCRIPT := "res://addons/material3/components/containment/m3_carousel.gd"
const DIALOG_SCRIPT := "res://addons/material3/components/containment/m3_dialog.gd"
const DIVIDER_SCRIPT := "res://addons/material3/components/containment/m3_divider.gd"
const LIST_SCRIPT := "res://addons/material3/components/containment/m3_list.gd"
const LIST_ITEM_SCRIPT := "res://addons/material3/components/containment/m3_list_item.gd"
const SIDE_SHEET_SCRIPT := "res://addons/material3/components/containment/m3_side_sheet.gd"

func _init() -> void:
	suite_name = "GSS_Containment"
	test_type = "integration"

# ==============================================================================
# 1. CARDS (containment.card) — Light & Dark + Clickable / Draggable
# ==============================================================================

func test_card_variants_and_interaction() -> void:
	var stage = await H.create_stage(self, "containment", "cards_light", false)

	var elevated := M3Card.new()
	elevated.name = "ElevatedCard"
	elevated.card_type = M3Card.CardType.ELEVATED
	elevated.is_clickable = true
	elevated.size = Vector2(240, 140)
	var lbl_e := Label.new()
	lbl_e.text = "Elevated Card\nClickable"
	elevated.add_child(lbl_e)
	stage.add(elevated, Vector2(60, 80))

	var filled := M3Card.new()
	filled.name = "FilledCard"
	filled.card_type = M3Card.CardType.FILLED
	filled.size = Vector2(240, 140)
	var lbl_f := Label.new()
	lbl_f.text = "Filled Card"
	filled.add_child(lbl_f)
	stage.add(filled, Vector2(340, 80))

	var outlined := M3Card.new()
	outlined.name = "OutlinedCard"
	outlined.card_type = M3Card.CardType.OUTLINED
	outlined.size = Vector2(240, 140)
	var lbl_o := Label.new()
	lbl_o.text = "Outlined Card"
	outlined.add_child(lbl_o)
	stage.add(outlined, Vector2(620, 80))

	var draggable_card := M3Card.new()
	draggable_card.name = "DraggableCard"
	draggable_card.card_type = M3Card.CardType.ELEVATED
	draggable_card.is_clickable = true
	draggable_card.is_draggable = true
	draggable_card.size = Vector2(240, 140)
	var lbl_d := Label.new()
	lbl_d.text = "Draggable Card"
	draggable_card.add_child(lbl_d)
	stage.add(draggable_card, Vector2(900, 80))

	var snap: Dictionary = await H.snapshot(stage, "containment.card", "variants_light")
	H.assert_snapshot(self, snap, [CARD_SCRIPT], "card variants light")

	var elev_node: Dictionary = H.node_entry(snap, "ElevatedCard")
	assert_eq(int(elev_node.get("script_variables", {}).get("corner_radius", 0)), 12, "Card corner radius is 12dp")
	assert_approx(float(elev_node.get("screen_rect", {}).get("width", 0.0)), 240.0, 1.0, "ElevatedCard width")

	var theme_mgr := M3ThemeSingleton.get_instance()
	await H.assert_pixel(self, stage, stage.point_of(elevated, Vector2(200, 110)), theme_mgr.get_color(&"surface_container_low"), 0.08, "elevated card surface_container_low")
	await H.assert_pixel(self, stage, stage.point_of(filled, Vector2(200, 110)), theme_mgr.get_color(&"surface_container_highest"), 0.08, "filled card surface_container_highest")
	await H.assert_pixel(self, stage, stage.point_of(outlined, Vector2(200, 110)), theme_mgr.get_color(&"surface"), 0.08, "outlined card surface")
	H.cover(self, "containment.card", "element", snap)

	# Dark mode snapshot
	M3ThemeSingleton.get_instance().set_dark_mode(true)
	stage.refresh_background()
	var snap_dark: Dictionary = await H.snapshot(stage, "containment.card", "variants_dark")
	H.assert_snapshot(self, snap_dark, [CARD_SCRIPT], "card variants dark")
	H.cover(self, "containment.card", "element", snap_dark)
	M3ThemeSingleton.get_instance().set_dark_mode(false)
	stage.refresh_background()

	# Interactive hover + click + drag recording
	var clicks: Array[int] = [0]
	var presses: Array[int] = [0]
	elevated.clicked.connect(func() -> void: clicks[0] += 1)
	elevated.pressed.connect(func() -> void: presses[0] += 1)

	var live: Dictionary = await H.record(stage, "containment.card", "click_and_drag", func() -> void:
		await stage.hover(elevated)
		await stage.wait(6)
		await stage.click(elevated, Vector2.INF, 6)
		await stage.wait(6)
		await stage.drag(draggable_card, Vector2(120, 70), Vector2(160, 110), 10)
		await stage.wait(6)
		await stage.leave()
	, 12, elevated)

	H.assert_recording(self, live, "card click and drag")
	assert_gte(float(presses[0]), 1.0, "ElevatedCard emitted pressed")
	assert_gte(float(clicks[0]), 1.0, "ElevatedCard emitted clicked")
	H.assert_animated(self, live, "ElevatedCard", "script_variables._state_layer_alpha", 3, "card state layer alpha tweened")
	H.assert_animated(self, live, "ElevatedCard", "script_variables._current_elevation", 2, "card elevation tweened")
	H.assert_mutated(self, live, "DraggableCard", "script_variables.drag_offset", null, "draggable card offset mutated")
	H.cover(self, "containment.card", "interaction", live)
	H.cover(self, "containment.card", "animation", live)
	stage.dispose()

# ==============================================================================
# 2. DIVIDERS (containment.divider)
# ==============================================================================

func test_divider_variants() -> void:
	var stage = await H.create_stage(self, "containment", "dividers_light", false)

	var vbox := VBoxContainer.new()
	vbox.name = "DividerColumn"
	vbox.size = Vector2(480, 260)
	vbox.add_theme_constant_override("separation", 32)
	stage.add(vbox, Vector2(80, 80))

	var div_full := M3Divider.new()
	div_full.name = "FullWidthDivider"
	div_full.inset_mode = M3Divider.InsetMode.FULL_WIDTH
	vbox.add_child(div_full)

	var div_inset := M3Divider.new()
	div_inset.name = "InsetDivider"
	div_inset.inset_mode = M3Divider.InsetMode.INSET
	vbox.add_child(div_inset)

	var div_mid := M3Divider.new()
	div_mid.name = "MiddleInsetDivider"
	div_mid.inset_mode = M3Divider.InsetMode.MIDDLE_INSET
	vbox.add_child(div_mid)

	var hbox := HBoxContainer.new()
	hbox.name = "VerticalDividerRow"
	hbox.size = Vector2(240, 120)
	hbox.add_theme_constant_override("separation", 24)
	stage.add(hbox, Vector2(640, 80))

	var left_lbl := Label.new()
	left_lbl.text = "Left"
	left_lbl.add_theme_color_override("font_color", M3ThemeSingleton.get_instance().get_color(&"on_surface"))
	hbox.add_child(left_lbl)

	var div_vert := M3Divider.new()
	div_vert.name = "VerticalDivider"
	div_vert.orientation = M3Divider.DividerOrientation.VERTICAL
	hbox.add_child(div_vert)

	var right_lbl := Label.new()
	right_lbl.text = "Right"
	right_lbl.add_theme_color_override("font_color", M3ThemeSingleton.get_instance().get_color(&"on_surface"))
	hbox.add_child(right_lbl)

	var snap: Dictionary = await H.snapshot(stage, "containment.divider", "all_variants")
	H.assert_snapshot(self, snap, [DIVIDER_SCRIPT], "divider variants")

	var full_node: Dictionary = H.node_entry(snap, "FullWidthDivider")
	var inset_node: Dictionary = H.node_entry(snap, "InsetDivider")
	var mid_node: Dictionary = H.node_entry(snap, "MiddleInsetDivider")
	var vert_node: Dictionary = H.node_entry(snap, "VerticalDivider")

	assert_approx(float(full_node.get("screen_rect", {}).get("height", 0.0)), 1.0, 0.1, "Horizontal divider is 1dp high")
	assert_approx(float(inset_node.get("script_variables", {}).get("inset_start", 0.0)), 16.0, 0.1, "Inset divider has 16dp start inset")
	assert_approx(float(mid_node.get("script_variables", {}).get("inset_start", 0.0)), 16.0, 0.1, "Middle-inset divider has 16dp start inset")
	assert_approx(float(mid_node.get("script_variables", {}).get("inset_end", 0.0)), 16.0, 0.1, "Middle-inset divider has 16dp end inset")
	assert_approx(float(vert_node.get("screen_rect", {}).get("width", 0.0)), 1.0, 0.1, "Vertical divider is 1dp wide")

	var outline_var := M3ThemeSingleton.get_instance().get_color(&"outline_variant")
	await H.assert_pixel(self, stage, stage.point_of(div_full, Vector2(240, 0)), outline_var, 0.08, "divider pixel matches outline_variant")
	H.cover(self, "containment.divider", "element", snap)
	stage.dispose()

# ==============================================================================
# 3. LISTS (containment.list)
# ==============================================================================

func test_list_variants_and_selection() -> void:
	var stage = await H.create_stage(self, "containment", "lists_light", false)

	var list := M3List.new()
	list.name = "ContactsList"
	list.with_dividers = true
	list.selectable = true
	list.size = Vector2(460, 320)
	stage.add(list, Vector2(100, 60))

	var item1 := M3ListItem.new()
	item1.name = "OneLineItem"
	item1.lines = M3ListItem.ItemLines.ONE_LINE
	item1.leading_type = M3ListItem.LeadingType.ICON
	item1.leading_icon_name = &"person"
	item1.headline = "Single-line item"
	item1.trailing_type = M3ListItem.TrailingType.TEXT
	item1.trailing_text = "100+"
	list.add_item(item1)

	var item2 := M3ListItem.new()
	item2.name = "TwoLineItem"
	item2.lines = M3ListItem.ItemLines.TWO_LINE
	item2.leading_type = M3ListItem.LeadingType.AVATAR
	item2.headline = "Two-line item with avatar"
	item2.supporting_text = "Secondary supporting text"
	item2.trailing_type = M3ListItem.TrailingType.ICON
	item2.trailing_icon_name = &"chevron_right"
	list.add_item(item2)

	var item3 := M3ListItem.new()
	item3.name = "ThreeLineItem"
	item3.lines = M3ListItem.ItemLines.THREE_LINE
	item3.leading_type = M3ListItem.LeadingType.AVATAR
	item3.overline_text = "OVERLINE"
	item3.headline = "Three-line item selected"
	item3.supporting_text = "Supporting line one\nSupporting line two"
	item3.trailing_type = M3ListItem.TrailingType.TEXT
	item3.trailing_text = "Now"
	item3.selected = true
	list.add_item(item3)

	list.selected_index = 2

	var snap: Dictionary = await H.snapshot(stage, "containment.list", "variants_light")
	H.assert_snapshot(self, snap, [LIST_SCRIPT, LIST_ITEM_SCRIPT], "list variants")

	var n1: Dictionary = H.node_entry(snap, "OneLineItem")
	var n2: Dictionary = H.node_entry(snap, "TwoLineItem")
	var n3: Dictionary = H.node_entry(snap, "ThreeLineItem")
	assert_approx(float(n1.get("screen_rect", {}).get("height", 0.0)), 56.0, 1.0, "1-line item is 56dp high")
	assert_approx(float(n2.get("screen_rect", {}).get("height", 0.0)), 72.0, 1.0, "2-line item is 72dp high")
	assert_approx(float(n3.get("screen_rect", {}).get("height", 0.0)), 88.0, 1.0, "3-line item is 88dp high")

	var sec_container := M3ThemeSingleton.get_instance().get_color(&"secondary_container")
	await H.assert_pixel(self, stage, stage.point_of(item3, Vector2(400, 12)), sec_container, 0.08, "selected list item background is secondary_container")
	H.cover(self, "containment.list", "element", snap)

	# Click item1 to change selection and animate _select_progress + _state_layer_alpha
	var live: Dictionary = await H.record(stage, "containment.list", "select_item", func() -> void:
		await stage.hover(item1)
		await stage.wait(4)
		await stage.click(item1, Vector2.INF, 4)
		await stage.wait(12)
		await stage.leave()
	, 12, list)

	H.assert_recording(self, live, "list item selection")
	H.assert_mutated(self, live, "ContactsList", "script_variables.selected_index", 0)
	H.assert_mutated(self, live, "OneLineItem", "script_variables.selected", true)
	H.assert_animated(self, live, "OneLineItem", "script_variables._select_progress", 3, "list item selection progress tweened")
	H.cover(self, "containment.list", "interaction", live)
	H.cover(self, "containment.list", "animation", live)
	stage.dispose()

# ==============================================================================
# 4. CAROUSEL (containment.carousel)
# ==============================================================================

func test_carousel_variants_and_scrolling() -> void:
	var stage = await H.create_stage(self, "containment", "carousel_variants", false)

	var multi := M3Carousel.new()
	multi.name = "MultiBrowseCarousel"
	multi.carousel_style = M3Carousel.CarouselStyle.MULTI_BROWSE
	multi.size = Vector2(540, 200)
	stage.add(multi, Vector2(60, 60))

	var hero := M3Carousel.new()
	hero.name = "HeroCarousel"
	hero.carousel_style = M3Carousel.CarouselStyle.HERO
	hero.size = Vector2(420, 200)
	stage.add(hero, Vector2(660, 60))

	var uncontained := M3Carousel.new()
	uncontained.name = "UncontainedCarousel"
	uncontained.carousel_style = M3Carousel.CarouselStyle.UNCONTAINED
	uncontained.size = Vector2(540, 180)
	stage.add(uncontained, Vector2(60, 320))

	var fullscreen_car := M3Carousel.new()
	fullscreen_car.name = "FullScreenCarousel"
	fullscreen_car.carousel_style = M3Carousel.CarouselStyle.FULL_SCREEN
	fullscreen_car.size = Vector2(420, 180)
	stage.add(fullscreen_car, Vector2(660, 320))

	var snap: Dictionary = await H.snapshot(stage, "containment.carousel", "all_styles")
	H.assert_snapshot(self, snap, [CAROUSEL_SCRIPT], "carousel styles")

	# Verify Multi-browse dynamic squishing widths: focal (~280dp), medium (~140dp), peek (56dp)
	assert_gte(multi.get_item_width(0), 260.0, "Multi-browse focal item >= 260dp")
	assert_approx(multi.get_item_width(1), 140.0, 20.0, "Multi-browse medium item ~140dp")
	assert_approx(multi.get_item_width(2), 56.0, 2.0, "Multi-browse small peek item 56dp")

	var prim_cont := M3ThemeSingleton.get_instance().get_color(&"primary_container")
	await H.assert_pixel(self, stage, stage.point_of(multi, Vector2(120, 80)), prim_cont, 0.08, "focal carousel item uses primary_container")
	H.cover(self, "containment.carousel", "element", snap)

	# Click compacted item 1 on MultiBrowseCarousel and drag to scroll
	var selected_items: Array[int] = []
	multi.item_selected.connect(func(idx: int) -> void: selected_items.append(idx))

	var item1_center: Vector2 = multi.get_item_rect(1).get_center()
	var live: Dictionary = await H.record(stage, "containment.carousel", "click_and_drag_scroll", func() -> void:
		await stage.click(multi, item1_center, 3)
		await stage.wait(18)
		await stage.drag(multi, Vector2(360, 100), Vector2(140, 100), 10)
		await stage.wait(16)
	, 12, multi)

	H.assert_recording(self, live, "carousel click and drag scroll")
	assert_false(selected_items.is_empty(), "item_selected emitted on carousel interaction")
	H.assert_mutated(self, live, "MultiBrowseCarousel", "script_variables.active_index")
	H.assert_animated(self, live, "MultiBrowseCarousel", "script_variables.scroll_offset", 4, "carousel scroll_offset animated smoothly")
	H.cover(self, "containment.carousel", "interaction", live)
	H.cover(self, "containment.carousel", "animation", live)
	stage.dispose()

# ==============================================================================
# 5. BASIC DIALOG (containment.dialog.basic)
# ==============================================================================

func test_basic_dialog_variants_and_interaction() -> void:
	var stage = await H.create_stage(self, "containment", "dialog_basic", false)

	var dlg := M3Dialog.new()
	dlg.name = "BasicDialog"
	dlg.size = Vector2(H.STAGE_SIZE)
	dlg.headline = "Reset settings?"
	dlg.supporting_text = "This will reset your app preferences back to their default state."
	dlg.confirm_text = "Reset"
	dlg.cancel_text = "Cancel"
	dlg.icon_name = &"settings"
	stage.add(dlg, Vector2.ZERO)

	var confirmed_cnt: Array[int] = [0]
	var dismissed_cnt: Array[int] = [0]
	dlg.confirmed.connect(func() -> void: confirmed_cnt[0] += 1)
	dlg.dismissed.connect(func() -> void: dismissed_cnt[0] += 1)

	# Record opening the dialog (animates open_progress 0 -> 1)
	var live_open: Dictionary = await H.record(stage, "containment.dialog.basic", "open_transition", func() -> void:
		dlg.open()
		await stage.wait(20)
	, 12, dlg)

	H.assert_recording(self, live_open, "basic dialog open animation")
	H.assert_mutated(self, live_open, "BasicDialog", "script_variables.is_open", true)
	H.assert_animated(self, live_open, "BasicDialog", "script_variables.open_progress", 4, "dialog open_progress animated")
	H.cover(self, "containment.dialog.basic", "animation", live_open)

	# Snapshot while open (with icon, headline, body, confirm/cancel actions, scrim)
	var snap: Dictionary = await H.snapshot(stage, "containment.dialog.basic", "open_with_icon")
	H.assert_snapshot(self, snap, [DIALOG_SCRIPT], "basic dialog open")
	var card_node: Dictionary = H.node_entry(snap, "DialogCard")
	assert_gte(float(card_node.get("screen_rect", {}).get("width", 0.0)), 280.0, "Basic dialog width >= 280dp")
	assert_lte(float(card_node.get("screen_rect", {}).get("width", 0.0)), 560.0, "Basic dialog width <= 560dp")

	var surf_high := M3ThemeSingleton.get_instance().get_color(&"surface_container_high")
	await H.assert_pixel(self, stage, stage.point_of(dlg.get_dialog_card(), Vector2(280, 28)), surf_high, 0.08, "dialog card uses surface_container_high")
	H.cover(self, "containment.dialog.basic", "element", snap)

	# Record clicking the Confirm button to confirm and close
	var confirm_btn := dlg.get_confirm_button()
	var live_confirm: Dictionary = await H.record(stage, "containment.dialog.basic", "confirm_click", func() -> void:
		await stage.click(confirm_btn, Vector2.INF, 3)
		await stage.wait(14)
	, 8, dlg)

	H.assert_recording(self, live_confirm, "basic dialog confirm interaction")
	assert_eq(confirmed_cnt[0], 1, "clicking confirm button emitted confirmed")
	H.assert_mutated(self, live_confirm, "BasicDialog", "script_variables.is_open", false)
	H.cover(self, "containment.dialog.basic", "interaction", live_confirm)

	# Also verify scrim click dismissal
	dlg.open()
	await stage.wait(16)
	await stage.click_at(Vector2(40, 40), 2)
	await stage.wait(14)
	assert_eq(dismissed_cnt[0], 1, "clicking scrim dismissed basic dialog")
	stage.dispose()

# ==============================================================================
# 6. FULL-SCREEN DIALOG (containment.dialog.fullscreen)
# ==============================================================================

func test_fullscreen_dialog_variants_and_interaction() -> void:
	var stage = await H.create_stage(self, "containment", "dialog_fullscreen", false)

	var fs_dlg := M3Dialog.new()
	fs_dlg.name = "FullscreenDialog"
	fs_dlg.size = Vector2(H.STAGE_SIZE)
	fs_dlg.fullscreen = true
	fs_dlg.headline = "Create Event"
	fs_dlg.supporting_text = "All-day conference at Moscone Center."
	fs_dlg.confirm_text = "Save"
	stage.add(fs_dlg, Vector2.ZERO)

	var saved_cnt: Array[int] = [0]
	fs_dlg.confirmed.connect(func() -> void: saved_cnt[0] += 1)

	# Record opening full-screen dialog
	var live_open: Dictionary = await H.record(stage, "containment.dialog.fullscreen", "open_fullscreen", func() -> void:
		fs_dlg.open()
		await stage.wait(16)
	, 8, fs_dlg)

	H.assert_recording(self, live_open, "fullscreen dialog open")
	H.assert_mutated(self, live_open, "FullscreenDialog", "script_variables.is_open", true)
	H.assert_animated(self, live_open, "FullscreenDialog", "script_variables.open_progress", 4, "fullscreen dialog open_progress animated")
	H.cover(self, "containment.dialog.fullscreen", "animation", live_open)

	# Snapshot open full-screen dialog
	var snap: Dictionary = await H.snapshot(stage, "containment.dialog.fullscreen", "open_header_and_body")
	H.assert_snapshot(self, snap, [DIALOG_SCRIPT], "fullscreen dialog open")

	var panel_node: Dictionary = H.node_entry(snap, "FullscreenPanel")
	var header_node: Dictionary = H.node_entry(snap, "FullscreenHeaderBar")
	assert_approx(float(panel_node.get("screen_rect", {}).get("width", 0.0)), 1280.0, 2.0, "Fullscreen dialog fills viewport width")
	assert_approx(float(panel_node.get("screen_rect", {}).get("height", 0.0)), 720.0, 2.0, "Fullscreen dialog fills viewport height")
	assert_approx(float(header_node.get("screen_rect", {}).get("height", 0.0)), 56.0, 2.0, "Fullscreen dialog header bar is 56dp high")

	var surf := M3ThemeSingleton.get_instance().get_color(&"surface")
	await H.assert_pixel(self, stage, Vector2(640, 360), surf, 0.08, "fullscreen dialog surface color")
	H.cover(self, "containment.dialog.fullscreen", "element", snap)

	# Click the Save button in the header bar
	var save_btn := fs_dlg.get_confirm_button()
	var live_save: Dictionary = await H.record(stage, "containment.dialog.fullscreen", "save_action", func() -> void:
		await stage.click(save_btn, Vector2.INF, 3)
		await stage.wait(14)
	, 8, fs_dlg)

	H.assert_recording(self, live_save, "fullscreen dialog save click")
	assert_eq(saved_cnt[0], 1, "Save button emitted confirmed")
	H.assert_mutated(self, live_save, "FullscreenDialog", "script_variables.is_open", false)
	H.cover(self, "containment.dialog.fullscreen", "interaction", live_save)
	stage.dispose()

# ==============================================================================
# 7. BOTTOM SHEET (containment.bottom_sheet)
# ==============================================================================

func test_bottom_sheet_variants_and_interaction() -> void:
	var stage = await H.create_stage(self, "containment", "bottom_sheet", false)

	var sheet := M3BottomSheet.new()
	sheet.name = "ModalBottomSheet"
	sheet.size = Vector2(H.STAGE_SIZE)
	sheet.sheet_type = M3BottomSheet.SheetType.MODAL
	sheet.sheet_height = 280.0
	sheet.title = "Share with contacts"
	var list_item := M3ListItem.new()
	list_item.headline = "Copy link to clipboard"
	sheet.add_content(list_item)
	stage.add(sheet, Vector2.ZERO)

	# Record opening the modal bottom sheet
	var live_open: Dictionary = await H.record(stage, "containment.bottom_sheet", "open_slide_up", func() -> void:
		sheet.open_sheet()
		await stage.wait(22)
	, 8, sheet)

	H.assert_recording(self, live_open, "bottom sheet open slide")
	H.assert_mutated(self, live_open, "ModalBottomSheet", "script_variables.is_open", true)
	H.assert_animated(self, live_open, "ModalBottomSheet", "script_variables.open_progress", 4, "bottom sheet open_progress animated")
	H.cover(self, "containment.bottom_sheet", "animation", live_open)

	# Snapshot while open
	var snap: Dictionary = await H.snapshot(stage, "containment.bottom_sheet", "modal_open")
	H.assert_snapshot(self, snap, [BOTTOM_SHEET_SCRIPT], "bottom sheet modal open")

	var handle_node: Dictionary = H.node_entry(snap, "DragHandle")
	assert_approx(float(handle_node.get("screen_rect", {}).get("width", 0.0)), 32.0, 1.0, "Drag handle width is 32dp")
	assert_approx(float(handle_node.get("screen_rect", {}).get("height", 0.0)), 4.0, 1.0, "Drag handle height is 4dp")

	var surf_low := M3ThemeSingleton.get_instance().get_color(&"surface_container_low")
	await H.assert_pixel(self, stage, stage.point_of(sheet.get_sheet_panel(), Vector2(400, 120)), surf_low, 0.08, "bottom sheet panel surface_container_low")
	H.cover(self, "containment.bottom_sheet", "element", snap)

	# Drag the drag handle down to dismiss
	var drag_handle_ctrl := sheet.get_drag_handle()
	var live_drag: Dictionary = await H.record(stage, "containment.bottom_sheet", "drag_handle_dismiss", func() -> void:
		var start_p: Vector2 = stage.point_of(drag_handle_ctrl)
		await stage.drag_points(start_p, start_p + Vector2(0, 140), 10)
		await stage.wait(16)
	, 8, sheet)

	H.assert_recording(self, live_drag, "bottom sheet drag dismiss")
	H.assert_mutated(self, live_drag, "ModalBottomSheet", "script_variables.is_open", false)
	H.assert_animated(self, live_drag, "ModalBottomSheet", "script_variables.open_progress", 4)
	H.cover(self, "containment.bottom_sheet", "interaction", live_drag)
	stage.dispose()

# ==============================================================================
# 8. SIDE SHEET (containment.side_sheet)
# ==============================================================================

func test_side_sheet_variants_and_interaction() -> void:
	var stage = await H.create_stage(self, "containment", "side_sheet", false)

	# Standard coplanar side sheet on left half
	var std_sheet := M3SideSheet.new()
	std_sheet.name = "StandardSideSheet"
	std_sheet.sheet_type = M3SideSheet.SheetType.STANDARD
	std_sheet.sheet_width = 300.0
	std_sheet.size = Vector2(300, 560)
	std_sheet.title = "Standard Sheet"
	std_sheet.show_back_button = true
	std_sheet.show_action_buttons = true
	var std_lbl := Label.new()
	std_lbl.text = "Coplanar side sheet content"
	std_sheet.add_content(std_lbl)
	stage.add(std_sheet, Vector2(40, 80))

	# Modal side sheet docked to right edge of stage
	var modal_sheet := M3SideSheet.new()
	modal_sheet.name = "ModalSideSheet"
	modal_sheet.sheet_type = M3SideSheet.SheetType.MODAL
	modal_sheet.sheet_edge = M3SideSheet.SheetEdge.RIGHT
	modal_sheet.sheet_width = 320.0
	modal_sheet.size = Vector2(H.STAGE_SIZE)
	modal_sheet.title = "Filters"
	modal_sheet.show_action_buttons = true
	var mod_lbl := Label.new()
	mod_lbl.text = "Modal side sheet with scrim"
	modal_sheet.add_content(mod_lbl)
	stage.add(modal_sheet, Vector2.ZERO)

	var snap: Dictionary = await H.snapshot(stage, "containment.side_sheet", "standard_and_modal")
	H.assert_snapshot(self, snap, [SIDE_SHEET_SCRIPT], "side sheet variants")

	var modal_panel: PanelContainer = modal_sheet.get_sheet_panel()
	assert_approx(modal_panel.size.x, 320.0, 1.0, "Modal side sheet width is 320dp")
	assert_approx(modal_panel.position.x, 1280.0 - 320.0, 1.0, "Right-docked modal side sheet sits at x = 960")

	var surf_low := M3ThemeSingleton.get_instance().get_color(&"surface_container_low")
	await H.assert_pixel(self, stage, stage.point_of(modal_panel, Vector2(200, 260)), surf_low, 0.08, "modal side sheet surface_container_low")
	H.cover(self, "containment.side_sheet", "element", snap)

	# Click close button on ModalSideSheet to animate close, then re-open
	var close_btn := modal_sheet.get_close_button()
	var live: Dictionary = await H.record(stage, "containment.side_sheet", "close_and_reopen", func() -> void:
		await stage.click(close_btn, Vector2.INF, 3)
		await stage.wait(16)
		modal_sheet.open()
		await stage.wait(18)
	, 10, modal_sheet)

	H.assert_recording(self, live, "side sheet close and reopen")
	H.assert_event(self, live, "script_variable_changed", "ModalSideSheet", "is_open")
	H.assert_animated(self, live, "ModalSideSheet", "script_variables.open_progress", 4, "side sheet open_progress animated")
	H.cover(self, "containment.side_sheet", "interaction", live)
	H.cover(self, "containment.side_sheet", "animation", live)
	stage.dispose()

# ==============================================================================
# 9. CONTAINMENT REGISTRY COVERAGE GATE
# ==============================================================================

func test_zz_containment_family_coverage_verified() -> void:
	var cov: Dictionary = H.compute_coverage()
	var containment_count: int = 0
	for it in cov.get("items", []):
		if str(it.get("category", "")) == "Containment":
			containment_count += 1
			assert_true(
				bool(it.get("verified", false)),
				"Containment spec '%s' verified (missing kinds=%s, scripts=%s)" % [
					str(it.get("id", "")),
					str(it.get("missing_kinds", [])),
					str(it.get("missing_scripts", []))
				]
			)
	assert_eq(containment_count, 8, "All 8 Containment spec elements present and verified")

