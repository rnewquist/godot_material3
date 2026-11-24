@tool
class_name M3Chip
extends M3BaseControl

signal clicked
signal pressed
signal toggled(is_selected: bool)
signal deleted
signal close_pressed

enum ChipType {
	ASSIST,
	FILTER,
	INPUT,
	SUGGESTION
}

@export var text: String = "Chip":
	set(value):
		text = value
		_update_content()

@export var chip_type: ChipType = ChipType.ASSIST:
	set(value):
		chip_type = value
		_update_content()

@export var elevated: bool = false:
	set(value):
		elevated = value
		queue_redraw()

@export var selected: bool = false:
	set(value):
		if selected != value:
			selected = value
			_animate_selection()
			toggled.emit(selected)
			queue_redraw()

@export var icon: Texture2D = null:
	set(value):
		icon = value
		_update_content()

@export var icon_name: StringName = &"":
	set(value):
		icon_name = value
		_update_content()

@export var leading_icon: String:
	get:
		return String(icon_name)
	set(value):
		icon_name = StringName(value)

@export var avatar_text: String = "":
	set(value):
		avatar_text = value
		_update_content()

@export var show_close_icon: bool = true:
	set(value):
		show_close_icon = value
		_update_content()

var _checkmark_progress: float = 0.0
var _select_progress: float = 0.0
var _check_tween: Tween
var _close_hovered: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(48, 32)
	size = custom_minimum_size

func _ready() -> void:
	super._ready()
	_checkmark_progress = 1.0 if selected else 0.0
	_select_progress = _checkmark_progress
	_update_content()

func _animate_selection() -> void:
	var target: float = 1.0 if selected else 0.0
	if not is_inside_tree():
		_checkmark_progress = target
		_select_progress = target
		return
	if _check_tween and _check_tween.is_valid():
		_check_tween.kill()
	_check_tween = create_tween()
	_check_tween.bind_node(self)
	_check_tween.set_parallel(true)
	_check_tween.set_trans(Tween.TRANS_CUBIC)
	_check_tween.set_ease(Tween.EASE_OUT)
	_check_tween.tween_property(self, ^"_checkmark_progress", target, 0.2)
	_check_tween.tween_property(self, ^"_select_progress", target, 0.2)
	_check_tween.tween_method(func(_val: Variant) -> void: queue_redraw(), 0.0, 1.0, 0.2)

func _has_leading_visual() -> bool:
	return icon != null or icon_name != &"" or not avatar_text.is_empty()

func _update_content() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 14
	var text_w: float = 0.0
	if font:
		text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	var total_w: float = 16.0 + text_w + 16.0
	if _has_leading_visual() or chip_type == ChipType.FILTER:
		total_w += 24.0
	if chip_type == ChipType.INPUT and show_close_icon:
		total_w += 24.0

	custom_minimum_size = Vector2(maxf(total_w, 48.0), 32.0)
	size = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
	update_minimum_size()
	queue_redraw()

func get_close_rect() -> Rect2:
	return Rect2(size.x - 28.0, (size.y - 18.0) * 0.5, 18.0, 18.0)

func remove_chip() -> void:
	close_pressed.emit()
	deleted.emit()

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseMotion:
		if chip_type == ChipType.INPUT and show_close_icon:
			var close_rect := get_close_rect()
			var was_close_hovered := _close_hovered
			_close_hovered = close_rect.has_point(event.position)
			if was_close_hovered != _close_hovered:
				queue_redraw()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			if _ripple_effect:
				_ripple_effect.start_press(event.position)
			queue_redraw()
			accept_event()
		else:
			if is_pressed:
				is_pressed = false
				if _ripple_effect:
					_ripple_effect.end_press()
				if chip_type == ChipType.INPUT and show_close_icon:
					var close_rect := get_close_rect()
					if close_rect.has_point(event.position):
						remove_chip()
						queue_redraw()
						accept_event()
						return

				if Rect2(Vector2.ZERO, size).has_point(event.position):
					if chip_type == ChipType.FILTER:
						selected = not selected
					clicked.emit()
					pressed.emit()
				queue_redraw()
				accept_event()

