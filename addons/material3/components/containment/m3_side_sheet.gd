@tool
class_name M3SideSheet
extends Control

## Material 3 Side Sheet component (https://m3.material.io/components/side-sheets/overview).
## Supports Standard (coplanar, 1dp leading outline border) and Modal (scrim + 16dp leading corner radius)
## variants, Right or Left edge docking, header with back/title/close controls, scrollable content container,
## optional footer action buttons, and Tween-animated open_progress (0.0..1.0).

signal opened
signal closed
signal back_pressed
signal confirm_pressed
signal cancel_pressed

enum SheetType {
	STANDARD,
	MODAL
}

enum SheetEdge {
	RIGHT,
	LEFT
}

@export var sheet_type: SheetType = SheetType.STANDARD:
	set(value):
		sheet_type = value
		_update_mode()
		_apply_styling()
		_update_panel_transform()

@export var sheet_edge: SheetEdge = SheetEdge.RIGHT:
	set(value):
		sheet_edge = value
		_apply_styling()
		_update_panel_transform()

@export var edge: SheetEdge:
	get:
		return sheet_edge
	set(value):
		sheet_edge = value

@export var sheet_width: float = 320.0:
	set(value):
		sheet_width = clampf(value, 200.0, 400.0)
		_update_mode()
		_update_panel_transform()

@export var corner_radius: int = 16:
	set(value):
		corner_radius = maxi(0, value)
		_apply_styling()

@export var title: String = "Side Sheet":
	set(value):
		title = value
		if _title_label:
			_title_label.text = title

@export var show_back_button: bool = false:
	set(value):
		show_back_button = value
		if _back_btn:
			_back_btn.visible = show_back_button

@export var show_close_button: bool = true:
	set(value):
		show_close_button = value
		if _close_btn:
			_close_btn.visible = show_close_button

@export var show_action_buttons: bool = false:
	set(value):
		show_action_buttons = value
		if _footer_box:
			_footer_box.visible = show_action_buttons

@export var confirm_text: String = "Save":
	set(value):
		confirm_text = value
		if _confirm_btn:
			_confirm_btn.text = confirm_text

@export var confirm_label: String:
	get:
		return confirm_text
	set(value):
		confirm_text = value

@export var cancel_text: String = "Cancel":
	set(value):
		cancel_text = value
		if _cancel_btn:
			_cancel_btn.text = cancel_text

@export var cancel_label: String:
	get:
		return cancel_text
	set(value):
		cancel_text = value

@export var is_open: bool = true:
	set(value):
		if is_open != value:
			is_open = value
			if not is_inside_tree():
				open_progress = 1.0 if is_open else 0.0
				visible = is_open or open_progress > 0.0

var open_progress: float = 1.0:
	set(value):
		open_progress = clampf(value, 0.0, 1.0)
		_update_panel_transform()
		if _scrim:
			_scrim.queue_redraw()
		queue_redraw()

var _scrim: Control = null
var _sheet_panel: PanelContainer = null
var _header_box: HBoxContainer = null
var _back_btn: M3IconButton = null
var _title_label: Label = null
var _close_btn: M3IconButton = null
var _scroll: ScrollContainer = null
var _content_box: VBoxContainer = null
var _footer_box: VBoxContainer = null
var _footer_divider: M3Divider = null
var _actions_row: HBoxContainer = null
var _confirm_btn: M3Button = null
var _cancel_btn: M3Button = null
var _tween: Tween = null

func _init() -> void:
	clip_contents = false
	custom_minimum_size = Vector2(sheet_width, 360.0)
	size = Vector2(sheet_width, 480.0)
	_build_ui()
	_update_mode()
	_apply_styling()
	_update_panel_transform()

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_update_mode()
	_apply_styling()
	_update_panel_transform()

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
	if _scrim:
		_scrim.queue_redraw()
	queue_redraw()

