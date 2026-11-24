@tool
class_name M3Icon
extends Control

## Material 3 Icon component.
## Renders crisp procedural vector glyphs for standard Material Symbols, or custom textures.

@export var icon_name: StringName = &"":
	set(value):
		icon_name = value
		queue_redraw()

@export var icon_size: float = 24.0:
	set(value):
		icon_size = maxf(1.0, value)
		custom_minimum_size = Vector2(icon_size, icon_size)
		update_minimum_size()
		queue_redraw()

@export var icon_color: Color = Color.WHITE:
	set(value):
		icon_color = value
		queue_redraw()

@export var custom_texture: Texture2D = null:
	set(value):
		custom_texture = value
		queue_redraw()

@export var stroke_width: float = 2.0:
	set(value):
		stroke_width = value
		queue_redraw()

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(icon_size, icon_size)

func _get_minimum_size() -> Vector2:
	return Vector2(icon_size, icon_size)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0 or r.size.y <= 0:
		return

	if custom_texture != null:
		var tex_s := custom_texture.get_size()
		var fit_s: Vector2
		if tex_s.x > 0 and tex_s.y > 0:
			var scale_f: float = minf(size.x / tex_s.x, size.y / tex_s.y)
			fit_s = tex_s * scale_f
		else:
			fit_s = size
		var draw_pos := (size - fit_s) * 0.5
		draw_texture_rect(custom_texture, Rect2(draw_pos, fit_s), false, icon_color)
		return

	if icon_name == &"":
		return

	var center := size * 0.5
	var s := minf(size.x, size.y)
	var scale_factor := s / 24.0
	var sw: float = maxf(1.0, stroke_width * scale_factor)

	# Transform helper: converts 24x24 canonical coords to local control coords
	var t := func(p: Vector2) -> Vector2:
		return center + (p - Vector2(12.0, 12.0)) * scale_factor

	var key: String = String(icon_name).to_lower().replace("-", "_")

	match key:
		"checkmark", "check":
			var pts := PackedVector2Array([t.call(Vector2(5, 12)), t.call(Vector2(10, 17)), t.call(Vector2(19, 7))])
			draw_polyline(pts, icon_color, sw, true)

		"close", "cross", "clear", "cancel":
			draw_line(t.call(Vector2(6, 6)), t.call(Vector2(18, 18)), icon_color, sw, true)
			draw_line(t.call(Vector2(18, 6)), t.call(Vector2(6, 18)), icon_color, sw, true)

		"arrow_down", "expand_more", "chevron_down":
			var pts := PackedVector2Array([t.call(Vector2(6, 9)), t.call(Vector2(12, 15)), t.call(Vector2(18, 9))])
			draw_polyline(pts, icon_color, sw, true)

		"arrow_up", "expand_less", "chevron_up":
			var pts := PackedVector2Array([t.call(Vector2(6, 15)), t.call(Vector2(12, 9)), t.call(Vector2(18, 15))])
			draw_polyline(pts, icon_color, sw, true)

		"arrow_right", "chevron_right":
			var pts := PackedVector2Array([t.call(Vector2(9, 6)), t.call(Vector2(15, 12)), t.call(Vector2(9, 18))])
			draw_polyline(pts, icon_color, sw, true)

		"arrow_back", "arrow_left", "chevron_left":
			var pts := PackedVector2Array([t.call(Vector2(15, 6)), t.call(Vector2(9, 12)), t.call(Vector2(15, 18))])
			draw_polyline(pts, icon_color, sw, true)

		"search":
			draw_arc(t.call(Vector2(10.5, 10.5)), 5.5 * scale_factor, 0, TAU, 24, icon_color, sw, true)
			draw_line(t.call(Vector2(14.5, 14.5)), t.call(Vector2(19.5, 19.5)), icon_color, sw, true)

		"settings":
			draw_arc(t.call(Vector2(12, 12)), 4.0 * scale_factor, 0, TAU, 20, icon_color, sw, true)
			for i in range(8):
				var angle := i * (TAU / 8.0)
				var dir := Vector2(cos(angle), sin(angle))
				var p1 := t.call(Vector2(12, 12) + dir * 6.5)
				var p2 := t.call(Vector2(12, 12) + dir * 9.5)
				draw_line(p1, p2, icon_color, sw * 1.3, true)

		"favorite", "heart":
			# Procedural heart bezier/poly
			var pts: PackedVector2Array = []
			var steps: int = 32
			for i in range(steps):
				var angle: float = (float(i) / float(steps)) * TAU
				# Math heart formula
				var hx: float = 16.0 * pow(sin(angle), 3)
				var hy: float = -(13.0 * cos(angle) - 5.0 * cos(2.0 * angle) - 2.0 * cos(3.0 * angle) - cos(4.0 * angle))
				var pos_24 := Vector2(12.0 + (hx / 17.0) * 8.5, 12.5 + (hy / 17.0) * 8.5)
				pts.append(t.call(pos_24))
			draw_colored_polygon(pts, icon_color)

		"menu", "hamburger":
			draw_line(t.call(Vector2(4, 7)), t.call(Vector2(20, 7)), icon_color, sw, true)
			draw_line(t.call(Vector2(4, 12)), t.call(Vector2(20, 12)), icon_color, sw, true)
			draw_line(t.call(Vector2(4, 17)), t.call(Vector2(20, 17)), icon_color, sw, true)

		"add", "plus":
			draw_line(t.call(Vector2(12, 5)), t.call(Vector2(12, 19)), icon_color, sw, true)
			draw_line(t.call(Vector2(5, 12)), t.call(Vector2(19, 12)), icon_color, sw, true)

		"remove", "minus":
			draw_line(t.call(Vector2(5, 12)), t.call(Vector2(19, 12)), icon_color, sw, true)

		"edit", "pencil":
			var pts := PackedVector2Array([
				t.call(Vector2(5, 19)),
				t.call(Vector2(9, 18)),
				t.call(Vector2(18, 9)),
				t.call(Vector2(15, 6)),
				t.call(Vector2(6, 15)),
				t.call(Vector2(5, 19))
			])
			draw_polyline(pts, icon_color, sw, true)

		"delete", "trash":
			# Lid
			draw_line(t.call(Vector2(4, 6)), t.call(Vector2(20, 6)), icon_color, sw, true)
			draw_line(t.call(Vector2(9, 4)), t.call(Vector2(15, 4)), icon_color, sw, true)
			# Body
			var body := PackedVector2Array([
				t.call(Vector2(6, 6)),
				t.call(Vector2(7, 20)),
				t.call(Vector2(17, 20)),
				t.call(Vector2(18, 6))
			])
			draw_polyline(body, icon_color, sw, true)
			draw_line(t.call(Vector2(10, 9)), t.call(Vector2(10, 17)), icon_color, sw * 0.8, true)
			draw_line(t.call(Vector2(14, 9)), t.call(Vector2(14, 17)), icon_color, sw * 0.8, true)

		"visibility", "eye":
			# Eye curve
			var pts_top: PackedVector2Array = []
			var pts_bot: PackedVector2Array = []
			for i in range(11):
				var px: float = 3.0 + float(i) * 1.8
				var nx: float = (px - 12.0) / 9.0
				var ny: float = (1.0 - nx * nx) * 5.0
				pts_top.append(t.call(Vector2(px, 12.0 - ny)))
				pts_bot.append(t.call(Vector2(px, 12.0 + ny)))
			draw_polyline(pts_top, icon_color, sw, true)
			draw_polyline(pts_bot, icon_color, sw, true)
			draw_circle(t.call(Vector2(12, 12)), 2.8 * scale_factor, icon_color)

		"visibility_off", "eye_off":
			# Eye + slash
			var pts_top: PackedVector2Array = []
			var pts_bot: PackedVector2Array = []
			for i in range(11):
				var px: float = 3.0 + float(i) * 1.8
				var nx: float = (px - 12.0) / 9.0
				var ny: float = (1.0 - nx * nx) * 5.0
				pts_top.append(t.call(Vector2(px, 12.0 - ny)))
				pts_bot.append(t.call(Vector2(px, 12.0 + ny)))
			draw_polyline(pts_top, icon_color, sw, true)
			draw_polyline(pts_bot, icon_color, sw, true)
			draw_line(t.call(Vector2(4, 4)), t.call(Vector2(20, 20)), icon_color, sw, true)

		"star":
			var pts: PackedVector2Array = []
			for i in range(10):
				var angle := -PI * 0.5 + float(i) * (TAU / 10.0)
				var r_pt := (9.0 if (i % 2 == 0) else 4.2)
				pts.append(t.call(Vector2(12, 12) + Vector2(cos(angle), sin(angle)) * r_pt))
			draw_colored_polygon(pts, icon_color)

		"person", "account":
			draw_circle(t.call(Vector2(12, 8)), 4.0 * scale_factor, icon_color)
			var body_pts: PackedVector2Array = []
			for i in range(13):
				var angle := PI + float(i) * (PI / 12.0)
				var p := Vector2(12, 21) + Vector2(cos(angle) * 7.5, sin(angle) * 6.0)
				body_pts.append(t.call(p))
			draw_polyline(body_pts, icon_color, sw, true)

		"home":
			# Roof
			var roof := PackedVector2Array([t.call(Vector2(4, 12)), t.call(Vector2(12, 5)), t.call(Vector2(20, 12))])
			draw_polyline(roof, icon_color, sw, true)
			# House box
			var house := PackedVector2Array([
				t.call(Vector2(6, 11)),
				t.call(Vector2(6, 20)),
				t.call(Vector2(18, 20)),
				t.call(Vector2(18, 11))
			])
			draw_polyline(house, icon_color, sw, true)
			draw_line(t.call(Vector2(10, 20)), t.call(Vector2(10, 14)), icon_color, sw, true)
			draw_line(t.call(Vector2(10, 14)), t.call(Vector2(14, 14)), icon_color, sw, true)
			draw_line(t.call(Vector2(14, 14)), t.call(Vector2(14, 20)), icon_color, sw, true)

		"more_vert":
			draw_circle(t.call(Vector2(12, 6)), sw * 0.9, icon_color)
			draw_circle(t.call(Vector2(12, 12)), sw * 0.9, icon_color)
			draw_circle(t.call(Vector2(12, 18)), sw * 0.9, icon_color)

		"more_horiz":
			draw_circle(t.call(Vector2(6, 12)), sw * 0.9, icon_color)
			draw_circle(t.call(Vector2(12, 12)), sw * 0.9, icon_color)
			draw_circle(t.call(Vector2(18, 12)), sw * 0.9, icon_color)

		"refresh":
			draw_arc(t.call(Vector2(12, 12)), 6.5 * scale_factor, 0.4, 1.8 * PI, 24, icon_color, sw, true)
			var arrow_pts := PackedVector2Array([
				t.call(Vector2(16, 7)),
				t.call(Vector2(20, 8.5)),
				t.call(Vector2(18.5, 12.5))
			])
			draw_polyline(arrow_pts, icon_color, sw, true)

		"calendar_today", "calendar", "event", "date_range":
			var cal := PackedVector2Array([t.call(Vector2(4, 6)), t.call(Vector2(20, 6)), t.call(Vector2(20, 20)), t.call(Vector2(4, 20)), t.call(Vector2(4, 6))])
			draw_polyline(cal, icon_color, sw, true)
			draw_line(t.call(Vector2(4, 10)), t.call(Vector2(20, 10)), icon_color, sw, true)
			draw_line(t.call(Vector2(8, 3.5)), t.call(Vector2(8, 7.5)), icon_color, sw, true)
			draw_line(t.call(Vector2(16, 3.5)), t.call(Vector2(16, 7.5)), icon_color, sw, true)

		"schedule", "clock", "access_time":
			draw_arc(t.call(Vector2(12, 12)), 8.5 * scale_factor, 0, TAU, 32, icon_color, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(12, 7)), t.call(Vector2(12, 12)), t.call(Vector2(15.5, 14))]), icon_color, sw, true)

		"keyboard":
			var kb := PackedVector2Array([t.call(Vector2(3, 7)), t.call(Vector2(21, 7)), t.call(Vector2(21, 17)), t.call(Vector2(3, 17)), t.call(Vector2(3, 7))])
			draw_polyline(kb, icon_color, sw, true)
			for kx in [7.0, 10.0, 13.0, 16.0]:
				draw_circle(t.call(Vector2(kx, 10.5)), sw * 0.6, icon_color)
			draw_line(t.call(Vector2(8, 14)), t.call(Vector2(16, 14)), icon_color, sw, true)

		"mic", "microphone":
			draw_line(t.call(Vector2(12, 5)), t.call(Vector2(12, 13)), icon_color, sw * 2.2, true)
			draw_arc(t.call(Vector2(12, 11)), 5.0 * scale_factor, 0.0, PI, 16, icon_color, sw, true)
			draw_line(t.call(Vector2(12, 16)), t.call(Vector2(12, 20)), icon_color, sw, true)

		"share":
			draw_circle(t.call(Vector2(17, 6)), 2.2 * scale_factor, icon_color)
			draw_circle(t.call(Vector2(7, 12)), 2.2 * scale_factor, icon_color)
			draw_circle(t.call(Vector2(17, 18)), 2.2 * scale_factor, icon_color)
			draw_line(t.call(Vector2(7, 12)), t.call(Vector2(17, 6)), icon_color, sw, true)
			draw_line(t.call(Vector2(7, 12)), t.call(Vector2(17, 18)), icon_color, sw, true)

		"bookmark":
			var bm := PackedVector2Array([t.call(Vector2(6, 4)), t.call(Vector2(18, 4)), t.call(Vector2(18, 20)), t.call(Vector2(12, 15.5)), t.call(Vector2(6, 20)), t.call(Vector2(6, 4))])
			draw_polyline(bm, icon_color, sw, true)

		"filter", "filter_list", "tune":
			draw_line(t.call(Vector2(4, 7)), t.call(Vector2(20, 7)), icon_color, sw, true)
			draw_line(t.call(Vector2(7, 12)), t.call(Vector2(17, 12)), icon_color, sw, true)
			draw_line(t.call(Vector2(10, 17)), t.call(Vector2(14, 17)), icon_color, sw, true)

		"info", "help":
			draw_arc(t.call(Vector2(12, 12)), 8.5 * scale_factor, 0, TAU, 32, icon_color, sw, true)
			draw_line(t.call(Vector2(12, 11)), t.call(Vector2(12, 16.5)), icon_color, sw, true)
			draw_circle(t.call(Vector2(12, 7.8)), sw * 0.7, icon_color)

		"error", "warning":
			var tri := PackedVector2Array([t.call(Vector2(12, 4)), t.call(Vector2(21, 19.5)), t.call(Vector2(3, 19.5)), t.call(Vector2(12, 4))])
			draw_polyline(tri, icon_color, sw, true)
			draw_line(t.call(Vector2(12, 9.5)), t.call(Vector2(12, 14)), icon_color, sw, true)
			draw_circle(t.call(Vector2(12, 16.8)), sw * 0.7, icon_color)

		"image", "photo":
			var fr := PackedVector2Array([t.call(Vector2(4, 5)), t.call(Vector2(20, 5)), t.call(Vector2(20, 19)), t.call(Vector2(4, 19)), t.call(Vector2(4, 5))])
			draw_polyline(fr, icon_color, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(5, 17)), t.call(Vector2(10, 11)), t.call(Vector2(14, 15)), t.call(Vector2(16, 13)), t.call(Vector2(19, 17))]), icon_color, sw, true)
			draw_circle(t.call(Vector2(15.5, 9)), 1.4 * scale_factor, icon_color)

		"mail", "email", "inbox":
			var env := PackedVector2Array([t.call(Vector2(3, 6)), t.call(Vector2(21, 6)), t.call(Vector2(21, 18)), t.call(Vector2(3, 18)), t.call(Vector2(3, 6))])
			draw_polyline(env, icon_color, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(3, 6.5)), t.call(Vector2(12, 13)), t.call(Vector2(21, 6.5))]), icon_color, sw, true)

		"send":
			var snd := PackedVector2Array([t.call(Vector2(3, 4)), t.call(Vector2(21, 12)), t.call(Vector2(3, 20)), t.call(Vector2(5.5, 12)), t.call(Vector2(3, 4))])
			draw_polyline(snd, icon_color, sw, true)
			draw_line(t.call(Vector2(5.5, 12)), t.call(Vector2(13, 12)), icon_color, sw, true)

		"undo":
			draw_arc(t.call(Vector2(13, 14)), 6.0 * scale_factor, -PI * 0.5, PI * 0.75, 20, icon_color, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(8, 4.5)), t.call(Vector2(5, 8)), t.call(Vector2(9, 10.5))]), icon_color, sw, true)

		"check_circle", "done_all":
			draw_arc(t.call(Vector2(12, 12)), 8.5 * scale_factor, 0, TAU, 32, icon_color, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(8, 12)), t.call(Vector2(11, 15)), t.call(Vector2(16.5, 9))]), icon_color, sw, true)

		"navigation", "explore":
			draw_arc(t.call(Vector2(12, 12)), 8.5 * scale_factor, 0, TAU, 32, icon_color, sw, true)
			draw_colored_polygon(PackedVector2Array([t.call(Vector2(15.5, 8.5)), t.call(Vector2(13, 13)), t.call(Vector2(8.5, 15.5)), t.call(Vector2(11, 11))]), icon_color)

		"notifications", "bell":
			draw_arc(t.call(Vector2(12, 11)), 5.5 * scale_factor, PI, TAU, 16, icon_color, sw, true)
			draw_line(t.call(Vector2(6.5, 11)), t.call(Vector2(6.5, 16)), icon_color, sw, true)
			draw_line(t.call(Vector2(17.5, 11)), t.call(Vector2(17.5, 16)), icon_color, sw, true)
			draw_line(t.call(Vector2(4.5, 16.5)), t.call(Vector2(19.5, 16.5)), icon_color, sw, true)
			draw_circle(t.call(Vector2(12, 19.5)), 1.4 * scale_factor, icon_color)

		"format_bold", "text_format":
			draw_polyline(PackedVector2Array([t.call(Vector2(8, 5)), t.call(Vector2(13, 5)), t.call(Vector2(15.5, 7.5)), t.call(Vector2(13, 11.5)), t.call(Vector2(8, 11.5))]), icon_color, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(8, 11.5)), t.call(Vector2(14, 11.5)), t.call(Vector2(16.5, 15)), t.call(Vector2(14, 19)), t.call(Vector2(8, 19)), t.call(Vector2(8, 5))]), icon_color, sw, true)

		"attach_file", "link":
			draw_arc(t.call(Vector2(12, 8)), 3.5 * scale_factor, PI, TAU, 12, icon_color, sw, true)
			draw_line(t.call(Vector2(8.5, 8)), t.call(Vector2(8.5, 16)), icon_color, sw, true)
			draw_line(t.call(Vector2(15.5, 8)), t.call(Vector2(15.5, 16)), icon_color, sw, true)
			draw_arc(t.call(Vector2(12, 16)), 3.5 * scale_factor, 0.0, PI, 12, icon_color, sw, true)

		"play_arrow", "play":
			draw_colored_polygon(PackedVector2Array([t.call(Vector2(8, 5)), t.call(Vector2(19, 12)), t.call(Vector2(8, 19))]), icon_color)

		"pause":
			draw_line(t.call(Vector2(9, 5)), t.call(Vector2(9, 19)), icon_color, sw * 1.6, true)
			draw_line(t.call(Vector2(15, 5)), t.call(Vector2(15, 19)), icon_color, sw * 1.6, true)

		"location", "place":
			draw_arc(t.call(Vector2(12, 9.5)), 5.5 * scale_factor, PI * 0.85, TAU + PI * 0.15, 20, icon_color, sw, true)
			draw_polyline(PackedVector2Array([t.call(Vector2(7, 12)), t.call(Vector2(12, 20.5)), t.call(Vector2(17, 12))]), icon_color, sw, true)
			draw_circle(t.call(Vector2(12, 9.5)), 1.8 * scale_factor, icon_color)

		_:
			# Fallback: simple dot or letter
			draw_circle(center, 4.0 * scale_factor, icon_color)
