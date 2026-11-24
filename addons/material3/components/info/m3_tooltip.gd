@tool
class_name M3Tooltip
extends M3BaseControl

enum TooltipType {
	PLAIN,
	RICH
}

const VariantType = TooltipType

signal action_clicked
signal action_pressed

@export var tooltip_type: TooltipType = TooltipType.PLAIN:
	set(value):
		tooltip_type = value
		if variant != value:
			variant = value
		_update_layout()

@export var variant: TooltipType = TooltipType.PLAIN:
	set(value):
		variant = value
		if tooltip_type != value:
			tooltip_type = value
		_update_layout()

@export var title: String = "":
	set(value):
		title = value
		_update_layout()

@export var text: String = "Tooltip message":
	set(value):
		text = value
		_update_layout()

@export var action_text: String = "":
	set(value):
		action_text = value
		_update_layout()

@export var enter_delay: float = 0.08
@export var target_node_path: NodePath:
	set(value):
		target_node_path = value
		_setup_target()

var open_progress: float = 0.0
var is_open: bool = false
var action_click_count: int = 0

var _target_node: Control
var _delay_timer: Timer
var _fade_tween: Tween
var _is_visible_state: bool = false
var _action_hovered: bool = false
var _action_rect: Rect2 = Rect2()

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	visible = false
	modulate.a = 0.0
	_update_layout()

func _ready() -> void:
	super._ready()
	focus_mode = FOCUS_NONE
	if _ripple_effect:
		_ripple_effect.visible = false
		_ripple_effect.mouse_filter = MOUSE_FILTER_IGNORE
	_delay_timer = Timer.new()
	_delay_timer.name = "EnterDelayTimer"
	_delay_timer.one_shot = true
	_delay_timer.timeout.connect(_on_timer_timeout)
	add_child(_delay_timer)

	_setup_target()
	_update_layout()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func set_target(ctrl: Control) -> void:
	if _target_node and is_instance_valid(_target_node):
		if _target_node.mouse_entered.is_connected(_on_target_mouse_entered):
			_target_node.mouse_entered.disconnect(_on_target_mouse_entered)
		if _target_node.mouse_exited.is_connected(_on_target_mouse_exited):
			_target_node.mouse_exited.disconnect(_on_target_mouse_exited)
	_target_node = ctrl
	if _target_node:
		if not _target_node.mouse_entered.is_connected(_on_target_mouse_entered):
			_target_node.mouse_entered.connect(_on_target_mouse_entered)
		if not _target_node.mouse_exited.is_connected(_on_target_mouse_exited):
			_target_node.mouse_exited.connect(_on_target_mouse_exited)

func _setup_target() -> void:
	if target_node_path and is_inside_tree() and has_node(target_node_path):
		set_target(get_node(target_node_path) as Control)
	elif _target_node == null and get_parent() is Control and get_parent() != get_viewport() and not (get_parent() is ColorRect) and not (get_parent() is Container):
		set_target(get_parent() as Control)

func _on_target_mouse_entered() -> void:
	if enter_delay <= 0.001 or _delay_timer == null:
		show_tooltip(true)
	else:
		_delay_timer.start(enter_delay)

func _on_target_mouse_exited() -> void:
	if _delay_timer:
		_delay_timer.stop()
	if tooltip_type == TooltipType.PLAIN or action_text == "":
		hide_tooltip(true)

func _on_timer_timeout() -> void:
	show_tooltip(true)

func _set_open_progress(val: float) -> void:
	open_progress = val
	modulate.a = clampf(val, 0.0, 1.0)
	queue_redraw()

func show_immediate() -> void:
	show_tooltip(false)

