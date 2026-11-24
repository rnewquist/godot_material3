@tool
class_name ShowcaseButtonsScreen
extends ScrollContainer

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

	# Title
	var title_lbl := Label.new()
	title_lbl.text = "Common Buttons, Groups, Split Buttons & FABs"
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", M3ThemeSingleton.get_instance().get_color(&"on_surface"))
	vbox.add_child(title_lbl)

	# Section 1: Standard Buttons
	var sec1 := _create_section(vbox, "Button Variants", "Elevated, Filled, Filled Tonal, Outlined, and Text buttons.")
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	sec1.add_child(btn_row)

	var b_elev := M3Button.new()
	b_elev.variant = M3Button.Variant.ELEVATED
	b_elev.text = "Elevated"
	btn_row.add_child(b_elev)

	var b_filled := M3Button.new()
	b_filled.variant = M3Button.Variant.FILLED
	b_filled.text = "Filled"
	btn_row.add_child(b_filled)

	var b_tonal := M3Button.new()
	b_tonal.variant = M3Button.Variant.TONAL
	b_tonal.text = "Filled Tonal"
	btn_row.add_child(b_tonal)

	var b_out := M3Button.new()
	b_out.variant = M3Button.Variant.OUTLINED
	b_out.text = "Outlined"
	btn_row.add_child(b_out)

	var b_txt := M3Button.new()
	b_txt.variant = M3Button.Variant.TEXT
	b_txt.text = "Text"
	btn_row.add_child(b_txt)

	# Section 2: Icon Buttons
	var sec2 := _create_section(vbox, "Icon Buttons", "Standard, Filled, Filled Tonal, and Outlined toggleable icon buttons.")
	var icon_btn_row := HBoxContainer.new()
	icon_btn_row.add_theme_constant_override("separation", 16)
	sec2.add_child(icon_btn_row)

	var ib_std := M3IconButton.new()
	ib_std.variant = M3IconButton.Variant.STANDARD
	ib_std.icon_name = &"favorite"
	icon_btn_row.add_child(ib_std)

	var ib_fill := M3IconButton.new()
	ib_fill.variant = M3IconButton.Variant.FILLED
	ib_fill.icon_name = &"settings"
	icon_btn_row.add_child(ib_fill)

	var ib_tonal := M3IconButton.new()
	ib_tonal.variant = M3IconButton.Variant.TONAL
	ib_tonal.icon_name = &"edit"
	icon_btn_row.add_child(ib_tonal)

	var ib_out := M3IconButton.new()
	ib_out.variant = M3IconButton.Variant.OUTLINED
	ib_out.icon_name = &"add"
	icon_btn_row.add_child(ib_out)

	var exp_ib_row := HBoxContainer.new()
	exp_ib_row.add_theme_constant_override("separation", 16)
	sec2.add_child(exp_ib_row)

	for sz in [
		M3IconButton.ButtonSize.EXTRA_SMALL,
		M3IconButton.ButtonSize.SMALL,
		M3IconButton.ButtonSize.MEDIUM,
		M3IconButton.ButtonSize.LARGE,
		M3IconButton.ButtonSize.EXTRA_LARGE
	]:
		var eib := M3IconButton.new()
		eib.variant = M3IconButton.Variant.TONAL
		eib.button_size = sz
		eib.button_shape = M3IconButton.ButtonShape.SQUARE if (sz == M3IconButton.ButtonSize.MEDIUM or sz == M3IconButton.ButtonSize.EXTRA_LARGE) else M3IconButton.ButtonShape.ROUND
		eib.width_mode = M3IconButton.WidthMode.WIDE if sz == M3IconButton.ButtonSize.LARGE else (M3IconButton.WidthMode.NARROW if sz == M3IconButton.ButtonSize.SMALL else M3IconButton.WidthMode.DEFAULT)
		eib.toggle_mode = true
		eib.icon_name = &"favorite"
		eib.selected_icon_name = &"checkmark"
		exp_ib_row.add_child(eib)

	# Section 3: Floating Action Buttons (FABs) & FAB Menu
	var sec3 := _create_section(vbox, "Floating Action Buttons (FAB) & FAB Menu", "Small, Standard, Large, Extended FABs, and Expressive FAB Menu.")
	var fab_row := HBoxContainer.new()
	fab_row.add_theme_constant_override("separation", 20)
	fab_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	sec3.add_child(fab_row)

	var fab_sm := M3FAB.new()
	fab_sm.fab_variant = M3FAB.FabVariant.SMALL
	fab_row.add_child(fab_sm)

	var fab_std := M3FAB.new()
	fab_std.fab_variant = M3FAB.FabVariant.STANDARD
	fab_row.add_child(fab_std)

	var fab_lg := M3FAB.new()
	fab_lg.fab_variant = M3FAB.FabVariant.LARGE
	fab_row.add_child(fab_lg)

	var fab_ext := M3FAB.new()
	fab_ext.fab_variant = M3FAB.FabVariant.EXTENDED
	fab_ext.text = "Compose"
	fab_row.add_child(fab_ext)

	var fab_menu := M3FabMenu.new()
	fab_menu.add_item("New Doc", "edit")
	fab_menu.add_item("Upload", "add")
	fab_row.add_child(fab_menu)

	# Section 4: Segmented Buttons
	var sec4 := _create_section(vbox, "Segmented Buttons", "Single and Multi-select segmented button groups.")
	var seg1 := M3SegmentedButton.new()
	seg1.segments = [{"label": "Songs"}, {"label": "Albums"}, {"label": "Artists"}]
	sec4.add_child(seg1)

	# Section 5: Expressive Button Groups
	var sec5 := _create_section(vbox, "Expressive Button Groups", "Standard and Connected button groups with width morph animation.")
	var grp_row := HBoxContainer.new()
	grp_row.add_theme_constant_override("separation", 24)
	sec5.add_child(grp_row)

	var bg_std := M3ButtonGroup.new()
	bg_std.group_variant = M3ButtonGroup.GroupVariant.STANDARD
	bg_std.add_button("Day")
	bg_std.add_button("Week")
	bg_std.add_button("Month")
	grp_row.add_child(bg_std)

	var bg_conn := M3ButtonGroup.new()
	bg_conn.group_variant = M3ButtonGroup.GroupVariant.CONNECTED
	bg_conn.add_button("Reply", "edit")
	bg_conn.add_button("Forward", "share")
	bg_conn.add_button("Archive", "check")
	grp_row.add_child(bg_conn)

	# Section 6: Expressive Split Buttons
	var sec6 := _create_section(vbox, "Expressive Split Buttons", "Primary action paired with a trailing menu trigger and rotating chevron.")
	var split_row := HBoxContainer.new()
	split_row.add_theme_constant_override("separation", 20)
	sec6.add_child(split_row)

	for vt in [M3SplitButton.VariantType.FILLED, M3SplitButton.VariantType.TONAL, M3SplitButton.VariantType.ELEVATED, M3SplitButton.VariantType.OUTLINED]:
		var sb := M3SplitButton.new()
		sb.variant = vt
		sb.text = "Send"
		sb.leading_icon = &"send"
		sb.add_menu_item("Schedule send")
		sb.add_menu_item("Save draft")
		split_row.add_child(sb)

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
