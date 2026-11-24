@tool
class_name M3NavigationDrawer
extends Control

signal destination_selected(index: int)
signal drawer_closed
signal drawer_opened

enum DrawerType {
	STANDARD,
	MODAL
}

@export var drawer_type: DrawerType = DrawerType.STANDARD:
	set(value):
		drawer_type = value
		_update_mode()
		_apply_styling()

@export var drawer_title: String = "Navigation":
	set(value):
		drawer_title = value
		if _vbox != null and is_instance_valid(_vbox):
			_rebuild_items()
		queue_redraw()

@export var destinations: Array[Dictionary] = [
	{"label": "Explore", "icon": null, "badge": 0, "section": "Mail"},
	{"label": "Favorites", "icon": null, "badge": 3, "section": "Mail"},
	{"label": "Saved", "icon": null, "badge": 0, "section": "Mail"},
	{"label": "Profile", "icon": null, "badge": 0, "section": "Account"},
	{"label": "Settings", "icon": null, "badge": 0, "section": "Account"}
]:
	set(value):
		destinations = value
		if _vbox != null and is_instance_valid(_vbox):
			_rebuild_items()
		queue_redraw()

@export var selected_index: int = 0:
	set(value):
		if selected_index != value and value >= 0 and value < destinations.size():
			selected_index = value
			destination_selected.emit(selected_index)
			_animate_selection()
			_update_items_redraw()
			queue_redraw()

@export var drawer_width: float = 320.0:
	set(value):
		drawer_width = value
		_update_mode()

var is_open: bool = true
var open_progress: float = 1.0:
	set(value):
		open_progress = clampf(value, 0.0, 1.0)
		_apply_open_progress()
		queue_redraw()

var selection_progress: float = 1.0:
	set(value):
		selection_progress = clampf(value, 0.0, 1.0)
		_update_items_redraw()

var _scrim: ColorRect
var _drawer_panel: PanelContainer
var _scroll: ScrollContainer
var _vbox: VBoxContainer
var _item_buttons: Array[Control] = []
var _tween: Tween
var _sel_tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(drawer_width, 0)
	size_flags_vertical = SIZE_EXPAND_FILL

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	_update_mode()
	_rebuild_items()

func _setup_theme_listener() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and not mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.connect(_on_theme_changed)

func _on_theme_changed() -> void:
	_apply_styling()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_modal_children()

func _layout_modal_children() -> void:
	if drawer_type == DrawerType.MODAL:
		var h: float = maxf(size.y, 360.0)
		if _scrim and is_instance_valid(_scrim):
			_scrim.position = Vector2.ZERO
			_scrim.size = Vector2(maxf(size.x, drawer_width + 120.0), h)
		if _drawer_panel and is_instance_valid(_drawer_panel):
			_drawer_panel.size = Vector2(drawer_width, h)
			_drawer_panel.position = Vector2(lerpf(-drawer_width, 0.0, open_progress), 0.0)
	else:
		if _drawer_panel and is_instance_valid(_drawer_panel):
			_drawer_panel.position = Vector2.ZERO
			if size.y > 0.0:
				_drawer_panel.size = Vector2(drawer_width, size.y)

func _update_mode() -> void:
	if drawer_type == DrawerType.MODAL:
		custom_minimum_size = Vector2(maxf(drawer_width + 160.0, 480.0), 320.0)
		mouse_filter = MOUSE_FILTER_PASS
		if _scrim:
			_scrim.visible = true
			_scrim.mouse_filter = MOUSE_FILTER_STOP if is_open else MOUSE_FILTER_IGNORE
	else:
		custom_minimum_size = Vector2(drawer_width, 0)
		size_flags_horizontal = SIZE_SHRINK_BEGIN
		size_flags_vertical = SIZE_EXPAND_FILL
		if _scrim:
			_scrim.visible = false
	_layout_modal_children()

func _build_ui() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	# Scrim for modal
	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = Color(0.0, 0.0, 0.0, 0.32)
	_scrim.mouse_filter = MOUSE_FILTER_STOP
	_scrim.gui_input.connect(_on_scrim_gui_input)
	add_child(_scrim)

	_drawer_panel = PanelContainer.new()
	_drawer_panel.name = "DrawerPanel"
	_drawer_panel.custom_minimum_size = Vector2(drawer_width, 0)
	_drawer_panel.size_flags_vertical = SIZE_EXPAND_FILL
	_drawer_panel.mouse_filter = MOUSE_FILTER_STOP
	add_child(_drawer_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_drawer_panel.add_child(margin)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.name = "ItemsVBox"
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 4)
	_scroll.add_child(_vbox)

	_apply_styling()

func _rebuild_items() -> void:
	if not _vbox:
		return
	for c in _vbox.get_children():
		_vbox.remove_child(c)
		c.queue_free()
	_item_buttons.clear()

	if drawer_title != "":
		var title_lbl := Label.new()
		title_lbl.name = "DrawerTitle"
		title_lbl.text = drawer_title
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.add_theme_color_override("font_color", get_scheme().on_surface_variant)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 16)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		m.add_child(title_lbl)
		_vbox.add_child(m)

	var cur_section: String = ""
	for i in range(destinations.size()):
		var item: Dictionary = destinations[i]
		var item_sec: String = str(item.get("section", ""))
		if item_sec != "" and item_sec != cur_section:
			cur_section = item_sec
			if i > 0:
				var div := M3Divider.new()
				div.inset_start = 16.0
				div.inset_end = 16.0
				_vbox.add_child(div)
			var sec_lbl := Label.new()
			sec_lbl.text = item_sec
			sec_lbl.add_theme_font_size_override("font_size", 12)
			sec_lbl.add_theme_color_override("font_color", get_scheme().on_surface_variant)
			var sm := MarginContainer.new()
			sm.add_theme_constant_override("margin_left", 16)
			sm.add_theme_constant_override("margin_top", 8)
			sm.add_theme_constant_override("margin_bottom", 4)
			sm.add_child(sec_lbl)
			_vbox.add_child(sm)

		var item_btn := _create_drawer_item_button(i, item)
		_vbox.add_child(item_btn)
		_item_buttons.append(item_btn)

