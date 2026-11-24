@tool
class_name M3BottomSheet
extends Control

## Material 3 Bottom Sheet component (https://m3.material.io/components/bottom-sheets/overview).
## Supports Standard (coplanar) and Modal (with scrim) variants, 28dp top corner radius,
## 32x4dp drag handle with interactive drag-to-dismiss, and Tween-animated open_progress (0.0..1.0).

signal opened
signal closed

enum SheetType {
	STANDARD,
	MODAL
}

@export var sheet_type: SheetType = SheetType.MODAL:
	set(value):
		sheet_type = value
		_apply_styling()
		_update_panel_position()

@export var title: String = "Bottom Sheet":
	set(value):
		title = value
		if _title_label:
			_title_label.text = title
			_title_label.visible = not title.is_empty()

@export var corner_radius: int = 28:
	set(value):
		corner_radius = value
		_apply_styling()

@export var show_drag_handle: bool = true:
	set(value):
		show_drag_handle = value
		if _drag_container:
			_drag_container.visible = show_drag_handle

@export var is_open: bool = false:
	set(value):
		if is_open != value:
			is_open = value
			if is_inside_tree():
				if is_open and not visible:
					_do_open_sheet()
				elif not is_open and visible:
					_do_close_sheet()
			else:
				open_progress = 1.0 if is_open else 0.0
				visible = is_open

@export var sheet_height: float = 300.0:
	set(value):
		sheet_height = maxf(80.0, value)
		if _sheet_panel:
			_sheet_panel.custom_minimum_size.y = sheet_height
		_update_panel_position()

var open_progress: float = 0.0:
	set(value):
		open_progress = clampf(value, 0.0, 1.0)
		_current_offset_y = (1.0 - open_progress) * sheet_height
		_update_panel_position()
		if _scrim:
			_scrim.queue_redraw()
		queue_redraw()

var _scrim: Control = null
var _sheet_panel: PanelContainer = null
var _content_box: VBoxContainer = null
var _drag_container: CenterContainer = null
var _drag_handle: Panel = null
var _title_label: Label = null
var _tween: Tween = null
var _drag_start_y: float = 0.0
var _is_dragging: bool = false
var _current_offset_y: float = 0.0

func _init() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	visible = false
	_build_ui()
	_apply_styling()

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_sync_parent_bounds()
	_apply_styling()
	if is_open:
		_do_open_sheet()

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

func _on_resized() -> void:
	_update_panel_position()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func _sync_parent_bounds() -> void:
	var p := get_parent()
	if p is Control:
		var pc := p as Control
		if (size.x <= 1.0 or size.y <= 1.0) and pc.size.x > 1.0 and pc.size.y > 1.0:
			size = pc.size
	elif p is Viewport:
		var vp := p as Viewport
		var vs := Vector2(vp.get_visible_rect().size)
		if (size.x <= 1.0 or size.y <= 1.0) and vs.x > 1.0 and vs.y > 1.0:
			size = vs
	_update_panel_position()

func _build_ui() -> void:
	if _sheet_panel != null:
		return

	# Scrim
	_scrim = Control.new()
	_scrim.name = "Scrim"
	_scrim.mouse_filter = MOUSE_FILTER_STOP
	_scrim.gui_input.connect(_on_scrim_gui_input)
	_scrim.draw.connect(_on_scrim_draw)
	add_child(_scrim)

	# Sheet panel
	_sheet_panel = PanelContainer.new()
	_sheet_panel.name = "SheetPanel"
	_sheet_panel.custom_minimum_size = Vector2(0, sheet_height)
	_sheet_panel.mouse_filter = MOUSE_FILTER_STOP
	add_child(_sheet_panel)

	var margin := MarginContainer.new()
	margin.name = "SheetMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 24)
	_sheet_panel.add_child(margin)

	_content_box = VBoxContainer.new()
	_content_box.name = "ContentBox"
	_content_box.add_theme_constant_override("separation", 16)
	margin.add_child(_content_box)

	# Drag Handle (32x4dp pill inside a 24dp interactive header zone)
	_drag_container = CenterContainer.new()
	_drag_container.name = "DragHandleContainer"
	_drag_container.custom_minimum_size = Vector2(0, 24)
	_drag_container.mouse_filter = MOUSE_FILTER_STOP
	_drag_container.visible = show_drag_handle
	_drag_container.gui_input.connect(_on_drag_handle_input)

	_drag_handle = Panel.new()
	_drag_handle.name = "DragHandle"
	_drag_handle.custom_minimum_size = Vector2(32, 4)
	_drag_handle.mouse_filter = MOUSE_FILTER_IGNORE
	_drag_container.add_child(_drag_handle)
	_content_box.add_child(_drag_container)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = title
	_title_label.visible = not title.is_empty()
	_title_label.add_theme_font_size_override("font_size", 18)
	_content_box.add_child(_title_label)

