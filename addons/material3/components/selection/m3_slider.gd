@tool
class_name M3Slider
extends M3Control

## Material 3 Slider component supporting Continuous, Discrete (with tick marks & value bubble), and Range modes.

enum SliderType {
	CONTINUOUS,
	DISCRETE,
	RANGE
}

enum Orientation {
	HORIZONTAL,
	VERTICAL
}

enum SliderSize {
	EXTRA_SMALL,
	SMALL,
	MEDIUM,
	LARGE,
	EXTRA_LARGE
}

signal value_changed(value: float)
signal range_changed(start_val: float, end_val: float)

@export var slider_type: SliderType = SliderType.CONTINUOUS:
	set(value):
		slider_type = value
		queue_redraw()

@export var orientation: M3Slider.Orientation = Orientation.HORIZONTAL:
	set(val):
		if orientation != val:
			orientation = val
			_update_slider_min_size()
			queue_redraw()

@export var centered_zero: bool = false:
	set(val):
		centered_zero = val
		queue_redraw()

@export var slider_size: SliderSize = SliderSize.EXTRA_SMALL:
	set(val):
		if slider_size != val:
			slider_size = val
			_update_slider_min_size()
			queue_redraw()

@export var is_discrete: bool:
	get:
		return slider_type == SliderType.DISCRETE
	set(val):
		if val:
			slider_type = SliderType.DISCRETE
		elif slider_type == SliderType.DISCRETE:
			slider_type = SliderType.CONTINUOUS

@export var range_mode: bool:
	get:
		return slider_type == SliderType.RANGE
	set(val):
		if val:
			slider_type = SliderType.RANGE
		elif slider_type == SliderType.RANGE:
			slider_type = SliderType.CONTINUOUS

@export var min_value: float = 0.0:
	set(val):
		min_value = val
		_validate_values()
		queue_redraw()

@export var max_value: float = 100.0:
	set(val):
		max_value = maxf(val, min_value + 0.001)
		_validate_values()
		queue_redraw()

@export var step: float = 1.0:
	set(val):
		step = maxf(0.0, val)
		_validate_values()
		queue_redraw()

@export var value: float = 50.0:
	set(val):
		var clamped_val := _snap_and_clamp(val)
		if value != clamped_val:
			value = clamped_val
			value_changed.emit(value)
			queue_redraw()

@export var start_value: float = 20.0:
	set(val):
		var clamped_val := _snap_and_clamp(val)
		clamped_val = minf(clamped_val, end_value)
		if start_value != clamped_val:
			start_value = clamped_val
			range_changed.emit(start_value, end_value)
			queue_redraw()

@export var end_value: float = 80.0:
	set(val):
		var clamped_val := _snap_and_clamp(val)
		clamped_val = maxf(clamped_val, start_value)
		if end_value != clamped_val:
			end_value = clamped_val
			range_changed.emit(start_value, end_value)
			queue_redraw()

@export var range_min_value: float:
	get:
		return start_value
	set(val):
		start_value = val

@export var range_max_value: float:
	get:
		return end_value
	set(val):
		end_value = val

@export var show_tick_marks: bool = true:
	set(val):
		show_tick_marks = val
		queue_redraw()

@export var show_ticks: bool:
	get:
		return show_tick_marks
	set(val):
		show_tick_marks = val

@export var show_value_bubble: bool = true:
	set(val):
		show_value_bubble = val
		queue_redraw()

var _is_dragging: bool = false
var _active_thumb: int = 0 # 0 = single, 1 = start, 2 = end
var _active_progress: float = 0.0
var _indicator_scale: float = 0.0
var _anim_tween: Tween = null
var _font: Font = null
var _font_size: int = 12

func _init() -> void:
	super._init()
	custom_minimum_size = Vector2(200.0, 44.0)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_update_font()
	_validate_values()

func _animate_active_state(active: bool) -> void:
	var target: float = 1.0 if active else 0.0
	if not is_inside_tree():
		_active_progress = target
		_indicator_scale = target
		return
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween()
	if _anim_tween:
		_anim_tween.bind_node(self)
		_anim_tween.set_parallel(true)
		_anim_tween.set_trans(Tween.TRANS_CUBIC)
		_anim_tween.set_ease(Tween.EASE_OUT)
		_anim_tween.tween_property(self, ^"_active_progress", target, 0.15)
		_anim_tween.tween_property(self, ^"_indicator_scale", target, 0.15)
		_anim_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.15)
	queue_redraw()

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = 12

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()

