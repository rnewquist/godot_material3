@tool
class_name M3Carousel
extends M3Control

## Material 3 Carousel component (https://m3.material.io/components/carousel/overview).
## Supports Multi-browse, Uncontained, Hero, and Full-screen layouts with dynamic item squishing,
## 28dp rounded corners, mouse drag scrolling, click-to-focus tweening, and scroll_to_index().

signal item_selected(index: int)
signal scroll_changed(offset: float)

enum CarouselStyle {
	MULTI_BROWSE,
	UNCONTAINED,
	HERO,
	FULL_SCREEN
}

@export var carousel_style: CarouselStyle = CarouselStyle.MULTI_BROWSE:
	set(value):
		carousel_style = value
		_layout_items()
		queue_redraw()

@export var style: CarouselStyle:
	get:
		return carousel_style
	set(value):
		carousel_style = value

@export var corner_radius: float = 28.0:
	set(value):
		corner_radius = maxf(0.0, value)
		custom_corner_radius = corner_radius
		queue_redraw()

@export var item_spacing: float = 8.0:
	set(value):
		item_spacing = maxf(0.0, value)
		_layout_items()
		queue_redraw()

@export var large_item_width: float = 280.0:
	set(value):
		large_item_width = maxf(120.0, value)
		_layout_items()
		queue_redraw()

@export var medium_item_width: float = 140.0:
	set(value):
		medium_item_width = maxf(72.0, value)
		_layout_items()
		queue_redraw()

@export var small_item_width: float = 56.0:
	set(value):
		small_item_width = maxf(40.0, value)
		_layout_items()
		queue_redraw()

@export var uncontained_item_width: float = 220.0:
	set(value):
		uncontained_item_width = maxf(80.0, value)
		_layout_items()
		queue_redraw()

@export var active_index: int = 0:
	set(value):
		var count: int = get_item_count()
		var clamped: int = clampi(value, 0, maxi(0, count - 1))
		if active_index != clamped:
			active_index = clamped
			if not _is_dragging and (_scroll_tween == null or not _scroll_tween.is_running()):
				scroll_offset = float(active_index) * _get_scroll_step()
			_layout_items()
			queue_redraw()

@export var scroll_offset: float = 0.0:
	set(value):
		var clamped: float = clampf(value, 0.0, _get_max_scroll())
		if not is_equal_approx(scroll_offset, clamped):
			scroll_offset = clamped
			_focal_position = scroll_offset / maxf(1.0, _get_scroll_step())
			_layout_items()
			scroll_changed.emit(scroll_offset)
			queue_redraw()
		else:
			scroll_offset = clamped
			_focal_position = scroll_offset / maxf(1.0, _get_scroll_step())
			_layout_items()
			queue_redraw()

var items: Array[Dictionary] = []
var _item_widths: Array[float] = []
var _item_rects: Array[Rect2] = []
var _focal_position: float = 0.0
var _scroll_tween: Tween = null
var _is_dragging: bool = false
var _pointer_down_carousel: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_offset: float = 0.0
var _hovered_item_index: int = -1

func _init() -> void:
	super._init()
	clip_contents = true
	shape_token = M3Shapes.ShapeToken.EXTRA_LARGE
	custom_corner_radius = corner_radius
	custom_minimum_size = Vector2(360.0, 200.0)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	clip_contents = true
	if items.is_empty() and _get_child_controls().is_empty():
		_populate_default_items()
	_layout_items()
	queue_redraw()

func _populate_default_items() -> void:
	add_item("Alpine Peaks", "Mountain expedition", Color.TRANSPARENT)
	add_item("Coastal Breeze", "Pacific shoreline", Color.TRANSPARENT)
	add_item("Desert Dunes", "Golden hour horizon", Color.TRANSPARENT)
	add_item("Forest Canopy", "Redwood trail", Color.TRANSPARENT)
	add_item("Northern Lights", "Arctic aurora", Color.TRANSPARENT)

