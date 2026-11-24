@tool
class_name M3Card
extends Container

## Material 3 Card component (https://m3.material.io/components/cards/overview).
## Supports Elevated (surface_container_low, elevation 1->2), Filled (surface_container_highest),
## and Outlined (surface, 1dp outline_variant border) variants with 12dp Medium corner radius,
## interactive clickable hover/press state layer and elevation tweening, and optional drag interaction.

signal clicked
signal pressed
signal drag_started
signal dragged(offset: Vector2)
signal drag_ended

enum CardType {
	ELEVATED,
	FILLED,
	OUTLINED
}

@export var card_type: CardType = CardType.ELEVATED:
	set(value):
		card_type = value
		_update_target_visuals(false)
		queue_redraw()

@export var clickable: bool = false:
	set(value):
		clickable = value
		_sync_input_filter()
		queue_redraw()

@export var is_clickable: bool:
	get:
		return clickable
	set(value):
		clickable = value

@export var draggable: bool = false:
	set(value):
		draggable = value
		_sync_input_filter()
		queue_redraw()

@export var is_draggable: bool:
	get:
		return draggable
	set(value):
		draggable = value

@export var disabled: bool = false:
	set(value):
		disabled = value
		_update_target_visuals(false)
		queue_redraw()

@export var padding: int = 16:
	set(value):
		padding = value
		queue_sort()

@export var corner_radius: int = 12:
	set(value):
		corner_radius = value
		if _ripple_effect:
			_ripple_effect.corner_radius = float(corner_radius)
		queue_redraw()

var is_hovered: bool = false
var is_pressed_state: bool = false
var is_focused: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var _current_elevation: float = 1.0:
	set(value):
		_current_elevation = value
		queue_redraw()

var _state_layer_alpha: float = 0.0:
	set(value):
		_state_layer_alpha = value
		queue_redraw()

var _ripple_wave_radius: float = 0.0
var _ripple_wave_alpha: float = 0.0
var _ripple_wave_count: int = 0

var _ripple_effect: M3Ripple = null
var _state_tween: Tween = null
var _drag_start_global: Vector2 = Vector2.ZERO
var _drag_origin_pos: Vector2 = Vector2.ZERO

func _init() -> void:
	custom_minimum_size = Vector2(100, 60)
	_sync_input_filter()
	_update_target_visuals(false)

func _ready() -> void:
	_setup_theme_listener()
	_setup_ripple()
	_sync_input_filter()
	_update_target_visuals(false)
	queue_redraw()

func _sync_input_filter() -> void:
	var interactive: bool = (clickable or draggable)
	focus_mode = FOCUS_ALL if interactive else FOCUS_NONE
	mouse_filter = MOUSE_FILTER_STOP if interactive else MOUSE_FILTER_PASS

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
		_ripple_effect.name = "M3Ripple"
		_ripple_effect.corner_radius = float(corner_radius)
		add_child(_ripple_effect)

func _on_theme_changed() -> void:
	if _ripple_effect:
		_ripple_effect.ripple_color = get_scheme().on_surface
	_resort_children()
	queue_redraw()

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func _get_rest_elevation() -> float:
	if disabled:
		return 0.0
	return 1.0 if card_type == CardType.ELEVATED else 0.0

func _get_target_elevation() -> float:
	if disabled:
		return 0.0
	var interactive: bool = (clickable or draggable)
	if is_dragging:
		return 4.0
	if interactive and (is_hovered or is_pressed_state):
		return 2.0 if card_type == CardType.ELEVATED else 1.0
	return _get_rest_elevation()

func _get_target_state_alpha() -> float:
	if disabled or not (clickable or draggable):
		return 0.0
	if is_dragging:
		return 0.16
	if is_pressed_state:
		return 0.12
	if is_hovered:
		return 0.08
	if is_focused:
		return 0.10
	return 0.0

func _update_target_visuals(animated: bool = true) -> void:
	var target_elev: float = _get_target_elevation()
	var target_alpha: float = _get_target_state_alpha()

	if _state_tween and _state_tween.is_valid():
		_state_tween.kill()

	if animated and is_inside_tree():
		_state_tween = create_tween()
		_state_tween.bind_node(self)
		_state_tween.set_parallel(true)
		_state_tween.set_trans(Tween.TRANS_CUBIC)
		_state_tween.set_ease(Tween.EASE_OUT)
		_state_tween.tween_property(self, ^"_current_elevation", target_elev, 0.15)
		_state_tween.tween_property(self, ^"_state_layer_alpha", target_alpha, 0.15)
	else:
		_current_elevation = target_elev
		_state_layer_alpha = target_alpha

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_resort_children()
		NOTIFICATION_MOUSE_ENTER:
			if (clickable or draggable) and not disabled:
				is_hovered = true
				if _ripple_effect:
					_ripple_effect.set_hovered(true)
				_update_target_visuals(true)
				queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			if (clickable or draggable) and not disabled:
				is_hovered = false
				if _ripple_effect:
					_ripple_effect.set_hovered(false)
				_update_target_visuals(true)
				queue_redraw()
		NOTIFICATION_FOCUS_ENTER:
			if clickable or draggable:
				is_focused = true
				_update_target_visuals(true)
				queue_redraw()
		NOTIFICATION_FOCUS_EXIT:
			if clickable or draggable:
				is_focused = false
				_update_target_visuals(true)
				queue_redraw()
		NOTIFICATION_RESIZED:
			queue_redraw()

