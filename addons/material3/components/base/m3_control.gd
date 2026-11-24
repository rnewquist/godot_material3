@tool
class_name M3Control
extends Control

## Base class for all Material 3 interactive controls.
## Handles state machine, theming lifecycle, touch targets, and ripple integration.

const M3RippleScript = preload("res://addons/material3/components/base/m3_ripple.gd")

enum ControlState {
	NORMAL,
	HOVERED,
	FOCUSED,
	PRESSED,
	DISABLED
}

signal state_changed(old_state: ControlState, new_state: ControlState)

@export var disabled: bool = false:
	set(value):
		if disabled != value:
			disabled = value
			_update_disabled_state()

@export var ripple_enabled: bool = true:
	set(value):
		ripple_enabled = value
		_update_ripple_state()

@export var shape_token: M3Shapes.ShapeToken = M3Shapes.ShapeToken.NONE:
	set(value):
		shape_token = value
		_update_shapes()
		queue_redraw()

@export var custom_corner_radius: float = -1.0:
	set(value):
		custom_corner_radius = value
		_update_shapes()
		queue_redraw()

@export var touch_target_min_size: Vector2 = Vector2(48.0, 48.0)

## Optional per-control M3 density override (-3..0). When > 0 (default 99), uses M3ThemeSingleton.visual_density.
@export var density_override: int = 99:
	set(value):
		density_override = value
		_on_theme_updated()
		queue_redraw()

var current_state: ControlState = ControlState.NORMAL
var _ripple: Control = null
var _theme_connected: bool = false
var _pointer_inside: bool = false
var _is_pointer_down: bool = false
var _state_layer_alpha: float = 0.0
var _ripple_wave_radius: float = 0.0
var _ripple_wave_alpha: float = 0.0
var _ripple_wave_count: int = 0

func _init() -> void:
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_STOP

func _enter_tree() -> void:
	_connect_theme()
	_ensure_ripple()
	_update_disabled_state()
	_update_shapes()
	_on_theme_updated()

func _exit_tree() -> void:
	_disconnect_theme()

func _ready() -> void:
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if not focus_entered.is_connected(_on_focus_entered):
		focus_entered.connect(_on_focus_entered)
	if not focus_exited.is_connected(_on_focus_exited):
		focus_exited.connect(_on_focus_exited)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_ensure_ripple()
	_update_shapes()
	_on_theme_updated()

func _connect_theme() -> void:
	if _theme_connected:
		return
	var theme_instance = M3ThemeSingleton.get_instance()
	if theme_instance == null:
		var st := Engine.get_main_loop() as SceneTree
		if st != null and st.root != null:
			theme_instance = st.root.get_node_or_null(^"M3Theme")

	if theme_instance != null:
		if not theme_instance.theme_changed.is_connected(_on_m3_theme_changed):
			theme_instance.theme_changed.connect(_on_m3_theme_changed)
			_theme_connected = true

func _disconnect_theme() -> void:
	if not _theme_connected:
		return
	var theme_instance = M3ThemeSingleton.get_instance()
	if theme_instance == null:
		var st := Engine.get_main_loop() as SceneTree
		if st != null and st.root != null:
			theme_instance = st.root.get_node_or_null(^"M3Theme")

	if theme_instance != null and theme_instance.theme_changed.is_connected(_on_m3_theme_changed):
		theme_instance.theme_changed.disconnect(_on_m3_theme_changed)
	_theme_connected = false

func _on_m3_theme_changed() -> void:
	_on_theme_updated()
	_update_ripple_colors()
	queue_redraw()

func _ensure_ripple() -> void:
	if not ripple_enabled:
		if _ripple != null and is_instance_valid(_ripple):
			_ripple.visible = false
		return

	if _ripple == null or not is_instance_valid(_ripple):
		var found_ripple := get_node_or_null(^"M3Ripple") as Control
		if found_ripple != null:
			_ripple = found_ripple
		else:
			_ripple = M3RippleScript.new()
			_ripple.name = "M3Ripple"
			add_child(_ripple, false, INTERNAL_MODE_FRONT)
	
	_ripple.visible = true
	_update_shapes()
	_update_ripple_colors()

func _update_ripple_state() -> void:
	if _ripple != null and is_instance_valid(_ripple):
		_ripple.visible = ripple_enabled
	elif ripple_enabled and is_inside_tree():
		_ensure_ripple()

func _update_ripple_colors() -> void:
	if _ripple == null or not is_instance_valid(_ripple):
		return
	if _ripple.has_method("set"):
		_ripple.set("ripple_color", get_m3_color(&"on_surface"))

func _update_shapes() -> void:
	var r: float = get_effective_corner_radius()
	if _ripple != null and is_instance_valid(_ripple):
		if _ripple.has_method("set"):
			_ripple.set("corner_radius", r)