func show_tooltip(animated: bool = true) -> void:
	_update_layout()
	_position_tooltip()
	visible = true
	_is_visible_state = true
	is_open = true
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if not is_inside_tree() or not animated:
		scale = Vector2.ONE
		_set_open_progress(1.0)
		return
	_set_open_progress(0.0)
	scale = Vector2(0.92, 0.92)
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_method(_set_open_progress, 0.0, 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_tooltip(animated: bool = true) -> void:
	_is_visible_state = false
	is_open = false
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if not is_inside_tree() or not animated:
		_set_open_progress(0.0)
		visible = false
		return
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_method(_set_open_progress, open_progress, 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fade_tween.chain().tween_callback(func() -> void: visible = false)

func _position_tooltip() -> void:
	if not _target_node or not is_inside_tree():
		return
	var target_rect := _target_node.get_global_rect()
	var vp_size := get_viewport_rect().size

	var pos := Vector2(target_rect.position.x + (target_rect.size.x - size.x) * 0.5, target_rect.end.y + 6.0)
	if pos.y + size.y > vp_size.y - 8.0:
		pos.y = target_rect.position.y - size.y - 6.0
	pos.x = clampf(pos.x, 8.0, maxf(8.0, vp_size.x - size.x - 8.0))
	global_position = pos

func get_action_rect() -> Rect2:
	return _action_rect

func get_action_local_center() -> Vector2:
	return _action_rect.get_center()

func _update_layout() -> void:
	var font := get_theme_default_font()
	var font_sz := 12
	var font_bold_sz := 14

	if tooltip_type == TooltipType.PLAIN:
		mouse_filter = MOUSE_FILTER_IGNORE
		var w: float = 80.0
		if font:
			w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz).x
		custom_minimum_size = Vector2(maxf(40.0, w + 16.0), 24.0)
		size = custom_minimum_size
		_action_rect = Rect2()
	else:
		mouse_filter = MOUSE_FILTER_STOP if action_text != "" else MOUSE_FILTER_PASS
		var w: float = 200.0
		var h: float = 16.0
		if font:
			if title != "":
				var t_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_bold_sz).x
				w = maxf(w, t_w + 32.0)
				h += 24.0
			var b_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz).x
			w = maxf(w, minf(b_w + 32.0, 280.0))
			h += 28.0
			if action_text != "":
				h += 32.0
		else:
			h = 72.0 + (24.0 if title != "" else 0.0) + (32.0 if action_text != "" else 0.0)
		custom_minimum_size = Vector2(w, h)
		size = custom_minimum_size
		if action_text != "":
			var act_w: float = 72.0
			if font:
				act_w = font.get_string_size(action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			_action_rect = Rect2(Vector2(16.0, size.y - 32.0), Vector2(act_w + 16.0, 24.0))
		else:
			_action_rect = Rect2()

	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if tooltip_type != TooltipType.RICH or action_text == "":
		return
	if event is InputEventMouseMotion:
		var was_hovered := _action_hovered
		_action_hovered = _action_rect.has_point(event.position)
		if was_hovered != _action_hovered:
			queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _action_rect.has_point(event.position):
			action_click_count += 1
			action_clicked.emit()
			action_pressed.emit()
			accept_event()
			hide_tooltip(true)

func _draw() -> void:
	var s := get_scheme()
	var font := get_theme_default_font()
	var rect := Rect2(Vector2.ZERO, size)

	if tooltip_type == TooltipType.PLAIN:
		var corner_rad: float = 4.0
		var sb := create_stylebox(s.inverse_surface, corner_rad)
		draw_style_box(sb, rect)
		if font:
			var txt_sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			var pos := Vector2((size.x - txt_sz.x) * 0.5, (size.y + txt_sz.y * 0.7) * 0.5)
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, s.inverse_on_surface)
	else:
		var corner_rad: float = 12.0
		draw_m3_shadow(self, rect, corner_rad, 2)
		var sb := create_stylebox(s.surface_container, corner_rad, 1, s.outline_variant)
		draw_style_box(sb, rect)

		var y_cursor: float = 16.0
		if font:
			if title != "":
				draw_string(font, Vector2(16.0, y_cursor + 10.0), title, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 32.0), 14, s.on_surface)
				y_cursor += 22.0
			draw_string(font, Vector2(16.0, y_cursor + 10.0), text, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 32.0), 12, s.on_surface_variant)
			y_cursor += 24.0

			if action_text != "":
				var act_sz := font.get_string_size(action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
				_action_rect = Rect2(Vector2(16.0, size.y - 32.0), Vector2(act_sz.x + 16.0, 24.0))
				if _action_hovered:
					draw_rect(_action_rect, s.primary.lerp(Color.TRANSPARENT, 0.85), true)
				draw_string(font, Vector2(_action_rect.position.x + 8.0, _action_rect.position.y + 16.0), action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, s.primary)