func _get_minimum_size() -> Vector2:
	var pad := float(padding) * 2.0
	var max_cs := Vector2.ZERO
	for child in get_children():
		if child is Control and child != _ripple_effect and (child as Control).visible:
			var cs: Vector2 = (child as Control).get_combined_minimum_size()
			max_cs.x = maxf(max_cs.x, cs.x)
			max_cs.y = maxf(max_cs.y, cs.y)
	return Vector2(maxf(100.0, max_cs.x + pad), maxf(60.0, max_cs.y + pad))

func _apply_fg_recursive(node: Node, fg: Color) -> void:
	if node is Label:
		(node as Label).add_theme_color_override("font_color", fg)
	for ch in node.get_children():
		if ch is M3Control:
			continue
		_apply_fg_recursive(ch, fg)

func _resort_children() -> void:
	var pad := float(padding)
	var available_rect := Rect2(pad, pad, maxf(0.0, size.x - pad * 2.0), maxf(0.0, size.y - pad * 2.0))
	var fg := get_scheme().on_surface
	for child in get_children():
		if child is Control and child != _ripple_effect:
			fit_child_in_rect(child, available_rect)
			_apply_fg_recursive(child, fg)
	if _ripple_effect:
		fit_child_in_rect(_ripple_effect, Rect2(Vector2.ZERO, size))

func _gui_input(event: InputEvent) -> void:
	if (not clickable and not draggable) or disabled:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_pressed_state = true
				_drag_start_global = mb.global_position
				_drag_origin_pos = position
				if _ripple_effect:
					_ripple_effect.ripple_color = get_scheme().on_surface
					_ripple_effect.start_press(mb.position)
				_update_target_visuals(true)
				pressed.emit()
				queue_redraw()
				accept_event()
			else:
				if is_dragging:
					is_dragging = false
					if _ripple_effect:
						_ripple_effect.set_dragged(false)
					drag_ended.emit()
				if is_pressed_state:
					is_pressed_state = false
					if _ripple_effect:
						_ripple_effect.end_press()
					clicked.emit()
				_update_target_visuals(true)
				queue_redraw()
				accept_event()

	elif event is InputEventMouseMotion and is_pressed_state and draggable:
		var mm := event as InputEventMouseMotion
		var delta: Vector2 = mm.global_position - _drag_start_global
		if not is_dragging and delta.length() > 4.0:
			is_dragging = true
			if _ripple_effect:
				_ripple_effect.set_dragged(true)
			_update_target_visuals(true)
			drag_started.emit()
		if is_dragging:
			drag_offset = delta
			position = _drag_origin_pos + delta
			dragged.emit(drag_offset)
			accept_event()

func _draw() -> void:
	var s := get_scheme()
	var rect := Rect2(Vector2.ZERO, size)
	var corner_rad: int = maxi(0, corner_radius)

	var bg_color := s.surface_container_low
	var border_width: int = 0
	var border_color := Color.TRANSPARENT

	match card_type:
		CardType.ELEVATED:
			bg_color = s.surface_container_low
		CardType.FILLED:
			bg_color = s.surface_container_highest
		CardType.OUTLINED:
			bg_color = s.surface
			border_width = 1
			border_color = s.outline_variant
			if (clickable or draggable) and (is_hovered or is_dragging):
				border_color = s.on_surface_variant

	if disabled:
		bg_color = s.surface.lerp(Color.TRANSPARENT, 0.6)
		border_color = s.outline_variant.lerp(Color.TRANSPARENT, 0.6)

	# 1. Rounded elevation shadow
	var elev_int: int = clampi(int(round(_current_elevation)), 0, 5)
	if elev_int > 0 and not disabled:
		var shadow_props := M3Elevation.get_shadow_props(elev_int)
		var offset_y: float = shadow_props.get("offset_y", 1.0)
		var blur: float = shadow_props.get("blur", 3.0)
		var alpha: float = shadow_props.get("alpha", 0.15)
		var shadow_sb := StyleBoxFlat.new()
		shadow_sb.bg_color = Color.TRANSPARENT
		shadow_sb.set_corner_radius_all(corner_rad)
		shadow_sb.shadow_color = Color(0, 0, 0, alpha)
		shadow_sb.shadow_size = int(blur)
		shadow_sb.shadow_offset = Vector2(0, offset_y)
		draw_style_box(shadow_sb, rect)

	# 2. Card container background & border
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(corner_rad)
	if border_width > 0:
		sb.set_border_width_all(border_width)
		sb.border_color = border_color
	draw_style_box(sb, rect)

	# 3. State overlay (rounded to match card)
	if (clickable or draggable) and not disabled and _state_layer_alpha > 0.001:
		var ov_sb := StyleBoxFlat.new()
		var ov := s.on_surface
		ov.a = _state_layer_alpha
		ov_sb.bg_color = ov
		ov_sb.set_corner_radius_all(corner_rad)
		draw_style_box(ov_sb, rect)
