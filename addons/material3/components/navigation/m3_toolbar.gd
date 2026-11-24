@tool
class_name M3Toolbar
extends M3Control

## Material Design 3 Expressive (2025) Toolbar.
## Supports DOCKED and FLOATING types, HORIZONTAL and VERTICAL orientations,
## STANDARD and VIBRANT color styles, interactive tool items with animated active pill,
## and optional adjacent FAB for floating toolbars.

enum ToolbarType {
	DOCKED,
	FLOATING
}

enum Orientation {
	HORIZONTAL,
	VERTICAL
}

enum ColorStyle {
	STANDARD,
	VIBRANT
}

signal item_selected(index: int)
signal fab_pressed()

@export var toolbar_type: ToolbarType = ToolbarType.FLOATING:
	set(value):
		toolbar_type = value
		_update_dimensions()
		_update_indicator_instant()
		queue_redraw()

@export var orientation: int = Orientation.HORIZONTAL:
	set(value):
		orientation = value
		_update_dimensions()
		_update_indicator_instant()
		queue_redraw()

@export var color_style: ColorStyle = ColorStyle.STANDARD:
	set(value):
		color_style = value
		queue_redraw()

@export var items: Array[Dictionary] = []:
	set(value):
		items = value
		_update_dimensions()
		_update_indicator_instant()
		queue_redraw()

@export var active_index: int = 0:
	set(value):
		if items.is_empty():
			active_index = value
			return
		var clamped: int = clampi(value, -1, items.size() - 1)
		if active_index != clamped:
			var old_idx: int = active_index
			active_index = clamped
			item_selected.emit(active_index)
			_animate_selection(old_idx, active_index)
			queue_redraw()

@export var show_fab: bool = false:
	set(value):
		show_fab = value
		_update_dimensions()
		queue_redraw()

@export var fab_icon: String = "add":
	set(value):
		fab_icon = value
		queue_redraw()

var selection_progress: float = 1.0:
	set(value):
		selection_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _indicator_pos: float = 12.0:
	set(value):
		_indicator_pos = value
		queue_redraw()

var _hovered_index: int = -1
var _fab_hovered: bool = false
var _tween: Tween = null

const BAR_THICKNESS := 64.0
const ITEM_STEP := 52.0
const END_PADDING := 12.0
const FAB_GAP := 8.0
const FAB_SIZE := 56.0

func _init() -> void:
	super._init()
	shape_token = M3Shapes.ShapeToken.FULL
	_update_dimensions()

func _ready() -> void:
	super._ready()
	_update_dimensions()
	_update_indicator_instant()

## Adds a tool item and returns its index.
func add_item(ic_name: String, label: String = "", toggleable: bool = true) -> int:
	var idx: int = items.size()
	items.append({
		"icon": ic_name,
		"label": label,
		"toggleable": toggleable
	})
	_update_dimensions()
	if items.size() == 1 or _tween == null or not _tween.is_running():
		_update_indicator_instant()
	queue_redraw()
	return idx

func clear_items() -> void:
	items.clear()
	active_index = -1
	_update_dimensions()
	queue_redraw()

func get_item_count() -> int:
	return items.size()

func _get_pill_length() -> float:
	var count: int = maxi(1, items.size())
	var content_len: float = END_PADDING * 2.0 + float(count) * ITEM_STEP
	if toolbar_type == ToolbarType.DOCKED and orientation == Orientation.HORIZONTAL:
		return maxf(maxf(size.x, custom_minimum_size.x), 320.0)
	return maxf(content_len, 128.0)