func get_item_button(idx: int) -> Control:
	if idx >= 0 and idx < _item_buttons.size():
		return _item_buttons[idx]
	return null

func get_scrim() -> ColorRect:
	return _scrim

func _create_drawer_item_button(idx: int, data: Dictionary) -> Control:
	var btn := M3BaseControl.new()
	btn.name = "DrawerItem_%d" % idx
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn.mouse_filter = MOUSE_FILTER_STOP

	btn.draw.connect(func():
		var s := get_scheme()
		var is_sel: bool = (idx == selected_index)
		var r := Rect2(Vector2.ZERO, btn.size)
		if is_sel:
			var pill_w: float = btn.size.x * lerpf(0.75, 1.0, selection_progress)
			var pill_r := Rect2(Vector2((btn.size.x - pill_w) * 0.5, 0.0), Vector2(pill_w, btn.size.y))
			var sb := btn.create_stylebox(s.secondary_container, 28.0)
			btn.draw_style_box(sb, pill_r)
		elif btn.is_hovered:
			var sb := btn.create_stylebox(s.on_surface.lerp(Color.TRANSPARENT, 0.92), 28.0)
			btn.draw_style_box(sb, r)

		var font := btn.get_theme_default_font()
		var icon_col := s.on_secondary_container if is_sel else s.on_surface_variant
		var text_col := s.on_secondary_container if is_sel else s.on_surface

		# Icon
		var center_y := btn.size.y * 0.5
		if data.get("icon") is Texture2D:
			var tex: Texture2D = data.get("icon")
			btn.draw_texture_rect(tex, Rect2(Vector2(16.0, center_y - 12.0), Vector2(24, 24)), false, icon_col)
		else:
			btn.draw_circle(Vector2(28.0, center_y), 5.0, icon_col)

		# Label
		if font:
			var label_str: String = str(data.get("label", data.get("title", "")))
			btn.draw_string(font, Vector2(56.0, center_y + 5.0), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_col)

			# Badge
			var badge_cnt: int = int(data.get("badge", 0))
			if badge_cnt > 0:
				var badge_str := str(badge_cnt) if badge_cnt <= 999 else "999+"
				var b_sz := font.get_string_size(badge_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
				var b_rect := Rect2(Vector2(btn.size.x - b_sz.x - 24.0, center_y - 9.0), Vector2(b_sz.x + 12.0, 18.0))
				var b_sb := btn.create_stylebox(s.error if not is_sel else s.on_secondary_container, 9.0)
				btn.draw_style_box(b_sb, b_rect)
				btn.draw_string(font, Vector2(b_rect.position.x + 6.0, b_rect.position.y + 13.0), badge_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, s.on_error if not is_sel else s.secondary_container)
	)

	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			selected_index = idx
			_update_items_redraw()
	)
	return btn

func _animate_selection() -> void:
	if not is_inside_tree():
		selection_progress = 1.0
		return
	if _sel_tween and _sel_tween.is_valid():
		_sel_tween.kill()
	selection_progress = 0.0
	_sel_tween = create_tween()
	_sel_tween.bind_node(self)
	_sel_tween.tween_property(self, ^"selection_progress", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _update_items_redraw() -> void:
	if _vbox:
		for c in _vbox.get_children():
			c.queue_redraw()

func _apply_styling() -> void:
	if not _drawer_panel:
		return
	var s := get_scheme()

	var sb := StyleBoxFlat.new()
	sb.bg_color = s.surface_container_low
	if drawer_type == DrawerType.MODAL:
		sb.corner_radius_top_right = 28
		sb.corner_radius_bottom_right = 28
		sb.shadow_size = 8
		sb.shadow_color = Color(0, 0, 0, 0.3)
	_drawer_panel.add_theme_stylebox_override("panel", sb)
	if _scrim:
		_scrim.color = Color(s.scrim.r, s.scrim.g, s.scrim.b, 0.32)
	_update_items_redraw()

func _apply_open_progress() -> void:
	if drawer_type == DrawerType.MODAL:
		if _scrim and is_instance_valid(_scrim):
			_scrim.modulate.a = open_progress
		if _drawer_panel and is_instance_valid(_drawer_panel):
			_drawer_panel.position.x = lerpf(-drawer_width, 0.0, open_progress)

func _on_scrim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_drawer()

func open_drawer(animated: bool = true) -> void:
	visible = true
	is_open = true
	if _scrim:
		_scrim.mouse_filter = MOUSE_FILTER_STOP
	if _tween and _tween.is_valid():
		_tween.kill()
	if not animated or not is_inside_tree():
		open_progress = 1.0
		drawer_opened.emit()
		return
	open_progress = 0.0
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.tween_property(self, ^"open_progress", 1.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void: drawer_opened.emit())

func close_drawer(animated: bool = true) -> void:
	is_open = false
	if _scrim:
		_scrim.mouse_filter = MOUSE_FILTER_IGNORE
	if drawer_type == DrawerType.MODAL:
		if _tween and _tween.is_valid():
			_tween.kill()
		if not animated or not is_inside_tree():
			open_progress = 0.0
			drawer_closed.emit()
			return
		_tween = create_tween()
		_tween.bind_node(self)
		_tween.tween_property(self, ^"open_progress", 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_tween.tween_callback(func():
			drawer_closed.emit()
		)
	else:
		open_progress = 0.0
		drawer_closed.emit()
