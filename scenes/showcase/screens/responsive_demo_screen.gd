@tool
class_name ShowcaseResponsiveDemoScreen
extends ScrollContainer

var _width_label: Label
var _size_class_label: Label
var _grid: GridContainer

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build_ui()
	_update_responsive_layout()

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
	vbox.add_theme_constant_override("separation", 24)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pad.add_child(vbox)
	
	var title_lbl := Label.new()
	title_lbl.text = "Adaptive Dashboard & Grid"
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)
	
	# Status Card
	var status_card := M3Card.new()
	status_card.card_type = M3Card.CardType.FILLED
	vbox.add_child(status_card)
	
	var s_vbox := VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 8)
	status_card.add_child(s_vbox)
	
	_width_label = Label.new()
	_width_label.text = "Viewport Width: 1280px"
	_width_label.add_theme_font_size_override("font_size", 16)
	s_vbox.add_child(_width_label)
	
	_size_class_label = Label.new()
	_size_class_label.text = "Active Size Class: Expanded (>840px)"
	_size_class_label.add_theme_font_size_override("font_size", 14)
	s_vbox.add_child(_size_class_label)
	
	# Responsive Grid
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(_grid)
	
	# Stat Card 1
	_grid.add_child(_create_stat_card("Active Users", "24,580", "+12.5%", true))
	_grid.add_child(_create_stat_card("Total Revenue", "$148,200", "+8.2%", true))
	_grid.add_child(_create_stat_card("System Health", "99.98%", "Normal", true))
	_grid.add_child(_create_stat_card("Open Issues", "14", "-3.1%", false))
	_grid.add_child(_create_stat_card("CPU Load", "34%", "4 cores", false))
	_grid.add_child(_create_stat_card("Memory Usage", "2.4 / 16 GB", "15%", false))

func _create_stat_card(title: String, val: String, sub: String, is_positive: bool) -> M3Card:
	var card := M3Card.new()
	card.card_type = M3Card.CardType.ELEVATED
	card.custom_minimum_size = Vector2(200, 120)
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var cvbox := VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 6)
	card.add_child(cvbox)
	
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 13)
	cvbox.add_child(t)
	
	var v := Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", 24)
	cvbox.add_child(v)
	
	var s := Label.new()
	s.text = sub
	s.add_theme_font_size_override("font_size", 12)
	cvbox.add_child(s)
	
	return card

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_responsive_layout()

func _update_responsive_layout() -> void:
	var w := size.x
	if w <= 0:
		w = get_viewport_rect().size.x
		
	if _width_label:
		_width_label.text = "Viewport Width: %d px" % int(w)
		
	if w < 600.0:
		if _size_class_label: _size_class_label.text = "Active Size Class: Compact (<600px)"
		if _grid: _grid.columns = 1
	elif w < 840.0:
		if _size_class_label: _size_class_label.text = "Active Size Class: Medium (600 - 840px)"
		if _grid: _grid.columns = 2
	else:
		if _size_class_label: _size_class_label.text = "Active Size Class: Expanded (>840px)"
		if _grid: _grid.columns = 3
