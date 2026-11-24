@tool
class_name M3BaseControl
extends Control

@export var disabled: bool = false:
	set(value):
		if disabled != value:
			disabled = value
			_on_state_changed()
			queue_redraw()

var is_hovered: bool = false
var is_pressed: bool = false
var is_focused: bool = false

var _ripple_effect: M3Ripple

func _ready() -> void:
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_STOP
	_setup_theme_listener()
	_setup_ripple()
	_update_theme()

func _setup_theme_listener() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and not mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.connect(_on_theme_changed)

func _exit_tree() -> void:
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.disconnect(_on_theme_changed)

func _setup_ripple() -> void:
	if not _ripple_effect:
		_ripple_effect = M3Ripple.new()
		_ripple_effect.set_anchors_preset(PRESET_FULL_RECT)
		add_child(_ripple_effect)

func _on_theme_changed() -> void:
	_update_theme()
	queue_redraw()

func _update_theme() -> void:
	pass

func _on_state_changed() -> void:
	pass

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if not disabled:
				is_hovered = true
				if _ripple_effect:
					_ripple_effect.set_hovered(true)
				_on_state_changed()
				queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			if not disabled:
				is_hovered = false
				if _ripple_effect:
					_ripple_effect.set_hovered(false)
				_on_state_changed()
				queue_redraw()
		NOTIFICATION_FOCUS_ENTER:
			is_focused = true
			_on_state_changed()
			queue_redraw()
		NOTIFICATION_FOCUS_EXIT:
			is_focused = false
			_on_state_changed()
			queue_redraw()
		NOTIFICATION_RESIZED:
			queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			if _ripple_effect:
				_ripple_effect.start_press(event.position)
			_on_state_changed()
			queue_redraw()
		else:
			if is_pressed:
				is_pressed = false
				if _ripple_effect:
					_ripple_effect.end_press()
				_on_state_changed()
				queue_redraw()

func create_stylebox(bg_color: Color, corner_radius: float, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(int(corner_radius))
	if border_width > 0:
		sb.set_border_width_all(border_width)
		sb.border_color = border_color
	return sb

func draw_m3_shadow(canvas: CanvasItem, rect: Rect2, _corner_radius: float, elevation_level: int) -> void:
	if elevation_level <= 0:
		return
	var offset := M3Elevation.get_shadow_offset(elevation_level)
	var blur := M3Elevation.get_shadow_blur(elevation_level)
	var alpha := M3Elevation.get_shadow_alpha(elevation_level)
	var shadow_color := Color(0, 0, 0, alpha)
	var shadow_rect := Rect2(rect.position + offset - Vector2(blur * 0.5, blur * 0.5), rect.size + Vector2(blur, blur))
	canvas.draw_rect(shadow_rect, shadow_color, true)
