@tool
class_name M3SplitButton
extends M3Control

## Material 3 Expressive Split Button component (https://m3.material.io/components/split-button/overview).
## Composed of a leading primary action segment and a trailing menu trigger segment with chevron rotation
## and an attached popup menu container.

enum VariantType {
	FILLED,
	TONAL,
	ELEVATED,
	OUTLINED
}

enum Variant {
	FILLED,
	TONAL,
	ELEVATED,
	OUTLINED
}

const BAR_HEIGHT: float = 40.0
const TRAILING_WIDTH: float = 40.0

signal primary_pressed()
signal pressed()
signal menu_toggled(is_open: bool)
signal item_selected(index: int)

@export var variant: VariantType = VariantType.FILLED:
	set(value):
		variant = value
		_update_elevation_and_colors()
		queue_redraw()

@export var text: String = "Split Action":
	set(value):
		text = value
		_update_layout()
		queue_redraw()

@export var label: String:
	get:
		return text
	set(value):
		text = value

@export var leading_icon: StringName = &"":
	set(value):
		leading_icon = value
		_update_layout()
		queue_redraw()

@export var icon_name: StringName:
	get:
		return leading_icon
	set(value):
		leading_icon = value

@export var leading_icon_texture: Texture2D = null:
	set(value):
		leading_icon_texture = value
		_update_layout()
		queue_redraw()

@export var gap: float = 2.0:
	set(value):
		gap = maxf(1.0, value)
		_update_layout()
		queue_redraw()

@export var inner_corner_radius: float = 4.0:
	set(value):
		inner_corner_radius = maxf(0.0, value)
		queue_redraw()

@export var menu_open: bool = false:
	set(value):
		var changed: bool = (menu_open != value)
		menu_open = value
		_on_menu_open_updated(value, changed)

@export var menu_items: Array[String] = []:
	set(value):
		menu_items = value
		_rebuild_popup_items()

var menu_open_progress: float = 0.0
var _menu_open_progress: float = 0.0
var chevron_rotation: float = 0.0
var selected_item_index: int = -1
var primary_press_count: int = 0
var _leading_hovered: bool = false
var _trailing_hovered: bool = false
var _pressed_segment: int = -1 # 0 = leading, 1 = trailing
var _hover_progress: float = 0.0
var _press_progress: float = 0.0
var _current_elevation: int = 0
var _font: Font = null
var _font_size: int = 14
var _menu_tween: Tween = null
var _motion_tween: Tween = null
var _popup_container: PanelContainer = null
var _popup_vbox: VBoxContainer = null

func _init() -> void:
	super._init()
	clip_contents = false
	shape_token = M3Shapes.ShapeToken.FULL
	_update_font()
	_ensure_popup()
	_update_elevation_and_colors()
	_update_layout()

func _ready() -> void:
	super._ready()
	clip_contents = false
	_update_font()
	_ensure_popup()
	_rebuild_popup_items()
	_update_elevation_and_colors()
	_update_layout()

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = 14

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()
	_update_elevation_and_colors()
	_style_popup_container()

func _ensure_popup() -> void:
	if _popup_container != null and is_instance_valid(_popup_container):
		return
	var existing := get_node_or_null(^"SplitMenuPopup") as PanelContainer
	if existing != null:
		_popup_container = existing
		_popup_vbox = _popup_container.get_node_or_null(^"PopupItems") as VBoxContainer
		return

	_popup_container = PanelContainer.new()
	_popup_container.name = "SplitMenuPopup"
	_popup_container.visible = menu_open
	_popup_container.position = Vector2(0.0, BAR_HEIGHT + 4.0)
	_popup_container.z_index = 20
	add_child(_popup_container)

	_popup_vbox = VBoxContainer.new()
	_popup_vbox.name = "PopupItems"
	_popup_vbox.add_theme_constant_override(&"separation", 2)
	_popup_container.add_child(_popup_vbox)
	_style_popup_container()

func _style_popup_container() -> void:
	if _popup_container == null or not is_instance_valid(_popup_container):
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = get_m3_color(&"surface_container")
	sb.set_corner_radius_all(12)
	sb.border_color = get_m3_color(&"outline_variant")
	sb.set_border_width_all(1)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	_popup_container.add_theme_stylebox_override(&"panel", sb)

func add_menu_item(item_label: String) -> M3Button:
	_ensure_popup()
	var next_items: Array[String] = menu_items.duplicate()
	next_items.append(item_label)
	menu_items = next_items
	var buttons := get_menu_item_buttons()
	return buttons[buttons.size() - 1] if not buttons.is_empty() else null