func _on_resized() -> void:
	super._on_resized()
	_layout_items()
	queue_redraw()

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_layout_items()
	queue_redraw()

## Adds a data item to the carousel and returns its index.
func add_item(title: String, subtitle: String = "", accent_color: Color = Color.TRANSPARENT) -> int:
	items.append({
		"title": title,
		"subtitle": subtitle,
		"accent_color": accent_color
	})
	_layout_items()
	queue_redraw()
	return items.size() - 1

## Clears all items from the carousel.
func clear_items() -> void:
	items.clear()
	active_index = 0
	scroll_offset = 0.0
	_layout_items()
	queue_redraw()

func _get_child_controls() -> Array[Control]:
	var out: Array[Control] = []
	for c in get_children():
		if c is Control and c != _ripple and c.name != "M3Ripple":
			out.append(c as Control)
	return out

func get_item_count() -> int:
	var child_ctrls := _get_child_controls()
	if not child_ctrls.is_empty():
		return child_ctrls.size()
	return items.size()

func get_item_width(idx: int) -> float:
	if idx >= 0 and idx < _item_widths.size():
		return _item_widths[idx]
	return 0.0

func get_item_rect(idx: int) -> Rect2:
	if idx >= 0 and idx < _item_rects.size():
		return _item_rects[idx]
	return Rect2()

func _get_scroll_step() -> float:
	match carousel_style:
		CarouselStyle.UNCONTAINED:
			return uncontained_item_width + item_spacing
		CarouselStyle.FULL_SCREEN:
			return maxf(200.0, size.x) + item_spacing
		CarouselStyle.HERO:
			return 200.0
		CarouselStyle.MULTI_BROWSE:
			return 160.0
	return 160.0

func _get_max_scroll() -> float:
	var count: int = get_item_count()
	if count <= 1:
		return 0.0
	return float(count - 1) * _get_scroll_step()

## Scrolls to the item at `idx`, optionally animating `scroll_offset` via Tween.
func scroll_to_index(idx: int, animated: bool = true) -> void:
	var count: int = get_item_count()
	if count <= 0:
		return
	var target_idx: int = clampi(idx, 0, count - 1)
	active_index = target_idx
	var target_offset: float = float(target_idx) * _get_scroll_step()

	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()

	if animated and is_inside_tree() and not is_equal_approx(scroll_offset, target_offset):
		_scroll_tween = create_tween()
		_scroll_tween.bind_node(self)
		_scroll_tween.set_trans(Tween.TRANS_CUBIC)
		_scroll_tween.set_ease(Tween.EASE_OUT)
		_scroll_tween.tween_property(self, ^"scroll_offset", target_offset, 0.28)
	else:
		scroll_offset = target_offset
		_layout_items()
		queue_redraw()

func _compute_dynamic_width(index: int, focal: float) -> float:
	var dist: float = absf(float(index) - focal)
	match carousel_style:
		CarouselStyle.MULTI_BROWSE:
			if dist <= 1.0:
				return lerpf(large_item_width, medium_item_width, dist)
			elif dist <= 2.0:
				return lerpf(medium_item_width, small_item_width, dist - 1.0)
			else:
				return small_item_width
		CarouselStyle.HERO:
			var hero_w: float = clampf(size.x - small_item_width - item_spacing, 260.0, 320.0)
			if dist <= 1.0:
				return lerpf(hero_w, small_item_width, dist)
			else:
				return small_item_width
		CarouselStyle.UNCONTAINED:
			return uncontained_item_width
		CarouselStyle.FULL_SCREEN:
			return maxf(260.0, size.x)
	return large_item_width