func get_effective_corner_radius() -> float:
	if custom_corner_radius >= 0.0:
		return custom_corner_radius
	return M3Shapes.get_radius(shape_token)

func get_touch_target_rect() -> Rect2:
	var w: float = maxf(size.x, touch_target_min_size.x)
	var h: float = maxf(size.y, touch_target_min_size.y)
	var offset := Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)
	return Rect2(offset, Vector2(w, h))

func _has_point(point: Vector2) -> bool:
	return get_touch_target_rect().has_point(point)

## Applies the active M3 visual density offset (-4dp per negative step) to a base height in dp.
func get_density_adjusted_height(base_height: float, min_floor: float = 24.0) -> float:
	var offset: float = float(clampi(density_override, -3, 0)) * 4.0 if density_override <= 0 else M3ThemeSingleton.get_instance().get_density_offset()
	return maxf(min_floor, base_height + offset)

## Resolves an M3 color role token from the active scheme.
## NOTE: Do not shadow the native Control.get_theme_color() here; GDScript dispatches
## engine-native names to the native implementation, which returns black for M3 tokens.
func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func _update_disabled_state() -> void:
	if disabled:
		_is_pointer_down = false
		mouse_default_cursor_shape = CURSOR_FORBIDDEN
		_set_state(ControlState.DISABLED)
		if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("cancel_ripple"):
			_ripple.call("cancel_ripple")
	else:
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		if _pointer_inside:
			_set_state(ControlState.HOVERED)
		elif has_focus():
			_set_state(ControlState.FOCUSED)
		else:
			_set_state(ControlState.NORMAL)

func _set_state(new_state: ControlState) -> void:
	if current_state == new_state:
		return
	var old_state := current_state
	current_state = new_state
	_on_state_updated(old_state, new_state)
	state_changed.emit(old_state, new_state)
	queue_redraw()

func _on_mouse_entered() -> void:
	_pointer_inside = true
	if disabled:
		return
	if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("set_hovered"):
		_ripple.call("set_hovered", true)
	if current_state != ControlState.PRESSED:
		_set_state(ControlState.HOVERED)

func _on_mouse_exited() -> void:
	_pointer_inside = false
	if disabled:
		return
	if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("set_hovered"):
		_ripple.call("set_hovered", false)
	if current_state != ControlState.PRESSED:
		if has_focus():
			_set_state(ControlState.FOCUSED)
		else:
			_set_state(ControlState.NORMAL)

func _on_focus_entered() -> void:
	if disabled:
		return
	if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("set_focused"):
		_ripple.call("set_focused", true)
	if current_state != ControlState.PRESSED and not _pointer_inside:
		_set_state(ControlState.FOCUSED)

func _on_focus_exited() -> void:
	if disabled:
		return
	if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("set_focused"):
		_ripple.call("set_focused", false)
	if current_state != ControlState.PRESSED:
		if _pointer_inside:
			_set_state(ControlState.HOVERED)
		else:
			_set_state(ControlState.NORMAL)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_pointer_down = true
				_set_state(ControlState.PRESSED)
				if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("start_press"):
					_ripple.call("start_press", mb.position)
				accept_event()
			else:
				if _is_pointer_down:
					_is_pointer_down = false
					# mb.position is in local space; compare against the 48x48dp-minimum touch target rect.
					var inside: bool = get_touch_target_rect().has_point(mb.position)
					if inside:
						if _pointer_inside:
							_set_state(ControlState.HOVERED)
						elif has_focus():
							_set_state(ControlState.FOCUSED)
						else:
							_set_state(ControlState.NORMAL)
						if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("end_press"):
							_ripple.call("end_press")
						_on_pressed_action()
					else:
						_set_state(ControlState.NORMAL)
						if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("cancel_ripple"):
							_ripple.call("cancel_ripple")
					accept_event()

	elif event is InputEventKey:
		var k := event as InputEventKey
		if (k.keycode == KEY_SPACE or k.keycode == KEY_ENTER) and not k.echo:
			if k.pressed:
				_set_state(ControlState.PRESSED)
				if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("start_press"):
					_ripple.call("start_press", size * 0.5)
				accept_event()
			else:
				if current_state == ControlState.PRESSED:
					if has_focus():
						_set_state(ControlState.FOCUSED)
					else:
						_set_state(ControlState.NORMAL)
					if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("end_press"):
						_ripple.call("end_press")
					_on_pressed_action()
					accept_event()

func _on_resized() -> void:
	_update_shapes()

# Virtual hooks for subclasses
func _on_theme_updated() -> void:
	pass

func _on_state_updated(_old_state: ControlState, _new_state: ControlState) -> void:
	pass

func _on_pressed_action() -> void:
	pass
