@tool
class_name M3Menu
extends Control

signal item_selected(id: int, label: String)
signal id_pressed(id: int)
signal submenu_opened(item_id: int, submenu: M3Menu)
signal dismissed

@export var is_open: bool = false:
	set(value):
		if is_open != value:
			is_open = value
			if is_open and not visible:
				show_immediate()
			elif not is_open and visible:
				hide_menu()

@export var expressive_grouped: bool = false:
	set(value):
		if expressive_grouped != value:
			expressive_grouped = value
			_apply_styling()
			_update_menu_size()
			if _panel:
				_panel.queue_redraw()
			queue_redraw()

var open_progress: float = 0.0
var _open_progress: float = 0.0
var active_submenu: M3Menu = null
var submenu_open_progress: float = 0.0
var _panel: PanelContainer
var _vbox: VBoxContainer
var _items: Array[M3MenuItem] = []
var _submenus: Dictionary = {}
var _submenu_items: Dictionary = {}
var _parent_menu: M3Menu = null
var _focused_idx: int = -1
var _tween: Tween
var _submenu_tween: Tween
var _opened_frame: int = -1

func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	visible = false
	_build_ui()

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	_ensure_submenus_parented()
	_apply_styling()
	_update_menu_size()
	if is_open:
		visible = true
		open_progress = 1.0
		_open_progress = 1.0
		if _panel:
			_panel.modulate.a = 1.0
			_panel.scale = Vector2.ONE

func _setup_theme_listener() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and not mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.connect(_on_theme_changed)

func _exit_tree() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.disconnect(_on_theme_changed)

func _on_theme_changed() -> void:
	_apply_styling()
	queue_redraw()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func _build_ui() -> void:
	if _panel != null:
		return

	_panel = PanelContainer.new()
	_panel.name = "MenuPanel"
	_panel.mouse_filter = MOUSE_FILTER_PASS
	_panel.draw.connect(_on_panel_draw)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.name = "MenuMargin"
	margin.mouse_filter = MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.name = "MenuVBox"
	_vbox.mouse_filter = MOUSE_FILTER_PASS
	_vbox.add_theme_constant_override("separation", 0)
	margin.add_child(_vbox)

func _update_menu_size() -> void:
	if _panel == null:
		return
	var max_w: float = 200.0
	var total_h: float = 16.0
	for it in _items:
		if is_instance_valid(it):
			max_w = maxf(max_w, it.custom_minimum_size.x)
			total_h += it.custom_minimum_size.y
	for it in _items:
		if is_instance_valid(it):
			it.custom_minimum_size.x = max_w
			it.size.x = max_w
	var p_size := Vector2(max_w, maxf(total_h, 48.0))
	custom_minimum_size = p_size
	size = p_size
	_panel.position = Vector2.ZERO
	_panel.custom_minimum_size = p_size
	_panel.size = p_size

func add_menu_item(label: String, id: int = 0, icon: Variant = null, shortcut_text: String = "", disabled_state: bool = false, trailing_icon: Variant = null) -> M3MenuItem:
	if _vbox == null:
		_build_ui()
	var item := M3MenuItem.new()
	item.name = "MenuItem_%d" % _items.size()
	item.label = label
	item.id = id
	if icon is Texture2D:
		item.icon = icon
	elif icon is String or icon is StringName:
		item.icon_name = StringName(icon)
	if trailing_icon is Texture2D:
		item.trailing_icon = trailing_icon
	elif trailing_icon is String or trailing_icon is StringName:
		item.trailing_icon_name = StringName(trailing_icon)
	item.shortcut_text = shortcut_text
	item.disabled = disabled_state
	item.clicked.connect(_on_item_clicked)
	_items.append(item)
	if _vbox:
		_vbox.add_child(item)
	_update_menu_size()
	return item

func add_item(label: String, id: int = 0, icon: Variant = null, shortcut_text: String = "", disabled_state: bool = false, trailing_icon: Variant = null) -> M3MenuItem:
	return add_menu_item(label, id, icon, shortcut_text, disabled_state, trailing_icon)