func clear_menu_items() -> void:
	menu_items = []
	_rebuild_popup_items()

func get_menu_item_buttons() -> Array[M3Button]:
	var result: Array[M3Button] = []
	if _popup_vbox == null or not is_instance_valid(_popup_vbox):
		return result
	for c in _popup_vbox.get_children():
		if c is M3Button:
			result.append(c as M3Button)
	return result

func get_popup_container() -> PanelContainer:
	_ensure_popup()
	return _popup_container

func _rebuild_popup_items() -> void:
	_ensure_popup()
	if _popup_vbox == null or not is_instance_valid(_popup_vbox):
		return
	for c in _popup_vbox.get_children():
		_popup_vbox.remove_child(c)
		c.queue_free()

	for i in range(menu_items.size()):
		var lbl: String = menu_items[i]
		var item_btn := M3Button.new()
		item_btn.name = "SplitMenuItem_%d" % i
		item_btn.variant = M3Button.Variant.TEXT
		item_btn.text = lbl
		item_btn.custom_corner_radius = 8.0
		var idx: int = i
		item_btn.pressed.connect(func() -> void: _on_menu_item_pressed(idx))
		_popup_vbox.add_child(item_btn)

	_style_popup_container()
	var min_s := _popup_container.get_combined_minimum_size()
	_popup_container.custom_minimum_size = Vector2(maxf(min_s.x, custom_minimum_size.x), min_s.y)
	_popup_container.size = _popup_container.custom_minimum_size

func _on_menu_item_pressed(idx: int) -> void:
	selected_item_index = idx
	item_selected.emit(idx)
	set_menu_open(false)

func set_menu_open(val: bool) -> void:
	menu_open = val

func _on_menu_open_updated(val: bool, changed: bool) -> void:
	_ensure_popup()
	var target: float = 1.0 if val else 0.0
	if val and _popup_container != null:
		_popup_container.visible = true
		var min_s := _popup_container.get_combined_minimum_size()
		_popup_container.size = Vector2(maxf(min_s.x, size.x), maxf(min_s.y, 40.0))

	if not is_inside_tree():
		_apply_menu_progress(target)
		if _popup_container != null:
			_popup_container.visible = val
		if changed:
			menu_toggled.emit(menu_open)
		return

	if _menu_tween != null and _menu_tween.is_valid():
		_menu_tween.kill()

	_menu_tween = create_tween()
	if _menu_tween:
		_menu_tween.bind_node(self)
		_menu_tween.set_trans(Tween.TRANS_CUBIC)
		_menu_tween.set_ease(Tween.EASE_OUT)
		_menu_tween.tween_method(_apply_menu_progress, menu_open_progress, target, 0.2)
		if not val:
			_menu_tween.tween_callback(func() -> void:
				if not menu_open and _popup_container != null:
					_popup_container.visible = false
			)
	else:
		_apply_menu_progress(target)
		if not val and _popup_container != null:
			_popup_container.visible = false

	if changed:
		menu_toggled.emit(menu_open)

func toggle_menu() -> void:
	set_menu_open(not menu_open)

func press_primary() -> void:
	primary_press_count += 1
	primary_pressed.emit()
	pressed.emit()

func _apply_menu_progress(p: float) -> void:
	menu_open_progress = p
	_menu_open_progress = p
	chevron_rotation = p * PI
	if _popup_container != null and is_instance_valid(_popup_container):
		_popup_container.modulate.a = clampf(p, 0.0, 1.0)
		_popup_container.position = Vector2(0.0, lerpf(BAR_HEIGHT - 2.0, BAR_HEIGHT + 4.0, p))
	queue_redraw()

func get_leading_rect() -> Rect2:
	var w: float = maxf(48.0, size.x - gap - TRAILING_WIDTH)
	return Rect2(0.0, 0.0, w, BAR_HEIGHT)

func get_trailing_rect() -> Rect2:
	return Rect2(size.x - TRAILING_WIDTH, 0.0, TRAILING_WIDTH, BAR_HEIGHT)

func get_leading_local_center() -> Vector2:
	return get_leading_rect().get_center()

func get_trailing_local_center() -> Vector2:
	return get_trailing_rect().get_center()

func _update_elevation_and_colors() -> void:
	match variant:
		VariantType.ELEVATED:
			_current_elevation = 2 if (current_state == ControlState.HOVERED) else (0 if disabled else 1)
		VariantType.FILLED, VariantType.TONAL:
			_current_elevation = 1 if (current_state == ControlState.HOVERED and not disabled) else 0
		_:
			_current_elevation = 0
	if _ripple != null and is_instance_valid(_ripple):
		_ripple.set("ripple_color", _get_content_color())

