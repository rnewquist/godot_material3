@tool
class_name M3Surface
extends Container

## Material 3 Surface container with elevation tinting, drop shadows, and shape tokens.

@export_range(0, 5) var elevation_level: int = 0:
	set(value):
		elevation_level = clampi(value, 0, 5)
		queue_redraw()

@export var surface_role: StringName = &"surface":
	set(value):
		surface_role = value
		queue_redraw()

@export var tint_role: StringName = &"surface_tint":
	set(value):
		tint_role = value
		queue_redraw()

@export var shape_token: M3Shapes.ShapeToken = M3Shapes.ShapeToken.NONE:
	set(value):
		shape_token = value
		queue_redraw()

@export var corner_radius_override: float = -1.0:
	set(value):
		corner_radius_override = value
		queue_redraw()

@export var border_color: Color = Color.TRANSPARENT:
	set(value):
		border_color = value
		queue_redraw()

@export var border_width: int = 0:
	set(value):
		border_width = value
		queue_redraw()

@export var custom_surface_color: Color = Color.TRANSPARENT:
	set(value):
		custom_surface_color = value
		queue_redraw()

@export var content_margin_left: int = 0:
	set(value):
		content_margin_left = value
		queue_sort()

@export var content_margin_top: int = 0:
	set(value):
		content_margin_top = value
		queue_sort()

@export var content_margin_right: int = 0:
	set(value):
		content_margin_right = value
		queue_sort()

@export var content_margin_bottom: int = 0:
	set(value):
		content_margin_bottom = value
		queue_sort()

var _theme_connected: bool = false

func _enter_tree() -> void:
	_connect_theme()
	queue_redraw()

func _exit_tree() -> void:
	_disconnect_theme()

func _connect_theme() -> void:
	if _theme_connected:
		return
	var theme_instance := M3ThemeSingleton.get_instance()
	if theme_instance != null:
		if not theme_instance.theme_changed.is_connected(_on_theme_changed):
			theme_instance.theme_changed.connect(_on_theme_changed)
			_theme_connected = true

func _disconnect_theme() -> void:
	if not _theme_connected:
		return
	var theme_instance := M3ThemeSingleton.get_instance()
	if theme_instance != null and theme_instance.theme_changed.is_connected(_on_theme_changed):
		theme_instance.theme_changed.disconnect(_on_theme_changed)
	_theme_connected = false

func _on_theme_changed() -> void:
	queue_redraw()

func get_effective_corner_radius() -> float:
	if corner_radius_override >= 0.0:
		return corner_radius_override
	return M3Shapes.get_radius(shape_token)

func get_effective_surface_color() -> Color:
	var base_col: Color
	if custom_surface_color.a > 0.0:
		base_col = custom_surface_color
	else:
		base_col = M3ThemeSingleton.get_instance().get_color(surface_role)
	
	var tint_col: Color = M3ThemeSingleton.get_instance().get_color(tint_role)
	return M3Elevation.get_surface_tinted_color(base_col, tint_col, elevation_level)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()

func _sort_children() -> void:
	var left: float = float(content_margin_left)
	var top: float = float(content_margin_top)
	var avail_w: float = maxf(0.0, size.x - left - float(content_margin_right))
	var avail_h: float = maxf(0.0, size.y - top - float(content_margin_bottom))

	for child in get_children():
		if child is Control and child.visible and not child.is_set_as_top_level():
			fit_child_in_rect(child, Rect2(left, top, avail_w, avail_h))

func _get_minimum_size() -> Vector2:
	var min_s: Vector2 = Vector2.ZERO
	for child in get_children():
		if child is Control and child.visible and not child.is_set_as_top_level():
			var cs: Vector2 = child.get_combined_minimum_size()
			min_s.x = maxf(min_s.x, cs.x)
			min_s.y = maxf(min_s.y, cs.y)

	min_s.x += float(content_margin_left + content_margin_right)
	min_s.y += float(content_margin_top + content_margin_bottom)
	return min_s

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var radius := get_effective_corner_radius()
	var final_color := get_effective_surface_color()

	# Drop shadow when elevation > 0
	if elevation_level > 0:
		var shadow_props := M3Elevation.get_shadow_props(elevation_level)
		var offset_y: float = shadow_props.get("offset_y", 1.0)
		var blur: float = shadow_props.get("blur", 3.0)
		var alpha: float = shadow_props.get("alpha", 0.15)
		var shadow_col := Color(0, 0, 0, alpha)

		# Draw shadow via StyleBoxFlat
		var shadow_sb := StyleBoxFlat.new()
		shadow_sb.bg_color = Color.TRANSPARENT
		shadow_sb.set_corner_radius_all(int(radius))
		shadow_sb.shadow_color = shadow_col
		shadow_sb.shadow_size = int(blur)
		shadow_sb.shadow_offset = Vector2(0, offset_y)
		draw_style_box(shadow_sb, r)

	# Surface background
	var sb := StyleBoxFlat.new()
	sb.bg_color = final_color
	sb.set_corner_radius_all(int(radius))
	if border_width > 0 and border_color.a > 0.0:
		sb.set_border_width_all(border_width)
		sb.border_color = border_color
	draw_style_box(sb, r)