func add_submenu_item(id: int, text: String, submenu: M3Menu, icon_name: Variant = "") -> M3MenuItem:
	var lead_icon: Variant = icon_name if String(icon_name) != "" else null
	var item := add_menu_item(text, id, lead_icon, "", false, &"chevron_right")
	item.submenu = submenu
	_submenu_items[id] = item
	if submenu != null:
		_submenus[id] = submenu
		submenu._parent_menu = self
		if submenu.get_parent() == null:
			if get_parent() != null:
				get_parent().add_child(submenu)
			else:
				add_child(submenu)
		item.mouse_entered.connect(func() -> void:
			if is_open and visible and not item.disabled:
				open_submenu_for_item(id)
		)
	return item

func _ensure_submenus_parented() -> void:
	if get_parent() == null:
		return
	for id in _submenus.keys():
		var sub: M3Menu = _submenus[id] as M3Menu
		if sub != null and is_instance_valid(sub) and sub.get_parent() != get_parent():
			if sub.get_parent() != null:
				sub.get_parent().remove_child(sub)
			get_parent().add_child(sub)

func open_submenu_for_item(id: int) -> void:
	if not _submenus.has(id):
		return
	var sub: M3Menu = _submenus[id] as M3Menu
	if sub == null or not is_instance_valid(sub):
		return
	_ensure_submenus_parented()

	if active_submenu != null and is_instance_valid(active_submenu) and active_submenu != sub and active_submenu.is_open:
		active_submenu.hide_menu()

	if active_submenu == sub and sub.is_open:
		return

	active_submenu = sub
	var item: M3MenuItem = _submenu_items.get(id, null) as M3MenuItem
	var target_pos: Vector2
	if is_inside_tree():
		var item_y: float = item.global_position.y if (item != null and is_instance_valid(item)) else global_position.y
		target_pos = Vector2(global_position.x + size.x + 4.0, item_y)
	else:
		var item_y_local: float = item.position.y if (item != null and is_instance_valid(item)) else 0.0
		target_pos = Vector2(position.x + size.x + 4.0, position.y + item_y_local)

	sub.popup_at_position(target_pos)

	if not is_inside_tree():
		submenu_open_progress = 1.0
	else:
		submenu_open_progress = 0.0
		if _submenu_tween and _submenu_tween.is_valid():
			_submenu_tween.kill()
		_submenu_tween = create_tween()
		_submenu_tween.bind_node(self)
		_submenu_tween.tween_property(self, ^"submenu_open_progress", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	submenu_opened.emit(id, sub)

func add_divider() -> M3MenuItem:
	if _vbox == null:
		_build_ui()
	var item := M3MenuItem.new()
	item.name = "MenuDivider_%d" % _items.size()
	item.is_divider = true
	_items.append(item)
	if _vbox:
		_vbox.add_child(item)
	_update_menu_size()
	return item

func add_group_break() -> M3MenuItem:
	if _vbox == null:
		_build_ui()
	expressive_grouped = true
	var item := M3MenuItem.new()
	item.name = "MenuGroupBreak_%d" % _items.size()
	item.is_divider = true
	item.is_group_break = true
	_items.append(item)
	if _vbox:
		_vbox.add_child(item)
	_update_menu_size()
	if _panel:
		_panel.queue_redraw()
	return item

func get_group_count() -> int:
	var groups: int = 0
	var in_group: bool = false
	for it in _items:
		if not is_instance_valid(it):
			continue
		if it.is_group_break or (expressive_grouped and it.is_divider):
			in_group = false
		else:
			if not in_group:
				groups += 1
				in_group = true
	return maxi(1, groups)

func get_item_count() -> int:
	return _items.size()

func get_item_control(index: int) -> M3MenuItem:
	if index >= 0 and index < _items.size():
		return _items[index]
	return null

func _on_item_clicked(id: int, label: String) -> void:
	if _submenus.has(id):
		open_submenu_for_item(id)
		return
	id_pressed.emit(id)
	item_selected.emit(id, label)
	hide_menu()
	if _parent_menu != null and is_instance_valid(_parent_menu) and _parent_menu.is_open:
		_parent_menu.id_pressed.emit(id)
		_parent_menu.item_selected.emit(id, label)
		_parent_menu.hide_menu()

func _place_at(pos: Vector2) -> void:
	_update_menu_size()
	if pos == Vector2.INF:
		return
	var final_pos := pos
	if is_inside_tree():
		var vp_sz := get_viewport_rect().size
		if vp_sz.x > 0 and vp_sz.y > 0:
			if final_pos.x + size.x > vp_sz.x - 8.0:
				final_pos.x = vp_sz.x - size.x - 8.0
			if final_pos.y + size.y > vp_sz.y - 8.0:
				final_pos.y = pos.y - size.y - 8.0
			final_pos.x = maxf(8.0, final_pos.x)
			final_pos.y = maxf(8.0, final_pos.y)
		global_position = final_pos
	else:
		position = final_pos

func show_immediate(pos: Vector2 = Vector2.INF) -> void:
	_apply_styling()
	_place_at(pos)
	visible = true
	is_open = true
	_opened_frame = Engine.get_process_frames()
	if _tween and _tween.is_valid():
		_tween.kill()
	open_progress = 1.0
	_open_progress = 1.0
	if _panel:
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE

func open(pos: Vector2 = Vector2.INF) -> void:
	popup_at_position(pos)

func popup_at(pos: Vector2) -> void:
	popup_at_position(pos)

func popup_at_control(target: Control) -> void:
	if target == null:
		popup_at_position(Vector2.INF)
		return
	var target_rect := target.get_global_rect()
	popup_at_position(Vector2(target_rect.position.x, target_rect.end.y + 4.0))

func popup_at_position(pos: Vector2) -> void:
	_apply_styling()
	_place_at(pos)
	visible = true
	is_open = true
	_opened_frame = Engine.get_process_frames()

	if not is_inside_tree():
		open_progress = 1.0
		_open_progress = 1.0
		if _panel:
			_panel.modulate.a = 1.0
			_panel.scale = Vector2.ONE
		return

	open_progress = 0.0
	_open_progress = 0.0
	if _panel:
		_panel.scale = Vector2(0.92, 0.92)
		_panel.modulate.a = 0.0

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_parallel(true)
	_tween.tween_property(self, ^"open_progress", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"_open_progress", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _panel:
		_tween.tween_property(_panel, ^"modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_property(_panel, ^"scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func close() -> void:
	hide_menu()

func hide_menu() -> void:
	is_open = false
	if active_submenu != null and is_instance_valid(active_submenu) and active_submenu.is_open:
		active_submenu.hide_menu()
	if not is_inside_tree():
		open_progress = 0.0
		_open_progress = 0.0
		submenu_open_progress = 0.0
		visible = false
		return
	if _submenu_tween and _submenu_tween.is_valid():
		_submenu_tween.kill()
	submenu_open_progress = 0.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_parallel(true)
	_tween.tween_property(self, ^"open_progress", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"_open_progress", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _panel:
		_tween.tween_property(_panel, ^"modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(func() -> void: visible = false)

func dismiss() -> void:
	dismissed.emit()
	hide_menu()

func _has_global_point(pt: Vector2) -> bool:
	if get_global_rect().has_point(pt):
		return true
	if active_submenu != null and is_instance_valid(active_submenu) and active_submenu.visible:
		if active_submenu._has_global_point(pt):
			return true
	return false

func _input(event: InputEvent) -> void:
	if not visible or not is_open:
		return
	if Engine.get_process_frames() == _opened_frame:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if _parent_menu != null and is_instance_valid(_parent_menu) and _parent_menu.visible and _parent_menu._has_global_point(mb.position):
			return
		if not _has_global_point(mb.position):
			dismiss()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept"):
		if _focused_idx >= 0 and _focused_idx < _items.size():
			var itm := _items[_focused_idx]
			if not itm.disabled and not itm.is_divider:
				_on_item_clicked(itm.id, itm.label)
				get_viewport().set_input_as_handled()

func _move_focus(dir: int) -> void:
	if _items.is_empty():
		return
	var new_idx := _focused_idx + dir
	while new_idx >= 0 and new_idx < _items.size():
		if not _items[new_idx].disabled and not _items[new_idx].is_divider:
			_focused_idx = new_idx
			_items[_focused_idx].grab_focus()
			return
		new_idx += dir

func _apply_styling() -> void:
	if not _panel:
		return
	if expressive_grouped:
		_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		_panel.queue_redraw()
		return
	var s := get_scheme()
	var sb := StyleBoxFlat.new()
	sb.bg_color = s.surface_container
	sb.set_corner_radius_all(4)
	sb.shadow_size = 6
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_offset = Vector2(0, 2)
	_panel.add_theme_stylebox_override("panel", sb)

func _on_panel_draw() -> void:
	if not expressive_grouped or _panel == null:
		return
	var s := get_scheme()
	var groups: Array[Array] = []
	var cur_group: Array[M3MenuItem] = []
	for it in _items:
		if not is_instance_valid(it):
			continue
		if it.is_group_break or it.is_divider:
			if not cur_group.is_empty():
				groups.append(cur_group)
				cur_group = []
		else:
			cur_group.append(it)
	if not cur_group.is_empty():
		groups.append(cur_group)

	if groups.is_empty():
		var fallback_sb := StyleBoxFlat.new()
		fallback_sb.bg_color = s.surface_container
		fallback_sb.set_corner_radius_all(16)
		_panel.draw_style_box(fallback_sb, Rect2(Vector2.ZERO, _panel.size))
		return

	var y_cursor: float = 8.0
	var g_idx: int = 0
	var g_count: int = groups.size()
	for it in _items:
		if not is_instance_valid(it):
			continue
		if it.is_group_break or it.is_divider:
			y_cursor += it.custom_minimum_size.y
	# Compute each group's exact vertical span inside MenuMargin (top margin 8)
	var item_y: float = 8.0
	var group_rects: Array[Rect2] = []
	var has_open_rect: bool = false
	var cur_top: float = 0.0
	var cur_bottom: float = 0.0
	for it in _items:
		if not is_instance_valid(it):
			continue
		var ih: float = maxf(it.size.y, it.custom_minimum_size.y)
		if it.is_group_break or it.is_divider:
			if has_open_rect:
				group_rects.append(Rect2(0.0, cur_top - 4.0, _panel.size.x, (cur_bottom - cur_top) + 8.0))
				has_open_rect = false
		else:
			if not has_open_rect:
				cur_top = item_y
				has_open_rect = true
			cur_bottom = item_y + ih
		item_y += ih
	if has_open_rect:
		group_rects.append(Rect2(0.0, cur_top - 4.0, _panel.size.x, (cur_bottom - cur_top) + 8.0))

	g_count = group_rects.size()
	for i in range(g_count):
		var gr: Rect2 = group_rects[i]
		var gsb := StyleBoxFlat.new()
		gsb.bg_color = s.surface_container
		var top_rad: int = 16 if i == 0 else 4
		var bot_rad: int = 16 if i == g_count - 1 else 4
		gsb.corner_radius_top_left = top_rad
		gsb.corner_radius_top_right = top_rad
		gsb.corner_radius_bottom_left = bot_rad
		gsb.corner_radius_bottom_right = bot_rad
		gsb.shadow_size = 5
		gsb.shadow_color = Color(0, 0, 0, 0.22)
		gsb.shadow_offset = Vector2(0, 2)
		_panel.draw_style_box(gsb, gr)