func _on_state_updated(old_state: ControlState, new_state: ControlState) -> void:
	super._on_state_updated(old_state, new_state)
	_update_elevation_and_colors()
	var target_hover: float = 1.0 if (new_state == ControlState.HOVERED or new_state == ControlState.PRESSED) else 0.0
	var target_press: float = 1.0 if new_state == ControlState.PRESSED else 0.0
	if not is_inside_tree():
		_hover_progress = target_hover
		_press_progress = target_press
		return
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween()
	if _motion_tween:
		_motion_tween.bind_node(self)
		_motion_tween.set_parallel(true)
		_motion_tween.set_trans(Tween.TRANS_CUBIC)
		_motion_tween.set_ease(Tween.EASE_OUT)
		_motion_tween.tween_property(self, ^"_hover_progress", target_hover, 0.16)
		_motion_tween.tween_property(self, ^"_press_progress", target_press, 0.16)
		_motion_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.16)

func _update_layout() -> void:
	if _font == null:
		_update_font()
	var has_ic: bool = (leading_icon != &"" or leading_icon_texture != null)
	var text_w: float = 0.0
	if _font != null and not text.is_empty():
		text_w = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	var lead_w: float = (16.0 if has_ic else 20.0) + (18.0 + 8.0 if has_ic else 0.0) + text_w + 16.0
	lead_w = maxf(lead_w, 76.0)
	var total_w: float = lead_w + gap + TRAILING_WIDTH
	custom_minimum_size = Vector2(total_w, BAR_HEIGHT)
	if size.x < total_w or size.y < BAR_HEIGHT:
		size = custom_minimum_size
	update_minimum_size()

func _get_minimum_size() -> Vector2:
	return custom_minimum_size

func _get_container_color() -> Color:
	if disabled:
		if variant == VariantType.OUTLINED:
			return Color.TRANSPARENT
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
	match variant:
		VariantType.FILLED:
			return get_m3_color(&"primary")
		VariantType.TONAL:
			return get_m3_color(&"secondary_container")
		VariantType.ELEVATED:
			var base_surf := get_m3_color(&"surface_container_low")
			var tint_col := get_m3_color(&"surface_tint")
			return M3Elevation.get_surface_tinted_color(base_surf, tint_col, _current_elevation)
		VariantType.OUTLINED:
			return Color.TRANSPARENT
	return get_m3_color(&"primary")

func _get_content_color() -> Color:
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTENT_OPACITY)
	match variant:
		VariantType.FILLED:
			return get_m3_color(&"on_primary")
		VariantType.TONAL:
			return get_m3_color(&"on_secondary_container")
		VariantType.ELEVATED, VariantType.OUTLINED:
			return get_m3_color(&"primary")
	return get_m3_color(&"on_primary")

func _get_border_color() -> Color:
	if variant != VariantType.OUTLINED:
		return Color.TRANSPARENT
	if disabled:
		return Color(get_m3_color(&"on_surface"), M3Color.DISABLED_CONTAINER_OPACITY)
	return get_m3_color(&"outline")

func _is_in_trailing(local_pos: Vector2) -> bool:
	return local_pos.x >= (size.x - TRAILING_WIDTH - gap * 0.5)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var in_trail: bool = _is_in_trailing(mm.position) and mm.position.y <= BAR_HEIGHT
		var in_lead: bool = (not in_trail) and mm.position.y <= BAR_HEIGHT
		if _leading_hovered != in_lead or _trailing_hovered != in_trail:
			_leading_hovered = in_lead
			_trailing_hovered = in_trail
			queue_redraw()

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pressed_segment = 1 if _is_in_trailing(mb.position) else 0

	super._gui_input(event)

func _on_mouse_exited() -> void:
	_leading_hovered = false
	_trailing_hovered = false
	super._on_mouse_exited()