func add_content(control: Control) -> void:
	if _content_box == null:
		_build_ui()
	if _content_box and control:
		_content_box.add_child(control)

func get_content_container() -> VBoxContainer:
	if _content_box == null:
		_build_ui()
	return _content_box

func get_drag_handle() -> Control:
	return _drag_container

func get_sheet_panel() -> PanelContainer:
	return _sheet_panel

func get_scrim() -> Control:
	return _scrim

func _update_panel_position() -> void:
	if _sheet_panel == null:
		return
	var host_h: float = maxf(sheet_height, size.y)
	var host_w: float = maxf(280.0, size.x)
	_sheet_panel.size = Vector2(host_w, sheet_height)
	_sheet_panel.position = Vector2(0.0, lerpf(host_h, host_h - sheet_height, open_progress))
	if _scrim:
		_scrim.size = Vector2(host_w, host_h)
		_scrim.visible = (sheet_type == SheetType.MODAL and open_progress > 0.001)
		_scrim.mouse_filter = MOUSE_FILTER_STOP if (sheet_type == SheetType.MODAL and is_open) else MOUSE_FILTER_IGNORE

func _on_scrim_draw() -> void:
	if _scrim == null or sheet_type != SheetType.MODAL or open_progress <= 0.001:
		return
	var s := get_scheme()
	var sc := s.scrim
	sc.a = 0.32 * open_progress
	_scrim.draw_rect(Rect2(Vector2.ZERO, _scrim.size), sc, true)

func _on_drag_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_is_dragging = true
			_drag_start_y = mb.global_position.y
			if _tween and _tween.is_valid():
				_tween.kill()
			accept_event()
		else:
			if _is_dragging:
				_is_dragging = false
				var delta_y: float = mb.global_position.y - _drag_start_y
				if delta_y > 60.0:
					close_sheet()
				else:
					_reset_drag()
				accept_event()
	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		var delta_y: float = maxf(0.0, mm.global_position.y - _drag_start_y)
		_current_offset_y = delta_y
		open_progress = clampf(1.0 - (delta_y / maxf(1.0, sheet_height)), 0.0, 1.0)
		accept_event()

func _reset_drag() -> void:
	if not is_inside_tree():
		open_progress = 1.0
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"open_progress", 1.0, 0.2)

func _apply_styling() -> void:
	if not _sheet_panel:
		return
	var s := get_scheme()

	if _scrim:
		_scrim.visible = (sheet_type == SheetType.MODAL and open_progress > 0.001)
		_scrim.queue_redraw()

	var sb := StyleBoxFlat.new()
	sb.bg_color = s.surface_container_low
	sb.corner_radius_top_left = corner_radius
	sb.corner_radius_top_right = corner_radius
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_offset = Vector2(0, -2)
	_sheet_panel.add_theme_stylebox_override("panel", sb)

	if _title_label:
		_title_label.add_theme_color_override("font_color", s.on_surface)

	if _drag_handle:
		var d_sb := StyleBoxFlat.new()
		var handle_col := s.on_surface_variant
		handle_col.a = 0.4
		d_sb.bg_color = handle_col
		d_sb.set_corner_radius_all(2)
		_drag_handle.add_theme_stylebox_override("panel", d_sb)

func _on_scrim_gui_input(event: InputEvent) -> void:
	if sheet_type != SheetType.MODAL:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_sheet()
		accept_event()

func open() -> void:
	open_sheet()

func open_sheet() -> void:
	_sync_parent_bounds()
	is_open = true
	_do_open_sheet()

func _do_open_sheet() -> void:
	_sync_parent_bounds()
	visible = true
	_apply_styling()

	if not is_inside_tree():
		open_progress = 1.0
		opened.emit()
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	open_progress = 0.0
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_EXPO)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"open_progress", 1.0, 0.3)
	_tween.chain().tween_callback(func() -> void: opened.emit())

func close() -> void:
	close_sheet()

func close_sheet() -> void:
	is_open = false
	_do_close_sheet()

func _do_close_sheet() -> void:
	if not is_inside_tree():
		open_progress = 0.0
		visible = false
		closed.emit()
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	if open_progress <= 0.01:
		open_progress = 1.0
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"open_progress", 0.0, 0.22)
	_tween.chain().tween_callback(func() -> void:
		visible = false
		closed.emit()
	)