func _layout_items() -> void:
	var count: int = get_item_count()
	_item_widths.clear()
	_item_rects.clear()
	if count <= 0:
		return

	var step: float = maxf(1.0, _get_scroll_step())
	var focal: float = clampf(scroll_offset / step, 0.0, float(maxi(0, count - 1)))
	_focal_position = focal
	var h: float = maxf(60.0, size.y)

	for i in range(count):
		_item_widths.append(_compute_dynamic_width(i, focal))

	if carousel_style == CarouselStyle.UNCONTAINED or carousel_style == CarouselStyle.FULL_SCREEN:
		var x_pos: float = -scroll_offset
		for i in range(count):
			var w: float = _item_widths[i]
			_item_rects.append(Rect2(x_pos, 0.0, w, h))
			x_pos += w + item_spacing
	else:
		# Dynamic squishing layout: position items so the focal item stays prominently in view.
		var raw_positions: Array[float] = []
		var accum_x: float = 0.0
		for i in range(count):
			raw_positions.append(accum_x)
			accum_x += _item_widths[i] + item_spacing
		var total_w: float = maxf(0.0, accum_x - item_spacing)

		# Smooth camera shift keeps the focal item near the leading edge while clamping to bounds.
		var focal_low: int = clampi(int(floor(focal)), 0, count - 1)
		var focal_high: int = clampi(focal_low + 1, 0, count - 1)
		var frac: float = focal - float(focal_low)
		var focal_x: float = lerpf(raw_positions[focal_low], raw_positions[focal_high], frac)
		var max_shift: float = maxf(0.0, total_w - size.x)
		var lead_margin: float = 0.0 if focal < 1.0 else (small_item_width + item_spacing) * clampf(focal, 0.0, 1.0)
		var shift_x: float = clampf(focal_x - lead_margin, 0.0, max_shift)

		for i in range(count):
			var w: float = _item_widths[i]
			_item_rects.append(Rect2(raw_positions[i] - shift_x, 0.0, w, h))

	# Sync child controls if present
	var child_ctrls := _get_child_controls()
	for i in range(mini(child_ctrls.size(), _item_rects.size())):
		var c := child_ctrls[i]
		var r := _item_rects[i]
		c.position = r.position
		c.size = r.size
		c.clip_contents = true

func _item_at_point(local_pos: Vector2) -> int:
	for i in range(_item_rects.size()):
		if _item_rects[i].has_point(local_pos):
			return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pointer_down_carousel = true
				_is_dragging = false
				_drag_start_pos = mb.position
				_drag_start_offset = scroll_offset
				_set_state(ControlState.PRESSED)
				if _scroll_tween != null and _scroll_tween.is_valid():
					_scroll_tween.kill()
				if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("start_press"):
					_ripple.call("start_press", mb.position)
				accept_event()
			else:
				if _pointer_down_carousel:
					_pointer_down_carousel = false
					if _ripple != null and is_instance_valid(_ripple) and _ripple.has_method("end_press"):
						_ripple.call("end_press")
					if _is_dragging:
						_is_dragging = false
						var snap_idx: int = clampi(int(round(scroll_offset / maxf(1.0, _get_scroll_step()))), 0, maxi(0, get_item_count() - 1))
						scroll_to_index(snap_idx, true)
						item_selected.emit(snap_idx)
					else:
						var hit_idx: int = _item_at_point(mb.position)
						if hit_idx >= 0:
							scroll_to_index(hit_idx, true)
							item_selected.emit(hit_idx)
					_set_state(ControlState.HOVERED if _pointer_inside else ControlState.NORMAL)
					accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			scroll_to_index(mini(get_item_count() - 1, active_index + 1), true)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			scroll_to_index(maxi(0, active_index - 1), true)
			accept_event()

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _pointer_down_carousel:
			var dx: float = mm.position.x - _drag_start_pos.x
			if absf(dx) > 4.0:
				_is_dragging = true
			if _is_dragging:
				scroll_offset = clampf(_drag_start_offset - dx, 0.0, _get_max_scroll())
				var nearest: int = clampi(int(round(scroll_offset / maxf(1.0, _get_scroll_step()))), 0, maxi(0, get_item_count() - 1))
				if active_index != nearest:
					active_index = nearest
				accept_event()
		else:
			var new_hover: int = _item_at_point(mm.position)
			if new_hover != _hovered_item_index:
				_hovered_item_index = new_hover
				queue_redraw()

