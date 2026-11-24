@tool
class_name M3Select
extends M3Control

## Material 3 Select / Exposed Dropdown Menu component with Filled & Outlined variants,
## rotating chevron, animated floating label, and in-tree M3 menu overlay.

signal item_selected(index: int, value: Variant)
signal dropdown_opened()
signal dropdown_closed()

@export var items: Array[Dictionary] = []:
	set(value):
		items = value
		_update_display_text(is_inside_tree())
		_sync_dropdown_panel()
		queue_redraw()

@export var options: Array:
	get:
		var arr: Array[String] = []
		for it in items:
			arr.append(str(it.get("label", "")))
		return arr
	set(value):
		var new_items: Array[Dictionary] = []
		for opt in value:
			if opt is Dictionary:
				new_items.append(opt)
			else:
				new_items.append({"label": str(opt), "value": opt})
		items = new_items

@export var selected_index: int = -1:
	set(value):
		if selected_index != value:
			selected_index = value
			_update_display_text(is_inside_tree())
			if selected_index >= 0 and selected_index < items.size():
				item_selected.emit(selected_index, items[selected_index].get("value", null))
			if _dropdown_panel != null and is_instance_valid(_dropdown_panel):
				_dropdown_panel.queue_redraw()
			queue_redraw()

@export var label: String = "Select":
	set(value):
		label = value
		queue_redraw()

@export var label_text: String:
	get:
		return label
	set(value):
		label = value
		queue_redraw()

@export var variant: M3TextField.Variant = M3TextField.Variant.OUTLINED:
	set(value):
		variant = value
		queue_redraw()

@export var leading_icon: StringName = &"":
	set(value):
		leading_icon = value
		queue_redraw()

@export var is_open: bool = false:
	set(value):
		if is_open != value:
			is_open = value
			if value:
				_open_dropdown()
			else:
				_close_dropdown()

var _is_open: bool = false
var open_progress: float = 0.0:
	set(value):
		open_progress = value
		if _dropdown_panel != null and is_instance_valid(_dropdown_panel):
			_dropdown_panel.queue_redraw()
		queue_redraw()

var _chevron_rot: float = 0.0:
	set(value):
		_chevron_rot = value
		queue_redraw()

var _chevron_tween: Tween = null
var _label_progress: float = 0.0:
	set(value):
		_label_progress = value
		queue_redraw()

var _label_tween: Tween = null
var _font: Font = null
var _font_size: int = 14
var _popup_menu: PopupMenu = null
var _dropdown_panel: _SelectDropdownOverlay = null

class _SelectDropdownOverlay extends Control:
	var owner_select: M3Select = null
	var hovered_index: int = -1

	func _init() -> void:
		top_level = true
		z_index = 100
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if owner_select == null or not is_instance_valid(owner_select):
			return
		if event is InputEventMouseMotion:
			var mm := event as InputEventMouseMotion
			var idx: int = int(floor((mm.position.y - 8.0) / 48.0))
			if idx < 0 or idx >= owner_select.items.size():
				idx = -1
			if idx != hovered_index:
				hovered_index = idx
				queue_redraw()
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				var idx: int = int(floor((mb.position.y - 8.0) / 48.0))
				if idx >= 0 and idx < owner_select.items.size():
					owner_select._on_popup_index_pressed(idx)
					accept_event()

	func _draw() -> void:
		if owner_select == null or not is_instance_valid(owner_select):
			return
		var prog: float = clampf(owner_select.open_progress, 0.0, 1.0)
		if prog <= 0.01 or size.x <= 0.0 or size.y <= 0.0:
			return
		var draw_h: float = size.y * lerpf(0.75, 1.0, prog)
		var r := Rect2(Vector2.ZERO, Vector2(size.x, draw_h))

		var surf_container := owner_select.get_m3_color(&"surface_container")
		var on_surf := owner_select.get_m3_color(&"on_surface")
		var sec_container := owner_select.get_m3_color(&"secondary_container")
		var on_sec_container := owner_select.get_m3_color(&"on_secondary_container")

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(surf_container, prog)
		sb.set_corner_radius_all(4)
		sb.shadow_color = Color(0, 0, 0, 0.24 * prog)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 2)
		draw_style_box(sb, r)

		var font := owner_select._font
		if font == null:
			return

		var n_items: int = owner_select.items.size()
		for i in range(n_items):
			var row_y: float = 8.0 + float(i) * 48.0
			if row_y + 24.0 > draw_h:
				break
			var row_rect := Rect2(0.0, row_y, size.x, 48.0)
			var is_sel: bool = (i == owner_select.selected_index)
			var text_col := on_surf
			if is_sel:
				draw_rect(row_rect, Color(sec_container, prog))
				text_col = on_sec_container
			elif i == hovered_index:
				draw_rect(row_rect, Color(on_surf, 0.08 * prog))

			var it_label: String = str(owner_select.items[i].get("label", ""))
			var ty: float = row_y + (48.0 - font.get_height(14)) * 0.5 + font.get_ascent(14)
			draw_string(font, Vector2(16.0, ty), it_label, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 32.0), 14, Color(text_col, prog))

