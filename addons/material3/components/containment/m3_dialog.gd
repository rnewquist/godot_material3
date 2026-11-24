@tool
class_name M3Dialog
extends Control

## Material 3 Dialog component (https://m3.material.io/components/dialogs/overview).
## Supports Basic dialogs (28dp rounded surface_container_high card, optional icon, headline,
## supporting text, text action buttons, and scrim) and Full-screen dialogs (0dp surface fill,
## 56dp header bar with close M3IconButton, headline, and confirm action M3Button).

signal confirmed
signal cancelled
signal dismissed
signal opened
signal closed

enum DialogVariant {
	BASIC,
	FULLSCREEN
}

@export var fullscreen: bool = false:
	set(value):
		if fullscreen != value:
			fullscreen = value
			_update_ui()
			_apply_styling()

@export var dialog_variant: DialogVariant:
	get:
		return DialogVariant.FULLSCREEN if fullscreen else DialogVariant.BASIC
	set(value):
		fullscreen = (value == DialogVariant.FULLSCREEN)

@export var headline: String = "Dialog Title":
	set(value):
		headline = value
		_update_ui()

@export var title_text: String:
	get:
		return headline
	set(value):
		headline = value

@export var body_text: String = "This is a Material 3 dialog description. It provides concise and important information.":
	set(value):
		body_text = value
		_update_ui()

@export var message_text: String:
	get:
		return body_text
	set(value):
		body_text = value

@export var supporting_text: String:
	get:
		return body_text
	set(value):
		body_text = value

@export var corner_radius: int = 28:
	set(value):
		corner_radius = value
		_apply_styling()

@export var confirm_label: String = "Confirm":
	set(value):
		confirm_label = value
		_update_ui()

@export var confirm_text: String:
	get:
		return confirm_label
	set(value):
		confirm_label = value

@export var cancel_label: String = "Cancel":
	set(value):
		cancel_label = value
		_update_ui()

@export var cancel_text: String:
	get:
		return cancel_label
	set(value):
		cancel_label = value

@export var icon: Texture2D = null:
	set(value):
		icon = value
		_update_ui()

@export var icon_name: StringName = &"":
	set(value):
		icon_name = value
		_update_ui()

@export var dismiss_on_scrim_click: bool = true
@export var custom_content: Control = null:
	set(value):
		custom_content = value
		_update_ui()

@export var is_open: bool = false:
	set(value):
		if is_open != value:
			is_open = value
			if is_inside_tree():
				if is_open and not visible:
					open()
				elif not is_open and visible:
					close()

var open_progress: float = 0.0:
	set(value):
		open_progress = clampf(value, 0.0, 1.0)
		if _dialog_card:
			_dialog_card.modulate.a = open_progress
			if not fullscreen:
				_dialog_card.pivot_offset = _dialog_card.size * 0.5
				_dialog_card.scale = Vector2.ONE * lerpf(0.92, 1.0, open_progress)
		if _fullscreen_panel:
			_fullscreen_panel.modulate.a = open_progress
			if fullscreen:
				_fullscreen_panel.position.y = lerpf(24.0, 0.0, open_progress)
		queue_redraw()

var _center_container: CenterContainer = null
var _dialog_card: PanelContainer = null
var _headline_label: Label = null
var _body_label: Label = null
var _icon_rect: TextureRect = null
var _m3_icon: M3Icon = null
var _confirm_btn: M3Button = null
var _cancel_btn: M3Button = null
var _content_box: VBoxContainer = null
var _actions_box: HBoxContainer = null

var _fullscreen_panel: PanelContainer = null
var _header_bar: PanelContainer = null
var _close_btn: M3IconButton = null
var _fs_headline_label: Label = null
var _fs_confirm_btn: M3Button = null
var _fs_content_box: VBoxContainer = null
var _fs_body_label: Label = null
var _tween: Tween = null

func _init() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	_update_ui()
	_apply_styling()

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_sync_parent_bounds()
	_update_ui()
	_apply_styling()
	if is_open:
		open()

func _on_resized() -> void:
	if _center_container:
		_center_container.size = size
	if _fullscreen_panel:
		_fullscreen_panel.size = size

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
	if _center_container:
		_center_container.position = Vector2.ZERO
		_center_container.size = size
	if _fullscreen_panel:
		_fullscreen_panel.size = size