func _get_item_palette_color(idx: int) -> Color:
	if idx >= 0 and idx < items.size():
		var c: Color = items[idx].get("accent_color", Color.TRANSPARENT)
		if c.a > 0.0:
			return c
	var tokens: Array[StringName] = [
		&"primary_container",
		&"secondary_container",
		&"tertiary_container",
		&"surface_container_highest",
		&"surface_container_high"
	]
	return get_m3_color(tokens[idx % tokens.size()])

func _get_item_content_color(idx: int) -> Color:
	var tokens: Array[StringName] = [
		&"on_primary_container",
		&"on_secondary_container",
		&"on_tertiary_container",
		&"on_surface",
		&"on_surface"
	]
	return get_m3_color(tokens[idx % tokens.size()])

func _draw() -> void:
	if _item_rects.size() != get_item_count():
		_layout_items()

	var child_ctrls := _get_child_controls()
	if not child_ctrls.is_empty():
		return

	var font: Font = ThemeDB.fallback_font
	var rad: int = int(corner_radius)
	var on_surf := get_m3_color(&"on_surface")

	for i in range(_item_rects.size()):
		var r: Rect2 = _item_rects[i]
		if r.end.x < 0.0 or r.position.x > size.x or r.size.x <= 2.0:
			continue

		var bg_col: Color = _get_item_palette_color(i)
		var fg_col: Color = _get_item_content_color(i)

		var sb := StyleBoxFlat.new()
		sb.bg_color = bg_col
		var eff_r: int = mini(rad, int(minf(r.size.x, r.size.y) * 0.5))
		sb.set_corner_radius_all(eff_r)
		if i == active_index:
			sb.border_color = get_m3_color(&"primary")
			sb.set_border_width_all(2)
		draw_style_box(sb, r)

		# State layer on hovered item
		if i == _hovered_item_index and not disabled:
			var hov_sb := StyleBoxFlat.new()
			hov_sb.bg_color = Color(on_surf.r, on_surf.g, on_surf.b, 0.08)
			hov_sb.set_corner_radius_all(eff_r)
			draw_style_box(hov_sb, r)

		# Decorative visual circle badge inside item
		if r.size.x >= 52.0:
			var badge_r: float = minf(20.0, r.size.x * 0.22)
			var badge_pos := Vector2(r.position.x + minf(28.0, r.size.x * 0.5), r.position.y + 28.0)
			var accent := Color(fg_col.r, fg_col.g, fg_col.b, 0.16)
			draw_circle(badge_pos, badge_r, accent)

		# Clipped text labels for sufficiently wide items
		if font != null and i < items.size() and r.size.x >= 84.0:
			var item_data: Dictionary = items[i]
			var title_str: String = str(item_data.get("title", ""))
			var sub_str: String = str(item_data.get("subtitle", ""))
			var avail_w: int = maxi(16, int(r.size.x - 32.0))

			if not title_str.is_empty():
				var ty: float = r.end.y - (38.0 if (not sub_str.is_empty() and r.size.x >= 160.0) else 20.0)
				draw_string(font, Vector2(r.position.x + 16.0, ty), title_str, HORIZONTAL_ALIGNMENT_LEFT, avail_w, 16, fg_col)

			if not sub_str.is_empty() and r.size.x >= 160.0:
				var sub_col := Color(fg_col.r, fg_col.g, fg_col.b, 0.78)
				draw_string(font, Vector2(r.position.x + 16.0, r.end.y - 18.0), sub_str, HORIZONTAL_ALIGNMENT_LEFT, avail_w, 12, sub_col)
