@tool
class_name M3Switch
extends M3Control

## Material 3 Switch component with smooth spring glide thumb animation and optional icons.

signal toggled(toggled_on: bool)

@export var selected: bool = false:
	set(value):
		if selected != value:
			selected = value
			_animate_switch()
			toggled.emit(selected)
			queue_redraw()

@export var checked: bool:
	get:
		return selected
	set(value):
		selected = value

@export var show_icons: bool = false:
	set(value):
		show_icons = value
		queue_redraw()

@export var text: String = "":
	set(value):
		text = value
		_update_min_size()
		queue_redraw()

var _progress: float = 0.0
var _thumb_size: float = 16.0
var _anim_tween: Tween = null
var _font: Font = null
var _font_size: int = 14

func _init() -> void:
	super._init()
	custom_minimum_size = Vector2(52.0, 48.0)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_update_font()
	_progress = 1.0 if selected else 0.0
	_thumb_size = 24.0 if (selected or show_icons) else 16.0
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

func _animate_switch() -> void:
	var target: float = 1.0 if selected else 0.0
	var target_thumb: float = 24.0 if (selected or show_icons) else 16.0
	if not is_inside_tree():
		_progress = target
		_thumb_size = target_thumb
		return
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween()
	if _anim_tween:
		_anim_tween.bind_node(self)
		_anim_tween.set_parallel(true)
		_anim_tween.set_trans(Tween.TRANS_CUBIC)
		_anim_tween.set_ease(Tween.EASE_OUT)
		_anim_tween.tween_property(self, ^"_progress", target, 0.2)
		_anim_tween.tween_property(self, ^"_thumb_size", target_thumb, 0.2)
		_anim_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)
	_update_ripple_colors()

func _update_min_size() -> void:
	var w: float = 52.0
	if _font != null and not text.is_empty():
		var text_w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		w = 52.0 + 16.0 + text_w
	custom_minimum_size = Vector2(w, 48.0)
	size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
	update_minimum_size()

func _on_pressed_action() -> void:
	selected = not selected

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var track_w: float = 52.0
	var track_h: float = 32.0
	var track_top: float = (size.y - track_h) * 0.5
	var track_rect := Rect2(0, track_top, track_w, track_h)

	var primary_col := get_m3_color(&"primary")
	var on_primary_col := get_m3_color(&"on_primary")
	var surf_highest := get_m3_color(&"surface_container_highest")
	var outline_col := get_m3_color(&"outline")
	var on_surf_var := get_m3_color(&"on_surface_variant")
	var on_surf_col := get_m3_color(&"on_surface")

	var track_fill: Color
	var track_border_col: Color
	var track_border_w: int = 0
	var thumb_col: Color
	var icon_col: Color

	if disabled:
		var dis_container := Color(on_surf_col, M3Color.DISABLED_CONTAINER_OPACITY)
		var dis_content := Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
		if selected:
			track_fill = dis_container
			thumb_col = get_m3_color(&"surface")
			icon_col = dis_content
		else:
			track_fill = dis_container
			track_border_col = dis_content
			track_border_w = 2
			thumb_col = dis_content
			icon_col = get_m3_color(&"surface")
	else:
		if _progress > 0.01:
			track_fill = surf_highest.lerp(primary_col, _progress)
			track_border_col = outline_col.lerp(Color.TRANSPARENT, _progress)
			track_border_w = int(round(lerpf(2.0, 0.0, _progress)))
			thumb_col = outline_col.lerp(on_primary_col, _progress)
			icon_col = on_surf_var.lerp(primary_col, _progress)
		else:
			track_fill = surf_highest
			track_border_col = outline_col
			track_border_w = 2
			thumb_col = outline_col
			icon_col = surf_highest

	# Draw track
	var track_sb := StyleBoxFlat.new()
	track_sb.bg_color = track_fill
	track_sb.set_corner_radius_all(16)
	if track_border_w > 0 and track_border_col.a > 0.0:
		track_sb.set_border_width_all(track_border_w)
		track_sb.border_color = track_border_col
	draw_style_box(track_sb, track_rect)

	# Calculate thumb position and size
	var thumb_unselected_size: float = 16.0
	var thumb_selected_size: float = 24.0
	if show_icons:
		thumb_unselected_size = 24.0

	var cur_thumb_size: float = lerpf(thumb_unselected_size, thumb_selected_size, _progress)
	var thumb_center_x: float = lerpf(16.0, track_w - 16.0, _progress)
	var thumb_center := Vector2(thumb_center_x, track_top + track_h * 0.5)

	# Draw thumb
	draw_circle(thumb_center, cur_thumb_size * 0.5, thumb_col)

	# Draw icons inside thumb if enabled
	if show_icons:
		var ic_scale: float = cur_thumb_size / 24.0
		var sw: float = maxf(1.0, 1.8 * ic_scale)
		var t := func(p: Vector2) -> Vector2:
			return thumb_center + (p - Vector2(12.0, 12.0)) * ic_scale

		if selected:
			var pts := PackedVector2Array([t.call(Vector2(6, 12)), t.call(Vector2(10, 16)), t.call(Vector2(18, 8))])
			draw_polyline(pts, icon_col, sw, true)
		else:
			draw_line(t.call(Vector2(7, 7)), t.call(Vector2(17, 17)), icon_col, sw, true)
			draw_line(t.call(Vector2(17, 7)), t.call(Vector2(7, 17)), icon_col, sw, true)

	# Draw label
	if _font != null and not text.is_empty():
		var label_col := Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY) if disabled else on_surf_col
		var text_x: float = track_w + 16.0
		var font_ascent := _font.get_ascent(_font_size)
		var text_y := (size.y - _font.get_height(_font_size)) * 0.5 + font_ascent
		draw_string(_font, Vector2(text_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, label_col)