func _snap_and_clamp(val: float) -> float:
	var v: float = clampf(val, min_value, max_value)
	if step > 0.0:
		var steps: float = roundf((v - min_value) / step)
		v = min_value + steps * step
		v = clampf(v, min_value, max_value)
	return v

func _validate_values() -> void:
	value = _snap_and_clamp(value)
	start_value = _snap_and_clamp(start_value)
	end_value = _snap_and_clamp(end_value)
	if start_value > end_value:
		start_value = end_value

func _get_track_thickness() -> float:
	match slider_size:
		SliderSize.SMALL:
			return 16.0
		SliderSize.MEDIUM:
			return 24.0
		SliderSize.LARGE:
			return 40.0
		SliderSize.EXTRA_LARGE:
			return 56.0
		_:
			return 4.0

func _get_track_corner_radius() -> int:
	match slider_size:
		SliderSize.SMALL:
			return 8
		SliderSize.MEDIUM:
			return 12
		SliderSize.LARGE:
			return 16
		SliderSize.EXTRA_LARGE:
			return 16
		_:
			return 2

func _update_slider_min_size() -> void:
	var thick: float = _get_track_thickness()
	var cross_min: float = maxf(44.0, thick + 16.0)
	if orientation == Orientation.VERTICAL:
		var was_horiz_default: bool = (size == Vector2(200.0, 44.0) or size.y <= 64.0)
		custom_minimum_size = Vector2(cross_min, 200.0)
		if was_horiz_default:
			size = custom_minimum_size
		else:
			size = Vector2(maxf(size.x, cross_min), maxf(size.y, 200.0))
	else:
		var was_vert_default: bool = (size == Vector2(44.0, 200.0) or size.x <= 64.0)
		custom_minimum_size = Vector2(200.0, cross_min)
		if was_vert_default:
			size = custom_minimum_size
		else:
			size = Vector2(maxf(size.x, 200.0), maxf(size.y, cross_min))
	update_minimum_size()

func _get_track_rect() -> Rect2:
	var thick: float = _get_track_thickness()
	if orientation == Orientation.VERTICAL:
		var pad_y: float = 12.0
		var track_x: float = (size.x - thick) * 0.5
		return Rect2(track_x, pad_y, thick, maxf(1.0, size.y - pad_y * 2.0))
	var pad_x: float = 12.0
	var track_y: float = (size.y - thick) * 0.5
	return Rect2(pad_x, track_y, maxf(1.0, size.x - pad_x * 2.0), thick)

func _val_to_x(val: float) -> float:
	var tr := _get_track_rect()
	var pct: float = (val - min_value) / maxf(0.001, max_value - min_value)
	return tr.position.x + tr.size.x * pct

func _x_to_val(x: float) -> float:
	var tr := _get_track_rect()
	var pct: float = clampf((x - tr.position.x) / maxf(1.0, tr.size.x), 0.0, 1.0)
	return min_value + pct * (max_value - min_value)

func _val_to_y(val: float) -> float:
	var tr := _get_track_rect()
	var pct: float = (val - min_value) / maxf(0.001, max_value - min_value)
	return tr.end.y - tr.size.y * pct

func _y_to_val(y: float) -> float:
	var tr := _get_track_rect()
	var pct: float = clampf((tr.end.y - y) / maxf(1.0, tr.size.y), 0.0, 1.0)
	return min_value + pct * (max_value - min_value)

func _pos_to_val(pos: Vector2) -> float:
	if orientation == Orientation.VERTICAL:
		return _y_to_val(pos.y)
	return _x_to_val(pos.x)

func _val_to_pos(val: float) -> Vector2:
	var tr := _get_track_rect()
	if orientation == Orientation.VERTICAL:
		return Vector2(tr.get_center().x, _val_to_y(val))
	return Vector2(_val_to_x(val), tr.get_center().y)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_animate_active_state(true)
				var click_val := _pos_to_val(mb.position)
				if slider_type == SliderType.RANGE:
					var dist_start := absf(click_val - start_value)
					var dist_end := absf(click_val - end_value)
					if dist_start <= dist_end:
						_active_thumb = 1
						start_value = click_val
					else:
						_active_thumb = 2
						end_value = click_val
				else:
					_active_thumb = 0
					value = click_val
				accept_event()
			else:
				if _is_dragging:
					_is_dragging = false
					_active_thumb = 0
					_animate_active_state(false)
					accept_event()

	elif event is InputEventMouseMotion:
		if _is_dragging:
			var cur_val := _pos_to_val((event as InputEventMouseMotion).position)
			if slider_type == SliderType.RANGE:
				if _active_thumb == 1:
					start_value = cur_val
				elif _active_thumb == 2:
					end_value = cur_val
			else:
				value = cur_val
			accept_event()

	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed:
			var delta: float = step if step > 0.0 else (max_value - min_value) * 0.05
			if k.keycode == KEY_LEFT or k.keycode == KEY_DOWN:
				if slider_type == SliderType.RANGE:
					start_value -= delta
				else:
					value -= delta
				accept_event()
			elif k.keycode == KEY_RIGHT or k.keycode == KEY_UP:
				if slider_type == SliderType.RANGE:
					end_value += delta
				else:
					value += delta
				accept_event()