func _init() -> void:
	super._init()
	custom_minimum_size = Vector2(200.0, 56.0)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_update_font()
	_setup_popup()
	_update_display_text(false)
	if is_open:
		_is_open = true
		open_progress = 1.0
		_chevron_rot = PI
		_label_progress = 1.0
	_sync_dropdown_panel()

func _update_font() -> void:
	_font = ThemeDB.fallback_font
	_font_size = 14

func _setup_popup() -> void:
	if _popup_menu == null:
		var found := get_node_or_null(^"M3SelectPopup") as PopupMenu
		if found != null:
			_popup_menu = found
		else:
			_popup_menu = PopupMenu.new()
			_popup_menu.name = "M3SelectPopup"
			add_child(_popup_menu, false, INTERNAL_MODE_FRONT)

	if _dropdown_panel == null:
		var found_panel := get_node_or_null(^"DropdownMenu") as _SelectDropdownOverlay
		if found_panel != null:
			_dropdown_panel = found_panel
		else:
			_dropdown_panel = _SelectDropdownOverlay.new()
			_dropdown_panel.name = "DropdownMenu"
			add_child(_dropdown_panel)
		_dropdown_panel.owner_select = self

func _sync_dropdown_panel() -> void:
	if _dropdown_panel == null or not is_instance_valid(_dropdown_panel):
		return
	var panel_h: float = float(maxi(1, items.size())) * 48.0 + 16.0
	var gp: Vector2 = get_global_position() if is_inside_tree() else position
	_dropdown_panel.position = Vector2(gp.x, gp.y + size.y + 4.0)
	_dropdown_panel.size = Vector2(maxf(size.x, 180.0), panel_h)
	_dropdown_panel.visible = _is_open and not items.is_empty()
	_dropdown_panel.queue_redraw()

func get_dropdown_panel() -> Control:
	return _dropdown_panel

## Returns the stage/viewport coordinates of the center of dropdown item `index`.
func get_item_global_position(index: int) -> Vector2:
	_sync_dropdown_panel()
	var gp: Vector2 = get_global_position()
	return Vector2(gp.x + size.x * 0.5, gp.y + size.y + 4.0 + 8.0 + float(index) * 48.0 + 24.0)

func _on_theme_updated() -> void:
	super._on_theme_updated()
	_update_font()
	if _dropdown_panel != null and is_instance_valid(_dropdown_panel):
		_dropdown_panel.queue_redraw()
	queue_redraw()

func add_item(p_label: String, p_value: Variant = null, p_icon: StringName = &"") -> void:
	var item_dict: Dictionary = {
		"label": p_label,
		"value": p_value if p_value != null else p_label,
		"icon": p_icon
	}
	var new_items := items.duplicate()
	new_items.append(item_dict)
	items = new_items

func clear_items() -> void:
	items = []
	selected_index = -1

