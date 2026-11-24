class_name TestM3ContainmentFamily
extends GDTestSuite

## Unit tests for the Material 3 Containment family:
## M3BottomSheet, M3Card, M3Carousel, M3Dialog (basic & fullscreen), M3Divider, M3List/M3ListItem, and M3SideSheet.

func _init() -> void:
	suite_name = "M3_Containment_Family_Unit"
	test_type = "unit"

func test_bottom_sheet_variants_and_lifecycle() -> void:
	var sheet := auto_add_child(M3BottomSheet.new()) as M3BottomSheet
	sheet.sheet_type = M3BottomSheet.SheetType.MODAL
	sheet.sheet_height = 240.0
	sheet.title = "Modal Options"
	await wait_frames(2)

	assert_eq(sheet.corner_radius, 28, "Bottom sheet top corner radius should be 28dp")
	assert_false(sheet.is_open, "Bottom sheet starts closed by default")

	var lbl := Label.new()
	lbl.text = "Sheet Item"
	sheet.add_content(lbl)
	assert_eq(lbl.get_parent(), sheet.get_content_container(), "add_content attaches child to content container")

	sheet.open_sheet()
	assert_true(sheet.is_open, "open_sheet marks is_open true")
	assert_true(sheet.visible, "open_sheet makes sheet visible")
	await get_tree().create_timer(0.35).timeout
	assert_approx(sheet.open_progress, 1.0, 0.05, "open_progress reaches 1.0 when open")

	sheet.close_sheet()
	assert_false(sheet.is_open, "close_sheet marks is_open false")

func test_card_variants_clickable_and_draggable() -> void:
	var card := auto_add_child(M3Card.new()) as M3Card
	card.card_type = M3Card.CardType.ELEVATED
	card.is_clickable = true
	card.is_draggable = true
	await wait_frames(2)

	assert_eq(card.corner_radius, 12, "M3Card default corner radius is 12dp")
	assert_true(card.clickable, "is_clickable alias updates clickable")
	assert_true(card.draggable, "is_draggable alias updates draggable")
	assert_approx(card._current_elevation, 1.0, 0.01, "Elevated card starts at elevation 1")

	card.card_type = M3Card.CardType.FILLED
	assert_approx(card._current_elevation, 0.0, 0.01, "Filled card rests at elevation 0")

	card.card_type = M3Card.CardType.OUTLINED
	assert_approx(card._current_elevation, 0.0, 0.01, "Outlined card rests at elevation 0")

func test_carousel_styles_and_dynamic_squishing() -> void:
	var carousel := auto_add_child(M3Carousel.new()) as M3Carousel
	carousel.size = Vector2(540, 200)
	carousel.clear_items()
	carousel.add_item("One", "First")
	carousel.add_item("Two", "Second")
	carousel.add_item("Three", "Third")
	carousel.add_item("Four", "Fourth")
	await wait_frames(2)

	assert_eq(carousel.get_item_count(), 4, "Carousel has 4 items")
	assert_eq(carousel.carousel_style, M3Carousel.CarouselStyle.MULTI_BROWSE)
	assert_approx(carousel.corner_radius, 28.0, 0.01, "Carousel item corner radius is 28dp")

	# Focal item (index 0) is large (~280dp), adjacent (index 1) is medium (~140dp), peek (index 2+) is small (56dp)
	assert_gte(carousel.get_item_width(0), 260.0, "Focal item has large width")
	assert_gt(carousel.get_item_width(0), carousel.get_item_width(1), "Focal item is wider than medium item")
	assert_gt(carousel.get_item_width(1), carousel.get_item_width(2), "Medium item is wider than small peek item")
	assert_approx(carousel.get_item_width(2), 56.0, 1.0, "Peek item is 56dp wide")

	# Scroll to index 2 non-animated
	carousel.scroll_to_index(2, false)
	assert_eq(carousel.active_index, 2, "active_index updated to 2")
	assert_gte(carousel.get_item_width(2), 260.0, "Item 2 is now the large focal item")
	assert_approx(carousel.get_item_width(0), 56.0, 1.0, "Item 0 squished to small peek width")

	# Hero style
	carousel.style = M3Carousel.CarouselStyle.HERO
	carousel.scroll_to_index(0, false)
	assert_gte(carousel.get_item_width(0), 260.0, "Hero focal item is large")
	assert_approx(carousel.get_item_width(1), 56.0, 1.0, "Hero non-focal item is 56dp peek")

	# Uncontained style
	carousel.style = M3Carousel.CarouselStyle.UNCONTAINED
	assert_approx(carousel.get_item_width(0), carousel. get_item_width(1), 0.01, "Uncontained items share equal width")

	# Fullscreen style
	carousel.style = M3Carousel.CarouselStyle.FULL_SCREEN
	assert_approx(carousel.get_item_width(0), 540.0, 0.01, "Full-screen item matches carousel width")