func _update_dimensions() -> void:
	if toolbar_type == ToolbarType.DOCKED:
		shape_token = M3Shapes.ShapeToken.NONE
		size_flags_horizontal = SIZE_EXPAND_FILL
		custom_minimum_size = Vector2(320.0, BAR_THICKNESS)
	else:
		shape_token = M3Shapes.ShapeToken.FULL
		size_flags_horizontal = SIZE_SHRINK_BEGIN
		var pill_len: float = END_PADDING * 2.0 + float(maxi(1, items.size())) * ITEM_STEP
		var extra_fab: float = (FAB_GAP + FAB_SIZE) if show_fab else 0.0
		if orientation == Orientation.HORIZONTAL:
			custom_minimum_size = Vector2(maxf(128.0, pill_len) + extra_fab, BAR_THICKNESS)
		else:
			custom_minimum_size = Vector2(BAR_THICKNESS, maxf(128.0, pill_len) + extra_fab)
		size = custom_minimum_size
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
	update_minimum_size()

func get_item_rect(index: int) -> Rect2:
	if index < 0 or index >= items.size():
		return Rect2()
	var count: int = items.size()
	if toolbar_type == ToolbarType.DOCKED and orientation == Orientation.HORIZONTAL:
		var slot_w: float = maxf(size.x, custom_minimum_size.x) / float(maxi(1, count))
		var cx: float = (float(index) + 0.5) * slot_w
		return Rect2(Vector2(cx - 24.0, (BAR_THICKNESS - 40.0) * 0.5), Vector2(48.0, 40.0))
	if orientation == Orientation.HORIZONTAL:
		var x: float = END_PADDING + float(index) * ITEM_STEP + (ITEM_STEP - 48.0) * 0.5
		return Rect2(Vector2(x, (BAR_THICKNESS - 40.0) * 0.5), Vector2(48.0, 40.0))
	else:
		var y: float = END_PADDING + float(index) * ITEM_STEP + (ITEM_STEP - 40.0) * 0.5
		return Rect2(Vector2((BAR_THICKNESS - 48.0) * 0.5, y), Vector2(48.0, 40.0))

func get_item_center(index: int) -> Vector2:
	return get_item_rect(index).get_center()

func get_fab_rect() -> Rect2:
	if not show_fab or toolbar_type != ToolbarType.FLOATING:
		return Rect2()
	var pill_len: float = END_PADDING * 2.0 + float(maxi(1, items.size())) * ITEM_STEP
	if orientation == Orientation.HORIZONTAL:
		return Rect2(Vector2(pill_len + FAB_GAP, (BAR_THICKNESS - FAB_SIZE) * 0.5), Vector2(FAB_SIZE, FAB_SIZE))
	else:
		return Rect2(Vector2((BAR_THICKNESS - FAB_SIZE) * 0.5, pill_len + FAB_GAP), Vector2(FAB_SIZE, FAB_SIZE))

func _get_target_indicator_pos(index: int) -> float:
	var r: Rect2 = get_item_rect(index)
	return r.position.x if orientation == Orientation.HORIZONTAL else r.position.y

func _update_indicator_instant() -> void:
	if active_index >= 0 and active_index < items.size():
		_indicator_pos = _get_target_indicator_pos(active_index)
		selection_progress = 1.0

func _animate_selection(old_idx: int, new_idx: int) -> void:
	if new_idx < 0 or new_idx >= items.size():
		return
	var start_pos: float = _get_target_indicator_pos(old_idx) if (old_idx >= 0 and old_idx < items.size()) else _indicator_pos
	var target_pos: float = _get_target_indicator_pos(new_idx)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not is_inside_tree():
		_indicator_pos = target_pos
		selection_progress = 1.0
		return
	_indicator_pos = start_pos
	selection_progress = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"_indicator_pos", target_pos, 0.24)
	_tween.tween_property(self, ^"selection_progress", 1.0, 0.24)

func _on_resized() -> void:
	super._on_resized()
	if _tween == null or not _tween.is_running():
		_update_indicator_instant()

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var new_hov: int = -1
		for i in range(items.size()):
			if get_item_rect(i).grow(2.0).has_point(mm.position):
				new_hov = i
				break
		var fab_r: Rect2 = get_fab_rect()
		var new_fab_hov: bool = fab_r.size.x > 0.0 and fab_r.has_point(mm.position)
		if new_hov != _hovered_index or new_fab_hov != _fab_hovered:
			_hovered_index = new_hov
			_fab_hovered = new_fab_hov
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var fab_r: Rect2 = get_fab_rect()
			if fab_r.size.x > 0.0 and fab_r.has_point(mb.position):
				fab_pressed.emit()
				accept_event()
				return
			for i in range(items.size()):
				if get_item_rect(i).grow(4.0).has_point(mb.position):
					if active_index == i:
						item_selected.emit(i)
					else:
						active_index = i
					accept_event()
					return
	super._gui_input(event)