func _on_resized() -> void:
	_update_panel_transform()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func _build_ui() -> void:
	if _sheet_panel != null:
		return

	# Modal scrim
	_scrim = Control.new()
	_scrim.name = "Scrim"
	_scrim.mouse_filter = MOUSE_FILTER_STOP
	_scrim.gui_input.connect(_on_scrim_gui_input)
	_scrim.draw.connect(_on_scrim_draw)
	add_child(_scrim)

	# Side sheet panel
	_sheet_panel = PanelContainer.new()
	_sheet_panel.name = "SheetPanel"
	_sheet_panel.custom_minimum_size = Vector2(sheet_width, 200.0)
	_sheet_panel.mouse_filter = MOUSE_FILTER_STOP
	add_child(_sheet_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 0)
	main_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_sheet_panel.add_child(main_vbox)

	# Header (padding 16dp, 24dp start when no back button)
	var header_margin := MarginContainer.new()
	header_margin.name = "HeaderMargin"
	header_margin.add_theme_constant_override("margin_left", 16)
	header_margin.add_theme_constant_override("margin_right", 16)
	header_margin.add_theme_constant_override("margin_top", 16)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	main_vbox.add_child(header_margin)

	_header_box = HBoxContainer.new()
	_header_box.name = "HeaderBox"
	_header_box.add_theme_constant_override("separation", 8)
	_header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header_margin.add_child(_header_box)

	_back_btn = M3IconButton.new()
	_back_btn.name = "BackButton"
	_back_btn.icon_name = &"arrow_back"
	_back_btn.visible = show_back_button
	_back_btn.pressed.connect(func() -> void: back_pressed.emit())
	_header_box.add_child(_back_btn)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = title
	_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 22)
	_header_box.add_child(_title_label)

	_close_btn = M3IconButton.new()
	_close_btn.name = "CloseButton"
	_close_btn.icon_name = &"close"
	_close_btn.visible = show_close_button
	_close_btn.pressed.connect(func() -> void: close())
	_header_box.add_child(_close_btn)

	# Scrollable body content
	var body_margin := MarginContainer.new()
	body_margin.name = "BodyMargin"
	body_margin.size_flags_horizontal = SIZE_EXPAND_FILL
	body_margin.size_flags_vertical = SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 24)
	body_margin.add_theme_constant_override("margin_right", 24)
	body_margin.add_theme_constant_override("margin_top", 4)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	main_vbox.add_child(body_margin)

	_scroll = ScrollContainer.new()
	_scroll.name = "BodyScroll"
	_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_margin.add_child(_scroll)

	_content_box = VBoxContainer.new()
	_content_box.name = "ContentBox"
	_content_box.size_flags_horizontal = SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 12)
	_scroll.add_child(_content_box)

	# Optional footer with divider and action buttons
	_footer_box = VBoxContainer.new()
	_footer_box.name = "FooterBox"
	_footer_box.add_theme_constant_override("separation", 0)
	_footer_box.visible = show_action_buttons
	main_vbox.add_child(_footer_box)

	_footer_divider = M3Divider.new()
	_footer_divider.name = "FooterDivider"
	_footer_box.add_child(_footer_divider)

	var footer_margin := MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_left", 24)
	footer_margin.add_theme_constant_override("margin_right", 24)
	footer_margin.add_theme_constant_override("margin_top", 16)
	footer_margin.add_theme_constant_override("margin_bottom", 24)
	_footer_box.add_child(footer_margin)

	_actions_row = HBoxContainer.new()
	_actions_row.name = "ActionsRow"
	_actions_row.add_theme_constant_override("separation", 8)
	footer_margin.add_child(_actions_row)

	_confirm_btn = M3Button.new()
	_confirm_btn.name = "ConfirmButton"
	_confirm_btn.variant = M3Button.Variant.FILLED
	_confirm_btn.text = confirm_text
	_confirm_btn.pressed.connect(func() -> void: confirm_pressed.emit())
	_actions_row.add_child(_confirm_btn)

	_cancel_btn = M3Button.new()
	_cancel_btn.name = "CancelButton"
	_cancel_btn.variant = M3Button.Variant.OUTLINED
	_cancel_btn.text = cancel_text
	_cancel_btn.pressed.connect(func() -> void: cancel_pressed.emit())
	_actions_row.add_child(_cancel_btn)

func get_content_container() -> VBoxContainer:
	if _content_box == null:
		_build_ui()
	return _content_box

func add_content(node: Control) -> void:
	if _content_box == null:
		_build_ui()
	if _content_box and node:
		_content_box.add_child(node)
		_style_content_labels()

func _style_content_labels() -> void:
	if _content_box == null:
		return
	var s := get_scheme()
	for c in _content_box.get_children():
		if c is Label:
			(c as Label).add_theme_color_override("font_color", s.on_surface_variant)

func get_close_button() -> M3IconButton:
	return _close_btn

func get_back_button() -> M3IconButton:
	return _back_btn

func get_confirm_button() -> M3Button:
	return _confirm_btn