func _is_expressive_bar_handle() -> bool:
	return slider_size != SliderSize.EXTRA_SMALL or orientation == Orientation.VERTICAL or centered_zero

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	var tr := _get_track_rect()
	var primary_col := get_m3_color(&"primary")
	var track_inactive := get_m3_color(&"surface_container_highest")
	var on_surface_col := get_m3_color(&"on_surface")
	var on_primary_col := get_m3_color(&"on_primary")
	var surface_col := get_m3_color(&"surface")

	if disabled:
		primary_col = Color(on_surface_col, M3Color.DISABLED_CONTENT_OPACITY)
		track_inactive = Color(on_surface_col, M3Color.DISABLED_CONTAINER_OPACITY)

	var corner_rad: int = _get_track_corner_radius()

	# Draw Inactive Track
	var inactive_sb := StyleBoxFlat.new()
	inactive_sb.bg_color = track_inactive
	inactive_sb.set_corner_radius_all(corner_rad)
	draw_style_box(inactive_sb, tr)

	# Draw Active Track segment
	var active_rect: Rect2
	if orientation == Orientation.VERTICAL:
		if slider_type == SliderType.RANGE:
			var sy := _val_to_y(start_value)
			var ey := _val_to_y(end_value)
			var top_y := minf(sy, ey)
			var bot_y := maxf(sy, ey)
			active_rect = Rect2(tr.position.x, top_y, tr.size.x, maxf(1.0, bot_y - top_y))
		elif centered_zero:
			var zy := _val_to_y(clampf(0.0, min_value, max_value))
			var vy := _val_to_y(value)
			var top_y := minf(zy, vy)
			var bot_y := maxf(zy, vy)
			active_rect = Rect2(tr.position.x, top_y, tr.size.x, maxf(1.0, bot_y - top_y))
		else:
			var vy := _val_to_y(value)
			active_rect = Rect2(tr.position.x, vy, tr.size.x, maxf(1.0, tr.end.y - vy))
	else:
		if slider_type == SliderType.RANGE:
			var sx := _val_to_x(start_value)
			var ex := _val_to_x(end_value)
			active_rect = Rect2(sx, tr.position.y, maxf(1.0, ex - sx), tr.size.y)
		elif centered_zero:
			var zx := _val_to_x(clampf(0.0, min_value, max_value))
			var vx := _val_to_x(value)
			var left_x := minf(zx, vx)
			var right_x := maxf(zx, vx)
			active_rect = Rect2(left_x, tr.position.y, maxf(1.0, right_x - left_x), tr.size.y)
		else:
			var vx := _val_to_x(value)
			active_rect = Rect2(tr.position.x, tr.position.y, maxf(1.0, vx - tr.position.x), tr.size.y)

	var active_sb := StyleBoxFlat.new()
	active_sb.bg_color = primary_col
	active_sb.set_corner_radius_all(corner_rad)
	draw_style_box(active_sb, active_rect)

	# Center zero tick dot
	if centered_zero and min_value <= 0.0 and max_value >= 0.0:
		var zero_pos := _val_to_pos(0.0)
		draw_circle(zero_pos, 2.5, on_primary_col if absf(value) > 0.01 else primary_col)

	# Draw Discrete tick marks
	if (slider_type == SliderType.DISCRETE or step > 1.0) and show_tick_marks and step > 0.0:
		var num_steps := int(round((max_value - min_value) / step))
		if num_steps in range(1, 101):
			for i in range(num_steps + 1):
				var tv: float = min_value + float(i) * step
				var tpos := _val_to_pos(tv)
				var is_active: bool = (tv <= value) if not centered_zero else ((tv >= 0.0 and tv <= value) or (tv <= 0.0 and tv >= value))
				var dot_col := on_primary_col if is_active else primary_col
				draw_circle(tpos, 2.0, dot_col)

	# Draw Thumbs
	var thumb_radius: float = 10.0
	if slider_type == SliderType.RANGE:
		var p1 := _val_to_pos(start_value)
		var p2 := _val_to_pos(end_value)
		_draw_thumb(p1, thumb_radius, primary_col, _active_thumb == 1, surface_col)
		_draw_thumb(p2, thumb_radius, primary_col, _active_thumb == 2, surface_col)
		if (_is_dragging or _indicator_scale > 0.01) and show_value_bubble:
			if _active_thumb == 1:
				_draw_value_bubble(p1, start_value)
			elif _active_thumb == 2:
				_draw_value_bubble(p2, end_value)
	else:
		var p := _val_to_pos(value)
		_draw_thumb(p, thumb_radius, primary_col, _is_dragging or _active_progress > 0.01, surface_col)
		if (_is_dragging or _indicator_scale > 0.01) and show_value_bubble:
			_draw_value_bubble(p, value)