func get_container_color() -> Color:
	if color_style == ColorStyle.VIBRANT:
		return get_m3_color(&"primary_container")
	if toolbar_type == ToolbarType.FLOATING:
		return get_m3_color(&"surface_container_high")
	return get_m3_color(&"surface_container")

func get_active_pill_color() -> Color:
	if color_style == ColorStyle.VIBRANT:
		return get_m3_color(&"primary")
	return get_m3_color(&"secondary_container")

func _get_item_color(is_selected: bool) -> Color:
	if color_style == ColorStyle.VIBRANT:
		return get_m3_color(&"on_primary") if is_selected else get_m3_color(&"on_primary_container")
	return get_m3_color(&"on_secondary_container") if is_selected else get_m3_color(&"on_surface_variant")

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	if _tween == null or not _tween.is_running():
		if active_index >= 0 and active_index < items.size():
			_indicator_pos = _get_target_indicator_pos(active_index)

	var bar_rect: Rect2
	if toolbar_type == ToolbarType.DOCKED:
		bar_rect = Rect2(Vector2.ZERO, size)
	else:
		var pill_len: float = END_PADDING * 2.0 + float(maxi(1, items.size())) * ITEM_STEP
		if orientation == Orientation.HORIZONTAL:
			bar_rect = Rect2(Vector2.ZERO, Vector2(maxf(128.0, pill_len), BAR_THICKNESS))
		else:
			bar_rect = Rect2(Vector2.ZERO, Vector2(BAR_THICKNESS, maxf(128.0, pill_len)))

	var radius: int = 32 if toolbar_type == ToolbarType.FLOATING else 0

	# Floating shadow
	if toolbar_type == ToolbarType.FLOATING:
		var sh_sb := StyleBoxFlat.new()
		sh_sb.bg_color = Color.TRANSPARENT
		sh_sb.set_corner_radius_all(radius)
		sh_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
		sh_sb.shadow_size = 8
		sh_sb.shadow_offset = Vector2(0.0, 3.0)
		draw_style_box(sh_sb, bar_rect)

	# Toolbar background
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = get_container_color()
	bg_sb.set_corner_radius_all(radius)
	draw_style_box(bg_sb, bar_rect)

	# Active pill indicator
	if active_index >= 0 and active_index < items.size():
		var pill_rect: Rect2
		if orientation == Orientation.HORIZONTAL:
			pill_rect = Rect2(Vector2(_indicator_pos, (BAR_THICKNESS - 40.0) * 0.5), Vector2(48.0, 40.0))
		else:
			pill_rect = Rect2(Vector2((BAR_THICKNESS - 48.0) * 0.5, _indicator_pos), Vector2(48.0, 40.0))
		var pill_sb := StyleBoxFlat.new()
		pill_sb.bg_color = get_active_pill_color()
		pill_sb.set_corner_radius_all(20)
		draw_style_box(pill_sb, pill_rect)

	# Draw items
	for i in range(items.size()):
		var item_r: Rect2 = get_item_rect(i)
		var is_sel: bool = (i == active_index)
		if _hovered_index == i and not is_sel:
			var hov_sb := StyleBoxFlat.new()
			hov_sb.bg_color = Color(_get_item_color(false), 0.08)
			hov_sb.set_corner_radius_all(20)
			draw_style_box(hov_sb, item_r)
		var ic_col: Color = _get_item_color(is_sel)
		var ic_name: String = str(items[i].get("icon", ""))
		_draw_tool_glyph(ic_name, item_r.get_center(), ic_col)

	# Optional adjacent FAB for floating toolbar
	var fab_r: Rect2 = get_fab_rect()
	if fab_r.size.x > 0.0:
		var fab_sh := StyleBoxFlat.new()
		fab_sh.bg_color = Color.TRANSPARENT
		fab_sh.set_corner_radius_all(16)
		fab_sh.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
		fab_sh.shadow_size = 8
		fab_sh.shadow_offset = Vector2(0.0, 3.0)
		draw_style_box(fab_sh, fab_r)

		var fab_sb := StyleBoxFlat.new()
		fab_sb.bg_color = get_m3_color(&"tertiary_container") if color_style == ColorStyle.VIBRANT else get_m3_color(&"primary_container")
		fab_sb.set_corner_radius_all(16)
		draw_style_box(fab_sb, fab_r)
		var fab_fg: Color = get_m3_color(&"on_tertiary_container") if color_style == ColorStyle.VIBRANT else get_m3_color(&"on_primary_container")
		_draw_tool_glyph(fab_icon, fab_r.get_center(), fab_fg)

