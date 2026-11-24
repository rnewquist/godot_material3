@tool
class_name M3Badge
extends M3BaseControl

enum BadgeSize {
	SMALL,
	LARGE
}

enum BadgeColorRole {
	ERROR,
	PRIMARY,
	SECONDARY,
	TERTIARY
}

@export var badge_size: BadgeSize = BadgeSize.LARGE:
	set(value):
		badge_size = value
		_update_badge_size()

@export var color_role: BadgeColorRole = BadgeColorRole.ERROR:
	set(value):
		color_role = value
		queue_redraw()

@export var count: int = 0:
	set(value):
		count = maxi(0, value)
		_update_badge_size()

@export var max_count: int = 999:
	set(value):
		max_count = maxi(1, value)
		_update_badge_size()

@export var text: String = "":
	set(value):
		text = value
		_update_badge_size()

@export var anchor_to_target: bool = true:
	set(value):
		anchor_to_target = value
		_update_target_anchor()

@export var target_node_path: NodePath:
	set(value):
		target_node_path = value
		_update_target_anchor()

var display_text: String = ""
var _target_node: Control

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	_update_badge_size()

func _ready() -> void:
	super._ready()
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	if _ripple_effect:
		_ripple_effect.visible = false
		_ripple_effect.mouse_filter = MOUSE_FILTER_IGNORE
	_update_target_anchor()
	_update_badge_size()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func set_target(ctrl: Control) -> void:
	_target_node = ctrl
	if _target_node and not _target_node.resized.is_connected(_on_target_resized):
		_target_node.resized.connect(_on_target_resized)
	_position_on_target()

func increment(amount: int = 1) -> void:
	count = maxi(0, count + amount)
	visible = count > 0 or badge_size == BadgeSize.SMALL or text != ""

func clear() -> void:
	count = 0
	text = ""
	visible = false

func _update_target_anchor() -> void:
	if not anchor_to_target:
		return
	if target_node_path and is_inside_tree() and has_node(target_node_path):
		_target_node = get_node(target_node_path) as Control
	elif get_parent() is Control and get_parent() != get_viewport() and not (get_parent() is ColorRect) and not (get_parent() is Container):
		_target_node = get_parent() as Control

	if _target_node and not _target_node.resized.is_connected(_on_target_resized):
		_target_node.resized.connect(_on_target_resized)

	_position_on_target()

func _on_target_resized() -> void:
	_position_on_target()

func _position_on_target() -> void:
	if not _target_node or not anchor_to_target:
		return
	var target_sz := _target_node.size
	if badge_size == BadgeSize.SMALL:
		position = Vector2(target_sz.x - 6.0, 0.0)
	else:
		position = Vector2(target_sz.x - (size.x * 0.5), -(size.y * 0.3))

func get_display_text() -> String:
	if text != "":
		return text
	if count > 0:
		if count > max_count:
			return "%d+" % max_count
		return str(count)
	return ""

func _update_badge_size() -> void:
	display_text = get_display_text()
	if badge_size == BadgeSize.SMALL:
		custom_minimum_size = Vector2(6, 6)
		size = custom_minimum_size
	else:
		var font := get_theme_default_font()
		var font_sz := 11
		var txt_w: float = 0.0
		if font and display_text != "":
			txt_w = font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz).x

		var w: float = 16.0 if display_text.length() <= 1 else maxf(16.0, txt_w + 8.0)
		custom_minimum_size = Vector2(w, 16.0)
		size = custom_minimum_size

	_position_on_target()
	queue_redraw()

func _draw() -> void:
	var s := get_scheme()
	var bg_color := s.error
	var text_color := s.on_error

	match color_role:
		BadgeColorRole.PRIMARY:
			bg_color = s.primary
			text_color = s.on_primary
		BadgeColorRole.SECONDARY:
			bg_color = s.secondary
			text_color = s.on_secondary
		BadgeColorRole.TERTIARY:
			bg_color = s.tertiary
			text_color = s.on_tertiary
		BadgeColorRole.ERROR:
			bg_color = s.error
			text_color = s.on_error

	var rect := Rect2(Vector2.ZERO, size)

	if badge_size == BadgeSize.SMALL:
		draw_circle(size * 0.5, 3.0, bg_color)
	else:
		var rad: float = size.y * 0.5
		var sb := create_stylebox(bg_color, rad)
		draw_style_box(sb, rect)

		if display_text != "":
			var font := get_theme_default_font()
			var font_sz := 11
			if font:
				var str_sz := font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
				var pos := Vector2((size.x - str_sz.x) * 0.5, (size.y + str_sz.y * 0.7) * 0.5)
				draw_string(font, pos, display_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, text_color)