func get_selected_value() -> Variant:
	if selected_index >= 0 and selected_index < items.size():
		return items[selected_index].get("value", null)
	return null

func get_selected_text() -> String:
	if selected_index >= 0 and selected_index < items.size():
		return str(items[selected_index].get("label", ""))
	return ""

func _update_display_text(animate: bool = true) -> void:
	var has_text: bool = not get_selected_text().is_empty()
	var target: float = 1.0 if (has_text or _is_open) else 0.0
	if not animate or not is_inside_tree():
		_label_progress = target
		queue_redraw()
		return

	if _label_tween != null and _label_tween.is_valid():
		_label_tween.kill()

	_label_tween = create_tween().set_parallel(true)
	if _label_tween:
		_label_tween.bind_node(self)
		_label_tween.set_trans(Tween.TRANS_CUBIC)
		_label_tween.set_ease(Tween.EASE_OUT)
		_label_tween.tween_property(self, ^"_label_progress", target, 0.2)
		_label_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)

func _on_pressed_action() -> void:
	if _is_open:
		_close_dropdown()
	else:
		_open_dropdown()

func open_dropdown() -> void:
	_open_dropdown()

func close_dropdown() -> void:
	_close_dropdown()

func _open_dropdown() -> void:
	if disabled:
		return

	_is_open = true
	is_open = true
	_sync_dropdown_panel()
	dropdown_opened.emit()
	if is_inside_tree():
		_animate_open_state(PI, 1.0)
		_update_display_text(true)
	else:
		_chevron_rot = PI
		open_progress = 1.0
		_label_progress = 1.0

func _close_dropdown() -> void:
	if not _is_open and not is_open:
		return
	_is_open = false
	is_open = false
	if is_inside_tree():
		_animate_open_state(0.0, 0.0)
		_update_display_text(true)
	else:
		_chevron_rot = 0.0
		open_progress = 0.0
		_update_display_text(false)
		_sync_dropdown_panel()
	dropdown_closed.emit()

func _on_popup_index_pressed(idx: int) -> void:
	selected_index = idx
	_close_dropdown()