func _draw_tool_glyph(ic_name: String, center: Vector2, col: Color) -> void:
	var key: String = ic_name.to_lower().replace("-", "_")
	var sw: float = 2.0
	match key:
		"add", "plus":
			draw_line(center + Vector2(0, -7), center + Vector2(0, 7), col, sw, true)
			draw_line(center + Vector2(-7, 0), center + Vector2(7, 0), col, sw, true)
		"edit", "pencil":
			draw_polyline(PackedVector2Array([
				center + Vector2(-6, 6), center + Vector2(-2, 5),
				center + Vector2(6, -3), center + Vector2(3, -6),
				center + Vector2(-5, 2), center + Vector2(-6, 6)
			]), col, sw, true)
		"share":
			draw_circle(center + Vector2(5, -6), 2.2, col)
			draw_circle(center + Vector2(-5, 0), 2.2, col)
			draw_circle(center + Vector2(5, 6), 2.2, col)
			draw_line(center + Vector2(-5, 0), center + Vector2(5, -6), col, sw, true)
			draw_line(center + Vector2(-5, 0), center + Vector2(5, 6), col, sw, true)
		"bookmark":
			draw_polyline(PackedVector2Array([
				center + Vector2(-5, -7), center + Vector2(5, -7),
				center + Vector2(5, 7), center + Vector2(0, 3),
				center + Vector2(-5, 7), center + Vector2(-5, -7)
			]), col, sw, true)
		"favorite", "heart":
			draw_circle(center + Vector2(-3, -2), 3.5, col)
			draw_circle(center + Vector2(3, -2), 3.5, col)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-6.2, -1), center + Vector2(6.2, -1), center + Vector2(0, 6.5)
			]), col)
		"search":
			draw_arc(center + Vector2(-1.5, -1.5), 5.0, 0.0, TAU, 20, col, sw, true)
			draw_line(center + Vector2(2.2, 2.2), center + Vector2(7.0, 7.0), col, sw, true)
		"tune", "filter":
			draw_line(center + Vector2(-7, -5), center + Vector2(7, -5), col, sw, true)
			draw_line(center + Vector2(-5, 0), center + Vector2(5, 0), col, sw, true)
			draw_line(center + Vector2(-3, 5), center + Vector2(3, 5), col, sw, true)
		"delete", "trash":
			draw_line(center + Vector2(-7, -5), center + Vector2(7, -5), col, sw, true)
			draw_polyline(PackedVector2Array([
				center + Vector2(-5, -5), center + Vector2(-4, 7),
				center + Vector2(4, 7), center + Vector2(5, -5)
			]), col, sw, true)
		"undo":
			draw_arc(center + Vector2(1, 2), 5.5, -PI * 0.5, PI * 0.75, 16, col, sw, true)
			draw_polyline(PackedVector2Array([
				center + Vector2(-3, -6), center + Vector2(-6, -3), center + Vector2(-2, -1)
			]), col, sw, true)
		_:
			draw_circle(center, 4.5, col)
