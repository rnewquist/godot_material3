@tool
class_name ShowcaseInputsScreen
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

	var title_lbl := Label.new()
	title_lbl.text = "Text Fields, Select & Pickers"
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)

	# Section 1: Filled Text Fields
	var sec1 := _create_section(vbox, "Filled Text Fields", "Standard filled style with floating label.")
	var tf1 := M3TextField.new()
	tf1.field_type = M3TextField.FieldType.FILLED
	tf1.label = "User Name"
	tf1.text = "John Doe"
	sec1.add_child(tf1)

	# Section 2: Outlined Text Fields
	var sec2 := _create_section(vbox, "Outlined Text Fields", "Outlined style with password visibility toggle & character counter.")
	var tf2 := M3TextField.new()
	tf2.field_type = M3TextField.FieldType.OUTLINED
	tf2.label = "Password"
	tf2.text = "SecretPass123"
	tf2.is_password = true
	tf2.supporting_text = "Must be at least 8 characters"
	sec2.add_child(tf2)

	var tf3 := M3TextField.new()
	tf3.field_type = M3TextField.FieldType.OUTLINED
	tf3.label = "Bio"
	tf3.text = "Godot 4 enthusiast"
	tf3.max_characters = 50
	sec3(sec2, tf3)

	var tf_affix := M3TextField.new()
	tf_affix.field_type = M3TextField.FieldType.OUTLINED
	tf_affix.label = "Price"
	tf_affix.prefix_text = "$"
	tf_affix.suffix_text = "USD"
	tf_affix.text = "49.99"
	sec2.add_child(tf_affix)

	var tf_multi := M3TextField.new()
	tf_multi.field_type = M3TextField.FieldType.OUTLINED
	tf_multi.label = "Notes"
	tf_multi.multiline = true
	tf_multi.min_lines = 3
	tf_multi.max_lines = 6
	tf_multi.text = "Line 1\nLine 2\nLine 3"
	sec2.add_child(tf_multi)

	# Section 3: Select Dropdown
	var sec_drop := _create_section(vbox, "Select Dropdown", "Exposed dropdown menu for single item selection.")
	var sel := M3Select.new()
	sel.label = "Department"
	sel.options = ["Engineering", "Design", "Product", "Operations"]
	sel.selected_index = 0
	sec_drop.add_child(sel)

	var drop := M3SelectDropdown.new()
	drop.label = "Select Role"
	drop.options = ["Administrator", "Editor", "Contributor", "Viewer"]
	sec_drop.add_child(drop)

	# Section 4: Date & Time Pickers
	var sec_pickers := _create_section(vbox, "Date & Time Pickers", "Material 3 modal calendar date picker and analog dial time picker.")
	var picker_row := HFlowContainer.new()
	picker_row.add_theme_constant_override("h_separation", 24)
	picker_row.add_theme_constant_override("v_separation", 24)
	sec_pickers.add_child(picker_row)

	var date_picker := M3DatePicker.new()
	date_picker.name = "ShowcaseDatePicker"
	picker_row.add_child(date_picker)

	var time_picker := M3TimePicker.new()
	time_picker.name = "ShowcaseTimePicker"
	picker_row.add_child(time_picker)

func sec3(sec: VBoxContainer, ctrl: Control) -> void:
	sec.add_child(ctrl)

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