func _animate_open_state(target_rad: float, target_open: float) -> void:
	if _chevron_tween != null and _chevron_tween.is_valid():
		_chevron_tween.kill()

	_chevron_tween = create_tween().set_parallel(true)
	if _chevron_tween:
		_chevron_tween.bind_node(self)
		_chevron_tween.set_trans(Tween.TRANS_CUBIC)
		_chevron_tween.set_ease(Tween.EASE_OUT)
		_chevron_tween.tween_property(self, ^"_chevron_rot", target_rad, 0.2)
		_chevron_tween.tween_property(self, ^"open_progress", target_open, 0.2)
		_chevron_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)
		if target_open <= 0.01:
			_chevron_tween.chain().tween_callback(func() -> void:
				if not _is_open and _dropdown_panel != null and is_instance_valid(_dropdown_panel):
					_dropdown_panel.visible = false
			)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	if _is_open:
		_sync_dropdown_panel()

	var primary_col := get_m3_color(&"primary")
	var outline_col := get_m3_color(&"outline")
	var surf_highest := get_m3_color(&"surface_container_highest")
	var on_surf_var := get_m3_color(&"on_surface_variant")
	var on_surf_col := get_m3_color(&"on_surface")

	var active_color := primary_col if (_is_open or has_focus()) else outline_col
	if disabled:
		active_color = Color(on_surf_col, M3Color.DISABLED_CONTAINER_OPACITY)

	var has_leading: bool = (leading_icon != &"")
	var label_start_x: float = 44.0 if has_leading else 16.0

	# 1. Background & Border
	if variant == M3TextField.Variant.FILLED:
		var sb := StyleBoxFlat.new()
		sb.bg_color = surf_highest if not disabled else Color(on_surf_col, M3Color.DISABLED_CONTAINER_OPACITY * 0.5)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		draw_style_box(sb, r)

		var line_h: float = 2.0 if (_is_open or has_focus()) else 1.0
		var line_col := primary_col if (_is_open or has_focus()) else on_surf_var
		if disabled:
			line_col = Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
		draw_line(Vector2(0, size.y - line_h * 0.5), Vector2(size.x, size.y - line_h * 0.5), line_col, line_h)

	else: # OUTLINED
		var border_w: float = 2.0 if (_is_open or has_focus()) else 1.0
		var radius: float = 4.0

		if not label.is_empty() and _label_progress > 0.01 and _font != null:
			var label_str_w: float = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var notch_start: float = label_start_x - 4.0
			var notch_end: float = label_start_x + label_str_w + 4.0

			if notch_start > radius:
				draw_line(Vector2(radius, 0), Vector2(notch_start, 0), active_color, border_w)
			if size.x - radius > notch_end:
				draw_line(Vector2(notch_end, 0), Vector2(size.x - radius, 0), active_color, border_w)

			draw_line(Vector2(size.x, radius), Vector2(size.x, size.y - radius), active_color, border_w)
			draw_line(Vector2(size.x - radius, size.y), Vector2(radius, size.y), active_color, border_w)
			draw_line(Vector2(0, size.y - radius), Vector2(0, radius), active_color, border_w)

			draw_arc(Vector2(radius, radius), radius, PI, 1.5 * PI, 8, active_color, border_w)
			draw_arc(Vector2(size.x - radius, radius), radius, 1.5 * PI, TAU, 8, active_color, border_w)
			draw_arc(Vector2(size.x - radius, size.y - radius), radius, 0, 0.5 * PI, 8, active_color, border_w)
			draw_arc(Vector2(radius, size.y - radius), radius, 0.5 * PI, PI, 8, active_color, border_w)
		else:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color.TRANSPARENT
			sb.border_color = active_color
			sb.set_border_width_all(int(border_w))
			sb.set_corner_radius_all(int(radius))
			draw_style_box(sb, r)

	# 2. Floating Label
	if not label.is_empty() and _font != null:
		var rest_y: float = (size.y - _font.get_height(16)) * 0.5 + _font.get_ascent(16)
		var float_y: float = (16.0 if variant == M3TextField.Variant.FILLED else 0.0) + _font.get_ascent(12) * 0.5
		if variant == M3TextField.Variant.OUTLINED:
			float_y = _font.get_ascent(12) * 0.5 - 2.0

		var cur_y: float = lerpf(rest_y, float_y, _label_progress)
		var cur_size: int = int(round(lerpf(16.0, 12.0, _label_progress)))
		var cur_label_color: Color = primary_col if (_is_open or has_focus()) else on_surf_var
		if disabled:
			cur_label_color = Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)

		draw_string(_font, Vector2(label_start_x, cur_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, cur_size, cur_label_color)

	# 3. Selected item text
	var sel_text := get_selected_text()
	if not sel_text.is_empty() and _font != null:
		var text_y: float = (size.y - _font.get_height(_font_size)) * 0.5 + _font.get_ascent(_font_size)
		if variant == M3TextField.Variant.FILLED and not label.is_empty():
			text_y += 6.0
		var text_col := on_surf_col if not disabled else Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY)
		draw_string(_font, Vector2(label_start_x, text_y), sel_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, text_col)

	# 4. Trailing rotating chevron
	var chevron_center := Vector2(size.x - 24.0, size.y * 0.5)
	_draw_rotating_chevron(chevron_center, on_surf_var if not disabled else Color(on_surf_col, M3Color.DISABLED_CONTENT_OPACITY))

func _draw_rotating_chevron(center: Vector2, col: Color) -> void:
	var sw: float = 2.0
	var p1 := Vector2(-6.0, -3.0).rotated(_chevron_rot) + center
	var p2 := Vector2(0.0, 3.0).rotated(_chevron_rot) + center
	var p3 := Vector2(6.0, -3.0).rotated(_chevron_rot) + center
	var pts := PackedVector2Array([p1, p2, p3])
	draw_polyline(pts, col, sw, true)
