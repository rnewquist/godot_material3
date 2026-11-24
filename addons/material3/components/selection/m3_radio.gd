@tool
class_name M3Radio
extends M3Control

## Material 3 Radio button component with animated inner dot and optional group_name.

signal toggled(selected: bool)

@export var selected: bool = false:
	set(value):
		if selected != value:
			selected = value
			_animate_dot()
			if selected and not group_name.is_empty() and is_inside_tree():
				_notify_group_selection()
			toggled.emit(selected)
			queue_redraw()

@export var group_name: String = ""

@export var text: String = "":
	set(value):
		text = value
		_update_min_size()
		queue_redraw()

@export var value: Variant = null
@export var ring_size: float = 20.0:
	set(value):
		ring_size = value
		_update_min_size()
		queue_redraw()

@export var dot_size: float = 10.0:
	set(value):
		dot_size = value
		queue_redraw()

var _dot_scale: float = 0.0
var _select_progress: float = 0.0
var _dot_tween: Tween = null
var _font: Font = null
var _font_size: int = 14

func _init() -> void:
	super._init()
	custom_minimum_size = Vector2(48.0, 48.0)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_update_font()
	_dot_scale = 1.0 if selected else 0.0
	_select_progress = _dot_scale
	_update_min_size()
	_update_ripple_colors()

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = 14

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()
	_update_ripple_colors()

func _update_ripple_colors() -> void:
	if _ripple != null and is_instance_valid(_ripple):
		_ripple.ripple_color = get_m3_color(&"primary") if selected else get_m3_color(&"on_surface")

func _animate_dot() -> void:
	var target: float = 1.0 if selected else 0.0
	if not is_inside_tree():
		_dot_scale = target
		_select_progress = target
		return
	if _dot_tween != null and _dot_tween.is_valid():
		_dot_tween.kill()

	_dot_tween = create_tween()
	if _dot_tween:
		_dot_tween.bind_node(self)
		_dot_tween.set_parallel(true)
		_dot_tween.set_trans(Tween.TRANS_CUBIC)
		_dot_tween.set_ease(Tween.EASE_OUT)
		_dot_tween.tween_property(self, ^"_dot_scale", target, 0.2)
		_dot_tween.tween_property(self, ^"_select_progress", target, 0.2)
		_dot_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)
	_update_ripple_colors()

func _notify_group_selection() -> void:
	var parent_node := get_parent()
	if parent_node != null:
		for child in parent_node.get_children():
			if child is M3Radio and child != self and child.group_name == group_name:
				child.selected = false

func _update_min_size() -> void:
	var w: float = 48.0
	if _font != null and not text.is_empty():
		var text_w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		w = 48.0 + text_w + 8.0
	custom_minimum_size = Vector2(w, 48.0)
	size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
	update_minimum_size()

func _on_pressed_action() -> void:
	if not selected:
		selected = true

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var center := Vector2(24.0, size.y * 0.5)
	var radius: float = ring_size * 0.5
	var sw: float = 2.0

	var primary_col := get_m3_color(&"primary")
	var on_surface_var := get_m3_color(&"on_surface_variant")
	var on_surface_col := get_m3_color(&"on_surface")

	if disabled:
		var dis_col := Color(on_surface_col, M3Color.DISABLED_CONTENT_OPACITY)
		draw_arc(center, radius - sw * 0.5, 0, TAU, 32, dis_col, sw, true)
		if selected:
			draw_circle(center, (dot_size * 0.5) * _dot_scale, dis_col)
	else:
		var ring_col := primary_col if selected else on_surface_var
		draw_arc(center, radius - sw * 0.5, 0, TAU, 32, ring_col, sw, true)
		if _dot_scale > 0.01:
			draw_circle(center, (dot_size * 0.5) * _dot_scale, primary_col)

	# Label text
	if _font != null and not text.is_empty():
		var label_col := Color(on_surface_col, M3Color.DISABLED_CONTENT_OPACITY) if disabled else on_surface_col
		var text_x: float = 44.0
		var font_ascent := _font.get_ascent(_font_size)
		var text_y := (size.y - _font.get_height(_font_size)) * 0.5 + font_ascent
		draw_string(_font, Vector2(text_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, label_col)
