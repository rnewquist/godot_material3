@tool
class_name ShowcaseSelectionScreen
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
	title_lbl.text = "Selection Controls"
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)
	
	# Section 1: Checkboxes
	var sec1 := _create_section(vbox, "Checkboxes", "Unchecked, Checked, and Indeterminate states.")
	var cb_row := HBoxContainer.new()
	cb_row.add_theme_constant_override("separation", 24)
	sec1.add_child(cb_row)
	
	var cb1 := M3Checkbox.new()
	cb1.text = "Unchecked"
	cb1.checked = false
	cb_row.add_child(cb1)
	
	var cb2 := M3Checkbox.new()
	cb2.text = "Checked"
	cb2.checked = true
	cb_row.add_child(cb2)
	
	var cb3 := M3Checkbox.new()
	cb3.text = "Indeterminate"
	cb3.indeterminate = true
	cb_row.add_child(cb3)

	var cb4 := M3Checkbox.new()
	cb4.text = "Error"
	cb4.checked = true
	cb4.is_error = true
	cb_row.add_child(cb4)

	var cb5 := M3Checkbox.new()
	cb5.text = "Disabled"
	cb5.checked = true
	cb5.disabled = true
	cb_row.add_child(cb5)
	
	# Section 2: Radio Buttons
	var sec2 := _create_section(vbox, "Radio Buttons", "Single-selection group options.")
	var radio_box := VBoxContainer.new()
	radio_box.add_theme_constant_override("separation", 8)
	sec2.add_child(radio_box)
	
	var r1 := M3Radio.new()
	r1.text = "Option A (High priority)"
	r1.group_name = "priority_group"
	r1.selected = true
	radio_box.add_child(r1)
	
	var r2 := M3Radio.new()
	r2.text = "Option B (Normal priority)"
	r2.group_name = "priority_group"
	radio_box.add_child(r2)
	
	var r3 := M3Radio.new()
	r3.text = "Option C (Low priority)"
	r3.group_name = "priority_group"
	radio_box.add_child(r3)
	
	# Section 3: Switches
	var sec3 := _create_section(vbox, "Switches", "Toggle switches for immediate state changes.")
	var sw_row := HBoxContainer.new()
	sw_row.add_theme_constant_override("separation", 24)
	sec3.add_child(sw_row)
	
	var sw1 := M3Switch.new()
	sw1.text = "Wi-Fi"
	sw1.selected = true
	sw_row.add_child(sw1)
	
	var sw2 := M3Switch.new()
	sw2.text = "Bluetooth"
	sw2.selected = false
	sw_row.add_child(sw2)

	var sw3 := M3Switch.new()
	sw3.text = "Notifications"
	sw3.show_icons = true
	sw3.selected = true
	sw_row.add_child(sw3)

	var sw4 := M3Switch.new()
	sw4.text = "Disabled"
	sw4.disabled = true
	sw_row.add_child(sw4)
	
	# Section 4: Sliders
	var sec4 := _create_section(vbox, "Sliders", "Continuous, Discrete, and Range sliders.")
	var sl_vbox := VBoxContainer.new()
	sl_vbox.add_theme_constant_override("separation", 16)
	sec4.add_child(sl_vbox)
	
	var sl_lbl1 := Label.new()
	sl_lbl1.text = "Continuous Slider (0 - 100):"
	sl_vbox.add_child(sl_lbl1)
	var sl1 := M3Slider.new()
	sl1.value = 45.0
	sl_vbox.add_child(sl1)
	
	var sl_lbl2 := Label.new()
	sl_lbl2.text = "Discrete Slider with steps (0 - 100, step 10):"
	sl_vbox.add_child(sl_lbl2)
	var sl2 := M3Slider.new()
	sl2.is_discrete = true
	sl2.step = 10.0
	sl2.value = 60.0
	sl_vbox.add_child(sl2)
	
	var sl_lbl3 := Label.new()
	sl_lbl3.text = "Range Slider (20 - 80):"
	sl_vbox.add_child(sl_lbl3)
	var sl3 := M3Slider.new()
	sl3.range_mode = true
	sl3.range_min_value = 25.0
	sl3.range_max_value = 75.0
	sl_vbox.add_child(sl3)

	var sl_lbl4 := Label.new()
	sl_lbl4.text = "Expressive Centered-Zero Slider (-100 to 100):"
	sl_vbox.add_child(sl_lbl4)
	var sl4 := M3Slider.new()
	sl4.slider_size = M3Slider.SliderSize.MEDIUM
	sl4.centered_zero = true
	sl4.min_value = -100.0
	sl4.max_value = 100.0
	sl4.value = 35.0
	sl_vbox.add_child(sl4)

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