func _on_pressed_action() -> void:
	if _pressed_segment == 1:
		toggle_menu()
	else:
		press_primary()
	_pressed_segment = -1

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return

	var lead_rect := get_leading_rect()
	var trail_rect := get_trailing_rect()
	var pill_r: int = int(BAR_HEIGHT * 0.5)
	var inner_r: int = int(inner_corner_radius)
	var trail_inner_r: int = int(lerpf(inner_corner_radius, float(pill_r), menu_open_progress))

	var bg_col := _get_container_color()
	var border_col := _get_border_color()
	var content_col := _get_content_color()

	# 1. Leading segment
	var lead_sb := StyleBoxFlat.new()
	lead_sb.bg_color = bg_col
	lead_sb.corner_radius_top_left = pill_r
	lead_sb.corner_radius_bottom_left = pill_r
	lead_sb.corner_radius_top_right = inner_r
	lead_sb.corner_radius_bottom_right = inner_r
	if border_col.a > 0.0:
		lead_sb.set_border_width_all(1)
		lead_sb.border_color = border_col
	draw_style_box(lead_sb, lead_rect)

	# 2. Trailing segment
	var trail_sb := StyleBoxFlat.new()
	trail_sb.bg_color = bg_col
	trail_sb.corner_radius_top_left = trail_inner_r
	trail_sb.corner_radius_bottom_left = trail_inner_r
	trail_sb.corner_radius_top_right = pill_r
	trail_sb.corner_radius_bottom_right = pill_r
	if border_col.a > 0.0:
		trail_sb.set_border_width_all(1)
		trail_sb.border_color = border_col
	draw_style_box(trail_sb, trail_rect)

	# 3. Leading segment content (icon + text)
	var has_ic: bool = (leading_icon != &"" or leading_icon_texture != null)
	var ic_s: float = 18.0
	var text_w: float = 0.0
	if _font != null and not text.is_empty():
		text_w = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x

	var total_lead_content_w: float = (ic_s + 8.0 if has_ic and not text.is_empty() else (ic_s if has_ic else 0.0)) + text_w
	var cur_x: float = lead_rect.position.x + (lead_rect.size.x - total_lead_content_w) * 0.5

	if has_ic:
		var ic_rect := Rect2(cur_x, (BAR_HEIGHT - ic_s) * 0.5, ic_s, ic_s)
		_draw_leading_icon(ic_rect, content_col)
		cur_x += ic_s + (8.0 if not text.is_empty() else 0.0)

	if _font != null and not text.is_empty():
		var font_ascent := _font.get_ascent(_font_size)
		var text_y := (BAR_HEIGHT - _font.get_height(_font_size)) * 0.5 + font_ascent
		draw_string(_font, Vector2(cur_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, content_col)

	# 4. Trailing segment chevron (rotates 0 -> PI via chevron_rotation)
	var trail_center := trail_rect.get_center()
	var scale_f: float = 20.0 / 24.0
	var sw: float = 2.0
	var p1 := Vector2(-5.0, -2.5) * scale_f
	var p2 := Vector2(0.0, 3.0) * scale_f
	var p3 := Vector2(5.0, -2.5) * scale_f
	var c_pts := PackedVector2Array([
		trail_center + p1.rotated(chevron_rotation),
		trail_center + p2.rotated(chevron_rotation),
		trail_center + p3.rotated(chevron_rotation)
	])
	draw_polyline(c_pts, content_col, sw, true)

func _draw_leading_icon(target_rect: Rect2, color: Color) -> void:
	if leading_icon_texture != null:
		draw_texture_rect(leading_icon_texture, target_rect, false, color)
		return
	var center := target_rect.get_center()
	var scale_factor := target_rect.size.x / 24.0
	var sw: float = maxf(1.2, 2.0 * scale_factor)
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_factor

	var key := String(leading_icon).to_lower().replace("-", "_")
	match key:
		"add", "plus":
			draw_line(t.call(Vector2(12, 5)), t.call(Vector2(12, 19)), color, sw, true)
			draw_line(t.call(Vector2(5, 12)), t.call(Vector2(19, 12)), color, sw, true)
		"edit", "pencil":
			var pts := PackedVector2Array([
				t.call(Vector2(5, 19)), t.call(Vector2(9, 18)), t.call(Vector2(18, 9)),
				t.call(Vector2(15, 6)), t.call(Vector2(6, 15)), t.call(Vector2(5, 19))
			])
			draw_polyline(pts, color, sw, true)
		"send":
			var snd := PackedVector2Array([t.call(Vector2(3, 4)), t.call(Vector2(21, 12)), t.call(Vector2(3, 20)), t.call(Vector2(5.5, 12)), t.call(Vector2(3, 4))])
			draw_polyline(snd, color, sw, true)
		"checkmark", "check":
			var pts := PackedVector2Array([t.call(Vector2(5, 12)), t.call(Vector2(10, 17)), t.call(Vector2(19, 7))])
			draw_polyline(pts, color, sw, true)
		_:
			draw_circle(center, 3.5 * scale_factor, color)
