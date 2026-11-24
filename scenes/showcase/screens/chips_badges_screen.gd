@tool
class_name ShowcaseChipsBadgesScreen
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
	title_lbl.text = "Chips, Badges & Tooltips"
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)
	
	# Section 1: Chips
	var sec1 := _create_section(vbox, "Material 3 Chips", "Assist, Filter (toggleable), Input (removable), and Suggestion chips.")
	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 12)
	sec1.add_child(chip_row)
	
	var c_assist := M3Chip.new()
	c_assist.chip_type = M3Chip.ChipType.ASSIST
	c_assist.icon_name = &"schedule"
	c_assist.text = "Set Alarm"
	chip_row.add_child(c_assist)
	
	var c_filter := M3Chip.new()
	c_filter.chip_type = M3Chip.ChipType.FILTER
	c_filter.text = "Price < $50"
	c_filter.selected = true
	chip_row.add_child(c_filter)
	
	var c_input := M3Chip.new()
	c_input.chip_type = M3Chip.ChipType.INPUT
	c_input.avatar_text = "J"
	c_input.text = "John Doe"
	c_input.deleted.connect(func(): c_input.queue_free())
	chip_row.add_child(c_input)
	
	var c_sugg := M3Chip.new()
	c_sugg.chip_type = M3Chip.ChipType.SUGGESTION
	c_sugg.text = "Turn on Wi-Fi"
	chip_row.add_child(c_sugg)

	var c_elev := M3Chip.new()
	c_elev.chip_type = M3Chip.ChipType.ASSIST
	c_elev.elevated = true
	c_elev.text = "Elevated Chip"
	chip_row.add_child(c_elev)
	
	# Section 2: Badges
	var sec2 := _create_section(vbox, "Badges", "Small 6dp notification dot and Large 16dp count pills.")
	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 36)
	sec2.add_child(badge_row)
	
	# Icon Button with Small Badge
	var b_icon_host1 := Control.new()
	b_icon_host1.custom_minimum_size = Vector2(48, 48)
	badge_row.add_child(b_icon_host1)
	
	var ib1 := M3IconButton.new()
	ib1.icon_button_type = M3IconButton.IconBtnType.FILLED_TONAL
	b_icon_host1.add_child(ib1)
	
	var badge_sm := M3Badge.new()
	badge_sm.badge_size = M3Badge.BadgeSize.SMALL
	badge_sm.anchor_to_target = true
	b_icon_host1.add_child(badge_sm)
	
	# Icon Button with Count Badge (3)
	var b_icon_host2 := Control.new()
	b_icon_host2.custom_minimum_size = Vector2(48, 48)
	badge_row.add_child(b_icon_host2)
	
	var ib2 := M3IconButton.new()
	ib2.icon_button_type = M3IconButton.IconBtnType.FILLED_TONAL
	b_icon_host2.add_child(ib2)
	
	var badge_num := M3Badge.new()
	badge_num.badge_size = M3Badge.BadgeSize.LARGE
	badge_num.count = 3
	badge_num.anchor_to_target = true
	b_icon_host2.add_child(badge_num)
	
	# Button with Overflow Badge (99+)
	var b_icon_host3 := Control.new()
	b_icon_host3.custom_minimum_size = Vector2(48, 48)
	badge_row.add_child(b_icon_host3)
	
	var ib3 := M3IconButton.new()
	ib3.icon_button_type = M3IconButton.IconBtnType.FILLED_TONAL
	b_icon_host3.add_child(ib3)
	
	var badge_max := M3Badge.new()
	badge_max.badge_size = M3Badge.BadgeSize.LARGE
	badge_max.count = 150
	badge_max.anchor_to_target = true
	b_icon_host3.add_child(badge_max)
	
	# Section 3: Tooltips
	var sec3 := _create_section(vbox, "Tooltips", "Hover over targets to inspect Plain and Rich tooltips.")
	var tip_row := HBoxContainer.new()
	tip_row.add_theme_constant_override("separation", 24)
	sec3.add_child(tip_row)
	
	# Plain Tooltip Host
	var btn_tip1 := M3Button.new()
	btn_tip1.text = "Hover for Plain Tooltip"
	tip_row.add_child(btn_tip1)
	
	var tip_plain := M3Tooltip.new()
	tip_plain.tooltip_type = M3Tooltip.TooltipType.PLAIN
	tip_plain.text = "Save changes to file"
	btn_tip1.add_child(tip_plain)
	
	# Rich Tooltip Host
	var btn_tip2 := M3Button.new()
	btn_tip2.variant = M3Button.Variant.OUTLINED
	btn_tip2.text = "Hover for Rich Tooltip"
	tip_row.add_child(btn_tip2)
	
	var tip_rich := M3Tooltip.new()
	tip_rich.tooltip_type = M3Tooltip.TooltipType.RICH
	tip_rich.title = "Cloud Synchronization"
	tip_rich.text = "Files are synced with the Material 3 server in real time."
	tip_rich.action_text = "Learn More"
	btn_tip2.add_child(tip_rich)

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