func test_dialog_basic_and_fullscreen_variants() -> void:
	var dlg := auto_add_child(M3Dialog.new()) as M3Dialog
	dlg.headline = "Discard draft?"
	dlg.supporting_text = "Your unsaved changes will be lost."
	dlg.confirm_text = "Discard"
	dlg.cancel_text = "Keep editing"
	dlg.icon_name = &"delete"
	await wait_frames(2)

	assert_eq(dlg.corner_radius, 28, "Basic dialog corner radius is 28dp")
	assert_eq(dlg.body_text, "Your unsaved changes will be lost.")
	assert_eq(dlg.confirm_label, "Discard")
	assert_false(dlg.fullscreen, "Default dialog is basic")

	dlg.open()
	assert_true(dlg.is_open, "Dialog is_open true after open()")
	assert_true(dlg.visible, "Dialog visible after open()")
	await get_tree().create_timer(0.3).timeout
	assert_approx(dlg.open_progress, 1.0, 0.05, "Basic dialog open_progress reaches 1.0")

	# Switch to Full-screen variant
	dlg.fullscreen = true
	await wait_frames(2)
	assert_eq(dlg.dialog_variant, M3Dialog.DialogVariant.FULLSCREEN)
	assert_not_null(dlg.get_close_button(), "Full-screen dialog has a header close icon button")
	assert_not_null(dlg.get_confirm_button(), "Full-screen dialog has a header confirm text button")

func test_divider_orientations_and_inset_modes() -> void:
	var div := auto_add_child(M3Divider.new()) as M3Divider
	div.size = Vector2(300, 1)
	assert_eq(div.inset_mode, M3Divider.InsetMode.FULL_WIDTH)
	assert_approx(div.inset_start, 0.0, 0.01)
	assert_approx(div.inset_end, 0.0, 0.01)

	div.inset_mode = M3Divider.InsetMode.INSET
	assert_approx(div.inset_start, 16.0, 0.01, "INSET mode sets 16dp start inset")
	assert_approx(div.inset_end, 0.0, 0.01, "INSET mode keeps 0dp end inset")

	div.inset_mode = M3Divider.InsetMode.MIDDLE_INSET
	assert_approx(div.inset_start, 16.0, 0.01, "MIDDLE_INSET sets 16dp start inset")
	assert_approx(div.inset_end, 16.0, 0.01, "MIDDLE_INSET sets 16dp end inset")

	div.orientation = M3Divider.DividerOrientation.VERTICAL
	assert_approx(div.custom_minimum_size.x, 1.0, 0.01, "Vertical divider has 1dp minimum width")

func test_list_and_list_items_selection_and_heights() -> void:
	var list := auto_add_child(M3List.new()) as M3List
	list.with_dividers = true
	list.selectable = true

	var item1 := M3ListItem.new()
	item1.lines = M3ListItem.ItemLines.ONE_LINE
	item1.headline = "One Line"
	list.add_item(item1)

	var item2 := M3ListItem.new()
	item2.lines = M3ListItem.ItemLines.TWO_LINE
	item2.headline = "Two Line"
	item2.supporting_text = "Second line text"
	list.add_item(item2)

	var item3 := M3ListItem.new()
	item3.lines = M3ListItem.ItemLines.THREE_LINE
	item3.headline = "Three Line"
	item3.supporting_text = "Line two\nLine three"
	list.add_item(item3)

	await wait_frames(2)
	assert_approx(item1.custom_minimum_size.y, 56.0, 0.01)
	assert_approx(item2.custom_minimum_size.y, 72.0, 0.01)
	assert_approx(item3.custom_minimum_size.y, 88.0, 0.01)

	list.select_item(1)
	assert_eq(list.selected_index, 1)
	assert_false(item1.selected)
	assert_true(item2.selected)
	assert_false(item3.selected)

func test_side_sheet_standard_and_modal() -> void:
	var side := auto_add_child(M3SideSheet.new()) as M3SideSheet
	side.size = Vector2(800, 600)
	side.sheet_type = M3SideSheet.SheetType.STANDARD
	side.sheet_width = 320.0
	side.title = "Inspector"
	side.show_back_button = true
	side.show_action_buttons = true
	await wait_frames(2)

	assert_true(side.get_back_button().visible, "Back button visible when show_back_button is true")
	assert_true(side.get_close_button().visible, "Close button visible by default")
	assert_true(side.get_confirm_button().is_visible_in_tree(), "Confirm action button visible")

	var body_lbl := Label.new()
	body_lbl.text = "Details"
	side.add_content(body_lbl)
	assert_eq(body_lbl.get_parent(), side.get_content_container())

	# Test modal open/close animation
	side.sheet_type = M3SideSheet.SheetType.MODAL
	side.close()
	await get_tree().create_timer(0.3).timeout
	assert_false(side.is_open)
	assert_approx(side.open_progress, 0.0, 0.05)

	side.open()
	await get_tree().create_timer(0.32).timeout
	assert_true(side.is_open)
	assert_approx(side.open_progress, 1.0, 0.05)