func _build_ui() -> void:
	if _dialog_card != null:
		return

	mouse_filter = MOUSE_FILTER_STOP

	# 1. Basic dialog centered layout
	_center_container = CenterContainer.new()
	_center_container.name = "CenterContainer"
	_center_container.mouse_filter = MOUSE_FILTER_PASS
	add_child(_center_container)

	_dialog_card = PanelContainer.new()
	_dialog_card.name = "DialogCard"
	_dialog_card.custom_minimum_size = Vector2(312, 180)
	_dialog_card.mouse_filter = MOUSE_FILTER_STOP
	_center_container.add_child(_dialog_card)

	var margin := MarginContainer.new()
	margin.name = "DialogMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_dialog_card.add_child(margin)

	_content_box = VBoxContainer.new()
	_content_box.name = "ContentBox"
	_content_box.add_theme_constant_override("separation", 16)
	margin.add_child(_content_box)

	_m3_icon = M3Icon.new()
	_m3_icon.name = "DialogIcon"
	_m3_icon.icon_size = 24.0
	_m3_icon.size_flags_horizontal = SIZE_SHRINK_CENTER
	_m3_icon.visible = false
	_content_box.add_child(_m3_icon)

	_icon_rect = TextureRect.new()
	_icon_rect.name = "DialogTextureIcon"
	_icon_rect.custom_minimum_size = Vector2(24, 24)
	_icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.size_flags_horizontal = SIZE_SHRINK_CENTER
	_icon_rect.visible = false
	_content_box.add_child(_icon_rect)

	_headline_label = Label.new()
	_headline_label.name = "HeadlineLabel"
	_headline_label.custom_minimum_size = Vector2(264, 0)
	_headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_headline_label.add_theme_font_size_override("font_size", 24)
	_content_box.add_child(_headline_label)

	_body_label = Label.new()
	_body_label.name = "BodyLabel"
	_body_label.custom_minimum_size = Vector2(264, 0)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 14)
	_content_box.add_child(_body_label)

	_actions_box = HBoxContainer.new()
	_actions_box.name = "ActionsBox"
	_actions_box.alignment = BoxContainer.ALIGNMENT_END
	_actions_box.add_theme_constant_override("separation", 8)
	_content_box.add_child(_actions_box)

	_cancel_btn = M3Button.new()
	_cancel_btn.name = "CancelButton"
	_cancel_btn.variant = M3Button.Variant.TEXT
	_cancel_btn.text = cancel_label
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	_actions_box.add_child(_cancel_btn)

	_confirm_btn = M3Button.new()
	_confirm_btn.name = "ConfirmButton"
	_confirm_btn.variant = M3Button.Variant.TEXT
	_confirm_btn.text = confirm_label
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	_actions_box.add_child(_confirm_btn)

	# 2. Full-screen dialog layout
	_fullscreen_panel = PanelContainer.new()
	_fullscreen_panel.name = "FullscreenPanel"
	_fullscreen_panel.mouse_filter = MOUSE_FILTER_STOP
	_fullscreen_panel.visible = false
	add_child(_fullscreen_panel)

	var fs_vbox := VBoxContainer.new()
	fs_vbox.name = "FullscreenVBox"
	fs_vbox.add_theme_constant_override("separation", 0)
	fs_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	fs_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_fullscreen_panel.add_child(fs_vbox)

	_header_bar = PanelContainer.new()
	_header_bar.name = "FullscreenHeaderBar"
	_header_bar.custom_minimum_size = Vector2(0, 56)
	fs_vbox.add_child(_header_bar)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 8)
	header_margin.add_theme_constant_override("margin_right", 16)
	header_margin.add_theme_constant_override("margin_top", 8)
	header_margin.add_theme_constant_override("margin_bottom", 8)
	_header_bar.add_child(header_margin)

	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.add_theme_constant_override("separation", 12)
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_margin.add_child(header_row)

	_close_btn = M3IconButton.new()
	_close_btn.name = "CloseButton"
	_close_btn.icon_name = &"close"
	_close_btn.pressed.connect(_on_cancel_pressed)
	header_row.add_child(_close_btn)

	_fs_headline_label = Label.new()
	_fs_headline_label.name = "FullscreenHeadlineLabel"
	_fs_headline_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_fs_headline_label.add_theme_font_size_override("font_size", 22)
	header_row.add_child(_fs_headline_label)

	_fs_confirm_btn = M3Button.new()
	_fs_confirm_btn.name = "FullscreenConfirmButton"
	_fs_confirm_btn.variant = M3Button.Variant.TEXT
	_fs_confirm_btn.text = confirm_label
	_fs_confirm_btn.pressed.connect(_on_confirm_pressed)
	header_row.add_child(_fs_confirm_btn)

	var fs_divider := M3Divider.new()
	fs_divider.name = "FullscreenHeaderDivider"
	fs_vbox.add_child(fs_divider)

	var fs_scroll := ScrollContainer.new()
	fs_scroll.name = "FullscreenBodyScroll"
	fs_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	fs_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	fs_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fs_vbox.add_child(fs_scroll)

	var fs_body_margin := MarginContainer.new()
	fs_body_margin.size_flags_horizontal = SIZE_EXPAND_FILL
	fs_body_margin.size_flags_vertical = SIZE_EXPAND_FILL
	fs_body_margin.add_theme_constant_override("margin_left", 24)
	fs_body_margin.add_theme_constant_override("margin_right", 24)
	fs_body_margin.add_theme_constant_override("margin_top", 24)
	fs_body_margin.add_theme_constant_override("margin_bottom", 24)
	fs_scroll.add_child(fs_body_margin)

	_fs_content_box = VBoxContainer.new()
	_fs_content_box.name = "FullscreenContentBox"
	_fs_content_box.add_theme_constant_override("separation", 16)
	_fs_content_box.size_flags_horizontal = SIZE_EXPAND_FILL
	fs_body_margin.add_child(_fs_content_box)

	_fs_body_label = Label.new()
	_fs_body_label.name = "FullscreenBodyLabel"
	_fs_body_label.custom_minimum_size = Vector2(320, 0)
	_fs_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fs_body_label.add_theme_font_size_override("font_size", 14)
	_fs_content_box.add_child(_fs_body_label)

