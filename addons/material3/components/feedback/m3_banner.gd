@tool
class_name M3Banner
extends PanelContainer

signal action_1_pressed
signal action_2_pressed
signal primary_action_pressed
signal secondary_action_pressed
signal dismissed

@export var text: String = "Banner message content explaining an issue or state.":
	set(value):
		text = value
		if message != value:
			message = value
		_update_ui()

@export var message: String = "Banner message content explaining an issue or state.":
	set(value):
		message = value
		if text != value:
			text = value
		_update_ui()

@export var icon: Texture2D = null:
	set(value):
		icon = value
		_update_ui()

@export var show_icon: bool = false:
	set(value):
		show_icon = value
		_update_ui()

@export var action_1_label: String = "Action 1":
	set(value):
		action_1_label = value
		if primary_action_label != value:
			primary_action_label = value
		_update_ui()

@export var primary_action_label: String = "Action 1":
	set(value):
		primary_action_label = value
		if action_1_label != value:
			action_1_label = value
		_update_ui()

@export var action_2_label: String = "Dismiss":
	set(value):
		action_2_label = value
		if secondary_action_label != value:
			secondary_action_label = value
		_update_ui()

@export var secondary_action_label: String = "Dismiss":
	set(value):
		secondary_action_label = value
		if action_2_label != value:
			action_2_label = value
		_update_ui()

@export var dismiss_on_secondary: bool = true

var open_progress: float = 1.0
var is_open: bool = true
var primary_click_count: int = 0
var secondary_click_count: int = 0

var _icon_rect: TextureRect
var _icon_badge: PanelContainer
var _icon_lbl: Label
var _label: Label
var _btn1: Button
var _btn2: Button
var _tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(440, 84)
	size = custom_minimum_size
	size_flags_horizontal = SIZE_EXPAND_FILL

func _ready() -> void:
	_setup_theme_listener()
	_build_ui()
	_apply_styling()
	_update_ui()
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))

func _exit_tree() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.disconnect(_on_theme_changed)

func _setup_theme_listener() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and not mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.connect(_on_theme_changed)

func _on_theme_changed() -> void:
	_apply_styling()
	queue_redraw()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func get_primary_button() -> Button:
	return _btn1

func get_secondary_button() -> Button:
	return _btn2

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var margin := MarginContainer.new()
	margin.name = "ContentMargin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "ContentColumn"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.add_theme_constant_override("separation", 16)
	vbox.add_child(top_row)

	_icon_rect = TextureRect.new()
	_icon_rect.name = "IconTexture"
	_icon_rect.custom_minimum_size = Vector2(24, 24)
	_icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_row.add_child(_icon_rect)

	_icon_badge = PanelContainer.new()
	_icon_badge.name = "IconBadge"
	_icon_badge.custom_minimum_size = Vector2(36, 36)
	_icon_lbl = Label.new()
	_icon_lbl.text = "!"
	_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_lbl.add_theme_font_size_override("font_size", 16)
	_icon_badge.add_child(_icon_lbl)
	top_row.add_child(_icon_badge)

	_label = Label.new()
	_label.name = "MessageLabel"
	_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 14)
	top_row.add_child(_label)

	var bottom_row := HBoxContainer.new()
	bottom_row.name = "ActionRow"
	bottom_row.alignment = BoxContainer.ALIGNMENT_END
	bottom_row.add_theme_constant_override("separation", 8)
	vbox.add_child(bottom_row)

	_btn2 = Button.new()
	_btn2.name = "SecondaryActionButton"
	_btn2.flat = true
	_btn2.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_btn2.pressed.connect(_on_secondary_pressed)
	bottom_row.add_child(_btn2)

	_btn1 = Button.new()
	_btn1.name = "PrimaryActionButton"
	_btn1.flat = true
	_btn1.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_btn1.pressed.connect(_on_primary_pressed)
	bottom_row.add_child(_btn1)

func _on_primary_pressed() -> void:
	primary_click_count += 1
	action_1_pressed.emit()
	primary_action_pressed.emit()

func _on_secondary_pressed() -> void:
	secondary_click_count += 1
	action_2_pressed.emit()
	secondary_action_pressed.emit()
	if dismiss_on_secondary:
		dismiss()

func _update_ui() -> void:
	if not _label:
		return
	_label.text = text
	_btn1.text = action_1_label
	_btn1.visible = action_1_label != ""
	_btn2.text = action_2_label
	_btn2.visible = action_2_label != ""

	if icon != null:
		_icon_rect.texture = icon
		_icon_rect.visible = true
		_icon_badge.visible = false
	elif show_icon:
		_icon_rect.visible = false
		_icon_badge.visible = true
	else:
		_icon_rect.visible = false
		_icon_badge.visible = false

func _apply_styling() -> void:
	var s := get_scheme()
	var sb := StyleBoxFlat.new()
	sb.bg_color = s.surface_container
	sb.border_width_bottom = 1
	sb.border_color = s.outline_variant
	add_theme_stylebox_override("panel", sb)

	if _icon_badge:
		var badge_sb := StyleBoxFlat.new()
		badge_sb.bg_color = s.secondary_container
		badge_sb.set_corner_radius_all(18)
		_icon_badge.add_theme_stylebox_override("panel", badge_sb)
	if _icon_lbl:
		_icon_lbl.add_theme_color_override("font_color", s.on_secondary_container)
	if _label:
		_label.add_theme_color_override("font_color", s.on_surface)
	if _btn1:
		_btn1.add_theme_color_override("font_color", s.primary)
		_btn1.add_theme_color_override("font_hover_color", s.primary)
		_btn1.add_theme_color_override("font_pressed_color", s.primary)
	if _btn2:
		_btn2.add_theme_color_override("font_color", s.primary)
		_btn2.add_theme_color_override("font_hover_color", s.primary)
		_btn2.add_theme_color_override("font_pressed_color", s.primary)

func _set_open_progress(val: float) -> void:
	open_progress = val
	modulate.a = clampf(val, 0.0, 1.0)
	queue_redraw()

func show_banner() -> void:
	visible = true
	is_open = true
	if _tween and _tween.is_valid():
		_tween.kill()
	if not is_inside_tree():
		_set_open_progress(1.0)
		return
	_set_open_progress(0.0)
	_tween = create_tween()
	_tween.tween_method(_set_open_progress, 0.0, 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func dismiss() -> void:
	is_open = false
	if _tween and _tween.is_valid():
		_tween.kill()
	if not is_inside_tree():
		_set_open_progress(0.0)
		visible = false
		dismissed.emit()
		return
	_tween = create_tween()
	_tween.tween_method(_set_open_progress, open_progress, 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(func() -> void:
		dismissed.emit()
		visible = false
	)