func get_cancel_button() -> M3Button:
	return _cancel_btn

func get_sheet_panel() -> PanelContainer:
	return _sheet_panel

func get_scrim() -> Control:
	return _scrim

func _update_mode() -> void:
	if sheet_type == SheetType.MODAL:
		mouse_filter = MOUSE_FILTER_PASS
		if _scrim:
			_scrim.visible = open_progress > 0.001
			_scrim.mouse_filter = MOUSE_FILTER_STOP if is_open else MOUSE_FILTER_IGNORE
	else:
		custom_minimum_size = Vector2(sheet_width, 240.0)
		mouse_filter = MOUSE_FILTER_PASS
		if _scrim:
			_scrim.visible = false
			_scrim.mouse_filter = MOUSE_FILTER_IGNORE

func _update_panel_transform() -> void:
	if _sheet_panel == null:
		return
	var h: float = maxf(240.0, size.y)
	_sheet_panel.size = Vector2(sheet_width, h)
	_sheet_panel.custom_minimum_size = Vector2(sheet_width, 200.0)

	var host_w: float = maxf(sheet_width, size.x)
	var open_x: float = 0.0
	var closed_x: float = 0.0

	if sheet_edge == SheetEdge.RIGHT:
		open_x = host_w - sheet_width
		closed_x = host_w
	else:
		open_x = 0.0
		closed_x = -sheet_width

	_sheet_panel.position = Vector2(lerpf(closed_x, open_x, open_progress), 0.0)
	if _scrim:
		_scrim.size = size
		_scrim.visible = (sheet_type == SheetType.MODAL and open_progress > 0.001)

func _on_scrim_draw() -> void:
	if _scrim == null or sheet_type != SheetType.MODAL or open_progress <= 0.001:
		return
	var s := get_scheme()
	var c := s.scrim
	c.a = 0.32 * open_progress
	_scrim.draw_rect(Rect2(Vector2.ZERO, _scrim.size), c, true)

func _on_scrim_gui_input(event: InputEvent) -> void:
	if sheet_type != SheetType.MODAL or not is_open:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()
		accept_event()

func _apply_styling() -> void:
	if _sheet_panel == null:
		return
	var s := get_scheme()
	var sb := StyleBoxFlat.new()

	if sheet_type == SheetType.MODAL:
		sb.bg_color = s.surface_container_low
		var rad: int = corner_radius
		if sheet_edge == SheetEdge.RIGHT:
			sb.corner_radius_top_left = rad
			sb.corner_radius_bottom_left = rad
			sb.corner_radius_top_right = 0
			sb.corner_radius_bottom_right = 0
			sb.shadow_offset = Vector2(-2, 0)
		else:
			sb.corner_radius_top_left = 0
			sb.corner_radius_bottom_left = 0
			sb.corner_radius_top_right = rad
			sb.corner_radius_bottom_right = 0 if rad == 0 else rad
			sb.shadow_offset = Vector2(2, 0)
		sb.shadow_size = 6
		sb.shadow_color = Color(0, 0, 0, 0.2)
	else:
		# Standard coplanar side sheet: surface background + 1dp leading outline_variant divider
		sb.bg_color = s.surface
		sb.set_corner_radius_all(0)
		sb.border_color = s.outline_variant
		if sheet_edge == SheetEdge.RIGHT:
			sb.border_width_left = 1
		else:
			sb.border_width_right = 1

	_sheet_panel.add_theme_stylebox_override("panel", sb)

	if _title_label:
		_title_label.add_theme_color_override("font_color", s.on_surface_variant)
	_style_content_labels()

func open() -> void:
	visible = true
	is_open = true
	_update_mode()
	_apply_styling()

	if not is_inside_tree():
		open_progress = 1.0
		opened.emit()
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	if open_progress >= 0.99:
		open_progress = 0.0
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"open_progress", 1.0, 0.26)
	_tween.chain().tween_callback(func() -> void:
		_update_mode()
		opened.emit()
	)

func open_sheet() -> void:
	open()

func close() -> void:
	is_open = false
	_update_mode()

	if not is_inside_tree():
		open_progress = 0.0
		closed.emit()
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	if open_progress <= 0.01:
		open_progress = 1.0
	_tween = create_tween()
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"open_progress", 0.0, 0.22)
	_tween.chain().tween_callback(func() -> void:
		_update_mode()
		closed.emit()
	)

func close_sheet() -> void:
	close()