func add_content(control: Control) -> void:
	custom_content = control

func get_confirm_button() -> M3Button:
	return _fs_confirm_btn if fullscreen else _confirm_btn

func get_cancel_button() -> Control:
	return _close_btn if fullscreen else _cancel_btn

func get_close_button() -> M3IconButton:
	return _close_btn

func get_dialog_card() -> PanelContainer:
	return _fullscreen_panel if fullscreen else _dialog_card

func _update_ui() -> void:
	if _headline_label == null:
		return

	_center_container.visible = not fullscreen
	_fullscreen_panel.visible = fullscreen

	_headline_label.text = headline
	_body_label.text = body_text
	_body_label.visible = not body_text.is_empty()
	_cancel_btn.text = cancel_label
	_cancel_btn.visible = not cancel_label.is_empty()
	_confirm_btn.text = confirm_label
	_confirm_btn.visible = not confirm_label.is_empty()

	_fs_headline_label.text = headline
	_fs_body_label.text = body_text
	_fs_body_label.visible = not body_text.is_empty()
	_fs_confirm_btn.text = confirm_label if not confirm_label.is_empty() else "Save"

	var has_icon: bool = (icon_name != &"" or icon != null)
	_m3_icon.visible = (icon_name != &"")
	_m3_icon.icon_name = icon_name
	_icon_rect.visible = (icon != null and icon_name == &"")
	_icon_rect.texture = icon
	_headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if has_icon else HORIZONTAL_ALIGNMENT_LEFT

	if custom_content:
		var target_box: VBoxContainer = _fs_content_box if fullscreen else _content_box
		if custom_content.get_parent() != target_box:
			if custom_content.get_parent():
				custom_content.get_parent().remove_child(custom_content)
			target_box.add_child(custom_content)
			if not fullscreen and target_box.get_child_count() >= 2:
				target_box.move_child(custom_content, target_box.get_child_count() - 2)

func _apply_styling() -> void:
	if not _dialog_card:
		return
	var s := get_scheme()

	queue_redraw()

	# Basic dialog card stylebox (M3 Extra Large 28dp, surface_container_high)
	var sb := StyleBoxFlat.new()
	sb.bg_color = s.surface_container_high
	sb.set_corner_radius_all(corner_radius)
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_offset = Vector2(0, 4)
	_dialog_card.add_theme_stylebox_override("panel", sb)

	# Fullscreen panel stylebox (0dp corner radius, surface color)
	if _fullscreen_panel:
		var fs_sb := StyleBoxFlat.new()
		fs_sb.bg_color = s.surface
		fs_sb.set_corner_radius_all(0)
		_fullscreen_panel.add_theme_stylebox_override("panel", fs_sb)

	if _header_bar:
		var hb_sb := StyleBoxFlat.new()
		hb_sb.bg_color = s.surface
		hb_sb.set_corner_radius_all(0)
		_header_bar.add_theme_stylebox_override("panel", hb_sb)

	if _m3_icon:
		_m3_icon.icon_color = s.secondary
	if _icon_rect:
		_icon_rect.modulate = s.secondary

	_headline_label.add_theme_color_override("font_color", s.on_surface)
	_body_label.add_theme_color_override("font_color", s.on_surface_variant)
	if _fs_headline_label:
		_fs_headline_label.add_theme_color_override("font_color", s.on_surface)
	if _fs_body_label:
		_fs_body_label.add_theme_color_override("font_color", s.on_surface_variant)

func _draw() -> void:
	if fullscreen:
		return
	var s := get_scheme()
	var sc := s.scrim
	sc.a = 0.32 * open_progress
	draw_rect(Rect2(Vector2.ZERO, size), sc, true)

func _gui_input(event: InputEvent) -> void:
	if fullscreen:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dismiss_on_scrim_click:
			dismiss()
			accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()

func open() -> void:
	_sync_parent_bounds()
	is_open = true
	visible = true
	_update_ui()
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
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"open_progress", 1.0, 0.22)
	_tween.chain().tween_callback(func() -> void: opened.emit())

func show_dialog() -> void:
	open()

func close() -> void:
	is_open = false
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
	_tween.tween_property(self, ^"open_progress", 0.0, 0.16)
	_tween.chain().tween_callback(func() -> void:
		visible = false
		closed.emit()
	)

func hide_dialog() -> void:
	close()

func dismiss() -> void:
	dismissed.emit()
	close()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	close()

func _on_confirm_pressed() -> void:
	confirmed.emit()
	close()
