@tool
class_name ShowcaseSurfacesScreen
extends ScrollContainer

var _dialog: M3Dialog
var _fullscreen_dialog: M3Dialog
var _bottom_sheet: M3BottomSheet
var _side_sheet: M3SideSheet

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build_ui()

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 32)
	pad.add_theme_constant_override("margin_right", 32)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_bottom", 48)
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pad.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "Surfaces & Containment"
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)

	# Section 1: Cards
	var sec1 := _create_section(vbox, "Cards", "Elevated, Filled, and Outlined cards.")
	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 16)
	sec1.add_child(card_row)

	var c_elev := M3Card.new()
	c_elev.card_type = M3Card.CardType.ELEVATED
	c_elev.custom_minimum_size = Vector2(160, 100)
	c_elev.clickable = true
	var lbl_e := Label.new()
	lbl_e.text = "Elevated Card\n(Clickable)"
	c_elev.add_child(lbl_e)
	card_row.add_child(c_elev)

	var c_fill := M3Card.new()
	c_fill.card_type = M3Card.CardType.FILLED
	c_fill.custom_minimum_size = Vector2(160, 100)
	var lbl_f := Label.new()
	lbl_f.text = "Filled Card"
	c_fill.add_child(lbl_f)
	card_row.add_child(c_fill)

	var c_out := M3Card.new()
	c_out.card_type = M3Card.CardType.OUTLINED
	c_out.custom_minimum_size = Vector2(160, 100)
	var lbl_o := Label.new()
	lbl_o.text = "Outlined Card"
	c_out.add_child(lbl_o)
	card_row.add_child(c_out)

	# Section 2: Carousel
	var sec_carousel := _create_section(vbox, "Carousel", "Multi-browse dynamic squishing carousel with 28dp rounded corners.")
	var carousel := M3Carousel.new()
	carousel.custom_minimum_size = Vector2(560, 190)
	sec_carousel.add_child(carousel)

	# Section 3: Dialogs, Bottom Sheet & Side Sheet
	var sec2 := _create_section(vbox, "Modals: Dialogs, Bottom Sheet & Side Sheet", "Trigger basic/full-screen dialogs, bottom sheets, and side sheets.")
	var mod_row := HBoxContainer.new()
	mod_row.add_theme_constant_override("separation", 12)
	sec2.add_child(mod_row)

	var btn_dlg := M3Button.new()
	btn_dlg.text = "Open Dialog"
	btn_dlg.pressed.connect(_open_dialog)
	mod_row.add_child(btn_dlg)

	var btn_fs_dlg := M3Button.new()
	btn_fs_dlg.variant = M3Button.Variant.OUTLINED
	btn_fs_dlg.text = "Full-Screen Dialog"
	btn_fs_dlg.pressed.connect(_open_fullscreen_dialog)
	mod_row.add_child(btn_fs_dlg)

	var btn_sheet := M3Button.new()
	btn_sheet.button_type = M3Button.ButtonType.FILLED_TONAL
	btn_sheet.text = "Open Bottom Sheet"
	btn_sheet.pressed.connect(_open_bottom_sheet)
	mod_row.add_child(btn_sheet)

	var btn_side := M3Button.new()
	btn_side.variant = M3Button.Variant.ELEVATED
	btn_side.text = "Open Side Sheet"
	btn_side.pressed.connect(_open_side_sheet)
	mod_row.add_child(btn_side)

	# Create Basic Dialog instance
	_dialog = M3Dialog.new()
	_dialog.headline = "Delete item?"
	_dialog.body_text = "This item will be permanently removed. This action cannot be undone."
	_dialog.confirm_label = "Delete"
	_dialog.cancel_label = "Cancel"
	add_child(_dialog)

	# Create Full-screen Dialog instance
	_fullscreen_dialog = M3Dialog.new()
	_fullscreen_dialog.fullscreen = true
	_fullscreen_dialog.headline = "New Calendar Event"
	_fullscreen_dialog.body_text = "Configure event details, attendees, and notifications."
	_fullscreen_dialog.confirm_label = "Save"
	add_child(_fullscreen_dialog)

	# Create Bottom Sheet instance
	_bottom_sheet = M3BottomSheet.new()
	_bottom_sheet.title = "Share Options"
	_bottom_sheet.sheet_height = 240.0
	add_child(_bottom_sheet)

	var sheet_content := VBoxContainer.new()
	sheet_content.add_theme_constant_override("separation", 8)
	var itm1 := M3ListItem.new()
	itm1.headline = "Copy link"
	sheet_content.add_child(itm1)
	var itm2 := M3ListItem.new()
	itm2.headline = "Send via Email"
	sheet_content.add_child(itm2)
	_bottom_sheet.add_content(sheet_content)

	# Create Modal Side Sheet instance
	_side_sheet = M3SideSheet.new()
	_side_sheet.sheet_type = M3SideSheet.SheetType.MODAL
	_side_sheet.title = "Filters"
	_side_sheet.show_action_buttons = true
	_side_sheet.is_open = false
	_side_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	var side_lbl := Label.new()
	side_lbl.text = "Refine search results by category and date."
	side_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side_sheet.add_content(side_lbl)
	add_child(_side_sheet)

	# Section 4: Lists
	var sec3 := _create_section(vbox, "Lists", "1-line, 2-line, and 3-line lists with dividers and avatar slots.")
	var list := M3List.new()
	list.with_dividers = true
	list.selectable = true
	sec3.add_child(list)

	var l1 := M3ListItem.new()
	l1.lines = M3ListItem.ItemLines.ONE_LINE
	l1.leading_type = M3ListItem.LeadingType.AVATAR
	l1.headline = "Alex Morgan"
	l1.trailing_type = M3ListItem.TrailingType.TEXT
	l1.trailing_text = "Online"
	list.add_child(l1)

	var l2 := M3ListItem.new()
	l2.lines = M3ListItem.ItemLines.TWO_LINE
	l2.leading_type = M3ListItem.LeadingType.AVATAR
	l2.headline = "Design Review Meeting"
	l2.supporting_text = "Scheduled for 3:00 PM tomorrow"
	l2.trailing_type = M3ListItem.TrailingType.TEXT
	l2.trailing_text = "10:45 AM"
	list.add_child(l2)

	var l3 := M3ListItem.new()
	l3.lines = M3ListItem.ItemLines.THREE_LINE
	l3.leading_type = M3ListItem.LeadingType.AVATAR
	l3.overline_text = "PROJECT UPDATE"
	l3.headline = "Material Design 3 Godot Port"
	l3.supporting_text = "Strictly typed, reactive styling with full tokens and components."
	l3.trailing_type = M3ListItem.TrailingType.TEXT
	l3.trailing_text = "Yesterday"
	list.add_child(l3)

func _open_dialog() -> void:
	if _dialog:
		_dialog.show_dialog()

func _open_fullscreen_dialog() -> void:
	if _fullscreen_dialog:
		_fullscreen_dialog.open()

func _open_bottom_sheet() -> void:
	if _bottom_sheet:
		_bottom_sheet.open_sheet()

func _open_side_sheet() -> void:
	if _side_sheet:
		_side_sheet.open()

func _create_section(parent: VBoxContainer, title: String, desc: String) -> VBoxContainer:
	var sec_card := M3Card.new()
	sec_card.card_type = M3Card.CardType.OUTLINED
	parent.add_child(sec_card)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	sec_card.add_child(inner)

	var head := Label.new()
	head.text = title
	head.add_theme_font_size_override("font_size", 18)
	inner.add_child(head)

	var d := Label.new()
	d.text = desc
	d.add_theme_font_size_override("font_size", 13)
	inner.add_child(d)

	var div := M3Divider.new()
	inner.add_child(div)

	return inner