func _draw() -> void:
	var s := get_scheme()
	var corner_rad: float = 8.0
	var rect := Rect2(Vector2.ZERO, size)

	var bg_color := Color.TRANSPARENT
	var border_color := Color.TRANSPARENT
	var border_width: int = 0
	var text_color := s.on_surface_variant
	var icon_color := s.primary
	var elev_level: int = 0

	var unsel_bg: Color = s.surface_container_low if elevated else Color.TRANSPARENT
	if selected or _select_progress > 0.01:
		bg_color = unsel_bg.lerp(s.secondary_container, _select_progress if is_inside_tree() else 1.0)
		text_color = s.on_surface_variant.lerp(s.on_secondary_container, _select_progress if is_inside_tree() else 1.0)
		icon_color = text_color
		if elevated:
			elev_level = 2 if is_hovered else 1
		elif _select_progress < 0.99:
			border_width = 1
			border_color = s.outline_variant.lerp(Color.TRANSPARENT, _select_progress)
	else:
		if elevated:
			bg_color = s.surface_container_low
			elev_level = 2 if is_hovered else 1
		else:
			bg_color = Color.TRANSPARENT
			border_width = 1
			border_color = s.outline_variant
			if is_hovered:
				border_color = s.on_surface_variant

		if chip_type == ChipType.SUGGESTION or chip_type == ChipType.ASSIST:
			icon_color = s.primary
		else:
			icon_color = s.on_surface_variant

	if disabled:
		bg_color = s.on_surface.lerp(Color.TRANSPARENT, 1.0 - 0.12) if (selected or elevated) else Color.TRANSPARENT
		border_color = s.on_surface.lerp(Color.TRANSPARENT, 1.0 - 0.12) if border_width > 0 else Color.TRANSPARENT
		text_color = s.on_surface.lerp(Color.TRANSPARENT, 1.0 - 0.38)
		icon_color = text_color
		elev_level = 0

	# Draw Elevation Shadow
	if elev_level > 0:
		draw_m3_shadow(self, rect, corner_rad, elev_level)

	# Draw Background
	var sb := create_stylebox(bg_color, corner_rad, border_width, border_color)
	draw_style_box(sb, rect)

	# Draw Hover/Pressed overlay
	if is_hovered and not disabled:
		var overlay := s.on_surface
		overlay.a = 0.08
		draw_rect(rect, overlay)
	if is_pressed and not disabled:
		var overlay := s.on_surface
		overlay.a = 0.12
		draw_rect(rect, overlay)

	# Draw Content
	var x_cursor: float = 12.0
	var center_y: float = size.y * 0.5
	var font := ThemeDB.fallback_font

	# Checkmark or Leading Icon / Avatar
	if chip_type == ChipType.FILTER:
		if _checkmark_progress > 0.01:
			var check_c := icon_color
			check_c.a *= _checkmark_progress
			var p1 := Vector2(x_cursor + 2, center_y)
			var p2 := Vector2(x_cursor + 6, center_y + 4)
			var p3 := Vector2(x_cursor + 14, center_y - 4)
			draw_line(p1, p2, check_c, 2.0, true)
			draw_line(p2, p3, check_c, 2.0, true)
			x_cursor += 18.0 * _checkmark_progress + 4.0
		elif _has_leading_visual():
			_draw_leading(Vector2(x_cursor, center_y - 9.0), icon_color, s, font)
			x_cursor += 22.0
	elif _has_leading_visual():
		_draw_leading(Vector2(x_cursor, center_y - 9.0), icon_color, s, font)
		x_cursor += 22.0

	# Text Label
	var font_size := 14
	if font:
		var text_sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos := Vector2(x_cursor, center_y + text_sz.y * 0.35)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
		x_cursor += text_sz.x + 8.0

	# Trailing Close button for Input chip
	if chip_type == ChipType.INPUT and show_close_icon:
		var close_x: float = size.x - 24.0
		var close_col := icon_color
		if _close_hovered:
			draw_circle(Vector2(close_x + 6, center_y), 9.0, s.on_surface_variant.lerp(Color.TRANSPARENT, 0.8))
			close_col = s.on_surface
		var rad: float = 4.5
		draw_line(Vector2(close_x + 6 - rad, center_y - rad), Vector2(close_x + 6 + rad, center_y + rad), close_col, 1.5, true)
		draw_line(Vector2(close_x + 6 - rad, center_y + rad), Vector2(close_x + 6 + rad, center_y - rad), close_col, 1.5, true)

func _draw_leading(top_left: Vector2, icon_color: Color, s: M3ColorScheme, font: Font) -> void:
	var icon_rect := Rect2(top_left, Vector2(18, 18))
	if not avatar_text.is_empty():
		var c := icon_rect.get_center()
		draw_circle(c, 11.0, s.primary)
		if font:
			var ch: String = avatar_text.substr(0, 1).to_upper()
			var ch_sz := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
			draw_string(font, Vector2(c.x - ch_sz.x * 0.5, c.y + ch_sz.y * 0.32), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, s.on_primary)
	elif icon != null:
		draw_texture_rect(icon, icon_rect, false, icon_color)
	elif icon_name != &"":
		var c := icon_rect.get_center()
		draw_arc(c, 6.5, 0, TAU, 20, icon_color, 1.8, true)
		draw_line(c, c + Vector2(0, -3.5), icon_color, 1.8, true)
		draw_line(c, c + Vector2(2.5, 1.5), icon_color, 1.8, true)