func _draw_thumb(pos: Vector2, radius: float, col: Color, is_active: bool, gap_col: Color) -> void:
	if _is_expressive_bar_handle():
		var thick: float = _get_track_thickness()
		var bar_len: float = maxf(28.0, thick + 12.0)
		var bar_thick: float = 2.5 if is_active else 4.0
		var gap_thick: float = bar_thick + 8.0
		var gap_rect: Rect2
		var bar_rect: Rect2
		if orientation == Orientation.VERTICAL:
			gap_rect = Rect2(pos.x - bar_len * 0.5 - 2.0, pos.y - gap_thick * 0.5, bar_len + 4.0, gap_thick)
			bar_rect = Rect2(pos.x - bar_len * 0.5, pos.y - bar_thick * 0.5, bar_len, bar_thick)
		else:
			gap_rect = Rect2(pos.x - gap_thick * 0.5, pos.y - bar_len * 0.5 - 2.0, gap_thick, bar_len + 4.0)
			bar_rect = Rect2(pos.x - bar_thick * 0.5, pos.y - bar_len * 0.5, bar_thick, bar_len)

		draw_rect(gap_rect, gap_col)
		var bar_sb := StyleBoxFlat.new()
		bar_sb.bg_color = col
		bar_sb.set_corner_radius_all(2)
		draw_style_box(bar_sb, bar_rect)
		return

	# Classic M3 circular thumb
	if is_active and not disabled:
		draw_circle(pos, radius * 1.8, Color(col, 0.12))

	# Drop shadow
	draw_circle(pos + Vector2(0, 1.5), radius, Color(0, 0, 0, 0.2))
	# Main thumb
	draw_circle(pos, radius, col)

func _draw_value_bubble(pos: Vector2, val: float) -> void:
	if _font == null:
		return

	var text_str: String = str(roundf(val * 100.0) / 100.0) if step != 1.0 else str(int(roundf(val)))
	var text_w := _font.get_string_size(text_str, HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size).x
	var bubble_w: float = maxf(text_w + 16.0, 32.0)
	var bubble_h: float = 26.0
	var half_handle: float = maxf(14.0, (_get_track_thickness() + 12.0) * 0.5) if _is_expressive_bar_handle() else 12.0
	var bubble_y: float = pos.y - bubble_h - half_handle - 4.0
	var bubble_rect := Rect2(pos.x - bubble_w * 0.5, bubble_y, bubble_w, bubble_h)

	var inv_surf := get_m3_color(&"inverse_surface")
	var inv_on_surf := get_m3_color(&"inverse_on_surface")

	# Bubble body
	var sb := StyleBoxFlat.new()
	sb.bg_color = inv_surf
	sb.set_corner_radius_all(13)
	draw_style_box(sb, bubble_rect)

	# Downward triangle tip
	var tip_pts := PackedVector2Array([
		Vector2(pos.x - 4.0, bubble_y + bubble_h),
		Vector2(pos.x + 4.0, bubble_y + bubble_h),
		Vector2(pos.x, bubble_y + bubble_h + 5.0)
	])
	draw_colored_polygon(tip_pts, inv_surf)

	# Label text
	var font_ascent := _font.get_ascent(_font_size)
	var ty := bubble_y + (bubble_h - _font.get_height(_font_size)) * 0.5 + font_ascent
	draw_string(_font, Vector2(bubble_rect.position.x, ty), text_str, HORIZONTAL_ALIGNMENT_CENTER, bubble_w, _font_size, inv_on_surf)
