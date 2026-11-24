@tool
class_name ShowcaseProgressScreen
extends ScrollContainer

var _linear_det: M3LinearProgress
var _linear_wavy_det: M3LinearProgress
var _circular_det: M3CircularProgress
var _circular_wavy_det: M3CircularProgress
var _menu: M3Menu

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
	title_lbl.text = "Progress & Feedback"
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)
	
	# Section 1: Progress Indicators
	var sec1 := _create_section(vbox, "Progress Indicators", "Determinate and Indeterminate Linear and Circular progress.")
	
	var sl_row := HBoxContainer.new()
	sl_row.add_theme_constant_override("separation", 16)
	sec1.add_child(sl_row)
	
	var sl_lbl := Label.new()
	sl_lbl.text = "Progress Value:"
	sl_row.add_child(sl_lbl)
	
	var prog_slider := M3Slider.new()
	prog_slider.min_value = 0.0
	prog_slider.max_value = 1.0
	prog_slider.step = 0.01
	prog_slider.value = 0.65
	prog_slider.value_changed.connect(_on_slider_value_changed)
	sl_row.add_child(prog_slider)
	
	# Linear Progress indicators
	var lin_lbl1 := Label.new()
	lin_lbl1.text = "Determinate Linear Progress:"
	sec1.add_child(lin_lbl1)
	
	_linear_det = M3LinearProgress.new()
	_linear_det.value = 0.65
	sec1.add_child(_linear_det)
	
	var lin_lbl2 := Label.new()
	lin_lbl2.text = "Indeterminate Linear Progress:"
	sec1.add_child(lin_lbl2)
	
	var linear_indet := M3LinearProgress.new()
	linear_indet.indeterminate = true
	sec1.add_child(linear_indet)

	var lin_wavy_lbl := Label.new()
	lin_wavy_lbl.text = "Expressive Wavy Linear Progress:"
	sec1.add_child(lin_wavy_lbl)

	_linear_wavy_det = M3LinearProgress.new()
	_linear_wavy_det.wavy = true
	_linear_wavy_det.value = 0.65
	sec1.add_child(_linear_wavy_det)

	var linear_wavy_indet := M3LinearProgress.new()
	linear_wavy_indet.wavy = true
	linear_wavy_indet.indeterminate = true
	sec1.add_child(linear_wavy_indet)
	
	# Circular Progress indicators
	var circ_row := HBoxContainer.new()
	circ_row.add_theme_constant_override("separation", 48)
	sec1.add_child(circ_row)
	
	var c_box1 := VBoxContainer.new()
	c_box1.add_theme_constant_override("separation", 8)
	var c_lbl1 := Label.new()
	c_lbl1.text = "Determinate:"
	c_box1.add_child(c_lbl1)
	_circular_det = M3CircularProgress.new()
	_circular_det.value = 0.65
	_circular_det.show_track = true
	c_box1.add_child(_circular_det)
	circ_row.add_child(c_box1)
	
	var c_box2 := VBoxContainer.new()
	c_box2.add_theme_constant_override("separation", 8)
	var c_lbl2 := Label.new()
	c_lbl2.text = "Indeterminate:"
	c_box2.add_child(c_lbl2)
	var circular_indet := M3CircularProgress.new()
	circular_indet.indeterminate = true
	c_box2.add_child(circular_indet)
	circ_row.add_child(c_box2)

	var c_box_wavy := VBoxContainer.new()
	c_box_wavy.add_theme_constant_override("separation", 8)
	var c_lbl_wavy := Label.new()
	c_lbl_wavy.text = "Wavy Circular:"
	c_box_wavy.add_child(c_lbl_wavy)
	_circular_wavy_det = M3CircularProgress.new()
	_circular_wavy_det.wavy = true
	_circular_wavy_det.value = 0.65
	c_box_wavy.add_child(_circular_wavy_det)
	circ_row.add_child(c_box_wavy)

	var c_box3 := VBoxContainer.new()
	c_box3.add_theme_constant_override("separation", 8)
	var c_lbl3 := Label.new()
	c_lbl3.text = "Expressive Loading:"
	c_box3.add_child(c_lbl3)
	var loading_std := M3LoadingIndicator.new()
	loading_std.contained = false
	c_box3.add_child(loading_std)
	circ_row.add_child(c_box3)

	var c_box4 := VBoxContainer.new()
	c_box4.add_theme_constant_override("separation", 8)
	var c_lbl4 := Label.new()
	c_lbl4.text = "Contained Loading:"
	c_box4.add_child(c_lbl4)
	var loading_contained := M3LoadingIndicator.new()
	loading_contained.contained = true
	c_box4.add_child(loading_contained)
	circ_row.add_child(c_box4)
	
	# Section 2: Snackbars & Menus
	var sec2 := _create_section(vbox, "Snackbars & Menus", "Trigger floating snackbar notifications or popup menus.")
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	sec2.add_child(btn_row)
	
	var btn_snack := M3Button.new()
	btn_snack.text = "Show Snackbar"
	btn_snack.pressed.connect(_show_snackbar)
	btn_row.add_child(btn_snack)
	
	var btn_menu := M3Button.new()
	btn_menu.button_type = M3Button.ButtonType.OUTLINED
	btn_menu.text = "Show Popup Menu"
	btn_menu.pressed.connect(func(): _popup_menu(btn_menu))
	btn_row.add_child(btn_menu)
	
	# Create Menu instance
	_menu = M3Menu.new()
	add_child(_menu)
	_menu.add_menu_item("New Document", 1, null, "Ctrl+N")
	_menu.add_menu_item("Open...", 2, null, "Ctrl+O")
	_menu.add_menu_item("Save", 3, null, "Ctrl+S")
	_menu.add_divider()
	_menu.add_menu_item("Export PDF", 4)
	_menu.add_menu_item("Print...", 5, null, "Ctrl+P")
	
	# Section 3: Banners
	var sec3 := _create_section(vbox, "Alert Banner", "Informational and status banners with actions.")
	var banner := M3Banner.new()
	banner.text = "Your storage space is nearly full (88% used). Consider upgrading your plan."
	banner.action_1_label = "Upgrade"
	banner.action_2_label = "Dismiss"
	sec3.add_child(banner)

func _on_slider_value_changed(val: float) -> void:
	if _linear_det: _linear_det.value = val
	if _linear_wavy_det: _linear_wavy_det.value = val
	if _circular_det: _circular_det.value = val
	if _circular_wavy_det: _circular_wavy_det.value = val

func _show_snackbar() -> void:
	M3Snackbar.show_message(self, "Project changes were saved successfully.", "Undo", func():
		print("Undo action clicked!")
	)

func _popup_menu(btn: Control) -> void:
	if _menu:
		_menu.popup_at_control(btn)

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
